-- Personal-mode fixtures; bundled defaults are covered in v13-revision6.lua.
local fresh,row,link,test,equal,near,truth,secret=...
local function guid(id,spawn) return "Creature-0-1-1-1-" .. id .. "-" .. (spawn or 1) end
local function world(saved,wall)
    local w,A=fresh(saved);if wall then w.wall=wall end
    w.guids={player=w.guid,target=guid(1000),mouseover=guid(1000)}
    UnitGUID=function(unit)return w.guids[unit]end
    UnitName=function(unit)return unit=="player" and "Player" or "Test creature"end
    C_Map={GetBestMapForUnit=function()return 10 end}
    GetInstanceInfo=function()return "Test zone","none",1,"Normal",5,false,false,0 end
    GetRealZoneText=function()return "Test zone"end
    IsInGroup=function()return w.group~=nil end;IsInRaid=function()return w.group=="raid"end
    LOOT_ITEM_SELF="You receive loot: %s.";LOOT_ITEM_SELF_MULTIPLE="You receive loot: %sx%d."
    YOU_LOOT_MONEY="You loot %s";GOLD_AMOUNT="%d Gold";SILVER_AMOUNT="%d Silver";COPPER_AMOUNT="%d Copper"
    Enum.TooltipDataType.Unit=2
    TooltipDataProcessor.AddTooltipPostCall=function(kind,fn)if kind==2 then w.unitTip=fn end end
    GetNumLootItems=function()return #(w.loot or {})end
    GetLootSourceInfo=function(slot)return unpack(w.loot[slot].sources)end
    GetLootSlotLink=function(slot)return w.loot[slot].link end
    GetLootSlotInfo=function(slot)
        local r=w.loot[slot]
        return 1,"Item",1,0,1,false,r.questItem or false,r.questID,r.questID~=nil
    end
    w:load();if saved==nil then A.DB.Settings().dropMode="observed" end;A.Farm.Tick();return w,A
end
local function tick(w,A,seconds)w:advance(seconds);A.Farm.Tick()end
local function enable(A,minutes)truth(A.Farm.ConfigureIdle(true,minutes or 5))end
local function loot(w,id,quantity,line)
    w:event("CHAT_MSG_LOOT","You receive loot: " .. link(id) .. (quantity and ("x" .. quantity) or "") .. ".",nil,nil,nil,nil,nil,nil,nil,nil,nil,line)
end

test("idle pause is optional and validates whole minutes with a five-minute minimum",function()
    local w,A=world();equal(A.DB.Settings().farmIdle,true);equal(A.DB.Settings().farmIdleMinutes,5);truth(A.Farm.ConfigureIdle(false,5))
    tick(w,A,900);near(A.Farm.Elapsed(),900);equal(A.Farm.Summary().idlePaused,false)
    for _,n in ipairs({0,4,5.5,61,secret})do equal(A.Farm.ConfigureIdle(true,n),false)end
    enable(A,5);equal(A.DB.Settings().farmIdle,true);equal(A.Farm.ConfigureIdle(true,60),true)
end)

test("the complete idle grace period counts and the timer stops at its precise boundary",function()
    local w,A=world();enable(A)
    tick(w,A,299);near(A.Farm.Elapsed(),299);equal(A.Farm.Summary().idlePaused,false)
    tick(w,A,31);near(A.Farm.Elapsed(),300);truth(A.Farm.Summary().idlePaused);truth(A.Farm.Summary().paused)
    tick(w,A,600);near(A.Farm.Elapsed(),300)
end)

test("a delayed update cannot backfill a long idle gap before a loot event",function()
    local w,A=world();enable(A)
    w:advance(1200);w:event("CHAT_MSG_MONEY","You loot 1 Silver")
    near(A.Farm.Elapsed(),300);equal(A.Farm.Summary().idlePaused,false);equal(A.Farm.Summary().coins,100)
    tick(w,A,10);near(A.Farm.Elapsed(),310)
end)

test("own item loot resumes at receipt time and settlement does not reset the idle clock",function()
    local w,A=world();w.items[100]={vendor=10};enable(A);tick(w,A,600)
    loot(w,100,nil,77);equal(A.Farm.Summary().idlePaused,false)
    tick(w,A,1.1);equal(A.Farm.Summary().total,10);near(A.Farm.Profile().current.idleElapsed,1.1)
    tick(w,A,298.9);truth(A.Farm.Summary().idlePaused);near(A.Farm.Elapsed(),600)
end)

test("repeated duplicate loot messages cannot keep an idle session awake",function()
    local w,A=world();w.items[100]={vendor=10};enable(A);loot(w,100,nil,77);tick(w,A,300)
    truth(A.Farm.Summary().idlePaused);loot(w,100,nil,77);truth(A.Farm.Summary().idlePaused)
    equal(A.Farm.Summary().total,10)
end)

test("manual pauses never resume automatically on loot or quest rewards",function()
    local w,A=world();w.items[100]={vendor=10};enable(A);A.Farm.Pause(true)
    loot(w,100);w:event("CHAT_MSG_MONEY","You loot 2 Gold");w:event("QUEST_LOOT_RECEIVED",42,link(100),1)
    tick(w,A,600);equal(A.Farm.Summary().total,0);near(A.Farm.Elapsed(),0);truth(A.Farm.Profile().current.paused)
    A.Farm.Pause(false);tick(w,A,10);near(A.Farm.Elapsed(),10)
end)

test("disabling idle pause resumes its timer without changing a manual pause",function()
    local w,A=world();enable(A);tick(w,A,600)
    truth(A.Farm.ConfigureIdle(false,5));tick(w,A,10);near(A.Farm.Elapsed(),310)
    A.Farm.Pause(true);truth(A.Farm.ConfigureIdle(false,5));tick(w,A,60);near(A.Farm.Elapsed(),310)
end)

test("loot activity restarts the full grace period including unpriced pickups",function()
    local w,A=world();enable(A);tick(w,A,250);loot(w,999,nil,1);tick(w,A,250)
    equal(A.Farm.Summary().idlePaused,false);equal(A.Farm.Summary().unknown,1)
    tick(w,A,50);truth(A.Farm.Summary().idlePaused);near(A.Farm.Elapsed(),550)
end)

test("included quest rewards and harvested items resume an automatic pause",function()
    local w,A=world();w.items[100]={vendor=10};enable(A);tick(w,A,300)
    w:event("QUEST_TURNED_IN",42,500,100);equal(A.Farm.Summary().idlePaused,false)
    tick(w,A,300);truth(A.Farm.Summary().idlePaused)
    truth(A.Farm.AddItem(link(100),2,"herbalism"));equal(A.Farm.Summary().harvestValue,20)
    equal(A.Farm.Summary().idlePaused,false)
end)

test("mail trade wallet changes and other players' visible loot cannot resume farming",function()
    local w,A=world();enable(A);tick(w,A,300)
    w.loot={{link=link(100),sources={guid(1000),1}}};w.group="party";w:event("LOOT_READY")
    w:event("PLAYER_MONEY");truth(A.Farm.Summary().idlePaused)
    for _,events in ipairs({{"MAIL_SHOW","MAIL_CLOSED"},{"TRADE_SHOW","TRADE_CLOSED"}}) do
        w:event(events[1]);w:event("CHAT_MSG_MONEY","You loot 1 Gold");loot(w,100)
        w:event(events[2]);tick(w,A,2.1);truth(A.Farm.Summary().idlePaused)
    end
    equal(A.Farm.Summary().total,0)
end)

test("idle state survives reload and excludes offline and loading time",function()
    local w,A=world();enable(A);tick(w,A,200)
    w:event("PLAYER_LEAVING_WORLD");tick(w,A,600);w:event("PLAYER_ENTERING_WORLD");tick(w,A,100)
    near(A.Farm.Elapsed(),300);truth(A.Farm.Summary().idlePaused)
    w:event("PLAYER_LOGOUT")
    local w2,A2=world(A.DB.data,w.wall+86400);truth(A2.Farm.Summary().idlePaused);near(A2.Farm.Elapsed(),300)
    w2:event("CHAT_MSG_MONEY","You loot 1 Copper");tick(w2,A2,10);near(A2.Farm.Elapsed(),310)
end)

test("farming settings expose validated idle minutes and an idle status without clearing the session",function()
    local w,A=world();A.FarmingUI.Show("settings");local ui=A.FarmingUI
    ui.idleCheck:SetChecked(true);ui.idleCheck.scripts.OnClick(ui.idleCheck)
    ui.idleMinutes:SetText("4");ui.applyIdle.scripts.OnClick();equal(A.DB.Settings().farmIdleMinutes,5)
    ui.idleMinutes:SetText("8");ui.applyIdle.scripts.OnClick();equal(A.DB.Settings().farmIdleMinutes,8)
    tick(w,A,500);ui.Refresh();ui.Animate(.1);truth(ui.note.text:find("Idle",1,true));truth(ui.hudRate.text:find("Idle",1,true))
    ui.idleCheck:SetChecked(false);ui.idleCheck.scripts.OnClick(ui.idleCheck);equal(A.Farm.Summary().idlePaused,false)
end)

test("coin rendering uses native assets with exact denominations and omits zero components",function()
    local _,A=world();local U=A.Util
    local gold="|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:1:0|t"
    local silver="|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:1:0|t"
    local copper="|TInterface\\MoneyFrame\\UI-CopperIcon:12:12:1:0|t"
    equal(U.Coins(12345),"1" .. gold .. " 23" .. silver .. " 45" .. copper)
    equal(U.Coins(10000),"1" .. gold);equal(U.Coins(1200),"12" .. silver);equal(U.Coins(0),"0" .. copper)
    equal(U.Coins(.5),"<1" .. copper);equal(U.Coins(1.5),"2" .. copper)
    equal(U.Coins(9007199254740991),"900719925474" .. gold .. " 9" .. silver .. " 91" .. copper)
    equal(U.Coins(secret),"Unavailable");equal(U.Coins(-1),"Unavailable")
end)

test("quotes CSV diagnostics and numeric gold inputs stay free of texture tags",function()
    local _,A=world();local r={recipeID=1,name="Test recipe",quote=12345,service=true}
    equal(A.Crafting.QuoteText(r),"Test recipe - 1g 23s 45c ea")
    equal(A.Util.GoldText(12345),"1.2345");equal(A.Util.Money(12345),"1g 23s 45c")
    equal(A.UI.DiagnosticsText():find("|T",1,true),nil)
    truth(A.Ledger.Record({kind="sale",name="Test",quantity=1,amount=12345,cost=10000,fee=0}))
    equal(A.Ledger.CSV({}):find("|T",1,true),nil)
end)

test("opportunity item colors match the link including while selected",function()
    local w,A=world();w.items[100]={quality=3,classID=4}
    local blue=link(100):gsub("cff1eff00","cff0070dd")
    local s=A.DB.NewSnapshot(A.Util.MarketKey(),1,w.wall);A.DB.AddRow(s,100,1,100,blue,0);truth(A.DB.Commit(s))
    w:openAH();A.MarketUI.Show();A.MarketUI.view="listed";A.Market.Ensure("listed","return",true)
    for _=1,100 do A.Market.Tick() end
    A.MarketUI.Refresh();local ui=A.MarketUI;ui.selected=A.Market.rows[1];ui.Refresh()
    local color=ui.rows[1].labels[1].color;near(color[1],0);near(color[2],112/255);near(color[3],221/255)
    near(select(1,A.Util.ItemColor(secret,secret)),.90)
end)

test("quest-only drops are hidden when their quest is absent and return without losing samples",function()
    local w,A=world();w.items[100]={classID=12,bindType=4};w.items[101]={classID=7}
    local active=false;C_QuestLog={IsOnQuest=function(id)return active and id==42 end}
    A.Drops.Observe(guid(1000),{{id=100,quantity=1,link=link(100),questID=42,questItem=true},{id=101,quantity=1,link=link(101)}})
    local rows,n=A.Drops.Rows(1000);equal(#rows,1);equal(rows[1].id,101);equal(n,1)
    active=true;w:event("QUEST_LOG_UPDATE");rows,n=A.Drops.Rows(1000);equal(#rows,2);equal(rows[1].id,100);truth(rows[1].wanted)
    active=false;w:event("QUEST_LOG_UPDATE");equal(#A.Drops.Rows(1000),1);equal(A.Drops.Profile().cells,2)
end)

test("quest log text identifies active quest items when no quest ID is exposed",function()
    local w,A=world();w.items[100]={name="Quest token",classID=12}
    C_QuestLog={GetNumQuestLogEntries=function()return 1 end,GetInfo=function()return {questID=42} end,
        GetQuestObjectives=function()return {{type="item",text="Quest token: 0/5",finished=false}}end}
    A.Drops.Observe(guid(1000),{{id=100,quantity=1,link=link(100):gsub("Test","Quest token"),questItem=true}})
    local rows=A.Drops.Rows(1000);equal(#rows,1);truth(rows[1].wanted)
    C_QuestLog.GetNumQuestLogEntries=function()return 0 end;w:event("QUEST_LOG_UPDATE");equal(#A.Drops.Rows(1000),0)
end)

test("normal trade materials remain visible after an associated quest ends",function()
    local w,A=world();w.items[100]={classID=7};C_QuestLog={IsOnQuest=function()return false end}
    A.Drops.Observe(guid(1000),{{id=100,quantity=1,link=link(100),questID=42,questItem=true}})
    local rows=A.Drops.Rows(1000);equal(#rows,1);equal(rows[1].wanted,false)
end)

test("reference quest items obey the same active quest filter",function()
    local w,A=world();local active=false
    C_QuestLog={IsOnQuest=function()return active end};A.DB.Settings().dropMode="reference"
    A.LootReference.Register("Reference",function()return {{id=100,questID=42,questItem=true,rate=20}}end,false)
    equal(#A.Drops.Rows(1000),0);active=true;w:event("QUEST_LOG_UPDATE");equal(#A.Drops.Rows(1000),1)
end)

test("visible uncollected drops count once across partial looting reopening and reload",function()
    local w,A=world();w.items[100]={vendor=10};w.items[101]={vendor=20}
    w.loot={{link=link(100),sources={guid(1000),1}},{link=link(101),sources={guid(1000),1}}}
    w:event("LOOT_READY");w:event("LOOT_OPENED");equal(#A.Drops.Rows(1000),2);equal(A.Farm.Summary().total,0)
    loot(w,100);w.loot={{link=link(101),sources={guid(1000),1}}};w:event("LOOT_SLOT_CHANGED",1)
    w:event("LOOT_CLOSED");w:event("LOOT_OPENED");tick(w,A,1.1)
    equal(select(2,A.Drops.Rows(1000)),1);equal(A.Farm.Summary().total,10)
    local w2,A2=world(A.DB.data,w.wall+10);w2.loot=w.loot;w2:event("LOOT_READY")
    local rows,n=A2.Drops.Rows(1000);equal(n,1);equal(#rows,2);equal(rows[1].hits,1);equal(rows[2].hits,1)
end)

test("late quest metadata is captured without counting a drop again",function()
    local w,A=world();w.loot={{link=link(100),sources={guid(1000),1}}};w:event("LOOT_READY")
    w.loot[1].questID=42;w.loot[1].questItem=true;w:event("LOOT_OPENED")
    local bucket=A.Drops.Profile().areas[A.Drops.Context().key].mobs[1000].groups.solo
    equal(bucket.samples,1);equal(bucket.items[100].hits,1);equal(bucket.items[100].questID,42);truth(bucket.items[100].questItem)
end)

test("drop headers describe checked corpses without calling them kills or observed",function()
    local w,A=world();A.Drops.Observe(guid(1000),{{id=100,quantity=1,link=link(100)}})
    w.unitTip(GameTooltip,{type=2,guid=guid(1000)})
    equal(GameTooltip.lines[2].right,"1 corpse checked");equal(GameTooltip.lines[2].right:find("observed",1,true),nil)
end)

-- Fixed vectors from the external compiler, not a Lua encoder clone.
test("packed reference counts decode exact rare rates and quest flags",function()
    local _,A=world();local R=A.LootReference
    local rows=R.Decode("BgywekDBDqB")
    truth(rows);equal(#rows,1);equal(rows[1].id,100);equal(rows[1].samples,1000000)
    near(rows[1].rate,.0001);truth(rows[1].questItem);equal(rows[1].questID,42)
end)

test("malformed packed sources are rejected without partial data or excessive work",function()
    local _,A=world();local R=A.LootReference
    for _,code in ipairs({"","!","BkDkDZA!","BkDkDZ","AgB","gggggggggg","BkDAZA"})do equal(R.Decode(code),nil)end
    equal(R.Decode(secret),nil)
end)

test("packed reference sources decode only on demand with bounded cache rows",function()
    local _,A=world();local R=A.LootReference;local sources={loot={}}
    for id=1,100 do sources.loot[id]="BkDkDZA"end
    truth(R.RegisterPacked("Packed",sources));equal(#R.order,0);equal(R.cachedRows,0)
    for id=1,100 do local rows=R.Rows(id);equal(#rows,1);near(rows[1].rate,25)end
    equal(#R.order,8);equal(R.cachedRows,8);equal(R.cache[1],nil)
    equal(#R.Rows(1,"mining"),0);equal(A.Drops.Profile().mobs,0)
end)

test("decoded reference cache enforces its row budget as well as source count",function()
    local _,A=world();local R=A.LootReference;local sources={loot={}}
    local code="ggBkD" .. string.rep("BZA",1024)
    for id=1,10 do sources.loot[id]=code end
    truth(R.RegisterPacked("Large sources",sources))
    for id=1,10 do equal(#R.Rows(id),1024);truth(R.cachedRows<=4096) end
    equal(#R.order,4);equal(R.cachedRows,4096);equal(R.cache[1],nil)
end)

test("quest and item-data changes refresh owned tooltips without duplicate sections",function()
    local w,A=world();local active=true;w.items[100]={classID=12,name="Quest token"}
    C_QuestLog={IsOnQuest=function()return active end}
    A.Drops.Observe(guid(1000),{{id=100,quantity=1,link=link(100),questID=42,questItem=true}})
    GameTooltip.data={type=2,guid=guid(1000)};GameTooltip.info={getterName="GetUnit",getterArgs={"mouseover"}}
    GameTooltip:Show();A.Drops.CheckTooltip();equal(#GameTooltip.lines,3)
    function GameTooltip:RebuildFromTooltipInfo()self:ClearLines();A.Drops.Tooltip(self,self.data)end
    active=false;w:event("QUEST_LOG_UPDATE");A.Drops.CheckTooltip()
    equal(#GameTooltip.lines,3);equal(GameTooltip.lines[3].left,"Quest-only drops hidden; no current matches.")
    w:event("GET_ITEM_INFO_RECEIVED",100,true);w.combat=true;A.Drops.CheckTooltip();equal(#GameTooltip.lines,3)
    w.combat=false;GameTooltip.RebuildFromTooltipInfo=function()error("native refresh unavailable")end
    A.Drops.CheckTooltip();A.Drops.CheckTooltip();equal(#GameTooltip.lines,3)
end)

test("name lookups are throttled bounded and never become auction requests",function()
    local w,A=world();local before=w.loadRequests
    for _=1,20 do A.Drops.RequestName(100)end;equal(w.loadRequests-before,1)
    for id=101,140 do A.Drops.RequestName(id)end;equal(w.loadRequests-before,20)
    tick(w,A,10)
    for id=141,160 do A.Drops.RequestName(id)end;equal(w.loadRequests-before,40)
    for batch=1,8 do tick(w,A,10);for id=1000+batch*20,1019+batch*20 do A.Drops.RequestName(id)end end
    equal(#A.Drops.nameQueue,128);equal(w.requests,0)
end)
