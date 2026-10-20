local fresh,row,truth,equal = ...
local w,A=fresh();w:load()
for day=1,15 do
    local snapshot=A.DB.NewSnapshot(A.Util.MarketKey(),200,w.wall)
    for index=1,200 do A.DB.AddRow(snapshot,100000+index,1,day==15 and 500 or 1000,nil,0)end
    truth(A.DB.Commit(snapshot));if day<15 then w:advance(86400)end
end
A.DB.data.settings.watchAlerts=false
for index=1,200 do truth(A.Watchlist.Save(100000+index,600,20,100))end
debugprofilestop=function()return os.clock()*1000 end
local start,maxStep,steps=os.clock(),0,0
A.Watchlist.Ensure()
while A.Watchlist.job do
    local step=os.clock();A.Watchlist.Tick();maxStep=math.max(maxStep,(os.clock()-step)*1000);steps=steps+1
    truth(steps<1000)
end
local watchCPU=(os.clock()-start)*1000
equal(#A.Watchlist.rows,200);for _,watch in ipairs(A.Watchlist.rows)do truth(watch.matched)end
local pubs=A.Watchlist.publications
for _=1,100 do A.Watchlist.Ensure()end;equal(A.Watchlist.publications,pubs)
for index=1,2000 do truth(A.Ledger.Record({kind="sale",name="Benchmark item",quantity=1,amount=10000,fee=500,cost=index%2==0 and 4000 or nil}))end
local ledgerStart=os.clock();local records=A.Ledger.Records();local summary=A.Ledger.Summary()
for _=1,100 do equal(A.Ledger.Records(),records);equal(A.Ledger.Summary(),summary)end
local ledgerCPU=(os.clock()-ledgerStart)*1000
equal(#records,2000);equal(summary.unknown,1000);equal(w.requests,0)
print(string.format("ECONOMY_BENCHMARK watches=200 history_days=15 steps=%d watch_cpu_ms=%.2f max_step_ms=%.2f ledger_entries=2000 cached_view_cpu_ms=%.2f csv_bytes=%d requests=0",steps,watchCPU,maxStep,ledgerCPU,#A.Ledger.CSV()))
