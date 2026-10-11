local _, A = ...
local U, D, V = A.Util, A.DB, A.Valuation
local T = { seen = setmetatable({}, { __mode = "k" }), allowed = setmetatable({}, { __mode = "k" }), refreshing = false }
A.Tooltips = T

local MAX_STACK = 1000000

local function PublicCall(fn, ...)
    if not U.Accessible(fn) or type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    if ok and U.Accessible(value) then return value end
end

local function StackFromLocation(location, itemID)
    if not U.Table(location) then return nil end
    local found = PublicCall(C_Item and C_Item.GetItemID, location)
    if not U.Number(found, 1, 2147483647, true) or found ~= itemID then return nil end
    local count = PublicCall(C_Item and C_Item.GetStackCount, location)
    if U.Number(count, 1, MAX_STACK, true) then return count end
end

function T.StackCount(tooltip, data, itemID)
    if not U.Accessible(tooltip) or not tooltip or
       (tooltip.IsForbidden and tooltip:IsForbidden()) or
       not U.Table(data) or not U.Number(itemID, 1, 2147483647, true) then return 1 end
    -- A GUID identifies one actual owned item instance, including stacks in
    -- bags/bank or an equipped slot. Never use total ownership or max stack size.
    if U.String(data.guid) and data.guid ~= "" then
        local location = PublicCall(C_Item and C_Item.GetItemLocation, data.guid)
        local count = StackFromLocation(location, itemID)
        if count then return count end
    end
    local info = PublicCall(tooltip.GetPrimaryTooltipInfo, tooltip)
    if not U.Table(info) or not U.String(info.getterName) or not U.Table(info.getterArgs) then return 1 end
    local args = info.getterArgs
    if info.getterName == "GetBagItem" and
       U.Number(args[1], -100, 100, true) and U.Number(args[2], 1, 1000, true) then
        local slot = PublicCall(C_Container and C_Container.GetContainerItemInfo, args[1], args[2])
        if U.Table(slot) and U.Number(slot.itemID, 1, 2147483647, true) and slot.itemID == itemID and
           U.Number(slot.stackCount, 1, MAX_STACK, true) then return slot.stackCount end
    elseif info.getterName == "GetInventoryItem" and U.String(args[1]) and args[1] == "player" and
           U.Number(args[2], 1, 1000, true) then
        local location = PublicCall(ItemLocation and ItemLocation.CreateFromEquipmentSlot, ItemLocation, args[2])
        local count = StackFromLocation(location, itemID)
        if count then return count end
    end
    -- Generic item links and unknown/restricted locations have no reliable
    -- stack context. Display each-only values instead of inventing a quantity.
    return 1
end

function T.Lines(itemID, link, stackCount)
    local settings, snapshot = D.Settings(), D.Snapshot()
    local info = V.ItemInfo(link or itemID)
    local count = U.Number(stackCount, 1, MAX_STACK, true) and stackCount or 1
    local lines = {}
    local function add(left, right, kind)
        lines[#lines + 1] = { left = left, right = right, kind = kind }
    end
    local function money(value)
        local each = U.Money(value)
        if count > 1 then return each .. " / " .. U.Money(value * count) end
        return each
    end
    if not settings.showVendor and not settings.showAuction and not settings.showDisenchant then return lines end
    local outcomes, reason, deValue
    if settings.showDisenchant and info then
        outcomes, reason = V.Outcomes(info)
        if outcomes then deValue = V.DisenchantValue(outcomes, snapshot) end
    end
    add(A.TITLE, count > 1 and ("Each / Stack (" .. tostring(count) .. ")") or "Each", "header")
    if settings.showVendor then
        add("Vendor sell", info and (info.vendor == 0 and "No vendor sale" or money(info.vendor)) or "Item data loading")
    end
    if settings.showAuction then
        local price, mode = D.Price(itemID, link, snapshot)
        if price then
            add(mode == "item-wide" and "AH low (item-wide)" or "AH low", money(price.low))
        else
            local messages = { ["no-scan"] = "Scan required", ["bid-only"] = "No buyout in scan", ["not-listed"] = "Not listed in scan" }
            add("AH low", messages[mode] or "Unavailable", "muted")
        end
    end
    if deValue then
        add("DE expected", deValue.complete and money(deValue.value) or "Unavailable", deValue.complete and "normal" or "muted")
        if not deValue.complete then
            add("Unpriced materials", tostring(#deValue.missing), "muted")
            if deValue.subtotal > 0 then add("DE priced portion only", money(deValue.subtotal), "muted") end
        end
    elseif settings.showDisenchant and not info then
        add("DE expected", "Item data loading", "muted")
    end
    if settings.showAge and snapshot and (settings.showAuction or settings.showDisenchant) then
        add("Auction snapshot", U.Age(snapshot.startedAt) .. (D.IsStale(snapshot) and " (stale)" or ""), D.IsStale(snapshot) and "warning" or "muted")
    end
    if outcomes or reason == "no-profile" or reason == "excluded" then
        add(" ", nil, "spacer")
        add("Disenchant estimate", "iLvl " .. tostring(info.level), "header")
        if outcomes then
            if settings.showMaterials then
                for _, outcome in ipairs(outcomes) do
                    local quantity = outcome.min == outcome.max and tostring(outcome.min) or (tostring(outcome.min) .. "-" .. tostring(outcome.max))
                    local probability = string.format("%g%%", outcome.probability * 100)
                    add(V.MaterialName(outcome.id), quantity .. " (" .. probability .. "; avg " .. string.format("%.2f", outcome.expected) .. ")")
                end
                add("One possible outcome per item.", nil, "muted")
            end
            add("Classic reference; Forever rules unverified.", nil, "warning")
        else
            add("Reference model", reason == "excluded" and "Item excluded" or "No iLvl profile", "muted")
        end
    end
    return lines
end

local colors = {
    header = { 0.55, 0.83, 0.85 }, muted = { 0.61, 0.66, 0.70 },
    warning = { 0.92, 0.72, 0.38 }, normal = { 0.83, 0.86, 0.89 },
}

function T.Handle(tooltip, data)
    if A.disabledReason or not D.data then return end
    if not U.Accessible(tooltip) or not T.allowed[tooltip] or not U.Table(data) then return end
    if tooltip.IsForbidden and tooltip:IsForbidden() then return end
    local itemID = data.id
    if not U.Number(itemID, 1, 2147483647, true) then return end
    if tooltip.GetPrimaryTooltipData then
        local primary = PublicCall(tooltip.GetPrimaryTooltipData, tooltip)
        if not U.Table(primary) or primary ~= data then return end
    end
    local old = T.seen[tooltip]
    if old and old.data == data and old.finalLines == tooltip:NumLines() then return end
    local link
    if tooltip.GetItem then
        local ok, _, found = pcall(tooltip.GetItem, tooltip)
        if ok and U.String(found) and U.ItemID(found) == itemID then link = found end
    end
    local lines = T.Lines(itemID, link, T.StackCount(tooltip, data, itemID))
    if #lines == 0 then return end
    tooltip:AddLine(" ")
    for _, line in ipairs(lines) do
        local color = colors[line.kind or "normal"] or colors.normal
        if line.right then
            tooltip:AddDoubleLine(line.left, line.right, color[1], color[2], color[3], color[1], color[2], color[3])
        else
            tooltip:AddLine(line.left, color[1], color[2], color[3], true)
        end
    end
    T.seen[tooltip] = { data = data, finalLines = tooltip:NumLines() }
end

function T.Allow(tooltip)
    if not tooltip or not U.Accessible(tooltip) or T.allowed[tooltip] then return end
    if tooltip.IsForbidden and tooltip:IsForbidden() then return end
    T.allowed[tooltip] = true
    if tooltip.HookScript then
        -- OnHide is a supported frame script. OnTooltipSetItem is intentionally
        -- not used: Forever's modern tooltip pipeline is data-driven.
        tooltip:HookScript("OnHide", function(self) T.seen[self] = nil end)
    end
end

function T.RefreshVisible()
    if not T.installed or U.Combat() or A.disabledReason or T.refreshing then return end
    T.refreshing = true
    -- Comparison tooltips start in append mode under the native comparison
    -- manager. Generic rebuild changes that to append=false, and ClearLines
    -- can clear their infoList before InternalProcessInfo inserts into it.
    -- Refresh only getter-backed primary item tooltips. The native manager
    -- owns comparison refreshes; arbitrary allowed frames are decoration-only.
    for _, tooltip in ipairs({ GameTooltip, ItemRefTooltip }) do
        if U.Accessible(tooltip) and T.allowed[tooltip] and
           not (tooltip.IsForbidden and tooltip:IsForbidden()) and tooltip:IsShown() and
           type(tooltip.GetPrimaryTooltipInfo) == "function" and
           type(tooltip.RebuildFromTooltipInfo) == "function" then
            local ok, info = pcall(tooltip.GetPrimaryTooltipInfo, tooltip)
            if ok and U.Table(info) and U.Accessible(info.append) and not info.append and
               (U.String(info.getterName) or (U.Accessible(info.getterFunction) and type(info.getterFunction) == "function")) then
                local dataOK, data
                if type(tooltip.GetPrimaryTooltipData) == "function" then
                    dataOK, data = pcall(tooltip.GetPrimaryTooltipData, tooltip)
                end
                if dataOK and U.Table(data) and U.Accessible(data.type) and
                   data.type == Enum.TooltipDataType.Item and U.Number(data.id, 1, 2147483647, true) then
                    T.seen[tooltip] = nil
                    pcall(tooltip.RebuildFromTooltipInfo, tooltip)
                end
            end
        end
    end
    T.refreshing = false
end

function T.Install()
    if T.installed then return true end
    if not TooltipDataProcessor or not TooltipDataProcessor.AddTooltipPostCall or
       not Enum or not Enum.TooltipDataType or Enum.TooltipDataType.Item == nil then
        A.tooltipReason = "The modern item tooltip API is unavailable."
        return false
    end
    for _, name in ipairs({ "GameTooltip", "ItemRefTooltip", "ShoppingTooltip1", "ShoppingTooltip2", "ItemRefShoppingTooltip1", "ItemRefShoppingTooltip2" }) do
        T.Allow(_G[name])
    end
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, T.Handle)
    T.installed = true
    return true
end
