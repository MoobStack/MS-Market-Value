local _, A = ...
local U = A.Util
local I={reads=0,replies=0,changes=0,unchanged=0,hits=0,retained=0}
A.MarketMetadata=I
local MAX_IDS,MAX_RECORDS,MAX_CACHE=256,1024,50000

local function CacheKey(id,lookup,variantKey)
    local variant=variantKey or U.VariantKey(lookup)
    if variant and U.SplitVariant(variant)~=id then return nil end
    return variant or ("id:"..id),variant
end

-- Native item data can be evicted while a large snapshot is being read.
-- Keep verified fields for this snapshot across automatic rebuilds and filter
-- changes. Missing/partial replies never erase fields already obtained.
local function Retain(key,name,quality,classID)
    local previous=I.cache[key]
    name=U.ItemName(nil,name,previous and previous.name)
    quality=previous and previous.quality~=nil and previous.quality or quality
    classID=previous and previous.classID or classID
    if not name and quality==nil and classID==nil then return nil end
    if previous and previous.name==name and previous.quality==quality and previous.classID==classID then return previous end
    local info={name=name,quality=quality,classID=classID,complete=name~=nil and quality~=nil}
    if previous or I.cacheCount<MAX_CACHE then
        if not previous then I.cacheCount=I.cacheCount+1 end
        I.cache[key]=info
    end
    return info
end

-- Ranking needs a name, rarity and item class. Vendor/equip data can be
-- unavailable even after a successful item reply and must not block a search.
function I.Read(lookup,variantKey)
    local numeric=U.Number(lookup,1,2147483647,true)
    local id=numeric and lookup or (U.String(lookup) and #lookup<=2048 and U.ItemID(lookup))
    if not id then return nil end
    local key=CacheKey(id,lookup,variantKey)
    if not key then return nil end
    local cached=I.cache[key]
    if cached and cached.complete and cached.classID~=nil then I.hits=I.hits+1;return cached end
    if not C_Item or type(C_Item.GetItemInfo)~="function" then return cached end
    I.reads=I.reads+1;I.reading=true
    local r={pcall(C_Item.GetItemInfo,lookup)}
    I.reading=false
    if not r[1] then return cached end
    local sameItem=U.String(r[3]) and U.ItemID(r[3])==id
    local exact=sameItem and not variantKey and (numeric or r[3]==lookup)
    if sameItem and not exact then
        local requested=variantKey or U.VariantKey(lookup)
        exact=requested and U.VariantKey(r[3])==requested
    end
    local name=exact and U.String(r[2]) and #r[2]>0 and #r[2]<=256 and r[2] or nil
    local quality=exact and U.Number(r[4],0,8,true) and r[4] or nil
    local classID=sameItem and U.Number(r[13],0,100,true) and r[13] or nil
    if cached and ((cached.name and not name) or (cached.quality~=nil and quality==nil) or
        (cached.classID~=nil and classID==nil)) then I.retained=I.retained+1 end
    return Retain(key,name,quality,classID)
end

function I.Begin(snapshot,market)
    if not I.cache or I.snapshot~=snapshot or I.market~=market then
        I.cache,I.cacheCount={},0;I.snapshot,I.market=snapshot,market
    end
    I.groups,I.order,I.pending,I.count,I.cursor,I.check={},{},{},0,1,nil
end
I.Begin()

function I.Await(id,lookup,info,analysis,variantKey)
    if not U.Number(id,1,2147483647,true) then return end
    if not (U.Number(lookup,1,2147483647,true) or
        (U.String(lookup) and #lookup<=2048 and U.ItemID(lookup))) then return end
    local cacheKey,variant=CacheKey(id,lookup,variantKey)
    if not cacheKey or not I.cache[cacheKey] and I.cacheCount>=MAX_CACHE then return end
    local group=I.groups[id]
    if not group then
        if #I.order>=MAX_IDS or I.count>=MAX_RECORDS then return end
        group={records={},byKey={}};I.groups[id]=group;I.order[#I.order+1]=id
    end
    local key=variant or tostring(id)
    local record=group.byKey[key]
    if not record then
        if I.count>=MAX_RECORDS then return end
        record={lookup=lookup,variantKey=variant,info=info,analysis=analysis==true}
        group.byKey[key]=record;group.records[#group.records+1]=record;I.count=I.count+1
        group.resolved,group.requested=false,nil
    elseif analysis then record.analysis=true end
end

function I.OnItemInfo(id)
    local group=I.groups and I.groups[id]
    if I.reading or not group or group.resolved then return end
    I.replies=I.replies+1
    group.received=true
    -- Coalesce a burst into one deferred read. No API calls in the callback.
    if group.checking then group.again=true else I.pending[id]=true end
end

function I.Request()
    local count=#I.order
    for _=1,math.min(20,count) do
        local id=I.order[I.cursor];I.cursor=I.cursor%count+1
        local group=I.groups[id]
        if not group.requested and not group.resolved then
            group.requested=A.Drops.RequestName(id)==true
        end
    end
end

local function Same(a,b)
    return (a and a.name)==(b and b.name) and (a and a.quality)==(b and b.quality) and
        (a and a.classID)==(b and b.classID)
end

function I.Tick(market)
    if not I.pending then return false end
    local start=debugprofilestop and debugprofilestop() or 0
    for _=1,8 do
        if not I.check then
            local now=U.Mono()
            for id in pairs(I.pending) do
                local group=I.groups[id]
                if not group or group.resolved then I.pending[id]=nil
                elseif not group.quietUntil or now>=group.quietUntil then
                    I.pending[id]=nil;group.checking=true
                    I.check={id=id,group=group,cursor=1,resolved=true};break
                end
            end
        end
        local check=I.check
        if not check then return false end
        local record=check.group.records[check.cursor]
        local info=I.Read(record.lookup,record.variantKey)
        if not Same(info,record.info) then
            record.info=info;I.changes=I.changes+1
            if record.analysis then
                if market.job then market.job.metadataDirty=true else market.metadataDirty=true end
            end
            for _,row in ipairs(market.rows) do if row.id==check.id then row.infoChecked=nil end end
        else I.unchanged=I.unchanged+1 end
        if not info or not info.complete then check.resolved=false end
        check.cursor=check.cursor+1
        if check.cursor>#check.group.records then
            check.group.checking=false;check.group.resolved=check.resolved
            check.group.quietUntil=U.Mono()+1;I.check=nil
            if check.group.again and not check.resolved then I.pending[check.id]=true end
            check.group.again=nil
        end
        if debugprofilestop and debugprofilestop()-start>=1 then return true end
    end
    return I.check~=nil
end
