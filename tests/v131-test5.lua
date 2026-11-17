local fresh,row,link,test,equal,near,truth,secret=...
local function make(count,all,saved)
    count=count or 3
    local w,A=fresh(saved);w:load();w.count=count;w.prices={}
    for index=1,count do
        local id=99+index
        w.items[id]={name=string.format("Watch %03d",index),quality=(index-1)%5,commodity=true}
        w.prices[index]=index==1 and 500 or index==2 and 800 or index==3 and 400 or 500+index
    end
    function w:scan(values)
        local entries={}
        for index=1,self.count do
            local price=values and values[index]or self.prices[index]
            if not values or values[index]~=false then entries[#entries+1]={id=99+index,price=price}end
        end
        local snapshot=A.DB.NewSnapshot(A.Util.MarketKey(),#entries,self.wall)
        for _,entry in ipairs(entries)do A.DB.AddRow(snapshot,entry.id,5,entry.price*5,link(entry.id),0)end
        truth(A.DB.Commit(snapshot));return snapshot
    end
    function w:drain()
        A.Watchlist.Ensure()
        for _=1,1000 do if not A.Watchlist.job then return end;A.Watchlist.Tick()end
        error("watchlist must settle")
    end
    function w:alert()self:drain();A.Watchlist.AlertTick()end
    w:scan()
    if not saved then for index=1,count do truth(A.Watchlist.Save(99+index,all and 1000 or index==3 and 0 or 600,0,0))end end
    w:drain();w:makeAH()
    return w,A,A.Watchlist,A.WatchUI,A.EconomyUI
end
local function click(button,mouse)button.scripts.OnClick(button,mouse or"LeftButton")end
local function later(w,values)w:advance(901);w:scan(values);w:drain()end
local function close(w,E)if E.frame then E.frame:Hide()end;w:event("AUCTION_HOUSE_CLOSED");AuctionHouseFrame:Hide()end

test("watchlists show ten reusable scrolling rows and reach all two hundred watches",function()
    local w,A,W,UI,E=make(200,true);E.Show("watch");equal(#UI.rows,10);equal(E.watchPrevious,nil);equal(E.watchNext,nil)
    equal(#UI.View(),200);local frames=w.createdFrames
    UI.Scroll(10000);equal(UI.offset,190);equal(UI.rows[10].row,UI.View()[200])
    for _=1,25 do UI.Scroll(0);UI.Scroll(190)end
    equal(w.createdFrames,frames);truth(UI.scrollbar:IsShown());equal(w.requests,0)
end)
test("watchlist mouse scrolling clamps at both ends and hides unused rows",function()
    local w,A,W,UI,E=make(12,true);E.Show("watch")
    UI.rows[1].scripts.OnMouseWheel(UI.rows[1],-1);equal(UI.offset,2)
    UI.list.scripts.OnMouseWheel(UI.list,1);equal(UI.offset,0)
    UI.Scroll(secret);equal(UI.offset,0);UI.Scroll(0/0);equal(UI.offset,0)
    UI.searchBox:SetText("Watch 012");equal(#UI.View(),1);equal(UI.rows[2]:IsShown(),false);equal(UI.scrollbar:IsShown(),false)
end)
test("watchlist sorts target status first and reverses numeric headers with unknowns last",function()
    local w,A,W,UI,E=make();E.Show("watch");equal(UI.rows[1].row.status,"TARGET MET")
    UI.Sort("current");equal(UI.rows[1].row.current,400)
    UI.Sort("current");equal(UI.rows[1].row.current,800)
    UI.Sort("target");equal(UI.View()[#UI.View()].watch.maxBuy,0)
    local first=UI.View();for _=1,50 do E.Refresh();equal(UI.View(),first)end
end)
test("watchlist search and target-only filters narrow names and reset scrolling",function()
    local w,A,W,UI,E=make(20,true);E.Show("watch");UI.Scroll(10)
    UI.searchBox:SetText("watch 002");equal(UI.offset,0);equal(#UI.View(),1);equal(UI.rows[1].row.id,101)
    UI.searchBox:SetText("");UI.only:SetChecked(true);click(UI.only);equal(#UI.View(),20)
    later(w,{[1]=2000});E.Refresh();equal(#UI.View(),19)
    UI.searchBox:SetText("[literal]");equal(#UI.View(),0);truth(UI.empty:IsShown())
end)
test("watchlist rarity colors stay on names while target status has its own highlight",function()
    local w,A,W,UI,E=make();E.Show("watch")
    for _,button in ipairs(UI.rows)do if button.row then
        local r,g,b=A.Util.ItemColor(button.row.link,button.row.quality)
        near(button.labels[1].color[1],r);near(button.labels[1].color[2],g);near(button.labels[1].color[3],b)
        equal(button.ready:IsShown(),button.row.matched);equal(button.labels[2].color[1],.90)
    end end
    equal(UI.rows[1].labels[6]:GetText(),"TARGET MET")
end)
test("left-clicking a watched item opens its native Buy page exactly once",function()
    local w,A,W,UI,E=make(1);w:openAH();local ah=w:nativeSearch();E.Show("watch")
    equal(w.itemSearches,0);click(UI.rows[1]);equal(w.itemSearches,1);equal(w.searchedKey.itemID,100)
    equal(E.frame:IsShown(),false);equal(w.requests,0);equal(ah.displayMode,AuctionHouseFrameDisplayMode.CommoditiesBuy)
end)
test("right-click and Edit open target editing without searches or a visible item id",function()
    local w,A,W,UI,E=make(1);w:openAH();w:nativeSearch();E.Show("watch")
    click(UI.rows[1],"RightButton");truth(UI.editor:IsShown());equal(E.watchInputs.item:IsShown(),false)
    equal(E.watchItemLabel:GetText(),"Watch 001");equal(w.itemSearches,0)
    UI.editor:Hide();click(UI.rows[1].edit);truth(UI.editor:IsShown());equal(w.itemSearches,0)
end)
test("watch target edits retain their scope and use gold amounts per item",function()
    local w,A,W,UI,E=make(1);E.Show("watch");UI.Edit(W.rows[1]);local v=E.watchInputs
    v.itemPrice:SetText("0.1234");v.roi:SetText("25");v.profit:SetText("0.01");truth(UI.Save());w:drain()
    equal(#W.Entries(),1);equal(W.Entries()[1].key,"100:*");equal(W.Entries()[1].entry.maxBuy,1234)
    equal(W.Entries()[1].entry.minReturn,25);equal(W.Entries()[1].entry.minProfit,100);equal(UI.editor:IsShown(),false)
end)
test("new watches accept item links instead of asking for numeric ids",function()
    local w,A,W,UI,E=make(1);E.Show("watch");UI.New();truth(E.watchInputs.item:IsShown())
    E.watchInputs.item:SetText("100");equal(UI.Save(),false)
    E.watchInputs.item:SetText(link(101,7));E.watchInputs.itemPrice:SetText("0.05");truth(UI.Save());w:drain()
    local found=false;for _,entry in ipairs(W.Entries())do if entry.key=="101:7"then found=true end end;truth(found)
end)
test("dragging a linked item fills the new-watch field and consumes only a valid cursor",function()
    local w,A,W,UI,E=make(1);E.Show("watch");UI.New();local cleared=0
    GetCursorInfo=function()return "item",101,link(101,7)end;ClearCursor=function()cleared=cleared+1 end
    E.watchInputs.item.scripts.OnReceiveDrag();equal(E.watchInputs.item:GetText(),link(101,7));equal(cleared,1)
    GetCursorInfo=function()return "spell",secret,secret end;UI.Drop();equal(cleared,1)
end)
test("watch settings stay in the watchlist while ledger settings keep their existing destination",function()
    local w,A,W,UI,E=make();E.Show("watch");click(E.settingsTab)
    truth(UI.settings:IsShown());equal(A.UI.frame and A.UI.frame:IsShown()or false,false)
    UI.checks.watchOpenOnScan:SetChecked(false);click(UI.checks.watchOpenOnScan);equal(A.DB.Settings().watchOpenOnScan,false)
    E.mode="ledger";E.Refresh();equal(UI.settings:IsShown(),false);click(E.settingsTab);truth(A.UI.frame:IsShown())
end)
test("quiet default alerts open one grouped watchlist with no chat or auction searches",function()
    local w,A,W,UI,E=make(3,true);w:openAH();w:nativeSearch();local messages=#w.messages
    w:alert();equal(W.alertBatches,1);equal(W.alertOpens,1);equal(W.lastAlertCount,3)
    truth(E.frame:IsShown());equal(E.mode,"watch");equal(#w.messages,messages);equal(w.itemSearches,0);equal(w.browseSearches,0)
    for _=1,50 do W.AlertTick();E.Refresh()end;equal(W.alertOpens,1)
end)
test("unchanged matches stay quiet through later scans and repeat AH visits",function()
    local w,A,W,UI,E=make(1);w:openAH();w:alert();close(w,E)
    w:openAH();w:alert();equal(W.alertOpens,1);equal(E.frame:IsShown(),false)
    later(w);W.AlertTick();equal(W.alertOpens,1);equal(E.frame:IsShown(),false)
end)
test("a lower matched price produces one new grouped review",function()
    local w,A,W,UI,E=make(1);w:openAH();w:alert();E.frame:Hide()
    later(w,{400});W.AlertTick();equal(W.alertOpens,2);truth(E.frame:IsShown());equal(W.rows[1].watch.lastAlertPrice,400)
    E.frame:Hide();later(w,{450});W.AlertTick();equal(W.alertOpens,2)
end)
test("missing or out-of-target listings rearm a watch before a later target hit",function()
    local w,A,W,UI,E=make(1);w:openAH();w:alert();E.frame:Hide()
    later(w,{900});W.AlertTick();equal(W.rows[1].matched,false);equal(W.alertOpens,1)
    later(w,{550});W.AlertTick();equal(W.alertOpens,2);E.frame:Hide()
    later(w,{false});W.AlertTick();equal(W.rows[1].status,"Not listed")
    later(w,{550});W.AlertTick();equal(W.alertOpens,3)
end)
test("reviewed watch matches remain quiet after saved-data reload",function()
    local w,A,W,UI,E=make(1);w:openAH();w:alert()
    local saved=A.DB.data;local oldWall=w.wall
    local w2,B=fresh(saved);w2.wall=oldWall;w2:load();w2:openAH()
    B.Watchlist.Ensure();for _=1,100 do B.Watchlist.Tick()end;B.Watchlist.AlertTick()
    equal(B.Watchlist.alertOpens,0);equal(B.Watchlist.MatchCount(),1);equal(B.EconomyUI.frame,nil)
end)
test("disabled watch alerts keep visible target matches and a passive badge",function()
    local w,A,W,UI,E=make(1);A.DB.Settings().watchAlerts=false;w:openAH();local messages=#w.messages
    w:alert();UI.UpdateBadge();equal(W.alertBatches,0);equal(E.frame,nil);equal(#w.messages,messages)
    equal(A.MarketUI.watchButton:GetText(),"Watchlists (1)");equal(W.MatchCount(),1)
end)
test("optional chat-only alerts emit one summary without opening the watch window",function()
    local w,A,W,UI,E=make(3,true);local s=A.DB.Settings();s.watchOpenOnScan=false;s.watchOpenOnAH=false;s.watchChatAlerts=true
    w:openAH();local messages=#w.messages;w:alert();equal(#w.messages,messages+1);equal(W.alertBatches,1);equal(W.alertOpens,0)
    equal(E.frame,nil);for _=1,100 do W.AlertTick()end;equal(#w.messages,messages+1)
end)
test("watch alerts wait for a real AH and never open during combat",function()
    local w,A,W,UI,E=make(1);A.auctionOpen=false;W.AlertTick();equal(W.alertOpens,0)
    w:openAH();w.combat=true;W.AlertTick();equal(W.alertOpens,0)
    w.combat=false;W.AlertTick();equal(W.alertOpens,1)
end)
test("stale and future snapshots cannot display target alerts",function()
    local w,A,W,UI,E=make(1);w:advance(86401);w:openAH();w:alert();equal(W.alertOpens,0);equal(W.MatchCount(),0)
    A.DB.Snapshot().startedAt=w.wall+10;w:drain();W.AlertTick();equal(W.alertOpens,0)
end)
test("automatic reviews wait while selling and use the latest eligible results",function()
    local w,A,W,UI,E=make(1);local ah=w:openAH();ah.CommoditiesSellFrame=CreateFrame("Frame",nil,ah);ah.CommoditiesSellFrame:Show()
    w:alert();equal(W.alertOpens,0);later(w,{900});W.AlertTick();equal(W.alertOpens,0)
    ah.CommoditiesSellFrame:Hide();W.AlertTick();equal(W.alertOpens,0)
    later(w,{500});W.AlertTick();equal(W.alertOpens,1)
end)
test("automatic reviews defer while typing and resume after the field is released",function()
    local w,A,W,UI,E=make(1);w:openAH();GetCurrentKeyBoardFocus=function()return {}end
    w:alert();equal(W.alertOpens,0);GetCurrentKeyBoardFocus=function()return nil end;W.AlertTick();equal(W.alertOpens,1)
end)
test("automatic reviews do not interrupt ledger or watch target editing",function()
    local w,A,W,UI,E=make(1);w:openAH();E.Show("ledger");w:alert();equal(W.alertOpens,0)
    E.frame:Hide();W.AlertTick();equal(W.alertOpens,1)
    UI.Edit(W.rows[1]);later(w,{400});W.AlertTick();equal(W.alertOpens,1)
    UI.editor:Hide();W.AlertTick();equal(W.alertOpens,1);equal(W.alertBatches,2);equal(W.rows[1].watch.lastAlertPrice,400)
end)
test("manually dismissing a watchlist prevents its unfinished batch from reopening it",function()
    local w,A,W,UI,E=make(30,true);w:openAH();E.Show("watch")
    w:advance(901);w:scan();W.Ensure();truth(W.job);E.frame:Hide()
    w:drain();W.AlertTick();equal(E.frame:IsShown(),false);equal(W.alertOpens,0)
end)
test("AH-entry-only alerts do not turn into after-scan alerts",function()
    local w,A,W,UI,E=make(1);local s=A.DB.Settings();s.watchOpenOnScan=false;s.watchOpenOnAH=true
    w:openAH();w:alert();equal(W.alertOpens,1);E.frame:Hide()
    later(w,{400});W.AlertTick();equal(W.alertOpens,1)
    close(w,E);w:openAH();w:alert();equal(W.alertOpens,2)
end)
test("scan-only alerts leave AH entry quiet and react to a completed scan",function()
    local w,A,W,UI,E=make(1);local s=A.DB.Settings();s.watchOpenOnScan=true;s.watchOpenOnAH=false;W.scanRequested=nil
    w:openAH();w:alert();equal(W.alertOpens,0)
    later(w);W.AlertTick();equal(W.alertOpens,1)
end)
test("watch editor cannot save into another market and combat blocks edits",function()
    local w,A,W,UI,E=make(1);E.Show("watch");UI.Edit(W.rows[1]);w.region=2;equal(UI.Save(),false)
    w.region=1;w.combat=true;equal(UI.Save(),false);equal(#W.Entries(),1)
end)
test("late item metadata updates names and rarity without restarting watch analysis",function()
    local w,A,W,UI,E=make(1);local watch=W.rows[1];watch.name="Item 100";watch.quality=nil;watch.watch.quality=nil
    w.items[100]={name="Ore",quality=4,commodity=true};local publications=W.publications
    for _=1,300 do W.OnItemInfo(100)end
    for _=1,20 do W.Tick()end
    equal(W.publications,publications);equal(watch.name,"Ore");equal(watch.quality,4);equal(W.job,nil)
    w.items[100]=nil;W.OnItemInfo(100);for _=1,20 do W.Tick()end;equal(watch.name,"Ore");equal(watch.quality,4)
end)
test("repeated item replies cannot recursively enqueue more watch metadata reads",function()
    local w,A,W,UI,E=make(1);local get=C_Item.GetItemInfo;local reads=0
    C_Item.GetItemInfo=function(item)reads=reads+1;W.OnItemInfo(100);return get(item)end
    W.OnItemInfo(100);for _=1,100 do W.Tick()end;equal(reads,1);equal(next(W.metadataPending),nil);equal(W.metadataJob,nil)
end)
test("older saved watch entries and an explicitly disabled alert preference survive upgrade",function()
    local w,A,W,UI,E=make(1);local saved=A.DB.data;saved.settings.watchAlerts=false
    saved.settings.watchOpenOnScan=nil;saved.settings.watchChatAlerts=nil
    local w2,B=fresh(saved);w2.wall=w.wall;w2:load()
    equal(B.DB.Settings().watchAlerts,false);equal(B.DB.Settings().watchOpenOnScan,true);equal(B.DB.Settings().watchChatAlerts,false)
    equal(B.Watchlist.Entries()[1].key,"100:*");equal(B.Watchlist.Entries()[1].entry.maxBuy,600)
end)
test("watch editor removal updates the list and never starts a native search",function()
    local w,A,W,UI,E=make(1);E.Show("watch");UI.Edit(W.rows[1]);click(UI.remove);w:drain();E.Refresh()
    equal(#W.Entries(),0);equal(#UI.View(),0);truth(UI.empty:IsShown());equal(w.requests,0)
end)
test("watch diagnostics report quiet preferences matched counts and popup totals",function()
    local w,A,W,UI,E=make(1);w:openAH();w:alert();local text=A.UI.DiagnosticsText()
    truth(text:find("Watchlist alerts: enabled=true; after_scan=true; AH_entry=true; chat=false; matched=1; batches=1; opened=1",1,true))
end)
test("automatic reviews wait for a native purchase confirmation to close",function()
    local w,A,W,UI,E=make(1);local ah=w:openAH();ah.BuyDialog=CreateFrame("Frame",nil,ah);ah.BuyDialog:Show()
    w:alert();equal(W.alertOpens,0);ah.BuyDialog:Hide();W.AlertTick();equal(W.alertOpens,1)
end)
test("automatic reviews reveal a new match hidden by an older search",function()
    local w,A,W,UI,E=make(2);w:openAH();E.Show("watch");UI.searchBox:SetText("Watch 002");E.frame:Hide()
    later(w,{400,800});W.AlertTick();equal(W.alertOpens,1);equal(UI.search,"");equal(UI.rows[1].row.id,100)
end)
