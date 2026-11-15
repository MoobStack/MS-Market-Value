local _, A = ...
local U = A.Util
local R = { label="No reference pack loaded", verified=false, cache={}, order={} }
A.LootReference = R

-- Optional packs supply one NPC at a time. No full database is copied or
-- downloaded, and reference samples never enter the player's observations.
function R.Register(label, query, verified)
    if not U.String(label) or #label>120 or type(query)~="function" then return false end
    R.label, R.query, R.verified = label, query, verified==true
    R.cache, R.order = {}, {}
    R.revision=(R.revision or 0)+1
    return true
end

function R.Rows(npcID,kind)
    if not U.Number(npcID,1,2147483647,true) or not R.query then return {} end
    kind=kind or "loot"
    local key=kind=="loot" and npcID or (kind .. ":" .. npcID)
    if R.cache[key] then return R.cache[key] end
    local ok, source = pcall(R.query,npcID,kind)
    local result = {}
    if ok and U.Table(source) then
        for index=1,math.min(#source,200) do
            local row=source[index]
            if U.Table(row) and U.Number(row.id,1,2147483647,true) and U.Number(row.rate,0,100) then
                result[#result+1]={id=row.id,rate=row.rate,name=U.String(row.name) and row.name or nil,
                    questID=U.Number(row.questID,1,2147483647,true) and row.questID or nil,
                    samples=U.Number(row.samples,1,1000000000,true) and row.samples or nil}
            end
        end
    end
    R.order[#R.order+1]=key
    if #R.order>64 then R.cache[table.remove(R.order,1)]=nil end
    R.cache[key]=result
    return result
end
