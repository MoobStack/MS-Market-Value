local _, A = ...
local U, D = A.Util, A.DB
local S = { state = "IDLE", active = false, requestCount = 0, responseCount = 0, dataUpdateCount = 0 }
A.Scanner = S

local function SetState(state, message)
    S.state, S.message = state, message
    U.Log(state .. (message and (": " .. message) or ""))
    U.Notify()
end

function S.RemainingCooldown()
    return D.data and math.max(0, math.ceil(D.data.cooldownUntil - U.Now())) or 0
end

function S.Supported()
    if not C_AuctionHouse then return false end
    for _, name in ipairs({ "ReplicateItems", "GetNumReplicateItems", "GetReplicateItemInfo", "GetReplicateItemLink" }) do
        if type(C_AuctionHouse[name]) ~= "function" then return false end
    end
    return true
end

function S.Stop(reason, failed)
    if not S.active then return false end
    S.active, S.work, S.pending, S.retryWork = false, nil, nil, nil
    SetState(failed and "FAILED" or "CANCELLED", reason or "Stopped by player.")
    U.Print(S.message .. " Previous snapshot kept.")
    return true
end

local function Complete()
    local work = S.work
    if not work then return S.Stop("No staged snapshot.", true) end
    if #S.pending ~= 0 then return S.Stop("Some auction rows remain unresolved.", true) end
    local ok, reason = D.Commit(work)
    if not ok then return S.Stop(reason, true) end
    S.active, S.work, S.pending, S.retryWork = false, nil, nil, nil
    SetState("COMPLETE", string.format("%d rows; %d priced items. Snapshot replaced.", work.totalRows, work.distinctItems))
    U.Print(S.message)
end

function S.Start()
    if A.disabledReason then return false, A.disabledReason end
    if not D.data then return false, "Saved data is not ready." end
    if S.active then return false, "A scan is already running." end
    if not A.auctionOpen then return false, "Open an auctioneer first." end
    if U.Combat() then return false, "Scanning is available outside combat." end
    if not S.Supported() then return false, "The required modern auction API is unavailable." end
    if S.RemainingCooldown() > 0 then
        return false, string.format("Full-scan cooldown: %dm %ds remaining.", math.floor(S.RemainingCooldown() / 60), S.RemainingCooldown() % 60)
    end
    if C_AuctionHouse.IsThrottledMessageSystemReady then
        local ok, ready = pcall(C_AuctionHouse.IsThrottledMessageSystemReady)
        if not ok or not U.Accessible(ready) or ready ~= true then
            return false, "The auction server is busy. Try again when it is ready."
        end
    end
    local market = U.MarketInfo()
    local key = market.key
    if not key then return false, market.reason end
    U.Log("Scan market: " .. key .. " (" .. market.label .. "; " .. market.regionSource .. ").")
    S.active, S.marketKey, S.marketInfo = true, key, market
    S.requestAt, S.startedMono = U.Now(), U.Mono()
    S.cursor, S.pending, S.loaded = 0, {}, {}
    S.responseCount, S.dataUpdateCount = 0, 0
    S.work, S.retryWork, S.totalRows = nil, nil, nil
    -- Keep the throttle across reload/logout, including cancelled requests. A
    -- locally cancelled request is not evidence that the server cancelled it.
    D.data.cooldownUntil = S.requestAt + A.SCAN_COOLDOWN
    SetState("WAITING", "Waiting for the auction server's full snapshot.")
    S.sending = true
    S.requestCount = S.requestCount + 1
    local ok = pcall(C_AuctionHouse.ReplicateItems)
    S.sending = false
    if not ok then
        S.Stop("The client refused the full-scan request.", true)
        return false, S.message
    end
    return true
end

function S.OnResponse()
    if not S.active then return end
    S.responseCount = S.responseCount + 1
    local ok, count = pcall(C_AuctionHouse.GetNumReplicateItems)
    if not ok or not U.Number(count, 0, A.MAX_ROWS, true) then
        return S.Stop("The server returned an unreadable or oversized auction count.", true)
    end
    if S.state == "PROCESSING" or S.state == "RESOLVING" then
        -- Native item-data readiness can emit the same event again. Accepted
        -- rows stay accepted, pending rows are retried, and no request/restart
        -- or duplicate price accumulation occurs for a same-count update.
        if count ~= S.totalRows then
            return S.Stop("The auction replication row count changed.", true)
        end
        S.dataUpdateCount = S.dataUpdateCount + 1
        if S.state == "RESOLVING" then S.nextRetry = U.Mono() end
        return
    end
    if S.state ~= "WAITING" then return end
    S.totalRows = count
    S.work = D.NewSnapshot(S.marketKey, count, S.requestAt)
    S.work.marketKind, S.work.ruleset = S.marketInfo.kind, S.marketInfo.ruleset
    S.work.region, S.work.faction = S.marketInfo.region, S.marketInfo.faction
    SetState("PROCESSING", "Reading every auction row.")
    if count == 0 then Complete() end
end

local function ReadRow(index)
    local values = { pcall(C_AuctionHouse.GetReplicateItemInfo, index) }
    if not values[1] then return nil, "Auction row access failed." end
    local quantity, buyout, saleStatus, itemID, allInfo = values[4], values[11], values[17], values[18], values[19]
    for _, field in ipairs({ 4, 11, 17, 18, 19 }) do
        if not U.Accessible(values[field]) then return nil, "Auction data is restricted; scan stopped." end
    end
    if allInfo ~= true then
        if U.Number(itemID, 1, 2147483647, true) and not S.loaded[itemID] and
           C_Item and C_Item.RequestLoadItemDataByID then
            S.loaded[itemID] = true
            pcall(C_Item.RequestLoadItemDataByID, itemID)
        end
        return false
    end
    if not U.Number(quantity, 1, A.MAX_ROWS * 10000, true) or
       not U.Number(buyout, 0, 9007199254740991, true) or
       not U.Number(itemID, 1, 2147483647, true) or
       not U.Number(saleStatus, 0, 1, true) then
        return nil, "An auction row contains invalid price, quantity, item ID, or sale status."
    end
    local ok, link = pcall(C_AuctionHouse.GetReplicateItemLink, index)
    if not ok or not U.String(link) then link = nil end
    return { itemID = itemID, quantity = quantity, buyout = buyout, link = link, saleStatus = saleStatus }
end

local function Process(index)
    local row, reason = ReadRow(index)
    if row == nil then S.Stop(reason, true); return nil end
    if row == false then return false end
    D.AddRow(S.work, row.itemID, row.quantity, row.buyout, row.link, row.saleStatus)
    return true
end

local function BudgetExpired(startMS, processed)
    if processed >= A.BATCH_SIZE then return true end
    return debugprofilestop and (debugprofilestop() - startMS) >= A.FRAME_BUDGET_MS
end

function S.Tick()
    if not S.active then return end
    if not A.auctionOpen then return S.Stop("The auction house closed.") end
    if U.Combat() then return S.Stop("Combat started.") end
    if U.MarketKey() ~= S.marketKey then return S.Stop("The market changed.", true) end
    local now = U.Mono()
    if S.state == "WAITING" then
        if now - S.startedMono > A.REQUEST_TIMEOUT then
            S.Stop("No full-scan response arrived. The server may still be on cooldown.", true)
        end
        return
    end
    local ok, count = pcall(C_AuctionHouse.GetNumReplicateItems)
    if not ok or not U.Number(count, 0, A.MAX_ROWS, true) or count ~= S.totalRows then
        return S.Stop("The auction replication buffer changed.", true)
    end
    local startMS = debugprofilestop and debugprofilestop() or 0
    local processed = 0
    if S.state == "PROCESSING" then
        while S.active and S.cursor < S.totalRows do
            local index = S.cursor
            local result = Process(index)
            if result == nil then return end
            if result == false then S.pending[#S.pending + 1] = index end
            S.cursor = index + 1
            processed = processed + 1
            if BudgetExpired(startMS, processed) then break end
        end
        if S.active and S.cursor == S.totalRows then
            if #S.pending == 0 then return Complete() end
            S.resolveDeadline, S.nextRetry = now + A.RESOLVE_TIMEOUT, now + 0.5
            S.retryCursor, S.retryWork = 1, {}
            SetState("RESOLVING", "Waiting for missing auction item data.")
        end
    elseif S.state == "RESOLVING" then
        if now > S.resolveDeadline then return S.Stop("Auction item data did not finish loading.", true) end
        if now < S.nextRetry then return end
        while S.active and S.retryCursor <= #S.pending do
            local index = S.pending[S.retryCursor]
            local result = Process(index)
            if result == nil then return end
            if result == false then S.retryWork[#S.retryWork + 1] = index end
            S.retryCursor = S.retryCursor + 1
            processed = processed + 1
            if BudgetExpired(startMS, processed) then break end
        end
        if S.active and S.retryCursor > #S.pending then
            S.pending, S.retryWork, S.retryCursor = S.retryWork, {}, 1
            S.nextRetry = now + 0.5
            if #S.pending == 0 then return Complete() end
        end
    end
end

function S.InstallObserver()
    if S.observerInstalled or not S.Supported() or not hooksecurefunc then return end
    S.observerInstalled = true
    hooksecurefunc(C_AuctionHouse, "ReplicateItems", function()
        if S.active and not S.sending then
            S.Stop("Another addon requested a full scan at the same time.", true)
        end
    end)
end
