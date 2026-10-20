local _, A = ...
local U, D, M = A.Util, A.DB, A.Market
local UI = { view = "deals", sort = "return", page = 1, rows = {}, dirty = {} }
A.MarketUI = UI

local function Label(parent, text, x, y, width, right)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y); label:SetSize(width, 16)
    label:SetJustifyH(right and "RIGHT" or "LEFT"); label:SetWordWrap(false); label:SetText(text)
    return label
end

local function Button(parent, text, x, y, width, handler)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y); button:SetSize(width, 24)
    button:SetText(text); button:SetScript("OnClick", handler)
    return button
end

local function Fill(parent, layer, r, g, b, alpha)
    local texture = parent:CreateTexture(nil, layer)
    texture:SetAllPoints(parent); texture:SetColorTexture(r, g, b, alpha)
    return texture
end

-- Keep saved prices in copper. Parse gold decimals without floating-point
-- rounding or accepting exponent notation in a currency box.
function UI.ParseGold(text)
    if not U.String(text) then return nil end
    text = string.match(text, "^%s*(.-)%s*$")
    if #text == 0 or #text > 12 or not string.match(text, "^%d*%.?%d*$") then return nil end
    local whole, fraction = string.match(text, "^(%d*)%.(%d*)$")
    if not whole then whole, fraction = text, "" end
    if whole == "" and fraction == "" or #fraction > 4 then return nil end
    local copper = (tonumber(whole) or 0) * 10000 + (tonumber(fraction .. string.rep("0", 4 - #fraction)) or 0)
    if U.Number(copper, 0, 100000000, true) then return copper end
end

function UI.GoldText(copper)
    local fraction = string.gsub(string.format("%04d", copper % 10000), "0+$", "")
    return tostring(math.floor(copper / 10000)) .. (#fraction > 0 and ("." .. fraction) or "")
end

local fields = {
    { "marketMinReturn", "Min return %", 10, -26, 0, 1000 },
    { "marketMinProfit", "Min profit (g)", 210, -26, 0, 10000 },
    { "marketFee", "AH cut %", 410, -26, 0, 30 },
    { "marketLookback", "Lookback days", 10, -71, 1, 30 },
    { "marketMinDays", "Min priced days", 210, -71, 2, 29 },
    { "marketMove", "Price move %", 410, -71, 0, 1000 },
}

local function AppliedText(key)
    local value = D.Settings()[key]
    return key == "marketMinProfit" and UI.GoldText(value) or tostring(value)
end

function UI.Apply()
    if not D.data or U.Combat() then return false end
    local values = {}
    for _, field in ipairs(fields) do
        local text = UI.inputs[field[1]]:GetText()
        local value
        if field[1] == "marketMinProfit" then value = UI.ParseGold(text) else value = tonumber(text) end
        if not U.Number(value, field[5], field[1] == "marketMinProfit" and 100000000 or field[6], true) then
            UI.message = field[1] == "marketMinProfit" and "Min profit: enter 0-10000 gold, with up to 4 decimal places (0.25 = 25s)." or
                (field[2] .. " must be a whole number from " .. field[5] .. " to " .. field[6] .. ".")
            UI.Refresh(); return false
        end
        values[field[1]] = value
    end
    if values.marketMinDays > values.marketLookback then
        UI.message = "Min priced days cannot exceed lookback days."; UI.Refresh(); return false
    end
    for key, value in pairs(values) do D.data.settings[key] = value; UI.inputs[key]:ClearFocus() end
    UI.message, UI.page, UI.selected, UI.dirty = nil, 1, nil, {}
    M.Ensure(UI.view, UI.sort); UI.Refresh()
    return true
end

local function Message(text)
    UI.message = text; UI.Refresh()
    if UI.panel and not UI.panel:IsShown() then U.Print(text) end
    return false
end

local function NativeKey(row)
    if not C_AuctionHouse or type(C_AuctionHouse.MakeItemKey) ~= "function" or
       type(C_AuctionHouse.GetItemKeyInfo) ~= "function" then return nil end
    local suffix = row.suffix or 0
    local function Read(level)
        local ok, key = pcall(C_AuctionHouse.MakeItemKey, row.id, level, suffix, 0)
        if not ok or not U.Table(key) or not U.Number(key.itemID, 1, 2147483647, true) or key.itemID ~= row.id or
           not U.Number(key.itemLevel, 0, 100000, true) or key.itemLevel ~= level or
           not U.Number(key.itemSuffix, -2147483647, 2147483647, true) or key.itemSuffix ~= suffix or
           not U.Number(key.battlePetSpeciesID, 0, 0, true) then return nil end
        local read, info = pcall(C_AuctionHouse.GetItemKeyInfo, key)
        if not read or not U.Table(info) or not U.Accessible(info.isCommodity) or type(info.isCommodity) ~= "boolean" or
           not U.Accessible(info.isEquipment) or type(info.isEquipment) ~= "boolean" or
           not U.String(info.itemName) or info.itemName == "" then return nil end
        return key, info
    end
    local key, info = Read(0)
    if info and info.isEquipment then
        local item = A.Valuation.ItemInfo(row.link)
        if not item or item.level == 0 then return nil end
        key, info = Read(item.level)
    end
    if info and info.isCommodity and suffix ~= 0 then return nil end
    return key, info
end

-- Only a row's left-click handler calls this. Analysis and refreshes never
-- request live listings. The native AH owns searches and purchase controls.
function UI.OpenListings(row)
    if U.Combat() then return Message("Open live listings outside combat.") end
    if next(UI.dirty) then return Message("Apply your filter changes before opening live listings.") end
    local ah, modes = AuctionHouseFrame, AuctionHouseFrameDisplayMode
    if not A.auctionOpen or not U.Table(ah) or not ah.IsShown or not ah:IsShown() or
       (ah.IsForbidden and ah:IsForbidden()) then return Message("Open the auction house to view live listings.") end
    if (A.Scanner.active or A.Scanner.paused) and not A.Scanner.localReady then
        return Message("Wait for the scan's local copy to finish before opening live listings.")
    end
    local snapshot = D.Snapshot()
    if M.job or M.snapshot ~= snapshot or M.key ~= U.MarketKey() or not snapshot or
       not U.Number(snapshot.startedAt, 0, U.Now()) or D.IsStale(snapshot) then
        return Message("Wait for current results, then choose the item again.")
    end
    local found = false
    for _, candidate in ipairs(M.rows) do if candidate == row then found = true; break end end
    if not found then return Message("Choose an item from the current results.") end
    if C_AuctionHouse and type(C_AuctionHouse.IsThrottledMessageSystemReady) == "function" then
        local ok, ready = pcall(C_AuctionHouse.IsThrottledMessageSystemReady)
        if not ok or not U.Accessible(ready) or ready ~= true then return Message("Auction house is busy. Try the item again shortly.") end
    end
    if UI.lastSearch and U.Mono() - UI.lastSearch < 0.5 then return Message("Please wait a moment before opening another item.") end
    if not U.Table(modes) or not modes.Buy or type(ah.SetDisplayMode) ~= "function" then
        return Message("The native Buy page is unavailable on this client.")
    end
    local key, info = NativeKey(row)
    local contexts = AuctionHouseSearchContext
    local context = info and U.Table(contexts) and (info.isCommodity and contexts.BuyCommodities or contexts.BuyItems)
    if key and U.Accessible(context) and context and type(ah.SelectBrowseResult) == "function" and type(ah.QueryItem) == "function" then
        UI.lastSearch, UI.message = U.Mono(), nil
        local ok = pcall(function()
            ah:SetDisplayMode(modes.Buy)
            ah:SelectBrowseResult({ itemKey = key, minPrice = row.buy })
            if type(ah.SetSearchText) == "function" then ah:SetSearchText(info.itemName) end
            ah:QueryItem(context, key)
        end)
        if not ok then return Message("Could not open live listings. Use the native Buy search and try again.") end
        return true
    end
    -- Changed native APIs can still offer the ordinary name search.
    local item, bar = A.Valuation.ItemInfo(row.link), ah.SearchBar
    if not item or not U.Table(bar) or type(bar.SetSearchText) ~= "function" or type(bar.StartSearch) ~= "function" then
        return Message("Item search is not ready. Wait for item details, or use the native Buy search.")
    end
    UI.lastSearch, UI.message = U.Mono(), nil
    local ok = pcall(function()
        ah:SetDisplayMode(modes.Buy); bar:SetSearchText(item.name); bar:StartSearch()
    end)
    if not ok then return Message("Could not start the native Buy search. Try searching there directly.") end
    return true
end

local function Highlight(button)
    if button.row and (button.hovered or button.row == UI.selected) then button.highlight:Show() else button.highlight:Hide() end
end

function UI.Create(parent)
    if UI.panel then return UI.panel end
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -34)
    panel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, 33)
    UI.panel = panel
    Label(panel, "Market opportunities", 14, -10, 400):SetFontObject("GameFontNormal")
    UI.age = Label(panel, "", 14, -31, 746)
    UI.views = {}
    local names = { { "deals", "Resale" }, { "rising", "Rising" }, { "falling", "Falling" }, { "all", "All signals" } }
    for index, data in ipairs(names) do
        local view = data[1]
        local button = Button(panel, data[2], 14 + (index - 1) * 96, -53, 90, function()
            UI.view, UI.page, UI.selected, UI.message = view, 1, nil, nil
            M.Ensure(UI.view, UI.sort); UI.Refresh()
        end)
        button.caption = data[2]; UI.views[view] = button
    end
    UI.sortButton = Button(panel, "Sort: return", 410, -53, 139, function()
        UI.sort = UI.sort == "return" and "profit" or "return"
        UI.page, UI.selected = 1, nil; M.Ensure(UI.view, UI.sort); UI.Refresh()
    end)
    UI.recheck = Button(panel, "Recheck saved scan", 559, -53, 201, function()
        UI.page, UI.selected = 1, nil; M.Ensure(UI.view, UI.sort, true); UI.Refresh()
    end)
    local filters = CreateFrame("Frame", nil, panel, "InsetFrameTemplate")
    filters:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -84); filters:SetSize(746, 99)
    Label(filters, "Profit targets", 10, -7, 500):SetFontObject("GameFontNormalSmall")
    Label(filters, "History & movement", 10, -52, 500):SetFontObject("GameFontNormalSmall")
    UI.inputs = {}
    for _, field in ipairs(fields) do
        local key = field[1]
        Label(filters, field[2], field[3], field[4] - 3, 100)
        local box = CreateFrame("EditBox", nil, filters, "InputBoxTemplate")
        box:SetPoint("TOPLEFT", filters, "TOPLEFT", field[3] + 108, field[4] + 3)
        box:SetSize(64, 24); box:SetAutoFocus(false); box:SetNumeric(key ~= "marketMinProfit"); box:SetMaxLetters(12)
        box:SetScript("OnEnterPressed", UI.Apply)
        box:SetScript("OnTextChanged", function(_, userInput)
            if userInput then UI.dirty[key], UI.message = true, nil; UI.Refresh() end
        end)
        box:SetScript("OnEscapePressed", function(self)
            UI.dirty[key], UI.message = nil, nil; self:ClearFocus(); self:SetText(AppliedText(key)); UI.Refresh()
        end)
        UI.inputs[key] = box
    end
    UI.apply = Button(filters, "Apply filters", 618, -19, 114, UI.Apply)
    Label(filters, "0.25g = 25s", 618, -49, 114)
    Label(filters, "Move: 0 = off", 618, -72, 114)
    local tableFrame = CreateFrame("Frame", nil, panel, "InsetFrameTemplate")
    tableFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -190); tableFrame:SetSize(746, 184)
    local header = CreateFrame("Frame", nil, tableFrame)
    header:SetPoint("TOPLEFT", tableFrame, "TOPLEFT", 3, -3); header:SetSize(740, 21)
    Fill(header, "BACKGROUND", 0.22, 0.18, 0.09, 0.45)
    local columns = { {"Item",7,218}, {"Scan low",229,88}, {"Baseline",321,88},
        {"Net / item",413,102}, {"Return",519,68}, {"Move",591,75}, {"Days",670,61} }
    for index, column in ipairs(columns) do Label(header, column[1], column[2], -3, column[3], index > 1):SetFontObject("GameFontNormalSmall") end
    for index = 1, 7 do
        local button = CreateFrame("Button", nil, tableFrame)
        button:SetPoint("TOPLEFT", tableFrame, "TOPLEFT", 3, -25 - (index - 1) * 22); button:SetSize(740, 22)
        Fill(button, "BACKGROUND", 0.12, 0.13, 0.15, index % 2 == 0 and 0.5 or 0.15)
        button.highlight = Fill(button, "ARTWORK", 0.72, 0.55, 0.20, 0.18); button.highlight:Hide()
        button:RegisterForClicks("LeftButtonUp", "RightButtonUp"); button.labels = {}
        for column, data in ipairs(columns) do button.labels[column] = Label(button, "", data[2], -3, data[3], column > 1) end
        button:SetScript("OnClick", function(self, mouse)
            UI.selected = self.row; UI.Refresh()
            if mouse == "LeftButton" then UI.OpenListings(self.row) end
        end)
        button:SetScript("OnEnter", function(self)
            self.hovered = true; UI.hovered = self.row; Highlight(self); UI.RefreshDetails()
            if self.row and GameTooltip and type(GameTooltip.SetHyperlink) == "function" then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetHyperlink(self.row.link); GameTooltip:Show()
            end
        end)
        button:SetScript("OnLeave", function(self)
            self.hovered, UI.hovered = nil, nil; Highlight(self); UI.RefreshDetails()
            if GameTooltip then GameTooltip:Hide() end
        end)
        UI.rows[index] = button
    end
    local details = CreateFrame("Frame", nil, panel, "InsetFrameTemplate")
    details:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -380); details:SetSize(746, 40)
    UI.detail = Label(details, "", 10, -6, 726); UI.detail:SetHeight(29); UI.detail:SetWordWrap(true)
    UI.previous = Button(panel, "Previous", 14, -424, 100, function() UI.page = math.max(1, UI.page - 1); UI.hovered = nil; UI.Refresh() end)
    UI.pageText = Label(panel, "", 127, -429, 500)
    UI.next = Button(panel, "Next", 660, -424, 100, function() UI.page = UI.page + 1; UI.hovered = nil; UI.Refresh() end)
    UI.status = Label(panel, "", 14, -451, 746)
    panel:SetScript("OnShow", function() M.Ensure(UI.view, UI.sort); UI.Refresh() end)
    panel:SetScript("OnHide", function() UI.hovered = nil; if GameTooltip then GameTooltip:Hide() end end)
    panel:Hide()
    return panel
end

function UI.RefreshDetails()
    if not UI.detail then return end
    local row = UI.hovered or UI.selected
    if row then
        local target = row.maxBuy > 0 and ("For your profit targets, buy at " .. U.Money(row.maxBuy) .. " or less.") or "No positive buy price meets both profit targets."
        local text = target .. " Prior range: " .. U.Money(row.low) .. " - " .. U.Money(row.high) .. "."
        if row.trend then text = text .. string.format(" Recent trend: %+.0f%%.", row.trend) end
        UI.detail:SetText(text)
    else UI.detail:SetText("Left-click an item to open live listings. Right-click for details; hover for its tooltip. Values are per item.") end
end

function UI.Refresh()
    if not UI.panel then return end
    local snapshot = M.snapshot or D.Snapshot()
    local history = A.History.Status()
    UI.age:SetText((snapshot and ("Scan: " .. U.Age(snapshot.startedAt) .. (D.IsStale(snapshot) and " (stale)" or "")) or "No saved scan") ..
        "  |  " .. history.days .. " saved UTC days  |  Baseline: prior daily lower quartile")
    local combat = U.Combat()
    for key, button in pairs(UI.views) do
        button:SetText((key == UI.view and "|cffffd100" or "|cffffffff") .. button.caption .. "|r")
        button:SetEnabled(not combat)
    end
    for _, field in ipairs(fields) do
        local box = UI.inputs[field[1]]
        if not box:HasFocus() and not UI.dirty[field[1]] then box:SetText(AppliedText(field[1])) end
    end
    UI.apply:SetEnabled(not combat); UI.recheck:SetEnabled(not combat and not M.job and not next(UI.dirty))
    UI.sortButton:SetText((UI.view == "rising" or UI.view == "falling") and "Sort: movement" or ("Sort: " .. UI.sort))
    UI.sortButton:SetEnabled(not combat and UI.view ~= "rising" and UI.view ~= "falling")
    if UI.publication ~= M.publications or not M.snapshot then
        UI.selected, UI.hovered, UI.publication = nil, nil, M.publications
    end
    local pages = math.max(1, math.ceil(#M.rows / 7))
    UI.page = math.max(1, math.min(UI.page, pages))
    for index, button in ipairs(UI.rows) do
        local row = M.rows[(UI.page - 1) * 7 + index]
        button.row = row
        if row then
            local texts = { M.Name(row), U.Money(row.current), U.Money(row.baseline), A.CraftingUI.SignedMoney(row.profit),
                string.format("%+.0f%%", row.roi), string.format("%+.0f%%", row.movement), tostring(row.days) }
            for column, value in ipairs(texts) do button.labels[column]:SetText(value) end
            for _, column in ipairs({4,5}) do button.labels[column]:SetTextColor(row.profit > 0 and 0.35 or 1, row.profit > 0 and 0.87 or 0.38, 0.38) end
            button.labels[6]:SetTextColor(row.movement > 0 and 0.35 or 1, row.movement > 0 and 0.87 or 0.65, 0.38)
            button.labels[1]:SetTextColor(row == UI.selected and 1 or 0.90, row == UI.selected and 0.82 or 0.89, row == UI.selected and 0.25 or 0.84)
            Highlight(button); button:Show()
        else button:Hide() end
    end
    UI.RefreshDetails()
    UI.previous:SetEnabled(UI.page > 1); UI.next:SetEnabled(UI.page < pages)
    UI.pageText:SetText(string.format("%d matches | Page %d / %d%s", M.eligible or 0, UI.page, pages, (M.eligible or 0) > 200 and " | Best 200 shown" or ""))
    UI.status:SetText(UI.message or (next(UI.dirty) and "Changes not applied. Click Apply filters or press Enter; Esc restores the focused field.") or
        (M.job and ((M.job.phase == "variants" and ("Checking history variants: " .. (M.job.prepared or 0)) or ("Checking saved prices: " .. M.job.examined)) .. ". Previous results remain until ready.") or M.reason) or
        (M.truncated and "Large dataset: first 50,000 price entries checked." or "Resale requires the minimum price drop. Estimates exclude deposits and unsold stock."))
end

function UI.Show()
    if U.Combat() then return U.Print("Open market opportunities outside combat.") end
    if not A.auctionOpen or not A.UI.InstallAuctionTab() then return U.Print("Open market opportunities at an auctioneer.") end
    A.UI.tabLibrary:SetSelected("MSMarketOpportunities")
end
