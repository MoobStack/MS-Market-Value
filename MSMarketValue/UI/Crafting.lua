local _, A = ...
local U, D, C = A.Util, A.DB, A.Crafting
local UI = { mode = "recipe", sort = "profit", page = 1, search = "" }
A.CraftingUI = UI

local function Label(parent, text, x, y, width, font)
    local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y); label:SetSize(width, 16)
    label:SetJustifyH("LEFT"); label:SetWordWrap(false); label:SetText(text)
    return label
end

local function Button(parent, text, x, y, width, handler)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y); button:SetSize(width, 26)
    button:SetText(text); button:SetScript("OnClick", handler)
    return button
end

local function Inset(parent, y, height)
    local inset = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
    inset:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, y); inset:SetSize(536, height)
    return inset
end

local function Fill(parent, r, g, b, alpha)
    local texture = parent:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints(parent); texture:SetColorTexture(r, g, b, alpha)
    return texture
end

function UI.SignedMoney(value)
    return (value < 0 and "-" or "+") .. U.Money(math.abs(value))
end

local function ChatOpener()
    if U.Table(ChatFrameUtil) and type(ChatFrameUtil.OpenChat) == "function" then return ChatFrameUtil.OpenChat end
    if type(ChatFrame_OpenChat) == "function" then return ChatFrame_OpenChat end
end

function UI.InsertQuote()
    if U.Combat() or not C.Form() or not UI.quoteText then return end
    local open = ChatOpener()
    if not open then return U.Print("Copy the quote text; the chat editor is unavailable.") end
    open(UI.quoteText) -- A draft only; the player chooses when and where to send it.
end

local function Range(a, b, formatter)
    if a == nil then return "Unavailable" end
    if a == b then return formatter(a) end
    return formatter(a) .. " - " .. formatter(b)
end

local function Return(value) return string.format("%+.1f%%", value) end

function UI.RecipeState(row)
    if row.service then return "service", "Service - material quote" end
    if row.profitMin ~= nil then return "priced", row.profitMin > 0 and "Profitable" or (row.profitMin < 0 and "Loss at scan price" or "Break even before fees") end
    if #(row.missing or {}) > 0 then return "missing", "Material prices missing: " .. #row.missing end
    if row.outputID and row.cost ~= nil then return "missing", "No output buyout in the scan" end
    if row.quote ~= nil then return "quote", "Material quote only" end
    return "missing", "Select for details"
end

function UI.SetSearch(text)
    if not U.String(text) or #text > 256 then return end
    UI.search, UI.page = string.lower(string.match(text, "^%s*(.-)%s*$")), 1
    UI.Refresh()
end

-- Filter published rows locally. Repeated UI ticks reuse both the ranking and
-- this single-view cache; changing search never rebuilds recipe valuations.
function UI.CatalogView()
    if UI.searchProfession ~= C.professionID then
        UI.searchProfession, UI.search, UI.page = C.professionID, "", 1
        if UI.searchBox then UI.searchBox:SetText("") end
    end
    local source = C.Ranked(UI.sort, D.Settings().showAllRecipes)
    local cache = UI.filtered
    if cache and cache.source == source and cache.count == #source and cache.query == UI.search then return cache.rows end
    local rows = source
    if UI.search ~= "" then
        rows = {}
        for _, row in ipairs(source) do
            if string.find(string.lower(row.name), UI.search, 1, true) then rows[#rows + 1] = row end
        end
    end
    UI.filtered = { source = source, count = #source, query = UI.search, rows = rows }
    return rows
end

function UI.CatalogSummary()
    local cache = UI.summary
    if cache and cache.source == C.rows and cache.count == #C.rows then return cache end
    cache = { source = C.rows, count = #C.rows, priced = 0, services = 0, quotes = 0, missing = 0 }
    for _, row in ipairs(C.rows) do
        local state = UI.RecipeState(row)
        local key = state == "priced" and "priced" or (state == "service" and "services" or (state == "quote" and "quotes" or "missing"))
        cache[key] = cache[key] + 1
    end
    UI.summary = cache
    return cache
end

local function HideTooltip() if GameTooltip then GameTooltip:Hide() end end
local function RecipeTooltip(button)
    local row = button.row
    if not row or not GameTooltip then return end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT"); GameTooltip:ClearLines()
    GameTooltip:AddLine(row.name, 1, 0.82, 0)
    local _, state = UI.RecipeState(row)
    GameTooltip:AddLine(state, 0.83, 0.86, 0.89, true)
    if row.cost ~= nil then GameTooltip:AddDoubleLine("Materials / craft", U.Money(row.cost)) end
    if row.service and row.cost ~= nil then
        -- Catalog quotes follow the current markup without repricing recipes.
        GameTooltip:AddDoubleLine("Quote / service", U.Money(C.Quote(row.cost, D.Settings().quoteMarkup)))
    elseif row.profitMin ~= nil then
        GameTooltip:AddDoubleLine("Gross profit / craft", Range(row.profitMin, row.profitMax, UI.SignedMoney))
    end
    if row.reason and not row.service then GameTooltip:AddLine(row.reason, 0.83, 0.86, 0.89, true) end
    GameTooltip:AddLine("Click to select this recipe.", 0.65, 0.65, 0.65)
    GameTooltip:Show()
end

function UI.ApplyMarkup()
    if not D.data or U.Combat() then return false end
    local value = tonumber(UI.markup:GetText())
    if not U.Number(value, 0, 1000, true) then U.Print("Choose a markup from 0 to 1000 percent."); return false end
    D.data.settings.quoteMarkup = value; UI.markup:ClearFocus()
    if C.selected and C.selected.cost then C.selected.quote = C.Quote(C.selected.cost, value) end
    UI.Refresh(); return true
end

function UI.Create()
    if UI.frame or U.Combat() then return end
    local frame = CreateFrame("Frame", "MSMarketValueCrafting", UIParent, "PortraitFrameTemplate")
    frame:SetSize(560, 650); frame:SetPoint("TOPLEFT", ProfessionsFrame, "TOPRIGHT", 6, 0)
    frame:SetClampedToScreen(true); frame:SetFrameStrata("DIALOG"); frame:SetTitle("MS Market Value - Crafting")
    if frame.PortraitContainer and frame.PortraitContainer.portrait then
        frame.PortraitContainer.portrait:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
    end
    frame:EnableMouse(true); frame:SetMovable(true); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) if not U.Combat() then self:StartMoving() end end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame.CloseButton:SetScript("OnClick", function() UI.suppressed = true; frame:Hide() end)
    frame:SetScript("OnHide", function()
        if C.Form() then UI.suppressed = true end
        if UI.opener then UI.opener:SetText("Show profits") end
        HideTooltip()
    end)
    frame:SetScript("OnShow", function() if UI.opener then UI.opener:SetText("Hide profits") end end)
    table.insert(UISpecialFrames, "MSMarketValueCrafting")
    UI.frame = frame
    UI.age = Label(frame, "", 72, -38, 470)
    UI.recipeTab = Button(frame, "Selected recipe", 16, -61, 156, function() UI.mode = "recipe"; UI.Refresh() end)
    UI.profitTab = Button(frame, "Recipe list", 181, -61, 174, function() UI.mode = "profit"; UI.Refresh() end)
    UI.showAllButton = Button(frame, "Show all recipes", 368, -61, 176, function()
        if U.Combat() or not D.data then return end
        D.data.settings.showAllRecipes = not D.Settings().showAllRecipes; UI.page = 1; UI.Refresh()
    end)

    local details = CreateFrame("Frame", nil, frame)
    details:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -95); details:SetSize(560, 514); UI.details = details
    local summary = Inset(details, 0, 194)
    UI.recipeName = Label(summary, "Select a learned recipe", 14, -11, 507, "GameFontNormal")
    UI.recipeName:SetHeight(30); UI.recipeName:SetWordWrap(true)
    UI.yield = Label(summary, "", 14, -43, 507)
    UI.values, UI.valueLabels = {}, {}
    local labels = { "Materials / craft", "Cost / item", "Sale / craft", "Gross profit / craft", "Return on cost" }
    for index, name in ipairs(labels) do
        local y = -69 - (index - 1) * 23
        UI.valueLabels[index] = Label(summary, name, 14, y, 190)
        UI.values[index] = Label(summary, "", 202, y, 318); UI.values[index]:SetJustifyH("RIGHT")
    end
    UI.serviceHelp = Label(summary, "", 14, -126, 507)
    UI.serviceHelp:SetHeight(51); UI.serviceHelp:SetWordWrap(true)
    local quotes = Inset(details, -204, 96)
    Label(quotes, "Craft quote", 14, -12, 186, "GameFontNormal")
    Label(quotes, "Markup", 273, -15, 60)
    local markup = CreateFrame("EditBox", nil, quotes, "InputBoxTemplate")
    markup:SetPoint("TOPLEFT", quotes, "TOPLEFT", 340, -8); markup:SetSize(50, 24)
    markup:SetAutoFocus(false); markup:SetNumeric(true); markup:SetMaxLetters(4)
    markup:SetText(tostring(D.Settings().quoteMarkup)); UI.markup = markup
    Label(quotes, "%", 394, -15, 15)
    markup:SetScript("OnEnterPressed", UI.ApplyMarkup)
    markup:SetScript("OnEscapePressed", function(self) self:ClearFocus(); self:SetText(tostring(D.Settings().quoteMarkup)) end)
    UI.applyMarkup = Button(quotes, "Apply", 421, -8, 99, UI.ApplyMarkup)
    local quote = CreateFrame("EditBox", nil, quotes, "InputBoxTemplate")
    quote:SetPoint("TOPLEFT", quotes, "TOPLEFT", 20, -42); quote:SetSize(499, 23)
    quote:SetAutoFocus(false); quote:SetMaxLetters(1500)
    quote:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    quote:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    UI.quoteBox = quote
    Label(quotes, "Materials + markup. Ctrl+C to copy.", 14, -73, 350)
    UI.insertQuote = Button(quotes, "Insert in chat", 383, -67, 137, UI.InsertQuote)
    local materials = Inset(details, -310, 164)
    Label(materials, "Materials", 14, -10, 507, "GameFontNormal")
    Label(materials, "Reagent", 14, -30, 230, "GameFontNormalSmall")
    Label(materials, "Qty", 256, -30, 35, "GameFontNormalSmall"):SetJustifyH("RIGHT")
    Label(materials, "Source", 305, -30, 80, "GameFontNormalSmall")
    Label(materials, "Total", 391, -30, 111, "GameFontNormalSmall"):SetJustifyH("RIGHT")
    local scroll = CreateFrame("ScrollFrame", nil, materials, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", materials, "TOPLEFT", 14, -51); scroll:SetPoint("BOTTOMRIGHT", materials, "BOTTOMRIGHT", -31, 12)
    local child = CreateFrame("Frame", nil, scroll); child:SetSize(490, 98); scroll:SetScrollChild(child)
    UI.materialChild, UI.materialRows = child, {}
    UI.reason = Label(details, "", 18, -483, 524); UI.reason:SetHeight(30); UI.reason:SetWordWrap(true)

    local catalog = CreateFrame("Frame", nil, frame)
    catalog:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -95); catalog:SetSize(560, 510); UI.catalog = catalog
    local controls = Inset(catalog, 0, 45)
    Label(controls, "Search", 12, -15, 45)
    UI.searchBox = CreateFrame("EditBox", nil, controls, "InputBoxTemplate")
    UI.searchBox:SetPoint("TOPLEFT", controls, "TOPLEFT", 67, -9); UI.searchBox:SetSize(167, 24)
    UI.searchBox:SetAutoFocus(false); UI.searchBox:SetMaxLetters(64)
    UI.searchBox:SetScript("OnTextChanged", function(self, userInput) if userInput then UI.SetSearch(self:GetText()) end end)
    UI.searchBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    UI.searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus(); self:SetText(""); UI.SetSearch("") end)
    UI.clearSearch = Button(controls, "X", 243, -8, 25, function() UI.searchBox:SetText(""); UI.SetSearch("") end)
    UI.sortProfit = Button(controls, "Profit / craft", 280, -8, 126, function() UI.sort = "profit"; UI.page = 1; UI.Refresh() end)
    UI.sortReturn = Button(controls, "Return %", 414, -8, 108, function() UI.sort = "return"; UI.page = 1; UI.Refresh() end)
    local list = Inset(catalog, -52, 378)
    local header = CreateFrame("Frame", nil, list)
    header:SetPoint("TOPLEFT", list, "TOPLEFT", 4, -4); header:SetSize(528, 22); Fill(header, 0.22, 0.18, 0.09, 0.45)
    Label(header, "Recipe", 10, -3, 275, "GameFontNormalSmall")
    Label(header, "Gross / craft", 285, -3, 129, "GameFontNormalSmall"):SetJustifyH("RIGHT")
    Label(header, "Return", 420, -3, 94, "GameFontNormalSmall"):SetJustifyH("RIGHT")
    UI.catalogRows = {}
    for index = 1, 8 do
        local row = CreateFrame("Button", nil, list)
        row:SetPoint("TOPLEFT", list, "TOPLEFT", 10, -31 - (index - 1) * 38); row:SetSize(516, 36)
        Fill(row, 0.12, 0.13, 0.15, index % 2 == 0 and 0.5 or 0.15)
        row.highlight = Fill(row, 0.72, 0.55, 0.20, 0.18); row.highlight:Hide()
        row.name = Label(row, "", 9, -3, 266)
        row.note = Label(row, "", 9, -19, 266); row.note:SetTextColor(0.61, 0.66, 0.70)
        row.profit = Label(row, "", 279, -11, 125); row.profit:SetJustifyH("RIGHT")
        row.percent = Label(row, "", 410, -11, 97); row.percent:SetJustifyH("RIGHT")
        row:SetScript("OnEnter", function(self) self.highlight:Show(); RecipeTooltip(self) end)
        row:SetScript("OnLeave", function(self) self.highlight:Hide(); HideTooltip() end)
        row:SetScript("OnClick", function(self)
            if U.Combat() or not self.recipeID or not C.Form() or not C_TradeSkillUI then return end
            C.Call(C_TradeSkillUI.OpenRecipe, self.recipeID); HideTooltip()
            UI.mode = "recipe"; C.Tick(); UI.Refresh()
        end)
        UI.catalogRows[index] = row
    end
    UI.pageText = Label(list, "", 14, -348, 272)
    UI.previous = Button(list, "Previous", 303, -341, 104, function() UI.page = math.max(1, UI.page - 1); HideTooltip(); UI.Refresh() end)
    UI.next = Button(list, "Next", 416, -341, 104, function() UI.page = UI.page + 1; HideTooltip(); UI.Refresh() end)
    local status = Inset(catalog, -438, 63)
    UI.catalogStatus = Label(status, "", 12, -9, 512)
    UI.catalogNote = Label(status, "", 12, -29, 512); UI.catalogNote:SetHeight(28); UI.catalogNote:SetWordWrap(true)
    UI.empty = Label(list, "", 22, -124, 492); UI.empty:SetHeight(68); UI.empty:SetWordWrap(true)
    Label(frame, "Craft profit is before AH fees. Quotes are materials + markup.\nScan prices are asking prices; a sale is not guaranteed.", 18, -616, 524):SetHeight(28)
    frame:Hide()
end

function UI.RefreshMaterials(row)
    local count = row and #row.materials or 0
    for index = 1, math.max(count, #UI.materialRows) do
        local button = UI.materialRows[index]
        if not button then
            button = CreateFrame("Button", nil, UI.materialChild)
            button:SetPoint("TOPLEFT", UI.materialChild, "TOPLEFT", 0, -(index - 1) * 26); button:SetSize(490, 26)
            Fill(button, 0.12, 0.13, 0.15, index % 2 == 0 and 0.5 or 0.15)
            button.name = Label(button, "", 0, -4, 230)
            button.quantity = Label(button, "", 242, -4, 35); button.quantity:SetJustifyH("RIGHT")
            button.source = Label(button, "", 291, -4, 80)
            button.total = Label(button, "", 377, -4, 111); button.total:SetJustifyH("RIGHT")
            button:SetScript("OnEnter", function(self)
                if self.material and GameTooltip and type(GameTooltip.SetHyperlink) == "function" then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetHyperlink("item:" .. self.material.id); GameTooltip:Show()
                end
            end)
            button:SetScript("OnLeave", HideTooltip); UI.materialRows[index] = button
        end
        local material = row and row.materials[index]; button.material = material
        if material then
            button.name:SetText(material.name); button.quantity:SetText(tostring(material.quantity))
            button.source:SetText(material.mode == "vendor" and "Vendor" or (material.mode == "vendor-unseen" and "Visit supplier" or (material.total ~= nil and "AH low" or "Missing")))
            button.source:SetTextColor(material.total ~= nil and 0.70 or 1, material.total ~= nil and 0.75 or 0.65, 0.38)
            button.total:SetText(material.total ~= nil and U.Money(material.total) or "Unavailable"); button:Show()
        else button:Hide() end
    end
    UI.materialChild:SetHeight(math.max(98, count * 26))
end

function UI.Refresh()
    if not UI.frame then return end
    local snapshot = UI.mode == "profit" and C.publishedSnapshot or D.Snapshot()
    UI.age:SetText(snapshot and ("Price scan: " .. U.Age(snapshot.startedAt) .. (D.IsStale(snapshot) and " (stale)" or "")) or "No complete price scan for this market")
    UI.recipeTab:SetText((UI.mode == "recipe" and "|cffffd100" or "|cffffffff") .. "Selected recipe|r")
    UI.profitTab:SetText((UI.mode == "profit" and "|cffffd100" or "|cffffffff") .. "Recipe list|r")
    UI.applyMarkup:SetEnabled(not U.Combat())
    if UI.mode == "recipe" then
        UI.details:Show(); UI.catalog:Hide(); UI.showAllButton:Hide()
        local row = C.selected
        local service = row and row.service
        UI.recipeName:SetText(row and row.name or "Select a learned recipe")
        UI.yield:SetText(service and "Service - quote per application" or (row and row.quantityMin and ("Output per craft: " .. (row.quantityMin == row.quantityMax and tostring(row.quantityMin) or (row.quantityMin .. "-" .. row.quantityMax))) or ""))
        local values = {
            row and row.cost and U.Money(row.cost) or "Unavailable",
            service and row.quote and U.Money(row.quote) or (row and Range(row.unitCostMin, row.unitCostMax, U.Money) or "Unavailable"),
            row and Range(row.saleMin, row.saleMax, U.Money) or "Unavailable",
            row and Range(row.profitMin, row.profitMax, UI.SignedMoney) or "Unavailable",
            row and row.cost == 0 and "No material cost" or (row and Range(row.returnMin, row.returnMax, Return) or "Unavailable"),
        }
        UI.valueLabels[1]:SetText(service and "Materials / service" or "Materials / craft")
        UI.valueLabels[2]:SetText(service and "Quote / service" or "Cost / item")
        for index, value in ipairs(values) do
            UI.values[index]:SetText(value)
            if service and index > 2 then UI.values[index]:Hide(); UI.valueLabels[index]:Hide()
            else UI.values[index]:Show(); UI.valueLabels[index]:Show() end
            local profit = row and row.profitMin
            if index >= 4 and profit then
                UI.values[index]:SetTextColor(profit >= 0 and 0.35 or 1, profit >= 0 and 0.87 or 0.38, 0.38)
            else UI.values[index]:SetTextColor(0.83, 0.86, 0.89) end
        end
        UI.serviceHelp:SetText(service and "This recipe applies a service rather than creating an auction item.\nUse the material quote and markup below to set your price." or "")
        if service then UI.serviceHelp:Show() else UI.serviceHelp:Hide() end
        local quoteText = C.QuoteText(row)
        if UI.quoteText ~= quoteText or UI.quoteRecipeID ~= (row and row.recipeID) then UI.quoteBox:ClearFocus() end
        UI.quoteRecipeID, UI.quoteText = row and row.recipeID, quoteText
        UI.insertQuote:SetEnabled(quoteText ~= nil and ChatOpener() ~= nil and not U.Combat())
        if not UI.quoteBox:HasFocus() then UI.quoteBox:SetText(quoteText or "Quote unavailable until all material prices are known") end
        UI.RefreshMaterials(row)
        UI.reason:SetText(service and (quoteText and "Service quote ready. Auction profit does not apply." or "Service quote unavailable. Check material cost and markup.") or
            (row and row.reason or (row and row.estimated and "Variable output: profit shows the minimum and maximum yield." or "")))
    else
        UI.details:Hide(); UI.catalog:Show(); UI.showAllButton:Show()
        local showAll = D.Settings().showAllRecipes
        UI.showAllButton:SetText(showAll and "Profitable only" or "Show all recipes")
        UI.sortProfit:SetText(UI.sort == "profit" and "|cffffd100Profit / craft|r" or "Profit / craft")
        UI.sortReturn:SetText(UI.sort == "return" and "|cffffd100Return %|r" or "Return %")
        local rows = UI.CatalogView()
        local pages = math.max(1, math.ceil(#rows / 8)); UI.page = math.max(1, math.min(UI.page, pages))
        for index, button in ipairs(UI.catalogRows) do
            local row = rows[(UI.page - 1) * 8 + index]; button.row = row; button.recipeID = row and row.recipeID or nil
            if row then
                local _, state = UI.RecipeState(row)
                button.name:SetText(row.name); button.note:SetText(state)
                button.profit:SetText(row.service and "Quote only" or (row.profitMin and UI.SignedMoney(row.profitMin) or "Unavailable"))
                button.percent:SetText(row.service and "Service" or (row.returnMin and Return(row.returnMin) or (row.cost == 0 and "No cost" or "Unavailable")))
                local r, g, b = 0.61, 0.66, 0.70
                if row.profitMin then r, g, b = row.profitMin >= 0 and 0.35 or 1, row.profitMin >= 0 and 0.87 or 0.38, 0.38 end
                button.profit:SetTextColor(r, g, b); button.percent:SetTextColor(r, g, b); button:Show()
            else button:Hide() end
        end
        UI.pageText:SetText(string.format("%d %s | Page %d / %d", #rows, showAll and "recipes" or "profitable", UI.page, pages))
        UI.previous:SetEnabled(UI.page > 1); UI.next:SetEnabled(UI.page < pages)
        local summary = UI.CatalogSummary()
        UI.catalogStatus:SetText(C.reason or (C.ready and string.format("%d priced | %d services | %d quote-only | %d need data", summary.priced, summary.services, summary.quotes, summary.missing) or
            ("Checking recipes: " .. math.min(C.cursor - 1, #(C.ids or {})) .. " / " .. #(C.ids or {}) .. (#C.rows > 0 and ". Showing the last complete list." or ""))))
        UI.catalogNote:SetText((C.catalogScope == "filtered" and "Uses the profession's current filters. " or "Learned recipes in this profession. ") ..
            (showAll and "Services have quotes, not auction profit. Click a recipe for details." or "Positive gross profit only; services appear under Show all recipes."))
        UI.empty:SetText(UI.search ~= "" and "No matching recipes in this view. Clear the search or try Show all recipes." or
            (#C.rows == 0 and "No learned recipes in the current catalog. Check the profession's filters." or "No profitable recipes with current prices. Try Show all recipes to view services and missing-price details."))
        if #rows == 0 and C.ready and not C.reason then UI.empty:Show() else UI.empty:Hide() end
    end
end

local strataOrder = { BACKGROUND = 1, LOW = 2, MEDIUM = 3, HIGH = 4, DIALOG = 5, FULLSCREEN = 6, FULLSCREEN_DIALOG = 7, TOOLTIP = 8 }

local function UsableFrame(frame)
    return U.Table(frame) and not C.Call(frame.IsForbidden, frame)
end

local function FrameValue(frame, method)
    if not UsableFrame(frame) then return nil end
    return C.Call(frame[method], frame)
end

local function HeaderLayout(native)
    local level, strata = 0, "MEDIUM"
    if not UsableFrame(native) then return level, strata end
    for _, key in ipairs({ "frame", "CraftingPage", "NineSlice", "PortraitContainer", "TitleContainer", "CloseButton" }) do
        local frame = key == "frame" and native or native[key]
        local value = FrameValue(frame, "GetFrameLevel")
        if U.Number(value, 0, 65534, true) then level = math.max(level, value) end
        value = FrameValue(frame, "GetFrameStrata")
        if U.String(value) and strataOrder[value] and strataOrder[value] > strataOrder[strata] then strata = value end
    end
    return level, strata
end

local function AttachToggle()
    local native, page = ProfessionsFrame, ProfessionsFrame.CraftingPage
    if not UI.opener then
        UI.opener = CreateFrame("Button", "MSMarketValueCraftingToggle", page, "UIPanelButtonTemplate")
        UI.opener:SetSize(146, 22)
        UI.opener:SetScript("OnClick", UI.Toggle)
    end
    if UI.nativePage ~= page then
        UI.opener:SetParent(page)
        UI.nativePage = page
        page:HookScript("OnHide", function(self) if UI.nativePage == self then UI.Hide() end end)
    end
    UI.opener:ClearAllPoints()
    if UsableFrame(native.CloseButton) then
        UI.opener:SetPoint("RIGHT", native.CloseButton, "LEFT", -4, 0)
    else
        UI.opener:SetPoint("TOPRIGHT", native, "TOPRIGHT", -45, -4)
    end
    -- The native portrait border and title sit at levels 500 and 510.
    -- Following CraftingPage alone leaves a title-bar button underneath them.
    local level, strata = HeaderLayout(native)
    UI.opener:SetFrameStrata(strata)
    UI.opener:SetFrameLevel(level + 1)
end

function UI.Diagnostics()
    local function Level(frame)
        local value = FrameValue(frame, "GetFrameLevel")
        return U.Number(value, 0, 65535, true) and tostring(value) or "unavailable"
    end
    local visible = FrameValue(UI.opener, "IsVisible")
    local strata = FrameValue(UI.opener, "GetFrameStrata")
    local native = UsableFrame(ProfessionsFrame) and ProfessionsFrame or {}
    local summary = UI.CatalogSummary()
    return "Crafting toggle: " .. (UI.opener and (UI.opener:IsShown() and "shown" or "hidden") or "not created") ..
        "; visible=" .. (type(visible) == "boolean" and tostring(visible) or "unavailable") ..
        "; strata=" .. (U.String(strata) and strata or "unavailable") .. "; level=" .. Level(UI.opener) ..
        "\nProfession header levels: border=" .. Level(native.NineSlice) .. "; title=" .. Level(native.TitleContainer) .. "; page=" .. Level(native.CraftingPage) ..
        "\nCrafting window: " .. (UI.frame and (UI.frame:IsShown() and "shown" or "hidden") or "not created") ..
        string.format("\nRecipe valuation counts: priced=%d; services=%d; quote_only=%d; needs_data=%d", summary.priced, summary.services, summary.quotes, summary.missing)
end

function UI.Update()
    if U.Combat() or not C.Form() then return end
    AttachToggle()
    UI.Create()
    if not UI.frame then return end
    UI.opener:Show()
    if not UI.session then UI.session = true; UI.suppressed = not D.Settings().craftAutoOpen end
    if not UI.suppressed then UI.frame:Show() end
    UI.opener:SetText(UI.frame:IsShown() and "Hide profits" or "Show profits")
    if UI.frame:IsShown() then UI.Refresh() end
end

function UI.Hide()
    UI.session = false
    if UI.frame then UI.frame:Hide() end
    if UI.opener then UI.opener:Hide() end
end

function UI.Show()
    if U.Combat() then return U.Print("Open crafting analysis outside combat.") end
    if not C.Form() then return U.Print("Open a profession and select a learned recipe first.") end
    C.Tick()
    if UI.frame then UI.suppressed = false; UI.frame:Show(); UI.Refresh() end
end

function UI.Toggle()
    if U.Combat() or not C.Form() then return end
    if UI.frame and UI.frame:IsShown() then
        UI.suppressed = true
        UI.frame:Hide()
    else UI.Show() end
end
