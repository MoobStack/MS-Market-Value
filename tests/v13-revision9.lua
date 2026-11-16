local fresh,row,link,test,equal,near,truth,secret=...
local function world()
    local w,A=fresh();w:load();return w,A
end
local function bonus(id,n,name)
    return "|cff1eff00|Hitem:"..id..":0:0:0:0:0:0:0:40:0:0:0:1:"..n.."|h["..name.."]|h|r"
end
local function scan(w,A,entries)
    local s=A.DB.NewSnapshot(A.Util.MarketKey(),#entries,w.wall)
    for _,r in ipairs(entries)do A.DB.AddRow(s,r.id,1,r.price or 100,r.link,0,r.quality,r.name)end
    truth(A.DB.Commit(s));return s
end
local function cycle(w,A,n,view,replies)
    for _=1,n do
        if replies then
            local ids={};for id in pairs(replies)do ids[#ids+1]=id;replies[id]=nil end
            for _,id in ipairs(ids)do w:event("GET_ITEM_INFO_RECEIVED",id,true) end
        end
        w:advance(.1);A.Market.Tick();A.Market.Ensure(view or "listed","return")
        A.Market.RequestVisibleInfo(A.Market.rows)
    end
end

test("filtered search retains resolved names when native reads alternate full and incomplete data",function()
    local w,A=world();local item=bonus(100,5661,"Imposing Pants");local replies={};local calls=0
    scan(w,A,{{id=100,link=item,quality=2}});A.DB.Settings().marketSearch="eagle"
    C_Item.GetItemInfo=function(lookup)
        calls=calls+1;replies[100]=true
        if calls%2==1 then return nil,lookup,nil,nil,nil,nil,nil,nil,nil,nil,nil,4 end
        return "Imposing Pants of the Eagle",lookup,2,nil,nil,nil,nil,nil,nil,nil,secret,4
    end
    A.Market.Ensure("listed","return");cycle(w,A,300,"listed",replies)
    if os.getenv("MSMV_REPLAY")=="1" then print("EVICTION_REPLAY frames=300 builds="..A.Market.builds.." publications="..A.Market.publications.." checking="..tostring(A.Market.job~=nil)) end
    equal(A.Market.job,nil);truth(A.Market.ready);equal(A.Market.builds,2);equal(A.Market.publications,2)
    equal(#A.Market.rows,1);equal(A.Market.rows[1].name,"Imposing Pants of the Eagle");equal(w.requests,0)
end)

test("learned modifier data survives keyword rarity and view changes after native eviction",function()
    local w,A=world();local item=bonus(100,5661,"Pants");local replies={};local ready=false
    scan(w,A,{{id=100,link=item,quality=2}});A.DB.Settings().marketSearch="eagle"
    C_Item.GetItemInfo=function(lookup)
        if ready then return "Pants of the Eagle",lookup,2,nil,nil,nil,nil,nil,nil,nil,nil,4 end
        replies[100]=true;return nil
    end
    A.Market.Ensure("listed","return");cycle(w,A,20,"listed",replies)
    ready=true;A.Market.OnItemInfo(100);cycle(w,A,20,"listed",replies)
    equal(#A.Market.rows,1);ready=false;local reads=A.MarketMetadata.reads
    for _,query in ipairs({"pants","eagle","of the","eagle"})do
        A.DB.Settings().marketSearch=query
        for _,mask in ipairs({4,63})do
            A.DB.Settings().marketQuality=mask;A.Market.Ensure("listed","return");cycle(w,A,20,"listed",replies)
            equal(#A.Market.rows,1);equal(A.Market.rows[1].name,"Pants of the Eagle");equal(A.Market.job,nil)
        end
    end
    A.Market.Ensure("deals","return");cycle(w,A,20,"deals",replies);equal(#A.Market.rows,0)
    A.Market.Ensure("listed","return");cycle(w,A,20,"listed",replies);equal(#A.Market.rows,1)
    equal(A.MarketMetadata.reads,reads);truth(A.MarketMetadata.hits>0)
end)

test("partial or throwing replies retain verified fields without manufacturing metadata changes",function()
    local _,A=world();local I=A.MarketMetadata;local item=bonus(100,5661,"Pants")
    C_Item.GetItemInfo=function(lookup)return "Pants of the Eagle",lookup,nil,nil,nil,nil,nil,nil,nil,nil,nil,4 end
    local original=I.Read(item);equal(original.quality,nil);equal(original.complete,false)
    I.Await(100,item,original,true)
    C_Item.GetItemInfo=function()return nil end
    I.OnItemInfo(100);I.Tick(A.Market);equal(I.changes,0);equal(I.unchanged,1)
    equal(I.Read(item).name,"Pants of the Eagle");truth(I.retained>0)
    C_Item.GetItemInfo=function()error("temporary native data failure")end
    equal(I.Read(item),original);equal(A.Market.metadataDirty,nil)
end)

test("partial native fields merge into one complete exact metadata record",function()
    local _,A=world();local I=A.MarketMetadata;local item=bonus(100,5661,"Pants")
    C_Item.GetItemInfo=function(lookup)return "Pants of the Eagle",lookup,nil,nil,nil,nil,nil,nil,nil,nil,nil,4 end
    local first=I.Read(item);equal(first.quality,nil)
    C_Item.GetItemInfo=function(lookup)return nil,lookup,2 end
    local second=I.Read(item);truth(second.complete);equal(second.name,"Pants of the Eagle");equal(second.classID,4)
    equal(second.quality,2);equal(first.quality,nil);equal(I.cacheCount,1)
    C_Item.GetItemInfo=function()error("complete cache should not query native data")end
    equal(I.Read(item),second)
end)

test("cached names and rarity still admit a later item class for history safeguards",function()
    local _,A=world();local I=A.MarketMetadata;local item=bonus(100,5661,"Pants")
    C_Item.GetItemInfo=function(lookup)return "Pants of the Eagle",lookup,2 end
    local first=I.Read(item);truth(first.complete);equal(first.classID,nil)
    C_Item.GetItemInfo=function(lookup)return "Pants of the Eagle",lookup,2,nil,nil,nil,nil,nil,nil,nil,nil,4 end
    local second=I.Read(item);equal(second.classID,4);equal(second.name,first.name);equal(first.classID,nil)
    local reads=I.reads;equal(I.Read(item),second);equal(I.reads,reads)
end)

test("metadata cache resets for a replacement snapshot or market and never enters saved variables",function()
    local w,A=world();local I=A.MarketMetadata;local item=bonus(100,5661,"Pants")
    local snapshot=scan(w,A,{{id=100,link=item,quality=2}})
    I.Begin(snapshot,A.Util.MarketKey())
    C_Item.GetItemInfo=function(lookup)return "Pants of the Eagle",lookup,2 end
    truth(I.Read(item));equal(I.cacheCount,1)
    local cache=I.cache;I.Begin(snapshot,A.Util.MarketKey());equal(I.cache,cache)
    I.Begin(snapshot,"another-market");equal(I.cacheCount,0)
    truth(I.Read(item));I.Begin({},"another-market");equal(I.cacheCount,0)
    truth(I.Read(item));A.Market.Clear("stale");equal(I.cacheCount,0)
    equal(A.DB.data.marketMetadata,nil);equal(A.DB.data.metadataCache,nil);equal(w.requests,0)
end)

test("cached names stay separate for bonus variants legacy suffixes and numeric item lookups",function()
    local _,A=world();local I=A.MarketMetadata
    local a,b=bonus(100,5661,"Pants"),bonus(100,5662,"Pants")
    C_Item.GetItemInfo=function(lookup)
        if type(lookup)=="number" then return "Pants",link(100),2 end
        local key=A.Util.VariantKey(lookup)
        return key=="100:0:b5661" and "Pants of the Eagle" or key=="100:0:b5662" and "Pants of the Bear" or "Pants of the Owl",lookup,2
    end
    equal(I.Read(a).name,"Pants of the Eagle");equal(I.Read(b).name,"Pants of the Bear")
    equal(I.Read(link(100,-5)).name,"Pants of the Owl");equal(I.Read(100).name,"Pants")
    equal(I.Read(a).name,"Pants of the Eagle");equal(I.cacheCount,4)
    equal(I.Read(a,"101:0:b5661"),nil)
    -- An ID-only reply cannot supply another bonus variant's name.
    local partial=I.Read(100,"100:0:b9999");equal(partial,nil)
end)

test("metadata cache has a hard bound and excess pending records cannot create an uncached rebuild loop",function()
    local _,A=world();local I=A.MarketMetadata
    C_Item.GetItemInfo=function(lookup)return "Pants",lookup,2 end
    for id=1,50010 do I.Read("item:"..id..":0:0:0:0:0:0:0") end
    equal(I.cacheCount,50000)
    I.Await(50010,"item:50010:0:0:0:0:0:0:0",nil,true)
    equal(I.count,0);equal(#I.order,0)
    truth(A.UI.DiagnosticsText():find("Market metadata cache: entries=50000/50000",1,true))
end)

test("incomplete item fields can arrive separately without repeatedly undoing prior progress",function()
    local w,A=world();local item=bonus(100,5661,"Pants");local replies={};local calls=0
    scan(w,A,{{id=100,link=item}});A.DB.Settings().marketSearch="eagle";A.DB.Settings().marketQuality=4
    C_Item.GetItemQualityByID=function()return nil end
    C_Item.GetItemInfo=function(lookup)
        calls=calls+1;replies[100]=true
        if calls%2==1 then return "Pants of the Eagle",lookup,nil,nil,nil,nil,nil,nil,nil,nil,nil,4 end
        return nil,lookup,2,nil,nil,nil,nil,nil,nil,nil,nil,4
    end
    A.Market.Ensure("listed","return");cycle(w,A,300,"listed",replies)
    equal(A.Market.job,nil);truth(A.Market.builds<=3);equal(#A.Market.rows,1)
    equal(A.Market.rows[1].name,"Pants of the Eagle");equal(A.Market.rows[1].quality,2)
end)
