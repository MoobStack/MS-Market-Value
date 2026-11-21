local fresh, test, equal, near, truth = ...

local function CreateMinimap()
    local map = CreateFrame("Frame", "Minimap", UIParent)
    map:SetSize(198, 198)
    map:Show()
    return map
end

test("the minimap badge opens the standalone window or the auction tab", function()
    local world, addon = fresh()
    world:load()
    equal(addon.MinimapBadge.button, nil)
    local map = CreateMinimap()
    world:event("PLAYER_ENTERING_WORLD")
    local badge = addon.MinimapBadge.button
    truth(badge:IsVisible())
    equal(badge:GetParent(), map)
    equal(badge.normalTexture, "Interface\\AddOns\\MSMarketValue\\UI\\Art\\MinimapBadge.tga")
    equal(badge:GetWidth(), 28)
    equal(badge:GetHeight(), 28)
    badge.scripts.OnEnter(badge)
    equal(#GameTooltip.lines, 1)
    equal(GameTooltip.lines[1].left, "Open MS Market Value")
    badge.scripts.OnLeave(badge)
    world:event("PLAYER_ENTERING_WORLD")
    equal(addon.MinimapBadge.button, badge)

    addon.auctionOpen = false
    badge.scripts.OnClick(badge)
    truth(addon.UI.frame:IsShown())
    equal(addon.UI.priceBasis:GetParent(), addon.UI.staleBox:GetParent())
    equal(addon.UI.rulesetButton:GetParent(), addon.UI.restartButton:GetParent())
    badge.scripts.OnClick(badge)
    equal(addon.UI.frame:IsShown(), false)

    world:openAH()
    badge.scripts.OnClick(badge)
    truth(addon.UI.panel:IsShown())
    equal(addon.UI.priceBasis:GetParent(), addon.UI.staleBox:GetParent())
    equal(addon.UI.rulesetButton:GetParent(), addon.UI.restartButton:GetParent())
    equal(world.requests, 0)
end)

test("the Tooltips checkbox remembers badge visibility across logins", function()
    local world, addon = fresh()
    CreateMinimap()
    world:load()
    truth(addon.DB.Settings().showMinimapBadge)
    addon.UI.ShowStandalone()
    local badge = addon.MinimapBadge.button
    local check = addon.UI.checks.showMinimapBadge
    equal(check:GetParent(), addon.UI.tooltipSettings)
    truth(check:GetChecked())
    check:SetChecked(false)
    check.scripts.OnClick(check)
    equal(badge:IsShown(), false)

    local login, after = fresh(addon.DB.data)
    CreateMinimap()
    login:load()
    equal(after.MinimapBadge.button, nil)
    after.UI.ShowStandalone()
    local toggle = after.UI.checks.showMinimapBadge
    equal(toggle:GetChecked(), false)
    after.DB.Settings().showInterfaceTips = false
    toggle:SetChecked(true)
    toggle.scripts.OnClick(toggle)
    truth(after.MinimapBadge.button:IsVisible())
    equal(after.DB.Settings().showInterfaceTips, false)
end)

test("the minimap badge drag repositions on a scaled map and keeps its place on reload", function()
    local world, addon = fresh()
    local map = CreateMinimap()
    map.effectiveScale = 1.25
    GetCursorPosition = function() return 960 * 1.25, 640 * 1.25 end
    world:load()
    addon.auctionOpen = false
    local badge = addon.MinimapBadge.button
    badge.scripts.OnDragStart(badge)
    badge.scripts.OnUpdate(badge)
    badge.scripts.OnDragStop(badge)
    equal(badge.scripts.OnUpdate, nil)
    near(addon.DB.data.minimapAngle, 90)
    near(badge.points[1][4], 0)
    near(badge.points[1][5], 101)
    badge.scripts.OnClick(badge)
    equal(addon.UI.frame, nil)
    badge.scripts.OnMouseDown(badge)
    badge.scripts.OnClick(badge)
    truth(addon.UI.frame:IsShown())

    local reload, after = fresh(addon.DB.data)
    local resized = CreateMinimap()
    resized:SetSize(180, 180)
    reload:load()
    near(after.MinimapBadge.button.points[1][4], 0)
    near(after.MinimapBadge.button.points[1][5], 92)
end)
