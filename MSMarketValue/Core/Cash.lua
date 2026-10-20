local _,A=...
local U,D,L,T=A.Util,A.DB,A.Ledger,A.Transactions
local C={hooks={},debits={},intents={},claims={},serial=0,lootAwards=0,expenses=0}
A.Cash=C
local MAX=1000000000000
local function Call(fn,...)
    if type(fn)~="function"then return nil end
    local ok,v=pcall(fn,...);if ok and U.Accessible(v)then return v end
end
local function Money(v)return U.Number(v,0,MAX,true)end
local function Name(v,fallback)return U.String(v)and #v>0 and #v<=180 and v or fallback end
local function Hook(object,key,fn)
    if not U.Table(object)or type(object[key])~="function"or type(hooksecurefunc)~="function"then return false end
    C.hooks[object]=C.hooks[object]or{}
    if C.hooks[object][key]then return true end
    local ok=pcall(hooksecurefunc,object,key,fn);if ok then C.hooks[object][key]=true end;return ok
end
function C.Reset()
    C.debits,C.intents,C.claims={},{},{};C.player=U.PlayerKey();C.balance=Call(GetMoney)
    C.mailPending,C.repairDrop,C.repairAttempt=nil,nil,nil
end
local function Domain()
    if T.trade or C.tradeOpen or(C.tradeClosed and U.Mono()-C.tradeClosed<1)then return "trade"end
    if A.auctionOpen or(C.auctionClosed and U.Mono()-C.auctionClosed<2)then return "auction"end
    if C.merchantOpen or T.vendorIntentAt then return "merchant"end
    if C.mailOpen or(C.mailPending and U.Mono()-C.mailPending.at<10)then return "mail"end
    if C.trainerOpen then return "trainer"end
    if C.taxiOpen then return "taxi"end
    return "other"
end
local function Consume(domain,amount,stamp)
    local observed=false
    for _,row in ipairs(C.debits)do
        if row.domain==domain and math.abs(row.at-stamp)<=4 then
            observed=true
            local take=math.min(amount,row.remaining);row.remaining=row.remaining-take;amount=amount-take
            if amount==0 then break end
        end
    end
    return amount,observed
end
function C.Claim(input)
    if not D.Settings().trackOther or not U.Table(input)or not Money(input.amount)then return end
    local domain=input.source=="Vendor"and input.kind=="vendor_buy"and"merchant"or
        input.source=="AH purchase"and input.kind=="buy"and"auction"or
        input.source=="Player trade"and input.kind=="tip_given"and"trade"or nil
    if not domain then return end
    local remaining,observed=Consume(domain,input.amount,U.Mono())
    -- A reconciled vendor batch can contain both buys and sells. Do not carry its
    -- unmatched gross amount into the next, unrelated wallet change.
    if remaining>0 and not observed and #C.claims<100 then C.claims[#C.claims+1]={domain=domain,amount=remaining,at=U.Mono()}end
end
function C.Intent(category,name,amount,domain,stamp)
    if not D.Settings().trackOther or not L.categoryTitles[category]then return end
    if amount~=nil and(not Money(amount)or amount==0)then return end
    if #C.intents>=100 then C.reason="Expense detail queue is full; review recent spending.";return end
    local intent={category=category,name=Name(name,L.categoryTitles[category]),amount=amount,
        domain=domain or"other",at=stamp or U.Mono(),time=math.floor(U.Now()),player=U.PlayerKey()}
    C.intents[#C.intents+1]=intent;return intent
end
function C.CheckRepair(all)
    local cost=Call(GetRepairAllCost);if not Money(cost)then C.repairQuote=nil;return end
    local old=C.repairQuote;C.repairQuote=cost
    if Money(old)and old>cost then C.repairDrop={amount=old-cost,at=U.Mono()}end
    local drop=C.repairDrop
    if drop and not drop.used and U.Mono()-drop.at<=1 and
       (all or Call(InRepairMode)==true or(C.repairAttempt and U.Mono()-C.repairAttempt<=1))then
        drop.used=true;drop.intent=C.Intent("repair",all and"Repair all"or"Item repairs",drop.amount,"merchant",drop.at)
    end
end
function C.MoneyChanged()
    if C.player~=U.PlayerKey()then C.Reset();return end
    local value=Call(GetMoney)
    if not Money(value)then C.balance=nil;C.reason="Wallet value unavailable; review recent spending.";return end
    local previous=C.balance;C.balance=value
    if not Money(previous)or value>=previous or not D.Settings().trackOther then return end
    if #C.debits>=256 then C.reason="Wallet change queue is full; review recent spending.";return end
    local domain=Domain()
    local row={remaining=previous-value,amount=previous-value,domain=domain,at=U.Mono(),time=math.floor(U.Now()),player=C.player}
    C.debits[#C.debits+1]=row
    for _,claim in ipairs(C.claims)do
        if claim.domain==domain and U.Mono()-claim.at<=4 and claim.amount>0 then
            local take=math.min(claim.amount,row.remaining);claim.amount=claim.amount-take;row.remaining=row.remaining-take
        end
    end
    if domain=="merchant"then C.CheckRepair(false)end
end
local function DomainsMatch(intent,row)
    if intent.domain==row.domain then return true end
    -- The native window may close before PLAYER_MONEY is delivered.
    if row.domain=="other"and(intent.domain=="taxi"or intent.domain=="trainer"or intent.domain=="mail"or(intent.domain=="merchant"and C.merchantClosed and U.Mono()-C.merchantClosed<2))then return true end
    return intent.domain=="other"and(row.domain=="trainer"or row.domain=="taxi")
end
local function SaveExpense(row,amount,category,name)
    if amount<=0 or row.player~=U.PlayerKey()then return end
    C.serial=C.serial+1
    T.Enqueue({kind="expense",name=name,category=category,quantity=1,amount=amount,fee=0,source="Game expense",time=row.time,
        autoKey="expense:"..row.time..":"..string.format("%.3f",row.at)..":"..C.serial})
    C.expenses=C.expenses+1
    -- Keep vendor item reconciliation independent of repairs made in its wallet interval.
    local before=T.vendorBase
    if category=="repair"and T.vendorIntentAt and before and row.at>=before.at then before.money=before.money-amount end
end
-- A vendor sale and repair may share one net wallet update. Matching bag value
-- plus the native repair-cost decrease explains the gross amounts without a guess.
function C.ReconcileVendorRepairs(before,current,total)
    if not D.Settings().trackOther then return end
    local difference=total-(current.money-before.money)
    if difference<=0 then return end
    local repairs,sum={},0
    for _,intent in ipairs(C.intents)do
        if not intent.done and intent.category=="repair"and intent.player==C.player and
           intent.at>=before.at and intent.at<=current.at and Money(intent.amount)then
            repairs[#repairs+1]=intent;sum=sum+intent.amount
        end
    end
    if sum~=difference then return end
    for _,intent in ipairs(repairs)do
        SaveExpense({at=intent.at,time=intent.time,player=intent.player},intent.amount,"repair",intent.name)
        Consume("merchant",intent.amount,intent.at);intent.done=true
    end
end

local function Prune()
    local intents={};for _,v in ipairs(C.intents)do if not v.done and U.Mono()-v.at<=10 then intents[#intents+1]=v end end;C.intents=intents
    local claims={};for _,v in ipairs(C.claims)do if v.amount>0 and U.Mono()-v.at<=4 then claims[#claims+1]=v end end;C.claims=claims
    if C.mailPending and U.Mono()-C.mailPending.at>10 then C.mailPending=nil end
end
function C.Tick(force)
    if C.player~=U.PlayerKey()then C.Reset();return end
    Prune();if #C.debits==0 then return end
    for _,intent in ipairs(C.intents)do
        if not intent.done and intent.player==C.player then
            local candidates,total={},0
            for _,row in ipairs(C.debits)do
                if row.remaining>0 and DomainsMatch(intent,row)and math.abs(row.at-intent.at)<=2 then
                    candidates[#candidates+1]=row;total=total+row.remaining
                end
            end
            if total>0 and(not intent.amount or total>=intent.amount)and(force or U.Mono()-intent.at>=.5)then
                local amount=intent.amount or total
                -- One entry for one observed action, even if money arrived in several updates.
                local first=candidates[1];SaveExpense(first,amount,intent.category,intent.name)
                for _,row in ipairs(candidates)do
                    local take=math.min(amount,row.remaining);row.remaining=row.remaining-take;amount=amount-take
                    if amount==0 then break end
                end
                intent.done=true
            end
        end
    end
    local retained={}
    for _,row in ipairs(C.debits)do
        local ready=force or U.Mono()-row.at>=2.5
        if not force and T.vendorIntentAt and U.Mono()-T.vendorIntentAt<3.5 and row.domain=="merchant"then ready=false end
        if not force and C.mailPending and row.domain=="mail"then ready=false end
        if ready then
            if row.remaining>0 and D.Settings().trackOther and row.domain~="auction"and row.domain~="trade"and
               (row.domain~="merchant"or D.Settings().trackVendor)then
                SaveExpense(row,row.remaining,"unclassified","Unclassified spending")
            end
        else retained[#retained+1]=row end
    end
    C.debits=retained;Prune()
end

-- Native localized money formats are used only on the dedicated loot event.
local function Escape(text)return(text:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])","%%%1"))end
local function FormatPattern(text,numeric)
    local result,positions={},{};local cursor,index=1,0
    while cursor<=#text do
        local first,last,position,kind=text:find("%%(%d*)%$?([sd])",cursor)
        if not first then result[#result+1]=Escape(text:sub(cursor));break end
        result[#result+1]=Escape(text:sub(cursor,first-1));index=index+1;positions[index]=tonumber(position)or index
        result[#result+1]=numeric and"(%d[%d%.,%s\194\160\226\128\175]*)"or"(.-)";cursor=last+1
    end
    return table.concat(result),positions
end
function C.ParseCoins(text)
    if not U.String(text)or #text>512 then return nil end
    text=text:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
    local total,found=0,false
    for _,entry in ipairs({{"GOLD_AMOUNT",10000,"[Gg]old"},{"SILVER_AMOUNT",100,"[Ss]ilver"},{"COPPER_AMOUNT",1,"[Cc]opper"}})do
        local formatText=_G[entry[1]]
        local pattern=U.String(formatText)and FormatPattern(formatText,true)or nil
        local amount=pattern and text:match(pattern)
        if not amount then pattern="(%d[%d%.,%s]*)%s*|T[^|]*"..entry[3].."[Ii]con[^|]*|t";amount=text:match(pattern)end
        if amount then
            amount=tonumber((amount:gsub("%D","")));if not Money(amount)then return nil end
            total=total+amount*entry[2];text=text:gsub(pattern,"",1);found=true
        end
    end
    if not found or not Money(total)or total<=0 or text:gsub("[%s%.,;\194\160\226\128\175]","")~=""then return nil end
    return total
end
function C.LootMessage(message)
    if not D.Settings().trackLoot or not U.String(message)or #message>1024 then return end
    for _,key in ipairs({"YOU_LOOT_MONEY","LOOT_MONEY_SPLIT","YOU_LOOT_MONEY_GUILD","LOOT_MONEY_SPLIT_GUILD"})do
        local formatText=_G[key]
        if U.String(formatText)then
            local pattern,positions=FormatPattern(formatText,false);local matches={message:match("^"..pattern.."$")}
            if #matches>0 then
                local money
                for index,position in ipairs(positions)do if position==1 then money=C.ParseCoins(matches[index]);break end end
                if not money then C.reason="Loot text could not be read; no amount was guessed.";return end
                local stamp=math.floor(U.Now());local day=L.LocalDay(stamp)
                T.Enqueue({kind="loot",name="Money looted",quantity=1,amount=money,cost=0,fee=0,source="Loot",time=stamp,lootDay=day,autoKey="loot:"..day})
                C.lootAwards=C.lootAwards+1;return
            end
        end
    end
end
function C.CaptureTrainer()
    C.trainer={};local count=Call(GetNumTrainerServices)
    if not U.Number(count,0,500,true)then return end
    for index=1,count do
        local cost=Call(GetTrainerServiceCost,index);local name=Call(GetTrainerServiceInfo,index)
        if Money(cost)and cost>0 then C.trainer[index]={cost=cost,name=Name(name,"Training")}end
    end
end
function C.CaptureTaxi()
    C.taxi={};local count=Call(NumTaxiNodes)
    if not U.Number(count,0,500,true)then return end
    for index=1,count do
        local cost=Call(TaxiNodeCost,index);if Money(cost)and cost>0 then C.taxi[index]={cost=cost,name=Name(Call(TaxiNodeName,index),"Flight")}end
    end
end
function C.CaptureMail()local price=Call(GetSendMailPrice);C.postage=Money(price)and price or nil end
function C.Install()
    if C.player~=U.PlayerKey()then C.Reset()end
    if C.balance==nil then C.balance=Call(GetMoney)end
    Hook(_G,"RepairAllItems",function(guild)
        if not U.Accessible(guild)or guild then
            C.repairAttempt=nil
            local drop=C.repairDrop
            if drop and U.Mono()-drop.at<=1 and drop.intent then drop.intent.done=true end
            return
        end
        C.repairAttempt=U.Mono();C.CheckRepair(true)
    end)
    Hook(_G,"BuyTrainerService",function(index)
        local row=U.Number(index,1,500,true)and C.trainer and C.trainer[index]
        C.Intent("training",row and("Training: "..row.name)or"Training",row and row.cost,"trainer")
    end)
    Hook(_G,"ConfirmTalentWipeDialog_Show",function(cost)C.respecQuote=Money(cost)and cost or nil end)
    Hook(_G,"ConfirmTalentWipe",function()C.Intent("respec","Talent reset",C.respecQuote,"other")end)
    Hook(_G,"TakeTaxiNode",function(index)
        local row=U.Number(index,1,500,true)and C.taxi and C.taxi[index]
        C.Intent("flight",row and("Flight: "..row.name)or"Flight",row and row.cost,"taxi")
    end)
    Hook(_G,"SetSendMailMoney",function(amount)C.mailGold=Money(amount)and amount or nil end)
    Hook(_G,"SendMail",function()
        C.mailPending={postage=C.postage,gold=C.mailGold,at=U.Mono(),time=math.floor(U.Now()),player=U.PlayerKey()}
    end)
    Hook(_G,"PurchaseSlot",function()C.Intent("bank","Bank storage",nil,"other")end)
    Hook(_G,"BuyGuildBankTab",function()C.Intent("bank","Guild bank tab",nil,"other")end)
    Hook(_G,"DepositGuildBankMoney",function(amount)C.Intent("bank","Guild bank deposit",amount,"other")end)
    Hook(C_StableInfo,"BuyStableSlot",function()C.Intent("services","Stable slot",nil,"other")end)
    Hook(_G,"GuildRegistrar_PurchaseCharter",function()C.Intent("services","Guild charter",nil,"other")end)
    Hook(_G,"GossipConfirmDialog_Show",function(id,_,cost)
        if U.Number(id,1,2147483647,true)and Money(cost)then C.gossip={id=id,cost=cost}end
    end)
    Hook(C_GossipInfo,"SelectOption",function(id,_,confirmed)
        if U.Accessible(confirmed)and confirmed and U.Number(id,1,2147483647,true)and C.gossip and id==C.gossip.id then
            C.Intent("services","Gossip service",C.gossip.cost,"other")
        end
    end)
end
function C.Event(event,a)
    if event=="PLAYER_LOGIN"then C.Install();C.Reset()
    elseif event=="ADDON_LOADED"then C.Install()
    elseif event=="PLAYER_MONEY"then C.MoneyChanged()
    elseif event=="CHAT_MSG_MONEY"then C.LootMessage(a)
    elseif event=="PLAYER_LOGOUT"then C.Tick(true)
    elseif event=="AUCTION_HOUSE_CLOSED"then C.auctionClosed=U.Mono()
    elseif event=="AUCTION_HOUSE_SHOW"then C.auctionClosed=nil
    elseif event=="MERCHANT_SHOW"then C.merchantClosed=nil;C.merchantOpen=true;C.Install();C.repairQuote=Call(GetRepairAllCost);C.repairDrop=nil
    elseif event=="MERCHANT_UPDATE"then C.CheckRepair(false)
    elseif event=="MERCHANT_CLOSED"then C.merchantOpen=false;C.merchantClosed=U.Mono()
    elseif event=="TRAINER_SHOW"then C.trainerOpen=true;C.Install();C.CaptureTrainer()
    elseif event=="TRAINER_UPDATE"or event=="TRAINER_SERVICE_INFO_NAME_UPDATE"then if C.trainerOpen then C.CaptureTrainer()end
    elseif event=="TRAINER_CLOSED"then C.trainerOpen=false
    elseif event=="TAXIMAP_OPENED"then C.taxiOpen=true;C.Install();C.CaptureTaxi()
    elseif event=="TAXIMAP_CLOSED"then C.taxiOpen=false
    elseif event=="TRADE_SHOW"then C.tradeOpen=true;C.tradeClosed=nil
    elseif event=="TRADE_CLOSED"or event=="TRADE_REQUEST_CANCEL"then C.tradeOpen=false;C.tradeClosed=U.Mono()
    elseif event=="MAIL_SHOW"then C.mailOpen=true;C.Install();C.mailGold=nil;C.CaptureMail()
    elseif event=="MAIL_SEND_INFO_UPDATE"then C.CaptureMail()
    elseif event=="MAIL_CLOSED"then C.mailOpen=false
    elseif event=="MAIL_FAILED"then C.mailPending=nil
    elseif event=="MAIL_SEND_SUCCESS"then
        local row=C.mailPending;C.mailPending=nil
        if row and row.player==U.PlayerKey()then
            if Money(row.postage)and row.postage>0 then C.Intent("postage","Postage",row.postage,"mail",row.at)end
            if Money(row.gold)and row.gold>0 then C.Intent("mail_gold","Gold sent by mail",row.gold,"mail",row.at)end
        end
    end
end
