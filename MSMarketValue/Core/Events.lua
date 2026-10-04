local _, A = ...
local U, D, S = A.Util, A.DB, A.Scanner
local frame = CreateFrame("Frame")
A.eventFrame = frame
A.auctionOpen = false

local function Initialize()
    if A.initialized then return end
    A.initialized = true
    local _, _, _, interface = GetBuildInfo()
    if not U.Number(interface, A.INTERFACE, A.INTERFACE, true) then
        A.disabledReason = "This build targets WoW Forever Interface 16001. See the compatibility documentation."
        return
    end
    if not D.Initialize() then return end
    if type(issecretvalue) ~= "function" then
        A.disabledReason = "The client's restricted-value detection API is unavailable."
        return
    end
    if not S.Supported() then
        A.disabledReason = "The required modern auction API is unavailable on this client."
        return
    end
    for _, event in ipairs({
        "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED", "REPLICATE_ITEM_LIST_UPDATE",
        "GET_ITEM_INFO_RECEIVED", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_LOGOUT",
    }) do frame:RegisterEvent(event) end
    S.InstallObserver()
end

local function Login()
    if not A.initialized then Initialize() end
    if not A.disabledReason then
        A.Tooltips.Install()
    end
    U.Print(A.VERSION .. " / " .. A.BUILD .. ". Type /msmv to open.")
    if A.disabledReason then U.Print(A.disabledReason) end
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "ADDON_LOADED" then
        if U.String(arg1) and arg1 == A.NAME then Initialize() end
    elseif event == "PLAYER_LOGIN" then
        Login()
    elseif event == "AUCTION_HOUSE_SHOW" then
        A.auctionOpen = true
        A.UI.OpenAtAH()
        U.Notify()
    elseif event == "AUCTION_HOUSE_CLOSED" then
        A.auctionOpen = false
        S.Stop("The auction house closed.")
        U.Notify()
    elseif event == "REPLICATE_ITEM_LIST_UPDATE" then
        S.OnResponse()
        if S.state == "COMPLETE" then A.refreshTooltips = true end
    elseif event == "GET_ITEM_INFO_RECEIVED" then
        if U.Number(arg1, 1, 2147483647, true) and U.Accessible(arg2) and arg2 == true then
            A.refreshTooltips = true
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        S.Stop("Combat started.")
        if A.UI.frame then A.UI.frame:Hide() end
        if A.UI.diagnostics then A.UI.diagnostics:Hide() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        A.refreshTooltips = true
        U.Notify()
    elseif event == "PLAYER_LOGOUT" then
        S.Stop("Logging out.")
    end
end)

local scanElapsed, uiElapsed = 0, 0
frame:SetScript("OnUpdate", function(_, elapsed)
    scanElapsed, uiElapsed = scanElapsed + elapsed, uiElapsed + elapsed
    if scanElapsed >= 0.05 then
        scanElapsed = 0
        local wasActive = S.active
        S.Tick()
        if wasActive and not S.active and S.state == "COMPLETE" then A.refreshTooltips = true end
    end
    if uiElapsed >= 0.25 then
        uiElapsed = 0
        if A.UI.frame and A.UI.frame:IsShown() then A.UI.Refresh() end
        if A.refreshTooltips and not U.Combat() then
            A.refreshTooltips = false
            A.Tooltips.RefreshVisible()
        end
    end
end)

SLASH_MSMARKETVALUE1 = "/msmv"
SLASH_MSMARKETVALUE2 = "/msmarketvalue"
SlashCmdList.MSMARKETVALUE = function(message)
    if not U.String(message) then return end
    local command = string.lower(string.match(message, "^%s*(%S+)") or "")
    if command == "" then
        A.UI.Toggle()
    elseif command == "scan" then
        local ok, reason = S.Start()
        if not ok then U.Print(reason) end
    elseif command == "stop" then
        if not S.Stop() then U.Print("No scan is running.") end
    elseif command == "status" then
        U.Print(S.state .. (S.message and (": " .. S.message) or ""))
        local snapshot = D.Snapshot()
        U.Print(snapshot and ("Saved complete snapshot: " .. tostring(snapshot.totalRows) .. " rows, " .. U.Age(snapshot.startedAt) .. ".") or "No complete snapshot for this realm/region.")
    elseif command == "diagnostics" then
        A.UI.ShowDiagnostics()
    else
        U.Print("/msmv | /msmv scan | /msmv stop | /msmv status | /msmv diagnostics")
    end
end
