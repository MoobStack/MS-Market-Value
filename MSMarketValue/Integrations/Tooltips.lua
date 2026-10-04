local _, A = ...
local U, D, V = A.Util, A.DB, A.Valuation
local T = { seen = setmetatable({}, { __mode = "k" }), allowed = setmetatable({}, { __mode = "k" }) }
A.Tooltips = T

function T.Lines(itemID, link)
    local settings, snapshot = D.Settings(), D.Snapshot()
    local info = V.ItemInfo(link or itemID)
    local lines = {}
    local function add(left, right, kind)
        lines[#lines + 1] = { left = left, right = right, kind = kind }
    end
    if not settings.showVendor and not settings.showAuction and not settings.showDisenchant then return lines end
    add(A.TITLE, "Values per item", "header")
    if settings.showVendor then
        add("Vendor sell (each)", info and (info.vendor == 0 and "No vendor sale" or U.Money(info.vendor)) or "Item data loading")
    end
    if settings.showAuction then
        local price, mode = D.Price(itemID, link, snapshot)
        if price then
            add(mode == "item-wide" and "AH low (item-wide)" or "AH low (each)", U.Money(price.low))
        else
            local messages = { ["no-scan"] = "Scan required", ["bid-only"] = "No buyout in scan", ["not-listed"] = "Not listed in scan" }
            add("AH low (each)", messages[mode] or "Unavailable", "muted")
        end
    end
    if settings.showDisenchant and info then
        local outcomes, reason = V.Outcomes(info)
        if outcomes then
            add("Disenchant estimate", "iLvl " .. tostring(info.level), "header")
            if settings.showMaterials then
                for _, outcome in ipairs(outcomes) do
                    local quantity = outcome.min == outcome.max and tostring(outcome.min) or (tostring(outcome.min) .. "-" .. tostring(outcome.max))
                    local probability = string.format("%g%%", outcome.probability * 100)
                    add(V.MaterialName(outcome.id), quantity .. " (" .. probability .. "; avg " .. string.format("%.2f", outcome.expected) .. ")")
                end
                add("One possible outcome per item.", nil, "muted")
            end
            local value = V.DisenchantValue(outcomes, snapshot)
            if value.complete then
                add("DE value (expected, each)", U.Money(value.value))
            else
                add("DE value (expected, each)", "Unavailable", "muted")
                add("Unpriced materials", tostring(#value.missing), "muted")
                if value.subtotal > 0 then add("Priced portion only", U.Money(value.subtotal), "muted") end
            end
            add("Classic reference; Forever rules unverified.", nil, "warning")
        elseif reason == "no-profile" then
            add("Disenchant estimate", "No iLvl profile", "muted")
        elseif reason == "excluded" then
            add("Disenchant estimate", "Item excluded", "muted")
        end
    elseif settings.showDisenchant and not info then
        add("Disenchant estimate", "Item data loading", "muted")
    end
    if settings.showAge and snapshot and (settings.showAuction or settings.showDisenchant) then
        add("Auction snapshot", U.Age(snapshot.startedAt) .. (D.IsStale(snapshot) and " (stale)" or ""), D.IsStale(snapshot) and "warning" or "muted")
    end
    return lines
end

local colors = {
    header = { 0.55, 0.83, 0.85 }, muted = { 0.61, 0.66, 0.70 },
    warning = { 0.92, 0.72, 0.38 }, normal = { 0.83, 0.86, 0.89 },
}

function T.Handle(tooltip, data)
    if A.disabledReason or not D.data or U.Combat() then return end
    if not U.Accessible(tooltip) or not T.allowed[tooltip] or not U.Table(data) then return end
    if tooltip.IsForbidden and tooltip:IsForbidden() then return end
    local itemID = data.id
    if not U.Number(itemID, 1, 2147483647, true) then return end
    if tooltip.GetPrimaryTooltipData then
        local primary = tooltip:GetPrimaryTooltipData()
        if not U.Table(primary) or primary ~= data then return end
    end
    local old = T.seen[tooltip]
    if old and old.data == data and old.finalLines == tooltip:NumLines() then return end
    local link
    if tooltip.GetItem then
        local ok, _, found = pcall(tooltip.GetItem, tooltip)
        if ok and U.String(found) and U.ItemID(found) == itemID then link = found end
    end
    local lines = T.Lines(itemID, link)
    if #lines == 0 then return end
    tooltip:AddLine(" ")
    for _, line in ipairs(lines) do
        local color = colors[line.kind or "normal"]
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
    if U.Combat() or A.disabledReason then return end
    for tooltip in pairs(T.allowed) do
        if tooltip:IsShown() and tooltip.RebuildFromTooltipInfo and
           not (tooltip.IsForbidden and tooltip:IsForbidden()) then
            T.seen[tooltip] = nil
            pcall(tooltip.RebuildFromTooltipInfo, tooltip)
        end
    end
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
