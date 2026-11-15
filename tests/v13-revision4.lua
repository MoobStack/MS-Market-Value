local fresh,row,link,test,equal,near,truth,secret=...
local function world(saved)
    local w,A=fresh(saved)
    UnitName=function()return "Test creature"end
    C_Map={GetBestMapForUnit=function()return 10 end}
    GetInstanceInfo=function()return "Test zone","none",1,"Normal",5,false,false,0 end
    GetRealZoneText=function()return "Test zone"end
    Enum.TooltipDataType.Unit=2
    TooltipDataProcessor.AddTooltipPostCall=function(kind,callback)if kind==2 then w.unitTip=callback end end
    w:load();A.Farm.Tick();return w,A
end
local function scan(w,A,entries)
    local snapshot=A.DB.NewSnapshot(A.Util.MarketKey(),#entries,w.wall)
    for _,r in ipairs(entries)do A.DB.AddRow(snapshot,r.id,r.quantity or 1,r.buyout or 100,r.link or link(r.id),0,r.quality,r.name)end
    truth(A.DB.Commit(snapshot));return snapshot
end
local function analyze(A,view,force)
    A.Market.Ensure(view or "listed","return",force~=false)
    for _=1,10000 do if not A.Market.job then return end;A.Market.Tick()end
    error("analysis did not finish")
end
local function market(w,A)
    w:openAH();A.MarketUI.Show();A.MarketUI.view="listed";analyze(A);A.MarketUI.Refresh();return A.MarketUI
end
local function blue(label)
    local c=label.color;near(c[1],0);near(c[2],112/255);near(c[3],221/255)
end

test("new profiles idle after five minutes by default without limiting session length",function()
    local w,A=world();truth(A.DB.Settings().farmIdle);equal(A.DB.Settings().farmIdleMinutes,5)
    for _=1,13 do w:advance(299);A.Farm.AddMoney(1,false);A.Farm.Tick()end
    truth(A.Farm.Elapsed()>3600);equal(A.Farm.Summary().idlePaused,false)
    w:advance(301);A.Farm.Tick();truth(A.Farm.Summary().idlePaused)
end)

test("unmarked beta profiles adopt enabled idle pause and clamp the old upper limit",function()
    local _,A=world();local db=A.DB.data;db.settings.farmIdle=false;db.settings.farmIdleMinutes=1440
    local _,B=world(db);truth(B.DB.Settings().farmIdle);equal(B.DB.Settings().farmIdleMinutes,60)
end)

test("an explicit disabled idle preference survives reload",function()
    local w,A=world();truth(A.Farm.ConfigureIdle(false,60));local _,B=world(A.DB.data)
    equal(B.DB.Settings().farmIdle,false);equal(B.DB.Settings().farmIdleMinutes,60)
    equal(B.Farm.ConfigureIdle(true,61),false);equal(B.DB.Settings().farmIdle,false)
end)

test("the sixty-minute idle boundary counts once and still auto resumes",function()
    local w,A=world();truth(A.Farm.ConfigureIdle(true,60))
    w:advance(4000);A.Farm.Tick();near(A.Farm.Elapsed(),3600);truth(A.Farm.Summary().idlePaused)
    truth(A.Farm.AddMoney(100,false));w:advance(10);A.Farm.Tick();near(A.Farm.Elapsed(),3610)
end)

test("auction scans retain native rarity and full modifier names before hover",function()
    local w,A=world();local r=row(100,1,100,-5);r.name="Boots of the Owl";r.quality=3
    w.rows={r};truth(A.Scanner.Start());A.Scanner.OnResponse();w:drain()
    local p=A.DB.Snapshot().variants["100:-5"];equal(p.display[1],3);equal(p.display[2],"Boots of the Owl")
    equal(p.display,A.DB.Snapshot().prices[100].display)
    local ui=market(w,A);equal(ui.rows[1].labels[1].text,"Boots of the Owl");blue(ui.rows[1].labels[1]);equal(ui.hovered,nil)
end)

test("visible rows request missing item data without a hover or auction query",function()
    local w,A=world();scan(w,A,{{id=100,link="item:100:0:0:0:0:0:0:0"}})
    local ui=market(w,A);truth(w.loadRequests>0);local requests=w.loadRequests
    for _=1,30 do ui.Refresh()end
    equal(w.loadRequests,requests);equal(w.requests,0);equal(ui.hovered,nil)
    w.items[100]={quality=3,name="Rare boots"};w:event("GET_ITEM_INFO_RECEIVED",100,true);ui.Refresh()
    blue(ui.rows[1].labels[1]);equal(ui.rows[1].labels[1].text,"Rare boots")
end)

test("shared price metadata never gives a different modifier its name",function()
    local w,A=world();local s=A.DB.NewSnapshot(A.Util.MarketKey(),3,w.wall)
    A.DB.AddRow(s,100,1,100,link(100,-5),0,3)
    A.DB.AddRow(s,100,1,100,link(100,-6),0,3,"Boots of the Bear")
    equal(s.variants["100:-5"].display[2],nil);equal(s.variants["100:-6"].display[2],"Boots of the Bear")
    A.DB.AddRow(s,100,1,90,link(100,-5),0,3,"Boots of the Owl")
    equal(s.prices[100].display[2],"Boots of the Owl");equal(s.variants["100:-6"].display[2],"Boots of the Bear")
    equal(s.variants["100:-5"].display,s.prices[100].display)
end)

test("quick native rarity colors a row while the full item metadata is unavailable",function()
    local w,A=world();C_Item.GetItemQualityByID=function()return 3 end
    scan(w,A,{{id=100,link="item:100:0:0:0:0:0:0:0"}})
    local ui=market(w,A);blue(ui.rows[1].labels[1]);equal(ui.hovered,nil)
end)

test("native rarity supersedes an early generic link color when data arrives",function()
    local w,A=world();scan(w,A,{{id=100,link=link(100):gsub("cff1eff00","cffffffff")}})
    local ui=market(w,A);w.items[100]={quality=3};w:event("GET_ITEM_INFO_RECEIVED",100,true);ui.Refresh()
    blue(ui.rows[1].labels[1]);local r,g,b=A.Util.ItemColor(link(100),3);near(r,0);near(g,112/255);near(b,221/255)
end)

test("rarity menu permits multiple checked qualities and applies them together",function()
    local w,A=world();scan(w,A,{{id=100,quality=2},{id=101,quality=3},{id=102,quality=4}})
    local ui=market(w,A);ui.qualityMenu:OpenMenu();truth(ui.qualityMenu:Pick("all"));equal(ui.qualityDraft,0)
    truth(ui.qualityMenu:Pick(2));truth(ui.qualityMenu:Pick(3));equal(ui.qualityDraft,12)
    truth(ui.qualityMenu:IsMenuOpen());equal(A.DB.Settings().marketQuality,63)
    truth(ui.Apply());analyze(A);ui.Refresh();equal(A.DB.Settings().marketQuality,12);equal(#A.Market.rows,2)
    for _,r in ipairs(A.Market.rows)do truth(r.quality==2 or r.quality==3)end
    local _,B=world(A.DB.data);equal(B.DB.Settings().marketQuality,12)
end)

test("no selected rarities means no rows and All restores every quality",function()
    local w,A=world();scan(w,A,{{id=100,quality=0},{id=101,quality=1},{id=102,quality=3}})
    A.DB.Settings().marketQuality=0;analyze(A);equal(#A.Market.rows,0)
    A.DB.Settings().marketQuality=63;analyze(A);equal(#A.Market.rows,3)
    equal(A.Market.QualityAllowed(8,secret),false)
end)

test("rarity filtering runs before the five hundred result cap",function()
    local w,A=world();local entries={}
    for id=1,520 do entries[#entries+1]={id=id,quality=2}end
    entries[#entries+1]={id=10000,quality=3};scan(w,A,entries);A.DB.Settings().marketQuality=8
    analyze(A);equal(#A.Market.rows,1);equal(A.Market.rows[1].id,10000);equal(A.Market.eligible,1)
end)

test("a filtered row with unknown rarity reappears automatically when data loads",function()
    local w,A=world();scan(w,A,{{id=100,link="item:100:0:0:0:0:0:0:0"}});A.DB.Settings().marketQuality=8
    analyze(A);equal(#A.Market.rows,0);truth(A.Market.reason:find("loading",1,true));local ui=market(w,A)
    truth(w.loadRequests>0);local builds=A.Market.builds
    w.items[100]={quality=3};w:event("GET_ITEM_INFO_RECEIVED",100,true);analyze(A,"listed",false);ui.Refresh()
    equal(A.Market.builds,builds+1);equal(#A.Market.rows,1);blue(ui.rows[1].labels[1])
end)

test("one-day All items shows each of-the modifier while resale awaits precise history",function()
    local w,A=world();w.items[100]={name="Boots",quality=2,classID=4}
    local function modern(bonus,name)return "|cff1eff00|Hitem:100:0:0:0:0:0:0:0:40:0:0:0:1:" .. bonus .. "|h[" .. name .. "]|h|r"end
    local a,b=modern(5661,"Boots of the Owl"),modern(5662,"Boots of the Bear")
    scan(w,A,{{id=100,link=a,buyout=100},{id=100,link=b,buyout=200}})
    analyze(A,"deals");equal(#A.Market.rows,0);truth(A.Market.reason:find("3 earlier",1,true))
    A.DB.Settings().marketSearch="of the";analyze(A);equal(#A.Market.rows,2)
    local names={};for _,r in ipairs(A.Market.rows)do names[r.name]=r.current;equal(r.days,0);truth(r.needsHistory)end
    equal(names["Boots of the Owl"],100);equal(names["Boots of the Bear"],200)
end)

test("metadata refresh preserves the warning on legacy item-wide equipment",function()
    local w,A=world();w.items[100]={quality=3,classID=4};local snapshot=scan(w,A,{{id=100}})
    snapshot.variants={};snapshot.prices[100].link=nil;snapshot.variantFormat=nil
    local ui=market(w,A);truth(ui.rows[1].labels[1].text:find("item-wide",1,true))
    w:event("GET_ITEM_INFO_RECEIVED",100,true);ui.Refresh();truth(ui.rows[1].labels[1].text:find("item-wide",1,true))
end)

test("personal creature tooltip names use their green and blue item qualities",function()
    local w,A=world();w.items[100]={quality=2,name="Green item"};w.items[101]={quality=3,name="Blue item"}
    A.Drops.Observe("Creature-0-1-1-1-1000-1",{{id=100,quantity=1,link=link(100):gsub("Test","Green item")},
        {id=101,quantity=1,link=link(101):gsub("Test","Blue item")}})
    w.unitTip(GameTooltip,{type=2,guid="Creature-0-1-1-1-1000-2"})
    local colors={};for _,line in ipairs(GameTooltip.lines)do colors[line.left]=line.leftColor end
    near(colors["Green item"][1],30/255);near(colors["Green item"][2],1)
    near(colors["Blue item"][1],0);near(colors["Blue item"][2],112/255);near(colors["Blue item"][3],221/255)
end)

test("reference tooltip colors use native item quality without changing percentages",function()
    local w,A=world();w.items[100]={quality=3,name="Blue reference"};A.DB.Settings().dropMode="reference"
    A.LootReference.Register("Test reference",function()return {{id=100,rate=25,samples=40}}end,false)
    w.unitTip(GameTooltip,{type=2,guid="Creature-0-1-1-1-1000-2"})
    local line=GameTooltip.lines[3];equal(line.left,"Blue reference");near(line.leftColor[2],112/255);equal(line.right,"25.0% (40 samples)")
end)

test("main settings can first open toggle and stay open in combat",function()
    local w,A=world();A.auctionOpen=false;w.combat=true
    SlashCmdList.MSMARKETVALUE("");truth(A.UI.frame:IsShown());equal(A.UI.scanButton.enabled,false)
    w:event("PLAYER_REGEN_DISABLED");truth(A.UI.frame:IsShown());SlashCmdList.MSMARKETVALUE("");equal(A.UI.frame:IsShown(),false)
    SlashCmdList.MSMARKETVALUE("");truth(A.UI.frame:IsShown());equal(w.requests,0)
end)

test("combat opens a standalone view without changing the native AH display",function()
    local w,A=world();w:openAH();local native=AuctionHouseFrame.displayMode;w.combat=true;w:event("PLAYER_REGEN_DISABLED")
    A.UI.OpenSettings();truth(A.UI.frame:IsShown());equal(AuctionHouseFrame.displayMode,native)
    equal(A.UI.content:GetParent(),A.UI.frame);equal(w.requests,0)
end)

test("ledger farming and diagnostics open in combat and cached ledger filters work",function()
    local w,A=world();w.combat=true;SlashCmdList.MSMARKETVALUE("ledger");truth(A.EconomyUI.frame:IsShown())
    A.EconomyUI.SetFilter("buy");equal(A.EconomyUI.filterKind,"buy");A.EconomyUI.SetPeriod("7d");equal(A.EconomyUI.period,"7d")
    SlashCmdList.MSMARKETVALUE("farm");truth(A.FarmingUI.frame:IsShown())
    SlashCmdList.MSMARKETVALUE("diagnostics");truth(A.UI.diagnostics:IsShown());equal(A.Scanner.Start(),false);equal(w.requests,0)
end)

test("combat window focusing leaves a protected root untouched",function()
    local w,A=world();A.UI.OpenSettings();local frame=A.UI.frame;frame.IsProtected=function()return true end
    w.combat=true;frame.SetFrameLevel=function()error("protected root changed")end
    A.Util.FocusWindow(frame);equal(w.requests,0)
end)
