local _, A = ...
local U, D, Metrics = A.Util, A.DB, A.FarmMetrics
local F={revision=0,historyRevision=0,pending={},questCredits={},receipts={},messages={},messageRing={},serial=0,ignoredMoney={}}
A.Farm=F
local MAX_ITEMS, MAX_RECENT, MAX_HISTORY = 500, 20, 50
F.limits={items=MAX_ITEMS,recent=MAX_RECENT,history=MAX_HISTORY}
local MAX=1000000000000
local interactions={{"merchant","MerchantFrame"},{"mail","MailFrame"},{"trade","TradeFrame"}}
F.sources={loot="Loot",quest="Quests",herbalism="Herbalism",mining="Mining",skinning="Skinning"}
function F.Harvest(kind) return kind=="herbalism" or kind=="mining" or kind=="skinning" end
local function Amount(v) return U.Number(v,0,MAX,true) end
local function New()
    return {startedAt=U.Now(),elapsed=0,coins=0,questCoins=0,items={},itemTypes=0,recent={},paused=false,idleElapsed=0,idlePaused=false,metrics=Metrics.New(0)}
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
    if profile==nil then profile={current=New(),history={},historyLimit=5};F.data.characters[key]=profile end
    local session=U.Table(profile) and profile.current
    if not U.Table(session) or not U.Table(session.items) or not U.Table(session.recent) or
       not U.Number(session.elapsed,0,315360000) or not Amount(session.coins) or not Amount(session.questCoins) or
       not U.Number(session.itemTypes,0,MAX_ITEMS,true) or #session.recent>MAX_RECENT or
       not U.Table(profile.history) or #profile.history>MAX_HISTORY or not U.Accessible(session.paused) or type(session.paused)~="boolean" then
        F.reason="Invalid farming session preserved.";return nil
    end
    if F.checked~=profile then
        if profile.historyLimit==nil then profile.historyLimit=5 end
        if not U.Number(profile.historyLimit,0,MAX_HISTORY,true) then F.reason="Invalid session limit preserved.";return nil end
        if session.idleElapsed==nil then session.idleElapsed=0 end
        if session.idlePaused==nil then session.idlePaused=false end
        if not U.Number(session.idleElapsed,0,315360000) or not U.Accessible(session.idlePaused) or type(session.idlePaused)~="boolean" then
            F.reason="Invalid idle timer preserved.";return nil
        end
        local count=0
        for key,item in pairs(session.items) do
            count=count+1
            if count>MAX_ITEMS or not U.String(key) or #key>256 or not U.Table(item) or not U.String(item.link) or
               #item.link>2048 or not U.ItemID(item.link) or not U.Number(item.quantity,1,1000000000,true) or
               not U.String(item.name) or #item.name>256 or not U.String(item.source) or
               not F.sources[item.source] then F.reason="Invalid farming item preserved.";return nil end
        end
        if count~=session.itemTypes then F.reason="Session counters did not match its items; session preserved.";return nil end
        if not Metrics.Validate(session) then F.reason="Invalid farming rate history preserved.";return nil end
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
            if not U.Accessible(record.items) or not U.Accessible(record.recent) then F.reason="Invalid saved session details preserved.";return nil end
            for _,field in ipairs({"items","recent"}) do
                local rows=record[field]
                if rows~=nil then
                    if not U.Table(rows) or #rows>(field=="items" and MAX_ITEMS or MAX_RECENT) then F.reason="Invalid saved session details preserved.";return nil end
                    for _,item in ipairs(rows) do
                        if not U.Table(item) or not U.String(item.name) or #item.name>256 or
                           not U.Accessible(item.link) or (item.link~=nil and (not U.String(item.link) or #item.link>2048 or not U.ItemID(item.link))) or
                           not U.Accessible(item.source) or (item.source~=nil and (not U.String(item.source) or not F.sources[item.source])) or
                           not U.Accessible(item.quantity) or (item.quantity~=nil and not U.Number(item.quantity,0,1000000000,true)) then
                            F.reason="Invalid saved session item preserved.";return nil
                        end
                        for _,key in ipairs({"total","amount","unit","time"}) do
                            if not U.Accessible(item[key]) or (item[key]~=nil and not U.Number(item[key],0,MAX)) then F.reason="Invalid saved session value preserved.";return nil end
                        end
                        if not U.Accessible(item.mode) or (item.mode~=nil and (not U.String(item.mode) or #item.mode>80)) then F.reason="Invalid saved session value preserved.";return nil end
                    end
                end
            end
        end
        F.checked=profile
    end
    return profile,key
end

function F.Accepting()
    local profile=F.Profile()
    return profile and D.Settings().farmTracking and not profile.current.paused and F.inWorld~=false and
        not (D.Settings().farmPauseOnDeath and F.dead)
end

function F.Active()
    local profile=F.Profile()
    return F.Accepting() and not F.waiting and (not D.Settings().farmIdle or not profile.current.idlePaused)
end

-- Account up to the idle boundary, including the whole grace period. Persist
-- online inactivity, never a monotonic timestamp or time spent logged out.
function F.Advance(profile,key,now)
    local session=profile and profile.current
    if session and not D.Settings().farmIdle then session.idlePaused=false;session.idleElapsed=0 end
    if session and F.last and F.player==key and D.Settings().farmTracking and not session.paused and F.inWorld~=false and
       not F.waiting and not (D.Settings().farmPauseOnDeath and F.dead) then
        local delta=math.max(0,now-F.last)
        if D.Settings().farmIdle and not F.combat then
            local boundary=D.Settings().farmIdleMinutes*60
            if session.idlePaused then delta=0 else delta=math.min(delta,math.max(0,boundary-session.idleElapsed)) end
            session.idleElapsed=math.min(boundary,session.idleElapsed+delta)
            if session.idleElapsed>=boundary then session.idlePaused=true end
        elseif F.combat then session.idleElapsed,session.idlePaused=0,false end
        session.elapsed=math.min(315360000,session.elapsed+delta)
        Metrics.Advance(session)
    end
    F.player,F.last=key,now
end

function F.Activity()
    if not F.Accepting() then return false end
    local profile,key=F.Profile()
    F.Advance(profile,key,U.Mono())
    F.waiting=nil
    profile.current.idleElapsed,profile.current.idlePaused=0,false
    return true
end

function F.IsDead()
    local value=U.Call(UnitIsDeadOrGhost,"player")
    if value==nil then value=U.Call(UnitIsDead,"player") end
    return value==true
end

function F.ConfigureDeath(enabled)
    if type(enabled)~="boolean" or not D.data then return false end
    F.Tick();D.data.settings.farmPauseOnDeath=enabled;F.dead=F.IsDead()
    if enabled and F.dead then F.waiting="death" end
    F.last=U.Mono();return true
end

function F.HistoryLimit()
    local profile=F.Profile()
    return profile and profile.historyLimit or 5
end

function F.SetHistoryLimit(limit)
    if not U.Number(limit,0,MAX_HISTORY,true) then return false,"Choose 0-50 saved sessions." end
    local profile=F.Profile()
    if not profile then return false,F.reason end
    profile.historyLimit=limit
    while #profile.history>limit do table.remove(profile.history) end
    F.historyRevision=F.historyRevision+1
    return true
end

-- Delete the exact selected record, never whichever index it later occupies.
function F.DeleteSession(record)
    local profile=F.Profile()
    if profile and U.Table(record) then
        for index,saved in ipairs(profile.history) do
            if saved==record then table.remove(profile.history,index);F.historyRevision=F.historyRevision+1;return true end
        end
    end
    return false,"That saved session is no longer available."
end

function F.ConfigureIdle(enabled,minutes)
    if not D.data then return false,"Farming settings are unavailable." end
    if type(enabled)~="boolean" or not U.Number(minutes,5,60,true) then return false,"Choose 5-60 whole minutes." end
    F.Tick()
    D.data.settings.farmIdle,D.data.settings.farmIdleMinutes=enabled,minutes
    D.data.settings.farmIdleConfigured=true
    local profile=F.Profile()
    if profile then profile.current.idleElapsed,profile.current.idlePaused=0,false end
    F.last=U.Mono();return true
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
    if not Amount(amount) or amount==0 or not F.Accepting() or (quest and not D.Settings().farmIncludeQuest) then return false end
    if quest then local profile,key=F.Profile();F.Advance(profile,key,U.Mono()) else F.Activity() end
    local session=F.Profile().current
    local field=quest and "questCoins" or "coins"
    if not Amount(session[field]+amount) then return false end
    session[field]=session[field]+amount
    Metrics.Record(session,amount,quest)
    Recent(session,{time=U.Now(),name=quest and "Quest gold" or "Looted gold",amount=amount,kind="money",source=quest and "quest" or "loot"})
    F.revision=F.revision+1;return true
end

function F.AddItem(itemLink,quantity,source,settledSession)
    local profile=F.Profile()
    local session=profile and profile.current
    if not session or (settledSession~=session and not F.Accepting()) or not U.String(itemLink) or #itemLink>2048 or not U.ItemID(itemLink) or
       not U.Number(quantity,1,1000000,true) or not U.String(source) or not F.sources[source] or
       (source=="quest" and not D.Settings().farmIncludeQuest) then return false end
    if settledSession~=session then
        if source=="quest" then local _,key=F.Profile();F.Advance(profile,key,U.Mono()) else F.Activity() end
    end
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
    Metrics.Record(session,unit and unit*quantity,source=="quest")
    Recent(session,{time=U.Now(),name=item.name,link=itemLink,quantity=quantity,amount=unit and unit*quantity,kind=source,source=source})
    F.revision=F.revision+1;F.summary=nil;return true
end

function F.Summary()
    local profile=F.Profile()
    if not profile then return {total=0,perHour=0,elapsed=0,unknown=0,items={},recent={}} end
    local session=profile.current
    local snapshot=D.Snapshot()
    local signature=table.concat({F.revision,D.Settings().farmThreshold,D.Settings().marketFee,tostring(D.Settings().farmUseAuction),
        tostring(snapshot and D.IsStale(snapshot)),tostring(D.Settings().farmQuestInRate)},"|")
    local result=F.summary
    if not result or result.signature~=signature or result.snapshot~=snapshot or result.session~=session then
        result={total=session.coins+session.questCoins,coins=session.coins,questCoins=session.questCoins,
            lootValue=0,questValue=0,harvestValue=0,unknown=0,items={},recent=session.recent,
            categories={loot=session.coins,quest=session.questCoins,herbalism=0,mining=0,skinning=0},
            signature=signature,snapshot=snapshot,session=session}
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
                    local field=item.source=="quest" and "questValue" or F.Harvest(item.source) and "harvestValue" or "lootValue"
                    result[field]=result[field]+row.total
                    result.categories[item.source]=(result.categories[item.source] or 0)+row.total
                else result.unknown=result.unknown+item.quantity end
                result.items[#result.items+1]=row
            end
        end
        table.sort(result.items,function(a,b)if (a.total or 0)==(b.total or 0) then return a.name<b.name end;return (a.total or 0)>(b.total or 0) end)
        F.summary=result
    end
    result.elapsed=session.elapsed
    result.rateValue=F.HourlyValue(result)
    result.perHour=session.elapsed>=60 and result.rateValue and result.rateValue/session.elapsed*3600 or 0
    Metrics.Summary(session,result,D.Settings().farmQuestInRate)
    result.idlePaused=not session.paused and (F.waiting~=nil or D.Settings().farmIdle and session.idlePaused)
    result.idleReason=result.idlePaused and (F.waiting or "inactive") or nil
    result.dead=D.Settings().farmPauseOnDeath and F.dead==true
    result.idleSeconds=session.idleElapsed
    result.paused=session.paused or result.idlePaused or result.dead or not D.Settings().farmTracking or F.inWorld==false
    return result
end

function F.HourlyValue(summary)
    if not U.Table(summary) or not U.Number(summary.total,0) then return nil end
    if D.Settings().farmQuestInRate then return summary.total end
    local gold,value=summary.questCoins,summary.questValue
    if not U.Accessible(gold) or not U.Accessible(value) then return nil end
    if gold~=nil and not Amount(gold) or value~=nil and not U.Number(value,0) then return nil end
    return math.max(0,summary.total-(gold or 0)-(value or 0))
end

function F.Pause(paused)
    local profile=F.Profile()
    if not profile then return false end
    F.Tick()
    if paused~=true and D.Settings().farmPauseOnDeath and F.dead then return false,"Resume after resurrecting." end
    profile.current.paused=paused==true
    if not paused then F.waiting=nil end
    profile.current.idleElapsed,profile.current.idlePaused=0,false
    F.last=U.Mono();return true
end

function F.Reset()
    if U.Combat() then return false,"Reset the farming session outside combat." end
    local profile=F.Profile()
    if not profile then return false,F.reason end
    F.Tick()
    if #F.pending>0 or #F.receipts>0 then return false,"Recent loot is settling. Try again in a moment." end
    local summary=F.Summary()
    if (summary.elapsed>0 or summary.total>0 or summary.unknown>0) and profile.historyLimit>0 then
        local top={};for index=1,math.min(#summary.items,10) do
            local item=summary.items[index];top[index]={name=item.name,quantity=item.quantity,total=item.total,mode=item.mode,source=item.source}
        end
        local items,recent={},{}
        for _,item in ipairs(summary.items) do
            items[#items+1]={name=item.name,link=item.link,quantity=item.quantity,total=item.total,unit=item.unit,mode=item.mode,source=item.source}
        end
        for _,item in ipairs(summary.recent) do
            recent[#recent+1]={name=item.name,link=item.link,quantity=item.quantity,amount=item.amount,source=item.source,time=item.time}
        end
        table.insert(profile.history,1,{startedAt=profile.current.startedAt,endedAt=U.Now(),elapsed=summary.elapsed,
            total=summary.total,coins=summary.coins,questCoins=summary.questCoins,
            lootValue=summary.lootValue,questValue=summary.questValue,harvestValue=summary.harvestValue,
            categories=summary.categories,unknown=summary.unknown,top=top,items=items,recent=recent,
            recentRate=summary.recentRate,recentDuration=summary.recentDuration,peak=summary.peak,
            recentFarmRate=summary.recentFarmRate,recentTotalRate=summary.recentTotalRate,ratePolicy=2,
            metricMissing=summary.metricMissing,metricsSince=summary.metricsSince})
        while #profile.history>profile.historyLimit do table.remove(profile.history) end
        F.historyRevision=F.historyRevision+1
    end
    profile.current=New();F.last=U.Mono();F.pending,F.questCredits,F.receipts,F.messages,F.messageRing={},{},{},{},{}
    F.ClearQuestContext();F.realLootAt=nil
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
    if not F.Accepting() or not F.ReceiptAllowed() or not U.String(message) or #message>2048 then return end
    if U.Number(lineID,1,9007199254740991,true) then
        if F.messages[lineID] then return end
        F.messageRing[#F.messageRing+1]=lineID;F.messages[lineID]=true
        if #F.messageRing>128 then F.messages[table.remove(F.messageRing,1)]=nil end
    end
    for _,formatName in ipairs({"LOOT_ITEM_SELF_MULTIPLE","LOOT_ITEM_SELF"}) do
        local itemLink,quantity=Match(message,_G[formatName])
        if U.ItemID(itemLink) and U.Number(quantity,1,1000000,true) then
            if #F.pending>=64 then F.reason="Loot receipt queue full; review the session.";return end
            local source=A.Drops.ReceiptKind(U.ItemID(itemLink))
            local worldLoot=A.Drops.lootOpen==true
            if not worldLoot and F.QuestContext() then source="quest" end
            if source=="quest" then local profile,key=F.Profile();F.Advance(profile,key,U.Mono()) else F.Activity() end
            F.pending[#F.pending+1]={link=itemLink,quantity=quantity,at=U.Mono(),session=F.Profile().current,source=source,worldLoot=worldLoot}
            return
        end
    end
end

function F.QuestLoot(questID,itemLink,quantity)
    if not U.Number(questID,1,2147483647,true) or not U.ItemID(itemLink) or
       not U.Number(quantity,1,1000000,true) then return end
    F.realLootAt=nil;F.lastQuestReceipt=U.Mono()
    -- Keep a short credit even when quest income is switched off: its generic
    -- loot chat must not reclassify the reward as a monster drop.
    local key=U.VariantKey(itemLink) or tostring(U.ItemID(itemLink))
    -- A generic quest receipt can settle before the dedicated event arrives.
    -- Confirm its counted quantity rather than adding the reward a second time.
    local profile=F.Profile()
    for _,receipt in ipairs(F.receipts) do
        if profile and receipt.session==profile.current and receipt.variant==key and
           U.Mono()-receipt.at<=5 and receipt.quantity>0 then
            local used=math.min(quantity,receipt.quantity)
            receipt.quantity=receipt.quantity-used;quantity=quantity-used
            if quantity==0 then return end
        end
    end
    local credit=F.questCredits[key]
    if credit and U.Mono()-credit.at<5 then credit.quantity=credit.quantity+quantity
    else F.questCredits[key]={at=U.Mono(),quantity=quantity} end
    F.AddItem(itemLink,quantity,"quest")
end

function F.Tick(flush)
    local now=U.Mono()
    F.SyncWindows()
    local profile,key=F.Profile()
    F.Advance(profile,key,now)
    local remaining={}
    for _,item in ipairs(F.pending) do
        if flush or now-item.at>=1 then
            local variant=U.VariantKey(item.link) or tostring(U.ItemID(item.link))
            local credit=not item.worldLoot and F.questCredits[variant]
            local skip=credit and math.abs(item.at-credit.at)<=5 and math.min(item.quantity,credit.quantity) or 0
            if skip>0 then credit.quantity=credit.quantity-skip end
            if item.quantity>skip and profile and profile.current==item.session then
                local source=item.source or "loot"
                if not item.worldLoot and F.QuestContext() and
                   (not F.lastQuest or math.abs(item.at-F.lastQuest)<=3) then source="quest" end
                if F.AddItem(item.link,item.quantity-skip,source,item.session) and source=="quest" then
                    F.receipts[#F.receipts+1]={variant=variant,quantity=item.quantity-skip,at=item.at,session=item.session}
                    if #F.receipts>64 then table.remove(F.receipts,1) end
                end
            end
        else remaining[#remaining+1]=item end
    end
    F.pending=remaining
    local receipts={}
    for _,receipt in ipairs(F.receipts) do
        if receipt.quantity>0 and now-receipt.at<=5 then receipts[#receipts+1]=receipt end
    end
    F.receipts=receipts
    for key,credit in pairs(F.questCredits) do if now-credit.at>6 then F.questCredits[key]=nil end end
end

function F.ClearQuestContext()
    F.questWindow,F.questOpenedAt,F.questFinished,F.lastQuest,F.lastQuestReceipt=nil,nil,nil,nil,nil
end

local function Shown(frame)
    if U.Accessible(frame) and frame and (type(frame)=="table" or type(frame)=="userdata") then return U.Call(frame.IsShown,frame) end
end

function F.SyncWindows()
    local now=U.Mono()
    for _,context in ipairs(interactions) do
        local key=context[1]
        if F[key.."Open"] and F[key.."OpenedAt"] and now-F[key.."OpenedAt"]>=.25 and Shown(_G[context[2]])==false then
            F[key.."Open"],F[key.."Closed"]=false,now
            F.recoveredWindows=(F.recoveredWindows or 0)+1
        end
    end
    if F.questWindow and F.questOpenedAt and now-F.questOpenedAt>=.25 and Shown(QuestFrame)==false then
        F.questWindow,F.questOpenedAt,F.questFinished=nil,nil,now
        F.recoveredWindows=(F.recoveredWindows or 0)+1
    end
end

function F.WorldReceipt()
    if A.Drops.lootOpen==true then return true end
    return F.realLootAt~=nil and U.Mono()-F.realLootAt<=3
end

function F.QuestContext()
    local now=U.Mono()
    -- A missing close event must not label the rest of a login as quest loot.
    local open=F.questWindow==true and F.questOpenedAt and
        (now-F.questOpenedAt<=60 or Shown(QuestFrame)==true)
    return open or (F.questFinished and now-F.questFinished<=3) or
        (F.lastQuest and now-F.lastQuest<=3) or (F.lastQuestReceipt and now-F.lastQuestReceipt<=3)
end

function F.ReceiptBlockReason()
    for _,key in ipairs({"mail","trade","merchant"})do
        if F[key.."Open"] then return key end
        if F[key.."Closed"] and U.Mono()-F[key.."Closed"]<=2 then return key.."_cooldown" end
    end
end
function F.ReceiptAllowed()
    return F.ReceiptBlockReason()==nil
end
function F.Event(event,...)
    local a,b,c=...
    if event=="PLAYER_LOGIN" or event=="PLAYER_ENTERING_WORLD" then
        for _,key in ipairs({"mail","trade","merchant"})do F[key.."Open"],F[key.."Closed"],F[key.."OpenedAt"]=false,nil,nil end
        F.ClearQuestContext();F.realLootAt=nil
        F.inWorld=true;F.last=U.Mono();F.combat=U.Combat()
        F.dead=F.IsDead()
        if event=="PLAYER_LOGIN" then F.waiting="login" end
        if D.Settings().farmPauseOnDeath and F.dead then F.waiting="death" end
        if F.combat then F.Activity() end
    elseif event=="PLAYER_DEAD" then
        F.Tick(true);F.dead=true;F.combat=false
        if D.Settings().farmPauseOnDeath then F.waiting="death" end
        F.last=U.Mono()
    elseif event=="PLAYER_ALIVE" or event=="PLAYER_UNGHOST" then
        F.Tick();F.dead=F.IsDead();F.last=U.Mono()
    elseif event=="PLAYER_REGEN_DISABLED" then
        F.Tick();F.ClearQuestContext();F.combat=true;F.Activity()
    elseif event=="PLAYER_REGEN_ENABLED" then
        F.Tick();F.combat=false
        local profile=F.Profile()
        if profile then profile.current.idleElapsed=0;profile.current.idlePaused=false end
    elseif event=="MAIL_SHOW" then F.mailOpen=true;F.mailClosed=nil;F.mailOpenedAt=U.Mono()
    elseif event=="MAIL_CLOSED" then F.mailOpen=false;F.mailClosed=U.Mono()
    elseif event=="TRADE_SHOW" then F.tradeOpen=true;F.tradeClosed=nil;F.tradeOpenedAt=U.Mono()
    elseif event=="TRADE_CLOSED" or event=="TRADE_REQUEST_CANCEL" then F.tradeOpen=false;F.tradeClosed=U.Mono()
    elseif event=="MERCHANT_SHOW" then F.merchantOpen=true;F.merchantClosed=nil;F.merchantOpenedAt=U.Mono()
    elseif event=="MERCHANT_CLOSED" then F.merchantOpen=false;F.merchantClosed=U.Mono()
    elseif event=="QUEST_COMPLETE" then F.realLootAt=nil;F.questWindow=true;F.questOpenedAt=U.Mono();F.questFinished=nil
    elseif event=="QUEST_FINISHED" then F.questWindow,F.questOpenedAt=nil,nil;F.questFinished=U.Mono()
    elseif event=="LOOT_READY" or event=="LOOT_OPENED" or event=="LOOT_SLOT_CHANGED" then
        if A.Drops.readWindows and A.Drops.worldLootRead==A.Drops.readWindows then F.ClearQuestContext();F.realLootAt=U.Mono() end
    elseif event=="PLAYER_LEAVING_WORLD" or event=="PLAYER_LOGOUT" then
        F.Tick(true);F.inWorld=false;F.last=nil;F.ClearQuestContext();F.realLootAt=nil
        for _,key in ipairs({"mail","trade","merchant"})do F[key.."Open"],F[key.."Closed"],F[key.."OpenedAt"]=false,nil,nil end
    elseif event=="CHAT_MSG_LOOT" then F.LootMessage(a,select(11,...))
    elseif event=="CHAT_MSG_MONEY" then
        local amount=A.Cash.ParseLootMessage(a)
        if amount then
            local reason=F.ReceiptBlockReason() or (F.QuestContext() and not F.WorldReceipt() and "quest")
            if reason then F.excludedReceipts=(F.excludedReceipts or 0)+1;F.ignoredMoney[reason]=(F.ignoredMoney[reason] or 0)+1
            else F.AddMoney(amount,false) end
        end
    elseif event=="QUEST_TURNED_IN" then F.realLootAt=nil;F.questWindow,F.questOpenedAt=nil,nil;F.lastQuest=U.Mono();F.AddMoney(c,true)
    elseif event=="QUEST_LOOT_RECEIVED" then F.QuestLoot(a,b,c)
    elseif event=="GET_ITEM_INFO_RECEIVED" then F.summary=nil end
end
