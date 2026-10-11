local _, A = ...
local U, D, V = A.Util, A.DB, A.Valuation
local C = { rows = {}, cursor = 1, generation = 0, dirty = true }
A.Crafting = C

local MAX_ID, MAX_QUANTITY, MAX_RECIPES = 2147483647, 1000000, 20000
local function Call(fn, ...)
    if not U.Accessible(fn) or type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    if ok and U.Accessible(value) then return value end
end
C.Call = Call

function C.Supported()
    if not U.Table(C_TradeSkillUI) then return false end
    for _, name in ipairs({ "GetRecipeInfo", "GetRecipeSchematic", "GetRecipeOutputItemData" }) do
        if type(C_TradeSkillUI[name]) ~= "function" then return false end
    end
    return true
end

function C.Form()
    if not U.Table(ProfessionsFrame) or (ProfessionsFrame.IsForbidden and ProfessionsFrame:IsForbidden()) or
       not ProfessionsFrame:IsShown() then return nil end
    local page = ProfessionsFrame.CraftingPage
    if not U.Table(page) or (page.IsShown and not page:IsShown()) then return nil end
    return U.Table(page.SchematicForm) and page.SchematicForm or nil
end

-- Native transactions separate regular and modified reagents. Copy only the
-- public item/quantity/slot fields; never modify Blizzard's transaction.
local function Allocations(form)
    local transaction = form and Call(form.GetTransaction, form)
    if not U.Table(transaction) then return nil end
    local result, modified = {}, {}
    for _, method in ipairs({ "CreateReagentInfoTbl", "CreateCraftingReagentInfoTbl" }) do
        local values = Call(transaction[method], transaction)
        if U.Table(values) then
            for index, value in ipairs(values) do
                if index > 200 or not U.Table(value) or not U.Table(value.reagent) or
                   not U.Number(value.dataSlotIndex, 1, 1000, true) or
                   not U.Number(value.quantity, 0, MAX_QUANTITY, true) then return nil, "Reagent selection is unavailable." end
                if value.quantity > 0 then
                    local id = value.reagent.itemID
                    if not U.Number(id, 1, MAX_ID, true) then return nil, "A selected reagent has no market item price." end
                    local slot = result[value.dataSlotIndex] or {}
                    result[value.dataSlotIndex] = slot
                    slot[#slot + 1] = { id = id, quantity = value.quantity }
                    if method == "CreateCraftingReagentInfoTbl" then
                        modified[#modified + 1] = { reagent = { itemID = id }, dataSlotIndex = value.dataSlotIndex, quantity = value.quantity }
                    end
                end
            end
        end
    end
    return result, nil, modified
end

function C.Quote(cost, markup)
    if not U.Number(cost, 0, 9007199254740991) or not U.Number(markup, 0, 1000, true) then return nil end
    local quote = cost * (1 + markup / 100)
    return U.Number(quote, 0, 9007199254740991) and quote or nil
end

function C.Analyze(recipeID, form, snapshot)
    if not C.Supported() or not U.Number(recipeID, 1, MAX_ID, true) then return nil end
    local level = form and Call(form.GetCurrentRecipeLevel, form)
    if not U.Number(level, 1, 1000, true) then level = nil end
    local info = Call(C_TradeSkillUI.GetRecipeInfo, recipeID, level)
    if not U.Table(info) or not U.Accessible(info.learned) or info.learned ~= true then return nil end
    local result = { recipeID = recipeID, name = U.String(info.name) and info.name or ("Recipe " .. recipeID), materials = {}, missing = {}, subtotal = 0 }
    local function Unavailable(reason) result.reason = reason; return result end
    for _, flag in ipairs({ "isRecraft", "isSalvageRecipe", "isGatheringRecipe", "isDummyRecipe" }) do
        if not U.Accessible(info[flag]) then return Unavailable("Recipe data is restricted.") end
        if info[flag] == true then return Unavailable("This recipe has no fixed material cost.") end
    end
    local schematic = Call(C_TradeSkillUI.GetRecipeSchematic, recipeID, false, level)
    if not U.Table(schematic) or not U.Table(schematic.reagentSlotSchematics) then
        return Unavailable("Recipe materials are loading.")
    end
    if not U.Accessible(schematic.isRecraft) or schematic.isRecraft == true then return Unavailable("Recraft cost is unavailable.") end
    local allocations, allocationReason, modified = Allocations(form)
    if allocationReason then return Unavailable(allocationReason) end
    local quantities, order, knownSlots = {}, {}, {}
    local function Add(id, quantity)
        if not quantities[id] then order[#order + 1] = id; quantities[id] = 0 end
        quantities[id] = quantities[id] + quantity
    end
    for index, slot in ipairs(schematic.reagentSlotSchematics) do
        if index > 100 or not U.Table(slot) or not U.Table(slot.reagents) or
           not U.Accessible(slot.required) or type(slot.required) ~= "boolean" or
           not U.Number(slot.quantityRequired, 0, MAX_QUANTITY, true) or
           not U.Number(slot.dataSlotIndex, 1, 1000, true) then
            return Unavailable("Recipe materials are unavailable.")
        end
        if knownSlots[slot.dataSlotIndex] then return Unavailable("Duplicate reagent slots are unavailable.") end
        knownSlots[slot.dataSlotIndex] = true
        if not U.Accessible(slot.variableQuantities) or
           (U.Table(slot.variableQuantities) and next(slot.variableQuantities) ~= nil) then
            return Unavailable("Variable reagent quantities need a separate estimate.")
        end
        local selected = allocations and allocations[slot.dataSlotIndex]
        local candidates = {}
        for candidateIndex, reagent in ipairs(slot.reagents) do
            if candidateIndex > 100 or not U.Table(reagent) then return Unavailable("Reagent choices are unavailable.") end
            if not U.Number(reagent.itemID, 1, MAX_ID, true) then
                if slot.required or selected then return Unavailable("A required reagent has no market item price.") end
            else candidates[reagent.itemID] = true end
        end
        if selected then
            local total = 0
            for _, reagent in ipairs(selected) do
                if not candidates[reagent.id] then return Unavailable("Reagent selection does not match this recipe.") end
                total = total + reagent.quantity
            end
            if slot.required and total ~= slot.quantityRequired then
                -- One fixed reagent has a known cost even when the character
                -- owns only part of the required quantity.
                if #slot.reagents == 1 then
                    Add(slot.reagents[1].itemID, slot.quantityRequired)
                else return Unavailable("Choose all required reagent quantities.") end
            else
                for _, reagent in ipairs(selected) do Add(reagent.id, reagent.quantity) end
            end
        elseif slot.required and slot.quantityRequired > 0 then
            if #slot.reagents ~= 1 then return Unavailable("Choose the required reagent variant to price this recipe.") end
            local id = slot.reagents[1].itemID
            if not U.Number(id, 1, MAX_ID, true) then return Unavailable("A required reagent has no market item price.") end
            Add(id, slot.quantityRequired)
        end
    end
    if allocations then
        for slotIndex in pairs(allocations) do
            if not knownSlots[slotIndex] then return Unavailable("Reagent selection is changing. Select the recipe again.") end
        end
    end
    snapshot = snapshot or D.Snapshot()
    for _, id in ipairs(order) do
        local quantity = quantities[id]
        if not U.Number(quantity, 1, MAX_QUANTITY, true) then return Unavailable("Invalid material quantity.") end
        local price, mode = D.Price(id, nil, snapshot)
        local material = { id = id, quantity = quantity, name = V.MaterialName(id), mode = mode }
        if price then
            material.unitPrice, material.total = price.low, price.low * quantity
            result.subtotal = result.subtotal + material.total
        else result.missing[#result.missing + 1] = id end
        result.materials[#result.materials + 1] = material
    end
    if #result.missing > 0 then return Unavailable("Material prices missing: " .. #result.missing .. ". Complete an AH scan or check listings.") end
    if not U.Number(result.subtotal, 0, 9007199254740991) then return Unavailable("Material cost is out of range.") end
    result.cost = result.subtotal
    result.quote = C.Quote(result.cost, D.Settings().quoteMarkup)
    local minimum, maximum = schematic.quantityMin, schematic.quantityMax
    if not U.Number(minimum, 1, MAX_QUANTITY, true) or not U.Number(maximum, minimum, MAX_QUANTITY, true) then
        return Unavailable("Output quantity is unavailable; material quote only.")
    end
    result.quantityMin, result.quantityMax = minimum, maximum
    local transaction = form and Call(form.GetTransaction, form)
    local guid = U.Table(transaction) and Call(transaction.GetAllocationItemGUID, transaction) or nil
    if not U.String(guid) then guid = nil end
    local quality = form and Call(form.GetOutputOverrideQualityID, form)
    if not U.Number(quality, 1, MAX_ID, true) then quality = nil end
    if not U.Accessible(info.supportsQualities) then return Unavailable("Output quality is restricted.") end
    if info.supportsQualities == true and not form then return Unavailable("Select this recipe to price its output quality.") end
    local output = Call(C_TradeSkillUI.GetRecipeOutputItemData, recipeID, U.Table(modified) and modified or nil, guid, quality)
    if U.Table(output) and (not U.Accessible(output.itemID) or not U.Accessible(output.hyperlink)) then
        return Unavailable("Output item data is restricted; material quote only.")
    end
    local outputLink = U.Table(output) and output.hyperlink
    local outputID = U.Table(output) and output.itemID
    if not U.Number(outputID, 1, MAX_ID, true) then outputID = U.ItemID(outputLink) end
    if info.supportsQualities == true and not U.Number(outputID, 1, MAX_ID, true) then
        return Unavailable("Selected output quality is unavailable; material quote only.")
    end
    if not U.Number(outputID, 1, MAX_ID, true) then outputID = schematic.outputItemID end
    if not U.Number(outputID, 1, MAX_ID, true) then
        result.service = true
        return Unavailable("Service recipe: material quote only.")
    end
    if not U.String(outputLink) or U.ItemID(outputLink) ~= outputID then outputLink = nil end
    result.outputID = outputID
    result.outputLink = outputLink
    result.unitCostMin, result.unitCostMax = result.cost / maximum, result.cost / minimum
    local price = D.Price(outputID, outputLink, snapshot)
    if not price then return Unavailable("Output has no buyout price in the latest scan; material quote only.") end
    local saleMin, saleMax = price.low * minimum, price.low * maximum
    if not U.Number(saleMin, 0, 9007199254740991) or not U.Number(saleMax, 0, 9007199254740991) then
        return Unavailable("Sale value is out of range; material quote only.")
    end
    result.saleMin, result.saleMax = saleMin, saleMax
    result.profitMin, result.profitMax = result.saleMin - result.cost, result.saleMax - result.cost
    if result.cost > 0 then
        result.returnMin, result.returnMax = result.profitMin / result.cost * 100, result.profitMax / result.cost * 100
    end
    result.estimated = minimum ~= maximum
    return result
end

function C.Invalidate()
    C.dirty = true
    C.generation = C.generation + 1
end

function C.BeginCatalog()
    C.rows, C.ids, C.cursor, C.ready, C.skipped = {}, {}, 1, false, 0
    C.dirty, C.rankedCache, C.catalogScope = false, {}, "full"
    C.snapshot = D.Snapshot()
    local ids = C.Supported() and Call(C_TradeSkillUI.GetAllRecipeIDs)
    if not U.Table(ids) and C.Supported() then
        ids = Call(C_TradeSkillUI.GetFilteredRecipeIDs)
        C.catalogScope = "filtered"
    end
    if not U.Table(ids) then C.reason = "The full recipe catalog API is unavailable."; C.ready = true; return end
    local seen = {}
    for index, id in ipairs(ids) do
        if index > MAX_RECIPES or not U.Number(id, 1, MAX_ID, true) then
            C.reason = "The recipe catalog is restricted or oversized."; C.ids = {}; C.ready = true; return
        end
        if not seen[id] then C.ids[#C.ids + 1] = id; seen[id] = true end
    end
    C.reason = nil
end

function C.Ranked(mode)
    mode = mode == "return" and "return" or "profit"
    local cache = C.rankedCache and C.rankedCache[mode]
    if cache and cache.rows == C.rows and cache.count == #C.rows then return cache.result end
    local result = {}
    for _, row in ipairs(C.rows) do
        if row.profitMin and row.profitMin > 0 and (mode ~= "return" or row.returnMin) then result[#result + 1] = row end
    end
    table.sort(result, function(a, b)
        local av, bv = mode == "return" and a.returnMin or a.profitMin, mode == "return" and b.returnMin or b.profitMin
        if av == bv then
            if a.name == b.name then return a.recipeID < b.recipeID end
            return a.name < b.name
        end
        return av > bv
    end)
    C.rankedCache = C.rankedCache or {}
    C.rankedCache[mode] = { rows = C.rows, count = #C.rows, result = result }
    return result
end

function C.Tick()
    if A.disabledReason or not D.data or U.Combat() then return end
    local form = C.Form()
    if not form then
        C.wasOpen = false
        if A.CraftingUI then A.CraftingUI.Hide() end
        return
    end
    if not C.wasOpen then C.Invalidate() end
    C.wasOpen = true
    local profession = C.Supported() and Call(C_TradeSkillUI.GetBaseProfessionInfo)
    local professionID = U.Table(profession) and profession.professionID
    if not U.Number(professionID, 1, MAX_ID, true) then professionID = nil end
    if professionID ~= C.professionID then C.professionID = professionID; C.Invalidate() end
    if C.snapshot ~= D.Snapshot() then C.Invalidate() end
    if C.dirty then C.BeginCatalog() end
    if C.ids and not C.ready then
        local start = debugprofilestop and debugprofilestop() or 0
        for _ = 1, 20 do
            local id = C.ids[C.cursor]
            if not id then C.ready = true; break end
            local row = C.Analyze(id, nil, C.snapshot)
            if row then C.rows[#C.rows + 1] = row; if not row.profitMin then C.skipped = C.skipped + 1 end end
            C.cursor = C.cursor + 1
            if debugprofilestop and debugprofilestop() - start >= A.FRAME_BUDGET_MS then break end
        end
    end
    local selected = Call(form.GetRecipeInfo, form)
    C.selected = U.Table(selected) and C.Analyze(selected.recipeID, form) or nil
    if A.CraftingUI then A.CraftingUI.Update(form) end
end
