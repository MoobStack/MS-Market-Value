local _, A = ...
local U, D = A.Util, A.DB
local P = { revision=0, seen={}, ring={}, cursor=1, names={}, skipped=0 }
A.Drops = P
local MAX_MOBS, MAX_CELLS, MAX_AREAS, MAX_SEEN, MAX_ITEMS_PER_MOB = 3000, 20000, 128, 2048, 200
P.limits={mobs=MAX_MOBS,items=MAX_CELLS,areas=MAX_AREAS,sources=MAX_SEEN}
local function ID(v) return U.Number(v,1,2147483647,true) end
local function Text(v,fallback) return U.String(v) and #v>0 and #v<=180 and v or fallback end

function P.NPC(guid)
    if not U.String(guid) or #guid>128 then return nil end
    local kind,id=guid:match("^(%a+)%-[^-]+%-[^-]+%-[^-]+%-[^-]+%-(%d+)%-")
    id=tonumber(id)
    if (kind=="Creature" or kind=="Vehicle") and ID(id) then return id end
end

function P.Initialize()
    local saved=D.data.drops
    if saved==nil then saved={schema=1,characters={}};D.data.drops=saved end
    if not U.Table(saved) or not U.Accessible(saved.schema) or saved.schema~=1 or not U.Table(saved.characters) then
        P.reason="Unsupported drop history preserved.";return
    end
    P.data=saved
end

function P.Profile()
    if not P.data then return nil end
    local guid=U.Call(UnitGUID,"player")
    if not U.String(guid) or #guid>128 then return nil end
    local key=D.ProfileKey(P.data,"characters",U.MarketInfo(),"|" .. guid)
    if not key then return nil end
    local profile=P.data.characters[key]
    if profile==nil then profile={areas={},mobs=0,cells=0,recent={}};P.data.characters[key]=profile end
    if not U.Table(profile) or not U.Table(profile.areas) or not U.Number(profile.mobs,0,MAX_MOBS,true) or
       not U.Number(profile.cells,0,MAX_CELLS,true) then P.reason="Invalid drop history preserved.";return nil end
    if P.checked~=profile then
        local areas,mobs,cells=0,0,0
        for areaKey,area in pairs(profile.areas) do
            areas=areas+1
            if areas>MAX_AREAS or not U.String(areaKey) or #areaKey>64 or not U.Table(area) or not U.Table(area.mobs) or
               not U.Number(area.mapID,0,1000000,true) or not U.Number(area.instanceID,0,1000000,true) or
               not U.String(area.zone) or #area.zone>180 then P.reason="Invalid drop area preserved.";return nil end
            for npc,mob in pairs(area.mobs) do
                mobs=mobs+1
                if mobs>MAX_MOBS or not ID(npc) or not U.Table(mob) or not U.String(mob.name) or #mob.name>180 or
                   not U.Table(mob.groups) then P.reason="Invalid drop creature preserved.";return nil end
                for group,bucket in pairs(mob.groups) do
                    if not U.String(group) or (group~="solo" and group~="party" and group~="raid") or not U.Table(bucket) or
                       not U.Number(bucket.samples,0,1000000000,true) or not U.Table(bucket.items) then P.reason="Invalid drop sample preserved.";return nil end
                    local bucketCount=0
                    for id,item in pairs(bucket.items) do
                        bucketCount=bucketCount+1
                        cells=cells+1
                        if bucketCount>MAX_ITEMS_PER_MOB or cells>MAX_CELLS or not ID(id) or not U.Table(item) or not U.Number(item.hits,0,bucket.samples,true) or
                           not U.Number(item.quantity,0,1000000000,true) or not U.String(item.name) or #item.name>180 or
                           not U.Accessible(item.questID) or (item.questID~=nil and not ID(item.questID)) then
                            P.reason="Invalid drop item preserved.";return nil
                        end
                    end
                    bucket.itemCount=bucketCount
                end
            end
        end
        if profile.mobs~=mobs or profile.cells~=cells then P.reason="Drop counters did not match stored records; history preserved.";return nil end
        if profile.recent==nil then profile.recent={} end
        if not U.Table(profile.recent) or #profile.recent>64 then P.reason="Invalid recent drop sources preserved.";return nil end
        local recent={}
        for _,source in ipairs(profile.recent) do
            if not U.Table(source) or not P.NPC(source.guid) or not U.Number(source.at,0,U.Now()) or
               not U.String(source.context) or #source.context>64 or not U.String(source.group) or
               (source.group~="solo" and source.group~="party" and source.group~="raid") or not U.Table(source.items) then
                P.reason="Invalid recent drop source preserved.";return nil
            end
            local count=0
            for id,quantity in pairs(source.items) do
                count=count+1
                if count>64 or not ID(id) or not U.Number(quantity,1,1000000,true) then P.reason="Invalid recent drop quantities preserved.";return nil end
            end
            if U.Now()-source.at<=300 then recent[#recent+1]=source end
        end
        profile.recent=recent
        P.checked=profile
    end
    if P.player~=key then
        P.seen,P.ring,P.cursor,P.player,P.cache={},{},1,key,nil
        for _,source in ipairs(profile.recent) do
            P.seen[source.guid]=source;P.ring[P.cursor]=source.guid;P.cursor=P.cursor%MAX_SEEN+1
        end
    end
    return profile
end

function P.Context()
    local map=U.Call(C_Map and C_Map.GetBestMapForUnit,"player")
    if not U.Number(map,0,1000000,true) then map=0 end
    local values=type(GetInstanceInfo)=="function" and {pcall(GetInstanceInfo)} or {}
    local instance=U.Number(values[9],0,1000000,true) and values[9] or 0
    local difficulty=U.Number(values[4],0,10000,true) and values[4] or 0
    local dungeon=U.String(values[3]) and (values[3]=="party" or values[3]=="raid")
    local zone=Text(U.Call(GetRealZoneText),Text(U.Call(GetZoneText),"Unknown zone"))
    return {key=map .. ":" .. (dungeon and instance or 0) .. ":" .. (dungeon and difficulty or 0),
        mapID=map,instanceID=dungeon and instance or 0,difficulty=difficulty,
        zone=zone,dungeon=dungeon and Text(values[2],zone) or nil}
end

function P.Group()
    if U.Call(IsInRaid)==true then return "raid" end
    return U.Call(IsInGroup)==true and "party" or "solo"
end

function P.Remember(unit)
    local guid=U.Call(UnitGUID,unit)
    local id=P.NPC(guid)
    if not id then return end
    if not P.names[id] then
        P.nameOrder=P.nameOrder or {};P.nameOrder[#P.nameOrder+1]=id
        if #P.nameOrder>256 then P.names[table.remove(P.nameOrder,1)]=nil end
    end
    P.names[id]=Text(U.Call(UnitName,unit),"NPC " .. id)
end

local function Area(profile,context)
    local area=profile.areas[context.key]
    if area then return U.Table(area) and U.Table(area.mobs) and area or nil end
    local count=0;for _ in pairs(profile.areas) do count=count+1 end
    if count>=MAX_AREAS then P.reason="Drop area limit reached. Reset an older zone to keep collecting.";return end
    area={mapID=context.mapID,instanceID=context.instanceID,zone=context.zone,dungeon=context.dungeon,mobs={}}
    profile.areas[context.key]=area;return area
end

function P.Observe(guid,items,context,group)
    if not D.Settings().dropTracking or not U.Table(items) then return false end
    local npc=P.NPC(guid)
    local profile=P.Profile()
    if not npc or not profile then return false end
    context=context or P.Context();group=group or P.Group()
    if group~="solo" and group~="party" and group~="raid" then return false end
    local seen=P.seen[guid]
    -- Reopening or changing slots must not count the corpse twice.
    if seen and (seen.context~=context.key or seen.group~=group) then return false end
    local area=Area(profile,context)
    if not area then return false end
    local mob=area.mobs[npc]
    if not mob then
        if profile.mobs>=MAX_MOBS then P.reason="Drop creature limit reached. Reset an older zone to keep collecting.";return false end
        mob={name=P.names[npc] or ("NPC " .. npc),groups={}};area.mobs[npc]=mob;profile.mobs=profile.mobs+1
    end
    if not U.Table(mob) or not U.Table(mob.groups) then return false end
    local bucket=mob.groups[group]
    if not bucket then bucket={samples=0,items={},itemCount=0};mob.groups[group]=bucket end
    if not U.Table(bucket) or not U.Number(bucket.samples,0,1000000000,true) or not U.Table(bucket.items) then return false end
    local changed=false
    if not seen then
        local old=P.ring[P.cursor];if old then P.seen[old]=nil end
        P.ring[P.cursor]=guid;P.cursor=P.cursor%MAX_SEEN+1
        seen={context=context.key,group=group,items={},guid=guid,at=U.Now()};P.seen[guid]=seen
        profile.recent[#profile.recent+1]=seen
        if #profile.recent>64 then table.remove(profile.recent,1) end
        bucket.samples=bucket.samples+1
        changed=true
    end
    mob.name=P.names[npc] or mob.name
    for index=1,math.min(#items,64) do
        local item=items[index]
        if U.Table(item) and ID(item.id) and U.Number(item.quantity,1,1000000,true) then
            local previous=seen.items[item.id] or 0
            if item.quantity>previous then
                local entry=bucket.items[item.id]
                if not entry and profile.cells<MAX_CELLS and bucket.itemCount<MAX_ITEMS_PER_MOB then
                    entry={hits=0,quantity=0};bucket.items[item.id]=entry;profile.cells=profile.cells+1
                    bucket.itemCount=bucket.itemCount+1
                end
                if U.Table(entry) and U.Number(entry.hits,0,bucket.samples,true) and U.Number(entry.quantity,0,1000000000,true) then
                    entry.hits=entry.hits+(previous==0 and 1 or 0)
                    entry.quantity=math.min(1000000000,entry.quantity+item.quantity-previous)
                    entry.name=Text(U.LinkName(item.link),entry.name or ("Item " .. item.id))
                    if ID(item.questID) then entry.questID=item.questID end
                    seen.items[item.id]=item.quantity
                    changed=true
                else P.reason="Drop item limit reached. Reset older observations to keep collecting." end
            end
        end
    end
    if changed then P.revision=P.revision+1;P.cache=nil end
    return true
end

function P.ReadLoot()
    if not D.Settings().dropTracking then return end
    P.Remember("target");P.Remember("mouseover")
    local count=U.Call(GetNumLootItems)
    if not U.Number(count,0,256,true) or type(GetLootSourceInfo)~="function" then return end
    local sources,context,group={},P.Context(),P.Group()
    for slot=1,count do
        local result={pcall(GetLootSourceInfo,slot)}
        local n=result[1] and result[2]
        if U.Number(n,0,64,true) and #result>=2+2*n then
            local itemLink=U.Call(GetLootSlotLink,slot)
            local itemID=U.ItemID(itemLink)
            local info=type(GetLootSlotInfo)=="function" and {pcall(GetLootSlotInfo,slot)} or {}
            for index=1,n do
                local guid,quantity=result[1+index*2],result[2+index*2]
                if P.NPC(guid) and U.Number(quantity,0,1000000,true) then
                    local items=sources[guid] or {};sources[guid]=items
                    if itemID and quantity>0 then
                        local key=itemID
                        local item=items[key] or {id=itemID,quantity=0,link=itemLink}
                        item.quantity=item.quantity+quantity
                        if ID(info[9]) then item.questID=info[9] end
                        items[key]=item
                    end
                end
            end
        end
    end
    for guid,items in pairs(sources) do
        local rows={};for _,item in pairs(items) do rows[#rows+1]=item end
        P.Observe(guid,rows,context,group)
    end
end

function P.QuestItems()
    if P.questItems then return P.questItems end
    local names={}
    local count=U.Call(C_QuestLog and C_QuestLog.GetNumQuestLogEntries)
    if U.Number(count,0,200,true) then
        for index=1,count do
            local info=U.Call(C_QuestLog.GetInfo,index)
            if U.Table(info) and ID(info.questID) then
                local objectives=U.Call(C_QuestLog.GetQuestObjectives,info.questID)
                if U.Table(objectives) then
                    for i=1,math.min(#objectives,32) do
                        local objective=objectives[i]
                        if U.Table(objective) and U.String(objective.type) and objective.type=="item" and
                           U.Accessible(objective.finished) and objective.finished==false and U.String(objective.text) then
                            names[#names+1]=string.lower(objective.text)
                        end
                    end
                end
            end
        end
    end
    P.questItems=names;return names
end

local function Wanted(row)
    if row.questID and U.Call(C_QuestLog and C_QuestLog.IsOnQuest,row.questID)==true and
       U.Call(C_QuestLog and C_QuestLog.IsComplete,row.questID)~=true then return true end
    local name=string.lower(row.name or A.Valuation.MaterialName(row.id))
    for _,text in ipairs(P.QuestItems()) do if string.find(text,name,1,true) then return true end end
    return false
end

function P.Rows(npcID)
    local context=P.Context()
    local cacheKey=npcID .. "|" .. context.key .. "|" .. D.Settings().dropMode .. "|" .. P.revision .. "|" .. (A.LootReference.revision or 0)
    local snapshot=D.Snapshot()
    if P.cache and P.cache.key==cacheKey and P.cache.snapshot==snapshot then return P.cache.rows,P.cache.samples end
    local rows,samples={},0
    if D.Settings().dropMode=="reference" then
        for _,row in ipairs(A.LootReference.Rows(npcID)) do
            rows[#rows+1]={id=row.id,name=row.name or A.Valuation.MaterialName(row.id),rate=row.rate,questID=row.questID}
        end
    else
        local profile=P.Profile()
        local area=profile and profile.areas[context.key]
        local mob=U.Table(area) and U.Table(area.mobs) and area.mobs[npcID]
        local totals={}
        for _,bucket in pairs(U.Table(mob) and U.Table(mob.groups) and mob.groups or {}) do
            if U.Table(bucket) and U.Number(bucket.samples,0,1000000000,true) and U.Table(bucket.items) then
                samples=samples+bucket.samples
                for id,item in pairs(bucket.items) do
                    if ID(id) and U.Table(item) and U.Number(item.hits,0,bucket.samples,true) then
                        local total=totals[id] or {id=id,hits=0,name=Text(item.name,A.Valuation.MaterialName(id)),questID=item.questID}
                        total.hits=total.hits+item.hits;totals[id]=total
                    end
                end
            end
        end
        for _,row in pairs(totals) do row.rate=samples>0 and row.hits/samples*100 or 0;rows[#rows+1]=row end
    end
    for _,row in ipairs(rows) do
        row.wanted=Wanted(row)
        local info=A.Valuation.ItemInfo(row.id)
        local price=D.Price(row.id,nil,snapshot)
        row.value=price and price.low or (info and info.vendor or 0)
        row.score=row.rate*row.value
    end
    table.sort(rows,function(a,b)
        if a.wanted~=b.wanted then return a.wanted end
        if a.score~=b.score then return a.score>b.score end
        if a.rate~=b.rate then return a.rate>b.rate end
        return a.id<b.id
    end)
    P.cache={key=cacheKey,rows=rows,samples=samples,snapshot=snapshot}
    return rows,samples
end

function P.Reset(scope,name)
    if U.Combat() then return false,"Reset drop history outside combat." end
    local profile=P.Profile()
    if not profile then return false,P.reason end
    if scope~="all" and scope~="zone" and scope~="dungeon" and scope~="monster" then return false,"Choose a reset scope." end
    if scope=="monster" and (not U.String(name) or name:match("^%s*$")) then return false,"Enter the creature's name or NPC ID." end
    local context,removed=P.Context(),0
    if scope=="dungeon" and context.instanceID==0 then return false,"Enter the dungeon before resetting it." end
    for areaKey,area in pairs(profile.areas) do
        local match=scope=="all" or scope=="monster" or
            (scope=="zone" and area.mapID==context.mapID) or (scope=="dungeon" and area.instanceID==context.instanceID)
        if match then
            for npc,mob in pairs(area.mobs) do
                if scope~="monster" or tostring(npc)==name or string.lower(mob.name)==string.lower(name) then
                    for _,bucket in pairs(mob.groups) do for _ in pairs(bucket.items) do profile.cells=profile.cells-1 end end
                    profile.mobs=profile.mobs-1;area.mobs[npc]=nil;removed=removed+1
                end
            end
            if not next(area.mobs) then profile.areas[areaKey]=nil end
        end
    end
    local seen,ring,recent={},{},{}
    for _,guid in ipairs(P.ring) do
        local source=P.seen[guid]
        local area=source and profile.areas[source.context]
        if area and area.mobs[P.NPC(guid)] then seen[guid]=source;ring[#ring+1]=guid end
    end
    for _,source in ipairs(profile.recent) do if seen[source.guid] then recent[#recent+1]=source end end
    P.seen,P.ring,P.cursor,P.cache,P.reason=seen,ring,#ring%MAX_SEEN+1,nil,nil;P.revision=P.revision+1
    profile.recent=recent
    return true,"Reset " .. removed .. " creature record(s)."
end

function P.Tooltip(tooltip,data)
    if not D.data or A.disabledReason or not D.Settings().showDrops or not U.Accessible(tooltip) or not U.Table(data) or tooltip~=GameTooltip or
       (tooltip.IsForbidden and tooltip:IsForbidden()) then return end
    local guid=U.String(data.guid) and data.guid or nil
    if not guid and type(tooltip.GetUnit)=="function" then
        local result={pcall(tooltip.GetUnit,tooltip)}
        if result[1] and U.String(result[3]) then guid=U.Call(UnitGUID,result[3]) end
    end
    local npc=P.NPC(guid)
    if not npc then return end
    if P.tip and P.tip.data==data and P.tip.lines==tooltip:NumLines() then return end
    local rows,samples=P.Rows(npc)
    if #rows==0 and D.Settings().dropMode~="reference" then return end
    tooltip:AddLine(" ")
    local reference=D.Settings().dropMode=="reference"
    tooltip:AddDoubleLine("MS Market Value - Drops",reference and A.LootReference.label or (samples .. " observed corpses"),.55,.83,.85,.61,.66,.70)
    if reference and #rows==0 then tooltip:AddLine("No reference rates for this creature.",.61,.66,.70) end
    for index=1,math.min(#rows,D.Settings().dropRows) do
        local row=rows[index]
        tooltip:AddDoubleLine((row.wanted and "|cffffd100Quest: |r" or "") .. row.name,
            string.format("%.1f%%",row.rate) .. (reference and "" or (" (" .. row.hits .. "/" .. samples .. ")")),
            .83,.86,.89,.83,.86,.89)
    end
    if #rows>D.Settings().dropRows then tooltip:AddLine("+" .. (#rows-D.Settings().dropRows) .. " more recorded items",.61,.66,.70) end
    if reference and not A.LootReference.verified then tooltip:AddLine("Reference data; not verified Forever server rates.",.92,.72,.38) end
    P.tip={data=data,lines=tooltip:NumLines()}
end

function P.Install()
    if P.installed or not GameTooltip or type(GameTooltip.HookScript)~="function" or
       not TooltipDataProcessor or not Enum or not Enum.TooltipDataType or Enum.TooltipDataType.Unit==nil then return end
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit,P.Tooltip)
    GameTooltip:HookScript("OnHide",function()P.tip=nil end);P.installed=true
end

function P.Event(event)
    if event=="LOOT_READY" or event=="LOOT_OPENED" or event=="LOOT_SLOT_CHANGED" then P.ReadLoot()
    elseif event=="UPDATE_MOUSEOVER_UNIT" then P.Remember("mouseover")
    elseif event=="PLAYER_TARGET_CHANGED" then P.Remember("target")
    elseif event=="QUEST_LOG_UPDATE" then P.questItems,P.cache=nil,nil
    elseif event=="GET_ITEM_INFO_RECEIVED" then P.cache=nil
    elseif event=="PLAYER_LOGIN" then P.Install() end
end
