-- Filter changes after the client's item cache becomes unreadable must reuse
-- verified metadata rather than rediscovering it on each analysis pass.
local fresh,truth,equal=...
local w,A=fresh();w:load()
local count,unavailable,calls,replies=16000,false,0,0
local function item(id)
    local pants=id%100==0
    local title=pants and "Traveler Pants" or "Craft material"
    local payload="item:"..id..":0:0:0:0:0:0:0:40:0:0:0:"..(pants and "1:5661" or "0")
    return "|cff1eff00|H"..payload.."|h["..title.."]|h|r",title,pants
end
for day=1,4 do
    local s=A.DB.NewSnapshot(A.Util.MarketKey(),count,w.wall)
    for i=1,count do
        local id=100000+i;local link,name=item(id)
        A.DB.AddRow(s,id,4,day==4 and 400 or 4000,link,0,2,name)
    end
    truth(A.DB.Commit(s));if day<4 then w:advance(86400)end
end
C_Item.GetItemInfo=function(lookup)
    calls=calls+1
    if unavailable then return nil end
    local id=type(lookup)=="number" and lookup or A.Util.ItemID(lookup)
    local link,name,pants=item(id)
    return name..(pants and " of the Eagle" or ""),link,2,40,0,nil,nil,nil,nil,nil,nil,pants and 4 or 7
end
debugprofilestop=function()return os.clock()*1000 end
local start,maximum,frames=os.clock(),0,0
local function finish(view,sort)
    A.Market.Ensure(view,sort)
    repeat
        -- Independent event noise can continue after all useful data is known.
        for id=100100,101600,100 do A.Market.OnItemInfo(id);replies=replies+1 end
        local at=os.clock();A.Market.Tick();maximum=math.max(maximum,(os.clock()-at)*1000)
        A.Market.Ensure(view,sort);w.mono=w.mono+.016;frames=frames+1
        truth(frames<10000,"cache-loss workload did not finish")
    until not A.Market.job
end
finish("listed","return");equal(A.Market.eligible,count)
local warmCalls=calls;equal(A.MarketMetadata.cacheCount,count)
unavailable=true
for n,query in ipairs({"pants","pants eagle","eagle","not-present"})do
    A.DB.Settings().marketSearch=query;A.DB.Settings().marketQuality=n%2==0 and 4 or 63
    A.DB.Settings().marketStockMin=n%2==0 and 2 or 0
    local view=n%2==0 and "deals" or "listed";local sort=n%2==0 and "profit" or "return"
    local before=A.Market.builds;finish(view,sort)
    equal(A.Market.builds,before+1);equal(A.Market.eligible,query=="not-present" and 0 or 160)
    for _=1,60 do A.Market.Tick();A.Market.Ensure(view,sort) end
    equal(A.Market.builds,before+1);equal(A.Market.job,nil)
end
equal(calls,warmCalls);equal(A.Market.builds,5);equal(A.Market.publications,5);equal(w.requests,0)
print(string.format("MARKET_CACHE_BENCHMARK items=%d queries=4 builds=%d publications=%d native_reads_after_eviction=%d cache_entries=%d cache_hits=%d replies=%d frames=%d cpu_ms=%.2f max_step_ms=%.2f",count,A.Market.builds,A.Market.publications,calls-warmCalls,A.MarketMetadata.cacheCount,A.MarketMetadata.hits,replies,frames,(os.clock()-start)*1000,maximum))
