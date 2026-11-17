local fresh,test,equal,truth,secret=...

local function world()
    local w,A=fresh();w:load();local ah=w:makeAH()
    function w:sell(name,amount)
        local native=CreateFrame("Frame",nil,ah)
        local price=CreateFrame("Frame",nil,native);native.PriceInput=price
        local money=CreateFrame("Frame",nil,price);price.MoneyInputFrame=money
        for _,key in ipairs({"GoldBox","SilverBox","CopperBox"})do
            local box=CreateFrame("EditBox",nil,money);money[key]=box
            box:SetMaxLetters(key=="GoldBox" and 7 or 2)
            function box:GetAmount()return tonumber(self:GetText())or 0 end
            box:SetScript("OnTextChanged",function()
                native.updates=(native.updates or 0)+1
                native.total=price:GetAmount()*native.quantity
            end)
            box:Show()
        end
        function price:GetAmount()return money.GoldBox:GetAmount()*10000+money.SilverBox:GetAmount()*100+money.CopperBox:GetAmount()end
        function price:SetAmount(value)
            money.CopperBox:SetText(tostring(value%100))
            money.SilverBox:SetText(tostring(math.floor(value/100)%100))
            money.GoldBox:SetText(tostring(math.floor(value/10000)))
        end
        native.item={};native.quantity=5
        function native:GetItem()return self.item end
        price.PriceError=CreateFrame("Frame",nil,price)
        price:Show();money:Show();native:Show();ah[name]=native
        AuctionHouseFrameDisplayMode[name]={name}
        price:SetAmount(amount or 619)
        return native,price,money
    end
    w:sell("CommoditiesSellFrame");w:sell("ItemSellFrame")
    function w:showSell(name)
        ah:SetDisplayMode({name or "CommoditiesSellFrame"})
        A.SellUI.Install()
        return A.SellUI.controls[ah[name or "CommoditiesSellFrame"]]
    end
    w:openAH();w:showSell()
    return w,A,ah
end

local function click(button,mouse)button.scripts.OnClick(button,mouse or "LeftButton")end

test("sell arrows change the displayed unit price by one copper and preserve quantity",function()
    local w,A,ah=world();local c=w:showSell();local native=ah.CommoditiesSellFrame
    click(c.up);equal(native.PriceInput:GetAmount(),620);equal(native.total,3100);equal(native.quantity,5)
    click(c.down);equal(native.PriceInput:GetAmount(),619);equal(native.total,3095)
    equal(w.requests,0);equal(w.browseSearches,nil)
end)

test("sell arrows normalize silver and gold carry and borrow",function()
    local w,A,ah=world();local c=w:showSell();local p=ah.CommoditiesSellFrame.PriceInput
    for _,value in ipairs({99,9999,1000099})do
        p:SetAmount(value);click(c.up);equal(p:GetAmount(),value+1)
        equal(p.MoneyInputFrame.CopperBox:GetAmount(),0)
        click(c.down);equal(p:GetAmount(),value)
    end
end)

test("sell arrows stop at zero and at the gold field's representable limit",function()
    local w,A,ah=world();local c=w:showSell();local p=ah.CommoditiesSellFrame.PriceInput
    p:SetAmount(1);click(c.down);equal(p:GetAmount(),0);equal(c.down.enabled,false)
    local updates=ah.CommoditiesSellFrame.updates;click(c.down);equal(ah.CommoditiesSellFrame.updates,updates)
    p.MoneyInputFrame.GoldBox:SetMaxLetters(2);p:SetAmount(999999)
    equal(c.up.enabled,false);click(c.up);equal(p:GetAmount(),999999)
    click(c.down);equal(p:GetAmount(),999998);equal(c.up.enabled,true)
end)

test("both sell modes have their own primary price arrows and do not edit bid inputs",function()
    local w,A,ah=world();local c=w:showSell("ItemSellFrame")
    ah.ItemSellFrame.SecondaryPriceInput={amount=400}
    click(c.up);equal(ah.ItemSellFrame.PriceInput:GetAmount(),620)
    equal(ah.ItemSellFrame.SecondaryPriceInput.amount,400)
    equal(ah.CommoditiesSellFrame.PriceInput:GetAmount(),619)
end)

test("sell controls use larger red panel buttons beside copper and retain the warning below",function()
    local w,A,ah=world();local c=w:showSell()
    equal(c.frame.parent,c.copper);equal(c.frame.points[1][3],"RIGHT");equal(c.frame.width,26);equal(c.frame.height,46)
    equal(c.up.width,26);equal(c.up.height,22);equal(c.down.points[1][5],-24)
    equal(c.up.template,"UIPanelButtonTemplate");equal(c.down.template,"UIPanelButtonTemplate")
    equal(c.up.icon.atlas,"auctionhouse-ui-sortarrow");equal(c.up.icon.width,12);equal(c.up.icon.height,10)
    equal(c.up.icon.texCoord[3],1);equal(c.up.icon.texCoord[4],0)
    equal(c.down.icon.texCoord[3],0);equal(c.down.icon.texCoord[4],1)
    equal(ah.CommoditiesSellFrame.PriceInput.PriceError.points[1][2],c.copper)
    equal(ah.CommoditiesSellFrame.PriceInput.PriceError.points[1][3],"BOTTOMRIGHT")
    c.up.scripts.OnEnter(c.up);truth(string.find(GameTooltip.lines[#GameTooltip.lines].left,"1 copper",1,true))
    c.up.scripts.OnLeave(c.up);equal(GameTooltip:IsShown(),false)
end)

test("manual price edits refresh arrow limits and keep native text-change callbacks",function()
    local w,A,ah=world();local c=w:showSell();local native=ah.CommoditiesSellFrame;local p=native.PriceInput
    p:SetAmount(0);equal(c.down.enabled,false)
    local updates=native.updates;p.MoneyInputFrame.CopperBox:SetText("40")
    equal(c.down.enabled,true);equal(native.updates,updates+1);equal(native.total,200)
    click(c.down);equal(p:GetAmount(),39);equal(native.total,195)
end)

test("reopening or refreshing the auction house reuses sell buttons and hooks",function()
    local w,A,ah=world();local c=w:showSell();local count=w.createdFrames
    for _=1,50 do A.SellUI.Install()end
    equal(w.createdFrames,count);equal(A.SellUI.controls[ah.CommoditiesSellFrame],c)
    local native=ah.CommoditiesSellFrame;local before=native.updates
    native.PriceInput.MoneyInputFrame.CopperBox:SetText("25");equal(native.updates,before+1)
    w:event("AUCTION_HOUSE_CLOSED");w:openAH();w:showSell();equal(w.createdFrames,count)
end)

test("sell arrows remain inert for hidden pages, closed auctions and absent items",function()
    local w,A,ah=world();local c=w:showSell();local native=ah.CommoditiesSellFrame
    native.item=nil;A.SellUI.Install();equal(c.up.enabled,false);click(c.up);equal(native.PriceInput:GetAmount(),619)
    native.item={};w:showSell("ItemSellFrame");click(c.up);equal(native.PriceInput:GetAmount(),619)
    w:showSell();w:event("AUCTION_HOUSE_CLOSED");click(c.up);equal(native.PriceInput:GetAmount(),619)
end)

test("sell arrows respect native disabled or hidden money fields and forbidden frames",function()
    local w,A,ah=world();local c=w:showSell();local native=ah.CommoditiesSellFrame;local m=native.PriceInput.MoneyInputFrame
    m.CopperBox:SetEnabled(false);A.SellUI.Install();equal(c.up.enabled,false);click(c.up);equal(native.PriceInput:GetAmount(),619)
    m.CopperBox:SetEnabled(true);m.CopperBox:Hide();click(c.up);equal(native.PriceInput:GetAmount(),619)
    m.CopperBox:Show();native.forbidden=true;click(c.up);equal(native.PriceInput:GetAmount(),619)
end)

test("combat defers sell installation and blocks adjustments until combat ends",function()
    local w,A=fresh();w:load();w.combat=true;w:makeAH();w:openAH();equal(next(A.SellUI.controls),nil)
    local other,B,ah=world();local c=other:showSell()
    other.combat=true;other:event("PLAYER_REGEN_DISABLED");equal(c.up.enabled,false);click(c.up)
    equal(ah.CommoditiesSellFrame.PriceInput:GetAmount(),619)
    other.combat=false;other:event("PLAYER_REGEN_ENABLED");B.SellUI.Install();equal(c.up.enabled,true)
end)

test("late native sell frames install on the normal UI update without changing the selected page",function()
    local w,A,ah=world();local previous=ah.CommoditiesSellFrame
    ah.CommoditiesSellFrame=nil;A.SellUI.controls[previous]=nil
    local native=w:sell("CommoditiesSellFrame",100)
    ah:SetDisplayMode({"CommoditiesSellFrame"});local mode=ah.displayMode
    A.eventFrame.scripts.OnUpdate(A.eventFrame,.25)
    truth(A.SellUI.controls[native]);equal(ah.displayMode,mode)
end)

test("sell arrows reject malformed or restricted prices without replacing native values",function()
    for _,value in ipairs({-1,1.5,math.huge,0/0,secret})do
        local w,A,ah=world();local c=w:showSell();local p=ah.CommoditiesSellFrame.PriceInput
        p.GetAmount=function()return value end
        p.SetAmount=function()error("unreadable price must not be written")end
        A.SellUI.Install();equal(c.up.enabled,false);click(c.up);click(c.down)
    end
end)

test("sell arrows ignore right clicks and report both native installations",function()
    local w,A,ah=world();local c=w:showSell();click(c.up,"RightButton");equal(ah.CommoditiesSellFrame.PriceInput:GetAmount(),619)
    truth(string.find(A.SellUI.Diagnostics(),"item=installed; commodity=installed; step=1c",1,true))
end)

test("sell price help follows the interface switch while one-copper edits keep working",function()
    local w,A,ah=world();local c=w:showSell()
    c.up.scripts.OnEnter(c.up);truth(GameTooltip:IsShown())
    A.DB.Settings().showInterfaceTips=false;A.Help.Refresh();equal(GameTooltip:IsShown(),false)
    c.down.scripts.OnEnter(c.down);equal(GameTooltip:IsShown(),false)
    click(c.up);equal(ah.CommoditiesSellFrame.PriceInput:GetAmount(),620)
    A.DB.Settings().showInterfaceTips=true;c.down.scripts.OnEnter(c.down)
    truth(GameTooltip:IsShown());truth(GameTooltip.lines[1].left:find("Decrease",1,true))
end)
