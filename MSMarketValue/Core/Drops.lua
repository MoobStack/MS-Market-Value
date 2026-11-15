local _, A = ...
local U, D = A.Util, A.DB
local P = { revision=0, seen={}, ring={}, cursor=1, names={}, skipped=0 }
A.Drops = P
local MAX_MOBS, MAX_CELLS, MAX_AREAS, MAX_SEEN, MAX_ITEMS_PER_MOB = 3000, 20000, 128, 2048, 200
P.limits={mobs=MAX_MOBS,items=MAX_CELLS,areas=MAX_AREAS,sources=MAX_SEEN}
P.labels={loot="Drops",herbalism="Herbalism",mining="Mining",skinning="Skinning"}
local function ID(v) return U.Number(v,1,2147483647,true) end
local function Text(v,fallback) return U.String(v) and #v>0 and #v<=180 and v or fallback end

function P.SourceID(guid)
    if not U.String(guid) or #guid>128 then return nil end
    local kind,id=guid:match("^(%a+)%-[^-]+%-[^-]+%-[^-]+%-[^-]+%-(%d+)%-")
    id=tonumber(id)
    if (kind=="Creature" or kind=="Vehicle" or kind=="GameObject") and ID(id) then return id,kind end
end
function P.NPC(guid)
    local id,kind=P.SourceID(guid)
    if kind=="Creature" or kind=="Vehicle" then return id end
end
function P.SourceKey(id,kind)
    if not ID(id) or not U.String(kind) or not P.labels[kind] then return nil end
    return kind=="loot" and id or (kind .. ":" .. id)
end
local function SourceKey(key)
    if ID(key) then return key,"loot" end
    if not U.String(key) then return nil end
    local kind,id=key:match("^(%a+):(%d+)$");id=tonumber(id)
    if kind~="loot" and P.SourceKey(id,kind)==key then return id,kind end
end
local function ReceiptKey(guid,kind)
    return kind=="loot" and guid or (kind .. "|" .. guid)
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
                if mobs>MAX_MOBS or not SourceKey(npc) or not U.Table(mob) or not U.String(mob.name) or #mob.name>180 or
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
            if not U.Table(source) or not P.SourceID(source.guid) or not U.Number(source.at,0,U.Now()) or
               not U.Accessible(source.kind) or (source.kind~=nil and (not U.String(source.kind) or not P.labels[source.kind])) or
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
            local receipt=ReceiptKey(source.guid,source.kind or "loot")
            P.seen[receipt]=source;P.ring[P.cursor]=receipt;P.cursor=P.cursor%MAX_SEEN+1
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

local function RememberName(id,name)
    if not P.names[id] then
        P.nameOrder=P.nameOrder or {};P.nameOrder[#P.nameOrder+1]=id
        if #P.nameOrder>256 then P.names[table.remove(P.nameOrder,1)]=nil end
    end
    P.names[id]=Text(name,"Source " .. id)
end
function P.Remember(unit)
    local guid=U.Call(UnitGUID,unit)
    local id=P.NPC(guid)
    if id then RememberName(id,U.Call(UnitName,unit)) end
end

local function Area(profile,context)
    local area=profile.areas[context.key]
    if area then return U.Table(area) and U.Table(area.mobs) and area or nil end
    local count=0;for _ in pairs(profile.areas) do count=count+1 end
    if count>=MAX_AREAS then P.reason="Drop area limit reached. Reset an older zone to keep collecting.";return end
    area={mapID=context.mapID,instanceID=context.instanceID,zone=context.zone,dungeon=context.dungeon,mobs={}}
    profile.areas[context.key]=area;return area
end

function P.Observe(guid,items,context,group,kind)
    if not D.Settings().dropTracking or not U.Table(items) then return false end
    kind=kind or "loot"
    local id,sourceType=P.SourceID(guid)
    local npc=P.SourceKey(id,kind)
    if (kind=="loot" or kind=="skinning") and sourceType=="GameObject" then return false end
    if (kind=="herbalism" or kind=="mining") and sourceType~="GameObject" then return false end
    local profile=P.Profile()
    if not npc or not profile then return false end
    context=context or P.Context();group=group or P.Group()
    if group~="solo" and group~="party" and group~="raid" then return false end
    local receipt=ReceiptKey(guid,kind)
    local seen=P.seen[receipt]
    -- Reopening or changing slots must not count the corpse twice.
    if seen and (seen.context~=context.key or seen.group~=group) then return false end
    local area=Area(profile,context)
    if not area then return false end
    local mob=area.mobs[npc]
    if not mob then
        if profile.mobs>=MAX_MOBS then P.reason="Drop creature limit reached. Reset an older zone to keep collecting.";return false end
        local fallback=(sourceType=="GameObject" and "Node " or "NPC ") .. id
        local known=P.hover and P.hover.id==id and P.hover.at and U.Mono()-P.hover.at<15 and P.hover.name or nil
        mob={name=P.names[npc] or (kind~="loot" and P.names[id]) or Text(known,fallback),
            groups={}};area.mobs[npc]=mob;profile.mobs=profile.mobs+1
    end
    if not U.Table(mob) or not U.Table(mob.groups) then return false end
    local bucket=mob.groups[group]
    if not bucket then bucket={samples=0,items={},itemCount=0};mob.groups[group]=bucket end
    if not U.Table(bucket) or not U.Number(bucket.samples,0,1000000000,true) or not U.Table(bucket.items) then return false end
    local changed=false
    if not seen then
        local old=P.ring[P.cursor];if old then P.seen[old]=nil end
        P.ring[P.cursor]=receipt;P.cursor=P.cursor%MAX_SEEN+1
        seen={context=context.key,group=group,items={},guid=guid,kind=kind,at=U.Now()};P.seen[receipt]=seen
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

local gatherSpells={ [2366]="herbalism",[2368]="herbalism",[3570]="herbalism",[11993]="herbalism",
    [2575]="mining",[2576]="mining",[3564]="mining",[10248]="mining",
    [8613]="skinning",[8617]="skinning",[8618]="skinning",[10768]="skinning" }
function P.GatherKind(spellID)
    if not ID(spellID) then return nil end
    if gatherSpells[spellID] then return gatherSpells[spellID] end
    if P.spellKinds and P.spellKinds[spellID]~=nil then return P.spellKinds[spellID] or nil end
    if not P.gatherNames then
        P.gatherNames={}
        for id,kind in pairs(gatherSpells) do
            local info=U.Call(C_Spell and C_Spell.GetSpellInfo,id)
            local name=U.Table(info) and info.name or U.Call(GetSpellInfo,id)
            if U.String(name) then P.gatherNames[name]=kind end
        end
    end
    local info=U.Call(C_Spell and C_Spell.GetSpellInfo,spellID)
    local name=U.Table(info) and info.name or U.Call(GetSpellInfo,spellID)
    if not U.String(name) then return nil end
    P.spellKinds=P.spellKinds or {};P.spellOrder=P.spellOrder or {}
    P.spellKinds[spellID]=P.gatherNames[name] or false;P.spellOrder[#P.spellOrder+1]=spellID
    if #P.spellOrder>128 then P.spellKinds[table.remove(P.spellOrder,1)]=nil end
    return P.spellKinds[spellID] or nil
end
function P.BeginGather(unit,castGUID,spellID,target)
    if not U.String(unit) or unit~="player" then return end
    local kind=P.GatherKind(spellID)
    if not kind then return end
    local hover=P.hover and U.Mono()-P.hover.at<3 and P.hover or nil
    local guid=U.Call(UnitGUID,"mouseover")
    local id,sourceType=P.SourceID(guid)
    if (kind=="skinning" and sourceType=="GameObject") or (kind~="skinning" and sourceType~="GameObject") then guid=nil end
    if hover and hover.guid then
        local _,hoverType=P.SourceID(hover.guid)
        if (kind=="skinning" and hoverType=="GameObject") or (kind~="skinning" and hoverType~="GameObject") then hover=nil end
    end
    local previous=P.gather
    local name=Text(target) or (previous and U.String(castGUID) and previous.cast==castGUID and previous.name) or (hover and hover.name)
    P.gather={kind=kind,cast=U.String(castGUID) and castGUID or nil,spellID=spellID,at=U.Mono(),
        guid=P.SourceID(guid) and guid or (hover and hover.guid),name=name}
end
function P.FinishGather(unit,castGUID,spellID)
    if not U.String(unit) or unit~="player" then return end
    local kind=P.GatherKind(spellID)
    if not kind then return end
    local gather=P.gather
    if not gather or gather.kind~=kind or U.Mono()-gather.at>30 then
        P.BeginGather(unit,castGUID,spellID);gather=P.gather
    end
    if gather then gather.confirmed=U.Mono() end
end
function P.ReceiptKind(itemID)
    local entry=P.acquisitions and P.acquisitions[itemID]
    return entry and U.Mono()-entry.at<=3 and entry.kind or "loot"
end
function P.ReadLoot()
    if not D.Settings().dropTracking and not D.Settings().farmTracking then return end
    P.Remember("target");P.Remember("mouseover")
    local count=U.Call(GetNumLootItems)
    if not U.Number(count,0,256,true) then return end
    if type(GetLootSourceInfo)~="function" then P.reason="Loot source API unavailable; no sources were guessed.";return end
    P.readWindows=(P.readWindows or 0)+1
    local sources,kinds,acquisitions,context,group={},{},{},P.Context(),P.Group()
    local gather=P.gather
    -- Some clients open loot before the success event. A recent, matching
    -- gathering cast plus its loot source is sufficient; a failed cast is cleared.
    if gather and U.Mono()-(gather.confirmed or gather.at)>10 then gather=nil end
    for slot=1,count do
        local result={pcall(GetLootSourceInfo,slot)}
        -- Native returns GUID, quantity, GUID, quantity ... with no count prefix.
        if result[1] and #result>1 and (#result-1)%2==0 and #result<=129 then
            local itemLink=U.Call(GetLootSlotLink,slot)
            local itemID=U.ItemID(itemLink)
            local info=type(GetLootSlotInfo)=="function" and {pcall(GetLootSlotInfo,slot)} or {}
            for index=2,#result,2 do
                local guid,quantity=result[index],result[index+1]
                local id,sourceType=P.SourceID(guid)
                local kind="loot"
                if gather and (gather.kind=="skinning" and sourceType~="GameObject" or
                    gather.kind~="skinning" and sourceType=="GameObject") and
                    (not gather.guid or gather.guid==guid) then kind=gather.kind end
                if id and (sourceType~="GameObject" or kind~="loot") and U.Number(quantity,0,1000000,true) then
                    local receipt=ReceiptKey(guid,kind)
                    local items=sources[receipt] or {};sources[receipt]=items;kinds[receipt]={guid=guid,kind=kind}
                    if kind~="loot" and gather and U.String(gather.name) then RememberName(P.SourceKey(id,kind),gather.name) end
                    if itemID and quantity>0 then
                        local key=itemID
                        local item=items[key] or {id=itemID,quantity=0,link=itemLink}
                        item.quantity=item.quantity+quantity
                        if ID(info[9]) then item.questID=info[9] end
                        items[key]=item
                        local old=acquisitions[itemID]
                        acquisitions[itemID]={kind=old and old.kind~=kind and "loot" or kind,at=U.Mono()}
                    end
                else P.skipped=P.skipped+1 end
            end
        elseif #result>1 then P.skipped=P.skipped+1 end
    end
    if next(acquisitions) then P.acquisitions=acquisitions end
    for key,items in pairs(sources) do
        local rows={};for _,item in pairs(items) do rows[#rows+1]=item end
        P.Observe(kinds[key].guid,rows,context,group,kinds[key].kind)
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

function P.Rows(npcID,kind)
    kind=kind or "loot"
    local sourceKey=P.SourceKey(npcID,kind)
    if not sourceKey then return {},0 end
    local context=P.Context()
    local cacheKey=tostring(sourceKey) .. "|" .. context.key .. "|" .. D.Settings().dropMode .. "|" .. P.revision .. "|" .. (A.LootReference.revision or 0)
    local snapshot=D.Snapshot()
    if P.cache and P.cache.key==cacheKey and P.cache.snapshot==snapshot then return P.cache.rows,P.cache.samples end
    local rows,samples={},0
    if D.Settings().dropMode=="reference" then
        for _,row in ipairs(A.LootReference.Rows(npcID,kind)) do
            rows[#rows+1]={id=row.id,name=row.name or A.Valuation.MaterialName(row.id),rate=row.rate,questID=row.questID,samples=row.samples}
        end
    else
        local profile=P.Profile()
        local area=profile and profile.areas[context.key]
        local mob=U.Table(area) and U.Table(area.mobs) and area.mobs[sourceKey]
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
                local id=SourceKey(npc)
                if scope~="monster" or tostring(id)==name or string.lower(mob.name)==string.lower(name) then
                    for _,bucket in pairs(mob.groups) do for _ in pairs(bucket.items) do profile.cells=profile.cells-1 end end
                    profile.mobs=profile.mobs-1;area.mobs[npc]=nil;removed=removed+1
                end
            end
            if not next(area.mobs) then profile.areas[areaKey]=nil end
        end
    end
    local seen,ring,recent={},{},{}
    for _,receipt in ipairs(P.ring) do
        local source=P.seen[receipt]
        local area=source and profile.areas[source.context]
        local id=source and P.SourceID(source.guid)
        if area and area.mobs[P.SourceKey(id,source.kind or "loot")] then seen[receipt]=source;ring[#ring+1]=receipt end
    end
    for _,source in ipairs(profile.recent) do if seen[ReceiptKey(source.guid,source.kind or "loot")] then recent[#recent+1]=source end end
    P.seen,P.ring,P.cursor,P.cache,P.reason=seen,ring,#ring%MAX_SEEN+1,nil,nil;P.revision=P.revision+1
    profile.recent=recent
    return true,"Reset " .. removed .. " creature record(s)."
end

local function TooltipName(tooltip,data)
    local first=U.Table(data.lines) and data.lines[1]
    if U.Table(first) and U.String(first.leftText) then return Text(first.leftText) end
    local label=_G.GameTooltipTextLeft1
    return Text(U.Call(label and label.GetText,label))
end
local function KnownNode(name,id)
    local profile=P.Profile()
    local context=P.Context()
    local area=profile and profile.areas[context.key]
    if id then
        for _,kind in ipairs({"herbalism","mining"}) do
            if (area and area.mobs[P.SourceKey(id,kind)]) or
               (D.Settings().dropMode=="reference" and #A.LootReference.Rows(id,kind)>0) then return id,kind end
        end
    end
    if not area then return nil end
    if not name then return nil end
    if not P.nodeNames or P.nodeNames.area~=area or P.nodeNames.revision~=P.revision then
        local names={}
        for key,mob in pairs(area.mobs) do
            local sourceID,kind=SourceKey(key)
            if kind=="herbalism" or kind=="mining" then
                if names[mob.name]~=nil then names[mob.name]=false else names[mob.name]={id=sourceID,kind=kind} end
            end
        end
        P.nodeNames={area=area,revision=P.revision,names=names}
    end
    local row=P.nodeNames.names[name]
    if row then return row.id,row.kind end
end
function P.ResolveTooltip(tooltip,data)
    local types=Enum and Enum.TooltipDataType
    if not types or not U.Accessible(data.type) or data.type==types.Item then return nil end
    if type(tooltip.GetItem)=="function" then
        local result={pcall(tooltip.GetItem,tooltip)}
        if result[1] and U.ItemID(result[3]) then return nil end
    end
    local name=TooltipName(tooltip,data)
    local guid=U.String(data.guid) and data.guid or nil
    if not guid and type(tooltip.GetUnit)=="function" then
        local result={pcall(tooltip.GetUnit,tooltip)}
        if result[1] then
            for index=3,4 do
                if P.SourceID(result[index]) then guid=result[index];break end
                if U.String(result[index]) then local found=U.Call(UnitGUID,result[index]);if P.SourceID(found) then guid=found;break end end
            end
        end
    end
    if not guid and name then
        local unitName=U.Call(UnitName,"mouseover")
        if U.String(unitName) and unitName==name then guid=U.Call(UnitGUID,"mouseover") end
    end
    local id,sourceType=P.SourceID(guid)
    if U.String(guid) and not id then return nil end -- Never treat a player as a node.
    if not id and types.Unit and data.type==types.Unit and ID(data.id) then id,sourceType=data.id,"Creature" end
    if name or id then P.hover={id=id,guid=guid,name=name or (id and P.names[id]),at=U.Mono()} end
    if sourceType=="Creature" or sourceType=="Vehicle" then
        local dead=U.Call(UnitIsDead,"mouseover")
        if dead==true and D.Settings().showHarvestDrops then
            local rows,n=P.Rows(id,"skinning")
            if n>0 or (D.Settings().dropMode=="reference" and #rows>0) then return id,"skinning",name end
        end
        return id,"loot",name
    end
    local node,kind=KnownNode(name,id)
    return node,kind,name
end

function P.Tooltip(tooltip,data)
    if not D.data or A.disabledReason or not D.Settings().showDrops or not U.Accessible(tooltip) or
       not U.Table(data) or tooltip~=GameTooltip or (tooltip.IsForbidden and tooltip:IsForbidden()) then return end
    local id,kind,name=P.ResolveTooltip(tooltip,data)
    if not id then return end
    if kind~="loot" and not D.Settings().showHarvestDrops then return end
    local key=tostring(P.SourceKey(id,kind)) .. (name or "")
    if P.tip and P.tip.key==key and P.tip.data==data and P.tip.lines==tooltip:NumLines() then return end
    local rows,samples=P.Rows(id,kind)
    tooltip:AddLine(" ")
    local reference=D.Settings().dropMode=="reference"
    local unit=kind=="loot" and "corpses" or "harvests"
    tooltip:AddDoubleLine("MS Market Value - " .. P.labels[kind],reference and A.LootReference.label or
        (samples .. " observed " .. unit),.55,.83,.85,.61,.66,.70)
    if #rows==0 then tooltip:AddLine(reference and "No reference data for this source." or "No personal samples yet.",.61,.66,.70) end
    for index=1,math.min(#rows,D.Settings().dropRows) do
        local row=rows[index]
        local count=reference and (row.samples and (" (" .. row.samples .. " samples)") or "") or
            (" (" .. row.hits .. "/" .. samples .. ")")
        local rate=row.rate>0 and row.rate<.01 and "<0.01%" or
            string.format(row.rate>0 and row.rate<1 and "%.2f%%" or "%.1f%%",row.rate)
        tooltip:AddDoubleLine((row.wanted and "|cffffd100Quest: |r" or "") .. row.name,
            rate .. count,.83,.86,.89,.83,.86,.89)
    end
    if #rows>D.Settings().dropRows then tooltip:AddLine("+" .. (#rows-D.Settings().dropRows) .. " more recorded items",.61,.66,.70) end
    if reference and not A.LootReference.verified then tooltip:AddLine("Sampled reference; not verified server settings.",.92,.72,.38) end
    P.tip={key=key,data=data,lines=tooltip:NumLines()}
end
function P.CheckTooltip()
    local tooltip=GameTooltip
    if not P.installed or not tooltip or not tooltip:IsShown() or (tooltip.IsForbidden and tooltip:IsForbidden()) then return end
    local data=U.Call(tooltip.GetPrimaryTooltipData,tooltip)
    if not U.Table(data) then P.fallbackData=P.fallbackData or {};data=P.fallbackData end
    P.Tooltip(tooltip,data)
end
function P.Install()
    if P.installed or not GameTooltip or type(GameTooltip.HookScript)~="function" or
       not TooltipDataProcessor or not Enum or not Enum.TooltipDataType or Enum.TooltipDataType.Unit==nil then return end
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit,P.Tooltip)
    if Enum.TooltipDataType.Object~=nil then TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Object,P.Tooltip) end
    GameTooltip:HookScript("OnHide",function()P.tip,P.fallbackData=nil,nil end);P.installed=true
end
function P.Event(event,...)
    local unit,a,b,c=...
    if event=="LOOT_READY" or event=="LOOT_OPENED" or event=="LOOT_SLOT_CHANGED" then P.ReadLoot()
    elseif event=="LOOT_CLOSED" then P.gather=nil
    elseif event=="UNIT_SPELLCAST_SENT" then P.BeginGather(unit,b,c,a)
    elseif event=="UNIT_SPELLCAST_START" then P.BeginGather(unit,a,b)
    elseif event=="UNIT_SPELLCAST_SUCCEEDED" then P.FinishGather(unit,a,b)
    elseif event=="UNIT_SPELLCAST_FAILED" or event=="UNIT_SPELLCAST_INTERRUPTED" then
        if U.String(unit) and unit=="player" then P.gather=nil end
    elseif event=="UPDATE_MOUSEOVER_UNIT" then P.Remember("mouseover")
    elseif event=="PLAYER_TARGET_CHANGED" then P.Remember("target")
    elseif event=="QUEST_LOG_UPDATE" then P.questItems,P.cache=nil,nil
    elseif event=="GET_ITEM_INFO_RECEIVED" then P.cache=nil
    elseif event=="PLAYER_LOGIN" then P.Install() end
end
