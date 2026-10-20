local _, A = ...
local U, D, H = A.Util, A.DB, A.History
local M = { rows = {}, builds = 0, publications = 0 }
A.Market = M
local MAX_PRICE, MAX_RESULTS, MAX_ITEMS = 1000000000000, 200, 50000

local function Price(value) return U.Number(value, 0, MAX_PRICE) and value > 0 end
local function Quantile(values, fraction)
    local position = (#values - 1) * fraction + 1
    local low = math.floor(position)
    return values[low] + ((values[low + 1] or values[low]) - values[low]) * (position - low)
end

function M.Evaluate(current, samples, settings)
    if not Price(current) or not U.Table(samples) or #samples < settings.marketMinDays then return nil end
    local values, chronological = {}, {}
    for _, value in ipairs(samples) do
        if not Price(value) then return nil end
        values[#values + 1], chronological[#chronological + 1] = value, value
    end
    table.sort(values)
    -- The lower quartile is deliberately below the median. One inflated day
    -- should not create a resale signal or an unrealistic target sell price.
    local median, baseline = Quantile(values, 0.5), math.floor(Quantile(values, 0.25))
    local buy = math.ceil(current)
    local proceeds = math.floor(baseline * (100 - settings.marketFee) / 100)
    local profit = proceeds - buy
    local row = { current = current, buy = buy, baseline = baseline, median = median,
        low = values[1], high = values[#values], days = #values, profit = profit,
        roi = profit / buy * 100, movement = (current - median) / median * 100,
        maxBuy = math.max(0, math.floor(math.min(proceeds / (1 + settings.marketMinReturn / 100), proceeds - settings.marketMinProfit))) }
    -- Compare prices directly so an exact percentage boundary is inclusive.
    local drop = current < median and current <= median * (100 - settings.marketMove) / 100
    local rise = current > median and current >= median * (100 + settings.marketMove) / 100
    row.deal = profit >= settings.marketMinProfit and profit > 0 and row.roi >= settings.marketMinReturn and
        (settings.marketMove == 0 or drop)
    row.rising, row.falling = rise, drop
    if #chronological >= 5 then
        local recent = { chronological[#chronological - 1], chronological[#chronological], current }
        local older = { chronological[#chronological - 4], chronological[#chronological - 3], chronological[#chronological - 2] }
        table.sort(recent); table.sort(older)
        row.trend = (recent[2] / older[2] - 1) * 100
    end
    return row
end

local function Signature(view, sort)
    local s = D.Settings()
    return table.concat({ view, sort, s.marketLookback, s.marketMinDays, s.marketFee,
        s.marketMinReturn, s.marketMinProfit, s.marketMove, A.Vendor.revision }, "|")
end

local function Fresh(snapshot)
    return snapshot and U.Number(snapshot.startedAt, 0, U.Now()) and not D.IsStale(snapshot)
end

function M.Clear(reason)
    M.job, M.rows, M.snapshot, M.reason, M.ready = nil, {}, nil, reason, true
    M.source, M.signature, M.examined, M.eligible = nil, nil, 0, 0
end

function M.Ensure(view, sort, force)
    H.Maintain()
    view = (view == "rising" or view == "falling" or view == "all") and view or "deals"
    sort = sort == "profit" and "profit" or "return"
    local key, snapshot = U.MarketKey(), D.Snapshot()
    if not Fresh(snapshot) then M.Clear(snapshot and "The saved scan is stale. Complete a fresh AH scan for current signals." or "Complete an AH scan to look for opportunities."); return end
    if not H.data then M.Clear(H.reason or "Price history is unavailable."); return end
    local signature = Signature(view, sort)
    if M.key ~= key then M.rows, M.snapshot, M.job = {}, nil, nil end
    M.key = key
    if not force and M.source == snapshot and M.historyRevision == H.revision and M.signature == signature then return end
    M.source, M.historyRevision, M.signature = snapshot, H.revision, signature
    local settings = {}
    for name, value in pairs(D.Settings()) do if U.String(name) and string.sub(name, 1, 6) == "market" then settings[name] = value end end
    local day, records = math.floor(snapshot.startedAt / 86400), {}
    local days = H.data.markets[key] or {}
    for date = day - settings.marketLookback, day - 1 do
        local record = days[date]
        if record and record.startedAt < snapshot.startedAt then records[#records + 1] = record end
    end
    local maps = { snapshot.variants }
    for _, record in ipairs(records) do maps[#maps + 1] = record.variants end
    M.job = { snapshot = snapshot, records = records, settings = settings, maps = maps, vendorKnown = A.Vendor.KnownItems(),
        mapIndex = 1, variants = {}, phase = "variants", rows = {}, examined = 0, eligible = 0,
        view = view, sort = sort, day = day, started = U.Mono() }
    M.ready, M.reason = false, nil
    M.builds = M.builds + 1
end

local function Identity(key, variant)
    if variant then
        if not U.String(key) then return nil end
        local id, suffix = string.match(key, "^(%d+):(%-?%d+)$")
        id, suffix = tonumber(id), tonumber(suffix)
        if not U.Number(id, 1, 2147483647, true) or not U.Number(suffix, -2147483647, 2147483647, true) then return nil end
        return id, suffix
    end
    if U.Number(key, 1, 2147483647, true) then return key end
end

local function Better(a, b, job)
    local av, bv
    if job.view == "rising" then av, bv = a.movement, b.movement
    elseif job.view == "falling" then av, bv = -a.movement, -b.movement
    elseif job.sort == "profit" then av, bv = a.profit, b.profit
    else av, bv = a.roi, b.roi end
    if av == bv then return a.key < b.key end
    return av > bv
end

local function Include(job, row)
    if job.view == "deals" then return row.deal end
    if job.view == "rising" then return row.rising end
    if job.view == "falling" then return row.falling end
    return row.deal or row.rising or row.falling
end

local function Evaluate(job, key, entry, variant)
    job.examined = job.examined + 1
    local id, suffix = Identity(key, variant)
    if not id or (not variant and job.variants[id]) or job.vendorKnown[id] or
       not U.Table(entry) or not Price(entry.low) then return end
    local values = {}
    for _, record in ipairs(job.records) do
        local value = (variant and record.variants or record.prices)[key]
        if Price(value) then values[#values + 1] = value end
    end
    local row = M.Evaluate(entry.low, values, job.settings)
    if not row or not Include(job, row) then return end
    job.eligible = job.eligible + 1
    row.id, row.suffix, row.key = id, suffix, tostring(key)
    row.link = "item:" .. id .. ":0:0:0:0:0:" .. (suffix or 0) .. ":0"
    local rows = job.rows
    local low, high = 1, #rows + 1
    while low < high do
        local middle = math.floor((low + high) / 2)
        if Better(row, rows[middle], job) then high = middle else low = middle + 1 end
    end
    if low <= MAX_RESULTS then
        table.insert(rows, low, row)
        if #rows > MAX_RESULTS then table.remove(rows) end
    end
end

local function Publish(job)
    M.rows, M.snapshot, M.settings = job.rows, job.snapshot, job.settings
    M.examined, M.eligible, M.truncated = job.examined, job.eligible, job.truncated
    M.ready, M.job = true, nil
    M.publications = M.publications + 1
    M.reason = job.reason or (#M.rows == 0 and ("No matching signals. Check the filters; at least " .. job.settings.marketMinDays .. " prior priced days are needed per item.") or nil)
end

function M.Tick()
    if U.Combat() or not D.data or A.disabledReason then return end
    local job = M.job
    if not job then return end
    if M.key ~= U.MarketKey() then M.Clear("Market changed; checking the new market."); return end
    if job.snapshot ~= D.Snapshot() or M.historyRevision ~= H.revision then M.job = nil; return end
    if not Fresh(job.snapshot) then M.Clear("The saved scan is stale. Complete a fresh AH scan."); return end
    local start = debugprofilestop and debugprofilestop() or 0
    for _ = 1, 500 do
        if job.phase == "variants" then
            local map = job.maps[job.mapIndex]
            if not map then job.phase, job.cursor, job.mapIndex = "prices", nil, 1
            else
                local key = next(map, job.cursor)
                job.cursor = key
                if key == nil then job.mapIndex = job.mapIndex + 1
                else
                    job.prepared = (job.prepared or 0) + 1
                    local id = Identity(key, true)
                    if id and job.snapshot.prices[id] ~= nil then job.variants[id] = true end
                    if job.prepared >= 500000 then
                        job.reason = "History is too large for this analysis. Reduce the lookback window."
                        job.rows, job.truncated = {}, true; Publish(job); return
                    end
                end
            end
        else
            local variant = job.phase == "prices-variants"
            local map = variant and job.snapshot.variants or job.snapshot.prices
            local key, entry = next(map, job.cursor)
            job.cursor = key
            if key == nil then
                if variant then Publish(job); return else job.phase = "prices-variants" end
            else
                Evaluate(job, key, entry, variant)
                if job.examined >= MAX_ITEMS then job.truncated = true; Publish(job); return end
            end
        end
        if debugprofilestop and debugprofilestop() - start >= A.FRAME_BUDGET_MS then return end
    end
end

function M.Name(row)
    if row.name then return row.name end
    local value = A.Valuation.ItemInfo(row.link)
    row.name = value and value.name or (A.Crafting.MaterialName(row.id) .. (row.suffix and row.suffix ~= 0 and (" (suffix " .. row.suffix .. ")") or ""))
    return row.name
end

function M.OnItemInfo(id)
    for _, row in ipairs(M.rows) do if row.id == id then row.name = nil end end
end
