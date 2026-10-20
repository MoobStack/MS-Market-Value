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
        "TRADE_SKILL_SHOW", "TRADE_SKILL_CLOSE", "TRADE_SKILL_LIST_UPDATE", "TRADE_SKILL_DATA_SOURCE_CHANGED",
        "NEW_RECIPE_LEARNED", "MERCHANT_SHOW", "MERCHANT_UPDATE", "MERCHANT_CLOSED", "UPDATE_FACTION",
        "AUCTION_HOUSE_PURCHASE_COMPLETED", "COMMODITY_PRICE_UPDATED", "COMMODITY_PRICE_UNAVAILABLE",
        "COMMODITY_PURCHASE_SUCCEEDED", "COMMODITY_PURCHASE_FAILED", "MAIL_SHOW", "MAIL_INBOX_UPDATE", "MAIL_CLOSED",
        "PLAYER_MONEY", "BAG_UPDATE_DELAYED", "CHAT_MSG_MONEY",
        "TRAINER_SHOW", "TRAINER_UPDATE", "TRAINER_CLOSED", "TRAINER_SERVICE_INFO_NAME_UPDATE",
        "TAXIMAP_OPENED", "TAXIMAP_CLOSED", "MAIL_SEND_INFO_UPDATE", "MAIL_SEND_SUCCESS", "MAIL_FAILED",
        "TRADE_SHOW", "TRADE_CLOSED", "TRADE_REQUEST_CANCEL", "TRADE_ACCEPT_UPDATE", "TRADE_UPDATE",
        "TRADE_MONEY_CHANGED", "PLAYER_TRADE_MONEY", "TRADE_PLAYER_ITEM_CHANGED", "TRADE_TARGET_ITEM_CHANGED",
        "UI_INFO_MESSAGE", "UI_ERROR_MESSAGE",
    }) do frame:RegisterEvent(event) end
    S.InstallObserver()
    A.Transactions.Install(); A.Cash.Install()
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
    if D.data and not A.disabledReason then A.Transactions.Event(event,arg1,arg2); A.Cash.Event(event,arg1,arg2) end
    if event == "ADDON_LOADED" then
        if U.String(arg1) and arg1 == A.NAME then Initialize() end
        if U.String(arg1) and arg1 == "Blizzard_AuctionHouseUI" and A.auctionOpen then
            A.UI.OnAuctionShow()
            A.Transactions.Install(); A.EconomyUI.InstallBuyButtons()
        end
    elseif event == "PLAYER_LOGIN" then
        Login()
    elseif event == "AUCTION_HOUSE_SHOW" then
        A.auctionOpen = true
        A.UI.OnAuctionShow()
        A.EconomyUI.InstallBuyButtons()
        U.Notify()
    elseif event == "AUCTION_HOUSE_CLOSED" then
        A.auctionOpen = false
        S.Stop("The auction house closed.")
        if A.UI.panel then A.UI.panel:Hide() end
        if A.MarketUI.panel then A.MarketUI.panel:Hide() end
        U.Notify()
    elseif event == "MERCHANT_SHOW" then
        A.Vendor.open, A.Vendor.pending = true, true
        A.Vendor.Capture()
    elseif event == "MERCHANT_UPDATE" then
        A.Vendor.pending = true
    elseif event == "MERCHANT_CLOSED" then
        A.Vendor.open, A.Vendor.pending = false, false
    elseif event == "UPDATE_FACTION" then
        A.Vendor.OnReputation()
    elseif event == "REPLICATE_ITEM_LIST_UPDATE" then
        S.OnResponse()
        if S.state == "COMPLETE" then A.refreshTooltips = true end
    elseif event == "TRADE_SKILL_LIST_UPDATE" then
        A.Crafting.RequestCatalogCheck()
    elseif event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_DATA_SOURCE_CHANGED" or event == "NEW_RECIPE_LEARNED" then
        A.Crafting.Invalidate()
    elseif event == "TRADE_SKILL_CLOSE" then
        A.Crafting.wasOpen = false
        A.CraftingUI.Hide()
    elseif event == "GET_ITEM_INFO_RECEIVED" then
        if U.Number(arg1, 1, 2147483647, true) and U.Accessible(arg2) and arg2 == true then
            A.refreshTooltips = true
            A.Crafting.OnItemInfo(arg1)
            A.Market.OnItemInfo(arg1)
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        S.Stop("Combat started.")
        if A.UI.frame then A.UI.frame:Hide() end
        if A.UI.panel then A.UI.panel:Hide() end
        if A.MarketUI.panel then A.MarketUI.panel:Hide() end
        U.Notify()
        if A.UI.diagnostics then A.UI.diagnostics:Hide() end
        if A.CraftingUI.frame then A.CraftingUI.frame:Hide() end
        if A.CraftingUI.opener then A.CraftingUI.opener:Hide() end
        if A.EconomyUI.frame then A.EconomyUI.frame:Hide() end
        if A.EconomyUI.csvFrame then A.EconomyUI.csvFrame:Hide() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        A.refreshTooltips = true
        if A.auctionOpen then A.UI.OnAuctionShow() end
        U.Notify()
    elseif event == "PLAYER_LOGOUT" then
        S.Discard("Logging out; the current client session's auction buffer cannot be saved.")
    end
end)

local scanElapsed, uiElapsed = 0, 0
frame:SetScript("OnUpdate", function(_, elapsed)
    scanElapsed, uiElapsed = scanElapsed + elapsed, uiElapsed + elapsed
    S.CopyTick()
    A.Watchlist.Tick()
    if A.MarketUI.panel and A.MarketUI.panel:IsVisible() then A.Market.Tick() end
    if scanElapsed >= 0.05 then
        scanElapsed = 0
        local wasActive = S.active
        S.Tick()
        if wasActive and not S.active and S.state == "COMPLETE" then A.refreshTooltips = true end
    end
    if uiElapsed >= 0.25 then
        uiElapsed = 0
        if D.data and not A.disabledReason then A.Cash.Tick(); A.Transactions.Tick() end
        A.History.Maintain()
        A.Watchlist.Ensure()
        A.Crafting.Tick()
        if A.Vendor.pending and A.Vendor.open then A.Vendor.Capture() end
        if A.MarketUI.panel and A.MarketUI.panel:IsVisible() and not U.Combat() then
            A.Market.Ensure(A.MarketUI.view, A.MarketUI.sort)
            A.MarketUI.Refresh()
        end
        if A.auctionOpen and not A.UI.tabInstalled and not U.Combat() then A.UI.InstallAuctionTab() end
        if A.auctionOpen and not U.Combat() then A.EconomyUI.InstallBuyButtons() end
        if A.EconomyUI.frame and A.EconomyUI.frame:IsShown() and not U.Combat() then A.EconomyUI.Refresh() end
        if (A.UI.frame and A.UI.frame:IsShown()) or (A.UI.panel and A.UI.panel:IsShown()) then A.UI.Refresh() end
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
    elseif command == "pause" or command == "stop" then
        if not S.Pause() then U.Print("No scan is running.") end
    elseif command == "resume" then
        local ok, reason = S.Resume()
        if not ok then U.Print(reason) end
    elseif command == "discard" then
        if not S.Discard() then U.Print("No incomplete scan to discard.") end
    elseif command == "restart" then
        local ok, reason = S.Restart()
        if not ok then U.Print(reason) end
    elseif command == "market" then
        A.MarketUI.Show()
    elseif command == "watch" then
        A.EconomyUI.Show("watch")
    elseif command == "ledger" then
        A.EconomyUI.Show("ledger")
    elseif command == "craft" then
        A.CraftingUI.Show()
    elseif command == "status" then
        U.Print(S.state .. (S.message and (": " .. S.message) or ""))
        local snapshot = D.Snapshot()
        U.Print(snapshot and ("Saved complete snapshot: " .. tostring(snapshot.totalRows) .. " rows, " .. U.Age(snapshot.startedAt) .. ".") or "No complete snapshot for this market.")
    elseif command == "diagnostics" then
        A.UI.ShowDiagnostics()
    else
        U.Print("/msmv | scan | pause | resume | restart | discard | craft | market | watch | ledger | status | diagnostics")
    end
end
