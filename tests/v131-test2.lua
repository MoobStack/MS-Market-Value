local fresh,craftingWorld,craftRecipe,row,link,test,equal,near,truth,secret=...
local function world(saved,wall,active)
    local w,A=fresh(saved);w.wall=wall or w.wall
    w.dead,w.ghost=false,false
    UnitIsDeadOrGhost=function(unit)return unit=="player" and (w.dead or w.ghost)end
    LOOT_ITEM_SELF="You receive loot: %s.";LOOT_ITEM_SELF_MULTIPLE="You receive loot: %sx%d."
    YOU_LOOT_MONEY="You loot %s";GOLD_AMOUNT="%d Gold";SILVER_AMOUNT="%d Silver";COPPER_AMOUNT="%d Copper"
    w:load(false);A.Farm.ConfigureIdle(false,5)
    if active then truth(A.Farm.Pause(false)) end
    function w:tick(seconds)self:advance(seconds);A.Farm.Tick()end
    function w:loot(id,quantity)
        self:event("CHAT_MSG_LOOT","You receive loot: "..link(id)..(quantity and ("x"..quantity) or "")..".")
    end
    return w,A
end
local function saves(w,A,count)
    A.Farm.Pause(false)
    for i=1,count do truth(A.Farm.AddMoney(i*100,false));w:tick(60);truth(A.Farm.Reset())end
end
local function items(w,A,count)
    for id=1,count do
        w.items[5000+id]={vendor=id,name="Saved item "..id}
        truth(A.Farm.AddItem(link(5000+id),2,id%2==0 and "skinning" or "loot"))
    end
end
local function recipes(count)
    local w,A=craftingWorld();w.recipeIDs={}
    for id=1,count do w.recipeIDs[id]=id;w.recipes[id]=craftRecipe(id,200) end
    A.Crafting.Invalidate()
    for _=1,30 do A.Crafting.Tick();if A.Crafting.ready then break end end
    truth(A.Crafting.ready);A.DB.Settings().showAllRecipes=true
    A.CraftingUI.mode="profit";A.CraftingUI.Refresh()
    return w,A,A.CraftingUI
end

test("login idle excludes all waiting time even with inactivity pause disabled",function()
    local w,A=world();equal(A.Farm.Summary().idleReason,"login");truth(A.Farm.Summary().paused)
    w:tick(600);near(A.Farm.Elapsed(),0);equal(A.Farm.Profile().current.paused,false)
    truth(A.Farm.Pause(false));w:tick(60);near(A.Farm.Elapsed(),60);equal(A.Farm.Summary().idlePaused,false)
end)

test("entering combat starts a login-idle timer at the combat event",function()
    local w,A=world();w:tick(600);w.combat=true;w:event("PLAYER_REGEN_DISABLED")
    near(A.Farm.Elapsed(),0);equal(A.Farm.Summary().idleReason,nil)
    w:tick(60);near(A.Farm.Elapsed(),60)
end)

test("received item loot starts a login-idle timer without charging earlier waiting",function()
    local w,A=world();w.items[100]={vendor=50};w:tick(600);w:loot(100,2);w:tick(2)
    equal(A.Farm.Summary().total,100);near(A.Farm.Elapsed(),2);equal(A.Farm.Summary().idlePaused,false)
end)

test("received gold starts login idle while wallet vendor and mail changes do not",function()
    local w,A=world();w:tick(600);w:event("PLAYER_MONEY");w:event("MERCHANT_SHOW")
    w:event("CHAT_MSG_MONEY","You loot 1 Gold");w:event("MERCHANT_CLOSED");w:tick(3)
    w:event("MAIL_SHOW");w:event("CHAT_MSG_MONEY","You loot 1 Gold");w:event("MAIL_CLOSED");w:tick(3)
    near(A.Farm.Elapsed(),0);equal(A.Farm.Summary().total,0);truth(A.Farm.Summary().idlePaused)
    w:event("CHAT_MSG_MONEY","You loot 1 Silver");w:tick(60)
    near(A.Farm.Elapsed(),60);equal(A.Farm.Summary().coins,100)
end)

test("quest totals can be recorded during login idle without starting farming time",function()
    local w,A=world();w.items[100]={vendor=50};w:tick(600)
    w:event("QUEST_COMPLETE");w:event("QUEST_TURNED_IN",42,100,200);w:event("QUEST_LOOT_RECEIVED",42,link(100),1)
    w:event("QUEST_FINISHED");w:tick(60)
    equal(A.Farm.Summary().total,250);near(A.Farm.Elapsed(),0);equal(A.Farm.Summary().idleReason,"login")
    near(A.Farm.Summary().peak.rate,0)
end)

test("login idle preserves metrics and manual pauses through reload",function()
    local w,A=world(nil,nil,true);A.Farm.AddMoney(100,false);w:tick(300)
    local elapsed=A.Farm.Elapsed();local peak=A.Farm.Summary().peak.rate
    local w2,B=world(A.DB.data,w.wall+5000);w2:tick(300)
    near(B.Farm.Elapsed(),elapsed);near(B.Farm.Summary().peak.rate,peak);equal(B.Farm.Summary().total,100)
    B.Farm.Pause(true);local w3,C=world(B.DB.data,w2.wall+100)
    w3.combat=true;w3:event("PLAYER_REGEN_DISABLED");w3:tick(60);w3:loot(100);w3:tick(2)
    near(C.Farm.Elapsed(),elapsed);equal(C.Farm.Summary().total,100);truth(C.Farm.Profile().current.paused)
end)

test("ordinary loading screens do not rearm login idle or add loading time",function()
    local w,A=world(nil,nil,true);w:tick(60);w:event("PLAYER_LEAVING_WORLD");w:tick(5000)
    w:event("PLAYER_ENTERING_WORLD");w:tick(30)
    near(A.Farm.Elapsed(),90);equal(A.Farm.Summary().idlePaused,false)
end)

test("death and ghost time pause farming and resurrection alone does not resume",function()
    local w,A=world(nil,nil,true);w:tick(60);w.dead=true;w:event("PLAYER_DEAD");w:tick(300)
    truth(A.Farm.Summary().dead);near(A.Farm.Elapsed(),60);equal(A.Farm.Pause(false),false)
    w.dead=false;w.ghost=true;w:event("PLAYER_ALIVE");w:tick(300)
    truth(A.Farm.Summary().dead);near(A.Farm.Elapsed(),60)
    w.ghost=false;w:event("PLAYER_UNGHOST");w:tick(300)
    equal(A.Farm.Summary().dead,false);equal(A.Farm.Summary().idleReason,"death");near(A.Farm.Elapsed(),60)
    truth(A.Farm.Pause(false));w:tick(60);near(A.Farm.Elapsed(),120)
end)

test("post-resurrection combat and loot resume a death pause at the new activity",function()
    for _,kind in ipairs({"combat","loot"}) do
        local w,A=world(nil,nil,true);w.items[100]={vendor=50};w:tick(60)
        w.dead=true;w:event("PLAYER_DEAD");w:tick(120);w.dead=false;w:event("PLAYER_UNGHOST");w:tick(120)
        if kind=="combat" then w.combat=true;w:event("PLAYER_REGEN_DISABLED") else w:loot(100)end
        w:tick(60);near(A.Farm.Elapsed(),120);equal(A.Farm.Summary().idlePaused,false)
    end
end)

test("combat and loot while dead cannot restart the death-paused calculator",function()
    local w,A=world(nil,nil,true);w.items[100]={vendor=50};w:tick(60);w.dead=true;w:event("PLAYER_DEAD")
    w.combat=true;w:event("PLAYER_REGEN_DISABLED");w:loot(100);w:event("CHAT_MSG_MONEY","You loot 1 Silver");w:tick(300)
    near(A.Farm.Elapsed(),60);equal(A.Farm.Summary().total,0);truth(A.Farm.Summary().idlePaused)
end)

test("manual pause survives death resurrection and subsequent combat",function()
    local w,A=world(nil,nil,true);w:tick(60);A.Farm.Pause(true)
    w.dead=true;w:event("PLAYER_DEAD");w.dead=false;w:event("PLAYER_UNGHOST")
    w.combat=true;w:event("PLAYER_REGEN_DISABLED");w:tick(120)
    near(A.Farm.Elapsed(),60);truth(A.Farm.Profile().current.paused);equal(A.Farm.Summary().idlePaused,false)
end)

test("death pause is optional and disabling it retains all elapsed time",function()
    local w,A=world(nil,nil,true);truth(A.Farm.ConfigureDeath(false));w:tick(60)
    w.dead=true;w:event("PLAYER_DEAD");w:advance(120);w.dead=false;w:event("PLAYER_UNGHOST")
    near(A.Farm.Elapsed(),180);equal(A.Farm.Summary().idlePaused,false)
    local _,B=world(A.DB.data,w.wall);equal(B.DB.Settings().farmPauseOnDeath,false)
    equal(B.Farm.Summary().idleReason,"login")
end)

test("logging in dead waits through resurrection and already active combat resumes login idle",function()
    local w,A=fresh();UnitIsDeadOrGhost=function()return true end;w:load(false)
    equal(A.Farm.Summary().idleReason,"death");equal(A.Farm.Pause(false),false)
    local w2,B=fresh();w2.combat=true;w2:load(false);w2:advance(30);B.Farm.Tick()
    near(B.Farm.Elapsed(),30);equal(B.Farm.Summary().idlePaused,false)
end)

test("session retention defaults to five and can keep the newest fifty",function()
    local w,A=world();equal(A.Farm.HistoryLimit(),5);truth(A.Farm.SetHistoryLimit(50));saves(w,A,53)
    local h=A.Farm.Profile().history;equal(#h,50);equal(h[1].total,5300);equal(h[50].total,400)
    local _,B=world(A.DB.data,w.wall);equal(#B.Farm.Profile().history,50);equal(B.Farm.HistoryLimit(),50)
end)

test("retention zero stops saving and reductions keep only the newest records",function()
    local w,A=world();saves(w,A,5);A.Farm.AddMoney(99,false)
    truth(A.Farm.SetHistoryLimit(2));local h=A.Farm.Profile().history
    equal(#h,2);equal(h[1].total,500);equal(h[2].total,400);equal(A.Farm.Summary().total,99)
    truth(A.Farm.SetHistoryLimit(0));equal(#h,0);w:tick(60);truth(A.Farm.Reset());equal(#h,0)
    truth(A.Farm.SetHistoryLimit(5));saves(w,A,1);equal(#h,1)
end)

test("invalid retention choices cannot erase saved sessions",function()
    local w,A=world();saves(w,A,3)
    for _,v in ipairs({-1,51,2.5,"2",secret})do equal(A.Farm.SetHistoryLimit(v),false);equal(#A.Farm.Profile().history,3)end
    equal(A.Farm.HistoryLimit(),5)
end)

test("session limits and deletion stay local to the current character and market",function()
    local w,A=world();w.realm="CAMWOWUS2Realm8PvP";A.Farm.SetHistoryLimit(20);saves(w,A,4);local first=A.Farm.Profile();local original=w.guid
    w.guid="Player-1-second";equal(A.Farm.HistoryLimit(),5);saves(w,A,2);local second=A.Farm.Profile()
    A.Farm.SetHistoryLimit(1);equal(#second.history,1);equal(#first.history,4);equal(first.historyLimit,20)
    w.guid=original;equal(A.Farm.HistoryLimit(),20);A.Farm.DeleteSession(first.history[1]);equal(#second.history,1)
    w.faction="Alliance";equal(A.Farm.HistoryLimit(),5);equal(#A.Farm.Profile().history,0)
end)

test("deleting an exact saved session preserves other records and the current session",function()
    local w,A=world();saves(w,A,4);A.Farm.AddMoney(99,false)
    local p=A.Farm.Profile();local target=p.history[2];local newest=p.history[1];local current=p.current
    truth(A.Farm.DeleteSession(target));equal(#p.history,3);equal(p.history[1],newest)
    equal(p.current,current);equal(A.Farm.Summary().total,99)
    equal(A.Farm.DeleteSession(target),false);equal(A.Farm.DeleteSession(current),false)
    local _,B=world(A.DB.data,w.wall);equal(#B.Farm.Profile().history,3)
end)

test("new saved sessions retain full item detail and recent receipts as independent snapshots",function()
    local w,A=world(nil,nil,true);items(w,A,35);w:tick(60);local s=A.Farm.Summary();local total=s.total
    truth(A.Farm.Reset());local h=A.Farm.Profile().history[1]
    equal(#h.items,35);equal(#h.top,10);equal(#h.recent,20);equal(h.total,total)
    truth(h.items[1].link);equal(h.items[1].unit,35)
    A.Farm.AddMoney(99,false);equal(h.total,total);equal(#h.recent,20)
    local _,B=world(A.DB.data,w.wall);equal(#B.Farm.Profile().history[1].items,35)
end)

test("older saved top-item summaries remain readable without invented item detail",function()
    local w,A=world();saves(w,A,1);local h=A.Farm.Profile().history[1];h.items,h.recent=nil,nil
    local _,B=world(A.DB.data,w.wall);local ui=B.FarmingUI;ui.Show("session");ui.SelectSession(1)
    truth(ui.breakdownTitle.text:find("top items only",1,true));equal(ui.recentButton.enabled,false)
    equal(ui.total.text,B.Util.Coins(100));equal(B.Farm.Profile().history[1].items,nil)
end)

test("corrupt or oversized saved item detail is preserved instead of silently discarded",function()
    for _,kind in ipairs({"restricted","quantity","oversized"})do
        local w,A=world();saves(w,A,1);local record=A.Farm.Profile().history[1]
        local entry={name="Item",quantity=1,total=100,link=link(100),source="loot"}
        if kind=="restricted" then record.items=secret
        elseif kind=="quantity" then entry.quantity=-1;record.items={entry}
        else record.items={};for i=1,501 do record.items[i]=entry end end
        local _,B=world(A.DB.data,w.wall);equal(B.Farm.Profile(),nil);truth(record.items~=nil)
    end
end)

test("session limit reduction requires confirmation and preserves the running session",function()
    local w,A=world();saves(w,A,4);A.Farm.AddMoney(99,false)
    local ui=A.FarmingUI;ui.Show("session");ui.ManageSessions();ui.historyLimit:SetFocus();ui.historyLimit:SetText("2")
    ui.applyHistory.scripts.OnClick();equal(#A.Farm.Profile().history,4);truth(ui.applyHistory.text:find("Confirm",1,true))
    ui.applyHistory.scripts.OnClick();equal(#A.Farm.Profile().history,2);equal(A.Farm.Summary().total,99)
end)

test("a changed retention request or new saved session invalidates the old confirmation",function()
    local w,A=world();saves(w,A,4);local ui=A.FarmingUI;ui.Show("session");ui.ManageSessions()
    ui.historyLimit:SetFocus();ui.historyLimit:SetText("2");ui.ApplyHistoryLimit();ui.historyLimit:SetText("1");ui.ApplyHistoryLimit()
    equal(#A.Farm.Profile().history,4);equal(ui.confirmLimit.value,1)
    A.Farm.AddMoney(500,false);w:tick(60);truth(A.Farm.Reset());ui.ApplyHistoryLimit();equal(#A.Farm.Profile().history,5)
    ui.ApplyHistoryLimit();equal(#A.Farm.Profile().history,1)
end)

test("individual deletion confirms the selected record even after its index shifts",function()
    local w,A=world();saves(w,A,3);local ui=A.FarmingUI;ui.Show("session");ui.SelectSession(1);ui.ManageSessions()
    local target=ui.historyRecord;ui.deleteSession.scripts.OnClick();equal(#A.Farm.Profile().history,3)
    A.Farm.AddMoney(400,false);w:tick(60);A.Farm.Reset();ui.Refresh();equal(ui.historyRecord,target);equal(ui.historyIndex,2)
    ui.deleteSession.scripts.OnClick();equal(#A.Farm.Profile().history,3);equal(A.Farm.Profile().history[1].total,400)
    equal(ui.historyRecord,nil);equal(ui.deleteSession.enabled,false)
end)

test("closing session management cancels pending deletion and current cannot be deleted",function()
    local w,A=world();saves(w,A,1);local ui=A.FarmingUI;ui.Show("session");ui.ManageSessions()
    equal(ui.deleteSession.enabled,false);ui.SelectSession(1);ui.deleteSession.scripts.OnClick()
    ui.manager:Hide();ui.ManageSessions();equal(ui.confirmDelete,nil);equal(#A.Farm.Profile().history,1)
    ui.deleteSession.scripts.OnClick();equal(#A.Farm.Profile().history,1)
end)

test("saved session menus are scrollable and retain direct current-session access",function()
    local w,A=world();A.Farm.SetHistoryLimit(50);saves(w,A,40);local ui=A.FarmingUI;ui.Show("session");ui.sessionMenu:OpenMenu()
    equal(#ui.sessionMenu.menuDescription.items,41);equal(ui.sessionMenu.menuDescription.scrollHeight,300)
    ui.sessionMenu:Pick(40);equal(ui.total.text,A.Util.Coins(100));ui.currentButton.scripts.OnClick();equal(ui.historyIndex,0)
end)

test("farming items scroll to every row with aligned quantity and value details",function()
    local w,A=world(nil,nil,true);items(w,A,35);local ui=A.FarmingUI;ui.Show("session")
    local all=ui.visibleItems;equal(#all,35);equal(#ui.rows,12);equal(ui.rows[1].item,all[1])
    equal(ui.rows[1].quantity.text,2);equal(ui.rows[1].unit.text,A.Util.Coins(35));equal(ui.rows[1].total.text,A.Util.Coins(70))
    ui.list.scripts.OnMouseWheel(ui.list,-1);equal(ui.offset,3);equal(ui.rows[1].item,all[4])
    ui.scrollbar:SetValue(999);equal(ui.offset,23);equal(ui.rows[12].item,all[35])
    ui.Scroll(-99);equal(ui.offset,0);equal(ui.prev,nil);equal(ui.next,nil)
end)

test("scrolling recent pickups and source filters never loses the session context",function()
    local w,A=world(nil,nil,true);items(w,A,35);w:tick(60);A.Farm.Reset()
    local ui=A.FarmingUI;ui.Show("session");ui.SelectSession(1);local record=ui.historyRecord
    ui.recentButton.scripts.OnClick();equal(ui.historyRecord,record);equal(#ui.visibleItems,20)
    ui.Scroll(99);equal(ui.offset,8);equal(ui.rows[12].item,record.recent[20])
    ui.itemsButton.scripts.OnClick();equal(ui.offset,0);equal(#ui.visibleItems,35)
    ui.source="quest";ui.Refresh();equal(#ui.visibleItems,0);equal(ui.offset,0);truth(ui.empty:IsShown())
    equal(ui.rows[1]:IsShown(),false);equal(ui.historyRecord,record)
end)

test("session layout fits twelve rows and retains all summary and management controls",function()
    local w,A=world(nil,nil,true);items(w,A,35);local ui=A.FarmingUI;ui.Show("session")
    truth(ui.frame.height<=700);equal(#ui.metricValues,4);equal(#ui.categoryTotals,3)
    truth(-ui.rows[12].points[1][5]+ui.rows[12].height<ui.list.height)
    truth(-ui.list.points[1][5]+ui.list.height < -ui.note.points[1][5]);truth(ui.manageButton)
    ui.Show("settings");ui.deathCheck:SetChecked(false);ui.deathCheck.scripts.OnClick(ui.deathCheck);equal(A.DB.Settings().farmPauseOnDeath,false)
    ui.Show("session");ui.rows[1].scripts.OnEnter(ui.rows[1]);truth(GameTooltip:IsShown());ui.Scroll(3);equal(GameTooltip:IsShown(),false)
end)

test("recipe list scrolls by wheel and scrollbar without page buttons",function()
    local _,A,ui=recipes(35);local all=ui.CatalogView();local publications=A.Crafting.publications;equal(#ui.catalogRows,11)
    ui.list.scripts.OnMouseWheel(ui.list,-1);equal(ui.offset,3);equal(ui.catalogRows[1].row,all[4])
    ui.scrollbar:SetValue(999);equal(ui.offset,24);equal(ui.catalogRows[11].row,all[35])
    ui.Scroll(-999);equal(ui.offset,0);equal(ui.previous,nil);equal(ui.next,nil)
    truth(ui.listCount.text:find("35 recipes",1,true));equal(A.Crafting.publications,publications)
end)

test("scrolling recipes reuses valuations and clicking selects the visible recipe",function()
    local w,A,ui=recipes(35);local builds,requests=A.Crafting.builds,w.requests
    local valuations=0;local native=C_TradeSkillUI.GetRecipeSchematic
    C_TradeSkillUI.GetRecipeSchematic=function(...)valuations=valuations+1;return native(...)end
    for _=1,10 do ui.Scroll(0);ui.Scroll(20)end
    equal(valuations,0);equal(A.Crafting.builds,builds);equal(w.requests,requests)
    local selected=ui.catalogRows[1].recipeID;ui.catalogRows[1].scripts.OnClick(ui.catalogRows[1]);equal(w.selectedID,selected);equal(ui.mode,"recipe")
end)

test("recipe searches filters and sorting reset and clamp the scroll position",function()
    local _,A,ui=recipes(35);ui.Scroll(20);ui.SetSearch("Recipe 35");equal(ui.offset,0);equal(ui.catalogRows[1].recipeID,35)
    equal(ui.catalogRows[2].recipeID,nil);equal(ui.scrollbar.enabled,false)
    ui.SetSearch("no match");truth(ui.empty:IsShown());equal(ui.offset,0)
    ui.SetSearch("");ui.Scroll(20);ui.sortReturn.scripts.OnClick();equal(ui.offset,0)
    ui.Scroll(20);ui.showAllButton.scripts.OnClick();equal(ui.offset,0)
    equal(A.DB.Settings().showAllRecipes,false)
end)

test("both scrolling lists ignore unreadable offsets and keep rows inside their tables",function()
    local w,A=world(nil,nil,true);items(w,A,20);A.FarmingUI.Show("session");A.FarmingUI.Scroll(secret);equal(A.FarmingUI.offset,0)
    local _,_,ui=recipes(35);ui.Scroll(secret);equal(ui.offset,0)
    local last=ui.catalogRows[11];truth(-last.points[1][5]+last.height < -ui.listCount.points[1][5])
    truth(last.width+last.points[1][4]<ui.list.width-20)
end)
