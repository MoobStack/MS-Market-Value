local _, A = ...
local U, D = A.Util, A.DB
local H = { cache = {}, cacheEntries = 0 }
A.History = H

local MAX_PRICE, MAX_ID, MAX_CACHE = 9007199254740991, 2147483647, 4096

local function Day(timestamp)
    if U.Number(timestamp, 0, MAX_PRICE) then return math.floor(timestamp / 86400) end
end

local function MarketKey(key) return U.String(key) and #key > 0 and #key <= 256 end

local function ItemKey(key) return U.Number(key, 1, MAX_ID, true) end

local function VariantKey(key)
    if not U.String(key) or #key > 32 then return false end
    local id, suffix = string.match(key, "^(%d+):(%-?%d+)$")
    return U.Number(tonumber(id), 1, MAX_ID, true) and
           U.Number(tonumber(suffix), -MAX_ID, MAX_ID, true) and
           key == tostring(tonumber(id)) .. ":" .. tostring(tonumber(suffix))
end

local function Price(value) return U.Number(value, 0, MAX_PRICE) and value > 0 end

local function ResetCache() H.cache, H.cacheEntries = {}, 0 end

local function CopyPrices(source, keyCheck, records)
    local result, count = {}, 0
    if not U.Table(source) then return result end
    for key, entry in pairs(source) do
        if keyCheck(key) then
            local value = records and (U.Table(entry) and entry.low or nil) or entry
            if Price(value) then
                result[key], count = value, count + 1
                if count >= A.MAX_ROWS then break end
            end
        end
    end
    return result
end

function H.Prune()
    local today = Day(U.Now())
    if not H.data or not today then return end
    local retention = D.Settings().historyDays
    local oldest = today - retention + 1
    for key, days in pairs(H.data.markets) do
        for day, record in pairs(days) do
            if not U.Number(day, oldest, today, true) or not U.Table(record) or
               Day(record.startedAt) ~= day then days[day] = nil end
        end
        if next(days) == nil then H.data.markets[key] = nil end
    end
    H.prunedDay, H.prunedRetention = today, retention
    ResetCache()
    A.refreshTooltips = true
end

function H.Maintain()
    if H.data and (H.prunedDay ~= Day(U.Now()) or H.prunedRetention ~= D.Settings().historyDays) then H.Prune() end
end

function H.Initialize()
    H.data, H.reason = nil, nil
    ResetCache()
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
                    validDays[day] = { startedAt = record.startedAt,
                        prices = CopyPrices(record.prices, ItemKey), variants = CopyPrices(record.variants, VariantKey) }
                end
            end
            if next(validDays) then clean.markets[key] = validDays end
        end
    end
    D.data.history, H.data = clean, clean
    H.Prune()
    -- Older releases kept only their latest complete scan. Import that scan
    -- once; earlier daily prices cannot be reconstructed.
    if migrate then for _, snapshot in pairs(D.data.markets) do H.Record(snapshot) end end
    return true
end

function H.Record(snapshot)
    if not H.data or not U.Table(snapshot) or not MarketKey(snapshot.marketKey) or
       not D.ValidSnapshot(snapshot, snapshot.marketKey) or D.data.markets[snapshot.marketKey] ~= snapshot then return false end
    H.Maintain()
    local day, today = Day(snapshot.startedAt), Day(U.Now())
    if not day or not today or day < today - D.Settings().historyDays + 1 or day > today then return false end
    local days = H.data.markets[snapshot.marketKey] or {}
    local previous = days[day]
    if previous and previous.startedAt > snapshot.startedAt then return false end
    days[day] = { startedAt = snapshot.startedAt,
        prices = CopyPrices(snapshot.prices, ItemKey, true), variants = CopyPrices(snapshot.variants, VariantKey, true) }
    H.data.markets[snapshot.marketKey] = days
    ResetCache()
    A.refreshTooltips = true
    return true
end

function H.SetRetention(value)
    if not D.data or not U.Number(value, 1, 30, true) then return false end
    D.data.settings.historyDays = value
    H.Prune()
    return true
end

function H.Status()
    H.Maintain()
    local key = U.MarketKey()
    local days = key and H.data and H.data.markets[key]
    local count, firstDay, lastDay = 0
    for day in pairs(days or {}) do
        count = count + 1
        firstDay, lastDay = math.min(firstDay or day, day), math.max(lastDay or day, day)
    end
    return { days = count, firstDay = firstDay, lastDay = lastDay, retention = D.Settings().historyDays, reason = H.reason }
end

function H.Average(itemID, link)
    if not ItemKey(itemID) or not H.data then return nil end
    H.Maintain()
    local key = U.MarketKey()
    local days = key and H.data.markets[key]
    if not days then return nil end
    local variant = U.VariantKey(link)
    if variant and U.ItemID(link) ~= itemID then variant = nil end
    local cacheKey = key .. "|" .. (variant or tostring(itemID))
    if H.cache[cacheKey] ~= nil then return H.cache[cacheKey] or nil end
    local function Average(map, id, mode)
        local count, mean, firstDay, lastDay = 0, 0
        -- Iterate calendar days in order for deterministic rounding. Each
        -- available daily low has equal weight; absent listings are skipped.
        local today = H.prunedDay
        for day = today - D.Settings().historyDays + 1, today do
            local record = days[day]
            local value = record and record[map][id]
            if Price(value) then
                count = count + 1
                mean = mean + (value - mean) / count
                firstDay, lastDay = firstDay or day, day
            end
        end
        if count > 0 then return { value = mean, days = count, mode = mode, firstDay = firstDay, lastDay = lastDay } end
    end
    local result = variant and Average("variants", variant, "variant") or nil
    result = result or Average("prices", itemID, "item-wide")
    if H.cacheEntries >= MAX_CACHE then ResetCache() end
    H.cache[cacheKey], H.cacheEntries = result or false, H.cacheEntries + 1
    return result
end
