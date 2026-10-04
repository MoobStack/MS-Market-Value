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

local regions = { us = 1, kr = 2, eu = 3, tw = 4, cn = 5 }

local function PublicCall(fn, ...)
    if type(fn) ~= "function" then return nil, "unavailable" end
    local ok, value = pcall(fn, ...)
    if not ok then return nil, "error" end
    if not U.Accessible(value) then return nil, "restricted" end
    return value
end

local function RealmName(value)
    if not U.String(value) then return nil end
    -- The normalized API can exist but return nil/empty on this client. Match
    -- WoW's whitespace/hyphen-free realm form when using the public name.
    local realm = string.gsub(value, "[%s%-]", "")
    if realm ~= "" then return realm end
end

local function PortalName(value)
    if not U.String(value) then return nil end
    local portal = string.lower(string.match(value, "^%s*(.-)%s*$"))
    if #portal > 0 and #portal <= 80 and string.match(portal, "^[%w_.%-]+$") and
       string.find(portal, "%a") then
        return portal
    end
end

local function Describe(value, errorReason)
    if errorReason then return errorReason end
    if U.String(value) then return value == "" and "empty" or string.sub(value, 1, 80) end
    if U.Number(value) then return tostring(value) end
    return "unavailable"
end

function U.MarketInfo()
    local normalized, normalizedError = PublicCall(GetNormalizedRealmName)
    local rawRealm, realmError = PublicCall(GetRealmName)
    local rawRegion, regionError = PublicCall(GetCurrentRegion)
    local portalValue, portalError = PublicCall(C_CVar and C_CVar.GetCVar, "portal")
    local portal = PortalName(portalValue)
    local portalSource = "C_CVar.GetCVar(portal)"
    if not portal then
        portalValue, portalError = PublicCall(GetCVar, "portal")
        portal, portalSource = PortalName(portalValue), "GetCVar(portal)"
    end
    local info = {
        normalizedRealm = Describe(normalized, normalizedError),
        realmName = Describe(rawRealm, realmError),
        nativeRegion = Describe(rawRegion, regionError),
        portal = Describe(portalValue, portalError),
    }
    info.realm = RealmName(normalized) and normalized or nil
    info.realmSource = "GetNormalizedRealmName"
    if not info.realm then
        info.realm, info.realmSource = RealmName(rawRealm), "GetRealmName"
    end
    if U.Number(rawRegion, 1, 10, true) then
        info.region, info.regionSource = tostring(rawRegion), "GetCurrentRegion"
    elseif regions[PortalName(rawRegion)] then
        info.region, info.regionSource = tostring(regions[PortalName(rawRegion)]), "GetCurrentRegion"
    elseif portal then
        -- A named test/beta portal remains a separate market. Never guess a
        -- region from locale or silently share prices with another portal.
        info.region = regions[portal] and tostring(regions[portal]) or ("portal:" .. portal)
        info.regionSource = portalSource
    end
    if not info.realm then
        info.reason = "Realm name is unavailable. Try again after entering the world; diagnostics show the lookup values."
    elseif not info.region then
        info.reason = "Region and login portal are unavailable. Copy diagnostics to report the lookup values."
    else
        -- Numeric portal fallbacks keep build001 keys such as 1|Realm intact.
        -- Markets are shared across factions, with no cross-region fallback.
        info.key = info.region .. "|" .. info.realm
    end
    return info
end

function U.MarketKey()
    local info = U.MarketInfo()
    return info.key, info.reason
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
