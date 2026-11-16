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
    marketLowMin = 0, marketLowMax = 0, marketStockMin = 0, marketStockMax = 0,
    marketStockDrop = 0, marketSearch = "", marketQuality = 63,
    dropTracking = true, showDrops = true, showHarvestDrops = true, dropRows = 4, dropMode = "reference",
    dropSort = "rate_desc", dropQuality = 63,
    farmTracking = true, farmShow = true, farmShowTotal = true, farmHover = false, farmUseAuction = true,
    farmIncludeQuest = true, farmThreshold = 10, farmIdle = true, farmIdleMinutes = 5,
    farmHUDWidth = 320, farmHUDLocked = false,
    serviceLabor = 0, serviceMinimum = 0, serviceCustomerMaterials = false,
    watchAlerts = true, ledgerDays = 90, trackAH = true, trackVendor = true, trackTrade = true, trackLoot = true, trackOther = true,
}

local settingBounds = { staleHours = { 1, 168 }, quoteMarkup = { 0, 1000 }, historyDays = { 1, 30 },
    marketLookback = { 1, 30 }, marketMinDays = { 2, 29 }, marketMinReturn = { 0, 1000 },
    marketMinProfit = { 0, 100000000 }, marketFee = { 0, 30 }, marketMove = { 0, 1000 },
    serviceLabor = { 0, 100000000 }, serviceMinimum = { 0, 100000000 }, ledgerDays = { 1, 365 },
    marketLowMin={0,1000000000},marketLowMax={0,1000000000},
    marketStockMin={0,1000000000},marketStockMax={0,1000000000},marketStockDrop={0,100},
    dropRows={1,10},dropQuality={0,63},farmThreshold={0,1000},farmIdleMinutes={5,60},farmHUDWidth={240,520},marketQuality={0,63} }

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
    -- Adopt reference mode once now that a base dataset ships with the addon.
    -- Later display choices and disabled collection stay as the player set them.
    if db.settings.dropModeConfigured~=true then
        db.settings.dropMode="reference";db.settings.dropModeConfigured=true
    end
    -- Earlier betas stored an off default without an explicit-choice marker.
    -- Adopt the requested on default once; later choices survive upgrades.
    if db.settings.farmIdleConfigured~=true then db.settings.farmIdle=true end
    if U.Number(db.settings.farmIdleMinutes,61,1440,true) then db.settings.farmIdleMinutes=60 end
    -- Preserve the six supported choices from earlier nine-quality masks.
    if U.Number(db.settings.marketQuality,0,511,true) then db.settings.marketQuality=db.settings.marketQuality%64 end
    for key, value in pairs(D.defaults) do
        if type(value) == "boolean" then
            if type(db.settings[key]) ~= "boolean" then db.settings[key] = value end
        elseif type(value) == "string" then
            if not U.String(db.settings[key]) or #db.settings[key] > 80 then db.settings[key] = value end
        elseif not U.Number(db.settings[key], settingBounds[key][1], settingBounds[key][2], true) then
            db.settings[key] = value
        end
    end
    if db.settings.dropMode ~= "observed" and db.settings.dropMode ~= "reference" then db.settings.dropMode = "reference" end
    if db.settings.dropSort~="rate_desc" and db.settings.dropSort~="rate_asc" and db.settings.dropSort~="value" then db.settings.dropSort="rate_desc" end
    if type(db.excludedItems) ~= "table" then db.excludedItems = {} end
    if not U.Number(db.cooldownUntil, 0) then db.cooldownUntil = 0 end
    db.version = A.VERSION
    db.build = A.BUILD
    _G.MSMarketValueDB = db
    D.data = db
    D.legacyPriceViews, D.profileKeys = {}, {}
    A.History.Initialize()
    A.Vendor.Initialize()
    A.Watchlist.Initialize()
    A.Ledger.Initialize()
    if A.Drops then A.Drops.Initialize() end
    if A.Farm then A.Farm.Initialize() end
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

-- Old live host price keys lacked a faction. Recover only ordinary PvP:
-- Blizzard allows one faction per account there. Bind those sources once to
-- that faction; conflicting saved vendor observations block the inference.
function D.LegacyPrices(market)
    if not D.data or not market.key or not market.liveAlias then return nil end
    local view = D.legacyPriceViews[market.key]
    if view then return view end
    view = { count = 0, keys = {} }
    D.legacyPriceViews[market.key] = view
    local keys, found, newest = {}, {}, nil
    for key, snapshot in pairs(D.data.markets) do
        if U.LegacyLiveHost(key, market) and D.ValidSnapshot(snapshot, key) and
           U.Number(snapshot.startedAt, 0, U.Now()) then
            keys[#keys + 1], found[key] = key, true
            if not newest or snapshot.startedAt > newest.startedAt or
               (snapshot.startedAt == newest.startedAt and key < newest.marketKey) then newest = snapshot end
        end
    end
    local history = A.History.data
    for key in pairs(history and history.markets or {}) do
        if U.LegacyLiveHost(key, market) and not found[key] then keys[#keys + 1] = key end
    end
    view.count = #keys
    if #keys == 0 then return view end
    if market.ruleset ~= "pvp" or (market.faction ~= "Horde" and market.faction ~= "Alliance") then
        view.reason = "Earlier host scans are preserved; their faction is unknown."
        return view
    end
    local owners = D.data.livePvPLegacyFaction
    if not U.Accessible(owners) or (owners ~= nil and not U.Table(owners)) then
        view.reason = "Earlier host scans are preserved; their faction record is unreadable."
        return view
    end
    local owner = owners and owners[market.region]
    if not U.Accessible(owner) or (owner ~= nil and owner ~= market.faction) then
        view.reason = "Earlier PvP host scans are bound to a different faction."
        return view
    end
    local vendor = D.data.vendorBuy
    local characters = U.Table(vendor) and U.Table(vendor.characters) and vendor.characters
    for key in pairs(characters or {}) do
        if U.String(key) then
            local host, faction = string.match(key, "^([^|]+|[^|]+)|([^|]+)|[^|]+$")
            if (faction == "Horde" or faction == "Alliance") and faction ~= market.faction and U.LegacyLiveHost(host, market) then
                view.reason = "Earlier PvP host scans are preserved; saved profiles include both factions."
                return view
            end
        end
    end
    owners = owners or {}; D.data.livePvPLegacyFaction = owners
    owners[market.region] = market.faction
    table.sort(keys); view.keys = keys
    if newest then
        local snapshot = {}
        for key, value in pairs(newest) do snapshot[key] = value end
        snapshot.legacyMarketKey, snapshot.marketKey = newest.marketKey, market.key
        view.snapshot = snapshot -- Session view only; keep the original snapshot intact.
    end
    return view
end

-- Keep one pre-existing profile readable after the market key changes. Never
-- combine ledgers (their receipt IDs can overlap) or duplicate saved tables.
function D.ProfileKey(root, field, market, suffix)
    if not market.key then return nil end
    local key = market.key .. suffix
    local profiles = U.Table(root) and root[field]
    if not market.liveAlias or not U.Table(profiles) or not U.Accessible(profiles[key]) or profiles[key] ~= nil then return key end
    if field == "markets" and market.ruleset == "pvp" then
        local legacy = D.LegacyPrices(market)
        if legacy and legacy.reason then return key end
    end
    local cache = D.profileKeys[root]
    if not cache then cache = {}; D.profileKeys[root] = cache end
    if cache[key] then return cache[key] end
    local links = root.liveHostProfiles
    if not U.Accessible(links) or (links ~= nil and not U.Table(links)) then return key end
    local used = {}
    for scope, prior in pairs(links or {}) do
        if U.String(scope) and scope ~= key and U.String(prior) then used[prior] = true end
    end
    local function Eligible(prior)
        return U.String(prior) and #prior > #suffix and not used[prior] and U.Table(profiles[prior]) and
            string.sub(prior, #prior - #suffix + 1) == suffix and
            U.LegacyLiveHost(string.sub(prior, 1, #prior - #suffix), market)
    end
    local prior = links and links[key]
    if not U.Accessible(prior) then return key end
    if not Eligible(prior) then
        prior = market.legacyKey .. suffix
        if not Eligible(prior) then
            local bestSize = -1
            prior = nil
            for candidate, profile in pairs(profiles) do
                if Eligible(candidate) then
                    local entries = U.Table(profile.entries) and profile.entries or
                        (U.Table(profile.prices) and profile.prices or {})
                    local size = 0
                    for _ in pairs(entries) do size = size + 1 end
                    if size > bestSize or (size == bestSize and candidate < prior) then prior, bestSize = candidate, size end
                end
            end
        end
        if prior then links = links or {}; root.liveHostProfiles = links; links[key] = prior end
    end
    cache[key] = prior or key
    return cache[key]
end

function D.Snapshot(market)
    if not D.data then return nil end
    market = market or U.MarketInfo()
    local key = market.key
    if not key then return nil end
    local snapshot = D.data.markets[key]
    if not D.ValidSnapshot(snapshot, key) then snapshot = nil end
    local legacy = D.LegacyPrices(market)
    local prior = legacy and legacy.snapshot
    if prior and (not snapshot or prior.startedAt > snapshot.startedAt) then return prior end
    return snapshot
end

local function AddPrice(map, key, unitPrice, quantity, link, display)
    local p = map[key]
    if not p then
        map[key] = { low = unitPrice, units = quantity, auctions = 1,
            lowUnits=quantity, lowAuctions=1, lowBuyout=unitPrice*quantity, link=link,display=display }
        return true
    end
    if unitPrice < p.low then
        p.low, p.lowUnits, p.lowAuctions, p.lowBuyout, p.link = unitPrice, quantity, 1, unitPrice*quantity, link
        p.display=display
    elseif unitPrice == p.low then
        p.lowUnits, p.lowAuctions = p.lowUnits + quantity, p.lowAuctions + 1
        p.lowBuyout = p.lowBuyout + unitPrice*quantity
        if not p.link then p.link=link end
        if display then
            if not p.display then p.display=display
            elseif (p.display[1]==nil and display[1]~=nil) or (not p.display[2] and display[2]) then
                p.display={p.display[1] or display[1],p.display[2] or display[2]}
            end
        end
    end
    p.units = p.units + quantity
    p.auctions = p.auctions + 1
    return false
end

function D.NewSnapshot(marketKey, count, startedAt)
    return {
        marketKey = marketKey, totalRows = count, processedRows = 0,
        buyoutRows = 0, bidOnlyRows = 0, soldRows = 0, distinctItems = 0,
        prices = {}, variants = {}, bidOnlyItems = {},
        startedAt = startedAt, method = "C_AuctionHouse.ReplicateItems", variantFormat=2,
        version = A.VERSION, build = A.BUILD, complete = false,
    }
end

-- Values were validated by the scan adapter before reaching this accumulator.
function D.AddRow(snapshot, itemID, quantity, buyout, link, saleStatus, quality, name)
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
    if not U.String(link) or #link > 2048 or U.ItemID(link) ~= itemID then link=nil end
    quality=U.Number(quality,0,8,true) and quality or nil
    name=U.String(name) and #name>0 and #name<=256 and name or nil
    local variant=U.VariantKey(link)
    local base,exact=snapshot.prices[itemID],variant and snapshot.variants[variant]
    -- An eighth field fits the existing price table. Share the small metadata
    -- pair between base/variant lows, and allocate it only for a candidate low.
    local display
    if (quality~=nil or name) and (not base or unitPrice<=base.low or variant and (not exact or unitPrice<=exact.low)) then
        display={quality,name}
    end
    if AddPrice(snapshot.prices, itemID, unitPrice, quantity, link,display) then
        snapshot.distinctItems = snapshot.distinctItems + 1
    end
    if variant and U.ItemID(link) == itemID then
        AddPrice(snapshot.variants, variant, unitPrice, quantity, link,display)
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
    local previous = D.Snapshot()
    if previous then
        local supply = { startedAt=previous.startedAt, prices={}, variants={} }
        for _, map in ipairs({"prices","variants"}) do
            for id, price in pairs(previous[map]) do
                if U.Table(price) and U.Number(price.units, 1, 1000000000, true) then supply[map][id]=price.units end
            end
        end
        snapshot.previousSupply = supply
    end
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
