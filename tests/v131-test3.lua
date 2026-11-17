local fresh,row,link,test,equal,near,truth,secret=...
local NOV15=1794700800
local function bonus(id,n,name,level,seed)
    return "|cff1eff00|Hitem:"..id..":0:0:0:0:0:0:"..(seed or 0)..":"..(level or 40)..":0:0:0:1:"..n.."|h["..(name or "Pants of the Owl").."]|h|r"
end
local function world(saved,wall)
    local w,A=fresh(saved);w.wall=wall or NOV15
    w.items[100]={vendor=50,name="Pants of the Owl",quality=2,classID=4}
    LOOT_ITEM_SELF="You receive loot: %s.";LOOT_ITEM_SELF_MULTIPLE="You receive loot: %sx%d."
    YOU_LOOT_MONEY="You loot %s";GOLD_AMOUNT="%d Gold";SILVER_AMOUNT="%d Silver";COPPER_AMOUNT="%d Copper"
    w.loot={}
    UnitGUID=function(unit)return unit=="player" and w.guid or "Creature-0-1-1-1-1000-1"end
    UnitName=function()return "Test creature"end
    GetNumLootItems=function()return #w.loot end
    GetLootSourceInfo=function()return "Creature-0-1-1-1-1000-1",1 end
    GetLootSlotLink=function(slot)return w.loot[slot]end
    GetLootSlotInfo=function()return 1,"Item",1,0,2,false,false,nil,false end
    w:load();A.Farm.ConfigureIdle(false,5)
    local native=C_Item.GetItemInfo
    C_Item.GetItemInfo=function(lookup)
        local values={native(lookup)}
        if values[1] then values[1]=A.Util.LinkName(lookup) or values[1] end
        return unpack(values,1,17)
    end
    function w:tick(n)self:advance(n);A.Farm.Tick()end
    function w:money()self:event("CHAT_MSG_MONEY","You loot 1 Silver")end
    function w:item(id)self:event("CHAT_MSG_LOOT","You receive loot: "..link(id or 100)..".")end
    return w,A
end
local function scan(w,A,entries)
    local s=A.DB.NewSnapshot(A.Util.MarketKey(),#entries,w.wall)
    for _,r in ipairs(entries)do A.DB.AddRow(s,r.id or 100,1,r.price or 1000,r.link or bonus(100,5661),0,2,r.name or A.Util.LinkName(r.link) or "Pants of the Owl")end
    truth(A.DB.Commit(s));return s
end
local function finish(A)
    for _=1,10000 do if not A.Market.job then return end;A.Market.Tick()end
    error("analysis must settle")
end
local function analyze(A,view)
    A.Market.Ensure(view or "listed","return");finish(A)
end
local function threeDates()
    local w,A=world()
    for day=0,2 do w.wall=NOV15+day*86400;scan(w,A,{{price=day==2 and 100 or 1000}})end
    A.DB.Settings().marketSearch="of the";return w,A
end

test("a missing quest close cannot discard all nineteen later combat loot awards",function()
    local w,A=world();w:event("QUEST_COMPLETE");w:event("QUEST_TURNED_IN",42,100,1000)
    w.combat=true;w:event("PLAYER_REGEN_DISABLED")
    for _=1,19 do w:money();w:tick(60)end
    local s=A.Farm.Summary()
    if os.getenv("V131_REPLAY")=="1"then print("FARM_CONTEXT_REPLAY coins="..s.coins.." quest="..s.questCoins.." ignored="..(A.Farm.excludedReceipts or 0).." peak="..s.peak.rate)end
    equal(s.coins,1900);equal(s.questCoins,1000);near(s.peak.rate,6000);equal(A.Farm.excludedReceipts or 0,0)
end)

test("a missing merchant close recovers from the hidden native frame",function()
    local w,A=world();MerchantFrame=CreateFrame("Frame");MerchantFrame:Show();w:event("MERCHANT_SHOW")
    w:money();equal(A.Farm.Summary().coins,0);MerchantFrame:Hide();w:tick(.3);w:tick(3)
    w:money();w:item();w:tick(2)
    if os.getenv("V131_REPLAY")=="1"then print("MERCHANT_CONTEXT_REPLAY total="..A.Farm.Summary().total.." blocked="..tostring(A.Farm.merchantOpen==true))end
    equal(A.Farm.Summary().coins,100);equal(A.Farm.Summary().lootValue,50);equal(A.Farm.merchantOpen,false)
end)

test("native mail and trade windows recover when hidden but retain close protection",function()
    for _,kind in ipairs({"mail","trade"})do
        local w,A=world();local frame=CreateFrame("Frame");frame:Show()
        if kind=="mail" then MailFrame=frame;w:event("MAIL_SHOW") else TradeFrame=frame;w:event("TRADE_SHOW") end
        w:tick(10);w:money();equal(A.Farm.Summary().coins,0)
        frame:Hide();w:tick(.3);w:money();equal(A.Farm.Summary().coins,0)
        w:tick(3);w:money();equal(A.Farm.Summary().coins,100)
    end
end)

test("a world transition retires transaction flags without their missing close event",function()
    for _,event in ipairs({"MERCHANT_SHOW","MAIL_SHOW","TRADE_SHOW"})do
        local w,A=world();w:event(event);w:event("PLAYER_LEAVING_WORLD");w:tick(100)
        w:event("PLAYER_ENTERING_WORLD");w:money();w:item();w:tick(2)
        equal(A.Farm.Summary().coins,100);equal(A.Farm.Summary().lootValue,50)
    end
end)

test("missing native frame data never pretends an active transaction has closed",function()
    local w,A=world();w:event("MAIL_SHOW");w:tick(100);w:money();w:item();w:tick(2)
    equal(A.Farm.Summary().total,0);equal(A.Farm.ignoredMoney.mail,1)
    w:event("MAIL_CLOSED");w:tick(3);w:money();equal(A.Farm.Summary().coins,100)
end)

test("quest context expires if both the close event and native window are unavailable",function()
    local w,A=world();w:event("QUEST_COMPLETE");w:tick(61);w:money();w:item();w:tick(2)
    equal(A.Farm.Summary().coins,100);equal(A.Farm.Summary().lootValue,50);equal(A.Farm.Summary().questValue,0)
end)

test("a visible quest reward window can stay open while the player chooses a reward",function()
    local w,A=world();QuestFrame=CreateFrame("Frame");QuestFrame:Show();w:event("QUEST_COMPLETE");w:tick(120)
    w:item();w:tick(1.1);w:event("QUEST_TURNED_IN",42,100,1000);w:event("QUEST_LOOT_RECEIVED",42,link(100),1)
    QuestFrame:Hide();w:tick(300)
    equal(A.Farm.Summary().total,1050);equal(A.Farm.Summary().questValue,50);equal(A.Farm.Summary().coins,0)
    near(A.Farm.Summary().peak.rate,0)
end)

test("a hidden quest window recovers before later ordinary receipts",function()
    local w,A=world();QuestFrame=CreateFrame("Frame");QuestFrame:Show();w:event("QUEST_COMPLETE")
    QuestFrame:Hide();w:tick(.3);w:tick(4);w:money();w:item();w:tick(2)
    equal(A.Farm.Summary().coins,100);equal(A.Farm.Summary().lootValue,50);truth(A.Farm.recoveredWindows>0)
end)

test("real corpse loot closes stale quest context even if its chat arrives after loot closes",function()
    local w,A=world();w:event("QUEST_COMPLETE")
    w.loot={link(100)};w:event("LOOT_READY");w:event("LOOT_OPENED");w.loot={};w:event("LOOT_CLOSED")
    w:money();w:item();w:tick(2)
    equal(A.Farm.Summary().coins,100);equal(A.Farm.Summary().lootValue,50);equal(A.Farm.Summary().questValue,0)
end)

test("quest gold echoes remain excluded after a real loot interaction",function()
    local w,A=world();w.loot={link(100)};w:event("LOOT_READY");w:event("LOOT_CLOSED")
    w:event("QUEST_COMPLETE");w:event("QUEST_TURNED_IN",42,100,100);w:money();w:tick(300)
    equal(A.Farm.Summary().questCoins,100);equal(A.Farm.Summary().coins,0);near(A.Farm.Summary().peak.rate,0)
    equal(A.Farm.ignoredMoney.quest,1)
end)

test("an unreadable loot reply cannot reuse an old world source to clear quest context",function()
    local w,A=world();w.loot={link(100)};w:event("LOOT_READY");w:event("LOOT_CLOSED")
    w:event("QUEST_COMPLETE");w:event("QUEST_TURNED_IN",42,100,100)
    GetNumLootItems=function()return secret end;w:event("LOOT_READY")
    equal(A.Drops.worldLootRead,nil);equal(A.Farm.realLootAt,nil);truth(A.Farm.QuestContext())
end)

test("context recovery cannot undo manual pause or death pause",function()
    local w,A=world();A.Farm.Pause(true);w:event("QUEST_COMPLETE");w:event("PLAYER_REGEN_DISABLED");w:money();w:item();w:tick(300)
    equal(A.Farm.Summary().total,0);truth(A.Farm.Profile().current.paused)
    A.Farm.Pause(false);w:event("PLAYER_DEAD");w:event("PLAYER_LEAVING_WORLD");w:event("PLAYER_ENTERING_WORLD")
    -- The player stays dead according to the public state API.
    UnitIsDeadOrGhost=function()return true end;w:event("PLAYER_ENTERING_WORLD");w:money();w:tick(60)
    equal(A.Farm.Summary().total,0);truth(A.Farm.Summary().paused)
end)

test("farming diagnostics identify each exclusion and recovered native window",function()
    local w,A=world();w:event("MERCHANT_SHOW");w:money();w:event("MERCHANT_CLOSED");w:tick(3)
    w:event("QUEST_COMPLETE");w:money();local text=A.UI.DiagnosticsText()
    truth(text:find("merchant=1",1,true));truth(text:find("quest=1",1,true));truth(text:find("Farming receipt context:",1,true))
end)

test("November seventeen has only two earlier exact dates after November fifteen tracking",function()
    local w,A=threeDates();analyze(A,"deals");equal(#A.Market.rows,0)
    analyze(A);local r=A.Market.rows[1];equal(r.days,2);truth(r.needsHistory);equal(r.profit,nil)
    equal(A.Market.coverage.modifiedPrior[2],1);equal(A.Market.historyInfo.exactDays,2)
    local text=table.concat(A.Market.HistoryDiagnostics(),"\n")
    truth(text:find("scan_UTC=2026-11-17",1,true));truth(text:find("2026-11-15:1000.00c,2026-11-16:1000.00c",1,true))
    if os.getenv("V131_REPLAY")=="1"then print("VARIANT_CALENDAR_REPLAY day=2026-11-17 prior="..r.days.." profit="..tostring(r.profit))end
end)

test("a fourth date supplies three earlier exact dates and permits qualifying resale",function()
    local w,A=threeDates();w.wall=NOV15+3*86400;scan(w,A,{{price=10}});analyze(A,"deals")
    equal(#A.Market.rows,1);local r=A.Market.rows[1];equal(r.days,3);truth(r.deal);truth(r.profit>0)
    equal(A.Market.coverage.modifiedPrior[3],1)
end)

test("twelve market-wide dates do not invent earlier days for new bonus variants",function()
    local w,A=world()
    for day=-9,-1 do w.wall=NOV15+day*86400;scan(w,A,{{link=link(100)}})end
    for day=0,2 do w.wall=NOV15+day*86400;scan(w,A,{{price=day==2 and 100 or 1000}})end
    A.DB.Settings().marketSearch="of the";analyze(A)
    equal(A.History.Status().days,12);equal(A.Market.rows[1].days,2);equal(A.Market.coverage.needsHistory,1)
end)

test("same-day rescans do not advance exact history coverage",function()
    local w,A=world();for _=1,5 do scan(w,A,{{price=100}});w:tick(900)end
    analyze(A);equal(A.Market.rows[1].days,0);equal(A.Market.historyInfo.priorDays,0)
end)

test("exact modifier history survives reload and level or unique-id link changes",function()
    local w,A=world()
    for day=0,3 do
        w.wall=NOV15+day*86400
        scan(w,A,{{link=bonus(100,5661,"Pants of the Owl",35+day,1000+day),price=day==3 and 100 or 1000}})
        if day<3 then w,A=world(A.DB.data,w.wall)end
    end
    A.DB.Settings().marketSearch="of the";analyze(A,"deals")
    equal(#A.Market.rows,1);equal(A.Market.rows[1].variantKey,"100:0:b5661");equal(A.Market.rows[1].days,3)
end)

test("a different modifier cannot fill an Owl variant's missing priced dates",function()
    local w,A=world()
    for day=0,3 do
        w.wall=NOV15+day*86400;local entries={{link=bonus(100,5662,"Pants of the Bear"),price=1000}}
        if day~=1 and day~=2 then entries[#entries+1]={link=bonus(100,5661),price=100}end
        scan(w,A,entries)
    end
    A.DB.Settings().marketSearch="of the owl";analyze(A)
    equal(#A.Market.rows,1);equal(A.Market.rows[1].days,1);truth(A.Market.rows[1].needsHistory)
    local text=table.concat(A.Market.HistoryDiagnostics(),"\n");truth(text:find("prior=1/3",1,true))
    equal(text:find("key=100:0:b5662",1,true),nil)
end)

test("sufficient exact history remains separate from profit and movement failures",function()
    local w,A=threeDates();w.wall=NOV15+3*86400;scan(w,A,{{price=2000}});analyze(A,"deals")
    equal(#A.Market.rows,0);equal(A.Market.coverage.needsHistory,0);equal(A.Market.coverage.filteredSignals,1)
    equal(A.Market.coverage.modifiedPrior[3],1);analyze(A);truth(A.Market.rows[1].profit<0);equal(A.Market.rows[1].needsHistory,nil)
end)

test("legacy nonzero-suffix history stays usable before the bonus format was introduced",function()
    local w,A=world();local item=link(100,-5):gsub("%[Test%]","[Pants of the Owl]")
    for day=0,3 do
        w.wall=NOV15+day*86400;local s=scan(w,A,{{link=item,price=day==3 and 100 or 1000}})
        if day<3 then s.variantFormat=nil;A.History.Days(A.Util.MarketInfo())[math.floor(w.wall/86400)].variantFormat=nil end
    end
    analyze(A,"deals");equal(#A.Market.rows,1);equal(A.Market.rows[1].days,3);equal(A.Market.historyInfo.exactDays,0)
end)

test("the player's explicit two-day filter works without changing the default",function()
    local _,A=threeDates();equal(A.DB.Settings().marketMinDays,3);A.DB.Settings().marketMinDays=2
    analyze(A,"deals");equal(#A.Market.rows,1);equal(A.Market.rows[1].days,2)
end)

test("history diagnostics work before opening Opportunities and make no auction requests",function()
    local w,A=threeDates();local requests=w.requests;local text=A.UI.DiagnosticsText()
    truth(text:find("exact_format_dates=2",1,true));truth(text:find("current_date_excluded=true",1,true))
    equal(w.requests,requests);equal(A.Market.builds,0)
end)

test("missing baselines display priced-day progress and dated details in All items",function()
    local w,A=threeDates();w:openAH();local ui=A.MarketUI;ui.view="listed";analyze(A);ui.Refresh()
    equal(ui.rows[1].labels[6].text,"2/3 days");equal(ui.rows[1].labels[7].text,"-")
    ui.rows[1].scripts.OnClick(ui.rows[1],"RightButton")
    truth(ui.detail.text:find("2/3 earlier priced UTC days",1,true));truth(ui.detail.text:find("2026-11-15",1,true))
    ui.rows[1].scripts.OnEnter(ui.rows[1]);truth(GameTooltip.lines[#GameTooltip.lines].left:find("current scan date excluded",1,true))
    equal(w.itemSearches or 0,0)
end)

test("diagnostic samples remain bounded and selected variants get their own exact key",function()
    local w,A=world();local entries={}
    for n=1,20 do entries[n]={link=bonus(100,5600+n,"Pants of the Owl"),price=100}end
    scan(w,A,entries);A.DB.Settings().marketSearch="of the";analyze(A)
    equal(#A.Market.coverage.samples,3);A.MarketUI.selected=A.Market.rows[10]
    local lines=A.Market.HistoryDiagnostics();equal(#lines,5)
    truth(lines[3]:find("key="..A.Market.rows[10].variantKey,1,true))
end)

test("a later scan cannot erase an exact modifier priced earlier on the same UTC date",function()
    local w,A=world();scan(w,A,{{price=1000}});w:tick(900)
    scan(w,A,{{id=200,link=link(200),price=500}})
    local record=A.History.Days(A.Util.MarketInfo())[math.floor(w.wall/86400)]
    if os.getenv("V131_REPLAY")=="1"then print("SAME_DAY_VARIANT_REPLAY price="..tostring(record.variants["100:0:b5661"]))end
    equal(record.variants["100:0:b5661"],1000);equal(A.DB.Price(100,bonus(100,5661)),nil)
    analyze(A);for _,r in ipairs(A.Market.rows)do truth(r.id~=100)end
    local _,B=world(A.DB.data,w.wall);equal(B.History.Average(100,bonus(100,5661)).days,1)
end)

test("three sold-out intraday observations can supply a later exact resale baseline",function()
    local w,A=world()
    for day=0,2 do
        w.wall=NOV15+day*86400;scan(w,A,{{price=1000}});w:tick(900);scan(w,A,{})
    end
    w.wall=NOV15+3*86400;scan(w,A,{{price=100}});analyze(A,"deals")
    equal(#A.Market.rows,1);equal(A.Market.rows[1].days,3);truth(A.Market.rows[1].deal)
end)

test("the latest observed price replaces a modifier price without adding another day",function()
    local w,A=world();scan(w,A,{{price=1000}});w:tick(900);scan(w,A,{{price=2000}})
    w:tick(900);scan(w,A,{})
    local average=A.History.Average(100,bonus(100,5661));equal(average.value,2000);equal(average.days,1)
end)

test("retained exact observations never fill an unobserved UTC date",function()
    local w,A=world();scan(w,A,{{price=1000}});w:tick(900);scan(w,A,{})
    w.wall=NOV15+86400;scan(w,A,{})
    local days=A.History.Days(A.Util.MarketInfo());equal(days[math.floor(w.wall/86400)].variants["100:0:b5661"],nil)
    equal(A.History.Average(100,bonus(100,5661)).days,1)
end)

test("daily retention cannot relabel legacy zero-suffix history as exact bonus data",function()
    local w,A=world();local s=scan(w,A,{{price=1000}})
    s.variantFormat=nil;local day=math.floor(w.wall/86400);A.History.Days(A.Util.MarketInfo())[day].variantFormat=nil
    w:tick(900);scan(w,A,{})
    equal(A.History.Days(A.Util.MarketInfo())[day].variants["100:0:b5661"],nil)
    equal(A.History.Average(100,bonus(100,5661)),nil)
end)

test("daily modifier retention stays bounded and newer observations take priority",function()
    local w,A=world();scan(w,A,{{link=bonus(100,5661),price=1000},{link=bonus(100,5662),price=2000}})
    A.MAX_ROWS=2;w:tick(900);scan(w,A,{{link=bonus(100,5663),price=3000}})
    local record=A.History.Days(A.Util.MarketInfo())[math.floor(w.wall/86400)]
    local count=0;for _ in pairs(record.variants)do count=count+1 end
    equal(count,2);equal(record.variants["100:0:b5663"],3000)
end)
