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
        "Test revision: " .. tostring(A.TEST_REVISION),
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
    Label(scan, A.VERSION .. "  |  " .. A.BUILD, 395, -14, 335)
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
    Label(settings, "Tooltip settings", 14, -13, 338, "GameFontNormal")
    Check(settings, "showVendor", "Vendor sell price", -36)
    Check(settings, "showAuction", "Lowest AH buyout", -64)
    Check(settings, "showDisenchant", "Estimated disenchant value", -92)
    Check(settings, "showMaterials", "Material ranges and chances", -120)
    Check(settings, "showAge", "Snapshot age and stale flag", -148)

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

function UI.Toggle()
    if U.Combat() then return U.Print("Open MS Market Value outside combat.") end
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
    UI.content:Hide()
    UI.content:SetParent(UI.frame)
    UI.content:SetFrameStrata(UI.frame:GetFrameStrata())
    UI.content:SetFrameLevel(UI.frame:GetFrameLevel() + 1)
    UI.content:ClearAllPoints()
    UI.content:SetPoint("TOPLEFT", UI.frame, "TOPLEFT", 16, -38)
    UI.content:Show()
    if wasShown then UI.frame:Hide() else UI.frame:Show() end
end
