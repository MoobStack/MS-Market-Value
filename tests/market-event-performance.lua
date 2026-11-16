-- Native-style success replies can repeat without making vendor data readable.
local fresh,truth,equal,secret=...
local w,A=fresh();w:load()
local count,days,replies=16000,10,{}
local function item(id)
    local title=id%100==0 and "Traveler Pants" or "Craft material"
    local payload="item:"..id..":0:0:0:0:0:0:0:40:0:0:0:"..(id%100==0 and "1:5661" or "0")
    return "|cff1eff00|H"..payload.."|h["..title.."]|h|r",title
end
for day=1,days do
    local s=A.DB.NewSnapshot(A.Util.MarketKey(),count,w.wall)
    for i=1,count do
        local id=100000+i;local link,name=item(id)
        A.DB.AddRow(s,id,1,day==days and 100 or 1000,link,0,2,name)
    end
    truth(A.DB.Commit(s));if day<days then w:advance(86400)end
end
C_Item.GetItemInfo=function(lookup)
    local id=type(lookup)=="number" and lookup or A.Util.ItemID(lookup)
    local link,name=item(id);replies[id]=true
    return name..(id%100==0 and " of the Eagle" or ""),link,2,40,0,nil,nil,nil,nil,nil,secret,id%100==0 and 4 or 7
end
debugprofilestop=function()return os.clock()*1000 end
local before=os.clock();local frames,maximum,delivered=0,0,0
for _,query in ipairs({"pants","pants eagle","of the eagle","not-present"})do
    A.DB.Settings().marketSearch=query;local builds=A.Market.builds
    A.Market.Ensure("listed","return")
    local quiet=0
    repeat
        local ids={};for id in pairs(replies)do ids[#ids+1]=id;replies[id]=nil end
        for _,id in ipairs(ids)do A.Market.OnItemInfo(id);delivered=delivered+1 end
        local at=os.clock();A.Market.Tick();maximum=math.max(maximum,(os.clock()-at)*1000)
        A.Market.Ensure("listed","return")
        local visible={};for i=1,math.min(12,#A.Market.rows)do visible[#visible+1]=A.Market.rows[i]end
        A.Market.RequestVisibleInfo(visible);w.mono=w.mono+.016;frames=frames+1
        quiet=A.Market.job and 0 or quiet+1
        truth(frames<10000,"repeated metadata must not keep analysis running")
    until quiet>=60
    equal(A.Market.builds,builds+1);equal(A.Market.eligible,query=="not-present" and 0 or 160)
end
equal(A.Market.builds,4);equal(A.Market.publications,4);equal(w.requests,0)
print(string.format("MARKET_EVENT_BENCHMARK items=%d days=%d queries=4 builds=%d publications=%d replies=%d frames=%d cpu_ms=%.2f max_step_ms=%.2f requests=%d",count,days,A.Market.builds,A.Market.publications,delivered,frames,(os.clock()-before)*1000,maximum,w.requests))
