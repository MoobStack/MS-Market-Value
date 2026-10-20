local _, A = ...
local U = A.Util
local D = {}
A.DB = D

D.defaults = {
    showVendor = true, showAuction = true, showDisenchant = true,
    showMaterials = true, showAge = true, showHistory = true,
    craftAutoOpen = false, showAllRecipes = false,
    staleHours = 24, quoteMarkup = 0, historyDays = 30,
    marketLookback = 14, marketMinDays = 3, marketMinReturn = 20,
    marketMinProfit = 100, marketFee = 5, marketMove = 15,
    serviceLabor = 0, serviceMinimum = 0, serviceCustomerMaterials = false,
    watchAlerts = true, ledgerDays = 90, trackAH = true, trackVendor = true, trackTrade = true,
}

local settingBounds = { staleHours = { 1, 168 }, quoteMarkup = { 0, 1000 }, historyDays = { 1, 30 },
    marketLookback = { 1, 30 }, marketMinDays = { 2, 29 }, marketMinReturn = { 0, 1000 },
    marketMinProfit = { 0, 100000000 }, marketFee = { 0, 30 }, marketMove = { 0, 1000 },
    serviceLabor = { 0, 100000000 }, serviceMinimum = { 0, 100000000 }, ledgerDays = { 1, 365 } }

function D.Initialize()
    local db = _G.MSMarketValueDB
    if db == nil then db = { schema = A.SCHEMA, markets = {}, settings = {} } end
    if type(db) ~= "table" or (db.schema ~= nil and db.schema ~= A.SCHEMA) then
        A.disabledReason = "Unsupported saved-data schema. Back up MSMarketValueDB.lua before changing it."
        return false
    end
    if db.markets ~= nil and type(db.markets) ~= "table" then
        A.disabledReason = "Invalid saved market data; existing data was preserved."
        return false
    end
    db.schema = A.SCHEMA
    db.markets = db.markets or {}
    if type(db.settings) ~= "table" then db.settings = {} end
    for key, value in pairs(D.defaults) do
        if type(value) == "boolean" then
            if type(db.settings[key]) ~= "boolean" then db.settings[key] = value end
        elseif not U.Number(db.settings[key], settingBounds[key][1], settingBounds[key][2], true) then
            db.settings[key] = value
        end
    end
    if type(db.excludedItems) ~= "table" then db.excludedItems = {} end
    if not U.Number(db.cooldownUntil, 0) then db.cooldownUntil = 0 end
    db.version = A.VERSION
    db.build = A.BUILD
    _G.MSMarketValueDB = db
    D.data = db
    A.History.Initialize()
    A.Vendor.Initialize()
    A.Watchlist.Initialize()
    A.Ledger.Initialize()
    return true
end

function D.Settings()
    return D.data and D.data.settings or D.defaults
end

function D.ValidSnapshot(snapshot, key)
    if not U.Table(snapshot) or not U.Accessible(snapshot.complete) or snapshot.complete ~= true or
       not U.String(snapshot.marketKey) or snapshot.marketKey ~= key or not U.Table(snapshot.prices) or
       not U.Table(snapshot.variants) or
       not U.Table(snapshot.bidOnlyItems) or
       not U.Number(snapshot.totalRows, 0, A.MAX_ROWS, true) or
       not U.Number(snapshot.distinctItems, 0, A.MAX_ROWS, true) or
       not U.Number(snapshot.bidOnlyRows, 0, A.MAX_ROWS, true) or
       not U.Number(snapshot.soldRows, 0, A.MAX_ROWS, true) or
       not U.Number(snapshot.startedAt, 0) then return false end
    return true
end

function D.Snapshot()
    if not D.data then return nil end
    local key = U.MarketKey()
    if not key then return nil end
    local snapshot = D.data.markets[key]
    if D.ValidSnapshot(snapshot, key) then return snapshot end
end

local function AddPrice(map, key, unitPrice, quantity)
    local p = map[key]
    if not p then
        map[key] = { low = unitPrice, units = quantity, auctions = 1 }
        return true
    end
    p.low = math.min(p.low, unitPrice)
    p.units = p.units + quantity
    p.auctions = p.auctions + 1
    return false
end

function D.NewSnapshot(marketKey, count, startedAt)
    return {
        marketKey = marketKey, totalRows = count, processedRows = 0,
        buyoutRows = 0, bidOnlyRows = 0, soldRows = 0, distinctItems = 0,
        prices = {}, variants = {}, bidOnlyItems = {},
        startedAt = startedAt, method = "C_AuctionHouse.ReplicateItems",
        version = A.VERSION, build = A.BUILD, complete = false,
    }
end

-- Values were validated by the scan adapter before reaching this accumulator.
function D.AddRow(snapshot, itemID, quantity, buyout, link, saleStatus)
    snapshot.processedRows = snapshot.processedRows + 1
    if saleStatus ~= 0 then
        snapshot.soldRows = snapshot.soldRows + 1
        return
    end
    if buyout == 0 then
        snapshot.bidOnlyRows = snapshot.bidOnlyRows + 1
        snapshot.bidOnlyItems[itemID] = true
        return
    end
    local unitPrice = buyout / quantity
    if AddPrice(snapshot.prices, itemID, unitPrice, quantity) then
        snapshot.distinctItems = snapshot.distinctItems + 1
    end
    local variant = U.VariantKey(link)
    if variant and U.ItemID(link) == itemID then
        AddPrice(snapshot.variants, variant, unitPrice, quantity)
    end
    snapshot.buyoutRows = snapshot.buyoutRows + 1
end

function D.Commit(snapshot)
    if not D.data or type(snapshot) ~= "table" or
       snapshot.complete ~= false or not U.Number(snapshot.totalRows, 0, A.MAX_ROWS, true) or
       snapshot.processedRows ~= snapshot.totalRows or
       snapshot.processedRows ~= snapshot.buyoutRows + snapshot.bidOnlyRows + snapshot.soldRows then
        return false, "Snapshot validation failed."
    end
    local key = U.MarketKey()
    if key ~= snapshot.marketKey then return false, "Market changed while scanning." end
    snapshot.finishedAt = U.Now()
    snapshot.complete = true
    -- The sole authoritative current-price write. History receives only a
    -- completed snapshot and never fills gaps in current prices.
    D.data.markets[key] = snapshot
    A.History.Record(snapshot)
    return true
end

function D.Price(itemID, link, snapshot)
    snapshot = snapshot or D.Snapshot()
    if not snapshot then return nil, "no-scan" end
    local variant = U.VariantKey(link)
    local record = variant and snapshot.variants[variant]
    if type(record) == "table" and U.Number(record.low, 0) then return record, "variant" end
    record = snapshot.prices[itemID]
    if type(record) == "table" and U.Number(record.low, 0) then return record, "item-wide" end
    if snapshot.bidOnlyItems and snapshot.bidOnlyItems[itemID] then return nil, "bid-only" end
    return nil, "not-listed"
end

function D.IsStale(snapshot)
    return snapshot and (U.Now() - snapshot.startedAt) > D.Settings().staleHours * 3600
end

function D.Exclude(itemID, excluded)
    if not D.data or not U.Number(itemID, 1, 2147483647, true) then return false end
    D.data.excludedItems[itemID] = excluded and true or nil
    U.Notify()
    return true
end
