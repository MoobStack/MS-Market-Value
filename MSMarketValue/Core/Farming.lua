local _, A = ...
local U, D = A.Util, A.DB
local F={revision=0,pending={},questCredits={},messages={},messageRing={},serial=0}
A.Farm=F
local MAX_ITEMS, MAX_RECENT, MAX_HISTORY = 500, 20, 5
F.limits={items=MAX_ITEMS,recent=MAX_RECENT,history=MAX_HISTORY}
local MAX=1000000000000
local function Amount(v) return U.Number(v,0,MAX,true) end
local function New()
    return {startedAt=U.Now(),elapsed=0,coins=0,questCoins=0,items={},itemTypes=0,recent={},paused=false}
end

function F.Initialize()
    local saved=D.data.farming
    if saved==nil then saved={schema=1,characters={}};D.data.farming=saved end
    if not U.Table(saved) or not U.Accessible(saved.schema) or saved.schema~=1 or not U.Table(saved.characters) then F.reason="Unsupported farming data preserved.";return end
    F.data=saved
end

function F.Profile()
    local guid=U.Call(UnitGUID,"player")
    if not F.data or not U.String(guid) or #guid>128 then return nil end
    local key=D.ProfileKey(F.data,"characters",U.MarketInfo(),"|" .. guid)
    if not key then return nil end
    local profile=F.data.characters[key]
    if profile==nil then profile={current=New(),history={}};F.data.characters[key]=profile end
    local session=U.Table(profile) and profile.current
    if not U.Table(session) or not U.Table(session.items) or not U.Table(session.recent) or
       not U.Number(session.elapsed,0,315360000) or not Amount(session.coins) or not Amount(session.questCoins) or
       not U.Number(session.itemTypes,0,MAX_ITEMS,true) or #session.recent>MAX_RECENT or
       not U.Table(profile.history) or #profile.history>MAX_HISTORY or not U.Accessible(session.paused) or type(session.paused)~="boolean" then
        F.reason="Invalid farming session preserved.";return nil
    end
    if F.checked~=profile then
        local count=0
        for key,item in pairs(session.items) do
            count=count+1
            if count>MAX_ITEMS or not U.String(key) or #key>64 or not U.Table(item) or not U.String(item.link) or
               #item.link>2048 or not U.ItemID(item.link) or not U.Number(item.quantity,1,1000000000,true) or
               not U.String(item.name) or #item.name>256 or not U.String(item.source) or
               (item.source~="quest" and item.source~="loot") then F.reason="Invalid farming item preserved.";return nil end
        end
        if count~=session.itemTypes then F.reason="Session counters did not match its items; session preserved.";return nil end
        for _,item in ipairs(session.recent) do
            if not U.Table(item) or not U.String(item.name) or #item.name>256 or not U.Number(item.time,0,U.Now()) or
               not U.Accessible(item.amount) or (item.amount~=nil and not U.Number(item.amount,0,MAX)) then
                F.reason="Invalid recent pickup preserved.";return nil
            end
        end
        for _,record in ipairs(profile.history) do
            if not U.Table(record) or not U.Number(record.total,0,MAX) or not U.Number(record.elapsed,0,315360000) or
               not U.Number(record.startedAt,0,U.Now()) or not U.Table(record.top) or #record.top>10 then F.reason="Invalid session history preserved.";return nil end
            for _,item in ipairs(record.top) do
                if not U.Table(item) or not U.String(item.name) or not U.Number(item.quantity,0,1000000000,true) or
                   not U.Accessible(item.total) or (item.total~=nil and not U.Number(item.total,0,MAX)) then F.reason="Invalid session breakdown preserved.";return nil end
            end
        end
        F.checked=profile
    end
    return profile,key
end

function F.Active()
    local profile=F.Profile()
    return profile and D.Settings().farmTracking and not profile.current.paused and F.inWorld~=false
end

function F.Elapsed()
    local profile=F.Profile()
    return profile and profile.current.elapsed or 0
end

function F.Price(itemLink,source,snapshot)
    local id=U.ItemID(itemLink)
    local info=A.Valuation.ItemInfo(itemLink)
    if not info then return nil,"loading" end
    if not U.Number(info.vendor,0,MAX,true) then return nil,"unavailable" end
    local vendor=math.floor(info.vendor)
    if source=="quest" or not D.Settings().farmUseAuction or info.quality==0 or info.bindType==1 or info.classID==12 then
        return vendor,"vendor"
    end
    snapshot=snapshot or D.Snapshot()
    local price,mode=D.Price(id,itemLink,snapshot)
    -- Exact variants and fresh scans only; an unrelated green is not income.
    if snapshot and not D.IsStale(snapshot) and price and
       (not U.VariantKey(itemLink) or mode=="variant") then
        local net=math.floor(price.low*(100-D.Settings().marketFee)/100)
        if net>vendor and net*100>=vendor*(100+D.Settings().farmThreshold) then return net,"AH net" end
    end
    return vendor,"vendor"
end

local function Recent(session,row)
    table.insert(session.recent,1,row)
    if #session.recent>MAX_RECENT then table.remove(session.recent) end
end

function F.AddMoney(amount,quest)
    if not Amount(amount) or amount==0 or not F.Active() or (quest and not D.Settings().farmIncludeQuest) then return false end
    local session=F.Profile().current
    local field=quest and "questCoins" or "coins"
    if not Amount(session[field]+amount) then return false end
    session[field]=session[field]+amount
    Recent(session,{time=U.Now(),name=quest and "Quest gold" or "Looted gold",amount=amount,kind="money"})
    F.revision=F.revision+1;return true
end

function F.AddItem(itemLink,quantity,source,settledSession)
    local profile=F.Profile()
    local session=profile and profile.current
    if not session or (settledSession~=session and not F.Active()) or not U.String(itemLink) or #itemLink>2048 or not U.ItemID(itemLink) or
       not U.Number(quantity,1,1000000,true) or (source~="loot" and source~="quest") or
       (source=="quest" and not D.Settings().farmIncludeQuest) then return false end
    local key=(U.VariantKey(itemLink) or tostring(U.ItemID(itemLink))) .. "|" .. source
    local item=session.items[key]
    if not item then
        if session.itemTypes>=MAX_ITEMS then F.reason="Session item limit reached. Reset the session to keep collecting.";return false end
        item={link=itemLink,id=U.ItemID(itemLink),quantity=0,source=source,name=U.LinkName(itemLink) or A.Valuation.MaterialName(U.ItemID(itemLink))}
        session.items[key]=item;session.itemTypes=session.itemTypes+1
    end
    if not U.Table(item) or not U.Number(item.quantity,0,1000000000,true) or item.quantity+quantity>1000000000 then return false end
    item.quantity=item.quantity+quantity
    local unit,mode=F.Price(itemLink,source)
    if unit and not U.Number(unit*item.quantity,0,MAX) then unit,mode=nil,"unavailable" end
    if mode=="loading" then U.Call(C_Item and C_Item.RequestLoadItemDataByID,item.id) end
    item.unit,item.mode=unit,mode
    Recent(session,{time=U.Now(),name=item.name,link=itemLink,quantity=quantity,amount=unit and unit*quantity,kind=source})
    F.revision=F.revision+1;F.summary=nil;return true
end

function F.Summary()
    local profile=F.Profile()
    if not profile then return {total=0,perHour=0,elapsed=0,unknown=0,items={},recent={}} end
    local session=profile.current
    local snapshot=D.Snapshot()
    local signature=table.concat({F.revision,D.Settings().farmThreshold,D.Settings().marketFee,tostring(D.Settings().farmUseAuction),
        tostring(snapshot and D.IsStale(snapshot))},"|")
    local result=F.summary
    if not result or result.signature~=signature or result.snapshot~=snapshot or result.session~=session then
        result={total=session.coins+session.questCoins,coins=session.coins,questCoins=session.questCoins,
            lootValue=0,questValue=0,unknown=0,items={},recent=session.recent,signature=signature,snapshot=snapshot,session=session}
        local count=0
        for _,item in pairs(session.items) do
            count=count+1;if count>MAX_ITEMS then F.reason="Oversized session preserved.";break end
            if U.Table(item) and U.String(item.link) and U.Number(item.quantity,0,1000000000,true) then
                local unit,mode=F.Price(item.link,item.source,snapshot)
                if unit and not U.Number(unit*item.quantity,0,MAX) then unit,mode=nil,"unavailable" end
                local row={name=item.name,quantity=item.quantity,unit=unit,mode=mode,source=item.source,link=item.link}
                row.total=unit and unit*item.quantity
                if row.total then
                    result.total=result.total+row.total
                    local field=item.source=="quest" and "questValue" or "lootValue"
                    result[field]=result[field]+row.total
                else result.unknown=result.unknown+item.quantity end
                result.items[#result.items+1]=row
            end
        end
        table.sort(result.items,function(a,b)if (a.total or 0)==(b.total or 0) then return a.name<b.name end;return (a.total or 0)>(b.total or 0) end)
        F.summary=result
    end
    result.elapsed=session.elapsed
    result.perHour=session.elapsed>=60 and result.total/session.elapsed*3600 or 0
    result.paused=session.paused or not D.Settings().farmTracking or F.inWorld==false
    return result
end

function F.Pause(paused)
    local profile=F.Profile()
    if not profile then return false end
    F.Tick();profile.current.paused=paused==true;F.last=U.Mono();return true
end

function F.Reset()
    if U.Combat() then return false,"Reset the farming session outside combat." end
    local profile=F.Profile()
    if not profile then return false,F.reason end
    F.Tick()
    if #F.pending>0 then return false,"Recent loot is settling. Try again in a moment." end
    local summary=F.Summary()
    if summary.elapsed>0 then
        local top={};for index=1,math.min(#summary.items,10) do
            local item=summary.items[index];top[index]={name=item.name,quantity=item.quantity,total=item.total,mode=item.mode}
        end
        table.insert(profile.history,1,{startedAt=profile.current.startedAt,endedAt=U.Now(),elapsed=summary.elapsed,
            total=summary.total,coins=summary.coins,questCoins=summary.questCoins,
            lootValue=summary.lootValue,questValue=summary.questValue,unknown=summary.unknown,top=top})
        if #profile.history>MAX_HISTORY then table.remove(profile.history) end
    end
    profile.current=New();F.last=U.Mono();F.pending,F.questCredits,F.messages,F.messageRing={},{},{},{}
    F.summary,F.reason=nil,nil;F.revision=F.revision+1;return true
end

-- Match the client's localized self-loot formats. Group members' messages,
-- crafting, vendor purchases, mail and trades never become farming income.
local function Match(text,formatText)
    if not U.String(formatText) then return nil end
    local pattern,cursor,slots={},1,{}
    while cursor<=#formatText do
        local a,b,pos,kind=formatText:find("%%(%d*)%$?([sd])",cursor)
        local literal=formatText:sub(cursor,a and a-1 or #formatText)
        pattern[#pattern+1]=literal:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])","%%%1")
        if not a then break end
        slots[#slots+1]=tonumber(pos) or #slots+1
        pattern[#pattern+1]=kind=="d" and "(%d+)" or "(.-)"
        cursor=b+1
    end
    local captures={text:match("^" .. table.concat(pattern) .. "$")}
    if #captures==0 then return nil end
    local values={};for i,pos in ipairs(slots) do values[pos]=captures[i] end
    return values[1],tonumber(values[2]) or 1
end

function F.LootMessage(message,lineID)
    if not F.Active() or not U.String(message) or #message>2048 then return end
    if U.Number(lineID,1,9007199254740991,true) then
        if F.messages[lineID] then return end
        F.messageRing[#F.messageRing+1]=lineID;F.messages[lineID]=true
        if #F.messageRing>128 then F.messages[table.remove(F.messageRing,1)]=nil end
    end
    for _,formatName in ipairs({"LOOT_ITEM_SELF_MULTIPLE","LOOT_ITEM_SELF"}) do
        local itemLink,quantity=Match(message,_G[formatName])
        if U.ItemID(itemLink) and U.Number(quantity,1,1000000,true) then
            if #F.pending>=64 then F.reason="Loot receipt queue full; review the session.";return end
            F.pending[#F.pending+1]={link=itemLink,quantity=quantity,at=U.Mono(),session=F.Profile().current}
            return
        end
    end
end

function F.QuestLoot(questID,itemLink,quantity)
    if not U.Number(questID,1,2147483647,true) or not U.ItemID(itemLink) or
       not U.Number(quantity,1,1000000,true) then return end
    -- Keep a short credit even when quest income is switched off: its generic
    -- loot chat must not reclassify the reward as a monster drop.
    local key=U.VariantKey(itemLink) or tostring(U.ItemID(itemLink))
    local credit=F.questCredits[key]
    if credit and U.Mono()-credit.at<1 then credit.quantity=credit.quantity+quantity
    else F.questCredits[key]={at=U.Mono(),quantity=quantity} end
    F.AddItem(itemLink,quantity,"quest")
end

function F.Tick(flush)
    local now=U.Mono()
    local profile,key=F.Profile()
    if profile and F.last and F.player==key and F.Active() then
        -- Time is online wall time, including travel/combat. Logout, loading
        -- screens and manual pauses never extend the session.
        profile.current.elapsed=math.min(315360000,profile.current.elapsed+math.max(0,now-F.last))
    end
    F.player,F.last=key,now
    local remaining={}
    for _,item in ipairs(F.pending) do
        if flush or now-item.at>=1 then
            local variant=U.VariantKey(item.link) or tostring(U.ItemID(item.link))
            local credit=F.questCredits[variant]
            local skip=credit and math.abs(item.at-credit.at)<=1 and math.min(item.quantity,credit.quantity) or 0
            if skip>0 then credit.quantity=credit.quantity-skip end
            if item.quantity>skip and profile and profile.current==item.session then F.AddItem(item.link,item.quantity-skip,"loot",item.session) end
        else remaining[#remaining+1]=item end
    end
    F.pending=remaining
    for key,credit in pairs(F.questCredits) do if now-credit.at>3 then F.questCredits[key]=nil end end
end

function F.Event(event,...)
    local a,b,c=...
    if event=="PLAYER_LOGIN" or event=="PLAYER_ENTERING_WORLD" then F.inWorld=true;F.last=U.Mono()
    elseif event=="PLAYER_LEAVING_WORLD" or event=="PLAYER_LOGOUT" then F.Tick(true);F.inWorld=false;F.last=nil
    elseif event=="CHAT_MSG_LOOT" then F.LootMessage(a,select(11,...))
    elseif event=="CHAT_MSG_MONEY" then local amount=A.Cash.ParseLootMessage(a);if amount then F.AddMoney(amount,false) end
    elseif event=="QUEST_TURNED_IN" then F.AddMoney(c,true)
    elseif event=="QUEST_LOOT_RECEIVED" then F.QuestLoot(a,b,c)
    elseif event=="GET_ITEM_INFO_RECEIVED" then F.summary=nil end
end
