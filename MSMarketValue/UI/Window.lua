local _, A = ...
local U, D, S = A.Util, A.DB, A.Scanner
local UI = {}
A.UI = UI

local function Label(parent, text, x, y, width, template)
    local font = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
    font:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    if width then font:SetWidth(width) end
    font:SetJustifyH("LEFT")
    font:SetText(text)
    return font
end

local function Button(parent, text, x, y, width, handler)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetSize(width, 26)
    button:SetText(text)
    button:SetScript("OnClick", handler)
    return button
end

local function Check(parent, key, text, y)
    local button = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    button:SetSize(26, 26)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, y)
    button.label = Label(parent, text, 41, y - 7, 309)
    button:SetScript("OnClick", function(self)
        if not D.data then return end
        D.data.settings[key] = self:GetChecked() and true or false
        if A.Tooltips then A.Tooltips.RefreshVisible() end
        UI.Refresh()
    end)
    UI.checks[key] = button
end

local function Inset(parent, x, y, width, height)
    local frame = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    frame:SetSize(width, height)
    return frame
end

local function PortraitWindow(name, title, width, height)
    local frame = CreateFrame("Frame", name, UIParent, "PortraitFrameTemplate")
    frame:SetSize(width, height)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetTitle(title)
    if frame.PortraitContainer and frame.PortraitContainer.portrait then
        frame.PortraitContainer.portrait:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
    end
    frame.CloseButton:SetScript("OnClick", function() frame:Hide() end)
    table.insert(UISpecialFrames, name)
    return frame
end

function UI.DiagnosticsText()
    local version, build, _, interface = GetBuildInfo()
    local snapshot = D.Snapshot()
    local market = U.MarketInfo()
    local lines = {
        A.TITLE .. " " .. A.VERSION .. " / " .. A.BUILD,
        "Client: " .. tostring(version) .. " / " .. tostring(build) .. " / Interface " .. tostring(interface),
        "API available: " .. tostring(S.Supported()),
        "Tooltip callback installed: " .. tostring(A.Tooltips.installed or false),
        "Addon disabled: " .. tostring(A.disabledReason or "no"),
        "Tooltip status: " .. tostring(A.tooltipReason or "ready"),
        "Scan state: " .. S.state,
        "Resume phase: " .. tostring(S.resumeState or "none"),
        "Staged rows: " .. tostring(S.work and S.work.processedRows or 0),
        "Local auction copy: " .. (S.localReady and "complete" or "incomplete") .. "; rows=" .. tostring(S.copiedRows or 0) .. "/" .. tostring(S.totalRows or 0),
        "Native buffer lost: " .. tostring(S.bufferLost or false),
        "Crafting API: " .. tostring(A.Crafting.Supported()),
        "Recipe catalog: " .. tostring(A.Crafting.reason or (A.Crafting.ready and "ready" or "waiting for a profession")),
        "Selected recipe: " .. tostring(A.Crafting.selected and A.Crafting.selected.recipeID or "none"),
        "Craft valuation: " .. tostring(A.Crafting.selected and (A.Crafting.selected.reason or "complete") or "none"),
        "Recipe catalog builds: " .. tostring(A.Crafting.builds),
        "Recipe catalog publications: " .. tostring(A.Crafting.publications),
        "Selected recipe link: " .. (A.Crafting.selected and A.Crafting.RecipeLink(A.Crafting.selected.recipeID) and "available" or "unavailable"),
        "Craft auto-open: " .. tostring(D.Settings().craftAutoOpen),
        A.CraftingUI.Diagnostics(),
        "Recipe list filter: " .. (D.Settings().showAllRecipes and "all learned recipes" or "profitable only"),
        "Full-scan requests this session: " .. tostring(S.requestCount),
        "Replication events this scan: " .. tostring(S.responseCount),
        "Same-count data updates: " .. tostring(S.dataUpdateCount),
        "Full-scan cooldown seconds: " .. tostring(S.RemainingCooldown()),
        "Market key: " .. tostring(market.key or market.reason),
        "Market identity: " .. tostring(market.kind or "unavailable"),
        "Ruleset: " .. tostring(market.ruleset or "undetected"),
        "Ruleset source: " .. tostring(market.rulesetSource or "unavailable"),
        "Player faction: " .. market.nativeFaction,
        "Normalized reporting alias: " .. market.normalizedRealm,
        "Public reporting alias: " .. market.realmName,
        "Native region: " .. market.nativeRegion,
        "Login portal: " .. market.portal,
        "Market sources: " .. tostring(market.realmSource) .. "; " .. tostring(market.regionSource or "unavailable"),
        "Auction House tab: " .. (UI.tabInstalled and "installed" or (UI.tabReason or "waiting for the auctioneer")),
        "Disenchant profile: " .. A.DEProfile.id .. " (Forever unverified)",
    }
    if A.TEST_REVISION then table.insert(lines, 2, "Test revision: " .. tostring(A.TEST_REVISION)) end
    local vendorCount, vendorReason = A.Vendor.Status()
    lines[#lines + 1] = "Vendor purchase prices: " .. vendorCount .. " for this player" .. (vendorReason and ("; " .. vendorReason) or "")
    lines[#lines + 1] = "Opportunities tab: " .. (A.MarketUI.tabButton and "installed" or "waiting for the auctioneer")
    lines[#lines + 1] = "Market analysis: " .. (A.Market.job and "checking" or (A.Market.ready and "ready" or "not opened")) .. "; builds=" .. A.Market.builds .. "; publications=" .. A.Market.publications .. "; matches=" .. (A.Market.eligible or 0)
    if A.Market.reason then lines[#lines + 1] = "Market analysis detail: " .. A.Market.reason end
    lines[#lines + 1] = "Craft pricing: AH cut=" .. D.Settings().marketFee .. "%; labor=" .. U.Money(D.Settings().serviceLabor) .. "; minimum=" .. U.Money(D.Settings().serviceMinimum) .. "; customer_materials=" .. tostring(D.Settings().serviceCustomerMaterials)
    lines[#lines + 1] = "Watchlists: " .. #A.Watchlist.Entries() .. " this market; " .. (A.Watchlist.job and "checking" or "ready") .. "; publications=" .. A.Watchlist.publications
    if A.Watchlist.reason then lines[#lines + 1] = "Watchlist detail: " .. A.Watchlist.reason end
    local ledger = A.Ledger.Summary()
    lines[#lines + 1] = "Ledger: " .. #ledger.rows .. " this character/market; retention=" .. D.Settings().ledgerDays .. " days; sales_needing_cost=" .. ledger.unknown
    if A.Ledger.reason then lines[#lines + 1] = "Ledger detail: " .. A.Ledger.reason end
    local tracking=A.Transactions
    lines[#lines+1]="Transaction tracking: AH="..tostring(D.Settings().trackAH).."; vendor="..tostring(D.Settings().trackVendor).."; captured="..tracking.captured.."; reconciled="..tracking.reconciled.."; waiting="..#tracking.queue
    lines[#lines+1]="Cash tracking: loot="..tostring(D.Settings().trackLoot).."; other="..tostring(D.Settings().trackOther).."; loot_awards="..A.Cash.lootAwards.."; expenses="..A.Cash.expenses.."; pending_wallet_changes="..#A.Cash.debits
    if A.Cash.reason then lines[#lines+1]="Cash tracking note: "..A.Cash.reason end
    lines[#lines+1]="Trade tip tracking: enabled="..tostring(D.Settings().trackTrade).."; money_API="..tostring(tracking.tradeAPI==true).."; awaiting_completion="..tostring(tracking.trade~=nil or tracking.closedTrade~=nil)
    lines[#lines+1]="Ledger time: local; "..date("%Y-%m-%d %H:%M:%S %Z",U.Now())
    lines[#lines+1]="Purchase observers: item="..tostring(tracking.purchaseHook==true).."; commodity="..tostring(tracking.commodityHook==true).."; mailbox="..tostring(tracking.mailOpen==true)
    lines[#lines+1]="Buy-page watch buttons: item="..tostring(A.EconomyUI.buyButtons and U.Table(AuctionHouseFrame)and A.EconomyUI.buyButtons[AuctionHouseFrame.ItemBuyFrame]~=nil or false).."; commodity="..tostring(A.EconomyUI.buyButtons and U.Table(AuctionHouseFrame)and A.EconomyUI.buyButtons[AuctionHouseFrame.CommoditiesBuyFrame]~=nil or false)
    if tracking.reason then lines[#lines+1]="Transaction detail: "..tracking.reason end
    local history = A.History.Status()
    lines[#lines + 1] = "Historic pricing: " .. (history.reason or (tostring(history.days) .. " UTC days for this market; retention=" .. tostring(history.retention) .. " days"))
    if history.firstDay then
        lines[#lines + 1] = "History dates UTC: " .. date("!%Y-%m-%d", history.firstDay * 86400) .. " to " .. date("!%Y-%m-%d", history.lastDay * 86400)
    end
    if snapshot then
        lines[#lines + 1] = string.format("Saved snapshot: complete; rows=%d; priced_items=%d; bid_only=%d; sold=%d", snapshot.totalRows, snapshot.distinctItems, snapshot.bidOnlyRows, snapshot.soldRows)
        lines[#lines + 1] = "Snapshot started UTC: " .. date("!%Y-%m-%dT%H:%M:%SZ", snapshot.startedAt)
        lines[#lines + 1] = "Snapshot age: " .. U.Age(snapshot.startedAt)
    else
        lines[#lines + 1] = "Saved snapshot: none for this market"
    end
    lines[#lines + 1] = "Recent local messages:"
    for _, message in ipairs(A.log) do lines[#lines + 1] = message end
    return table.concat(lines, "\n")
end

function UI.SettingsPage(page)
    UI.settingsPage = page == "craft" and "craft" or "tooltips"
    if not UI.tooltipSettings then return end
    if UI.settingsPage == "craft" then UI.tooltipSettings:Hide(); UI.craftSettings:Show()
    else UI.tooltipSettings:Show(); UI.craftSettings:Hide() end
    UI.tooltipSettingsTab:SetEnabled(UI.settingsPage ~= "tooltips")
    UI.craftSettingsTab:SetEnabled(UI.settingsPage ~= "craft")
end

function UI.ApplyRetention()
    local value = tonumber(UI.retentionBox:GetText())
    if not A.History.SetRetention(value) then return U.Print("Choose a history length from 1 to 30 days.") end
    UI.retentionBox:ClearFocus()
    A.Tooltips.RefreshVisible()
    UI.Refresh()
end

function UI.ShowDiagnostics()
    if U.Combat() then return U.Print("Open diagnostics outside combat.") end
    if not UI.diagnostics then
        local frame = PortraitWindow("MSMarketValueDiagnostics", "Diagnostics - Ctrl+C to copy", 620, 440)
        Inset(frame, 10, -35, 598, 386)
        local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 22, -47)
        scroll:SetPoint("BOTTOMRIGHT", -40, 29)
        local edit = CreateFrame("EditBox", nil, scroll)
        edit:SetMultiLine(true)
        edit:SetAutoFocus(false)
        edit:SetFontObject(GameFontHighlightSmall)
        edit:SetWidth(548)
        edit:SetHeight(1100)
        edit:SetMaxLetters(16384)
        edit:SetScript("OnEscapePressed", function() frame:Hide() end)
        scroll:SetScrollChild(edit)
        UI.diagnostics, UI.diagnosticsEdit = frame, edit
    end
    UI.diagnosticsEdit:SetText(UI.DiagnosticsText())
    UI.diagnostics:Show()
    UI.diagnosticsEdit:SetFocus()
    UI.diagnosticsEdit:HighlightText()
end

function UI.Create()
    if UI.frame or U.Combat() then return end
    UI.checks = {}
    local window = PortraitWindow("MSMarketValueWindow", A.TITLE, 800, 538)
    window:EnableMouse(true)
    window:SetMovable(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", function(self) if not U.Combat() then self:StartMoving() end end)
    window:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        local px, py = UIParent:GetCenter()
        if D.data and U.Number(x) and U.Number(y) and U.Number(px) and U.Number(py) then
            D.data.windowPosition = { x = x - px, y = y - py }
        end
    end)
    local pos = D.data and D.data.windowPosition
    if type(pos) == "table" and U.Number(pos.x, -10000, 10000) and U.Number(pos.y, -10000, 10000) then
        window:ClearAllPoints()
        window:SetPoint("CENTER", UIParent, "CENTER", pos.x, pos.y)
    end
    -- Shared controls fill the native AH body. Blizzard templates provide the
    -- textured backgrounds, nine-slice borders, buttons, inputs and checkboxes.
    local frame = CreateFrame("Frame", nil, window)
    frame:SetSize(768, 460)
    frame:SetPoint("TOPLEFT", window, "TOPLEFT", 16, -38)
    UI.content = frame
    local scan = Inset(frame, 12, -8, 744, 196)
    Label(scan, "Price snapshot", 14, -13, 365, "GameFontNormal")
    Label(scan, A.VERSION, 270, -14, 200)
    UI.ledgerShortcut = Button(scan,"Ledger",496,-8,110,function()A.EconomyUI.Show("ledger")end)
    UI.watchShortcut = Button(scan,"Watchlists",616,-8,112,function()A.EconomyUI.Show("watch")end)
    UI.marketText = Label(scan, "", 14, -34, 716)
    UI.snapshotText = Label(scan, "", 14, -55, 716)
    UI.statusText = Label(scan, "", 14, -89, 716)
    UI.progress = CreateFrame("StatusBar", nil, scan)
    UI.progress:SetPoint("TOPLEFT", 14, -135)
    UI.progress:SetSize(716, 10)
    UI.progress:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    UI.progress:SetStatusBarColor(0.2, 0.7, 0.2)
    UI.progress:SetMinMaxValues(0, 1)
    UI.progress:SetValue(0)
    UI.scanButton = Button(scan, "Scan entire AH", 14, -155, 152, function()
        local ok, message = S.Start()
        if not ok then U.Print(message) end
    end)
    UI.stopButton = Button(scan, "Pause scan", 178, -155, 110, function() S.Pause() end)
    Button(scan, "Copy diagnostics", 300, -155, 150, UI.ShowDiagnostics)
    UI.restartButton = Button(scan, "Restart scan", 462, -155, 124, function()
        local ok, message = S.Restart()
        if not ok then U.Print(message) end
    end)

    local settings = Inset(frame, 12, -216, 366, 204)
    UI.tooltipSettingsTab = Button(settings, "Tooltips", 10, -7, 146, function() UI.SettingsPage("tooltips") end)
    UI.craftSettingsTab = Button(settings, "Crafting & history", 163, -7, 193, function() UI.SettingsPage("craft") end)
    local tooltipSettings = CreateFrame("Frame", nil, settings)
    tooltipSettings:SetPoint("TOPLEFT", 0, -40); tooltipSettings:SetSize(366, 158)
    UI.tooltipSettings = tooltipSettings
    Check(tooltipSettings, "showVendor", "Vendor sell price", 0)
    Check(tooltipSettings, "showHistory", "Historic average and sample days", -25)
    Check(tooltipSettings, "showAuction", "Lowest AH buyout", -50)
    Check(tooltipSettings, "showDisenchant", "Estimated disenchant value", -75)
    Check(tooltipSettings, "showMaterials", "Material ranges and chances", -100)
    Check(tooltipSettings, "showAge", "Snapshot age and stale flag", -125)
    local craftSettings = CreateFrame("Frame", nil, settings)
    craftSettings:SetPoint("TOPLEFT", 0, -40); craftSettings:SetSize(366, 158)
    UI.craftSettings = craftSettings
    Check(craftSettings, "craftAutoOpen", "Auto-open crafting profits", 0)
    Label(craftSettings, "Keep price history for", 14, -42, 155)
    local retention = CreateFrame("EditBox", nil, craftSettings, "InputBoxTemplate")
    retention:SetSize(36, 24); retention:SetPoint("TOPLEFT", 177, -35)
    retention:SetAutoFocus(false); retention:SetNumeric(true); retention:SetMaxLetters(2)
    retention:SetScript("OnEnterPressed", UI.ApplyRetention)
    retention:SetScript("OnEscapePressed", function(self) self:ClearFocus(); UI.Refresh() end)
    UI.retentionBox = retention
    Label(craftSettings, "days", 220, -42, 42)
    UI.retentionApply = Button(craftSettings, "Apply", 272, -34, 76, UI.ApplyRetention)
    Label(craftSettings, "1-30 days. Latest complete scan per UTC day.", 14, -72, 338)
    UI.historyText = Label(craftSettings, "", 14, -98, 338)
    Label(craftSettings, "Shortening history removes older days.\nEarlier scans cannot be recovered.", 14, -124, 338)
    UI.SettingsPage("tooltips")

    local prices = Inset(frame, 390, -216, 366, 204)
    Label(prices, "Price settings", 14, -13, 338, "GameFontNormal")
    Label(prices, "Mark prices stale after", 14, -41, 165)
    local stale = CreateFrame("EditBox", nil, prices, "InputBoxTemplate")
    stale:SetSize(45, 24)
    stale:SetPoint("TOPLEFT", 185, -34)
    stale:SetAutoFocus(false)
    stale:SetNumeric(true)
    stale:SetMaxLetters(3)
    stale:SetScript("OnEscapePressed", function(self) self:ClearFocus(); UI.Refresh() end)
    UI.staleBox = stale
    Label(prices, "hours (1-168)", 237, -41, 113)
    Button(prices, "Apply", 260, -72, 90, function()
        if not D.data then return end
        local value = tonumber(stale:GetText())
        if not U.Number(value, 1, 168, true) then return U.Print("Choose a stale age from 1 to 168 hours.") end
        D.data.settings.staleHours = value
        stale:ClearFocus()
        A.Tooltips.RefreshVisible()
        UI.Refresh()
    end)
    Label(prices, "Disenchant exclusions", 14, -118, 338, "GameFontNormal")
    local exclude = CreateFrame("EditBox", nil, prices, "InputBoxTemplate")
    exclude:SetSize(95, 24)
    exclude:SetPoint("TOPLEFT", 20, -143)
    exclude:SetAutoFocus(false)
    exclude:SetNumeric(true)
    exclude:SetMaxLetters(10)
    exclude:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    local function Exclude(excluded)
        local id = tonumber(exclude:GetText())
        if not D.Exclude(id, excluded) then return U.Print("Enter a valid numeric item ID.") end
        U.Print("Item " .. tostring(id) .. (excluded and " excluded from DE estimates." or " restored to the DE reference model."))
        exclude:ClearFocus()
        A.Tooltips.RefreshVisible()
    end
    Button(prices, "Exclude", 120, -143, 90, function() Exclude(true) end)
    Button(prices, "Restore estimate", 218, -143, 128, function() Exclude(false) end)
    Label(prices, "Enter an item ID to override the reference model.", 14, -181, 338)
    Label(frame, "AH values are asking prices, before fees. Disenchant outcomes use an unverified Classic reference.\nKeep the AH open until Local copy is complete. Paused scans resume outside combat at an auctioneer.", 14, -433, 740)
    frame:SetScript("OnShow", UI.Refresh)
    window:SetScript("OnShow", UI.Refresh)
    window:Hide()
    UI.frame = window
    frame:Show()
end

function UI.Refresh()
    if not UI.frame then return end
    local snapshot = D.Snapshot()
    local market = U.MarketInfo()
    UI.marketText:SetText("Market: " .. (market.label or "Waiting for market identity"))
    if snapshot then
        UI.snapshotText:SetText(string.format("Saved: %d auctions | %d priced items | %s%s\nA complete new scan replaces this market's snapshot.", snapshot.totalRows, snapshot.distinctItems, U.Age(snapshot.startedAt), D.IsStale(snapshot) and " (stale)" or ""))
    else
        UI.snapshotText:SetText("No complete scan saved for this market.\n" .. (market.key and "Click Scan entire AH at an open auctioneer." or market.reason))
    end
    local status = S.state .. (S.message and (": " .. S.message) or "")
    if S.work then
        status = status .. string.format("\nLocal copy %d/%d%s | Read %d; unresolved %d.", S.copiedRows or 0, S.totalRows, S.localReady and " (complete)" or "", S.work.processedRows, #S.pending)
    elseif S.RemainingCooldown() > 0 then
        status = status .. string.format("\nNext full scan in %dm %ds.", math.floor(S.RemainingCooldown() / 60), S.RemainingCooldown() % 60)
    end
    if A.disabledReason then status = A.disabledReason end
    if A.tooltipReason then status = status .. "\n" .. A.tooltipReason end
    UI.statusText:SetText(status)
    UI.progress:SetValue(S.work and (S.totalRows > 0 and S.work.processedRows / S.totalRows or 1) or (S.state == "COMPLETE" and 1 or 0))
    UI.scanButton:SetText(S.paused and (S.bufferLost and S.RemainingCooldown() == 0 and "Restart scan" or "Resume scan") or "Scan entire AH")
    UI.scanButton:SetEnabled(D.data ~= nil and not A.disabledReason and A.auctionOpen and not U.Combat() and not S.active and (S.paused == true or S.RemainingCooldown() == 0))
    UI.stopButton:SetEnabled(S.active)
    UI.restartButton:SetEnabled(D.data ~= nil and not A.disabledReason and A.auctionOpen and not U.Combat() and S.paused == true and S.RemainingCooldown() == 0)
    if UI.tabButton then UI.tabButton:SetEnabled(not U.Combat()) end
    for key, check in pairs(UI.checks) do check:SetChecked(D.Settings()[key]) end
    if not UI.staleBox:HasFocus() then UI.staleBox:SetText(tostring(D.Settings().staleHours)) end
    if not UI.retentionBox:HasFocus() then UI.retentionBox:SetText(tostring(D.Settings().historyDays)) end
    local history = A.History.Status()
    UI.historyText:SetText(history.reason or ("Saved daily scans for this market: " .. history.days))
end

function UI.Dock()
    if not UI.panel or U.Combat() then return end
    UI.frame:Hide()
    UI.content:Hide()
    UI.content:SetParent(UI.panel)
    UI.content:SetFrameStrata(UI.panel:GetFrameStrata())
    UI.content:SetFrameLevel(UI.panel:GetFrameLevel() + 1)
    UI.content:ClearAllPoints()
    UI.content:SetPoint("TOPLEFT", UI.panel, "TOPLEFT", 12, -5)
    UI.content:Show()
end

function UI.InstallAuctionTab()
    if UI.tabInstalled then return true end
    if UI.tabFailed then return false end
    if U.Combat() then UI.tabReason = "deferred until combat ends"; return false end
    local ah = AuctionHouseFrame
    if not U.Table(ah) or not ah.IsShown or not ah:IsShown() or
       (ah.IsForbidden and ah:IsForbidden()) then
        UI.tabReason = "waiting for the Auction House frame"
        return false
    end
    if type(ah.SetDisplayMode) ~= "function" or not U.Table(ah.Tabs) or #ah.Tabs == 0 or
       type(LibStub) ~= "table" then
        UI.tabReason = "the modern Auction House tab API is unavailable"
        return false
    end
    local lib = LibStub:GetLibrary("LibAHTab-1-0", true)
    if not lib then UI.tabReason = "the bundled tab library is unavailable"; return false end
    UI.Create()
    if not UI.panel then
        local panel = CreateFrame("Frame", nil, ah)
        panel:SetPoint("TOPLEFT", ah, "TOPLEFT", 4, -34)
        panel:SetPoint("BOTTOMRIGHT", ah, "BOTTOMRIGHT", -4, 33)
        panel:SetScript("OnShow", UI.Refresh)
        panel:Hide()
        UI.panel = panel
    end
    local opportunities = A.MarketUI.Create(ah)
    if not lib:DoesIDExist("MSMarketOpportunities") then
        local added = pcall(lib.CreateTab, lib, "MSMarketOpportunities", opportunities, "MS Opportunities", "MS Market Value - Opportunities")
        if not added then UI.tabReason = "could not register the opportunities tab"; return false end
    end
    local marketButton = lib:GetButton("MSMarketOpportunities")
    marketButton:SetScript("OnClick", function()
        if U.Combat() or not A.auctionOpen then return end
        lib:SetSelected("MSMarketOpportunities")
    end)
    A.MarketUI.tabButton = marketButton
    local ok, errorReason = pcall(lib.CreateTab, lib, "MSMarketValue", UI.panel, A.TITLE, A.TITLE)
    if not ok then
        UI.tabFailed = true
        UI.tabReason = "could not register the Auction House tab"
        U.Log(UI.tabReason .. (U.String(errorReason) and (": " .. errorReason) or ""))
        return false
    end
    UI.tabInstalled, UI.tabReason, UI.tabLibrary = true, nil, lib
    UI.tabButton = lib:GetButton("MSMarketValue")
    UI.tabButton:SetScript("OnClick", function()
        if U.Combat() or not A.auctionOpen then return end
        UI.Dock()
        lib:SetSelected("MSMarketValue")
    end)
    ah:HookScript("OnShow", function() if not U.Combat() then UI.Dock() end end)
    ah:HookScript("OnHide", function() if UI.panel then UI.panel:Hide() end end)
    UI.Dock()
    UI.Refresh()
    return true
end

function UI.OnAuctionShow()
    if U.Combat() then return end
    if UI.frame then UI.frame:Hide() end
    if UI.InstallAuctionTab() then UI.Dock() end
end

function UI.ShowStandalone()
    UI.Create()
    UI.content:Hide()
    UI.content:SetParent(UI.frame)
    UI.content:SetFrameStrata(UI.frame:GetFrameStrata())
    UI.content:SetFrameLevel(UI.frame:GetFrameLevel() + 1)
    UI.content:ClearAllPoints()
    UI.content:SetPoint("TOPLEFT", UI.frame, "TOPLEFT", 16, -38)
    UI.content:Show()
    UI.frame:Show()
end

function UI.OpenSettings()
    if U.Combat()then return U.Print("Open MS Market Value outside combat.")end
    if A.EconomyUI.frame then A.EconomyUI.frame:Hide()end
    if A.auctionOpen and UI.InstallAuctionTab()then
        UI.Dock();UI.tabLibrary:SetSelected("MSMarketValue")
    else UI.ShowStandalone()end
end

function UI.Toggle()
    if U.Combat() then return U.Print("Open MS Market Value outside combat.") end
    if A.EconomyUI.frame then A.EconomyUI.frame:Hide()end
    if A.auctionOpen and UI.InstallAuctionTab() then
        UI.Dock()
        if UI.panel:IsShown() and AuctionHouseFrameDisplayMode and AuctionHouseFrameDisplayMode.Buy then
            AuctionHouseFrame:SetDisplayMode(AuctionHouseFrameDisplayMode.Buy)
        else
            UI.tabLibrary:SetSelected("MSMarketValue")
        end
        return
    end
    UI.Create()
    local wasShown = UI.frame:IsShown()
    if wasShown then UI.frame:Hide()else UI.ShowStandalone()end
end
