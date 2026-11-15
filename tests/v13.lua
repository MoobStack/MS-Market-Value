local fresh, row, link, test, equal, near, truth, secret = ...
local function guid(npc,spawn) return "Creature-0-1-1-1-" .. npc .. "-" .. (spawn or "000001") end
local function world(saved,wall)
    local w,A=fresh(saved)
    w.wall=wall or w.wall
    w.guids={player=w.guid,target=guid(1000),mouseover=guid(1000)}
    UnitGUID=function(unit)return w.guids[unit]end
    UnitName=function(unit)return unit=="player" and "Player" or "Test creature"end
    C_Map={GetBestMapForUnit=function()return w.mapID or 10 end}
    GetInstanceInfo=function()return w.dungeon or "Test zone",w.dungeon and "party" or "none",1,"Normal",5,false,false,w.instanceID or 0 end
    GetRealZoneText=function()return w.zone or "Test zone"end
    IsInGroup=function()return w.group~=nil end;IsInRaid=function()return w.group=="raid"end
    LOOT_ITEM_SELF="You receive loot: %s."
    LOOT_ITEM_SELF_MULTIPLE="You receive loot: %sx%d."
    YOU_LOOT_MONEY="You loot %s";GOLD_AMOUNT="%d Gold";SILVER_AMOUNT="%d Silver";COPPER_AMOUNT="%d Copper"
    _G.Enum.TooltipDataType.Unit=2
    local itemCallback=w.tooltipCallback
    TooltipDataProcessor.AddTooltipPostCall=function(kind,callback)
        if kind==2 then w.unitTooltipCallback=callback else w.tooltipCallback=callback end
    end
    GetNumLootItems=function()return #(w.loot or {})end
    GetLootSlotLink=function(slot)return w.loot[slot].link end
    GetLootSlotInfo=function(slot)
        local entry=w.loot[slot]
        return 1,"Item",entry.quantity or 1,0,1,false,entry.questID~=nil,entry.questID,entry.questID~=nil
    end
    GetLootSourceInfo=function(slot)return unpack(w.loot[slot].sources)end
    w:load();A.Farm.Tick()
    return w,A
end
local function scan(w,A,rows)
    local snapshot=A.DB.NewSnapshot(A.Util.MarketKey(),#rows,w.wall)
    for _,entry in ipairs(rows)do A.DB.AddRow(snapshot,entry.id,entry.quantity,entry.buyout,entry.link,0)end
    truth(A.DB.Commit(snapshot));return snapshot
end
local function tick(w,A,seconds)w:advance(seconds);A.Farm.Tick()end
local function named(id,suffix,name)
    return link(id,suffix):gsub("%[Test%]","[" .. name .. "]")
end
local function history(w,A)
    for i=1,3 do scan(w,A,{row(100,1,1000,-5),row(100,1,1500,-6)});w:advance(86400)end
end
local function analyze(A)
    A.Market.Ensure("deals","profit",true)
    for i=1,1000 do if not A.Market.job then return end;A.Market.Tick()end
    error("analysis did not finish")
end

test("1.3 preserves full scanned modifier names links and lowest-price stack totals",function()
    local w,A=world();history(w,A)
    local a,b=named(100,-5,"Ancient Belt of the Owl"),named(100,-6,"Ancient Belt of Fiery Wrath")
    scan(w,A,{{id=100,quantity=10,buyout=5000,link=a},{id=100,quantity=15,buyout=7500,link=a},
        {id=100,quantity=4,buyout=2400,link=a},{id=100,quantity=1,buyout=700,link=b}})
    local price=A.DB.Snapshot().variants["100:-5"]
    equal(price.lowUnits,25);equal(price.units,29);equal(price.lowBuyout,12500);equal(price.lowAuctions,2)
    analyze(A);equal(#A.Market.rows,2)
    local rows={};for _,r in ipairs(A.Market.rows)do rows[r.suffix]=r end
    equal(A.Market.Name(rows[-5]),"Ancient Belt of the Owl");equal(rows[-5].link,a)
    equal(A.Market.Name(rows[-6]),"Ancient Belt of Fiery Wrath")
end)

test("opportunity quantity search and scarcity filters apply before the result cap",function()
    local w,A=world();history(w,A)
    local a=named(100,-5,"Ancient Belt of the Owl")
    scan(w,A,{{id=100,quantity=20,buyout=10000,link=a}})
    w:advance(901);scan(w,A,{{id=100,quantity=5,buyout=2000,link=a}})
    local s=A.DB.Settings()
    s.marketLowMin,s.marketLowMax,s.marketStockMax,s.marketStockDrop,s.marketSearch=4,5,5,75,"belt owl"
    analyze(A);equal(#A.Market.rows,1);near(A.Market.rows[1].stockMove,-75)
    s.marketSearch="fiery";analyze(A);equal(#A.Market.rows,0)
    s.marketSearch="";s.marketLowMax=4;analyze(A);equal(#A.Market.rows,0)
end)

test("supply history stores only one compact prior scan and old low quantities remain unknown",function()
    local w,A=world();history(w,A)
    local previous=A.DB.Snapshot()
    previous.variants["100:-5"].lowUnits=nil
    analyze(A)
    local s=A.DB.Settings();s.marketLowMin=1
    analyze(A);equal(#A.Market.rows,0)
    w:advance(901);local latest=scan(w,A,{row(100,2,1000,-5)})
    equal(latest.previousSupply.variants["100:-5"],1)
    equal(latest.previousSupply.previousSupply,nil)
    equal(latest.previousSupply.prices[100],2)
end)

test("drop reads deduplicate reopen events and count stack hits per observed corpse",function()
    local w,A=world();local g=guid(1000)
    w.loot={{link=link(100),quantity=3,sources={1,g,3}}}
    w:event("LOOT_READY");w:event("LOOT_OPENED");w:event("LOOT_SLOT_CHANGED",1)
    local rows,n=A.Drops.Rows(1000);equal(n,1);equal(rows[1].hits,1);equal(rows[1].rate,100)
    w.loot={{quantity=1,sources={1,guid(1000,"000002"),1}}}
    w:event("LOOT_READY");rows,n=A.Drops.Rows(1000);equal(n,2);equal(rows[1].rate,50)
end)

test("area loot attributes each source quantity and party raid cohorts without crediting player income",function()
    local w,A=world();w.group="party"
    w.loot={{link=link(100),quantity=4,sources={2,guid(1000),2,guid(1000,"000002"),2}}}
    w:event("LOOT_READY")
    local rows,n=A.Drops.Rows(1000);equal(n,2);equal(rows[1].hits,2)
    local profile=A.Drops.Profile()
    local bucket=profile.areas[A.Drops.Context().key].mobs[1000].groups.party
    equal(bucket.samples,2);equal(bucket.items[100].quantity,4)
    w.group="raid";w.loot={{link=link(100),sources={1,guid(1000,"000003"),1}}};w:event("LOOT_READY")
    rows,n=A.Drops.Rows(1000);equal(n,3)
    equal(A.Farm.Summary().total,0)
end)

test("quest drops outrank more valuable items and creature tooltips enforce the item limit",function()
    local w,A=world()
    C_QuestLog={IsOnQuest=function(id)return id==42 end}
    local one=named(100,0,"Quest token");local two=named(101,0,"Expensive drop")
    w.items[100]={name="Quest token",vendor=0};w.items[101]={name="Expensive drop",vendor=100000}
    w.loot={{link=one,sources={1,guid(1000),1},questID=42},{link=two,sources={1,guid(1000),1}}}
    w:event("LOOT_READY")
    local rows=A.Drops.Rows(1000);equal(rows[1].id,100);truth(rows[1].wanted)
    A.DB.Settings().dropRows=1
    local data={guid=guid(1000)}
    w.unitTooltipCallback(GameTooltip,data)
    equal(#GameTooltip.lines,4);truth(GameTooltip.lines[3].left:find("Quest",1,true))
    w.unitTooltipCallback(GameTooltip,data);equal(#GameTooltip.lines,4)
end)

test("drop resets are character and selected area specific",function()
    local w,A=world()
    A.Drops.Remember("target")
    truth(A.Drops.Observe(guid(1000),{{id=100,quantity=1,link=link(100)}}))
    w.mapID=11;truth(A.Drops.Observe(guid(1000,"000002"),{}))
    truth(A.Drops.Reset("zone"));equal(A.Drops.Profile().mobs,1)
    w.mapID=10;equal(select(2,A.Drops.Rows(1000)),1)
    truth(A.Drops.Reset("monster","test creature"));equal(A.Drops.Profile().mobs,0)
    w.combat=true;equal(A.Drops.Reset("all"),false)
end)

test("drop reset by dungeon removes all floors without affecting outdoor data",function()
    local w,A=world();A.Drops.Observe(guid(1000),{})
    w.dungeon,w.instanceID="Test dungeon",22
    A.Drops.Observe(guid(1000,"000002"),{})
    w.mapID=12;A.Drops.Observe(guid(1000,"000003"),{})
    truth(A.Drops.Reset("dungeon"));equal(A.Drops.Profile().mobs,1)
end)

test("unknown or restricted loot sources are skipped without guessing their NPC",function()
    local w,A=world()
    w.loot={{link=link(100),sources={1,secret,1}}};w:event("LOOT_READY")
    equal(A.Drops.Profile().mobs,0)
    w.loot={{link=secret,sources={1,guid(1000),secret}}};w:event("LOOT_READY")
    equal(A.Drops.Profile().mobs,0)
    equal(A.Drops.Observe("GameObject-0-1-1-1-1000-1",{}),false)
end)

test("reference mode stays separate from personal samples and validates external rows",function()
    local w,A=world();A.Drops.Observe(guid(1000),{{id=100,quantity=1,link=link(100)}})
    truth(A.LootReference.Register("Test reference",function(id)
        return {{id=100,rate=25},{id=101,rate=101},{id=secret,rate=5}}
    end,false))
    A.DB.Settings().dropMode="reference"
    local rows,n=A.Drops.Rows(1000);equal(rows[1].rate,25);equal(n,0);equal(#rows,1)
    A.DB.Settings().dropMode="observed";rows,n=A.Drops.Rows(1000);equal(rows[1].rate,100);equal(n,1)
end)

test("observations and farming sessions reload for the same character without counting offline time",function()
    local w,A=world();A.Drops.Observe(guid(1000),{})
    tick(w,A,60);A.Farm.AddMoney(100,false)
    local saved=A.DB.data
    local w2,A2=world(saved,w.wall+86400);w2.mono=0
    near(A2.Farm.Elapsed(),60);equal(select(2,A2.Drops.Rows(1000)),1);equal(A2.Farm.Summary().coins,100)
    w2.guids.player="Player-1-alt"
    equal(A2.Farm.Summary().total,0);equal(A2.Drops.Profile().mobs,0)
end)

test("farming applies the AH cut and vendor threshold inclusively using exact variants",function()
    local w,A=world();w.items[100]={name="Trade item",vendor=100}
    scan(w,A,{row(100,1,115)})
    equal(A.Farm.Price(link(100),"loot"),100)
    w:advance(901);scan(w,A,{row(100,1,116)})
    equal(A.Farm.Price(link(100),"loot"),110)
    equal(A.Farm.Price(link(100),"quest"),100)
    w:advance(25*3600);equal(A.Farm.Price(link(100),"loot"),100)
end)

test("unseen variants and missing item data cannot inflate farming estimates",function()
    local w,A=world();w.items[100]={vendor=10}
    scan(w,A,{row(100,1,10000,-7)})
    equal(A.Farm.Price(link(100,-8),"loot"),10)
    truth(A.Farm.AddItem(link(101),2,"loot"));equal(A.Farm.Summary().unknown,2);equal(A.Farm.Summary().total,0)
    w.items[101]={vendor=50};w:event("GET_ITEM_INFO_RECEIVED",101,true);equal(A.Farm.Summary().total,100)
end)

test("self loot chat counts acquired quantities once while party loot and purchases do not",function()
    local w,A=world();w.items[100]={name="Test item",vendor=10}
    A.Farm.LootMessage("You receive loot: " .. link(100) .. "x3.",77)
    A.Farm.LootMessage("You receive loot: " .. link(100) .. "x3.",77)
    A.Farm.LootMessage("Other receives loot: " .. link(100) .. ".",78)
    tick(w,A,1.1)
    equal(A.Farm.Summary().lootValue,30);equal(A.Farm.Summary().items[1].quantity,3)
    equal(#A.Ledger.Records(),0)
end)

test("quest reward receipts do not count again through generic loot chat",function()
    local w,A=world();w.items[100]={vendor=100}
    w:event("CHAT_MSG_LOOT","You receive loot: " .. link(100) .. ".")
    w:event("QUEST_LOOT_RECEIVED",42,link(100),1)
    w:event("QUEST_TURNED_IN",42,1000,500)
    tick(w,A,1.1)
    local sum=A.Farm.Summary();equal(sum.questValue,100);equal(sum.lootValue,0);equal(sum.questCoins,500);equal(sum.total,600)
end)

test("farming loot gold works independently of ledger collection",function()
    local w,A=world();A.DB.Settings().trackLoot=false
    w:event("CHAT_MSG_MONEY","You loot 2 Silver")
    equal(A.Farm.Summary().coins,200);equal(#A.Ledger.Records(),0)
end)

test("pauses session reset and bounded recent history preserve exact reports",function()
    local w,A=world()
    tick(w,A,60);A.Farm.AddMoney(100,false);near(A.Farm.Summary().perHour,6000)
    A.Farm.Pause(true);tick(w,A,300);equal(A.Farm.AddMoney(200,false),false);near(A.Farm.Elapsed(),60)
    A.Farm.Pause(false);tick(w,A,60);near(A.Farm.Summary().perHour,3000)
    for i=1,30 do A.Farm.AddMoney(1,false)end
    equal(#A.Farm.Summary().recent,20)
    truth(A.Farm.Reset());equal(A.Farm.Summary().total,0);equal(A.Farm.Profile().history[1].total,130)
    for i=1,7 do tick(w,A,60);A.Farm.AddMoney(1,false);truth(A.Farm.Reset())end
    equal(#A.Farm.Profile().history,5)
end)

test("farming HUD interpolates without changing accounting and hover mode stays mouse accessible",function()
    local w,A=world();tick(w,A,60);A.Farm.AddMoney(100,false)
    A.FarmingUI.Animate(.1)
    truth(A.FarmingUI.displayTotal>0 and A.FarmingUI.displayTotal<100)
    equal(A.Farm.Summary().total,100)
    A.DB.Settings().farmHover=true;A.FarmingUI.HUD();equal(A.FarmingUI.hud.alpha,0)
    A.FarmingUI.hud.scripts.OnEnter();equal(A.FarmingUI.hud.alpha,1)
    SlashCmdList.MSMARKETVALUE("drops");truth(A.FarmingUI.drops:IsShown())
    SlashCmdList.MSMARKETVALUE("farm");truth(A.FarmingUI.session:IsShown())
end)

test("live loot events never cause auction requests or automated game actions",function()
    local w,A=world();w.loot={{link=link(100),sources={1,guid(1000),1}}}
    for i=1,50 do w:event("LOOT_READY");A.Farm.Tick();A.FarmingUI.Animate(.1)end
    equal(w.requests,0);equal(select(2,A.Drops.Rows(1000)),1)
end)

test("disabling quest income excludes both reward events and their generic loot messages",function()
    local w,A=world();w.items[100]={vendor=10};A.DB.Settings().farmIncludeQuest=false
    w:event("QUEST_LOOT_RECEIVED",42,link(100),1)
    w:event("CHAT_MSG_LOOT","You receive loot: " .. link(100) .. ".")
    w:event("QUEST_TURNED_IN",42,1000,100)
    tick(w,A,1.1);equal(A.Farm.Summary().total,0);equal(A.Farm.Summary().unknown,0)
end)

test("unsupported farming and drop roots are preserved while other money tools work",function()
    local saved={schema=1,markets={},settings={},farming={schema=99},drops={schema=99}}
    local w,A=world(saved)
    equal(A.Farm.AddMoney(10,false),false);equal(A.Drops.Observe(guid(1000),{}),false)
    equal(saved.farming.schema,99);equal(saved.drops.schema,99)
    truth(A.Ledger.Record({kind="buy",name="Existing tool",quantity=1,amount=10}))
    equal(#A.Ledger.Records(),1)
end)

test("stock filters with unavailable prior scans never invent a scarcity signal",function()
    local w,A=world();history(w,A)
    local snapshot=scan(w,A,{row(100,1,500,-5)})
    snapshot.previousSupply=nil;A.DB.Settings().marketStockDrop=1
    analyze(A);equal(#A.Market.rows,0)
end)

test("the exact modifier search never falls back to a broad base item search",function()
    local w,A=world();history(w,A);w.items[100]={name="Ancient Belt",level=36,equipment=true}
    scan(w,A,{{id=100,quantity=1,buyout=500,link=named(100,-5,"Ancient Belt of the Owl")}})
    w:openAH();w:nativeSearch();A.MarketUI.Show();analyze(A)
    C_AuctionHouse.MakeItemKey=nil
    equal(A.MarketUI.OpenListings(A.Market.rows[1]),false);equal(w.browseSearches,0);equal(w.itemSearches,0)
end)

test("localized reordered loot messages and restricted identifiers stay safe",function()
    local w,A=world();w.items[100]={vendor=10}
    LOOT_ITEM_SELF_MULTIPLE="Received %2$d of %1$s."
    A.Farm.LootMessage("Received 3 of " .. link(100) .. ".",91)
    A.Farm.LootMessage(secret,92)
    tick(w,A,1.1);equal(A.Farm.Summary().lootValue,30)
    w.guids.player=secret;equal(A.Farm.AddMoney(10,false),false);equal(A.Drops.Profile(),nil)
end)

test("reference queries are cached and do not retain an unbounded creature index",function()
    local w,A=world();local calls=0
    A.LootReference.Register("Fixture",function(id)calls=calls+1;return {{id=100,rate=10}}end,false)
    local first=A.LootReference.Rows(1)
    equal(A.LootReference.Rows(1),first);equal(calls,1)
    for id=2,70 do A.LootReference.Rows(id)end
    equal(#A.LootReference.order,64);equal(A.LootReference.cache[1],nil)
    equal(w.requests,0)
end)

test("confirmed loot settles across a pause and is flushed before logout",function()
    local w,A=world();w.items[100]={vendor=10}
    A.Farm.LootMessage("You receive loot: " .. link(100) .. ".",77)
    A.Farm.Pause(true);tick(w,A,1.1);equal(A.Farm.Summary().lootValue,10)
    A.Farm.Pause(false);A.Farm.LootMessage("You receive loot: " .. link(100) .. ".",78)
    equal(A.Farm.Reset(),false)
    w:event("PLAYER_LOGOUT");equal(A.Farm.Summary().lootValue,20);equal(#A.Farm.pending,0)
end)

test("a corpse reopened after reload is not a new drop sample",function()
    local w,A=world()
    A.Drops.Observe(guid(1000),{{id=100,quantity=2,link=link(100)}})
    local saved=A.DB.data
    local w2,A2=world(saved,w.wall+30)
    A2.Drops.Observe(guid(1000),{{id=100,quantity=2,link=link(100)}})
    local rows,n=A2.Drops.Rows(1000);equal(n,1);equal(rows[1].hits,1)
    equal(#A2.Drops.Profile().recent,1)
end)

test("resetting one creature preserves another creature's duplicate protection",function()
    local w,A=world()
    A.Drops.Observe(guid(1000),{})
    A.Drops.Observe(guid(1001),{{id=100,quantity=1,link=link(100)}})
    truth(A.Drops.Reset("monster","1000"))
    A.Drops.Observe(guid(1001),{{id=100,quantity=1,link=link(100)}})
    equal(select(2,A.Drops.Rows(1001)),1);equal(A.Drops.Profile().mobs,1)
end)

if os.getenv("MSMV_BENCHMARK")=="1" then
    local w,A=world()
    collectgarbage("collect")
    local before=collectgarbage("count")
    local start=os.clock()
    for npc=1,200 do
        local items={};for item=1,64 do items[item]={id=item,quantity=1,link=link(item)}end
        truth(A.Drops.Observe(guid(npc,"000001"),items))
    end
    for spawn=2,2600 do truth(A.Drops.Observe(guid(1,string.format("%06d",spawn)),{}))end
    for item=1,501 do
        w.items[10000+item]={vendor=1}
        local ok=A.Farm.AddItem(link(10000+item),1,"loot")
        equal(ok,item<=500)
    end
    for i=1,1000 do A.Farm.AddMoney(1,false)end
    equal(#A.Drops.ring,2048);equal(A.Drops.Profile().cells,12800)
    equal(A.Farm.Profile().current.itemTypes,500);equal(#A.Farm.Summary().recent,20)
    collectgarbage("collect")
    local added=collectgarbage("count")-before
    truth(added<16384,"new tracking state exceeds the 16 MiB synthetic memory budget")
    local cached=A.Farm.Summary()
    for i=1,100 do equal(A.Farm.Summary(),cached)end
    equal(w.requests,0)
    print(string.format("TRACKING_BENCHMARK npcs=200 item_counters=12800 receipts=2600 source_ring=%d session_types=500 retained_lua_kib=%.0f cpu_ms=%.2f requests=0",
        #A.Drops.ring,added,(os.clock()-start)*1000))
end
