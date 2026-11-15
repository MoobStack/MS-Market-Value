-- User-sized cold/warm keyword workload. Measures the analysis, not native FPS.
local fresh,row,truth,equal=...
local w,A=fresh();w:load()
local count,days=16000,10
for day=1,days do
    local snapshot=A.DB.NewSnapshot(A.Util.MarketKey(),count,w.wall)
    for index=1,count do
        local id=100000+index
        local name=index%100==0 and ("Boots of the Owl " .. index) or ("Crafting material " .. index)
        w.items[id]=w.items[id] or {name=name,quality=2,classID=7}
        local entry=row(id,1,day==days and 400+index%100 or 1000+index%100)
        local full=entry.link:gsub("%[Test%]",function()return "[" .. name .. "]"end)
        A.DB.AddRow(snapshot,id,1,entry.buyout,full,0,2,name)
    end
    truth(A.DB.Commit(snapshot));if day<days then w:advance(86400)end
end
collectgarbage("collect");local before=collectgarbage("count")
debugprofilestop=function()return os.clock()*1000 end
local function run(query)
    A.DB.Settings().marketSearch=query
    local started,ticks,maximum=os.clock(),0,0
    A.Market.Ensure("listed","return")
    while A.Market.job do
        local tick=os.clock();A.Market.Tick()
        maximum=math.max(maximum,(os.clock()-tick)*1000);ticks=ticks+1
        truth(ticks<10000,"search must finish")
    end
    return (os.clock()-started)*1000,ticks,maximum
end
local cold,coldTicks,coldMax=run("");equal(A.Market.eligible,count)
local calls=w.itemCalls or 0
local warm,warmTicks,warmMax=run("of the");equal(A.Market.eligible,160);equal(#A.Market.rows,160)
local warmCalls=(w.itemCalls or 0)-calls
truth(warmCalls<=160,"unrelated names must not trigger item metadata calls")
for _,entry in ipairs(A.Market.rows)do truth(entry.name:find("of the",1,true))end
local empty,emptyTicks,emptyMax=run("no-such-keyword");equal(A.Market.eligible,0);equal(#A.Market.rows,0)
collectgarbage("collect")
print(string.format("SEARCH_BENCHMARK items=%d days=%d cold_cpu_ms=%.2f cold_ticks=%d cold_max_ms=%.2f warm_cpu_ms=%.2f warm_ticks=%d warm_max_ms=%.2f warm_metadata_calls=%d empty_cpu_ms=%.2f empty_ticks=%d empty_max_ms=%.2f analysis_retained_kib=%.0f requests=%d",
    count,days,cold,coldTicks,coldMax,warm,warmTicks,warmMax,warmCalls,empty,emptyTicks,emptyMax,collectgarbage("count")-before,w.requests))
