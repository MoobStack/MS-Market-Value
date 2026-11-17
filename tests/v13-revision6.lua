local fresh,row,link,test,equal,near,truth=...
local function world(saved,wall)
    local w,A=fresh(saved)
    w.wall=wall or w.wall
    UnitName=function()return "Test creature"end
    C_Map={GetBestMapForUnit=function()return 10 end}
    GetInstanceInfo=function()return "Test zone","none",1,"Normal",5,false,false,0 end
    GetRealZoneText=function()return "Test zone"end
    Enum.TooltipDataType.Unit=2
    w:load();A.Farm.Tick();return w,A
end
local function guid(id,spawn,object)return (object and "GameObject" or "Creature") .. "-0-1-1-1-" .. id .. "-" .. (spawn or 1)end
local function tick(w,A,seconds)w:advance(seconds);A.Farm.Tick();A.FarmingUI.Animate(.1)end
local function byID(rows)local found={};for _,r in ipairs(rows)do found[r.id]=r end;return found end
local function mode(A,index)
    local ui=A.FarmingUI;ui.Show("drops");ui.mode:OpenMenu();ui.mode.menuDescription.items[index].callback()
end

test("the bundled base is ready by default without decoding sources or seeding personal counts",function()
    local _,A=world();local R=A.LootReference
    equal(A.DB.Settings().dropMode,"reference");truth(A.DB.Settings().dropTracking)
    equal(R.label,"Everloot reference");truth(R.packed);equal(R.verified,false)
    equal(R.bundled.rates,1876);equal(R.bundled.sources,243)
    equal(#R.order,0);equal(R.cachedRows,0);equal(A.Drops.Profile().mobs,0);equal(A.Drops.Profile().cells,0)
end)

test("bundled herb rates work before a personal harvest and preserve their own denominators",function()
    local _,A=world();local rows,n=A.Drops.Rows(1617,"herbalism");local by=byID(rows)
    equal(n,0);equal(by[765].origin,"everloot");near(by[765].rate,100);equal(by[765].samples,40)
    near(by[268415].rate,2.5);equal(A.Drops.Profile().cells,0)
    GameTooltip:ClearLines();A.Drops.tip=nil
    A.Drops.Tooltip(GameTooltip,{type=2,guid=guid(1617,1,true),lines={{leftText="Silverleaf"}}})
    truth(#GameTooltip.lines>2)
end)

test("reference display continues collecting personal rates and fills only missing drops",function()
    local _,A=world()
    truth(A.Drops.Observe(guid(1617,1,true),{{id=765,quantity=2,link=link(765)},{id=99999,quantity=1,link=link(99999)}},nil,"solo","herbalism"))
    truth(A.Drops.Observe(guid(1617,2,true),{},nil,"solo","herbalism"))
    local rows,n=A.Drops.Rows(1617,"herbalism");local by=byID(rows)
    equal(n,2);equal(by[765].origin,"everloot");near(by[765].rate,100);equal(by[765].samples,40)
    equal(by[99999].origin,"personal");near(by[99999].rate,50);equal(by[99999].hits,1);equal(by[99999].samples,2)
    mode(A,1);equal(A.DB.Settings().dropMode,"observed");truth(A.DB.Settings().dropTracking)
    by=byID(A.Drops.Rows(1617,"herbalism"));near(by[765].rate,50);equal(by[765].samples,2);equal(by[268415],nil)
end)

test("personal display choice survives reload while the bundled data stays available",function()
    local _,A=world();mode(A,1)
    local _,B=world(A.DB.data);equal(B.DB.Settings().dropMode,"observed");truth(B.DB.Settings().dropTracking)
    truth(B.LootReference.query);mode(B,2);equal(B.DB.Settings().dropMode,"reference")
end)

test("the first bundled-data upgrade preserves personal counters and explicitly disabled tracking",function()
    local _,A=world();truth(A.Drops.Observe(guid(1000),{{id=100,quantity=1,link=link(100)}}))
    local saved=A.DB.data;saved.settings.dropMode="observed";saved.settings.dropModeConfigured=nil;saved.settings.dropTracking=false
    local _,B=world(saved);equal(B.DB.Settings().dropMode,"reference");equal(B.DB.Settings().dropTracking,false)
    equal(B.Drops.Profile().cells,1);equal(select(2,B.Drops.Rows(1000)),1)
end)

test("resetting personal data cannot erase or copy the bundled reference",function()
    local _,A=world();truth(A.Drops.Observe(guid(1000),{{id=100,quantity=1,link=link(100)}}))
    truth(A.Drops.Reset("all"));equal(A.Drops.Profile().cells,0)
    equal(#A.LootReference.Rows(1617,"herbalism"),2)
    equal(A.DB.data.reference,nil);equal(A.DB.data.lootReference,nil)
end)

test("farming display labels the hourly rate and session total separately by default",function()
    local w,A=world();tick(w,A,60);A.Farm.AddMoney(100,false);A.FarmingUI.Animate(.1)
    local ui=A.FarmingUI;truth(A.DB.Settings().farmShowTotal);truth(ui.hudTotal:IsShown());equal(ui.hud.height,56)
    equal(ui.hudRateLabel.text,"Average");truth(ui.hudRate.text:find(" / h",1,true))
    equal(ui.hudTotalLabel.text,"Session");equal(ui.hudTotal.text:find(" / h",1,true),nil)
    equal(A.Farm.Summary().total,100);truth(ui.displayTotal>0 and ui.displayTotal<100)
end)

test("idle appears beside one hourly rate and both figures remain frozen until own loot",function()
    local w,A=world();tick(w,A,60);A.Farm.AddMoney(100,false);tick(w,A,300)
    local ui=A.FarmingUI;truth(ui.hudRate.text:find("Idle",1,true));equal(ui.hudTotal.text:find("Idle",1,true),nil)
    local text,total,elapsed,rate=ui.hudRate.text,ui.hudTotal.text,A.Farm.Elapsed(),A.Farm.Summary().perHour
    tick(w,A,600);equal(ui.hudRate.text,text);equal(ui.hudTotal.text,total);near(A.Farm.Elapsed(),elapsed);near(ui.displayRate,rate)
    truth(A.Farm.AddMoney(25,false));ui.Animate(.1);equal(ui.hudRate.text:find("Idle",1,true),nil)
    tick(w,A,10);near(A.Farm.Elapsed(),elapsed+10);equal(A.Farm.Summary().total,125)
end)

test("hiding session value compacts the display without altering tracking and survives reload",function()
    local w,A=world();tick(w,A,60);truth(A.Farm.AddMoney(100,false))
    local ui=A.FarmingUI;ui.Show("settings");local box
    for _,b in ipairs(ui.checks)do if b.key=="farmShowTotal" then box=b end end
    truth(box);box:SetChecked(false);box.scripts.OnClick(box)
    equal(ui.hud.height,34);equal(ui.hudTotal:IsShown(),false);truth(ui.hud:IsShown());equal(A.Farm.Summary().total,100)
    local _,B=world(A.DB.data,w.wall);equal(B.DB.Settings().farmShowTotal,false);equal(B.FarmingUI.hud.height,34)
    equal(B.FarmingUI.hudTotal:IsShown(),false);equal(B.Farm.Summary().total,100)
    box:SetChecked(true);box.scripts.OnClick(box);equal(ui.hud.height,56);truth(ui.hudTotal:IsShown())
end)

test("manual pause has its own rate status and cannot be resumed by incoming loot",function()
    local w,A=world();tick(w,A,60);truth(A.Farm.AddMoney(100,false));A.Farm.Pause(true);A.FarmingUI.Animate(.1)
    truth(A.FarmingUI.hudRate.text:find("Paused",1,true));equal(A.FarmingUI.hudRate.text:find("Idle",1,true),nil)
    equal(A.Farm.AddMoney(100,false),false);tick(w,A,300);near(A.Farm.Elapsed(),60);equal(A.Farm.Summary().total,100)
end)

test("drop diagnostics identify the bundled snapshot and independent personal tracker",function()
    local _,A=world();local text=A.UI.DiagnosticsText()
    truth(text:find("Bundled reference: Everloot 2026-11-16; rates=1876; sources/modes=243;",1,true))
    truth(text:find("mode=reference; tracking=true",1,true));truth(text:find("Test revision: 3",1,true))
end)
