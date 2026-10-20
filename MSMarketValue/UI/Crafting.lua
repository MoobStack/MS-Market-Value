local _, A = ...
local U, D, C = A.Util, A.DB, A.Crafting
local UI = { mode = "recipe", sort = "profit", page = 1 }
A.CraftingUI = UI

local function Label(parent, text, x, y, width, font)
    local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetWidth(width)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    return label
end

local function Button(parent, text, x, y, width, handler)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetSize(width, 26)
    button:SetText(text)
    button:SetScript("OnClick", handler)
    return button
end

local function Inset(parent, y, height)
    local inset = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
    inset:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, y)
    inset:SetSize(536, height)
    return inset
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

function UI.Create()
    if UI.frame or U.Combat() then return end
    local frame = CreateFrame("Frame", "MSMarketValueCrafting", UIParent, "PortraitFrameTemplate")
    frame:SetSize(560, 650)
    frame:SetPoint("TOPLEFT", ProfessionsFrame, "TOPRIGHT", 6, 0)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("DIALOG")
    frame:SetTitle("MS Market Value - Crafting")
    if frame.PortraitContainer and frame.PortraitContainer.portrait then
        frame.PortraitContainer.portrait:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
    end
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) if not U.Combat() then self:StartMoving() end end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame.CloseButton:SetScript("OnClick", function() UI.suppressed = true; frame:Hide() end)
    frame:SetScript("OnHide", function()
        if C.Form() then UI.suppressed = true end
        if UI.opener then UI.opener:SetText("Show profits") end
    end)
    frame:SetScript("OnShow", function() if UI.opener then UI.opener:SetText("Hide profits") end end)
    table.insert(UISpecialFrames, "MSMarketValueCrafting")
    UI.frame = frame
    UI.age = Label(frame, "", 18, -38, 524)
    UI.recipeTab = Button(frame, "Selected recipe", 16, -61, 156, function() UI.mode = "recipe"; UI.Refresh() end)
    UI.profitTab = Button(frame, "Recipe list", 181, -61, 174, function() UI.mode = "profit"; UI.Refresh() end)
    UI.showAllButton = Button(frame, "Show all recipes", 368, -61, 176, function()
        if not D.data then return end
        D.data.settings.showAllRecipes = not D.Settings().showAllRecipes
        UI.page = 1
        UI.Refresh()
    end)

    local details = CreateFrame("Frame", nil, frame)
    details:SetPoint("TOPLEFT", 0, -95)
    details:SetSize(560, 500)
    UI.details = details
    local summary = Inset(details, 0, 194)
    UI.recipeName = Label(summary, "Select a learned recipe", 14, -13, 507, "GameFontNormal")
    UI.yield = Label(summary, "", 14, -39, 507)
    UI.values = {}
    local labels = { "Materials / craft", "Cost / item", "Sale / craft", "Gross profit / craft", "Return on cost" }
    for index, name in ipairs(labels) do
        local y = -67 - (index - 1) * 23
        Label(summary, name, 14, y, 190)
        UI.values[index] = Label(summary, "", 202, y, 318)
        UI.values[index]:SetJustifyH("RIGHT")
    end
    local quotes = Inset(details, -204, 96)
    Label(quotes, "Craft quote", 14, -12, 186, "GameFontNormal")
    Label(quotes, "Markup", 273, -15, 60)
    local markup = CreateFrame("EditBox", nil, quotes, "InputBoxTemplate")
    markup:SetPoint("TOPLEFT", 340, -8)
    markup:SetSize(50, 24)
    markup:SetAutoFocus(false)
    markup:SetNumeric(true)
    markup:SetMaxLetters(4)
    markup:SetText(tostring(D.Settings().quoteMarkup))
    Label(quotes, "%", 394, -15, 15)
    local function Apply()
        local value = tonumber(markup:GetText())
        if not D.data or not U.Number(value, 0, 1000, true) then return U.Print("Choose a markup from 0 to 1000 percent.") end
        D.data.settings.quoteMarkup = value
        markup:ClearFocus()
        if C.selected and C.selected.cost then C.selected.quote = C.Quote(C.selected.cost, value) end
        UI.Refresh()
    end
    markup:SetScript("OnEnterPressed", Apply)
    markup:SetScript("OnEscapePressed", function(self) self:ClearFocus(); self:SetText(tostring(D.Settings().quoteMarkup)) end)
    Button(quotes, "Apply", 421, -8, 99, Apply)
    local quote = CreateFrame("EditBox", nil, quotes, "InputBoxTemplate")
    quote:SetPoint("TOPLEFT", 20, -42)
    quote:SetSize(499, 23)
    quote:SetAutoFocus(false)
    quote:SetMaxLetters(1500)
    quote:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    quote:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    UI.quoteBox = quote
    Label(quotes, "Materials + markup. Ctrl+C to copy.", 14, -73, 350)
    UI.insertQuote = Button(quotes, "Insert in chat", 383, -67, 137, UI.InsertQuote)
    local materials = Inset(details, -310, 154)
    Label(materials, "Materials", 14, -12, 507, "GameFontNormal")
    local scroll = CreateFrame("ScrollFrame", nil, materials, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 14, -33)
    scroll:SetPoint("BOTTOMRIGHT", -31, 12)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(478, 120)
    scroll:SetScrollChild(child)
    UI.materialChild, UI.materialRows = child, {}
    UI.reason = Label(details, "", 18, -475, 524)

    local catalog = CreateFrame("Frame", nil, frame)
    catalog:SetPoint("TOPLEFT", 0, -95)
    catalog:SetSize(560, 500)
    UI.catalog = catalog
    local list = Inset(catalog, 0, 428)
    Label(list, "Recipe", 14, -16, 246, "GameFontNormal")
    UI.sortProfit = Button(list, "Profit / craft", 264, -7, 136, function() UI.sort = "profit"; UI.page = 1; UI.Refresh() end)
    UI.sortReturn = Button(list, "Return %", 408, -7, 114, function() UI.sort = "return"; UI.page = 1; UI.Refresh() end)
    UI.catalogRows = {}
    for index = 1, 8 do
        local row = CreateFrame("Button", nil, list, "UIPanelButtonTemplate")
        row:SetPoint("TOPLEFT", 10, -44 - (index - 1) * 42)
        row:SetSize(516, 38)
        row.name = Label(row, "", 9, -7, 240)
        row.name:SetHeight(26)
        row.profit = Label(row, "", 248, -13, 142)
        row.profit:SetJustifyH("RIGHT")
        row.percent = Label(row, "", 397, -13, 108)
        row.percent:SetJustifyH("RIGHT")
        row:SetScript("OnClick", function(self)
            if U.Combat() or not self.recipeID or not C_TradeSkillUI then return end
            C.Call(C_TradeSkillUI.OpenRecipe, self.recipeID)
            UI.mode = "recipe"
            C.Tick()
            UI.Refresh()
        end)
        UI.catalogRows[index] = row
    end
    UI.pageText = Label(list, "", 14, -391, 246)
    UI.previous = Button(list, "Previous", 303, -384, 104, function() UI.page = math.max(1, UI.page - 1); UI.Refresh() end)
    UI.next = Button(list, "Next", 416, -384, 104, function() UI.page = UI.page + 1; UI.Refresh() end)
    UI.catalogStatus = Label(catalog, "", 18, -441, 524)
    UI.catalogNote = Label(catalog, "", 18, -470, 524)
    Label(frame, "Latest AH asking prices; profit is before fees. Owned materials\nuse their market value. A sale is not guaranteed.", 18, -616, 524)
    frame:Hide()
end

function UI.Refresh()
    if not UI.frame then return end
    local snapshot = UI.mode == "profit" and C.publishedSnapshot or D.Snapshot()
    UI.age:SetText(snapshot and ("Price scan: " .. U.Age(snapshot.startedAt) .. (D.IsStale(snapshot) and " (stale)" or "")) or "No complete price scan for this market")
    if UI.mode == "recipe" then
        UI.details:Show(); UI.catalog:Hide()
        UI.showAllButton:Hide()
        local row = C.selected
        UI.recipeName:SetText(row and row.name or "Select a learned recipe")
        UI.yield:SetText(row and row.quantityMin and ("Output per craft: " .. (row.quantityMin == row.quantityMax and tostring(row.quantityMin) or (row.quantityMin .. "-" .. row.quantityMax))) or "")
        local values = {
            row and row.cost and U.Money(row.cost) or "Unavailable",
            row and Range(row.unitCostMin, row.unitCostMax, U.Money) or "Unavailable",
            row and Range(row.saleMin, row.saleMax, U.Money) or "Unavailable",
            row and Range(row.profitMin, row.profitMax, UI.SignedMoney) or "Unavailable",
            row and row.cost == 0 and "No material cost" or (row and Range(row.returnMin, row.returnMax, Return) or "Unavailable"),
        }
        for index, value in ipairs(values) do
            UI.values[index]:SetText(value)
            local profit = row and row.profitMin
            if index >= 4 and profit then
                UI.values[index]:SetTextColor(profit >= 0 and 0.35 or 1, profit >= 0 and 0.87 or 0.38, 0.38)
            else UI.values[index]:SetTextColor(0.83, 0.86, 0.89) end
        end
        local quoteText = C.QuoteText(row)
        if UI.quoteText ~= quoteText or UI.quoteRecipeID ~= (row and row.recipeID) then UI.quoteBox:ClearFocus() end
        UI.quoteRecipeID, UI.quoteText = row and row.recipeID, quoteText
        UI.insertQuote:SetEnabled(quoteText ~= nil and ChatOpener() ~= nil)
        if not UI.quoteBox:HasFocus() then
            UI.quoteBox:SetText(quoteText or "Quote unavailable until all material prices are known")
        end
        local count = row and #row.materials or 0
        for index = 1, math.max(count, #UI.materialRows) do
            local label = UI.materialRows[index]
            if not label then label = Label(UI.materialChild, "", 0, -(index - 1) * 25, 477); UI.materialRows[index] = label end
            local material = row and row.materials[index]
            if material then
                label:SetText(material.quantity .. " x " .. material.name .. "  |  " .. (material.total and U.Money(material.total) or "Price missing") .. (material.mode == "vendor" and "  (vendor)" or (material.mode == "vendor-unseen" and "  (visit supplier)" or ""))); label:Show()
            else label:Hide() end
        end
        UI.materialChild:SetHeight(math.max(115, count * 25))
        UI.reason:SetText(row and row.reason or (row and row.estimated and "Variable output: profit shows the minimum and maximum yield." or ""))
    else
        UI.details:Hide(); UI.catalog:Show()
        UI.showAllButton:Show()
        local showAll = D.Settings().showAllRecipes
        UI.showAllButton:SetText(showAll and "Profitable only" or "Show all recipes")
        local rows = C.Ranked(UI.sort, showAll)
        local pages = math.max(1, math.ceil(#rows / 8))
        UI.page = math.min(UI.page, pages)
        for index, button in ipairs(UI.catalogRows) do
            local row = rows[(UI.page - 1) * 8 + index]
            button.recipeID = row and row.recipeID or nil
            if row then
                button.name:SetText(row.name)
                button.profit:SetText(row.profitMin and UI.SignedMoney(row.profitMin) or "Unavailable")
                button.percent:SetText(row.returnMin and Return(row.returnMin) or (row.cost == 0 and "No cost" or "Unavailable"))
                local r, g, b = 0.61, 0.66, 0.70
                if row.profitMin then
                    r, g, b = row.profitMin >= 0 and 0.35 or 1, row.profitMin >= 0 and 0.87 or 0.38, 0.38
                end
                button.profit:SetTextColor(r, g, b); button.percent:SetTextColor(r, g, b)
                button:Show()
            else button:Hide() end
        end
        UI.pageText:SetText(string.format("%d %s | Page %d / %d", #rows, showAll and "recipes" or "profitable", UI.page, pages))
        UI.previous:SetEnabled(UI.page > 1); UI.next:SetEnabled(UI.page < pages)
        UI.catalogStatus:SetText(C.reason or (C.ready and ("Catalog ready. " .. C.skipped .. " recipes lack a complete valuation.") or ("Checking recipes: " .. math.min(C.cursor - 1, #(C.ids or {})) .. " / " .. #(C.ids or {}) .. (#C.rows > 0 and ". Showing the last complete list." or ""))))
        UI.catalogNote:SetText((C.catalogScope == "filtered" and "Uses the profession's current filters. " or "Learned recipes in this profession. ") .. "Minimum yield sets ranking.\n" .. (showAll and "Unknown values are shown last. Select a recipe for details." or "Only fully priced recipes with a positive profit are shown."))
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
    return "Crafting toggle: " .. (UI.opener and (UI.opener:IsShown() and "shown" or "hidden") or "not created") ..
        "; visible=" .. (type(visible) == "boolean" and tostring(visible) or "unavailable") ..
        "; strata=" .. (U.String(strata) and strata or "unavailable") .. "; level=" .. Level(UI.opener) ..
        "\nProfession header levels: border=" .. Level(native.NineSlice) .. "; title=" .. Level(native.TitleContainer) .. "; page=" .. Level(native.CraftingPage) ..
        "\nCrafting window: " .. (UI.frame and (UI.frame:IsShown() and "shown" or "hidden") or "not created")
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
