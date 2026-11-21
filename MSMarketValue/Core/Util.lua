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

U.coin={gold="|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:1:0|t",
    silver="|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:1:0|t",
    copper="|TInterface\\MoneyFrame\\UI-CopperIcon:12:12:1:0|t"}

-- Rich text belongs in labels and tooltips. Quotes, clipboard text, CSV and
-- diagnostics keep U.Money's plain denominations.
function U.Coins(copper)
    if not U.Number(copper,0) then return "Unavailable" end
    if copper>0 and copper<1 then return "<1" .. U.coin.copper end
    if copper~=math.floor(copper) then copper=math.floor(copper+.5) end
    local gold,silver,bronze=math.floor(copper/10000),math.floor(copper/100)%100,copper%100
    local parts={}
    if gold>0 then parts[#parts+1]=string.format("%.0f",gold) .. U.coin.gold end
    if silver>0 then parts[#parts+1]=silver .. U.coin.silver end
    if bronze>0 or #parts==0 then parts[#parts+1]=bronze .. U.coin.copper end
    return table.concat(parts," ")
end

U.qualityNames={"Poor","Common","Uncommon","Rare","Epic","Legendary","Artifact","Heirloom","WoW Token"}
local qualityHex={"9d9d9d","ffffff","1eff00","0070dd","a335ee","ff8000","e6cc80","00ccff","00ccff"}
function U.ItemQuality(item,known)
    if U.Number(known,0,8,true) then return known end
    if U.String(item) or U.Number(item,1,2147483647,true) then
        local quality=U.Call(C_Item and C_Item.GetItemQualityByID,item)
        if U.Number(quality,0,8,true) then return quality end
    end
    local hex=U.String(item) and item:match("|c%x%x(%x%x%x%x%x%x)|Hitem:")
    if hex then for index=1,6 do if hex:lower()==qualityHex[index] then return index-1 end end end
end

function U.ItemColor(link,quality)
    if U.Number(quality,0,8,true) and C_Item and type(C_Item.GetItemQualityColor)=="function" then
        local r={pcall(C_Item.GetItemQualityColor,quality)}
        if r[1] and U.Number(r[2],0,1) and U.Number(r[3],0,1) and U.Number(r[4],0,1) then return r[2],r[3],r[4] end
    end
    local hex=U.Number(quality,0,8,true) and qualityHex[quality+1] or
        (U.String(link) and link:match("|c%x%x(%x%x%x%x%x%x)|Hitem:"))
    if hex then return tonumber(hex:sub(1,2),16)/255,tonumber(hex:sub(3,4),16)/255,tonumber(hex:sub(5,6),16)/255 end
    return .90,.89,.84
end

function U.ItemName(link,current,scanned)
    local name=U.String(scanned) and #scanned>0 and scanned or U.LinkName(link)
    if U.String(current) and #current>0 then
        if not name or #current>#name then name=current end
    end
    return name
end

function U.ParseGold(text, maximum)
    if not U.String(text) then return nil end
    text = string.match(text, "^%s*(.-)%s*$")
    if #text == 0 or #text > 24 or not string.match(text, "^%d*%.?%d*$") then return nil end
    local whole, fraction = string.match(text, "^(%d*)%.(%d*)$")
    if not whole then whole, fraction = text, "" end
    if whole == "" and fraction == "" or #fraction > 4 then return nil end
    local copper = (tonumber(whole) or 0) * 10000 + (tonumber(fraction .. string.rep("0", 4 - #fraction)) or 0)
    if U.Number(copper, 0, maximum or 100000000, true) then return copper end
end

function U.GoldText(copper)
    if not U.Number(copper, 0, 1000000000000, true) then return "" end
    local fraction = string.gsub(string.format("%04d", copper % 10000), "0+$", "")
    return string.format("%.0f", math.floor(copper / 10000)) .. (#fraction > 0 and ("." .. fraction) or "")
end

function U.PlayerGUID()
    local guid = U.Call(UnitGUID, "player")
    if U.String(guid) and #guid > 0 and #guid <= 128 and not guid:find("|", 1, true) then return guid end
end

function U.PlayerKey()
    local guid = U.PlayerGUID()
    if not guid then return nil end
    return A.DB.ProfileKey(A.Ledger and A.Ledger.data, "characters", U.MarketInfo(), "|" .. guid)
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

-- Keep legacy random suffixes and modern bonus lists separate. Link level,
-- unique instance ID, gems and player-applied enchants are not market variants.
function U.VariantKey(link)
    if not U.String(link) or #link>2048 then return nil end
    local payload = string.match(link, "item:([^|]+)")
    if not payload then return nil end
    local fields = {}
    for field in string.gmatch(payload .. ":", "(.-):") do
        fields[#fields + 1] = field
        if #fields >= 64 then return nil end
    end
    local itemID = tonumber(fields[1])
    local suffix = tonumber(fields[7]) or 0
    if not U.Number(itemID, 1, 2147483647, true) or
       not U.Number(suffix, -2147483647, 2147483647, true) then return nil end
    local key=tostring(itemID) .. ":" .. tostring(suffix)
    local count=(fields[13]==nil or fields[13]=="") and 0 or tonumber(fields[13])
    if not U.Number(count,0,16,true) then return nil end
    if count>0 then
        local bonuses,seen={},{}
        for index=14,13+count do
            local value=tonumber(fields[index])
            if not U.Number(value,1,2147483647,true) then return nil end
            if not seen[value] then bonuses[#bonuses+1]=value;seen[value]=true end
        end
        table.sort(bonuses)
        key=key .. ":b" .. table.concat(bonuses,",")
    end
    return key
end

function U.SplitVariant(key)
    if not U.String(key) or #key>224 then return nil end
    local id,suffix,tail=key:match("^(%d+):(%-?%d+)(.*)$")
    id,suffix=tonumber(id),tonumber(suffix)
    if not U.Number(id,1,2147483647,true) or not U.Number(suffix,-2147483647,2147483647,true) then return nil end
    if tail~="" then
        local values=tail:match("^:b(%d[%d,]*)$")
        if not values then return nil end
        local previous,count=0,0
        for part in values:gmatch("[^,]+") do
            local n=tonumber(part);count=count+1
            if not U.Number(n,1,2147483647,true) or n<=previous or count>16 then return nil end
            previous=n
        end
        if values:find(",,",1,true) or values:sub(-1)=="," then return nil end
    end
    if key:sub(1,#tostring(id)+#tostring(suffix)+1)~=id .. ":" .. suffix then return nil end
    return id,suffix,tail~=""
end

function U.LinkName(link)
    if not U.String(link) or #link > 2048 then return nil end
    local name = string.match(link, "|h%[([^%]]+)%]|h")
    if name and #name <= 256 then return name end
end

function U.Call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    if ok and U.Accessible(value) then return value end
end

-- Native portrait titles sit hundreds of levels above their root. Give each
-- standalone window a whole band so another window cannot cut through it.
local windows,windowSet={},{}
function U.FocusWindow(frame)
    for _=1,16 do
        if not frame or windowSet[frame] then break end
        frame=frame.GetParent and frame:GetParent() or nil
    end
    if not frame or not windowSet[frame] then return end
    if U.Combat() and frame.IsProtected and frame:IsProtected() then return end
    local index
    for i,other in ipairs(windows) do if other==frame then index=i;break end end
    if not index then return end
    table.remove(windows,index);windows[#windows+1]=frame
    for i,other in ipairs(windows) do
        if not U.Combat() or not other.IsProtected or not other:IsProtected() then other:SetFrameLevel(20+(i-1)*1024) end
    end
end
function U.ManageWindow(frame)
    if not frame or windowSet[frame] then return end
    if #windows>=12 then return end
    windowSet[frame]=true;windows[#windows+1]=frame
    if frame.SetToplevel then frame:SetToplevel(true) end
    frame:HookScript("OnShow",function(self)U.FocusWindow(self)end)
    frame:HookScript("OnMouseDown",function(self)U.FocusWindow(self)end)
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

U.rulesetNames = { normal = "Normal", pvp = "PvP", roleplaying = "Roleplaying",
    roleplayingpvp = "Roleplaying PvP", hardcore = "Hardcore" }
U.rulesetOrder = { "pvp", "normal", "roleplaying", "roleplayingpvp", "hardcore" }
U.defaultRuleset = "pvp"

function U.RulesetMarketKey(region, ruleset, faction)
    return "forever|" .. region .. "|" .. ruleset .. "|" .. faction
end

local rulesetTokens = { normal = "normal", pve = "normal", pvp = "pvp", rp = "roleplaying",
    roleplay = "roleplaying", roleplaying = "roleplaying", rppvp = "roleplayingpvp",
    roleplaypvp = "roleplayingpvp", roleplayingpvp = "roleplayingpvp", hardcore = "hardcore" }

local function LiveRuleset(realm)
    local compact = RealmName(realm)
    if not compact then return nil end
    -- Live reporting hosts look like CAMWOWUS2Realm8PvP. The site/host
    -- numbers are not market boundaries; the native region still is.
    local site, token = string.match(string.lower(compact), "^camwow(%a+)%d+realm%d+(%a+)$")
    if site and regions[site] then return rulesetTokens[token] end
end

local function ReadGameRule(name)
    local rule = Enum and Enum.GameRule and Enum.GameRule[name]
    if not U.Number(rule, 0, nil, true) then return nil end
    local active = U.Call(C_GameRules and C_GameRules.IsGameRuleActive, rule)
    if type(active) == "boolean" then return active end
end

local function NativeRuleset(info)
    local hardcore = U.Call(C_GameRules and C_GameRules.IsHardcoreActive)
    local hc = ReadGameRule("HardcoreRuleset")
    local pvp = ReadGameRule("PvPRuleset")
    local rp = ReadGameRule("RPRuleset")
    info.hardcoreFlag, info.pvpFlag, info.roleplayFlag = hc, pvp, rp
    if hardcore == true then return "hardcore", "C_GameRules.IsHardcoreActive" end
    local source = "C_GameRules.IsGameRuleActive"
    if hc == true then return "hardcore", source end
    if (hc == false or hardcore == false) and pvp ~= nil and rp ~= nil then
        if rp then return pvp and "roleplayingpvp" or "roleplaying", source end
        return pvp and "pvp" or "normal", source
    end
end

local function ReportingRuleset(realm, source, live)
    if live then return live, source .. " (Forever live reporting alias)" end
    if not realm then return nil end
    local compact = string.lower(RealmName(realm) or "")
    -- These are internal reporting aliases, not traditional market realms.
    -- Match known Forever beta/future alias forms conservatively. Never infer
    -- a ruleset from the player's PvP flag or Classic/Modern UI preset.
    for _, prefix in ipairs({ "classicbeta", "forever", "wowforever" }) do
        for token, ruleset in pairs(rulesetTokens) do
            if string.match(compact, "^" .. prefix .. token .. "%d*$") then
                return ruleset, source .. " (Forever reporting alias)"
            end
        end
    end
end

function U.MarketInfo()
    local normalized, normalizedError = PublicCall(GetNormalizedRealmName)
    local rawRealm, realmError = PublicCall(GetRealmName)
    local rawRegion, regionError = PublicCall(GetCurrentRegion)
    local faction, factionError = PublicCall(UnitFactionGroup, "player")
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
        nativeFaction = Describe(faction, factionError),
    }
    info.realm = RealmName(normalized) and normalized or nil
    info.realmSource = "GetNormalizedRealmName"
    if not info.realm then
        info.realm, info.realmSource = RealmName(rawRealm), "GetRealmName"
    end
    -- Forever beta reports native region 90. Accept the API's positive integer
    -- identifier rather than restricting it to production regions 1-10.
    if U.Number(rawRegion, 1, 2147483647, true) then
        info.region, info.regionSource = tostring(rawRegion), "GetCurrentRegion"
    elseif regions[PortalName(rawRegion)] then
        info.region, info.regionSource = tostring(regions[PortalName(rawRegion)]), "GetCurrentRegion"
    elseif portal then
        -- A named test/beta portal remains a separate market. Never guess a
        -- region from locale or silently share prices with another portal.
        info.region = regions[portal] and tostring(regions[portal]) or ("portal:" .. portal)
        info.regionSource = portalSource
    end
    local live = LiveRuleset(info.realm)
    info.detectedRuleset, info.detectedSource = NativeRuleset(info)
    if not info.detectedRuleset then
        info.detectedRuleset, info.detectedSource = ReportingRuleset(info.realm, info.realmSource, live)
    end
    if U.String(faction) and (faction == "Horde" or faction == "Alliance" or faction == "Neutral") then
        info.faction = faction
    end
    info.canChooseRuleset = info.region ~= nil and info.faction ~= nil and (info.detectedRuleset ~= nil or not info.realm)
    if info.canChooseRuleset and A.DB then
        info.selectedRuleset, info.selectionSource = A.DB.RulesetSelection(info)
    end
    info.ruleset = info.selectedRuleset or info.detectedRuleset
    info.rulesetSource = info.selectionSource or info.detectedSource
    if not info.region then
        info.reason = "Region and login portal are unavailable. Copy diagnostics to report the lookup values."
    elseif info.ruleset then
        info.kind = "realmless-ruleset"
        if not info.faction then
            info.reason = "Player faction is unavailable. Try again after entering the world; copy diagnostics if it persists."
        else
            -- Share reporting hosts in one ruleset, keep Normal/PvP separate,
            -- and conservatively keep faction prices separate until the AH's
            -- cross-faction sharing has been qualified on this client.
            info.key = U.RulesetMarketKey(info.region, info.ruleset, info.faction)
            info.label = U.rulesetNames[info.ruleset] .. " ruleset (" .. info.faction .. ")"
            local liveAlias = live ~= nil and live == info.ruleset
            info.recoverLiveHosts = liveAlias or not info.realm
            if liveAlias then info.legacyKey = info.region .. "|" .. info.realm end
        end
    elseif not info.realm then
        if info.canChooseRuleset then
            info.pendingRuleset = U.defaultRuleset
            info.label = U.rulesetNames[info.pendingRuleset] .. " (confirm ruleset)"
            info.reason = "Confirm your ruleset to load saved prices and scan the Auction House."
        else
            info.reason = "Player faction is unavailable. Try again after entering the world; copy diagnostics if it persists."
        end
    else
        -- An unrecognized alias stays isolated. Old realm-key records remain
        -- readable in this fallback but are not merged into ruleset caches.
        info.kind, info.label = "isolated-alias", "Ruleset undetected (" .. info.realm .. ")"
        info.key = info.region .. "|" .. info.realm
    end
    return info
end

function U.LegacyLiveHost(key, market)
    if not market.recoverLiveHosts or not U.String(key) then return false end
    local region, realm = string.match(key, "^([^|]+)|([^|]+)$")
    return region == market.region and LiveRuleset(realm) == market.ruleset
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
