local fresh,row,link,test,equal,near,truth,secret=...
local function guid(spawn)return "Creature-0-1-1-1-1000-"..(spawn or 1)end
local function world(saved,wall)
    local w,A=fresh(saved);w.wall=wall or w.wall
    w.guids={player=w.guid,mouseover=guid(),target=guid()};w.dead={mouseover=true,target=true}
    UnitGUID=function(unit)return w.guids[unit]end
    UnitName=function(unit)return unit=="player" and "Player" or "Test creature"end
    UnitIsDead=function(unit)return w.guids[unit]~=nil and w.dead[unit] or false end
    UnitIsTapDenied=function()return w.tapDenied or false end
    C_Map={GetBestMapForUnit=function()return 10 end}
    GetInstanceInfo=function()return "Test zone","none",1,"Normal",5,false,false,0 end
    GetRealZoneText=function()return "Test zone"end
    LOOT_ITEM_SELF="You receive loot: %s.";LOOT_ITEM_SELF_MULTIPLE="You receive loot: %sx%d."
    YOU_LOOT_MONEY="You loot %s";GOLD_AMOUNT="%d Gold";SILVER_AMOUNT="%d Silver";COPPER_AMOUNT="%d Copper"
    Enum.TooltipDataType.Unit=2
    TooltipDataProcessor.AddTooltipPostCall=function(kind,callback)if kind==2 then w.unitTip=callback end end
    w.loot={}
    GetNumLootItems=function()return #w.loot end
    GetLootSourceInfo=function(slot)local r=w.loot[slot];if r then return unpack(r.sources or {})end end
    GetLootSlotLink=function(slot)return w.loot[slot] and w.loot[slot].link end
    GetLootSlotInfo=function(slot)
        local r=w.loot[slot];return 1,"Item",r.quantity or 1,0,r.quality or 2,false,r.questID~=nil,r.questID,r.questID~=nil
    end
    for index=1,200 do
        local i=index
        _G["GameTooltipTextLeft"..i]={GetText=function()return GameTooltip.lines[i] and GameTooltip.lines[i].left end}
    end
    local show=GameTooltip.Show
    function GameTooltip:Show()show(self);self.fitLines=self:NumLines()end
    function GameTooltip:RebuildFromTooltipInfo()
        self:ClearLines();self:AddLine("Test creature");w.unitTip(self,self.data);self:Show()
    end
    w:load();A.DB.Settings().dropMode="observed";A.Farm.ConfigureIdle(false,5)
    function w:tick(seconds)self:advance(seconds);A.Farm.Tick();A.Drops.CheckTooltip()end
    function w:body(spawn,items)
        self.guids.mouseover,self.guids.target=guid(spawn),guid(spawn)
        self.dead.mouseover,self.dead.target=true,true;self.loot=items or {}
    end
    function w:open()self:event("LOOT_READY");self:event("LOOT_OPENED",false,false)end
    function w:close()self.loot={};self:event("LOOT_CLOSED")end
    function w:message(id,quantity,lineID)
        self:event("CHAT_MSG_LOOT","You receive loot: "..link(id)..(quantity and ("x"..quantity) or "")..".",nil,nil,nil,nil,nil,nil,nil,nil,nil,lineID)
    end
    function w:unitTooltip()
        GameTooltip:ClearLines();A.Drops.tip=nil
        GameTooltip.data={type=2,guid=guid()};GameTooltip.info={getterName="GetUnit",getterArgs={"mouseover"}}
        GameTooltip:AddLine("Test creature");self.unitTip(GameTooltip,GameTooltip.data);GameTooltip:Show()
    end
    return w,A
end
local function headers()
    local n=0;for _,r in ipairs(GameTooltip.lines)do if r.left and r.left:find("MS Market Value -",1,true)then n=n+1 end end;return n
end

test("empty inspected corpses lower personal drop rates without creating item income",function()
    local w,A=world()
    for i=1,3 do w:body(i);w:open();w:close()end
    w:body(4,{{link=link(100),sources={guid(4),1}}});w:open();w:close()
    local rows,samples=A.Drops.Rows(1000)
    if os.getenv("V131_REPLAY")=="1" then print("EMPTY_CORPSE_REPLAY samples="..samples.." rate="..rows[1].rate)end
    equal(samples,4);equal(rows[1].hits,1);near(rows[1].rate,25);equal(A.Farm.Summary().total,0)
end)

test("reopening an empty corpse and repeated ready events count one inspection",function()
    local w,A=world();w:open();w:event("LOOT_OPENED",false,false);w:event("LOOT_READY");w:close()
    w:open();w:close();equal(select(2,A.Drops.Rows(1000)),1);equal(A.Drops.emptyChecks,1)
end)

test("a previously looted corpse is not a second empty sample",function()
    local w,A=world();w:body(1,{{link=link(100),sources={guid(),1}}});w:open();w:close()
    w:open();w:close();local rows,n=A.Drops.Rows(1000);equal(n,1);equal(rows[1].rate,100)
end)

test("empty corpse deduplication survives reload without resetting existing observations",function()
    local w,A=world();w:open();w:close();local _,B=world(A.DB.data,w.wall)
    B.eventFrame.scripts.OnEvent(B.eventFrame,"LOOT_READY")
    B.eventFrame.scripts.OnEvent(B.eventFrame,"LOOT_OPENED",false,false)
    B.eventFrame.scripts.OnEvent(B.eventFrame,"LOOT_CLOSED")
    equal(select(2,B.Drops.Rows(1000)),1);equal(B.Drops.emptyChecks or 0,0)
end)

test("an empty-ready interaction can finish without an opened window",function()
    local w,A=world();w:event("LOOT_READY");w:event("LOOT_CLOSED")
    equal(select(2,A.Drops.Rows(1000)),1)
    w:body(2);w:event("LOOT_READY");w:tick(1.1);equal(select(2,A.Drops.Rows(1000)),2);equal(A.Drops.lootOpen,false)
end)

test("the inspected corpse identity survives the loot frame hiding mouseover",function()
    local w,A=world();w:event("LOOT_READY");w.guids.mouseover=nil
    w:event("LOOT_OPENED",false,false);w:close();equal(select(2,A.Drops.Rows(1000)),1)
end)

test("hovering a dead body alone never counts an inspected corpse",function()
    local w,A=world();w:event("UPDATE_MOUSEOVER_UNIT");w:unitTooltip();w:tick(2)
    equal(select(2,A.Drops.Rows(1000)),0)
end)

test("ambiguous alive foreign and restricted empty-loot sources never fabricate samples",function()
    for _,kind in ipairs({"absent","alive","denied","restricted","object"})do
        local w,A=world()
        if kind=="absent" then w.guids.mouseover=nil
        elseif kind=="alive" then w.dead.mouseover=false
        elseif kind=="denied" then w.tapDenied=true
        elseif kind=="restricted" then w.guids.mouseover=secret
        else w.guids.mouseover="GameObject-0-1-1-1-1000-1"end
        w:open();w:close();equal(select(2,A.Drops.Rows(1000)),0,kind)
    end
end)

test("item containers and an expired corpse candidate do not enter empty-corpse counts",function()
    local w,A=world();w:event("LOOT_READY");w:event("LOOT_OPENED",false,true);w:close()
    equal(select(2,A.Drops.Rows(1000)),0)
    w:event("LOOT_READY");w:advance(4);w:event("LOOT_OPENED",false,false);w:close()
    equal(select(2,A.Drops.Rows(1000)),0)
end)

test("empty sampling respects disabled collection and keeps skinning samples separate",function()
    local w,A=world();A.DB.Settings().dropTracking=false;w:open();w:close()
    equal(select(2,A.Drops.Rows(1000)),0);A.DB.Settings().dropTracking=true
    w:event("UNIT_SPELLCAST_SENT","player","Test creature","skin",8613);w:open();w:close()
    equal(select(2,A.Drops.Rows(1000)),0);equal(select(2,A.Drops.Rows(1000,"skinning")),1)
end)

test("empty-only personal sources show their inspection count and a truthful empty message",function()
    local w,A=world();w:open();w:close();w:unitTooltip()
    equal(GameTooltip.lines[3].right,"1 corpse checked")
    equal(GameTooltip.lines[4].left,"No item drops recorded yet.")
end)

test("quest rewards are session-only by default while hourly and peak stay farming-only",function()
    local w,A=world();w.items[200]={name="Quest reward",vendor=1000}
    for _=1,5 do truth(A.Farm.AddMoney(100,false));w:tick(60)end
    A.Farm.AddMoney(10000,true);A.Farm.AddItem(link(200),1,"quest")
    local s=A.Farm.Summary();equal(s.total,11500);equal(s.rateValue,500)
    near(s.perHour,6000);near(s.recentRate,6000);near(s.peak.rate,6000)
    A.DB.Settings().farmQuestInRate=true;s=A.Farm.Summary()
    near(s.perHour,138000);near(s.recentRate,138000);near(s.peak.rate,6000)
end)

test("quest interaction receipts cannot inflate peak or duplicate native quest rewards",function()
    local w,A=world();w.items[200]={name="Quest reward",vendor=100000}
    for _=1,5 do w:event("CHAT_MSG_MONEY","You loot 1 Silver");w:tick(60)end
    w:event("QUEST_COMPLETE");w:message(200,nil,991);w:tick(1.1)
    w:event("QUEST_TURNED_IN",42,100,50000);w:event("CHAT_MSG_MONEY","You loot 5 Gold")
    w:tick(1.1);w:event("QUEST_LOOT_RECEIVED",42,link(200),1);w:event("QUEST_FINISHED");w:tick(300)
    local s=A.Farm.Summary()
    if os.getenv("V131_REPLAY")=="1" then print("QUEST_REPLAY total="..s.total.." peak="..s.peak.rate.." rate="..s.perHour)end
    equal(s.total,150500);equal(s.questValue,100000);equal(s.questCoins,50000);equal(s.coins,500)
    near(s.peak.rate,6000);truth(s.perHour<6000);truth(s.recentRate<6000)
end)

test("native quest item events before generic chat count once in either event order",function()
    local w,A=world();w.items[200]={vendor=100}
    w:event("QUEST_COMPLETE");w:event("QUEST_LOOT_RECEIVED",42,link(200),2)
    w:tick(2);w:message(200,2,992);w:tick(1.1)
    equal(A.Farm.Summary().total,200);equal(A.Farm.Summary().questValue,200);equal(A.Farm.Summary().lootValue,0)
end)

test("a quest chat receipt without a dedicated item event still stays out of farming rates",function()
    local w,A=world();w.items[200]={vendor=10000}
    w:event("QUEST_COMPLETE");w:message(200,nil,993);w:tick(2);w:event("QUEST_FINISHED");w:tick(300)
    equal(A.Farm.Summary().total,10000);equal(A.Farm.Summary().perHour,0);equal(A.Farm.Summary().peak.rate,0)
end)

test("actual corpse receipts during a quest interaction remain farming income",function()
    local w,A=world();w.items[100]={vendor=100}
    w:event("QUEST_COMPLETE");w:body(1,{{link=link(100),sources={guid(),1}}});w:open()
    w:message(100,nil,994);w:event("CHAT_MSG_MONEY","You loot 1 Silver");w:close();w:tick(2)
    equal(A.Farm.Summary().lootValue,100);equal(A.Farm.Summary().coins,100);equal(A.Farm.Summary().questValue,0)
end)

test("a real corpse drop cannot consume the matching quest reward credit",function()
    local w,A=world();w.items[100]={vendor=100}
    w:event("QUEST_COMPLETE");w:event("QUEST_LOOT_RECEIVED",42,link(100),1)
    w:body(1,{{link=link(100),sources={guid(),1}}});w:open();w:message(100,nil,998);w:close();w:tick(2)
    equal(A.Farm.Summary().lootValue,100);equal(A.Farm.Summary().questValue,100)
    w:message(100,nil,999);w:tick(1.1)
    equal(A.Farm.Summary().total,200)
end)

test("reset waits for delayed quest confirmation and becomes available after settlement",function()
    local w,A=world();w.items[200]={vendor=100}
    w:event("QUEST_COMPLETE");w:message(200,nil,1000);w:tick(2)
    equal(A.Farm.Reset(),false);equal(A.Farm.Summary().total,100)
    w:event("QUEST_LOOT_RECEIVED",42,link(200),1)
    truth(A.Farm.Reset());equal(A.Farm.Profile().history[1].total,100)
    w:event("QUEST_COMPLETE");w:message(200,nil,1001);w:tick(2);equal(A.Farm.Reset(),false)
    w:event("QUEST_FINISHED");w:tick(4);truth(A.Farm.Reset())
end)

test("vendor sales and buybacks do not count acquired items a second time",function()
    local w,A=world();w.items[100]={vendor=50,name="Test item"};A.DB.Settings().farmUseAuction=false
    w.wallet=100000;GetMoney=function()return w.wallet end;NUM_BAG_SLOTS=0
    C_Container.GetContainerNumSlots=function()return 16 end
    C_Container.UseContainerItem=function()end;BuybackItem=function()end
    A.Transactions.Install()
    w:body(1,{{link=link(100),sources={guid(),1}}});w:open();w:message(100,nil,995);w:close();w:tick(2)
    equal(A.Farm.Summary().total,50)
    w.containers["0:1"]={itemID=100,stackCount=1,hyperlink=link(100)}
    w:event("MERCHANT_SHOW");C_Container.UseContainerItem(0,1)
    w.containers["0:1"]=nil;w.wallet=w.wallet+50
    w:event("PLAYER_MONEY");w:event("BAG_UPDATE_DELAYED");w:advance(.25);A.Transactions.Tick()
    equal(A.Farm.Summary().total,50)
    local sales=0;for _,r in ipairs(A.Ledger.Records())do if r.kind=="vendor_sale" then sales=sales+1;equal(r.amount,50)end end;equal(sales,1)
    w:event("CHAT_MSG_MONEY","You loot 1 Silver");w:message(100,nil,996)
    BuybackItem(1);w:event("PLAYER_MONEY");w:event("MERCHANT_CLOSED");w:tick(3)
    equal(A.Farm.Summary().total,50)
end)

test("wallet changes quest exclusions and manual pauses cannot create new farming value",function()
    local w,A=world();w:event("PLAYER_MONEY");equal(A.Farm.Summary().total,0)
    A.DB.Settings().farmIncludeQuest=false;w.items[200]={vendor=100}
    w:event("QUEST_COMPLETE");w:message(200,nil,997);w:event("QUEST_LOOT_RECEIVED",42,link(200),1)
    w:event("QUEST_TURNED_IN",42,100,500);w:tick(2);equal(A.Farm.Summary().total,0)
    A.DB.Settings().farmIncludeQuest=true;A.Farm.Pause(true);w:event("QUEST_TURNED_IN",43,100,500)
    w:event("QUEST_LOOT_RECEIVED",43,link(200),1);equal(A.Farm.Summary().total,0)
end)

test("new rate history starts at upgrade while existing session totals and observations survive",function()
    local w,A=world();A.Farm.AddMoney(100,false);A.Farm.AddMoney(10000,true);w:tick(300)
    w:body(1,{{link=link(100),sources={guid(),1}}});w:open();w:close()
    local current=A.Farm.Profile().current;current.metrics.schema=1;current.metrics.peak.rate=999999
    local _,B=world(A.DB.data,w.wall);local s=B.Farm.Summary()
    equal(s.total,10100);equal(s.elapsed,300);equal(s.peak.rate,0);equal(s.metricsSince,300)
    equal(B.Farm.Profile().current.metrics.schema,2);equal(select(2,B.Drops.Rows(1000)),1)
end)

test("session dropdown lists saved sessions and returns directly to the live session",function()
    local w,A=world()
    for i=1,3 do A.Farm.AddMoney(i*100,false);w:tick(60);truth(A.Farm.Reset())end
    A.Farm.AddMoney(99,false)
    local ui=A.FarmingUI;ui.Show("session");ui.sessionMenu:OpenMenu()
    equal(#ui.sessionMenu.menuDescription.items,4);truth(ui.sessionMenu:Pick(2));equal(ui.total.text,A.Util.Coins(200))
    equal(ui.pause.enabled,false);equal(ui.reset.enabled,false);equal(ui.currentButton.enabled,true)
    ui.itemsButton.scripts.OnClick();equal(ui.total.text,A.Util.Coins(200))
    ui.currentButton.scripts.OnClick();equal(ui.total.text,A.Util.Coins(99));equal(ui.historyIndex,0)
    equal(ui.pause.enabled,true);equal(ui.currentButton.enabled,false)
end)

test("saved-session selection survives a new history insertion and falls back if it is evicted",function()
    local w,A=world()
    for i=1,5 do A.Farm.AddMoney(i*100,false);w:tick(60);truth(A.Farm.Reset())end
    local ui=A.FarmingUI;ui.Show("session");ui.SelectSession(2);local selected=ui.historyRecord
    A.Farm.AddMoney(600,false);w:tick(60);truth(A.Farm.Reset());ui.Refresh()
    equal(ui.historyRecord,selected);equal(ui.historyIndex,3);equal(ui.total.text,A.Util.Coins(400))
    ui.SelectSession(5);A.Farm.AddMoney(700,false);w:tick(60);truth(A.Farm.Reset());ui.Refresh()
    equal(ui.historyRecord,nil);equal(ui.historyIndex,0);equal(ui.pause.enabled,true)
end)

test("opening the farming report again goes to current without losing archived sessions",function()
    local w,A=world();A.Farm.AddMoney(100,false);w:tick(60);A.Farm.Reset()
    local ui=A.FarmingUI;ui.Show("session");ui.SelectSession(1);ui.frame:Hide();ui.Show("session")
    equal(ui.historyIndex,0);equal(#A.Farm.Profile().history,1)
end)

test("invalid saved-session choices safely return to current without reporting success",function()
    local _,A=world();A.FarmingUI.Show("session")
    truth(A.FarmingUI.SelectSession(0));equal(A.FarmingUI.SelectSession(99),false)
    equal(A.FarmingUI.SelectSession(secret),false);equal(A.FarmingUI.historyRecord,nil)
end)

test("older archived rates are not replaced with live values or unverifiable peaks",function()
    local w,A=world();local profile=A.Farm.Profile()
    profile.history[1]={startedAt=w.wall-600,endedAt=w.wall,elapsed=60,total=10100,questCoins=10000,questValue=0,
        top={},coins=100,lootValue=0,harvestValue=0,peak={rate=999999},recentRate=606000,recentDuration=60}
    A.Farm.AddMoney(500,false);w:tick(60)
    local ui=A.FarmingUI;ui.Show("session");ui.SelectSession(1)
    equal(ui.total.text,A.Util.Coins(10100));equal(ui.rate.text,A.Util.Coins(6000).." / h")
    equal(ui.metricValues[4].text,"Not recorded");equal(ui.peakValue.text,"Not recorded")
end)

test("quest rate choices update live and archived hourly figures without changing session totals",function()
    local w,A=world();A.Farm.AddMoney(100,false);A.Farm.AddMoney(1000,true);w:tick(60)
    local ui=A.FarmingUI;ui.Show("settings");ui.questMenu:Pick("hourly")
    near(A.Farm.Summary().perHour,66000);near(A.Farm.Summary().recentRate,66000)
    ui.questMenu:Pick("session");near(A.Farm.Summary().perHour,6000);equal(A.Farm.Summary().total,1100)
    truth(A.Farm.Reset());ui.Show("session");ui.SelectSession(1);equal(ui.rate.text,A.Util.Coins(6000).." / h")
    ui.questMenu:Pick("hourly");equal(ui.rate.text,A.Util.Coins(66000).." / h")
    ui.questMenu:Pick("off");equal(A.DB.Settings().farmIncludeQuest,false);equal(A.Farm.Profile().history[1].total,1100)
end)

test("skinning loot overlays cannot append a second corpse block or escape the tooltip layout",function()
    local w,A=world();w.items[100]={vendor=50}
    A.Drops.Observe(guid(2),{{id=100,quantity=1,link=link(100)}},nil,"solo","loot")
    A.Drops.Observe(guid(2),{{id=100,quantity=1,link=link(100)}},nil,"solo","skinning")
    w:unitTooltip();equal(headers(),1)
    w:event("UNIT_SPELLCAST_SENT","player","Test creature","skin",8613)
    w.loot={{link=link(100),sources={guid(),1}}};w:open();w.guids.mouseover=nil
    w.unitTip(GameTooltip,GameTooltip.data);A.Drops.CheckTooltip()
    if os.getenv("V131_REPLAY")=="1" then print("TOOLTIP_REPLAY headers="..headers().." lines="..GameTooltip:NumLines().." layout="..GameTooltip.fitLines)end
    truth(headers()<=1);equal(GameTooltip:NumLines(),GameTooltip.fitLines);equal(headers(),0)
    for _=1,30 do w.unitTip(GameTooltip,GameTooltip.data);A.Drops.CheckTooltip()end
    equal(headers(),0)
    w:close();A.Drops.CheckTooltip();equal(headers(),1);equal(GameTooltip:NumLines(),GameTooltip.fitLines)
end)

test("tooltip source changes replace an owned section instead of appending to it",function()
    local w,A=world();w.items[100]={vendor=50}
    A.Drops.Observe(guid(2),{{id=100,quantity=1}},nil,"solo","loot")
    A.Drops.Observe(guid(2),{{id=100,quantity=1}},nil,"solo","skinning")
    w.dead.mouseover,w.dead.target=false,false;w:unitTooltip();equal(headers(),1)
    w.dead.mouseover,w.dead.target=true,true;w.unitTip(GameTooltip,GameTooltip.data);A.Drops.CheckTooltip()
    equal(headers(),1);equal(A.Drops.tip.kind,"skinning");equal(GameTooltip:NumLines(),GameTooltip.fitLines)
end)

test("an extra addon line and unavailable rebuild API cannot duplicate drop blocks",function()
    local w,A=world();w.items[100]={vendor=50}
    A.Drops.Observe(guid(2),{{id=100,quantity=1}});w:unitTooltip()
    GameTooltip:AddLine("Other addon");GameTooltip:Show();GameTooltip.RebuildFromTooltipInfo=nil
    A.Drops.tipDirty=true
    for _=1,30 do w.unitTip(GameTooltip,GameTooltip.data);A.Drops.CheckTooltip()end
    equal(headers(),1);equal(GameTooltip:NumLines(),GameTooltip.fitLines)
end)

test("a native tooltip rebuild with the same row count still gets exactly one fresh section",function()
    local w,A=world();w.items[100]={vendor=50}
    A.Drops.Observe(guid(2),{{id=100,quantity=1}});w:unitTooltip();local count=GameTooltip:NumLines()
    GameTooltip:ClearLines();for i=1,count do GameTooltip:AddLine("Native line "..i)end
    w.unitTip(GameTooltip,{type=2,guid=guid()});equal(headers(),1)
end)

test("hiding a tooltip with retained rows cannot append another section when shown again",function()
    local w,A=world();w.items[100]={vendor=50}
    A.Drops.Observe(guid(2),{{id=100,quantity=1}});w:unitTooltip();equal(headers(),1)
    GameTooltip:Hide();GameTooltip:Show();w.unitTip(GameTooltip,GameTooltip.data);A.Drops.CheckTooltip()
    equal(headers(),1);equal(GameTooltip:NumLines(),GameTooltip.fitLines)
    GameTooltip:Hide();GameTooltip:ClearLines();GameTooltip:AddLine("A different native unit")
    GameTooltip.data={type=2,guid=guid(3)};GameTooltip:Show();w.unitTip(GameTooltip,GameTooltip.data)
    equal(headers(),1)
end)

test("rate and empty-corpse choices persist while manual pauses stay manual",function()
    local w,A=world();A.DB.Settings().farmQuestInRate=true;A.Farm.Pause(true)
    w:open();w:close();local _,B=world(A.DB.data,w.wall)
    truth(B.DB.Settings().farmQuestInRate);truth(B.Farm.Summary().paused);equal(select(2,B.Drops.Rows(1000)),1)
end)
