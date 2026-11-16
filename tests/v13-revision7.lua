local fresh,row,link,test,equal,near,truth,secret=...
local function world(saved,wall)
    local w,A=fresh(saved);w.wall=wall or w.wall
    GetRealZoneText=function()return "Riverglades"end
    C_Map={GetBestMapForUnit=function()return 10 end,
        GetPlayerMapPosition=function()return {GetXY=function()return .432,.609 end}end}
    w:load();A.Farm.Tick();return w,A
end
local function tick(w,A,n) w:advance(n);A.Farm.Tick() end
local function byID(rows)local result={};for _,v in ipairs(rows)do result[v.id]=v end;return result end

test("Classic fills the missing Elder Mottled Boar without inventing samples",function()
    local _,A=world();local R=A.LootReference
    equal(R.classic.npcs,4395);equal(R.classic.lootNPCs,4289);equal(R.classic.skinningNPCs,924)
    equal(R.classic.verified,false);equal(#R.order,0)
    local rows=byID(R.Rows(3100,"loot"))
    truth(rows[769]);near(rows[769].rate,82.3572);equal(rows[769].samples,nil);equal(rows[769].origin,"classic")
    rows=byID(R.Rows(3100,"skinning"));near(rows[2318].rate,40.3871);near(rows[2934].rate,59.6129)
    equal(A.Drops.Profile().cells,0);equal(A.DB.data.reference,nil)
end)

test("Forever overrides matching Classic rows and personal data fills the final gap",function()
    local _,A=world();local R=A.LootReference
    R.Register("Forever fixture",function(id)return id==3100 and {{id=769,rate=25,samples=20}}end,false,"everloot")
    truth(A.Drops.Observe("Creature-0-1-1-1-3100-1",{{id=999999,quantity=1,link=link(999999)}}))
    local rows=byID(A.Drops.Rows(3100))
    near(rows[769].rate,25);equal(rows[769].samples,20);equal(rows[769].origin,"everloot")
    truth(rows[771]);equal(rows[771].origin,"classic");equal(rows[999999].origin,"personal")
    A.DB.Settings().dropMode="observed";A.Drops.cache=nil
    rows=byID(A.Drops.Rows(3100));equal(rows[769],nil);truth(rows[999999])
end)

test("curated packed input rejects corruption without returning partial tables",function()
    local _,A=world();local R=A.LootReference
    for _,code in ipairs({"", "!", "BA", "BB!", "CCAC", "BBBBBBBBBBBBBBBBBBBBBBBBB"})do equal(R.DecodeCurated(code,{}),nil)end
    equal(R.DecodeCurated(secret,{}),nil)
end)

test("combat resumes automatic idle and stays active through a slow fight",function()
    local w,A=world();tick(w,A,300);truth(A.Farm.Summary().idlePaused)
    tick(w,A,600);near(A.Farm.Elapsed(),300)
    w.combat=true;w:event("PLAYER_REGEN_DISABLED");equal(A.Farm.Summary().idlePaused,false)
    tick(w,A,700);near(A.Farm.Elapsed(),1000);equal(A.Farm.Summary().idlePaused,false)
    w.combat=false;w:event("PLAYER_REGEN_ENABLED")
    tick(w,A,299);near(A.Farm.Elapsed(),1299);equal(A.Farm.Summary().idlePaused,false)
    tick(w,A,2);near(A.Farm.Elapsed(),1300);truth(A.Farm.Summary().idlePaused)
end)

test("combat restarts the inactivity grace period but never resumes a manual pause",function()
    local w,A=world();tick(w,A,290);w.combat=true;w:event("PLAYER_REGEN_DISABLED")
    tick(w,A,50);w.combat=false;w:event("PLAYER_REGEN_ENABLED");tick(w,A,299)
    equal(A.Farm.Summary().idlePaused,false);near(A.Farm.Elapsed(),639)
    A.Farm.Pause(true);w.combat=true;w:event("PLAYER_REGEN_DISABLED");tick(w,A,600)
    near(A.Farm.Elapsed(),639);truth(A.Farm.Profile().current.paused)
    w.combat=false;w:event("PLAYER_REGEN_ENABLED");truth(A.Farm.Summary().paused)
end)

test("five complete minutes establish a located peak and quest spikes cannot raise it",function()
    local w,A=world();A.Farm.ConfigureIdle(false,5)
    for i=1,5 do truth(A.Farm.AddMoney(100,false));tick(w,A,60) end
    local s=A.Farm.Summary();near(s.perHour,6000);near(s.recentRate,6000);near(s.peak.rate,6000)
    equal(s.peak.location.zone,"Riverglades");near(s.peak.location.x,43.2);near(s.peak.location.y,60.9)
    equal(s.peak.location.time,w.wall-60)
    truth(A.Farm.AddMoney(1000000,true));tick(w,A,300)
    s=A.Farm.Summary();near(s.peak.rate,6000);truth(s.perHour>6000);truth(s.recentRate>6000)
end)

test("an early receipt cannot set a peak until a five-minute window completes",function()
    local w,A=world();A.Farm.ConfigureIdle(false,5);truth(A.Farm.AddMoney(500,false))
    tick(w,A,299);near(A.Farm.Summary().peak.rate,0)
    tick(w,A,1);near(A.Farm.Summary().peak.rate,6000)
end)

test("a long delayed tick still evaluates the earlier completed peak window",function()
    local w,A=world();A.Farm.ConfigureIdle(false,5);A.Farm.AddMoney(100,false)
    tick(w,A,10000);near(A.Farm.Summary().peak.rate,1200);near(A.Farm.Summary().recentRate,0)
end)

test("invalid saved minute history is preserved rather than used as income",function()
    local w,A=world();local saved=A.DB.data;local session=A.Farm.Profile().current
    session.metrics.buckets[999]={total=100,farm=100}
    local _,B=world(saved,w.wall);equal(B.Farm.Profile(),nil);truth(B.Farm.reason:find("preserved",1,true))
    equal(session.metrics.buckets[999].total,100)
end)

test("logging in during combat resumes automatic idle without charging offline time",function()
    local w,A=world();tick(w,A,300);truth(A.Farm.Summary().idlePaused)
    local w2,B=fresh(A.DB.data);w2.wall=w.wall+5000;w2.combat=true;w2:load();B.Farm.Tick()
    equal(B.Farm.Summary().idlePaused,false);near(B.Farm.Elapsed(),300)
    tick(w2,B,60);near(B.Farm.Elapsed(),360)
end)

test("recent income expires while whole-session income remains and rate history is bounded",function()
    local w,A=world();A.Farm.ConfigureIdle(false,5);A.Farm.AddMoney(100,false)
    tick(w,A,60);near(A.Farm.Summary().recentRate,6000)
    tick(w,A,3600);near(A.Farm.Summary().recentRate,0);truth(A.Farm.Summary().perHour>0)
    for i=1,200 do A.Farm.AddMoney(1,false);tick(w,A,60) end
    local count=0;for _ in pairs(A.Farm.Profile().current.metrics.buckets)do count=count+1 end
    truth(count<=61);equal(#A.Farm.Profile().current.recent,20)
end)

test("late price changes revalue the session without manufacturing a historical peak",function()
    local w,A=world();A.Farm.ConfigureIdle(false,5);w.items[100]={vendor=10}
    truth(A.Farm.AddItem(link(100),1,"loot"));tick(w,A,300);near(A.Farm.Summary().peak.rate,120)
    w.items[100].vendor=10000;w:event("GET_ITEM_INFO_RECEIVED",100,true)
    near(A.Farm.Summary().total,10000);near(A.Farm.Summary().peak.rate,120);near(A.Farm.Summary().recentRate,120)
end)

test("unpriced pickups do not become invented recent income and report their omission",function()
    local w,A=world();A.Farm.ConfigureIdle(false,5)
    truth(A.Farm.AddItem(link(999),1,"loot"));tick(w,A,300)
    local s=A.Farm.Summary();equal(s.metricMissing,1);near(s.peak.rate,0);near(s.recentRate,0)
    w.items[999]={vendor=100};w:event("GET_ITEM_INFO_RECEIVED",999,true)
    equal(A.Farm.Summary().total,100);near(A.Farm.Summary().peak.rate,0)
end)

test("upgrades preserve old session totals and start recent coverage at the actual upgrade",function()
    local w,A=world();A.Farm.ConfigureIdle(false,5);A.Farm.AddMoney(100,false);tick(w,A,120)
    local session=A.Farm.Profile().current;session.metrics=nil
    local _,B=world(A.DB.data,w.wall);local s=B.Farm.Summary()
    equal(s.total,100);near(s.elapsed,120);near(s.metricsSince,120);near(s.recentRate,0);near(s.peak.rate,0)
end)

test("reload retains the bounded rate history and saved sessions retain their own peak",function()
    local w,A=world();A.Farm.ConfigureIdle(false,5);A.Farm.AddMoney(100,false);tick(w,A,300)
    local w2,B=world(A.DB.data,w.wall);near(B.Farm.Summary().peak.rate,1200)
    truth(B.Farm.Reset());near(B.Farm.Summary().peak.rate,0)
    B.FarmingUI.Show("session");local ui=B.FarmingUI;ui.historyButton.scripts.OnClick()
    truth(ui.sessionTitle.text:find("Saved session",1,true));equal(ui.total.text,B.Util.Coins(100));equal(ui.pause.enabled,false)
    truth(ui.peakLocation.text:find("Riverglades",1,true));truth(ui.peakLocation.text:find("43.2, 60.9",1,true))
    ui.itemsButton.scripts.OnClick();equal(ui.pause.enabled,true);equal(ui.total.text,B.Util.Coins(0))
end)

test("HUD columns form one centered group with spacing and a saved adjustable width",function()
    local w,A=world();local ui=A.FarmingUI;ui.Show("settings")
    equal(ui.hudContent.points[1][1],"CENTER");equal(ui.hudRateLabel.justifyH,"RIGHT");equal(ui.hudRate.justifyH,"LEFT")
    local labelWidth=ui.hudRateLabel.width;equal(ui.hudRate.points[1][4],labelWidth+18)
    truth(ui.hudContent.width<=ui.hud.width-28)
    ui.hudWidth:SetText("420");ui.applyWidth.scripts.OnClick();equal(ui.hud.width,420)
    for _,v in ipairs({"239","521","300.5","no"})do ui.hudWidth:SetText(v);ui.applyWidth.scripts.OnClick();equal(ui.hud.width,420)end
    local _,B=world(A.DB.data,w.wall);equal(B.FarmingUI.hud.width,420)
end)

test("locking the HUD prevents dragging while retaining click actions and resizing",function()
    local _,A=world();local ui=A.FarmingUI;ui.Show("settings")
    local lock;for _,box in ipairs(ui.checks)do if box.key=="farmHUDLocked"then lock=box end end
    truth(lock);lock:SetChecked(true);lock.scripts.OnClick(lock)
    ui.hud.scripts.OnDragStart(ui.hud);equal(ui.hud.dragging,nil);equal(ui.hud.moving,nil)
    ui.hud.scripts.OnClick(ui.hud,"RightButton");truth(A.Farm.Profile().current.paused)
    ui.hudWidth:SetText("400");ui.applyWidth.scripts.OnClick();equal(ui.hud.width,400)
    lock:SetChecked(false);lock.scripts.OnClick(lock);ui.hud.scripts.OnDragStart(ui.hud);truth(ui.hud.moving)
    ui.hud.scripts.OnDragStop(ui.hud);equal(ui.hud.moving,false);truth(A.DB.data.farmHUD)
end)

test("session summary uses neutral text and keeps the item list inside the report",function()
    local _,A=world();local ui=A.FarmingUI;ui.Show("session")
    equal(ui.frame.width,760);equal(ui.frame.height,620);equal(#ui.metricValues,4)
    for _,font in ipairs({ui.rate,ui.total,ui.sessionTitle})do equal(font.color,nil) end
    truth(ui.rateNote.color[1]<.7);truth(ui.lines[7].points[1][5]+ui.lines[7].height<0)
    truth(-ui.lines[7].points[1][5]+ui.lines[7].height < -ui.prev.points[1][5])
end)
