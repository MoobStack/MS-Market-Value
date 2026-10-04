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

local function Check(parent, key, text, x, y)
    local button = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    button:SetSize(26, 26)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button.label = Label(parent, text, x + 29, y - 7, 205)
    button:SetScript("OnClick", function(self)
        if not D.data then return end
        D.data.settings[key] = self:GetChecked() and true or false
        if A.Tooltips then A.Tooltips.RefreshVisible() end
    end)
    UI.checks[key] = button
end

function UI.DiagnosticsText()
    local version, build, _, interface = GetBuildInfo()
    local snapshot = D.Snapshot()
    local lines = {
        A.TITLE .. " " .. A.VERSION .. " / " .. A.BUILD,
        "Client: " .. tostring(version) .. " / " .. tostring(build) .. " / Interface " .. tostring(interface),
        "API available: " .. tostring(S.Supported()),
        "Tooltip callback installed: " .. tostring(A.Tooltips.installed or false),
        "Addon disabled: " .. tostring(A.disabledReason or "no"),
        "Tooltip status: " .. tostring(A.tooltipReason or "ready"),
        "Scan state: " .. S.state,
        "Full-scan cooldown seconds: " .. tostring(S.RemainingCooldown()),
        "Disenchant profile: " .. A.DEProfile.id .. " (Forever unverified)",
    }
    if snapshot then
        lines[#lines + 1] = string.format("Saved snapshot: complete; rows=%d; priced_items=%d; bid_only=%d; sold=%d", snapshot.totalRows, snapshot.distinctItems, snapshot.bidOnlyRows, snapshot.soldRows)
        lines[#lines + 1] = "Snapshot started UTC: " .. date("!%Y-%m-%dT%H:%M:%SZ", snapshot.startedAt)
        lines[#lines + 1] = "Snapshot age: " .. U.Age(snapshot.startedAt)
    else
        lines[#lines + 1] = "Saved snapshot: none for this realm/region"
    end
    lines[#lines + 1] = "Recent local messages:"
    for _, message in ipairs(A.log) do lines[#lines + 1] = message end
    return table.concat(lines, "\n")
end

function UI.ShowDiagnostics()
    if U.Combat() then return U.Print("Open diagnostics outside combat.") end
    if not UI.diagnostics then
        local frame = CreateFrame("Frame", "MSMarketValueDiagnostics", UIParent, "BackdropTemplate")
        frame:SetSize(550, 410)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("DIALOG")
        frame:SetClampedToScreen(true)
        frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        frame:SetBackdropColor(0.07, 0.08, 0.10, 0.98)
        frame:SetBackdropBorderColor(0.25, 0.32, 0.37, 1)
        Label(frame, "Diagnostics - Ctrl+C to copy", 18, -18, 460, "GameFontNormal")
        Button(frame, "Close", 449, -12, 82, function() frame:Hide() end)
        local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 18, -53)
        scroll:SetPoint("BOTTOMRIGHT", -40, 18)
        local edit = CreateFrame("EditBox", nil, scroll)
        edit:SetMultiLine(true)
        edit:SetAutoFocus(false)
        edit:SetFontObject(GameFontHighlightSmall)
        edit:SetWidth(488)
        edit:SetHeight(800)
        edit:SetMaxLetters(16384)
        edit:SetScript("OnEscapePressed", function() frame:Hide() end)
        scroll:SetScrollChild(edit)
        UI.diagnostics, UI.diagnosticsEdit = frame, edit
        table.insert(UISpecialFrames, "MSMarketValueDiagnostics")
    end
    UI.diagnosticsEdit:SetText(UI.DiagnosticsText())
    UI.diagnostics:Show()
    UI.diagnosticsEdit:SetFocus()
    UI.diagnosticsEdit:HighlightText()
end

function UI.Create()
    if UI.frame or U.Combat() then return end
    UI.checks = {}
    local frame = CreateFrame("Frame", "MSMarketValueWindow", UIParent, "BackdropTemplate")
    frame:SetSize(530, 570)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) if not U.Combat() then self:StartMoving() end end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        local px, py = UIParent:GetCenter()
        if D.data and U.Number(x) and U.Number(y) and U.Number(px) and U.Number(py) then
            D.data.windowPosition = { x = x - px, y = y - py }
        end
    end)
    local pos = D.data and D.data.windowPosition
    if type(pos) == "table" and U.Number(pos.x, -10000, 10000) and U.Number(pos.y, -10000, 10000) then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", pos.x, pos.y)
    end
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(0.06, 0.07, 0.09, 0.98)
    frame:SetBackdropBorderColor(0.25, 0.32, 0.37, 1)
    Label(frame, A.TITLE, 18, -18, 400, "GameFontNormalLarge")
    Label(frame, A.VERSION .. "  |  " .. A.BUILD, 18, -42, 490)
    Button(frame, "Close", 426, -14, 85, function() frame:Hide() end)
    UI.snapshotText = Label(frame, "", 18, -77, 493)
    UI.statusText = Label(frame, "", 18, -118, 493)
    UI.progress = CreateFrame("StatusBar", nil, frame)
    UI.progress:SetPoint("TOPLEFT", 18, -167)
    UI.progress:SetSize(493, 9)
    UI.progress:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    UI.progress:SetStatusBarColor(0.35, 0.65, 0.68)
    UI.progress:SetMinMaxValues(0, 1)
    UI.progress:SetValue(0)
    UI.scanButton = Button(frame, "Scan entire AH", 18, -188, 152, function()
        local ok, message = S.Start()
        if not ok then U.Print(message) end
    end)
    UI.stopButton = Button(frame, "Stop scan", 182, -188, 105, function() S.Stop() end)
    Button(frame, "Copy diagnostics", 299, -188, 160, UI.ShowDiagnostics)
    Label(frame, "Tooltip settings", 18, -236, 493, "GameFontNormal")
    Check(frame, "showVendor", "Vendor sell price", 16, -259)
    Check(frame, "showAuction", "Lowest AH buyout", 278, -259)
    Check(frame, "showDisenchant", "Estimated disenchant value", 16, -291)
    Check(frame, "showMaterials", "Material ranges and chances", 278, -291)
    Check(frame, "showAge", "Snapshot age and stale flag", 16, -323)
    Check(frame, "openAtAH", "Open at auction house", 278, -323)
    Label(frame, "Mark prices stale after", 18, -370, 175)
    local stale = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    stale:SetSize(45, 24)
    stale:SetPoint("TOPLEFT", 191, -363)
    stale:SetAutoFocus(false)
    stale:SetNumeric(true)
    stale:SetMaxLetters(3)
    stale:SetScript("OnEscapePressed", function(self) self:ClearFocus(); UI.Refresh() end)
    UI.staleBox = stale
    Label(frame, "hours (1-168)", 247, -370, 112)
    Button(frame, "Apply", 374, -363, 85, function()
        if not D.data then return end
        local value = tonumber(stale:GetText())
        if not U.Number(value, 1, 168, true) then return U.Print("Choose a stale age from 1 to 168 hours.") end
        D.data.settings.staleHours = value
        stale:ClearFocus()
        A.Tooltips.RefreshVisible()
        UI.Refresh()
    end)
    Label(frame, "Disenchant exclusions (for item-specific exceptions)", 18, -413, 493, "GameFontNormal")
    local exclude = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    exclude:SetSize(110, 24)
    exclude:SetPoint("TOPLEFT", 25, -436)
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
    Button(frame, "Exclude item", 151, -436, 140, function() Exclude(true) end)
    Button(frame, "Restore estimate", 303, -436, 156, function() Exclude(false) end)
    Label(frame, "AH values are asking prices, before fees. Disenchant outcomes use a\nClassic reference; Forever probabilities and item eligibility need testing.", 18, -483, 493)
    Label(frame, "Scanning and tooltip calculations run outside combat.", 18, -537, 493)
    table.insert(UISpecialFrames, "MSMarketValueWindow")
    frame:SetScript("OnShow", UI.Refresh)
    frame:Hide()
    UI.frame = frame
end

function UI.Refresh()
    if not UI.frame then return end
    local snapshot = D.Snapshot()
    if snapshot then
        UI.snapshotText:SetText(string.format("Saved: %d auctions | %d priced items | %s%s\nA complete new scan replaces this realm's snapshot.", snapshot.totalRows, snapshot.distinctItems, U.Age(snapshot.startedAt), D.IsStale(snapshot) and " (stale)" or ""))
    else
        UI.snapshotText:SetText("No complete scan saved for this realm/region.\nOpen an auctioneer and click Scan entire AH.")
    end
    local status = S.state .. (S.message and (": " .. S.message) or "")
    if S.work then
        status = status .. string.format("\nRead %d/%d; unresolved %d.", S.work.processedRows, S.totalRows, #S.pending)
    elseif S.RemainingCooldown() > 0 then
        status = status .. string.format("\nNext full scan in %dm %ds.", math.floor(S.RemainingCooldown() / 60), S.RemainingCooldown() % 60)
    end
    if A.disabledReason then status = A.disabledReason end
    if A.tooltipReason then status = status .. "\n" .. A.tooltipReason end
    UI.statusText:SetText(status)
    UI.progress:SetValue(S.work and (S.totalRows > 0 and S.work.processedRows / S.totalRows or 1) or (S.state == "COMPLETE" and 1 or 0))
    UI.scanButton:SetEnabled(D.data ~= nil and not A.disabledReason and A.auctionOpen and not U.Combat() and not S.active and S.RemainingCooldown() == 0)
    UI.stopButton:SetEnabled(S.active)
    for key, check in pairs(UI.checks) do check:SetChecked(D.Settings()[key]) end
    if not UI.staleBox:HasFocus() then UI.staleBox:SetText(tostring(D.Settings().staleHours)) end
end

function UI.Toggle()
    if U.Combat() then return U.Print("Open MS Market Value outside combat.") end
    UI.Create()
    if UI.frame:IsShown() then UI.frame:Hide() else UI.frame:Show() end
end

function UI.OpenAtAH()
    if not D.Settings().openAtAH or U.Combat() then return end
    UI.Create()
    UI.frame:Show()
end
