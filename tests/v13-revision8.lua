local fresh,row,link,test,equal,near,truth,secret=...
local function world()
    local w,A=fresh();w:load();return w,A
end
local function named(id,name,suffix)
    return (link(id,suffix):gsub("%[Test%]",function()return "["..name.."]"end))
end
local function bonus(id,n,name)
    return "|cff1eff00|Hitem:"..id..":0:0:0:0:0:0:0:40:0:0:0:1:"..n.."|h["..name.."]|h|r"
end
local function scan(w,A,entries)
    local s=A.DB.NewSnapshot(A.Util.MarketKey(),#entries,w.wall)
    for _,r in ipairs(entries)do A.DB.AddRow(s,r.id,r.quantity or 1,r.buyout or 100,r.link,0,r.quality,r.name)end
    truth(A.DB.Commit(s));return s
end
local function finish(A)
    for _=1,10000 do if not A.Market.job then return end;A.Market.Tick() end
    error("search did not finish")
end
local function analyze(A,view)
    A.Market.Ensure(view or "listed","return");finish(A)
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

test("successful partial replies cannot keep an Opportunities search rebuilding",function()
    local w,A=world();local replies={}
    local item=bonus(100,5661,"Imposing Pants")
    scan(w,A,{{id=100,link=item,quality=2}});A.DB.Settings().marketSearch="pants eagle"
    local original=C_Item.GetItemInfo
    C_Item.GetItemInfo=function(lookup)
        replies[100]=true
        return "Imposing Pants of the Eagle",item,2,40,0,"Armor","Cloth",1,"INVTYPE_LEGS",1,secret,4,1
    end
    A.Market.Ensure("listed","return");cycle(w,A,200,"listed",replies)
    equal(A.Market.builds,1);equal(A.Market.publications,1);equal(A.Market.job,nil)
    equal(#A.Market.rows,1);equal(A.Market.rows[1].name,"Imposing Pants of the Eagle")
    equal(A.Market.rows[1].variantKey,"100:0:b5661");truth(A.Market.rows[1].needsHistory)
    equal(w.requests,0);C_Item.GetItemInfo=original
end)

test("unchanged unresolved replies leave published results ready and requests bounded",function()
    local w,A=world();local replies={}
    scan(w,A,{{id=100,link=bonus(100,5661,"Pants"),quality=2}});A.DB.Settings().marketSearch="of the eagle"
    C_Item.GetItemInfo=function()replies[100]=true;return nil end
    A.Market.Ensure("listed","return");cycle(w,A,200,"listed",replies)
    equal(A.Market.builds,1);equal(A.Market.publications,1);truth(A.Market.ready);equal(A.Market.job,nil)
    truth(A.MarketMetadata.unchanged>0);truth(A.MarketMetadata.reads<50)
    truth(w.loadRequests<=1);equal(w.requests,0)
end)

test("real name progress refreshes the result once and duplicate replies then settle",function()
    local w,A=world();local item=bonus(100,5661,"Pants")
    scan(w,A,{{id=100,link=item,quality=2}});A.DB.Settings().marketSearch="eagle"
    analyze(A);equal(#A.Market.rows,0)
    w.items[100]={name="Pants of the Eagle",quality=2,classID=4}
    local reads=A.MarketMetadata.reads
    for _=1,50 do A.Market.OnItemInfo(100) end
    equal(A.MarketMetadata.reads,reads);equal(A.Market.builds,1)
    cycle(w,A,60);equal(A.Market.builds,2);equal(#A.Market.rows,1)
    local builds=A.Market.builds
    for _=1,50 do A.Market.OnItemInfo(100) end
    cycle(w,A,60);equal(A.Market.builds,builds);equal(A.Market.job,nil)
end)

test("one item reply resolves its exact variants independently without sharing modifier names",function()
    local w,A=world();local a,b=bonus(100,5661,"Imposing Pants"),bonus(100,5662,"Imposing Pants")
    scan(w,A,{{id=100,link=a,quality=2},{id=100,link=b,quality=2}});A.DB.Settings().marketSearch="of the"
    analyze(A);equal(#A.Market.rows,0)
    C_Item.GetItemInfo=function(lookup)
        local eagle=A.Util.VariantKey(lookup)=="100:0:b5661"
        return "Imposing Pants of the "..(eagle and "Eagle" or "Bear"),lookup,2,nil,nil,nil,nil,nil,nil,nil,nil,4
    end
    w:event("GET_ITEM_INFO_RECEIVED",100,true);cycle(w,A,60)
    equal(A.Market.builds,2);equal(#A.Market.rows,2)
    local names={};for _,r in ipairs(A.Market.rows)do names[r.variantKey]=r.name end
    equal(names["100:0:b5661"],"Imposing Pants of the Eagle");equal(names["100:0:b5662"],"Imposing Pants of the Bear")
end)

test("base-item metadata cannot rename an exact modifier as a different variant",function()
    local _,A=world();local requested=bonus(100,5661,"Pants")
    C_Item.GetItemInfo=function()return "Pants of the Bear",bonus(100,5662,"Pants of the Bear"),2,nil,nil,nil,nil,nil,nil,nil,nil,4 end
    local info=A.MarketMetadata.Read(requested)
    equal(info.name,nil);equal(info.quality,nil);equal(info.complete,false)
end)

test("an unresolved modifier never borrows a different modifier title through the item-ID fallback",function()
    local w,A=world();local requested=bonus(100,5661,"Pants"):match("|H([^|]+)|h")
    scan(w,A,{{id=100,link=requested,quality=2}})
    C_Item.GetItemInfo=function()return "Pants of the Bear",bonus(100,5662,"Pants of the Bear"),2,nil,nil,nil,nil,nil,nil,nil,nil,4 end
    analyze(A);equal(#A.Market.rows,1)
    equal(A.Market.rows[1].variantKey,"100:0:b5661");equal(A.Market.rows[1].name:find("Bear",1,true),nil)
    truth(A.Market.rows[1].name:find("modifier details unavailable",1,true))
end)

test("a real reply during a multi-frame metadata check is not lost",function()
    local w,A=world();local entries={}
    for n=1,12 do entries[#entries+1]={id=100,link=bonus(100,5000+n,"Pants"),quality=2} end
    scan(w,A,entries);A.DB.Settings().marketSearch="eagle";analyze(A)
    local first=A.MarketMetadata.groups[100].records[1].lookup
    local ready=false
    C_Item.GetItemInfo=function(lookup)
        if ready and lookup==first then return "Pants of the Eagle",lookup,2,nil,nil,nil,nil,nil,nil,nil,nil,4 end
    end
    debugprofilestop=function()w.cpu=w.cpu+2;return w.cpu end
    A.Market.OnItemInfo(100);A.Market.Tick();truth(A.MarketMetadata.check)
    ready=true;A.Market.OnItemInfo(100)
    cycle(w,A,100);equal(#A.Market.rows,1);equal(A.Market.rows[1].name,"Pants of the Eagle")
    equal(A.Market.job,nil)
end)

test("a later unresolved modifier reopens an already resolved item-ID watch",function()
    local w,A=world();local I=A.MarketMetadata
    local a,b=bonus(100,5661,"Pants"),bonus(100,5662,"Pants")
    I.Await(100,a,nil,true)
    C_Item.GetItemInfo=function(lookup)return "Pants of the Eagle",lookup,2,nil,nil,nil,nil,nil,nil,nil,nil,4 end
    I.OnItemInfo(100);I.Tick(A.Market);truth(I.groups[100].resolved)
    A.Market.metadataDirty=nil
    I.Await(100,b,nil,true);equal(I.groups[100].resolved,false)
    I.OnItemInfo(100);w:advance(1.1);I.Tick(A.Market)
    truth(A.Market.metadataDirty);truth(I.groups[100].resolved)
end)

test("restricted or unrelated metadata never enters a search title or rarity",function()
    local w,A=world();local reads=w.itemCalls or 0
    equal(A.MarketMetadata.Read(secret),nil);equal(w.itemCalls or 0,reads)
    C_Item.GetItemInfo=function()return secret,link(100),secret,nil,nil,nil,nil,nil,nil,nil,secret,secret end
    equal(A.MarketMetadata.Read(link(100)),nil)
    C_Item.GetItemInfo=function()return "Different item",link(101),3,nil,nil,nil,nil,nil,nil,nil,nil,4 end
    equal(A.MarketMetadata.Read(link(100)),nil)
end)

test("stable visible rows do not requery item metadata on every quarter-second refresh",function()
    local w,A=world();w.items[100]={name="Rare Pants",quality=3}
    scan(w,A,{{id=100,link=named(100,"Rare Pants"),quality=3}});analyze(A)
    A.Market.RequestVisibleInfo(A.Market.rows);local reads=A.MarketMetadata.reads
    for _=1,100 do A.Market.RequestVisibleInfo(A.Market.rows) end
    equal(A.MarketMetadata.reads,reads);equal(A.Market.builds,1)
end)

test("pending exact-link lookups stay bounded even under a large missing-data search",function()
    local w,A=world();local entries={}
    for id=1,300 do for n=1,6 do entries[#entries+1]={id=id,link=bonus(id,5000+n,"Pants"),quality=2} end end
    scan(w,A,entries);A.DB.Settings().marketSearch="eagle";analyze(A)
    truth(#A.MarketMetadata.order<=256);truth(A.MarketMetadata.count<=1024)
    for _,id in ipairs(A.MarketMetadata.order)do truth(#A.MarketMetadata.groups[id].records>0);A.Market.OnItemInfo(id) end
    cycle(w,A,200);equal(A.Market.builds,1);equal(A.Market.job,nil);truth(w.loadRequests<=40)
end)

test("a changed search cancels stale pending names and unrelated replies cannot restart it",function()
    local w,A=world();scan(w,A,{{id=100,link=bonus(100,5661,"Pants"),quality=2},
        {id=101,link=named(101,"Cotton Thread"),quality=1}})
    A.DB.Settings().marketSearch="eagle";analyze(A)
    A.DB.Settings().marketSearch="thread";analyze(A);local builds=A.Market.builds
    for _=1,100 do A.Market.OnItemInfo(100);A.Market.OnItemInfo(99999) end
    cycle(w,A,40);equal(A.Market.builds,builds);equal(#A.Market.rows,1);equal(A.Market.rows[1].id,101)
end)

test("All items immediately shows pants modifiers while Resale waits for their own earlier days",function()
    local w,A=world();local entries={{id=100,link=bonus(100,5661,"Imposing Pants of the Eagle"),quality=2},
        {id=100,link=bonus(100,5662,"Imposing Pants of the Bear"),quality=2},
        {id=101,link=named(101,"Sorcerer Pants of the Owl",-5),quality=2}}
    -- Eleven item-wide days cannot establish prices for new modifier keys.
    for _=1,10 do
        local s=scan(w,A,{{id=100,link=named(100,"Imposing Pants"),quality=2},{id=101,link=named(101,"Sorcerer Pants"),quality=2}})
        s.variantFormat=nil;A.History.Days(A.Util.MarketInfo())[math.floor(w.wall/86400)].variantFormat=nil
        w:advance(86400)
    end
    scan(w,A,entries);A.DB.Settings().marketSearch="pants"
    analyze(A,"deals");equal(#A.Market.rows,0);equal(A.Market.coverage.needsHistory,3);equal(A.Market.coverage.matchingVariants,3)
    analyze(A,"listed");equal(#A.Market.rows,3)
    for _,r in ipairs(A.Market.rows)do equal(r.days,0);truth(r.needsHistory);truth(r.variantKey) end
    equal(A.Market.variantIndex.modifiers,3);equal(A.Market.variantIndex.count,3)
end)

test("three earlier exact days allow each qualifying pants modifier into Resale",function()
    local w,A=world();local a,b=bonus(100,5661,"Imposing Pants of the Eagle"),bonus(100,5662,"Imposing Pants of the Bear")
    for day=1,4 do
        scan(w,A,{{id=100,link=a,quality=2,buyout=day==4 and 100 or 1000},
            {id=100,link=b,quality=2,buyout=day==4 and 200 or 2000}})
        if day<4 then w:advance(86400) end
    end
    A.DB.Settings().marketSearch="pants";analyze(A,"deals");equal(#A.Market.rows,2)
    for _,r in ipairs(A.Market.rows)do equal(r.days,3);truth(r.deal) end
    equal(A.Market.coverage.needsHistory,0)
end)

test("same-day rescan adds no historical days and signal filters remain separate from browsing",function()
    local w,A=world();local entries={{id=100,link=bonus(100,5661,"Pants of the Eagle"),quality=2,buyout=1000}}
    for day=1,4 do scan(w,A,entries);if day<4 then w:advance(86400)end end
    scan(w,A,entries);A.DB.Settings().marketSearch="pants";analyze(A,"deals")
    equal(#A.Market.rows,0);equal(A.Market.coverage.needsHistory,0);equal(A.Market.coverage.filteredSignals,1)
    analyze(A,"listed");equal(#A.Market.rows,1);equal(A.Market.rows[1].days,3)
end)

test("diagnostics distinguish current modifier coverage history gaps and unchanged replies",function()
    local w,A=world();scan(w,A,{{id=100,link=bonus(100,5661,"Pants of the Eagle"),quality=2}})
    A.DB.Settings().marketSearch="pants";analyze(A,"deals");local text=A.UI.DiagnosticsText()
    truth(text:find('keyword="pants"',1,true));truth(text:find("current=1; modified=1",1,true))
    truth(text:find("need_history=1",1,true));truth(text:find("Market item replies:",1,true))
end)
