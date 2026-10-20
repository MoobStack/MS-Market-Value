local _, A = ...
local U, D = A.Util, A.DB
local L = { revision = 0, limit = 10000 }
A.Ledger = L
local MAX_MONEY = 1000000000000
local kinds = { sale = true, buy = true, commission = true, vendor_sale = true, vendor_buy = true, expense = true }
local sources = { Manual=true, ["AH invoice"]=true, ["AH purchase"]=true, ["AH mail"]=true, Vendor=true, ["Craft quote"]=true }
function L.Income(kind) return kind == "sale" or kind == "commission" or kind == "vendor_sale" end

function L.Initialize()
    local saved = D.data.ledger
    if saved == nil then saved = { schema = 1, characters = {} }; D.data.ledger = saved end
    if not U.Table(saved) or not U.Accessible(saved.schema) or saved.schema ~= 1 or not U.Table(saved.characters) then
        L.reason = "Unsupported ledger data preserved."; return
    end
    L.data = saved
end

local function Optional(value, check)
    return U.Accessible(value) and (value == nil or check(value))
end
local function Money(value) return U.Number(value, 0, MAX_MONEY, true) end
local function Valid(row)
    return U.Table(row) and U.Number(row.id, 1, 9007199254740991, true) and U.Number(row.time, 0, U.Now(), true) and
        U.String(row.kind) and kinds[row.kind] and U.String(row.name) and #row.name > 0 and #row.name <= 256 and
        U.Number(row.quantity, 1, 1000000, true) and Money(row.amount) and Money(row.fee) and
        (not L.Income(row.kind) or row.fee <= row.amount) and Money(row.refund) and Optional(row.cost, Money) and
        Optional(row.tip, Money) and Optional(row.estimatedCost, function(v) return type(v)=="boolean" end) and
        Optional(row.autoKey, function(v) return U.String(v) and #v<=1024 end) and
        Optional(row.recipeID, function(v) return U.Number(v,1,2147483647,true) end) and
        Optional(row.itemID, function(v) return U.Number(v, 1, 2147483647, true) end) and
        Optional(row.invoiceKey, function(v) return U.String(v) and #v <= 1024 end) and
        Optional(row.invoiceExpiry, function(v) return U.Number(v, 0, 9007199254740991, true) end) and
        U.String(row.source) and sources[row.source] == true
end

function L.Profile(create)
    local key = U.PlayerKey()
    if not L.data or not key then return nil end
    local profile = L.data.characters[key]
    if not U.Accessible(profile) then return nil end
    if profile == nil and create then profile = { entries = {}, seen = {}, nextID = 1 }; L.data.characters[key] = profile end
    if not U.Table(profile) or not U.Table(profile.entries) or not U.Number(profile.nextID, 1, 9007199254740991, true) then return nil end
    if L.checkedProfile ~= profile then
        if not U.Accessible(profile.seen) then L.reason = "Restricted invoice index preserved."; return nil end
        if profile.seen == nil then profile.seen = {} end
        if not U.Table(profile.seen) or #profile.seen > 20000 then L.reason = "Invalid invoice index preserved."; return nil end
        for _, stamp in ipairs(profile.seen) do
            if not U.Table(stamp) or not U.String(stamp.key) or #stamp.key > 1024 or not U.Number(stamp.expiry,0,9007199254740991,true) or
               not U.Number(stamp.id,1,9007199254740991,true) then L.reason = "Invalid invoice index preserved."; return nil end
        end
        if not U.Accessible(profile.receipts) then return nil end
        if profile.receipts == nil then profile.receipts = {} end
        if not U.Table(profile.receipts) or #profile.receipts>20000 then L.reason="Invalid transaction index preserved.";return nil end
        for _,receipt in ipairs(profile.receipts) do
            if not U.Table(receipt) or not U.String(receipt.key) or #receipt.key>1024 or
               not U.Number(receipt.id,1,9007199254740991,true) or not U.Number(receipt.time,0,U.Now(),true) or
               not U.String(receipt.kind) or not kinds[receipt.kind] or not U.String(receipt.name) or
               not Money(receipt.amount) or not U.Number(receipt.quantity,1,1000000,true) or
               not Optional(receipt.itemID,function(v)return U.Number(v,1,2147483647,true)end) or
               not Optional(receipt.matched,function(v)return type(v)=="boolean"end) then
                L.reason="Invalid transaction index preserved.";return nil
            end
        end
        if not U.Accessible(profile.pending)then return nil end
        if profile.pending==nil then profile.pending={}end
        if not U.Table(profile.pending)or #profile.pending>100 then L.reason="Invalid pending transactions preserved.";return nil end
        for _,staged in ipairs(profile.pending)do
            if not U.Table(staged)or not U.Table(staged.input)or not Valid(staged.input)or
               not U.String(staged.player)or staged.player~=key then L.reason="Invalid pending transactions preserved.";return nil end
        end
        if #profile.entries > L.limit then L.reason = "Oversized ledger preserved; export/repair it before editing."; return nil end
        local ids = {}
        for _, row in ipairs(profile.entries) do
            if not Valid(row) or ids[row.id] or row.id >= profile.nextID then L.reason = "Invalid ledger records preserved; restore a backup before editing."; return nil end
            ids[row.id] = true
        end
        L.checkedProfile = profile;L.receiptIndex=nil
    end
    L.reason = nil
    return profile, key
end

function L.Stage(input)
    local profile,key=L.Profile(true)
    if not profile then return nil,L.reason or"Ledger unavailable; confirmed transaction could not be saved."end
    for _,staged in ipairs(profile.pending)do if staged.input.autoKey==input.autoKey then return profile.pending end end
    if #profile.pending>=100 then return nil,"Pending transaction limit reached. Free ledger space before continuing trades."end
    local row={id=profile.nextID,time=input.time,kind=input.kind,name=input.name,quantity=input.quantity,amount=input.amount,
        fee=input.fee or 0,refund=0,tip=0,itemID=input.itemID,source=input.source,autoKey=input.autoKey}
    if not Valid(row)or not U.String(row.autoKey)then return nil,"Confirmed transaction data could not be queued."end
    profile.pending[#profile.pending+1]={input=row,player=key}
    return profile.pending
end

function L.Maintain()
    local profile, key = L.Profile(false)
    if not profile then return end
    local day = math.floor(U.Now() / 86400)
    local stamp = key .. "|" .. day .. "|" .. D.Settings().ledgerDays
    if L.maintained == stamp then return end
    local cutoff, entries = (day - D.Settings().ledgerDays + 1) * 86400, {}
    for _, row in ipairs(profile.entries) do if row.time >= cutoff then entries[#entries + 1] = row end end
    if #entries ~= #profile.entries then profile.entries = entries; L.revision = L.revision + 1 end
    local seen = {}
    for _, stamp in ipairs(profile.seen) do if stamp.expiry + 120 >= U.Now() then seen[#seen + 1] = stamp end end
    profile.seen = seen
    local receipts={}
    for _,receipt in ipairs(profile.receipts)do if receipt.time+31*86400>=U.Now()then receipts[#receipts+1]=receipt end end
    if #receipts~=#profile.receipts then L.receiptIndex=nil end
    profile.receipts=receipts
    L.maintained = stamp
end

function L.Records()
    L.Maintain()
    local profile, key = L.Profile(false)
    if L.cache and L.cache.profile == profile and L.cache.revision == L.revision then return L.cache.rows, key end
    local rows,ordered,previous = {},true,nil
    for _,row in ipairs(profile and profile.entries or {})do
        rows[#rows+1]=row
        if previous and (row.time<previous.time or(row.time==previous.time and row.id<previous.id))then ordered=false end
        previous=row
    end
    if ordered then
        for index=1,math.floor(#rows/2)do rows[index],rows[#rows-index+1]=rows[#rows-index+1],rows[index]end
    else
        table.sort(rows,function(a,b)if a.time==b.time then return a.id>b.id end;return a.time>b.time end)
    end
    L.cache = { profile = profile, revision = L.revision, rows = rows }
    return rows, key
end

function L.Amounts(row)
    local net = L.Income(row.kind) and (row.amount + (row.tip or 0) - row.fee) or -(row.amount + row.fee)
    local profit = L.Income(row.kind) and row.cost ~= nil and (net - row.cost) or nil
    return net, profit
end

function L.Summary(filter)
    local rows = L.View(filter)
    if L.summary and L.summary.rows == rows then return L.summary end
    local result = { rows = rows, sales = 0, spend = 0, profit = 0, estimatedProfit=0, estimated=0, unknown = 0, refunds = 0, tips=0, byKind={} }
    for _, row in ipairs(rows) do
        local net, profit = L.Amounts(row)
        result.byKind[row.kind]=(result.byKind[row.kind] or 0)+net
        if L.Income(row.kind) then
            result.sales = result.sales + net; result.refunds = result.refunds + row.refund
            result.tips=result.tips+(row.tip or 0)
            if profit ~= nil then
                if row.estimatedCost then result.estimatedProfit=result.estimatedProfit+profit;result.estimated=result.estimated+1
                else result.profit = result.profit + profit end
            else result.unknown = result.unknown + 1 end
        else result.spend = result.spend - net end
    end
    result.flow = result.sales - result.spend; L.summary = result
    return result
end

function L.Record(input, editID, automatic)
    if U.Combat() and not automatic then return false, "Edit ledger entries outside combat." end
    if not U.Table(input) then return false, "Transaction data is unavailable." end
    for _,key in ipairs({"fee","refund","cost","tip","estimatedCost","itemID","invoiceKey","invoiceExpiry","autoKey","recipeID","source"}) do
        if not U.Accessible(input[key]) then return false, "Transaction data is restricted." end
    end
    if not U.Accessible(editID) then return false, "Entry identity is restricted." end
    local profile = L.Profile(true)
    if not profile then return false, L.reason or "Player/market ledger is unavailable." end
    L.Maintain()
    local existing
    if editID ~= nil then
        if not U.Number(editID, 1, 9007199254740991, true) then return false, "Choose an existing entry." end
        for index,row in ipairs(profile.entries) do if row.id == editID then existing = index; break end end
        if not existing then return false, "Entry no longer exists." end
    elseif #profile.entries >= L.limit then return false, "Ledger limit reached (10000). Export/remove older entries or shorten retention." end
    local old = existing and profile.entries[existing]
    if not old and input.autoKey then
        if not L.receiptIndex then L.receiptIndex={};for _,receipt in ipairs(profile.receipts)do L.receiptIndex[receipt.key]=receipt.id end end
        if L.receiptIndex[input.autoKey]then return false,"Transaction already recorded.",L.receiptIndex[input.autoKey]end
        if #profile.receipts>=20000 then return false,"Transaction index full; export records and wait for old receipts to expire." end
    end
    local row = { id = old and old.id or profile.nextID, time = old and old.time or (automatic and U.Number(input.time,0,U.Now(),true) and input.time or math.floor(U.Now())),
        kind = input.kind, name = input.name, quantity = input.quantity, amount = input.amount,
        fee = input.fee or 0, cost = input.cost, refund = input.refund or (old and old.refund) or 0, itemID = input.itemID,
        tip=input.tip or 0, estimatedCost=input.estimatedCost, recipeID=input.recipeID,
        autoKey=old and old.autoKey or input.autoKey,
        source = old and old.source or input.source or (input.invoiceKey and "AH invoice" or "Manual"),
        invoiceKey = old and old.invoiceKey or input.invoiceKey, invoiceExpiry = old and old.invoiceExpiry or input.invoiceExpiry }
    if not Valid(row) then return false, "Enter a name, quantity and valid totals. Sale fees cannot exceed the sale amount." end
    if row.invoiceKey then
        if not row.invoiceExpiry then return false, "Invoice identity is incomplete; use a manual entry." end
        local unchanged=old and old.invoiceKey==row.invoiceKey and old.invoiceExpiry==row.invoiceExpiry
        for _, stamp in ipairs(profile.seen) do
            if not automatic and not unchanged and stamp.id ~= row.id and stamp.key == row.invoiceKey and math.abs(stamp.expiry - row.invoiceExpiry) <= 120 then
                return false, "A similar invoice was already imported. Review the ledger or use a manual entry for a separate identical transaction."
            end
        end
        for _, previous in ipairs(profile.entries) do
            if not automatic and not unchanged and previous.id ~= row.id and previous.invoiceKey == row.invoiceKey and previous.invoiceExpiry and
               math.abs(previous.invoiceExpiry - row.invoiceExpiry) <= 120 then
                return false, "A similar invoice is already recorded. Use New manual entry for a separate identical transaction."
            end
        end
        local known = false
        for _, stamp in ipairs(profile.seen) do if stamp.id == row.id and stamp.key == row.invoiceKey then known = true; break end end
        if not known then
            if #profile.seen >= 20000 then return false, "Invoice history limit reached; wait for old mail identities to expire." end
            profile.seen[#profile.seen+1] = {key=row.invoiceKey,expiry=row.invoiceExpiry,id=row.id}
        end
    end
    if existing then profile.entries[existing] = row else profile.entries[#profile.entries + 1] = row; profile.nextID = profile.nextID + 1 end
    if not old and row.autoKey then
        profile.receipts[#profile.receipts+1]={key=row.autoKey,id=row.id,time=row.time,kind=row.kind,name=row.name,
            quantity=row.quantity,amount=row.amount,itemID=row.itemID}
        L.receiptIndex[row.autoKey]=row.id
    end
    if row.time<(math.floor(U.Now()/86400)-D.Settings().ledgerDays+1)*86400 then L.maintained=nil end
    L.revision = L.revision + 1; L.lastDeleted = nil
    return true, row.id
end

function L.Commission(row,price,tip,quantity)
    if not U.Table(row)or not U.String(row.name)then return false,"Select a recipe first."end
    if not Money(tip)or not U.Number(quantity,1,1000000,true)then return false,"Use a valid total tip and a whole quantity (at least 1)."end
    local fixed=not row.service and U.Number(row.quantityMin,1,1000000,true)and U.Number(row.quantityMax,1,1000000,true)and row.quantityMin==row.quantityMax
    local divisor=fixed and row.quantityMin or 1
    if price==nil then
        local quote=A.Crafting.DisplayQuote(row)
        if not U.Number(quote,0,MAX_MONEY)then return false,"Quote unavailable. Enter the price received."end
        price=math.floor(quote/divisor+.5)
    end
    if not Money(price)or not Money(price*quantity+tip)then return false,"Enter a valid price and total."end
    local cost,estimate
    if row.service and D.Settings().serviceCustomerMaterials then cost=0
    elseif U.Number(row.cost,0,MAX_MONEY)then cost=math.ceil(row.cost/divisor*quantity);estimate=true end
    return L.Record({kind="commission",name=row.name,itemID=row.outputID,recipeID=row.recipeID,quantity=quantity,
        amount=price*quantity,tip=tip,fee=0,cost=cost,estimatedCost=estimate,source="Craft quote"})
end

function L.Remove(id)
    if U.Combat() or not U.Number(id,1,9007199254740991,true) then return false end
    local profile, key = L.Profile(false)
    if not profile then return false end
    for index,row in ipairs(profile.entries) do
        if row.id == id then
            L.lastDeleted = { key = key, row = row }; table.remove(profile.entries,index); L.revision = L.revision + 1; return true
        end
    end
    return false
end

function L.Undo()
    if U.Combat() or not L.lastDeleted then return false end
    local profile, key = L.Profile(false)
    if not profile or key ~= L.lastDeleted.key or #profile.entries >= L.limit then return false end
    if L.lastDeleted.row.time < (math.floor(U.Now()/86400) - D.Settings().ledgerDays + 1)*86400 then return false end
    profile.entries[#profile.entries + 1] = L.lastDeleted.row; L.lastDeleted = nil; L.revision = L.revision + 1
    return true
end

-- The reviewed Forever mail UI exposes invoice totals, not a durable mail ID.
-- Import is an explicit preview. Ambiguous matching invoices need manual review.
function L.ReadInvoice(index)
    if not U.Number(index,1,10000,true)then return nil,"Invalid invoice index." end
    if type(GetInboxInvoiceInfo) ~= "function" or type(GetInboxHeaderInfo) ~= "function" then return nil, "Invoice API unavailable; enter the transaction manually." end
    local invoice, header = {pcall(GetInboxInvoiceInfo,index)}, {pcall(GetInboxHeaderInfo,index)}
    if not invoice[1] or not header[1] or not U.String(invoice[2]) or (invoice[2] ~= "seller" and invoice[2] ~= "buyer") then
        return nil, "Choose a completed AH invoice; pending sales and ordinary mail are not transactions."
    end
    if not U.String(invoice[3]) or #invoice[3] == 0 or #invoice[3] > 256 or not Money(invoice[5]) or invoice[5] <= 0 or
       not U.Number(invoice[12],1,1000000,true) or not U.Number(header[8],0,366) then
        return nil, "Invoice amounts, quantity or expiry are unavailable. Enter it manually."
    end
    local sale = invoice[2] == "seller"
    local fee, refund = 0, 0
    if sale then
        if not Money(invoice[7]) or not Money(invoice[8]) or invoice[8] > invoice[5] then return nil, "Invoice fee/deposit data is unavailable." end
        fee, refund = invoice[8], invoice[7]
    end
    local row = { kind = sale and "sale" or "buy", name = invoice[3], quantity = invoice[12], amount = invoice[5], fee = fee, refund = refund,
        invoiceExpiry = math.floor(U.Now() + header[8] * 86400 + 0.5) }
    row.invoiceKey = table.concat({row.kind,#row.name,row.name,row.quantity,string.format("%.0f",row.amount),fee,refund},"|")
    if type(GetInboxItem) == "function" then
        local item = {pcall(GetInboxItem,index,1)}
        if item[1] and U.Number(item[3],1,2147483647,true) then row.itemID = item[3] end
    end
    return row
end

function L.ReadOpenInvoice()
    local inbox,frame=InboxFrame,OpenMailFrame
    if U.Combat() or not U.Table(inbox) or not U.Table(frame) or not frame.IsShown or not frame:IsShown() or
       (frame.IsForbidden and frame:IsForbidden()) or not U.Number(inbox.openMailID,1,10000,true)then
        return nil,"Open an AH purchase/sale invoice in your mailbox first."
    end
    return L.ReadInvoice(inbox.openMailID)
end

-- Count matching receipts, so several identical invoices visible together are
-- distinct transactions. The expiry tolerance also recognises older imports.
function L.ImportInvoice(row,ordinal)
    local profile=L.Profile(true)
    if not profile or not U.Table(row) or not U.String(row.invoiceKey) or not U.Number(row.invoiceExpiry,0)then return false,"Invoice identity unavailable."end
    local matched=0
    for _,stamp in ipairs(profile.seen)do
        if stamp.key==row.invoiceKey and math.abs(stamp.expiry-row.invoiceExpiry)<=120 then matched=matched+1 end
    end
    if matched>=(ordinal or 1)then return true,"already recorded" end
    if #profile.seen>=20000 then return false,"Invoice index full." end
    if row.kind=="buy"then
        local candidate
        for _,receipt in ipairs(profile.receipts)do
            if receipt.kind=="buy" and not receipt.matched and receipt.amount==row.amount and receipt.quantity==row.quantity and
               ((row.itemID and receipt.itemID==row.itemID) or receipt.name==row.name) and receipt.time<=U.Now() and
               (not candidate or receipt.time<candidate.time)then candidate=receipt end
        end
        if candidate then
            candidate.matched=true
            profile.seen[#profile.seen+1]={key=row.invoiceKey,expiry=row.invoiceExpiry,id=candidate.id}
            for _,existing in ipairs(profile.entries)do if existing.id==candidate.id then existing.invoiceKey,existing.invoiceExpiry=row.invoiceKey,row.invoiceExpiry end end
            L.revision=L.revision+1;return true,"purchase reconciled"
        end
    end
    row.source="AH mail"
    return L.Record(row,nil,true)
end

-- Dates use UTC, matching saved market history and CSV exports.
function L.DateDay(text)
    if not U.String(text)then return nil end
    local y,m,d=string.match(text,"^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
    y,m,d=tonumber(y),tonumber(m),tonumber(d)
    if not y or y<1970 or y>2200 or m<1 or m>12 or d<1 then return nil end
    local leap=y%4==0 and (y%100~=0 or y%400==0)
    local lengths={31,leap and 29 or 28,31,30,31,30,31,31,30,31,30,31}
    if d>lengths[m]then return nil end
    y=y-(m<=2 and 1 or 0)
    local era=math.floor(y/400);local year=y-era*400
    local month=m+(m>2 and -3 or 9)
    return era*146097+year*365+math.floor(year/4)-math.floor(year/100)+math.floor((153*month+2)/5)+d-1-719468
end
function L.Range(period,first,last)
    if period=="custom"then
        local a,b=L.DateDay(first),L.DateDay(last)
        if not a or not b or a>b then return nil,"Use valid UTC dates: YYYY-MM-DD, from date first."end
        return {first=a*86400,last=(b+1)*86400-1}
    end
    local day=math.floor(U.Now()/86400)
    local days=period=="today" and 1 or (period=="7d"and 7 or (period=="30d"and 30 or nil))
    return {first=days and (day-days+1)*86400 or 0,last=(day+1)*86400-1}
end
function L.View(filter)
    local rows=L.Records()
    if not filter or (not filter.kind or filter.kind=="all")and not filter.first and not filter.last then return rows end
    local key=table.concat({filter.kind or"all",filter.first or 0,filter.last or 9007199254740991},"|")
    if L.view and L.view.source==rows and L.view.key==key then return L.view.rows end
    local result={}
    for _,row in ipairs(rows)do
        if (not filter.kind or filter.kind=="all"or row.kind==filter.kind)and row.time>=(filter.first or 0)and row.time<=(filter.last or 9007199254740991)then result[#result+1]=row end
    end
    L.view={source=rows,key=key,rows=result};return result
end

function L.CSV(filter)
    local function Text(value)
        value = tostring(value or "")
        if string.match(value,"^%s*[=+@%-]") then value = "'" .. value end
        return '"' .. string.gsub(value,'"','""') .. '"'
    end
    local lines = {"UTC,Type,Name,Quantity,TotalCopper,FeeCopper,CostCopper,NetCopper,ProfitCopper,ReturnedDepositCopper,Source,TipCopper,CostBasis"}
    for _,row in ipairs(L.View(filter)) do
        local net,profit = L.Amounts(row)
        lines[#lines+1] = table.concat({Text(date("!%Y-%m-%dT%H:%M:%SZ",row.time)),Text(row.kind),Text(row.name),row.quantity,row.amount,row.fee,
            row.cost ~= nil and row.cost or "",net,profit ~= nil and profit or "",row.refund,Text(row.source),row.tip or 0,
            Text(row.cost==nil and "Unknown"or(row.estimatedCost and"Craft estimate"or"Recorded"))},",")
    end
    return table.concat(lines,"\n")
end
