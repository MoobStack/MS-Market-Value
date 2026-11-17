local _, A = ...
local U, D, M = A.Util, A.DB, A.Market
local UI = { view = "deals", sort = "return", page = 1, offset=0, rows = {}, dirty = {} }
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

UI.ParseGold, UI.GoldText = U.ParseGold, U.GoldText

local function QualityLabel(quality)
    local name=_G["ITEM_QUALITY" .. quality .. "_DESC"]
    local r,g,b=U.ItemColor(nil,quality)
    return string.format("|cff%02x%02x%02x%s|r",math.floor(r*255+.5),math.floor(g*255+.5),math.floor(b*255+.5),
        U.String(name) and name or U.qualityNames[quality+1])
end

local fields = {
    { "marketMinReturn", "Min return %", 10, -26, 0, 1000 },
    { "marketMinProfit", "Min profit " .. U.coin.gold, 210, -26, 0, 10000 },
    { "marketFee", "AH cut %", 410, -26, 0, 30 },
    { "marketLookback", "Lookback days", 10, -71, 1, 30 },
    { "marketMinDays", "Min priced days", 210, -71, 2, 29 },
    { "marketMove", "Price move %", 410, -71, 0, 1000 },
    { "marketLowMin", "Low qty min", 10, -100, 0, 1000000000 },
    { "marketLowMax", "Low qty max", 210, -100, 0, 1000000000 },
    { "marketStockMin", "Stock min", 410, -100, 0, 1000000000 },
    { "marketStockMax", "Stock max", 10, -129, 0, 1000000000 },
    { "marketStockDrop", "Stock drop %", 210, -129, 0, 100 },
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
    if values.marketLowMax>0 and values.marketLowMin>values.marketLowMax or
       values.marketStockMax>0 and values.marketStockMin>values.marketStockMax then
        UI.message="A quantity minimum cannot exceed its maximum."; UI.Refresh(); return false
    end
    local query=UI.searchBox:GetText()
    if not U.String(query) or #query>80 then return false end
    if not U.Number(UI.qualityDraft,0,63,true) then return false end
    D.data.settings.marketQuality=UI.qualityDraft
    D.data.settings.marketSearch=query:match("^%s*(.-)%s*$")
    UI.searchBox:ClearFocus()
    for key, value in pairs(values) do D.data.settings[key] = value; UI.inputs[key]:ClearFocus() end
    UI.message, UI.page, UI.selected, UI.dirty, UI.offset, UI.filtersOpen = nil, 1, nil, {}, 0, false
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

local function BrowseVariant(row,start)
    if not C_AuctionHouse or type(C_AuctionHouse.GetBrowseResults)~="function" or
       type(C_AuctionHouse.GetItemKeySampleLink)~="function" then return nil end
    local results=U.Call(C_AuctionHouse.GetBrowseResults)
    if not U.Table(results) then return nil end
    local last=math.min(#results,(start or 1)+39,500)
    for index=start or 1,last do
        local result=results[index]
        local key=U.Table(result) and result.itemKey
        if U.Table(key) and U.Number(key.itemID,1,2147483647,true) and key.itemID==row.id and
           U.Number(key.itemLevel,0,100000,true) and U.Number(key.itemSuffix,-2147483647,2147483647,true) and
           U.Number(key.battlePetSpeciesID,0,0,true) then
            local link=U.Call(C_AuctionHouse.GetItemKeySampleLink,key)
            if link and U.VariantKey(link)==row.variantKey then
                local info=U.Call(C_AuctionHouse.GetItemKeyInfo,key)
                if U.Table(info) and U.String(info.itemName) and U.Accessible(info.isCommodity) and type(info.isCommodity)=="boolean" then
                    return {itemID=key.itemID,itemLevel=key.itemLevel,itemSuffix=key.itemSuffix,battlePetSpeciesID=0},info,index+1
                end
            end
        end
    end
    return nil,nil,last<#results and last<500 and last+1 or 1
end
local function OpenNative(row,key,info)
    local ah=AuctionHouseFrame
    local contexts=AuctionHouseSearchContext
    local context=U.Table(contexts) and (info.isCommodity and contexts.BuyCommodities or contexts.BuyItems)
    if not context or not ah or type(ah.SelectBrowseResult)~="function" or type(ah.QueryItem)~="function" then return false end
    return pcall(function()
        ah:SetDisplayMode(AuctionHouseFrameDisplayMode.Buy)
        ah:SelectBrowseResult({itemKey=key,minPrice=row.buy})
        if ah.SetSearchText then ah:SetSearchText(info.itemName) end
        ah:QueryItem(context,key)
    end)
end
function UI.ResolvePendingVariant()
    local pending=UI.pendingVariant
    if not pending then return end
    if U.Combat() or not A.auctionOpen or pending.market~=U.MarketKey() or pending.snapshot~=D.Snapshot() then UI.pendingVariant=nil;return end
    if U.Mono()-pending.at>6 then
        UI.pendingVariant=nil;return Message("Exact modifier details are not ready. Choose it in the Buy results, or try again.")
    end
    local bar=AuctionHouseFrame and AuctionHouseFrame.SearchBar
    local query=bar and U.Call(bar.GetSearchText,bar)
    if U.String(query) and query~=pending.query then UI.pendingVariant=nil;return end
    if type(C_AuctionHouse.IsThrottledMessageSystemReady)=="function" and
       U.Call(C_AuctionHouse.IsThrottledMessageSystemReady)~=true then return end
    local key,info,nextIndex=BrowseVariant(pending.row,pending.index)
    pending.index=nextIndex or 1
    if key then
        UI.pendingVariant=nil
        if not OpenNative(pending.row,key,info) then Message("Could not open that modifier. Choose it in the Buy results.") end
    end
end

-- Only a row's left-click handler calls this. Analysis and refreshes never
-- request live listings. The native AH owns searches and purchase controls.
function UI.OpenListings(row, source)
    if U.Combat() then return Message("Open live listings outside combat.") end
    if source ~= "watch" and next(UI.dirty) then return Message("Apply your filter changes before opening live listings.") end
    local ah, modes = AuctionHouseFrame, AuctionHouseFrameDisplayMode
    if not A.auctionOpen or not U.Table(ah) or not ah.IsShown or not ah:IsShown() or
       (ah.IsForbidden and ah:IsForbidden()) then return Message("Open the auction house to view live listings.") end
    if (A.Scanner.active or A.Scanner.paused) and not A.Scanner.localReady then
        return Message("Wait for the scan's local copy to finish before opening live listings.")
    end
    local snapshot = D.Snapshot()
    local results = source == "watch" and A.Watchlist or M
    if results.job or results.snapshot ~= snapshot or results.key ~= U.MarketKey() or not snapshot or
       not U.Number(snapshot.startedAt, 0, U.Now()) or D.IsStale(snapshot) then
        return Message("Wait for current results, then choose the item again.")
    end
    local found = false
    for _, candidate in ipairs(results.rows) do if candidate == row then found = true; break end end
    if not found then return Message("Choose an item from the current results.") end
    if row.itemWide then return Message("This saved row is item-wide. Rescan, then select its exact modifier under All items.") end
    if C_AuctionHouse and type(C_AuctionHouse.IsThrottledMessageSystemReady) == "function" then
        local ok, ready = pcall(C_AuctionHouse.IsThrottledMessageSystemReady)
        if not ok or not U.Accessible(ready) or ready ~= true then return Message("Auction house is busy. Try the item again shortly.") end
    end
    if UI.lastSearch and U.Mono() - UI.lastSearch < 0.5 then return Message("Please wait a moment before opening another item.") end
    if not U.Table(modes) or not modes.Buy or type(ah.SetDisplayMode) ~= "function" then
        return Message("The native Buy page is unavailable on this client.")
    end
    if row.hasBonuses then
        local key,info=BrowseVariant(row)
        if key then UI.lastSearch=U.Mono();return OpenNative(row,key,info) end
        local bar=ah.SearchBar
        if not U.Table(bar) or type(bar.SetSearchText)~="function" or type(bar.StartSearch)~="function" then
            return Message("Exact modifier details are unavailable. Use the Buy search.")
        end
        -- Search the base name to populate native variant keys. Only the
        -- matching full sample link may then open a modifier's listings.
        local item=A.Valuation.ItemInfo(row.id)
        local query=item and item.name or M.Name(row)
        UI.pendingVariant={row=row,market=U.MarketKey(),snapshot=snapshot,at=U.Mono(),index=1,query=query}
        UI.lastSearch,UI.message=U.Mono(),nil
        local ok=pcall(function()ah:SetDisplayMode(modes.Buy);bar:SetSearchText(query);bar:StartSearch()end)
        if not ok then UI.pendingVariant=nil;return Message("Could not start the native modifier search.") end
        return true
    end
    local key, info = NativeKey(row)
    if source == "watch" and row.suffix == nil and info and not info.isCommodity then key = nil end
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
    -- A base-name fallback must not silently open all random modifiers.
    if row.suffix and row.suffix~=0 then
        return Message("Exact variant search is unavailable. Use the full item name on the Buy page.")
    end
    local item, bar = A.Valuation.ItemInfo(row.link), ah.SearchBar
    local name = info and info.itemName or (item and item.name)
    if not U.String(name) or name == "" or not U.Table(bar) or type(bar.SetSearchText) ~= "function" or type(bar.StartSearch) ~= "function" then
        return Message("Item search is not ready. Wait for item details, or use the native Buy search.")
    end
    UI.lastSearch, UI.message = U.Mono(), nil
    local ok = pcall(function()
        ah:SetDisplayMode(modes.Buy); bar:SetSearchText(name); bar:StartSearch()
    end)
    if not ok then return Message("Could not start the native Buy search. Try searching there directly.") end
    return true
end

local function Highlight(button)
    if button.row and (button.hovered or button.row == UI.selected) then button.highlight:Show() else button.highlight:Hide() end
end

function UI.Layout()
    if not UI.tableFrame then return end
    local expanded=UI.filtersOpen==true
    UI.pageSize=expanded and 4 or 12
    if expanded then UI.filters:Show() else UI.filters:Hide() end
    local caption=expanded and "Hide filters" or "Filters"
    if D.Settings().marketQuality~=63 then
        local count=0;for quality=0,5 do if M.QualityAllowed(D.Settings().marketQuality,quality) then count=count+1 end end
        caption=caption .. " (" .. count .. ")"
    end
    UI.filterToggle:SetText(caption)
    if UI.layoutExpanded~=expanded then
        UI.tableFrame:ClearAllPoints()
        UI.tableFrame:SetPoint("TOPLEFT",UI.panel,"TOPLEFT",14,expanded and -280 or -116)
        UI.tableFrame:SetSize(746,expanded and 106 or 266)
        UI.layoutExpanded=expanded
    end
end
function UI.Scroll(offset)
    UI.offset=math.max(0,math.min(math.floor(offset),math.max(0,#M.rows-(UI.pageSize or 12))))
    UI.hovered=nil;UI.Refresh()
end

function UI.Create(parent)
    if UI.panel then return UI.panel end
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -34)
    panel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, 33)
    UI.panel = panel
    Label(panel, "Market opportunities", 14, -10, 400):SetFontObject("GameFontNormal")
    UI.age = Label(panel, "", 14, -31, 746)
    UI.watchButton=Button(panel, "Watchlists", 510, -7, 120, function() A.EconomyUI.Show("watch") end)
    Button(panel, "Ledger", 640, -7, 120, function() A.EconomyUI.Show("ledger") end)
    UI.views = {}
    local names = { { "deals", "Resale" }, { "rising", "Rising" }, { "falling", "Falling" }, { "all", "All signals" }, {"listed","All items"} }
    for index, data in ipairs(names) do
        local view = data[1]
        local button = Button(panel, data[2], 14 + (index - 1) * 80, -53, 74, function()
            UI.view, UI.page, UI.selected, UI.message, UI.offset = view, 1, nil, nil, 0
            M.Ensure(UI.view, UI.sort); UI.Refresh()
        end)
        button.caption = data[2]; UI.views[view] = button
    end
    UI.sortButton = Button(panel, "Sort: return", 410, -53, 139, function()
        UI.sort = UI.sort == "return" and "profit" or "return"
        UI.page, UI.selected, UI.offset = 1, nil, 0; M.Ensure(UI.view, UI.sort); UI.Refresh()
    end)
    UI.recheck = Button(panel, "Recheck saved scan", 559, -53, 201, function()
        UI.page, UI.selected, UI.offset = 1, nil, 0; M.Ensure(UI.view, UI.sort, true); UI.Refresh()
    end)
    UI.filterToggle=Button(panel,"Filters",410,-84,139,function()
        UI.filtersOpen=not UI.filtersOpen;UI.Refresh()
    end)
    Label(panel,"Keyword",14,-89,60)
    local filters = CreateFrame("Frame", nil, panel, "InsetFrameTemplate")
    filters:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -116); filters:SetSize(746, 157)
    UI.filters=filters
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
    Label(filters,"Rarity",410,-132,100)
    UI.qualityDraft=D.Settings().marketQuality
    UI.qualityMenu=CreateFrame("DropdownButton",nil,filters,"WowStyle1DropdownTemplate")
    UI.qualityMenu:SetPoint("TOPLEFT",filters,"TOPLEFT",518,-126);UI.qualityMenu:SetSize(214,24)
    UI.qualityMenu:SetDefaultText("All rarities")
    UI.qualityMenu:SetupMenu(function(_,root)
        root:CreateCheckbox("All rarities",function()return UI.qualityDraft==63 end,function()
            UI.qualityDraft=UI.qualityDraft==63 and 0 or 63;UI.dirty.marketQuality=true;UI.Refresh()
        end,"all")
        for quality=0,5 do
            local q=quality
            root:CreateCheckbox(QualityLabel(q),
                function()return M.QualityAllowed(UI.qualityDraft,q)end,function()
                    local bit=2^q
                    UI.qualityDraft=UI.qualityDraft+(M.QualityAllowed(UI.qualityDraft,q) and -bit or bit)
                    UI.dirty.marketQuality=true;UI.Refresh()
                end,q)
        end
    end)
    UI.searchBox=CreateFrame("EditBox",nil,panel,"InputBoxTemplate")
    UI.searchBox:SetPoint("TOPLEFT",panel,"TOPLEFT",80,-81); UI.searchBox:SetSize(308,24)
    UI.searchBox:SetAutoFocus(false); UI.searchBox:SetMaxLetters(80); UI.searchBox:SetScript("OnEnterPressed",UI.Apply)
    UI.searchBox:SetScript("OnTextChanged",function(_,user) if user then UI.dirty.marketSearch=true end end)
    UI.searchBox:SetScript("OnEscapePressed",function(self)
        self:ClearFocus(); self:SetText(D.Settings().marketSearch); UI.dirty.marketSearch=nil; UI.Refresh()
    end)
    UI.apply = Button(filters, "Apply filters", 618, -19, 114, UI.Apply)
    UI.quickApply=Button(panel,"Apply search",559,-84,201,UI.Apply)
    Label(filters, "0.25" .. U.coin.gold .. " = 25" .. U.coin.silver, 618, -49, 114)
    Label(filters, "Move: 0 = off", 618, -72, 114)
    local tableFrame = CreateFrame("Frame", nil, panel, "InsetFrameTemplate")
    UI.tableFrame=tableFrame
    tableFrame:EnableMouseWheel(true)
    tableFrame:SetScript("OnMouseWheel",function(_,delta)UI.Scroll(UI.offset-delta*3)end)
    local header = CreateFrame("Frame", nil, tableFrame)
    header:SetPoint("TOPLEFT", tableFrame, "TOPLEFT", 3, -3); header:SetSize(716, 21)
    Fill(header, "BACKGROUND", 0.22, 0.18, 0.09, 0.45)
    local columns = { {"Item / modifier",7,211}, {"Each",222,76}, {"At low",302,44},
        {"Low buyout",350,92}, {"Stock",446,44}, {"Net / item",494,88},
        {"Return",586,53}, {"Move",643,63} }
    for index, column in ipairs(columns) do Label(header, column[1], column[2], -3, column[3], index > 1):SetFontObject("GameFontNormalSmall") end
    for index = 1, 12 do
        local button = CreateFrame("Button", nil, tableFrame)
        button:SetPoint("TOPLEFT", tableFrame, "TOPLEFT", 3, -25 - (index - 1) * 20); button:SetSize(716, 20)
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
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetHyperlink(self.row.link)
                GameTooltip:AddLine(M.HistoryDescription(self.row),.61,.66,.70);GameTooltip:Show()
            end
        end)
        button:SetScript("OnLeave", function(self)
            self.hovered, UI.hovered = nil, nil; Highlight(self); UI.RefreshDetails()
            if GameTooltip then GameTooltip:Hide() end
        end)
        UI.rows[index] = button
    end
    UI.scrollbar=CreateFrame("Slider",nil,tableFrame,"UIPanelScrollBarTemplate")
    UI.scrollbar:SetPoint("TOPRIGHT",tableFrame,"TOPRIGHT",-4,-19)
    UI.scrollbar:SetPoint("BOTTOMRIGHT",tableFrame,"BOTTOMRIGHT",-4,19)
    UI.scrollbar:SetWidth(16);UI.scrollbar:SetValueStep(1);UI.scrollbar:SetObeyStepOnDrag(true)
    UI.scrollbar:SetScript("OnValueChanged",function(_,value)if not UI.syncScroll then UI.Scroll(value) end end)
    local details = CreateFrame("Frame", nil, panel, "InsetFrameTemplate")
    details:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -388); details:SetSize(746, 40)
    UI.detail = Label(details, "", 10, -6, 726); UI.detail:SetHeight(29); UI.detail:SetWordWrap(true)
    UI.previous = Button(panel, "Previous", 14, -432, 100, function() UI.Scroll(UI.offset-(UI.pageSize or 12)) end)
    UI.pageText = Label(panel, "", 127, -437, 270)
    UI.watchSelected = Button(panel, "Watch selected", 420, -432, 145, function() A.EconomyUI.WatchDraft(UI.selected) end)
    UI.next = Button(panel, "Next", 660, -432, 100, function() UI.Scroll(UI.offset+(UI.pageSize or 12)) end)
    UI.status = Label(panel, "", 14, -459, 746)
    panel:SetScript("OnShow", function() M.Ensure(UI.view, UI.sort); UI.Refresh() end)
    panel:SetScript("OnHide", function() UI.hovered = nil; if GameTooltip then GameTooltip:Hide() end end)
    panel:Hide()
    return panel
end

function UI.RefreshDetails()
    if not UI.detail then return end
    local row = UI.hovered or UI.selected
    if row then
        if row.needsHistory then
            UI.detail:SetText(M.Name(row)..". "..M.HistoryDescription(row))
            return
        end
        local target = row.maxBuy and row.maxBuy > 0 and ("Buy at " .. U.Coins(row.maxBuy) .. " or less.") or "No positive target buy price."
        local text = M.Name(row) .. ". " .. target .. " Baseline " .. U.Coins(row.baseline) .. " (" .. row.days .. " days)."
        text=text .. (row.stockMove and string.format(" Stock %+.0f%% since prior scan.",row.stockMove) or " Stock change needs two scans.")
        if not row.lowUnits then text=text .. " Rescan for quantities at the low." end
        if row.trend then text = text .. string.format(" Recent trend: %+.0f%%.", row.trend) end
        UI.detail:SetText(text)
    else UI.detail:SetText("Left-click an item to open live listings. Right-click for details; hover for its tooltip. Values are per item.") end
end

function UI.Refresh()
    if not UI.panel then return end
    UI.Layout()
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
    if not UI.searchBox:HasFocus() and not UI.dirty.marketSearch then UI.searchBox:SetText(D.Settings().marketSearch) end
    if not UI.dirty.marketQuality then UI.qualityDraft=D.Settings().marketQuality end
    local count,label=0
    for quality=0,5 do if M.QualityAllowed(UI.qualityDraft,quality) then count=count+1;label=QualityLabel(quality) end end
    if UI.qualityMenu.OverrideText then UI.qualityMenu:OverrideText(count==6 and "All rarities" or count==0 and "No rarities" or count==1 and label or (count .. " rarities selected")) end
    UI.apply:SetEnabled(not combat); UI.quickApply:SetEnabled(not combat); UI.recheck:SetEnabled(not combat and not M.job and not next(UI.dirty))
    UI.sortButton:SetText((UI.view == "rising" or UI.view == "falling") and "Sort: movement" or ("Sort: " .. UI.sort))
    UI.sortButton:SetEnabled(not combat and UI.view ~= "rising" and UI.view ~= "falling")
    if UI.publication ~= M.publications or not M.snapshot then
        UI.selected, UI.hovered, UI.publication, UI.offset = nil, nil, M.publications, 0
    end
    UI.offset=math.max(0,math.min(UI.offset or 0,math.max(0,#M.rows-UI.pageSize)))
    UI.page=math.floor(UI.offset/UI.pageSize)+1
    UI.syncScroll=true;UI.scrollbar:SetMinMaxValues(0,math.max(0,#M.rows-UI.pageSize));UI.scrollbar:SetValue(UI.offset);UI.syncScroll=false
    local visible={}
    for index=1,UI.pageSize do if M.rows[UI.offset+index] then visible[#visible+1]=M.rows[UI.offset+index] end end
    M.RequestVisibleInfo(visible)
    for index, button in ipairs(UI.rows) do
        local row = index<=UI.pageSize and M.rows[UI.offset+index] or nil
        button.row = row
        if row then
            local texts = { M.Name(row), U.Coins(row.current), row.lowUnits and tostring(row.lowUnits) or "-",
                row.lowBuyout and U.Coins(row.lowBuyout) or "-", row.units and tostring(row.units) or "-",
                row.profit and A.CraftingUI.SignedMoney(row.profit) or row.itemWide and "Rescan" or
                    row.needsHistory and ((row.days or 0).."/"..(row.minDays or D.Settings().marketMinDays).." days") or "-", row.roi and string.format("%+.0f%%", row.roi) or "-",
                row.movement and string.format("%+.0f%%", row.movement) or "-" }
            for column, value in ipairs(texts) do button.labels[column]:SetText(value) end
            for _, column in ipairs({6,7}) do button.labels[column]:SetTextColor(row.profit and row.profit>0 and 0.35 or 1, row.profit and row.profit>0 and 0.87 or 0.38, 0.38) end
            button.labels[8]:SetTextColor(row.movement and row.movement>0 and 0.35 or 1, row.movement and row.movement>0 and 0.87 or 0.65, 0.38)
            if row.needsHistory then for _,column in ipairs({6,7,8})do button.labels[column]:SetTextColor(.61,.66,.70) end end
            button.labels[1]:SetTextColor(row.r or .90,row.g or .89,row.b or .84)
            Highlight(button); button:Show()
        else button:Hide() end
    end
    UI.RefreshDetails()
    UI.previous:SetEnabled(UI.offset>0); UI.next:SetEnabled(UI.offset+UI.pageSize<#M.rows)
    UI.watchSelected:SetEnabled(UI.selected ~= nil and not combat and not M.job)
    UI.pageText:SetText(string.format("%d-%d / %d%s",#M.rows>0 and UI.offset+1 or 0,math.min(UI.offset+UI.pageSize,#M.rows),
        M.eligible or 0,(M.eligible or 0)>M.limit and (" | Best " .. M.limit .. " shown") or ""))
    UI.status:SetText(UI.message or (next(UI.dirty) and "Changes not applied. Click Apply filters or press Enter; Esc restores the focused field.") or
        (M.job and ((M.job.phase == "variants" and ("Preparing item variants: " .. (M.job.prepared or 0)) or ("Updating results: " .. M.job.examined .. " current entries checked")) .. ". Previous results shown until finished.") or M.reason) or
        (M.truncated and "Large dataset: first 50,000 price entries checked." or "Resale requires the minimum price drop. Estimates exclude deposits and unsold stock."))
end

function UI.Show()
    if U.Combat() then return U.Print("Open market opportunities outside combat.") end
    if not A.auctionOpen or not A.UI.InstallAuctionTab() then return U.Print("Open market opportunities at an auctioneer.") end
    A.UI.tabLibrary:SetSelected("MSMarketOpportunities")
end
