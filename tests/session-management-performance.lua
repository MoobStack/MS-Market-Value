local fresh,link,truth,equal=...
local w,A=fresh();w:load();A.Farm.ConfigureIdle(false,5);A.Farm.SetHistoryLimit(50)
for id=1,500 do w.items[50000+id]={vendor=1,name="Stored item "..id} end
collectgarbage("collect");local before=collectgarbage("count");local start=os.clock()
for session=1,52 do
    for id=1,500 do truth(A.Farm.AddItem(link(50000+id),1,"loot")) end
    w:advance(60);A.Farm.Tick();truth(A.Farm.Reset())
end
local profile=A.Farm.Profile();equal(#profile.history,50)
local count=0
for _,record in ipairs(profile.history) do equal(#record.items,500);equal(#record.recent,20);count=count+#record.items end
equal(count,25000);collectgarbage("collect");local retained=collectgarbage("count")-before
truth(retained<32768,"Saved session detail exceeded 32 MiB in the fixture")
local w2,B=fresh(A.DB.data);w2.wall=w.wall
local loadStart=os.clock();w2:load(false);truth(B.Farm.Profile());local loadMs=(os.clock()-loadStart)*1000
equal(#B.Farm.Profile().history,50);truth(B.Farm.SetHistoryLimit(5));equal(#B.Farm.Profile().history,5)
print(string.format("SESSION_STORAGE_BENCHMARK saved=50 items=25000 recent_receipts=1000 retained_kib=%.2f cpu_ms=%.2f reload_ms=%.2f reduced_to=%d",
    retained,(os.clock()-start)*1000,loadMs,#B.Farm.Profile().history))
