-- Personal-mode fixtures; bundled defaults are covered in v13-revision6.lua.
local function coin(amount) return _G.MSMarketValue.Util.Coins(amount) end
local fresh,row,link,test,equal,near,truth,secret=...
local function guid(id,spawn,kind) return (kind or "Creature") .. "-0-1-1-1-" .. id .. "-" .. (spawn or "1") end
local function modern(id,bonuses,name)
    return "|cff1eff00|Hitem:" .. id .. ":0:0:0:0:0:0:234:40:0:0:0:" .. #bonuses ..
        (#bonuses>0 and (":" .. table.concat(bonuses,":")) or "") .. "|h[" .. (name or "Modified item") .. "]|h|r"
end
local function world(saved)
    local w,A=fresh(saved)
    w.guids={player=w.guid,target=guid(1000),mouseover=guid(1000)}
    UnitGUID=function(unit)return w.guids[unit]end
    UnitName=function(unit)return unit=="player" and "Player" or "Test creature"end
    UnitIsDead=function()return w.dead or false end
    C_Map={GetBestMapForUnit=function()return 10 end}
    GetInstanceInfo=function()return "Test zone","none",1,"Normal",5,false,false,0 end
    GetRealZoneText=function()return "Test zone"end
    IsInGroup=function()return false end;IsInRaid=function()return false end
    LOOT_ITEM_SELF="You receive loot: %s.";LOOT_ITEM_SELF_MULTIPLE="You receive loot: %sx%d."
    YOU_LOOT_MONEY="You loot %s";GOLD_AMOUNT="%d Gold";SILVER_AMOUNT="%d Silver";COPPER_AMOUNT="%d Copper"
    Enum.TooltipDataType.Unit=2
    TooltipDataProcessor.AddTooltipPostCall=function(kind,fn) if kind==2 then w.unitTip=fn end end
    GetNumLootItems=function()return #(w.loot or {})end
    GetLootSourceInfo=function(slot)return unpack(w.loot[slot].sources)end
    GetLootSlotLink=function(slot)return w.loot[slot].link end
    GetLootSlotInfo=function()return 1,"Item",1,0,1,false,false,nil,false end
    w:load();if saved==nil then A.DB.Settings().dropMode="observed" end;A.Farm.Tick();return w,A
end
local function scan(w,A,entries)
    local s=A.DB.NewSnapshot(A.Util.MarketKey(),#entries,w.wall)
    for _,r in ipairs(entries) do A.DB.AddRow(s,r.id,r.quantity,r.buyout,r.link,0) end
    truth(A.DB.Commit(s));return s
end
local function analyze(A,view)
    A.Market.Ensure(view or "deals","return",true)
    for i=1,10000 do if not A.Market.job then return end;A.Market.Tick() end
    error("analysis did not finish")
end
local function market()
    local w,A=world();w.items[15166]={name="Imposing Gloves",classID=4,quality=2,level=45,equipment=true}
    local a,b=modern(15166,{5661},"Imposing Gloves of Agility"),modern(15166,{5662},"Imposing Gloves of Defense")
    for day=1,4 do
        scan(w,A,{{id=15166,quantity=2,buyout=day==4 and 1000 or 2000,link=a},
            {id=15166,quantity=3,buyout=6000,link=b}})
        if day<4 then w:advance(86400) end
    end
    return w,A,a,b
end

test("modern bonus signatures are canonical and exclude player applied changes",function()
    local _,A=world();local U=A.Util
    equal(U.VariantKey(modern(15166,{5662,5661,5661})),"15166:0:b5661,5662")
    local id,suffix,bonus=U.SplitVariant("15166:0:b5661,5662");equal(id,15166);equal(suffix,0);truth(bonus)
    equal(U.VariantKey(modern(15166,{5661}):gsub(":0:0:0:0:0:0:234",":123:1:2:3:4:0:999")),"15166:0:b5661")
    for _,key in ipairs({"15166:0:b2,1","15166:0:b1,,2","15166:0:b1,","015166:0:b1"}) do equal(U.SplitVariant(key),nil) end
    equal(U.VariantKey("item:15166:0:0:0:0:0:0:0:40:0:0:0:bad"),nil)
    equal(U.VariantKey(modern(15166,{5661}):gsub(":1:5661",":2:5661")),nil)
    equal(U.VariantKey(secret),nil)
end)

test("each modern modifier keeps its own current history stock and movement",function()
    local w,A,a,b=market();analyze(A)
    equal(#A.Market.rows,1);local r=A.Market.rows[1]
    equal(r.variantKey,"15166:0:b5661");equal(r.name,"Imposing Gloves of Agility")
    equal(r.current,500);equal(r.baseline,1000);near(r.movement,-50)
    equal(r.lowUnits,2);equal(r.lowBuyout,1000);equal(r.units,2)
    analyze(A,"listed");equal(#A.Market.rows,2)
    local values={};for _,entry in ipairs(A.Market.rows) do values[entry.variantKey]=entry.current end
    equal(values["15166:0:b5662"],2000);equal(A.DB.Price(15166,a).low,500);equal(A.DB.Price(15166,b).low,2000)
    equal(w.requests,0)
end)

test("legacy suffix-zero history is never used as a precise equipment baseline",function()
    local w,A=world();w.items[15166]={classID=4,quality=2}
    for day=1,3 do
        scan(w,A,{{id=15166,quantity=1,buyout=1000,link=link(15166)}})
        for _,record in pairs(A.History.Days(A.Util.MarketInfo())) do record.variantFormat=nil end
        w:advance(86400)
    end
    scan(w,A,{{id=15166,quantity=1,buyout=100,link=link(15166)}})
    analyze(A);equal(#A.Market.rows,0)
    analyze(A,"listed");equal(#A.Market.rows,1);equal(A.Market.rows[1].days,0);truth(A.Market.rows[1].needsHistory)
    truth(A.Watchlist.Save(link(15166),0,20,1));A.Watchlist.Ensure();A.Watchlist.Tick()
    equal(A.Watchlist.rows[1].profit,nil);equal(A.Watchlist.rows[1].days,0)
end)

test("old item-wide equipment is labeled and cannot open misleading precise listings",function()
    local w,A=market();local snapshot=A.DB.Snapshot()
    snapshot.variantFormat=nil;snapshot.variants={};snapshot.prices[15166].link=nil
    w:openAH();w:nativeSearch();analyze(A,"listed");A.MarketUI.Show();analyze(A,"listed")
    local r=A.Market.rows[1];truth(r.itemWide);truth(r.name:find("item%-wide"));equal(r.movement,nil)
    equal(A.MarketUI.OpenListings(r),false);equal(w.itemSearches,0);equal(w.browseSearches,0)
end)

test("exact bonus watches persist and edit independently including Buy-page additions",function()
    local w,A,a,b=market()
    truth(A.Watchlist.Save(a,600,0,0));truth(A.Watchlist.Save(b,1900,0,0))
    A.Watchlist.Ensure();A.Watchlist.Tick();equal(#A.Watchlist.rows,2)
    local by={};for _,r in ipairs(A.Watchlist.rows)do by[r.variantKey]=r end
    truth(by["15166:0:b5661"].matched);equal(by["15166:0:b5662"].matched,false)
    A.EconomyUI.WatchDraft(by["15166:0:b5662"]);equal(A.EconomyUI.watchInputs.itemPrice:GetText(),"0.19")
    w:openAH();w:nativeSearch()
    local native=AuctionHouseFrame.ItemBuyFrame;native.itemKey={itemID=15166,itemSuffix=9001}
    C_AuctionHouse.GetItemKeySampleLink=function()return a end
    A.EconomyUI.WatchFromBuy(native,false)
    equal(A.EconomyUI.watchInputs.item:GetText(),a);equal(A.EconomyUI.watchInputs.itemPrice:GetText(),"0.06")
    local w2,A2=world(A.DB.data);equal(#A2.Watchlist.Entries(),2);equal(w2.requests,0)
end)

test("bonus navigation resolves a matching native sample rather than inventing a suffix key",function()
    local w,A,a,b=market();w:openAH();w:nativeSearch();analyze(A)
    C_AuctionHouse.GetBrowseResults=function()return {
        {itemKey={itemID=15166,itemLevel=45,itemSuffix=9002,battlePetSpeciesID=0}},
        {itemKey={itemID=15166,itemLevel=45,itemSuffix=9001,battlePetSpeciesID=0}}}end
    C_AuctionHouse.GetItemKeySampleLink=function(key)return key.itemSuffix==9001 and a or b end
    truth(A.MarketUI.OpenListings(A.Market.rows[1]));equal(w.searchedKey.itemSuffix,9001)
    equal(w.itemSearches,1);equal(w.browseSearches,0)
end)

test("pending modifier searches resolve once and cancel when the player's search changes",function()
    local w,A,a=market();w:openAH();w:nativeSearch();analyze(A)
    local results={};C_AuctionHouse.GetBrowseResults=function()return results end
    C_AuctionHouse.GetItemKeySampleLink=function()return a end
    function AuctionHouseFrame.SearchBar:GetSearchText()return self.searchText end
    truth(A.MarketUI.OpenListings(A.Market.rows[1]));equal(w.browseSearches,1);truth(A.MarketUI.pendingVariant)
    equal(AuctionHouseFrame.SearchBar:GetSearchText(),"Imposing Gloves");equal(w.itemSearches,0)
    AuctionHouseFrame.SearchBar:SetSearchText("Another item");A.MarketUI.ResolvePendingVariant()
    equal(A.MarketUI.pendingVariant,nil);equal(w.itemSearches,0)
    w:advance(1);truth(A.MarketUI.OpenListings(A.Market.rows[1]))
    results={{itemKey={itemID=15166,itemLevel=45,itemSuffix=9001,battlePetSpeciesID=0}}}
    w:event("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED");equal(w.itemSearches,1);equal(A.MarketUI.pendingVariant,nil)
    w:event("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED");equal(w.itemSearches,1)
end)

test("Opportunities reuses twelve rows with scrolling and collapsible filters",function()
    local w,A=world();local entries={}
    for id=1,40 do entries[#entries+1]={id=id,quantity=1,buyout=id*100,link=link(id)} end
    scan(w,A,entries);w:openAH();A.MarketUI.Show();A.MarketUI.view="listed";analyze(A,"listed");A.MarketUI.Refresh()
    local ui=A.MarketUI;equal(#ui.rows,12);equal(ui.pageSize,12);truth(ui.rows[12]:IsShown())
    local first=ui.rows[1].row;ui.Scroll(12);truth(ui.rows[1].row~=first)
    ui.scrollbar:SetValue(20);equal(ui.offset,20);equal(#ui.rows,12)
    ui.filterToggle.scripts.OnClick();equal(ui.pageSize,4);truth(ui.filters:IsShown())
    truth(ui.Apply());equal(ui.pageSize,12);equal(ui.filters:IsShown(),false)
    equal(w.requests,0)
end)

test("native alternating source pairs count corpse loot without a count prefix",function()
    local w,A=world();w.loot={{link=link(100),sources={guid(1000),2,guid(1000,2),1}}}
    w:event("LOOT_READY");w:event("LOOT_OPENED")
    local rows,n=A.Drops.Rows(1000);equal(n,2);equal(rows[1].hits,2)
    w.loot={{link=link(100),sources={1,guid(1000,3),1}}};w:event("LOOT_READY")
    equal(select(2,A.Drops.Rows(1000)),2);truth(A.Drops.skipped>0)
end)

test("personal creature tooltip resolves native unit tokens missing a data GUID",function()
    local w,A=world();A.Drops.Observe(guid(1000),{{id=100,quantity=1,link=link(100)}})
    GameTooltip.GetUnit=function()return "Test creature","mouseover"end
    w.unitTip(GameTooltip,{type=2,lines={{leftText="Test creature"}}})
    equal(GameTooltip.lines[2].right,"1 corpse checked");truth(GameTooltip.lines[3].right:find("100.0%%"))
    local data={type=2,id=1000,lines={{leftText="Test creature"}}}
    GameTooltip:ClearLines();GameTooltip.GetUnit=nil;w.guids.mouseover=nil
    w.unitTip(GameTooltip,data);truth(GameTooltip.lines[3].right:find("1/1",1,true))
    w.unitTip(GameTooltip,data);equal(#GameTooltip.lines,3)
end)

test("empty personal tooltips explain missing samples and never attach to players or items",function()
    local w,A=world();w.unitTip(GameTooltip,{type=2,id=1000})
    equal(GameTooltip.lines[3].left,"No personal samples yet.")
    GameTooltip:ClearLines();w.unitTip(GameTooltip,{type=2,guid=w.guid});equal(#GameTooltip.lines,0)
    w.unitTip(GameTooltip,{type=0,id=1000});equal(#GameTooltip.lines,0)
end)

test("harvest casts capture normal and rare node materials and categorize only personal receipts",function()
    local w,A=world() -- A stale unit mouseover must not block object loot.
    local node=guid(1618,1,"GameObject");w.items[100]={vendor=10};w.items[101]={vendor=50}
    A.Drops.ResolveTooltip(GameTooltip,{lines={{leftText="Peacebloom"}}})
    w:event("UNIT_SPELLCAST_SENT","player","Peacebloom","Cast-herb",2366)
    w.loot={{link=link(100),sources={node,2}},{link=link(101),sources={node,1}}}
    w:event("LOOT_READY");w:event("UNIT_SPELLCAST_SUCCEEDED","player","Cast-herb",2366)
    w:event("LOOT_OPENED");local rows,n=A.Drops.Rows(1618,"herbalism");equal(n,1);equal(#rows,2)
    equal(select(2,A.Drops.Rows(1618)),0);equal(A.Farm.Summary().total,0)
    w:event("CHAT_MSG_LOOT","You receive loot: " .. link(100) .. "x2.")
    w:advance(1.1);A.Farm.Tick();local sum=A.Farm.Summary()
    equal(sum.harvestValue,20);equal(sum.categories.herbalism,20);equal(sum.lootValue,0);equal(sum.recent[1].source,"herbalism")
    w:event("LOOT_CLOSED")
    GameTooltip:ClearLines();GameTooltip.data={lines={{leftText="Peacebloom"}}};GameTooltip:Show();A.Drops.CheckTooltip()
    truth(GameTooltip.lines[2].left:find("Herbalism",1,true));equal(GameTooltip.lines[2].right,"1 node checked")
    A.DB.Settings().showHarvestDrops=false;GameTooltip:ClearLines();A.Drops.CheckTooltip();equal(#GameTooltip.lines,0)
end)

test("skinning and creature loot from the same corpse use independent denominators",function()
    local w,A=world();w.dead=true
    w.loot={{link=link(100),sources={guid(1000),1}}};w:event("LOOT_READY");w:event("LOOT_CLOSED")
    w:event("UNIT_SPELLCAST_START","player","Cast-skin",8613)
    w.loot={{link=link(101),sources={guid(1000),2}}};w:event("LOOT_READY");w:event("LOOT_OPENED")
    equal(select(2,A.Drops.Rows(1000)),1);local rows,n=A.Drops.Rows(1000,"skinning")
    equal(n,1);equal(rows[1].id,101)
    w:event("LOOT_CLOSED")
    w.unitTip(GameTooltip,{type=2,guid=guid(1000)})
    truth(GameTooltip.lines[2].left:find("Skinning",1,true))
    A.DB.Settings().showHarvestDrops=false;GameTooltip:ClearLines()
    w.unitTip(GameTooltip,{type=2,guid=guid(1000)});truth(GameTooltip.lines[2].left:find("Drops",1,true))
    truth(A.Drops.Reset("monster","1000"));equal(A.Drops.Profile().mobs,0)
end)

test("failed or stale harvesting casts never turn unrelated corpse loot into node samples",function()
    local w,A=world();w:event("UNIT_SPELLCAST_START","player","Cast-mine",2575)
    w:event("UNIT_SPELLCAST_FAILED","player","Cast-mine",2575)
    w.loot={{link=link(100),sources={guid(1000),1}}};w:event("LOOT_READY")
    equal(select(2,A.Drops.Rows(1000,"mining")),0);equal(select(2,A.Drops.Rows(1000)),1)
    w:event("UNIT_SPELLCAST_START","player","Cast-skin",8613);w:advance(11)
    w.loot={{link=link(100),sources={guid(1000,2),1}}};w:event("LOOT_READY")
    equal(select(2,A.Drops.Rows(1000,"skinning")),0);equal(select(2,A.Drops.Rows(1000)),2)
end)

test("harvest observations survive reload and node resets retain other sources",function()
    local w,A=world();A.Drops.Observe(guid(1618,1,"GameObject"),{{id=100,quantity=1}},nil,nil,"herbalism")
    A.Drops.Observe(guid(1731,1,"GameObject"),{{id=101,quantity=1}},nil,nil,"mining")
    local w2,A2=world(A.DB.data);equal(select(2,A2.Drops.Rows(1618,"herbalism")),1)
    truth(A2.Drops.Reset("monster","1618"));equal(select(2,A2.Drops.Rows(1618,"herbalism")),0)
    A2.Drops.Observe(guid(1731,1,"GameObject"),{{id=101,quantity=1}},nil,nil,"mining")
    equal(select(2,A2.Drops.Rows(1731,"mining")),1);equal(A2.Drops.Profile().mobs,1)
end)

test("mail trade and wallet increases never become farming gold or item income",function()
    local w,A=world();w.items[100]={vendor=10}
    for _,pair in ipairs({{"MAIL_SHOW","MAIL_CLOSED"},{"TRADE_SHOW","TRADE_CLOSED"}}) do
        w:event(pair[1]);w:event("PLAYER_MONEY");w:event("CHAT_MSG_MONEY","You loot 2 Gold")
        w:event("CHAT_MSG_LOOT","You receive loot: " .. link(100) .. ".")
        w:event(pair[2]);w:event("CHAT_MSG_MONEY","You loot 2 Gold");w:advance(2.1);A.Farm.Tick()
    end
    equal(A.Farm.Summary().total,0);equal(#A.Farm.pending,0);equal(A.Farm.excludedReceipts,4)
    w:event("CHAT_MSG_MONEY","You loot 1 Silver");equal(A.Farm.Summary().coins,100)
end)

test("categorized reports and saved summaries reconcile loot quests and harvesting",function()
    local w,A=world();w.items[100]={vendor=10}
    for _,source in ipairs({"loot","quest","herbalism","mining","skinning"})do A.Farm.AddItem(link(100),1,source) end
    A.Farm.AddMoney(100,false);A.Farm.AddMoney(200,true)
    local s=A.Farm.Summary();equal(s.total,350);equal(s.harvestValue,30);equal(s.categories.loot,110);equal(s.categories.quest,210)
    A.FarmingUI.Show("session");local ui=A.FarmingUI
    equal(ui.categoryTotals[3]:GetText(),coin(30))
    ui.source="harvesting";ui.Refresh();truth(ui.listCount:GetText():find("3 entries",1,true))
    w:advance(60);A.Farm.Tick();truth(A.Farm.Reset());equal(A.Farm.Profile().history[1].categories.mining,10)
    equal(A.Farm.Profile().history[1].harvestValue,30)
end)

test("standalone windows occupy whole frame-level bands and focus as complete windows",function()
    local _,A=world();A.UI.ShowStandalone();local main=A.UI.frame
    A.FarmingUI.Show();local farm=A.FarmingUI.frame
    truth(farm:GetFrameLevel()>=main:GetFrameLevel()+1024)
    main.scripts.OnMouseDown(main);truth(main:GetFrameLevel()>=farm:GetFrameLevel()+1024)
    A.FarmingUI.Show();truth(farm:GetFrameLevel()>=main:GetFrameLevel()+1024)
    A.UI.ShowDiagnostics();local diag=A.UI.diagnostics
    truth(diag:GetFrameLevel()>=farm:GetFrameLevel()+1024)
end)

test("reference samples stay scoped to creature versus harvesting data",function()
    local _,A=world()
    A.LootReference.Register("Source samples",function(id,kind)
        return {{id=kind=="mining" and 101 or 100,rate=12.5,samples=400}}
    end,false)
    equal(A.LootReference.Rows(1000,"loot")[1].id,100)
    equal(A.LootReference.Rows(1000,"mining")[1].id,101)
    equal(A.LootReference.Rows(1000,"mining")[1].samples,400)
end)

test("reference node tooltips do not require an existing personal area record",function()
    local _,A=world();A.DB.Settings().dropMode="reference"
    A.LootReference.Register("Reference source",function(id,kind)
        if id==1731 and kind=="mining" then return {{id=2770,name="Copper Ore",rate=90,samples=500},
            {id=1210,name="Rare gem",rate=.024,samples=4204},{id=12363,name="Tiny sample rate",rate=.0001,samples=1000000}} end
        return {}
    end,false)
    A.Drops.Tooltip(GameTooltip,{guid=guid(1731,1,"GameObject"),lines={{leftText="Copper Vein"}}})
    truth(GameTooltip.lines[2].left:find("Mining",1,true))
    truth(GameTooltip.lines[3].right:find("500 samples",1,true));equal(A.Drops.Profile().mobs,0)
    truth(GameTooltip.lines[4].right:find("0.02%",1,true));truth(GameTooltip.lines[5].right:find("<0.01%",1,true))
end)

test("combat spell name checks are cached with a bounded index",function()
    local _,A=world();local calls=0
    C_Spell={GetSpellInfo=function(id) calls=calls+1;return {name=id==2366 and "Herbalism" or ("Ability " .. id)} end}
    for _=1,100 do equal(A.Drops.GatherKind(9999),nil) end
    truth(calls<=13)
    for id=10000,10200 do A.Drops.GatherKind(id) end
    equal(#A.Drops.spellOrder,128);equal(A.Drops.spellKinds[9999],nil)
end)
