local _, A = ...
local U = {}
A.Util = U

-- Test access before inspecting, formatting, comparing, or using a value as a key.
-- A restricted value is never converted into a supposedly readable value.
function U.Accessible(value)
    if issecretvalue and issecretvalue(value) then return false end
    if canaccessvalue and not canaccessvalue(value) then return false end
    return true
end

function U.Number(value, minValue, maxValue, integer)
    if not U.Accessible(value) or type(value) ~= "number" then return false end
    if value ~= value or value == math.huge or value == -math.huge then return false end
    if minValue and value < minValue then return false end
    if maxValue and value > maxValue then return false end
    if integer and value ~= math.floor(value) then return false end
    return true
end

function U.String(value)
    return U.Accessible(value) and type(value) == "string"
end

function U.Table(value)
    return U.Accessible(value) and type(value) == "table"
end

function U.Now()
    if GetServerTime then return GetServerTime() end
    return time()
end

function U.Mono()
    return GetTime()
end

function U.Money(copper)
    if not U.Number(copper, 0) then return "Unavailable" end
    if copper > 0 and copper < 1 then return "<1c" end
    if copper ~= math.floor(copper) then copper = math.floor(copper + 0.5) end
    local gold = math.floor(copper / 10000)
    local silver = math.floor(copper / 100) % 100
    local bronze = copper % 100
    if gold > 0 then return string.format("%.0fg %02ds %02dc", gold, silver, bronze) end
    if silver > 0 then return string.format("%ds %02dc", silver, bronze) end
    return string.format("%dc", bronze)
end

function U.Age(timestamp)
    if not U.Number(timestamp, 0) then return "unknown age" end
    local seconds = math.max(0, U.Now() - timestamp)
    if seconds < 60 then return "just now" end
    if seconds < 3600 then return string.format("%dm ago", math.floor(seconds / 60)) end
    if seconds < 86400 then return string.format("%dh ago", math.floor(seconds / 3600)) end
    return string.format("%dd ago", math.floor(seconds / 86400))
end

function U.ItemID(link)
    if not U.String(link) then return nil end
    local itemID = tonumber(string.match(link, "item:(%d+)"))
    if U.Number(itemID, 1, 2147483647, true) then return itemID end
end

-- Vanilla-content item variants differ by signed random suffix. Do not key on
-- enchantment, gems, unique instance ID, or the viewer's level.
function U.VariantKey(link)
    if not U.String(link) then return nil end
    local payload = string.match(link, "item:([^|]+)")
    if not payload then return nil end
    local fields = {}
    for field in string.gmatch(payload .. ":", "(.-):") do
        fields[#fields + 1] = field
        if #fields >= 7 then break end
    end
    local itemID = tonumber(fields[1])
    local suffix = tonumber(fields[7]) or 0
    if not U.Number(itemID, 1, 2147483647, true) or
       not U.Number(suffix, -2147483647, 2147483647, true) then return nil end
    return tostring(itemID) .. ":" .. tostring(suffix)
end

function U.MarketKey()
    local realm = GetNormalizedRealmName and GetNormalizedRealmName() or GetRealmName()
    local region = GetCurrentRegion and GetCurrentRegion() or nil
    if not U.String(realm) or realm == "" or not U.Number(region, 1, 10, true) then
        return nil, "Realm/region information is not available yet."
    end
    -- Modern AH markets are shared across factions. Separate realm/region caches
    -- prevent a price from a different market being presented as a local price.
    return tostring(region) .. "|" .. realm
end

function U.Log(message)
    if not U.String(message) then return end
    local log = A.log
    log[#log + 1] = message
    if #log > 60 then table.remove(log, 1) end
end

function U.Print(message)
    if DEFAULT_CHAT_FRAME and U.String(message) then
        DEFAULT_CHAT_FRAME:AddMessage("|cff8ed4d8MS Market Value:|r " .. message)
    end
    U.Log(message)
end

function U.Combat()
    return InCombatLockdown and InCombatLockdown() or false
end

function U.Notify()
    if A.UI and A.UI.Refresh then A.UI.Refresh() end
end
