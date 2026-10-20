local _, A = ...
local U, D, H, M = A.Util, A.DB, A.History, A.Market
local W = { rows = {}, revision = 0, publications = 0 }
A.Watchlist = W
local MAX_ITEMS = 200

function W.Initialize()
    local saved = D.data.watchlists
    if saved == nil then saved = { schema = 1, markets = {} }; D.data.watchlists = saved end
    if not U.Table(saved) or not U.Accessible(saved.schema) or saved.schema ~= 1 or not U.Table(saved.markets) then
        W.reason = "Unsupported watchlist data preserved."; return
    end
    W.data = saved
end

local function Profile(create)
    local key = U.MarketKey()
    if not W.data or not key then return nil end
    local profile = W.data.markets[key]
    if profile == nil and create then profile = { entries = {} }; W.data.markets[key] = profile end
    if profile and U.Table(profile) and U.Table(profile.entries) then return profile end
end

local function Valid(row)
    return U.Table(row) and U.Number(row.id, 1, 2147483647, true) and
        U.Accessible(row.suffix) and (row.suffix == nil or U.Number(row.suffix, -2147483647, 2147483647, true)) and
        U.Number(row.maxBuy, 0, 100000000, true) and U.Number(row.minReturn, 0, 1000, true) and
        U.Number(row.minProfit, 0, 100000000, true)
end

function W.Entries()
    local profile, result, visited = Profile(false), {}, 0
    for key, row in pairs(profile and profile.entries or {}) do
        visited = visited + 1
        if visited > 400 then W.reason = "Oversized watchlist preserved; restore a valid backup."; return {} end
        if U.String(key) and Valid(row) and key == row.id .. ":" .. (row.suffix or "*") then
            result[#result + 1] = { key = key, entry = row }
            if #result > MAX_ITEMS then W.reason = "More than 200 watches saved; restore a valid backup."; return {} end
        end
    end
    table.sort(result, function(a,b) return a.key < b.key end)
    if W.data then W.reason = nil end
    return result
end

function W.Save(input, maxBuy, minReturn, minProfit)
    if U.Combat() then return false, "Edit watchlists outside combat." end
    local id, suffix
    if U.Number(input, 1, 2147483647, true) then id = input
    elseif U.String(input) then
        if string.match(input, "^%s*%d+%s*$") then id = tonumber(input)
        else
            id = U.ItemID(input)
            local variant = U.VariantKey(input)
            suffix = variant and tonumber(string.match(variant, ":(%-?%d+)$"))
        end
    end
    local row = { id = id, suffix = suffix, maxBuy = maxBuy, minReturn = minReturn, minProfit = minProfit }
    if not Valid(row) then return false, "Choose an item ID/link and valid price/return targets." end
    local profile = Profile(true)
    if not profile then return false, W.reason or "The current market is unavailable." end
    local key = id .. ":" .. (suffix or "*")
    local entries = W.Entries()
    if W.reason then return false, W.reason end
    if profile.entries[key] == nil and #entries >= MAX_ITEMS then return false, "Watchlist limit: 200 items per market." end
    local info = A.Valuation.ItemInfo(suffix ~= nil and input or id)
    row.name = info and info.name or ("Item " .. id)
    local old = profile.entries[key]
    if Valid(old) then row.lastAlertAt = old.lastAlertAt end
    profile.entries[key] = row; W.revision = W.revision + 1
    return true, key
end

function W.Remove(key)
    if U.Combat() or not U.String(key) then return false end
    local profile = Profile(false)
    if not profile or not profile.entries[key] then return false end
    profile.entries[key] = nil; W.revision = W.revision + 1; return true
end

local function Evaluate(job, watch)
    local entry = watch.entry
    local row = { id = entry.id, suffix = entry.suffix, key = watch.key, watch = entry,
        name = U.String(entry.name) and entry.name or ("Item " .. entry.id), days = 0, matched = false }
    row.link = "item:" .. row.id .. ":0:0:0:0:0:" .. (row.suffix or 0) .. ":0"
    if not job.fresh then row.status = "Fresh scan needed"; return row end
    local series = row.suffix ~= nil and job.snapshot.variants or job.snapshot.prices
    local index = row.suffix ~= nil and (row.id .. ":" .. row.suffix) or row.id
    local price = series[index]
    if not U.Table(price) or not U.Number(price.low, 0, 1000000000000) or price.low <= 0 then
        row.status = "Not listed"; return row
    end
    row.current, row.buy = price.low, math.ceil(price.low)
    local samples, day = {}, math.floor(job.snapshot.startedAt / 86400)
    local history = H.data and H.data.markets[job.key] or {}
    for date = day - job.lookback, day - 1 do
        local record = history[date]
        local value = record and (row.suffix ~= nil and record.variants or record.prices)[index]
        if U.Number(value, 0, 1000000000000) and value > 0 then samples[#samples + 1] = value end
    end
    row.days = #samples
    local settings = { marketMinDays = job.minDays, marketFee = job.fee, marketMove = 0,
        marketMinReturn = entry.minReturn, marketMinProfit = entry.minProfit }
    local estimate = M.Evaluate(row.current, samples, settings)
    if estimate then
        for _, key in ipairs({ "profit", "roi", "baseline", "median", "low", "high", "maxBuy", "movement" }) do row[key] = estimate[key] end
    end
    local priceTarget, profitTarget = entry.maxBuy > 0, entry.minReturn > 0 or entry.minProfit > 0
    if not priceTarget and not profitTarget then row.status = "Tracking only"
    elseif profitTarget and not estimate then row.status = "More history needed"
    else
        row.matched = (not priceTarget or row.buy <= entry.maxBuy) and
            (not profitTarget or (row.profit >= entry.minProfit and row.roi >= entry.minReturn and row.profit > 0))
        row.status = row.matched and "TARGET MET" or "Watching"
    end
    return row
end

function W.Ensure()
    if not W.data then return end
    local key, snapshot = U.MarketKey(), D.Snapshot()
    local fresh = snapshot ~= nil and U.Number(snapshot.startedAt, 0, U.Now()) and not D.IsStale(snapshot)
    local s = D.Settings()
    local signature = table.concat({ W.revision, H.revision or 0, s.marketLookback, s.marketMinDays, s.marketFee, tostring(fresh) }, "|")
    if W.key ~= key then W.rows, W.snapshot = {}, nil end
    W.key = key
    if W.source == snapshot and W.signature == signature then return end
    W.source, W.signature = snapshot, signature
    W.job = { key = key, snapshot = snapshot, fresh = fresh, entries = W.Entries(), rows = {}, cursor = 1,
        signature = signature, revision = W.revision, historyRevision = H.revision, lookback = s.marketLookback, minDays = s.marketMinDays, fee = s.marketFee }
end

function W.Tick()
    if U.Combat() then return end
    local job = W.job
    if not job then return end
    local settings = D.Settings()
    if job.key ~= U.MarketKey() or job.snapshot ~= D.Snapshot() or job.historyRevision ~= H.revision or job.signature ~= W.signature or
       job.revision ~= W.revision or job.fee ~= settings.marketFee or job.lookback ~= settings.marketLookback or job.minDays ~= settings.marketMinDays or
       (job.fresh and (D.IsStale(job.snapshot) or not U.Number(job.snapshot.startedAt,0,U.Now()))) then W.job = nil; W.signature = nil; return end
    local start = debugprofilestop and debugprofilestop() or 0
    for _ = 1, 20 do
        local watch = job.entries[job.cursor]
        if not watch then
            W.rows, W.snapshot, W.job = job.rows, job.snapshot, nil
            W.publications = W.publications + 1
            local alerts = 0
            for _, row in ipairs(W.rows) do
                if row.matched and D.Settings().watchAlerts and (not U.Number(row.watch.lastAlertAt,0,U.Now()) or row.watch.lastAlertAt ~= job.snapshot.startedAt) then
                    row.watch.lastAlertAt = job.snapshot.startedAt; alerts = alerts + 1
                end
            end
            if alerts > 0 then U.Print(alerts .. " watchlist target(s) met. Type /msmv watch to review.") end
            return
        end
        job.rows[#job.rows + 1] = Evaluate(job, watch); job.cursor = job.cursor + 1
        if debugprofilestop and debugprofilestop() - start >= A.FRAME_BUDGET_MS then return end
    end
end
