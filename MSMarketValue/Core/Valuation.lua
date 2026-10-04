local _, A = ...
local U, D, P = A.Util, A.DB, A.DEProfile
local V = {}
A.Valuation = V

local equipSlots = {
    INVTYPE_HEAD = true, INVTYPE_NECK = true, INVTYPE_SHOULDER = true,
    INVTYPE_CHEST = true, INVTYPE_ROBE = true, INVTYPE_WAIST = true,
    INVTYPE_LEGS = true, INVTYPE_FEET = true, INVTYPE_WRIST = true,
    INVTYPE_HAND = true, INVTYPE_FINGER = true, INVTYPE_TRINKET = true,
    INVTYPE_CLOAK = true, INVTYPE_WEAPON = true, INVTYPE_SHIELD = true,
    INVTYPE_2HWEAPON = true, INVTYPE_WEAPONMAINHAND = true,
    INVTYPE_WEAPONOFFHAND = true, INVTYPE_HOLDABLE = true,
    INVTYPE_RANGED = true, INVTYPE_RANGEDRIGHT = true, INVTYPE_THROWN = true,
}

function V.ItemInfo(item)
    if not U.Accessible(item) or (type(item) ~= "string" and type(item) ~= "number") then return nil end
    if not C_Item or not C_Item.GetItemInfo then return nil end
    local r = { pcall(C_Item.GetItemInfo, item) }
    if not r[1] then return nil end
    -- Only touch fields used by this addon. Restricted fields stop the feature.
    for _, index in ipairs({ 2, 3, 4, 5, 10, 12, 13, 14 }) do
        if not U.Accessible(r[index]) then return nil end
    end
    if not U.String(r[2]) or not U.String(r[3]) or
       not U.Number(r[4], 0, 8, true) or not U.Number(r[5], 0, 100000, true) or
       not U.Number(r[12], 0) or not U.Number(r[13], 0, 100, true) or
       not U.Number(r[14], 0, 100, true) or not U.String(r[10]) then return nil end
    local itemID = U.ItemID(r[3])
    if not itemID then return nil end
    return {
        id = itemID, name = r[2], link = r[3], quality = r[4], level = r[5],
        equipLoc = r[10], vendor = r[12], classID = r[13], subclassID = r[14],
    }
end

local function Outcome(itemID, probability, minimum, maximum)
    return { id = itemID, probability = probability / 100, min = minimum, max = maximum,
             expected = probability / 100 * (minimum + maximum) / 2 }
end

local function Find(rows, level)
    for _, row in ipairs(rows) do
        if level >= row[1] and level <= row[2] then return row end
    end
end

function V.Outcomes(info)
    if not info or not U.Number(info.quality, 2, 4, true) or
       not U.Number(info.level, 1, 100000, true) or
       not U.String(info.equipLoc) or not equipSlots[info.equipLoc] then return nil, "ineligible" end
    if info.classID ~= 2 and info.classID ~= 4 then return nil, "ineligible" end
    if info.classID == 2 and info.subclassID == 20 then return nil, "ineligible" end -- fishing poles
    if info.classID == 4 and info.subclassID == 5 then return nil, "ineligible" end -- cosmetic armor
    if D.data and D.data.excludedItems[info.id] then return nil, "excluded" end
    local results, row = {}
    if info.quality == 2 then
        row = Find(P.green, info.level)
        if row then
            -- Wands follow armor's dust-heavy distribution in the reference.
            local weapon = info.classID == 2 and info.subclassID ~= 19
            local dustChance = weapon and row[12] or row[10]
            local essenceChance = weapon and row[13] or row[11]
            results[1] = Outcome(row[3], dustChance, row[4], row[5])
            results[2] = Outcome(row[6], essenceChance, row[7], row[8])
            if row[9] then results[3] = Outcome(row[9], 100 - dustChance - essenceChance, 1, 1) end
        end
    else
        row = Find(info.quality == 3 and P.rare or P.epic, info.level)
        if row then
            results[1] = Outcome(row[3], row[6], row[4], row[5])
            if info.quality == 3 and row[6] < 100 then
                results[2] = Outcome(20725, 100 - row[6], 1, 1)
            end
        end
    end
    if not row then return nil, "no-profile" end
    return results, P.label
end

function V.DisenchantValue(outcomes, snapshot)
    local result = { subtotal = 0, missing = {}, complete = true, expectedQuantities = {} }
    for _, outcome in ipairs(outcomes) do
        result.expectedQuantities[outcome.id] = outcome.expected
        local price = D.Price(outcome.id, nil, snapshot)
        if price then
            result.subtotal = result.subtotal + outcome.expected * price.low
        else
            result.complete = false
            result.missing[#result.missing + 1] = outcome.id
        end
    end
    -- A missing price is not a zero price. No complete total is exposed unless
    -- every possible material has a current-snapshot buyout observation.
    if result.complete then result.value = result.subtotal end
    return result
end

function V.MaterialName(itemID)
    if C_Item and C_Item.GetItemInfo then
        local ok, name = pcall(C_Item.GetItemInfo, itemID)
        if ok and U.String(name) then return name end
    end
    return P.materials[itemID] or ("Item " .. tostring(itemID))
end
