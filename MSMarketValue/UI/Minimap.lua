local _, A = ...
local U, D = A.Util, A.DB
local M = {}
A.MinimapBadge = M

local DEFAULT_ANGLE = -140
local ICON = "Interface\\AddOns\\" .. A.NAME .. "\\UI\\Art\\MinimapBadge.tga"

local function Place(button)
    local map = button:GetParent()
    local saved = D.data.minimapAngle
    local angle = math.rad(U.Number(saved, -180, 180) and saved or DEFAULT_ANGLE)
    local x = math.cos(angle) * (map:GetWidth() / 2 + 2)
    local y = math.sin(angle) * (map:GetHeight() / 2 + 2)
    button:ClearAllPoints()
    button:SetPoint("CENTER", map, "CENTER", x, y)
end

local function FollowCursor(button)
    local map = button:GetParent()
    local cx, cy = map:GetCenter()
    local scale = map:GetEffectiveScale()
    local x, y = GetCursorPosition()
    if not U.Number(cx) or not U.Number(cy) or not U.Number(x) or not U.Number(y) or
       not U.Number(scale) or scale <= 0 then return end
    D.data.minimapAngle = math.deg(math.atan2(y / scale - cy, x / scale - cx))
    Place(button)
end

local function Create(map)
    local button = CreateFrame("Button", "MSMarketValueMinimapButton", map)
    button:SetSize(28, 28)
    button:SetFrameLevel(map:GetFrameLevel() + 8)
    button:SetNormalTexture(ICON)
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnMouseDown", function(self) self.dragged = false end)
    button:SetScript("OnClick", function(self)
        if not self.dragged then A.UI.Toggle() end
    end)
    button:SetScript("OnDragStart", function(self)
        self.dragged = true
        A.Help.Hide(self)
        self:SetScript("OnUpdate", FollowCursor)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        FollowCursor(self)
    end)
    button:SetScript("OnHide", function(self) self:SetScript("OnUpdate", nil) end)
    map:HookScript("OnSizeChanged", function() Place(button) end)
    A.Help.Bind(button, "Open MS Market Value")
    return button
end

function M.Refresh()
    if not D.data or A.disabledReason or not D.Settings().showMinimapBadge then
        if M.button then M.button:Hide() end
        return
    end
    local map = Minimap
    if not U.Table(map) or (map.IsForbidden and map:IsForbidden()) then return end
    M.button = M.button or Create(map)
    Place(M.button)
    M.button:Show()
end
