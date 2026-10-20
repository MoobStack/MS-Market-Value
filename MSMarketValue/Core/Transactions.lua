local _,A=...
local U,D,L=A.Util,A.DB,A.Ledger
local T={hooks={},pending={},queue={},captured=0,reconciled=0,skipped=0,serial=0,mailGeneration=0}
A.Transactions=T
local MAX=1000000000000
local function Call(fn,...)
    if type(fn)~="function"then return nil end
    local ok,value=pcall(fn,...)
    if ok and U.Accessible(value)then return value end
end
local function Money(v)return U.Number(v,0,MAX,true)end
local function Name(id,link)
    local item=A.Valuation.ItemInfo(link or id)
    return item and item.name or("Item "..id)
end
local function Warn(reason)
    T.reason=reason;T.skipped=T.skipped+1
    if not T.lastWarning or U.Mono()-T.lastWarning>=30 then
        T.lastWarning=U.Mono();U.Print("Ledger: "..reason)
    end
end
local function Hook(object,key,callback)
    if not U.Table(object) or type(object[key])~="function" or type(hooksecurefunc)~="function"then return false end
    T.hooks[object]=T.hooks[object]or{}
    if T.hooks[object][key]then return true end
    local ok=pcall(hooksecurefunc,object,key,callback)
    if ok then T.hooks[object][key]=true end
    return ok
end
function T.Save(input)
    local ok,why
    if input.kind=="loot"then ok,why=L.AddLoot(input.amount,input.time,input.lootDay)else ok,why=L.Record(input,nil,true)end
    if ok then T.captured=T.captured+1;return true end
    if why=="Transaction already recorded."then return true end
    T.reason=tostring(why);return false
end
function T.Enqueue(input)
    input.time=input.time or math.floor(U.Now())
    if A.Cash then A.Cash.Claim(input)end
    if T.Save(input)then return end
    local pending,why=L.Stage(input)
    if not pending then return Warn(why)end
    T.queue=pending
    Warn("A confirmed transaction is saved and waiting for ledger space. Export or shorten retention.")
end

-- Gold offers are read only. Acceptance/closure alone never records a transfer.
function T.ResetTrade()
    T.trade,T.closedTrade=nil,nil
end
local function TradeHidden()
    local frame=TradeFrame
    return U.Table(frame)and type(frame.IsShown)=="function"and Call(frame.IsShown,frame)==false
end
function T.ReadTrade()
    local row=T.trade
    if not row then return end
    -- The native close handler can clear offers before our TRADE_CLOSED callback.
    if row.final and TradeHidden()then return end
    local given,received=Call(GetPlayerTradeMoney),Call(GetTargetTradeMoney)
    if row.given~=given or row.received~=received then row.final=nil end
    row.given,row.received=given,received
end
function T.StartTrade()
    T.ResetTrade()
    T.tradeAPI=type(GetPlayerTradeMoney)=="function"and type(GetTargetTradeMoney)=="function"
    if not D.Settings().trackTrade or not T.tradeAPI then return end
    T.trade={player=U.PlayerKey()};T.ReadTrade()
end
function T.TradeAcceptUpdate(playerAccepted,targetAccepted)
    local row=T.trade
    if not row or(row.final and TradeHidden())then return end
    T.ReadTrade()
    row.final=nil
    -- Native success is authoritative; the final 1/1 update need not arrive separately.
    if U.Number(playerAccepted,0,1,true)and U.Number(targetAccepted,0,1,true)and(playerAccepted==1 or targetAccepted==1)and Money(row.given)and Money(row.received)then
        row.final={given=row.given,received=row.received}
    end
end
function T.TradeClosed()
    if T.trade then T.closedTrade=T.trade;T.closedTrade.closedAt=U.Mono();T.trade=nil end
end
function T.CompleteTrade()
    local row=T.closedTrade or T.trade
    T.ResetTrade()
    if not D.Settings().trackTrade or not row or row.player~=U.PlayerKey()or(row.closedAt and U.Mono()-row.closedAt>10)then return end
    if not row.final then return Warn("Trade completed without readable final gold offers. Record it manually.")end
    T.serial=T.serial+1
    local key="trade:"..U.Now()..":"..string.format("%.3f",U.Mono())..":"..T.serial
    for _,definition in ipairs({{"tip_received","Trade gold received",row.final.received},{"tip_given","Trade gold given",row.final.given}})do
        if definition[3]>0 then
            T.Enqueue({kind=definition[1],name=definition[2],quantity=1,amount=definition[3],fee=0,source="Player trade",autoKey=key..":"..definition[1]})
        end
    end
end
function T.TradeMessage(code,message)
    if not T.trade and not T.closedTrade then return end
    local name=U.Number(code,1,2147483647,true)and Call(GetGameMessageInfo,code)or nil
    if (U.String(name)and name=="ERR_TRADE_COMPLETE")or(U.String(message)and U.String(ERR_TRADE_COMPLETE)and message==ERR_TRADE_COMPLETE)then
        T.CompleteTrade()
    elseif (U.String(name)and string.match(name,"^ERR_TRADE"))or(U.String(message)and U.String(ERR_TRADE_CANCELLED)and message==ERR_TRADE_CANCELLED)then
        T.ResetTrade()
    end
end

local function AuctionRow(row)
    if not U.Table(row)or not U.Number(row.auctionID,1,9007199254740991,true)or not U.Table(row.itemKey)or
       not U.Number(row.itemKey.itemID,1,2147483647,true)or not U.Number(row.quantity,1,1000000,true)or
       not Money(row.buyoutAmount)or row.buyoutAmount==0 then return nil end
    local id=row.itemKey.itemID
    return {auctionID=row.auctionID,itemID=id,quantity=row.quantity,amount=row.buyoutAmount,name=Name(id,U.String(row.itemLink)and row.itemLink or nil)}
end
function T.ObserveBid(auctionID,amount)
    if not D.Settings().trackAH or not U.Number(auctionID,1,9007199254740991,true)or not Money(amount)then return end
    local ah=AuctionHouseFrame
    local frame=U.Table(ah)and ah.ItemBuyFrame
    local list=U.Table(frame)and frame.ItemList
    local row=U.Table(list)and Call(list.GetSelectedEntry,list)
    local data=AuctionRow(row)
    if not data or data.auctionID~=auctionID then data=T.selectedAuction end
    if not data or data.auctionID~=auctionID or data.amount~=amount then return end
    local count=0;for _ in pairs(T.pending)do count=count+1 end
    if count>=100 then return Warn("Too many pending AH purchases; mailbox invoices will fill in confirmed purchases.")end
    T.pending[auctionID]={row=data,at=U.Mono(),player=U.PlayerKey()}
end
function T.PurchaseCompleted(auctionID)
    if not U.Number(auctionID,1,9007199254740991,true)then return end
    local pending=T.pending[auctionID];T.pending[auctionID]=nil
    if not D.Settings().trackAH or not pending or pending.player~=U.PlayerKey()or U.Mono()-pending.at>120 then return end
    local row=pending.row
    T.Enqueue({kind="buy",name=row.name,itemID=row.itemID,quantity=row.quantity,amount=row.amount,fee=0,source="AH purchase",autoKey="ah:"..auctionID})
end
function T.StartCommodity(id,quantity)
    T.commodity=nil
    if D.Settings().trackAH and U.Number(id,1,2147483647,true)and U.Number(quantity,1,1000000,true)then
        T.commodity={itemID=id,quantity=quantity,name=Name(id),at=U.Mono(),player=U.PlayerKey()}
    end
end
function T.CommodityQuote(unit,total)
    local row=T.commodity
    if not row or not Money(unit)or unit==0 or not Money(total)or total==0 or U.Mono()-row.at>120 then return end
    row.total=total;row.confirmed=nil
end
function T.ConfirmCommodity(id,quantity)
    local row=T.commodity
    if row and U.Number(id,1,2147483647,true)and U.Number(quantity,1,1000000,true)and row.itemID==id and row.quantity==quantity and row.total then
        row.confirmed,row.at=true,U.Mono()
    end
end
function T.CommoditySucceeded()
    local row=T.commodity;T.commodity=nil
    if not D.Settings().trackAH or not row or not row.confirmed or row.player~=U.PlayerKey()or U.Mono()-row.at>120 then return end
    T.serial=T.serial+1
    T.Enqueue({kind="buy",name=row.name,itemID=row.itemID,quantity=row.quantity,amount=row.total,fee=0,source="AH purchase",
        autoKey="commodity:"..U.Now()..":"..string.format("%.3f",U.Mono())..":"..T.serial})
end

function T.RequestMail()
    if not T.mailOpen or not D.Settings().trackAH then return end
    T.mailGeneration=T.mailGeneration+1;T.mailDirty=true;T.mailJob=nil
end
function T.CaptureMailIndex(index)
    if not T.mailOpen or not D.Settings().trackAH or not U.Number(index,1,10000,true)then return end
    local row=L.ReadInvoice(index)
    if row then
        local count=Call(GetInboxNumItems)
        if U.Number(count,1,100,true)then
            local ordinal=0
            for current=1,count do
                local invoice=current==index and row or L.ReadInvoice(current)
                if invoice and invoice.invoiceKey==row.invoiceKey and math.abs(invoice.invoiceExpiry-row.invoiceExpiry)<=120 then
                    ordinal=ordinal+1
                    local ok,why=L.ImportInvoice(invoice,ordinal)
                    if ok and why=="purchase reconciled"then T.reconciled=T.reconciled+1
                    elseif ok and type(why)=="number"then T.captured=T.captured+1
                    elseif not ok then Warn(why or"Invoice could not be saved.")end
                end
            end
        end
    end
    T.RequestMail()
end
function T.MailTick()
    if not T.mailOpen or not D.Settings().trackAH then T.mailJob=nil;return end
    if T.mailDirty then
        local count=Call(GetInboxNumItems)
        if not U.Number(count,0,10000,true)then return end
        T.mailJob={count=count,index=1,rows={},generation=T.mailGeneration,player=U.PlayerKey()};T.mailDirty=false
    end
    local job=T.mailJob
    if not job then return end
    if job.player~=U.PlayerKey()or job.generation~=T.mailGeneration then T.mailJob=nil;return end
    local start=debugprofilestop and debugprofilestop()or 0
    for _=1,10 do
        if job.index>job.count then
            -- Publish a stable inbox snapshot only. Indexes are not mail IDs.
            local count=Call(GetInboxNumItems)
            if count~=job.count then T.RequestMail();return end
            if not job.commit then job.commit=1;job.groups={} end
            local committed=0
            while job.commit<=#job.rows and committed<10 do
                local row=job.rows[job.commit]
                local groups=job.groups[row.invoiceKey]or{};job.groups[row.invoiceKey]=groups
                local group
                for _,candidate in ipairs(groups)do if math.abs(candidate.expiry-row.invoiceExpiry)<=120 then group=candidate;break end end
                if not group then group={expiry=row.invoiceExpiry,count=0};groups[#groups+1]=group end
                group.count=group.count+1
                local ok,why=L.ImportInvoice(row,group.count)
                if ok and why=="purchase reconciled"then T.reconciled=T.reconciled+1
                elseif ok and type(why)=="number"then T.captured=T.captured+1
                elseif not ok then Warn(why or"Invoice could not be saved.")end
                job.commit=job.commit+1;committed=committed+1
                if debugprofilestop and debugprofilestop()-start>=A.FRAME_BUDGET_MS then return end
            end
            if job.commit<=#job.rows then return end
            T.mailJob=nil;return
        end
        local row=L.ReadInvoice(job.index)
        if row then job.rows[#job.rows+1]=row end
        job.index=job.index+1
        if debugprofilestop and debugprofilestop()-start>=A.FRAME_BUDGET_MS then return end
    end
end

local function Inventory()
    if type(GetMoney)~="function"or not U.Table(C_Container)or type(C_Container.GetContainerNumSlots)~="function"then return nil end
    local money=Call(GetMoney)
    if not Money(money)then return nil end
    local result={money=money,items={},at=U.Mono()}
    local bags=U.Number(NUM_BAG_SLOTS,0,11,true)and NUM_BAG_SLOTS or 4
    for bag=0,bags do
        local count=Call(C_Container.GetContainerNumSlots,bag)
        if not U.Number(count,0,100,true)then return nil end
        for slot=1,count do
            local info=Call(C_Container.GetContainerItemInfo,bag,slot)
            if info~=nil then
                if not U.Table(info)or not U.Number(info.itemID,1,2147483647,true)or not U.Number(info.stackCount,1,1000000,true)or not U.String(info.hyperlink)then return nil end
                local key=U.VariantKey(info.hyperlink)
                if not key then return nil end
                local item=result.items[key]
                if not item then
                    local value=A.Valuation.ItemInfo(info.hyperlink)
                    item={id=info.itemID,name=value and value.name or("Item "..info.itemID),quantity=0,sell=value and value.vendor}
                    result.items[key]=item
                end
                item.quantity=item.quantity+info.stackCount
            end
        end
    end
    return result
end
function T.MerchantPrices()
    local prices,catalog,backPrices={},{},{}
    local count=Call(GetMerchantNumItems)
    if U.Number(count,0,500,true)then
        for index=1,count do
            local info=U.Table(C_MerchantFrame)and Call(C_MerchantFrame.GetItemInfo,index)
            if not info and type(GetMerchantItemInfo)=="function"then
                local v={pcall(GetMerchantItemInfo,index)}
                if v[1]then info={price=v[4],stackCount=v[5],hasExtendedCost=v[9]}end
            end
            local key=U.VariantKey(Call(GetMerchantItemLink,index))
            if key and U.Table(info)and Money(info.price)and U.Number(info.stackCount,1,1000000,true)and
               U.Accessible(info.hasExtendedCost)and info.hasExtendedCost==false then
                prices[key]=info.price/info.stackCount;catalog[index]={key=key,unit=info.price/info.stackCount}
            end
        end
    end
    -- A buyback is a new vendor purchase. Its actual total is known separately.
    local back=Call(GetNumBuybackItems)
    if U.Number(back,0,12,true)and type(GetBuybackItemInfo)=="function"then
        for index=1,back do
            local v={pcall(GetBuybackItemInfo,index)}
            local key=U.VariantKey(Call(GetBuybackItemLink,index))
            if key and v[1]and Money(v[4])and U.Number(v[5],1,1000000,true)then backPrices[index]={key=key,unit=v[4]/v[5]}end
        end
    end
    T.vendorPrices,T.vendorCatalog,T.vendorBuybacks=prices,catalog,backPrices
end
function T.ResetVendor()
    T.vendorIntentAt=nil;T.vendorDirty=false
    T.vendorBase=T.vendorOpen and D.Settings().trackVendor and Inventory()or nil
    if T.vendorOpen then T.MerchantPrices()end
end
function T.VendorIntent()
    if T.vendorOpen and D.Settings().trackVendor then
        T.vendorIntentAt=T.vendorIntentAt or U.Mono();T.vendorDirty=true;T.vendorDue=U.Mono()+.15
    end
end
function T.VendorTick()
    if not D.Settings().trackVendor then T.vendorBase=nil;T.vendorIntentAt=nil;T.vendorDirty=false;return end
    if not T.vendorDirty or (T.vendorDue and U.Mono()<T.vendorDue)then return end
    local current=Inventory();local before=T.vendorBase
    if not current then
        if T.vendorIntentAt and U.Mono()-T.vendorIntentAt>3 then Warn("Vendor item/money data unavailable; review this trade manually.");T.vendorDirty=false;T.vendorIntentAt=nil end
        return
    end
    if not before or not T.vendorIntentAt then T.vendorBase=current;T.vendorDirty=false;return end
    if T.vendorPlayer~=U.PlayerKey()then T.vendorBase=current;T.vendorIntentAt=nil;T.vendorDirty=false;return end
    local keys={};for key in pairs(before.items)do keys[key]=true end;for key in pairs(current.items)do keys[key]=true end
    local rows,total,valid={},0,true
    for key in pairs(keys)do
        local old,new=before.items[key],current.items[key]
        local delta=(new and new.quantity or 0)-(old and old.quantity or 0)
        if delta~=0 then
            local sale=delta<0;local item=sale and old or new
            local unit=sale and item.sell or(T.vendorPrices and T.vendorPrices[key])
            if not U.Number(unit,0,MAX)then valid=false;break end
            local amount=math.floor(math.abs(delta)*unit+.5)
            if not Money(amount)or(sale and amount==0)then valid=false;break end
            total=total+(sale and amount or -amount)
            rows[#rows+1]={kind=sale and"vendor_sale"or"vendor_buy",name=item.name,itemID=item.id,quantity=math.abs(delta),amount=amount,fee=0,source="Vendor"}
        end
    end
    if valid and #rows>0 and A.Cash then A.Cash.ReconcileVendorRepairs(before,current,total)end
    if valid and #rows>0 and current.money-before.money==total then
        for _,row in ipairs(rows)do
            T.serial=T.serial+1;row.autoKey="vendor:"..U.Now()..":"..string.format("%.3f",U.Mono())..":"..T.serial
            T.Enqueue(row)
        end
        T.vendorBase=current;T.vendorIntentAt=nil;T.vendorDirty=false;T.reason=nil
        if T.vendorOpen then T.MerchantPrices()end
    elseif U.Mono()-T.vendorIntentAt>3 then
        Warn("Vendor changes did not match the item prices and wallet. Review this trade manually.")
        T.vendorBase=current;T.vendorIntentAt=nil;T.vendorDirty=false
    end
end

function T.SyncQueue()
    local profile,key=L.Profile(false)
    T.queue=profile and profile.pending or {};T.queuePlayer=key
end
function T.Install()
    T.SyncQueue()
    T.tradeAPI=type(GetPlayerTradeMoney)=="function"and type(GetTargetTradeMoney)=="function"
    local ah=C_AuctionHouse
    T.purchaseHook=Hook(ah,"PlaceBid",T.ObserveBid)
    T.commodityHook=Hook(ah,"StartCommoditiesPurchase",T.StartCommodity)
    Hook(ah,"ConfirmCommoditiesPurchase",T.ConfirmCommodity)
    -- Cancel on a dialog hide can run before our success-event callback.
    -- Keep a confirmed request until success, explicit failure or timeout.
    Hook(ah,"CancelCommoditiesPurchase",function()if T.commodity and not T.commodity.confirmed then T.commodity=nil end end)
    local native=AuctionHouseFrame
    local item=U.Table(native)and native.ItemBuyFrame
    Hook(item,"OnAuctionSelected",function(_,row)T.selectedAuction=AuctionRow(row)end)
    Hook(_G,"BuyMerchantItem",function(index)
        T.VendorIntent();local row=U.Number(index,1,500,true)and T.vendorCatalog and T.vendorCatalog[index]
        if row then T.vendorPrices[row.key]=row.unit end
    end)
    Hook(_G,"BuybackItem",function(index)
        T.VendorIntent();local row=U.Number(index,1,12,true)and T.vendorBuybacks and T.vendorBuybacks[index]
        if row then T.vendorPrices[row.key]=row.unit end
    end)
    for _,key in ipairs({"SellCursorItem","PickupMerchantItem"})do Hook(_G,key,T.VendorIntent)end
    Hook(C_Container,"UseContainerItem",function()
        if type(InRepairMode)=="function"and Call(InRepairMode)==true then return end
        T.VendorIntent()
    end)
    Hook(C_MerchantFrame,"SellAllJunkItems",T.VendorIntent)
    for _,key in ipairs({"TakeInboxMoney","TakeInboxItem","DeleteInboxItem"})do Hook(_G,key,T.CaptureMailIndex)end
end
function T.Event(event,a,b)
    if event=="TRADE_SHOW"then T.StartTrade()
    elseif event=="TRADE_ACCEPT_UPDATE"then T.TradeAcceptUpdate(a,b)
    elseif event=="TRADE_CLOSED"then T.TradeClosed()
    elseif event=="TRADE_REQUEST_CANCEL"or event=="PLAYER_LOGOUT"then T.ResetTrade()
    elseif event=="TRADE_MONEY_CHANGED"or event=="PLAYER_TRADE_MONEY"or event=="TRADE_UPDATE"then T.ReadTrade()
    elseif event=="TRADE_PLAYER_ITEM_CHANGED"or event=="TRADE_TARGET_ITEM_CHANGED"then
        if T.trade and not(T.trade.final and TradeHidden())then T.trade.final=nil;T.ReadTrade()end
    elseif event=="UI_INFO_MESSAGE"or event=="UI_ERROR_MESSAGE"then T.TradeMessage(a,b)
    elseif event=="AUCTION_HOUSE_PURCHASE_COMPLETED"then T.PurchaseCompleted(a)
    elseif event=="COMMODITY_PRICE_UPDATED"then T.CommodityQuote(a,b)
    elseif event=="COMMODITY_PURCHASE_SUCCEEDED"then T.CommoditySucceeded()
    elseif event=="COMMODITY_PURCHASE_FAILED"or event=="COMMODITY_PRICE_UNAVAILABLE"then T.commodity=nil
    elseif event=="AUCTION_HOUSE_SHOW"then T.Install()
    elseif event=="MAIL_SHOW"then T.mailOpen=true;T.RequestMail()
    elseif event=="MAIL_INBOX_UPDATE"then T.RequestMail()
    elseif event=="MAIL_CLOSED"then T.mailOpen=false;T.mailJob=nil;T.mailDirty=false
    elseif event=="MERCHANT_SHOW"then
        T.Install();T.vendorOpen=true;T.vendorPlayer=U.PlayerKey();T.vendorIntentAt=nil
        T.vendorBase=Inventory();T.MerchantPrices()
    elseif event=="MERCHANT_UPDATE"then
        -- Preserve the pre-trade buyback prices until its changes reconcile.
        if not T.vendorIntentAt then T.MerchantPrices()end
        T.vendorDirty=true;T.vendorDue=U.Mono()+.15
    elseif event=="MERCHANT_CLOSED"then
        T.vendorOpen=false
        if T.vendorIntentAt then T.vendorDirty=true;T.vendorDue=U.Mono()+.15 else T.vendorBase=nil end
    elseif event=="PLAYER_MONEY"or event=="BAG_UPDATE_DELAYED"then
        if T.vendorOpen or T.vendorIntentAt then T.vendorDirty=true;T.vendorDue=U.Mono()+.15 end
    end
end
function T.Tick()
    if T.queuePlayer~=U.PlayerKey()then T.SyncQueue()end
    T.MailTick();T.VendorTick()
    if T.closedTrade and U.Mono()-T.closedTrade.closedAt>10 then T.closedTrade=nil end
    for id,pending in pairs(T.pending)do if U.Mono()-pending.at>120 then T.pending[id]=nil end end
    if T.commodity and U.Mono()-T.commodity.at>120 then T.commodity=nil end
    if #T.queue>0 and (not T.retryAt or U.Mono()>=T.retryAt)then
        T.retryAt=U.Mono()+2
        local row=T.queue[1]
        if row.player==U.PlayerKey()and T.Save(row.input)then table.remove(T.queue,1)end
    end
end
