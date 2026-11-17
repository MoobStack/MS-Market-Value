local _,A=...
local U=A.Util
local UI={controls={}}
A.SellUI=UI
local names={"ItemSellFrame","CommoditiesSellFrame"}

local function Frame(value)
    return U.Table(value) and not (value.IsForbidden and value:IsForbidden())
end

local function Inputs(native)
    if not Frame(native) or not Frame(native.PriceInput) then return end
    local price=native.PriceInput
    local money=price.MoneyInputFrame
    if not Frame(money) or type(price.GetAmount)~="function" or type(price.SetAmount)~="function" then return end
    for _,key in ipairs({"GoldBox","SilverBox","CopperBox"})do
        local box=money[key]
        if not Frame(box) or type(box.IsEnabled)~="function" then return end
    end
    if type(money.GoldBox.GetMaxLetters)~="function" then return end
    return price,money
end

local function Read(control)
    if A.disabledReason or not A.auctionOpen or U.Combat() then return end
    local native=control.native
    local price,money=Inputs(native)
    if price~=control.price or not money or money.CopperBox~=control.copper then return end
    if U.Call(native.IsVisible,native)~=true or U.Call(control.copper.IsVisible,control.copper)~=true then return end
    if type(native.GetItem)~="function" then return end
    local item=U.Call(native.GetItem,native)
    if not U.Accessible(item) or not item then return end
    for _,key in ipairs({"GoldBox","SilverBox","CopperBox"})do
        if U.Call(money[key].IsEnabled,money[key])~=true then return end
    end
    local digits=U.Call(money.GoldBox.GetMaxLetters,money.GoldBox)
    if not U.Number(digits,1,11,true) then return end
    local maximum=10^digits*10000-1
    local amount=U.Call(price.GetAmount,price)
    if not U.Number(amount,0,maximum,true) then return end
    return amount,maximum
end

function UI.RefreshControl(control)
    local amount,maximum=Read(control)
    local up,down=amount~=nil and amount<maximum,amount~=nil and amount>0
    control.up:SetEnabled(up);control.down:SetEnabled(down)
    local high,low=up and 1 or .45,down and 1 or .45
    control.up.icon:SetVertexColor(high,high,high)
    control.down.icon:SetVertexColor(low,low,low)
end

function UI.Change(control,step)
    if step~=1 and step~=-1 then return end
    local amount,maximum=Read(control)
    if not amount then return end
    local value=math.max(0,math.min(maximum,amount+step))
    if value~=amount then
        -- The native setter normalizes denominations and fires the existing
        -- price callback, which updates totals and posting validation.
        control.price:SetAmount(value)
    end
    UI.RefreshControl(control)
end

local function Arrow(control,up)
    local button=CreateFrame("Button",nil,control.frame,"UIPanelButtonTemplate")
    button:SetSize(28,24)
    button:SetPoint("TOPLEFT",control.frame,"TOPLEFT",0,up and 0 or -26)
    local icon=button:CreateTexture(nil,"ARTWORK")
    icon:SetAtlas("auctionhouse-ui-sortarrow")
    icon:SetSize(14,12);icon:SetPoint("CENTER",button,"CENTER",0,0)
    icon:SetTexCoord(0,1,up and 1 or 0,up and 0 or 1)
    button.icon=icon
    button:RegisterForClicks("LeftButtonUp")
    button:SetScript("OnClick",function(_,mouse)
        if mouse=="LeftButton" then UI.Change(control,up and 1 or -1) end
    end)
    button:SetScript("OnEnter",function(self)
        if GameTooltip then
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            GameTooltip:AddLine((up and "Increase" or "Decrease").." unit price by 1 copper.")
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave",function()if GameTooltip then GameTooltip:Hide()end end)
    button:Show()
    return button
end

function UI.Install()
    if not U.Combat() and not A.disabledReason and A.DB.data and Frame(AuctionHouseFrame) then
        for _,name in ipairs(names)do
            local native=AuctionHouseFrame[name]
            local price,money=Inputs(native)
            if price and not UI.controls[native] then
                local frame=CreateFrame("Frame",nil,money.CopperBox)
                frame:SetPoint("LEFT",money.CopperBox,"RIGHT",6,0)
                frame:SetSize(28,50)
                local control={frame=frame,native=native,price=price,copper=money.CopperBox}
                control.up,control.down=Arrow(control,true),Arrow(control,false)
                UI.controls[native]=control
                -- The wider buttons use the remaining space beside copper.
                -- Put the native warning just below that field, clear of the list.
                if Frame(price.PriceError) then
                    price.PriceError:ClearAllPoints()
                    price.PriceError:SetPoint("TOPRIGHT",money.CopperBox,"BOTTOMRIGHT",0,-4)
                end
                local function refresh()UI.RefreshControl(control)end
                native:HookScript("OnShow",refresh)
                for _,key in ipairs({"GoldBox","SilverBox","CopperBox"})do money[key]:HookScript("OnTextChanged",refresh) end
                frame:Show()
            end
        end
    end
    for _,control in pairs(UI.controls)do UI.RefreshControl(control)end
end

function UI.Diagnostics()
    local states={}
    for index,name in ipairs(names)do
        local native=Frame(AuctionHouseFrame) and AuctionHouseFrame[name]
        states[index]=(index==1 and "item=" or "commodity=")..(native and UI.controls[native] and "installed" or "waiting")
    end
    return "Sell-page price arrows: "..table.concat(states,"; ").."; step=1c"
end
