local _, A = ...
local U, D = A.Util, A.DB
local V = { revision = 0 }
A.Vendor = V

-- Identification only. Purchase prices always come from the player's merchant,
-- never from a sell-price multiplier or a price table for another game version.
local supplies = { 2320, 2321, 4291, 8343, 14341, 2324, 2325, 2604, 2605,
    4340, 4341, 4342, 6260, 6261, 10290, 4289, 2880, 3466, 3857,
    3371, 3372, 8925, 18256, 2678, 2692, 3713, 4470, 11291 }
V.supplies = {}
for _, id in ipairs(supplies) do V.supplies[id] = true end
local MAX_PRICE, MAX_ID = 1000000000000, 2147483647

local function Call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    if ok and U.Accessible(value) then return value end
end

local function CharacterKey()
    local guid, market, faction = Call(UnitGUID, "player"), U.MarketKey(), Call(UnitFactionGroup, "player")
    if U.String(guid) and #guid <= 128 and market and U.String(faction) then return market .. "|" .. faction .. "|" .. guid end
end

local function Reputation()
    local api = U.Table(C_Reputation) and C_Reputation
    local count = api and Call(api.GetNumFactions)
    if not U.Number(count, 1, 512, true) then return nil end
    local parts = {}
    for index = 1, count do
        local row = Call(api.GetFactionDataByIndex, index)
        if U.Table(row) and U.Number(row.factionID, 1, MAX_ID, true) and U.Number(row.reaction, 1, 8, true) then
            parts[#parts + 1] = row.factionID .. ":" .. row.reaction
        end
    end
    table.sort(parts)
    return table.concat(parts, ",")
end

function V.Initialize()
    local saved = D.data.vendorBuy
    if saved == nil then saved = { schema = 1, characters = {} }; D.data.vendorBuy = saved end
    if not U.Table(saved) or not U.Accessible(saved.schema) or saved.schema ~= 1 or not U.Table(saved.characters) then
        V.reason = "Unsupported vendor data preserved; visit a supplier after resolving it."
        return
    end
    V.data, V.reputation = saved, Reputation()
end

local function Profile(create)
    local key = CharacterKey()
    if not key or not V.data then return nil end
    local profile = V.data.characters[key]
    if not U.Table(profile) or not U.Table(profile.prices) then
        if not create then return nil end
        profile = { prices = {}, known = {}, reputation = V.reputation }
        V.data.characters[key] = profile
    end
    if not U.Table(profile.known) then
        profile.known = {}
        for id in pairs(profile.prices) do
            if U.Number(id, 1, MAX_ID, true) then profile.known[id] = true end
        end
    end
    if not U.Accessible(profile.reputation) or (V.reputation ~= nil and profile.reputation ~= V.reputation) then
        profile.prices, profile.reputation = {}, V.reputation
        V.revision = V.revision + 1
    end
    return profile
end

function V.IsKnown(id)
    local profile = Profile(false)
    return V.supplies[id] == true or (profile and (profile.known[id] == true or U.Table(profile.prices[id]))) or false
end

function V.KnownItems()
    local result, profile = {}, Profile(false)
    for id in pairs(V.supplies) do result[id] = true end
    for id, known in pairs(profile and profile.known or {}) do if known == true then result[id] = true end end
    return result
end

function V.Price(id)
    local profile = Profile(false)
    local price = profile and profile.prices[id]
    if U.Table(price) and U.Number(price.unit, 0, MAX_PRICE) and price.unit > 0 and
       U.Number(price.seenAt, 0, U.Now()) and U.Now() - price.seenAt <= 7 * 86400 then
        return price.unit, "vendor"
    end
    if V.IsKnown(id) then return nil, "vendor-unseen" end
end

local function MerchantItem(index)
    if U.Table(C_MerchantFrame) and type(C_MerchantFrame.GetItemInfo) == "function" then
        return Call(C_MerchantFrame.GetItemInfo, index)
    end
    if type(GetMerchantItemInfo) ~= "function" then return nil end
    local values = { pcall(GetMerchantItemInfo, index) }
    if not values[1] then return nil end
    return { price = values[4], stackCount = values[5], numAvailable = values[6],
        isPurchasable = values[7], hasExtendedCost = values[9] }
end

function V.Capture()
    if not V.open or U.Combat() or not D.data then return false end
    local count = Call(GetMerchantNumItems)
    if not U.Number(count, 0, 500, true) then return false end
    V.reputation = Reputation() or V.reputation
    local profile = Profile(true)
    if not profile then V.reason = "Player identity unavailable; vendor prices were not saved."; return false end
    local changed = false
    for index = 1, count do
        local info = MerchantItem(index)
        local id = Call(GetMerchantItemID, index)
        if not U.Number(id, 1, MAX_ID, true) then id = U.ItemID(Call(GetMerchantItemLink, index)) end
        if U.Number(id, 1, MAX_ID, true) and U.Table(info) and
           U.Number(info.price, 1, MAX_PRICE, true) and U.Number(info.stackCount, 1, 1000000, true) and
           U.Number(info.numAvailable, -1, -1, true) and U.Accessible(info.isPurchasable) and info.isPurchasable == true and
           U.Accessible(info.hasExtendedCost) and info.hasExtendedCost == false then
            local unit, previous = info.price / info.stackCount, profile.prices[id]
            if not U.Table(previous) or previous.unit ~= unit then changed = true end
            profile.prices[id] = { unit = unit, seenAt = U.Now() }
            profile.known[id] = true
        end
    end
    V.pending, V.reason = false, nil
    if changed then
        V.revision = V.revision + 1
        if A.Crafting then A.Crafting.Invalidate() end
    end
    return changed
end

function V.OnReputation()
    local value = Reputation()
    if value ~= nil and value ~= V.reputation then
        V.reputation = value
        Profile(false)
        if A.Crafting then A.Crafting.Invalidate() end
    end
    if V.open then V.pending = true end
end

function V.Status()
    local profile, count = Profile(false), 0
    for id in pairs(profile and profile.prices or {}) do if V.Price(id) then count = count + 1 end end
    return count, V.reason
end
