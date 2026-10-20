local _, A = ...
local U, D, M = A.Util, A.DB, A.Market
local UI = { view = "deals", sort = "return", page = 1, rows = {} }
A.MarketUI = UI

local function Label(parent, text, x, y, width, right)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetSize(width, 16)
    label:SetJustifyH(right and "RIGHT" or "LEFT")
    if label.SetWordWrap then label:SetWordWrap(false) end
    label:SetText(text)
    return label
end

local function Button(parent, text, x, y, width, handler)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y); button:SetSize(width, 25)
    button:SetText(text); button:SetScript("OnClick", handler)
    return button
end

local fields = {
    { "marketMinReturn", "Min return %", 10, -12, 0, 1000 },
    { "marketMinProfit", "Min profit (s)", 205, -12, 0, 1000000, 100 },
    { "marketFee", "AH cut %", 400, -12, 0, 30 },
    { "marketLookback", "Lookback days", 10, -42, 1, 30 },
    { "marketMinDays", "Min priced days", 205, -42, 2, 29 },
    { "marketMove", "Price move %", 400, -42, 1, 1000 },
}

function UI.Apply()
    if not D.data or U.Combat() then return end
    local values = {}
    for _, field in ipairs(fields) do
        local value = tonumber(UI.inputs[field[1]]:GetText())
        if not U.Number(value, field[5], field[6], true) then
            UI.message = field[2] .. " must be " .. field[5] .. "-" .. field[6] .. "."
            UI.Refresh(); return false
        end
        values[field[1]] = value * (field[7] or 1)
    end
    if values.marketMinDays > values.marketLookback then
        UI.message = "Min priced days cannot exceed lookback days."; UI.Refresh(); return false
    end
    for key, value in pairs(values) do D.data.settings[key] = value; UI.inputs[key]:ClearFocus() end
    UI.message, UI.page, UI.selected = nil, 1, nil
    M.Ensure(UI.view, UI.sort, true); UI.Refresh()
    return true
end

function UI.Create(parent)
    if UI.panel then return UI.panel end
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -34)
    panel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, 33)
    UI.panel = panel
    Label(panel, "Market opportunities", 14, -12, 400):SetFontObject("GameFontNormal")
    UI.age = Label(panel, "", 14, -35, 750)
    UI.views = {}
    local names = { { "deals", "Resale" }, { "rising", "Rising" }, { "falling", "Falling" }, { "all", "All signals" } }
    for index, data in ipairs(names) do
        local view = data[1]
        UI.views[view] = Button(panel, data[2], 14 + (index - 1) * 96, -57, 90, function()
            UI.view, UI.page, UI.selected, UI.message = view, 1, nil, nil
            M.Ensure(UI.view, UI.sort); UI.Refresh()
        end)
    end
    UI.sortButton = Button(panel, "Sort: return", 410, -57, 139, function()
        UI.sort = UI.sort == "return" and "profit" or "return"
        UI.page, UI.selected = 1, nil; M.Ensure(UI.view, UI.sort); UI.Refresh()
    end)
    UI.recheck = Button(panel, "Recheck saved scan", 559, -57, 200, function()
        UI.page, UI.selected = 1, nil; M.Ensure(UI.view, UI.sort, true); UI.Refresh()
    end)
    local filters = CreateFrame("Frame", nil, panel, "InsetFrameTemplate")
    filters:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -89); filters:SetSize(745, 77)
    UI.inputs = {}
    for _, field in ipairs(fields) do
        local key = field[1]
        Label(filters, field[2], field[3], field[4] - 1, 105)
        local box = CreateFrame("EditBox", nil, filters, "InputBoxTemplate")
        box:SetPoint("TOPLEFT", filters, "TOPLEFT", field[3] + 111, field[4] + 5)
        box:SetSize(58, 24); box:SetAutoFocus(false); box:SetNumeric(true); box:SetMaxLetters(7)
        box:SetScript("OnEnterPressed", UI.Apply)
        box:SetScript("OnEscapePressed", function(self) self:ClearFocus(); UI.Refresh() end)
        UI.inputs[key] = box
    end
    UI.apply = Button(filters, "Apply", 610, -10, 120, UI.Apply)
    Label(filters, "Saved scans only.", 600, -46, 135)
    local columns = { {"Item",0,236}, {"Scan low",240,86}, {"Baseline",330,86},
        {"Net / item",420,100}, {"Return",524,66}, {"Move",594,73}, {"Days",671,57} }
    for index, column in ipairs(columns) do Label(panel, column[1], 14 + column[2], -177, column[3], index > 1):SetFontObject("GameFontNormalSmall") end
    for index = 1, 7 do
        local button = CreateFrame("Button", nil, panel)
        button:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -199 - (index - 1) * 26); button:SetSize(745, 24)
        button.labels = {}
        for column, data in ipairs(columns) do button.labels[column] = Label(button, "", data[2], -4, data[3], column > 1) end
        button:SetScript("OnClick", function(self) UI.selected = self.row; UI.Refresh() end)
        button:SetScript("OnEnter", function(self)
            if self.row and GameTooltip and type(GameTooltip.SetHyperlink) == "function" then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetHyperlink(self.row.link); GameTooltip:Show()
            end
        end)
        button:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        UI.rows[index] = button
    end
    UI.detail = Label(panel, "Select an item for its target buy price and history range.", 14, -386, 745)
    UI.detail:SetHeight(32)
    if UI.detail.SetWordWrap then UI.detail:SetWordWrap(true) end
    UI.previous = Button(panel, "Previous", 14, -420, 100, function() UI.page = math.max(1, UI.page - 1); UI.Refresh() end)
    UI.pageText = Label(panel, "", 127, -426, 500)
    UI.next = Button(panel, "Next", 659, -420, 100, function() UI.page = UI.page + 1; UI.Refresh() end)
    UI.status = Label(panel, "", 14, -451, 745)
    panel:SetScript("OnShow", function() M.Ensure(UI.view, UI.sort); UI.Refresh() end)
    panel:Hide()
    return panel
end

function UI.Refresh()
    if not UI.panel then return end
    local snapshot = M.snapshot or D.Snapshot()
    local history = A.History.Status()
    UI.age:SetText((snapshot and ("Scan: " .. U.Age(snapshot.startedAt) .. (D.IsStale(snapshot) and " (stale)" or "")) or "No saved scan") ..
        "  |  " .. history.days .. " saved UTC days  |  Baseline: prior daily lower quartile")
    for key, button in pairs(UI.views) do button:SetEnabled(key ~= UI.view and not U.Combat()) end
    for _, field in ipairs(fields) do
        local box = UI.inputs[field[1]]
        if not box:HasFocus() then box:SetText(tostring(D.Settings()[field[1]] / (field[7] or 1))) end
    end
    UI.sortButton:SetText((UI.view == "rising" or UI.view == "falling") and "Sort: movement" or ("Sort: " .. UI.sort))
    UI.sortButton:SetEnabled(UI.view ~= "rising" and UI.view ~= "falling")
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
            button.labels[1]:SetTextColor(row == UI.selected and 1 or 0.83, row == UI.selected and 0.82 or 0.86, row == UI.selected and 0.25 or 0.89)
            button:Show()
        else button:Hide() end
    end
    if UI.publication ~= M.publications or not M.snapshot then
        UI.selected, UI.publication = nil, M.publications
    end
    local row = UI.selected
    if row then
        local target = row.maxBuy > 0 and ("buy at " .. U.Money(row.maxBuy) .. " or less for the set targets.") or "No positive buy price meets both targets."
        local text = M.Name(row) .. ": " .. target .. " Prior range " .. U.Money(row.low) .. "-" .. U.Money(row.high) .. "."
        if row.trend then text = text .. string.format(" Recent/older 3-point median: %+.0f%%.", row.trend) end
        UI.detail:SetText(text)
    else UI.detail:SetText("Select an item for its target buy price and history range. Values are per item; asking prices do not establish sales.") end
    UI.previous:SetEnabled(UI.page > 1); UI.next:SetEnabled(UI.page < pages)
    UI.pageText:SetText(string.format("%d matches | Page %d / %d%s", M.eligible or 0, UI.page, pages, (M.eligible or 0) > 200 and " | Best 200 shown" or ""))
    UI.status:SetText(UI.message or (M.job and ((M.job.phase == "variants" and ("Checking history variants: " .. (M.job.prepared or 0)) or ("Checking saved prices: " .. M.job.examined)) .. ". Previous results remain until ready.") or M.reason) or
        (M.truncated and "Large dataset: first 50,000 price entries checked." or "Estimated net excludes deposits and unsold stock. Check live listings before buying."))
end

function UI.Show()
    if U.Combat() then return U.Print("Open market opportunities outside combat.") end
    if not A.auctionOpen or not A.UI.InstallAuctionTab() then return U.Print("Open market opportunities at an auctioneer.") end
    A.UI.tabLibrary:SetSelected("MSMarketOpportunities")
end
