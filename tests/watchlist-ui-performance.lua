local fresh,link,truth,equal=...
local w,A=fresh();w:load();A.DB.Settings().watchAlerts=false
local snapshot=A.DB.NewSnapshot(A.Util.MarketKey(),200,w.wall)
for index=1,200 do
    local id=100000+index;w.items[id]={name=string.format("Watch %03d",index),quality=index%5}
    A.DB.AddRow(snapshot,id,5,2500,link(id),0)
end
truth(A.DB.Commit(snapshot))
for index=1,200 do truth(A.Watchlist.Save(100000+index,600,0,0))end
A.Watchlist.Ensure();while A.Watchlist.job do A.Watchlist.Tick()end
A.EconomyUI.Show("watch")
local UI,E,W=A.WatchUI,A.EconomyUI,A.Watchlist
local frames,publications,reads=w.createdFrames,W.publications,w.itemCalls
local view=UI.View();local start,maxStep=os.clock(),0
for index=1,200 do
    local step=os.clock();UI.Scroll(index%191);maxStep=math.max(maxStep,(os.clock()-step)*1000)
    equal(UI.View(),view)
end
for index=1,100 do E.Refresh();equal(UI.View(),view)end
equal(w.createdFrames,frames);equal(W.publications,publications);equal(w.itemCalls,reads)
for index=1,200 do
    UI.searchBox:SetText(string.format("Watch %03d",index));equal(#UI.View(),1)
end
UI.searchBox:SetText("");UI.Scroll(190);equal(UI.rows[10].row.id,100200)
equal(#UI.rows,10);equal(#UI.View(),200);equal(w.requests,0)
print(string.format("WATCHLIST_UI_BENCHMARK watches=200 visible_rows=10 scrolls=200 searches=200 new_frames=0 new_publications=0 metadata_reads_during_scroll=0 cpu_ms=%.2f max_scroll_ms=%.2f requests=0",(os.clock()-start)*1000,maxStep))
