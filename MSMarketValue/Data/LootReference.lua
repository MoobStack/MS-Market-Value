local _, A = ...
local U = A.Util
local R = { label="No reference pack loaded", verified=false, cache={}, order={}, cachedRows=0, cacheLimit=64, maxRows=200 }
A.LootReference = R

-- Optional packs supply one NPC at a time. No full database is copied or
-- downloaded, and reference samples never enter the player's observations.
function R.Register(label, query, verified)
    if not U.String(label) or #label>120 or type(query)~="function" then return false end
    R.label, R.query, R.verified = label, query, verified==true
    R.cache, R.order, R.cachedRows = {}, {}, 0
    R.cacheLimit,R.maxRows,R.packed=64,200,false
    R.revision=(R.revision or 0)+1
    return true
end

-- Printable base-32 varints (the upper alphabet half continues a number).
-- Source strings stay packed in memory; only a queried source is
-- decoded. Exact counts retain the precision of very rare drops.
local alphabet="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
local digits={};for index=1,#alphabet do digits[alphabet:byte(index)]=index-1 end
function R.Decode(code)
    if not U.String(code) or #code>131072 then return nil end
    local cursor=1
    local function Read()
        local value,multiplier=0,1
        for _=1,7 do
            local digit=digits[code:byte(cursor)];cursor=cursor+1
            if not digit then return nil end
            value=value+(digit%32)*multiplier
            if value>4000000003 then return nil end
            if digit<32 then return value end
            multiplier=multiplier*32
        end
    end
    local count,default=Read(),Read()
    if not U.Number(count,1,4096,true) or not U.Number(default,1,1000000000,true) then return nil end
    local rows,id={},0
    for _=1,count do
        local delta,hits,extra=Read(),Read(),Read()
        if not U.Number(delta,1,2147483647,true) or not hits or not extra then return nil end
        id=id+delta
        local flags=extra%4
        local samples=math.floor(extra/4);if samples==0 then samples=default end
        local questID=flags>=2 and Read() or nil
        if not U.Number(id,1,2147483647,true) or not U.Number(samples,1,1000000000,true) or
           not U.Number(hits,1,samples,true) or (flags>=2 and not U.Number(questID,1,2147483647,true)) then return nil end
        rows[#rows+1]={id=id,rate=hits/samples*100,samples=samples,questItem=flags%2==1 or nil,questID=questID}
    end
    if cursor~=#code+1 then return nil end
    return rows
end

function R.RegisterPacked(label,sources)
    if not U.Table(sources) then return false end
    for _,kind in ipairs({"loot","herbalism","mining","skinning"}) do
        if not U.Accessible(sources[kind]) or (sources[kind]~=nil and not U.Table(sources[kind])) then return false end
    end
    local ok=R.Register(label,function(id,kind)
        local group=sources[kind or "loot"]
        return group and R.Decode(group[id]) or nil
    end,false)
    if ok then R.packed,R.maxRows,R.cacheLimit=true,4096,8 end
    return ok
end

function R.Rows(npcID,kind)
    if not U.Number(npcID,1,2147483647,true) or not R.query then return {} end
    kind=kind or "loot"
    if not U.String(kind) or (kind~="loot" and kind~="herbalism" and kind~="mining" and kind~="skinning") then return {} end
    local key=kind=="loot" and npcID or (kind .. ":" .. npcID)
    if R.cache[key] then return R.cache[key] end
    local ok, source = pcall(R.query,npcID,kind)
    local result = {}
    if ok and U.Table(source) and R.packed then result=source
    elseif ok and U.Table(source) then
        for index=1,math.min(#source,R.maxRows) do
            local row=source[index]
            if U.Table(row) and U.Number(row.id,1,2147483647,true) and U.Number(row.rate,0,100) then
                result[#result+1]={id=row.id,rate=row.rate,name=U.String(row.name) and #row.name>0 and #row.name<=180 and row.name or nil,
                    questID=U.Number(row.questID,1,2147483647,true) and row.questID or nil,
                    questItem=U.Accessible(row.questItem) and row.questItem==true or nil,
                    samples=U.Number(row.samples,1,1000000000,true) and row.samples or nil}
            end
        end
    end
    while #R.order>0 and (#R.order>=R.cacheLimit or R.cachedRows+#result>4096) do
        local old=table.remove(R.order,1)
        R.cachedRows=R.cachedRows-#R.cache[old];R.cache[old]=nil
    end
    R.order[#R.order+1]=key;R.cachedRows=R.cachedRows+#result
    R.cache[key]=result
    return result
end
