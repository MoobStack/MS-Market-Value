local _, A = ...
local U, D = A.Util, A.DB
local H = { cache = {}, cacheEntries = 0 }
A.History = H

local MAX_PRICE, MAX_ID, MAX_CACHE = 9007199254740991, 2147483647, 4096
local MAX_SCANS = math.ceil(86400 / A.SCAN_COOLDOWN) + 1
H.basisNames = { daily = "Daily", intraday = "Intraday" }

local function Day(timestamp)
    if U.Number(timestamp, 0, MAX_PRICE) then return math.floor(timestamp / 86400) end
end

local function MarketKey(key) return U.String(key) and #key > 0 and #key <= 256 end

local function ItemKey(key) return U.Number(key, 1, MAX_ID, true) end

local function VariantKey(key)
    return U.SplitVariant(key)~=nil
end

local function Price(value) return U.Number(value, 0, MAX_PRICE) and value > 0 end

local function ResetCache(dataChanged)
    H.cache, H.cacheEntries = {}, 0
    if dataChanged then
        H.dailyViews, H.priceViews = {}, {}
        H.revision = (H.revision or 0) + 1
    end
end

local function CopyPrices(source, keyCheck, records)
    local result, count = {}, 0
    if not U.Table(source) then return result,count end
    for key, entry in pairs(source) do
        if keyCheck(key) then
            local value = records and (U.Table(entry) and entry.low or nil) or entry
            if Price(value) then
                result[key], count = value, count + 1
                if count >= A.MAX_ROWS then break end
            end
        end
    end
    return result,count
end

local function PackScan(prices, variants)
    local parts = {}
    for key, value in pairs(prices) do parts[#parts + 1] = string.format("%d=%.17g", key, value) end
    parts[#parts + 1] = "|"
    for key, value in pairs(variants) do parts[#parts + 1] = string.format("%s=%.17g", key, value) end
    local plain = table.concat(parts, ",")
    local api = C_EncodingUtil
    if api and #plain >= 1024 then
        local compressed = U.Call(api.CompressString, plain)
        local encoded = U.String(compressed) and U.Call(api.EncodeBase64, compressed)
        if U.String(encoded) and #encoded > 0 and #encoded < #plain then return "z" .. encoded end
    end
    return "p" .. plain
end

local function RestoreIntraday(saved, record, day)
    if not U.Table(saved) or not U.Table(saved.scans) or #saved.scans < 1 or #saved.scans > MAX_SCANS or
       not U.Table(saved.counts) then return nil end
    local scans, previous = {}, nil
    for _, scan in ipairs(saved.scans) do
        if not U.Table(scan) or Day(scan.startedAt) ~= day or (previous and scan.startedAt <= previous) or
           not U.String(scan.encoded) or #scan.encoded < 2 or #scan.encoded > 300 * A.MAX_ROWS or
           not scan.encoded:match("^[pz]") then return nil end
        scans[#scans + 1] = { startedAt = scan.startedAt, encoded = scan.encoded }
        previous = scan.startedAt
    end
    if previous ~= record.startedAt then return nil end
    local counts, earlier = {}, {}
    for _, map in ipairs({ "prices", "variants" }) do
        if not U.Table(saved.counts[map]) then return nil end
        local cleanCounts, cleanEarlier = {}, {}
        local prior = U.Table(saved.earlier) and U.Table(saved.earlier[map]) and saved.earlier[map]
        for key in pairs(record[map]) do
            local count = saved.counts[map][key]
            if U.Number(count, 1, #scans, true) then
                cleanCounts[key] = count
                local value = prior and prior[key]
                if count > 1 and Price(value) then cleanEarlier[key] = value end
            end
        end
        counts[map], earlier[map] = cleanCounts, cleanEarlier
    end
    return { scans = scans, counts = counts, earlier = earlier }
end

local function PendingDay(today)
    local scanner = A.Scanner
    local day = scanner and (scanner.active or scanner.paused) and Day(scanner.requestAt)
    if day and day < today then return day, scanner.marketKey end
end

function H.Prune()
    local today = Day(U.Now())
    if not H.data or not today then return end
    local retention = D.Settings().historyDays
    local oldest = today - retention + 1
    local pendingDay, pendingMarket = PendingDay(today)
    H.deferredDay, H.deferredMarket = nil, nil
    for key, days in pairs(H.data.markets) do
        for day, record in pairs(days) do
            if not U.Number(day, oldest, today, true) or not U.Table(record) or
               Day(record.startedAt) ~= day then
                days[day] = nil
            elseif day < today and record.intraday then
                if day == pendingDay and key == pendingMarket then
                    H.deferredDay, H.deferredMarket = day, key
                else record.intraday = nil end
            end
        end
        if next(days) == nil then H.data.markets[key] = nil end
    end
    H.prunedDay, H.prunedRetention = today, retention
    ResetCache(true)
    A.refreshTooltips = true
    if A.Drops then A.Drops.InvalidateDisplay() end
end

function H.Maintain()
    if not H.data then return end
    local today = Day(U.Now())
    if H.prunedDay ~= today or H.prunedRetention ~= D.Settings().historyDays then H.Prune()
    elseif H.deferredDay and today then
        local day, key = PendingDay(today)
        if day ~= H.deferredDay or key ~= H.deferredMarket then H.Prune() end
    end
end

local function SeedSavedScan(snapshot, today)
    if not U.Table(snapshot) or not MarketKey(snapshot.marketKey) or
       not D.ValidSnapshot(snapshot, snapshot.marketKey) or Day(snapshot.startedAt) ~= today then return end
    local days = H.data.markets[snapshot.marketKey]
    local record = days and days[today]
    if not record or record.intraday or record.startedAt ~= snapshot.startedAt then return end
    local prices = CopyPrices(snapshot.prices, ItemKey, true)
    local variants = CopyPrices(snapshot.variants, VariantKey, true)
    local counts = { prices = {}, variants = {} }
    for key in pairs(prices) do if record.prices[key] == prices[key] then counts.prices[key] = 1 end end
    for key in pairs(variants) do if record.variants[key] == variants[key] then counts.variants[key] = 1 end end
    record.intraday = { scans = {{ startedAt = snapshot.startedAt, encoded = PackScan(prices, variants) }},
        counts = counts, earlier = { prices = {}, variants = {} } }
end

function H.Initialize()
    H.data, H.reason = nil, nil
    ResetCache(true)
    local saved = D.data.history
    local migrate = saved == nil
    if saved ~= nil and (not U.Table(saved) or not U.Accessible(saved.schema) or saved.schema ~= 1 or not U.Table(saved.markets)) then
        H.reason = "Unsupported history data; existing history was preserved."
        return false
    end
    local clean = { schema = 1, markets = {} }
    local today = Day(U.Now())
    if not today then H.reason = "Server date unavailable."; return false end
    local oldest = today - D.Settings().historyDays + 1
    for key, days in pairs(saved and saved.markets or {}) do
        if MarketKey(key) and U.Table(days) then
            local validDays = {}
            for day, record in pairs(days) do
                if U.Number(day, oldest, today, true) and U.Table(record) and Day(record.startedAt) == day and
                   U.Table(record.prices) and U.Table(record.variants) then
                    local valid = { startedAt = record.startedAt,
                        variantFormat=U.Number(record.variantFormat,2,2,true) and 2 or nil,
                        prices = CopyPrices(record.prices, ItemKey), variants = CopyPrices(record.variants, VariantKey) }
                    if day == today then valid.intraday = RestoreIntraday(record.intraday, valid, day) end
                    validDays[day] = valid
                end
            end
            if next(validDays) then clean.markets[key] = validDays end
        end
    end
    D.data.history, H.data = clean, clean
    H.Prune()
    -- Older releases kept only their latest complete scan. Import that scan
    -- once; earlier daily prices cannot be reconstructed.
    for _, snapshot in pairs(D.data.markets) do
        if migrate then H.Record(snapshot) else SeedSavedScan(snapshot, today) end
    end
    return true
end

local function RollUp(observed, previous, counts)
    local means, newCounts, earlier, total = {}, {}, {}, 0
    for key, value in pairs(observed) do
        local count = counts and counts[key] or 0
        local last = count > 0 and previous and previous[key]
        if not last then count = 0 end
        newCounts[key] = count + 1
        means[key] = last and (last + (value - last) / (count + 1)) or value
        if last then earlier[key] = last end
        total = total + 1
    end
    -- An absent price contributes no sample, even when the entire scan is empty.
    for key, value in pairs(previous or {}) do
        if total >= A.MAX_ROWS then break end
        if means[key] == nil then
            means[key], newCounts[key], total = value, counts and counts[key], total + 1
        end
    end
    return means, newCounts, earlier
end

function H.Record(snapshot)
    if not H.data or not U.Table(snapshot) or not MarketKey(snapshot.marketKey) or
       not D.ValidSnapshot(snapshot, snapshot.marketKey) or D.data.markets[snapshot.marketKey] ~= snapshot then return false end
    H.Maintain()
    local day, today = Day(snapshot.startedAt), Day(U.Now())
    if not day or not today or day < today - D.Settings().historyDays + 1 or day > today then return false end
    local days = H.data.markets[snapshot.marketKey] or {}
    local previous = days[day]
    if previous and previous.startedAt >= snapshot.startedAt then return false end
    local format=snapshot.variantFormat==2 and 2 or nil
    local batch = previous and previous.intraday
    local compatibleVariants = previous and previous.variantFormat == format
    local prices = CopyPrices(snapshot.prices, ItemKey, true)
    local variants = CopyPrices(snapshot.variants, VariantKey, true)
    local dailyPrices, priceCounts, earlierPrices = RollUp(prices, previous and previous.prices, batch and batch.counts.prices)
    local dailyVariants, variantCounts, earlierVariants = RollUp(variants, compatibleVariants and previous.variants,
        compatibleVariants and batch and batch.counts.variants)
    local record = { startedAt = snapshot.startedAt, variantFormat = format, prices = dailyPrices, variants = dailyVariants }
    if day == today then
        local scans = batch and batch.scans or {}
        scans[#scans + 1] = { startedAt = snapshot.startedAt, encoded = PackScan(prices, variants) }
        record.intraday = { scans = scans, counts = { prices = priceCounts, variants = variantCounts },
            earlier = { prices = earlierPrices, variants = earlierVariants } }
    end
    days[day] = record
    H.data.markets[snapshot.marketKey] = days
    ResetCache(true)
    A.refreshTooltips = true
    if A.Drops then A.Drops.InvalidateDisplay() end
    return true
end

function H.SetRetention(value)
    if not D.data or not U.Number(value, 1, 30, true) then return false end
    D.data.settings.historyDays = value
    H.Prune()
    return true
end

-- A market's view keeps one daily record per UTC date, even when
-- an older addon wrote the scans under multiple reporting-host keys.
function H.Days(market)
    H.Maintain()
    if not H.data or not market.key then return nil, 0, 0 end
    local own = H.data.markets[market.key]
    local legacy = D.LegacyPrices(market)
    if not legacy or #legacy.keys == 0 then
        return own, 0, legacy and legacy.count or 0, legacy and legacy.reason
    end
    local view = H.dailyViews[market.key]
    if not view then
        local days, previousHosts = {}, {}
        for day, record in pairs(own or {}) do days[day] = record end
        for _, key in ipairs(legacy.keys) do
            for day, record in pairs(H.data.markets[key] or {}) do
                if not days[day] or record.startedAt > days[day].startedAt then
                    days[day], previousHosts[day] = record, true
                end
            end
        end
        local count = 0
        for _ in pairs(previousHosts) do count = count + 1 end
        view = { days = days, legacyDays = count }
        H.dailyViews[market.key] = view
    end
    return view.days, view.legacyDays, legacy.count
end

function H.Status(market)
    local days, legacyDays, legacyHosts, legacyReason = H.Days(market or U.MarketInfo())
    local count, firstDay, lastDay = 0
    for day in pairs(days or {}) do
        count = count + 1
        firstDay, lastDay = math.min(firstDay or day, day), math.max(lastDay or day, day)
    end
    local today = days and days[H.prunedDay]
    return { days = count, firstDay = firstDay, lastDay = lastDay, scansToday = today and today.intraday and #today.intraday.scans or 0,
        retention = D.Settings().historyDays, reason = H.reason,
        legacyDays = legacyDays, legacyHosts = legacyHosts, legacyReason = legacyReason }
end

-- Price signals use completed dates before the current scan's UTC date.
-- This is separate from the market-wide count shown beside the scan age.
function H.PriorRecords(snapshot,lookback,market)
    local records={}
    if not U.Table(snapshot) or not U.Number(snapshot.startedAt,0,U.Now()) or not U.Number(lookback,1,30,true) then return records end
    local day=Day(snapshot.startedAt)
    local info={scanDay=day,priorDays=0,exactDays=0}
    local days=H.Days(market or U.MarketInfo()) or {}
    for date=day-lookback,day-1 do
        local record=days[date]
        if record and record.startedAt<snapshot.startedAt then
            records[#records+1]=record;info.priorDays=info.priorDays+1
            if record.variantFormat==2 then
                info.exactDays=info.exactDays+1;info.firstExact=info.firstExact or date;info.lastExact=date
            end
        end
    end
    return records,info
end

function H.Pricing(market, basis)
    H.Maintain()
    market = market or U.MarketInfo()
    if not H.data or not market.key then return nil end
    basis = basis or D.Settings().priceBasis
    local key = market.key .. "|" .. basis
    local view = H.priceViews[key]
    if not view then
        local days = H.Days(market) or {}
        view = { key = key, basis = basis, days = days, today = H.prunedDay, retention = D.Settings().historyDays }
        H.priceViews[key] = view
    end
    return view
end

function H.IntradayBaseline(market, snapshot)
    local view = H.Pricing(market, "intraday")
    local day = view and view.days[view.today]
    if day and day.intraday and snapshot and day.startedAt == snapshot.startedAt then return day end
end

function H.EarlierScans(record, map, key)
    local earlier = record and record.intraday.earlier[map][key]
    if earlier then return earlier, record.intraday.counts[map][key] - 1 end
    return nil, 0
end

local function Average(view, map, id, mode, variantFormat)
    if view.basis == "intraday" then
        local record = view.days[view.today]
        local scans = record and (not variantFormat or record.variantFormat == variantFormat) and
            record.intraday and record.intraday.counts[map][id]
        if scans then return { value = record[map][id], scans = scans, days = 1, mode = mode, basis = view.basis } end
        return nil
    end
    local count, mean, firstDay, lastDay = 0, 0
    -- Iterate calendar days in order for deterministic rounding. Each
    -- available daily low has equal weight; absent listings are skipped.
    local today = view.today
    for day = today - view.retention + 1, today do
        local record = view.days[day]
        local value = record and (not variantFormat or record.variantFormat == variantFormat) and record[map][id]
        if Price(value) then
            count = count + 1
            mean = mean + (value - mean) / count
            firstDay, lastDay = firstDay or day, day
        end
    end
    if count > 0 then return { value = mean, days = count, mode = mode, basis = view.basis, firstDay = firstDay, lastDay = lastDay } end
end

function H.ExactVariantAverage(key, view)
    return Average(view, "variants", key, "variant", 2)
end

function H.Average(itemID, link, view)
    if not ItemKey(itemID) or not H.data then return nil end
    view = view or H.Pricing(nil, "daily")
    if not view then return nil end
    local variant = U.VariantKey(link)
    if variant and U.ItemID(link) ~= itemID then variant = nil end
    local cacheKey = view.key .. "|" .. (variant or tostring(itemID))
    if H.cache[cacheKey] ~= nil then return H.cache[cacheKey] or nil end
    local result = variant and Average(view, "variants", variant, "variant") or nil
    result = result or Average(view, "prices", itemID, "item-wide")
    if H.cacheEntries >= MAX_CACHE then ResetCache(false) end
    H.cache[cacheKey], H.cacheEntries = result or false, H.cacheEntries + 1
    return result
end

function H.Estimate(itemID, link, view)
    view = view or H.Pricing()
    if view then return H.Average(itemID, link, view) end
end
