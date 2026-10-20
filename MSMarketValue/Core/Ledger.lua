local _, A = ...
local U, D = A.Util, A.DB
local L = { revision = 0, limit = 2000 }
A.Ledger = L
local MAX_MONEY = 1000000000000
local kinds = { sale = true, buy = true, expense = true }

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
        (row.kind ~= "sale" or row.fee <= row.amount) and Money(row.refund) and Optional(row.cost, Money) and
        Optional(row.itemID, function(v) return U.Number(v, 1, 2147483647, true) end) and
        Optional(row.invoiceKey, function(v) return U.String(v) and #v <= 1024 end) and
        Optional(row.invoiceExpiry, function(v) return U.Number(v, 0, 9007199254740991, true) end) and
        U.String(row.source) and (row.source == "Manual" or row.source == "AH invoice")
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
        if not U.Table(profile.seen) or #profile.seen > 4000 then L.reason = "Invalid invoice index preserved."; return nil end
        for _, stamp in ipairs(profile.seen) do
            if not U.Table(stamp) or not U.String(stamp.key) or #stamp.key > 1024 or not U.Number(stamp.expiry,0,9007199254740991,true) or
               not U.Number(stamp.id,1,9007199254740991,true) then L.reason = "Invalid invoice index preserved."; return nil end
        end
        if #profile.entries > L.limit then L.reason = "Oversized ledger preserved; export/repair it before editing."; return nil end
        local ids = {}
        for _, row in ipairs(profile.entries) do
            if not Valid(row) or ids[row.id] or row.id >= profile.nextID then L.reason = "Invalid ledger records preserved; restore a backup before editing."; return nil end
            ids[row.id] = true
        end
        L.checkedProfile = profile
    end
    L.reason = nil
    return profile, key
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
    L.maintained = stamp
end

function L.Records()
    L.Maintain()
    local profile, key = L.Profile(false)
    if L.cache and L.cache.profile == profile and L.cache.revision == L.revision then return L.cache.rows, key end
    local rows = {}
    for _, row in ipairs(profile and profile.entries or {}) do rows[#rows + 1] = row end
    table.sort(rows, function(a,b) if a.time == b.time then return a.id > b.id end; return a.time > b.time end)
    L.cache = { profile = profile, revision = L.revision, rows = rows }
    return rows, key
end

function L.Amounts(row)
    local net = row.kind == "sale" and (row.amount - row.fee) or -(row.amount + row.fee)
    local profit = row.kind == "sale" and row.cost ~= nil and (net - row.cost) or nil
    return net, profit
end

function L.Summary()
    local rows = L.Records()
    if L.summary and L.summary.rows == rows then return L.summary end
    local result = { rows = rows, sales = 0, spend = 0, profit = 0, unknown = 0, refunds = 0 }
    for _, row in ipairs(rows) do
        local net, profit = L.Amounts(row)
        if row.kind == "sale" then
            result.sales = result.sales + net; result.refunds = result.refunds + row.refund
            if profit ~= nil then result.profit = result.profit + profit else result.unknown = result.unknown + 1 end
        else result.spend = result.spend - net end
    end
    result.flow = result.sales - result.spend; L.summary = result
    return result
end

function L.Record(input, editID)
    if U.Combat() then return false, "Edit ledger entries outside combat." end
    if not U.Table(input) then return false, "Transaction data is unavailable." end
    for _,key in ipairs({"fee","refund","cost","itemID","invoiceKey","invoiceExpiry"}) do
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
    elseif #profile.entries >= L.limit then return false, "Ledger limit reached (2000). Export/remove older entries or shorten retention." end
    local old = existing and profile.entries[existing]
    local row = { id = old and old.id or profile.nextID, time = old and old.time or U.Now(),
        kind = input.kind, name = input.name, quantity = input.quantity, amount = input.amount,
        fee = input.fee or 0, cost = input.cost, refund = input.refund or 0, itemID = input.itemID,
        source = input.invoiceKey and "AH invoice" or "Manual", invoiceKey = input.invoiceKey, invoiceExpiry = input.invoiceExpiry }
    if not Valid(row) then return false, "Enter a name, quantity and valid totals. Sale fees cannot exceed the sale amount." end
    if row.invoiceKey then
        if not row.invoiceExpiry then return false, "Invoice identity is incomplete; use a manual entry." end
        for _, stamp in ipairs(profile.seen) do
            if stamp.id ~= row.id and stamp.key == row.invoiceKey and math.abs(stamp.expiry - row.invoiceExpiry) <= 120 then
                return false, "A similar invoice was already imported. Review the ledger or use a manual entry for a separate identical transaction."
            end
        end
        for _, previous in ipairs(profile.entries) do
            if previous.id ~= row.id and previous.invoiceKey == row.invoiceKey and previous.invoiceExpiry and
               math.abs(previous.invoiceExpiry - row.invoiceExpiry) <= 120 then
                return false, "A similar invoice is already recorded. Use New manual entry for a separate identical transaction."
            end
        end
        local known = false
        for _, stamp in ipairs(profile.seen) do if stamp.id == row.id and stamp.key == row.invoiceKey then known = true; break end end
        if not known then
            if #profile.seen >= 4000 then return false, "Invoice history limit reached; wait for old mail identities to expire." end
            profile.seen[#profile.seen+1] = {key=row.invoiceKey,expiry=row.invoiceExpiry,id=row.id}
        end
    end
    if existing then profile.entries[existing] = row else profile.entries[#profile.entries + 1] = row; profile.nextID = profile.nextID + 1 end
    L.revision = L.revision + 1; L.lastDeleted = nil
    return true, row.id
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
function L.ReadOpenInvoice()
    local inbox, frame = InboxFrame, OpenMailFrame
    if U.Combat() or not U.Table(inbox) or not U.Table(frame) or not frame.IsShown or not frame:IsShown() or
       (frame.IsForbidden and frame:IsForbidden()) or not U.Number(inbox.openMailID,1,10000,true) then
        return nil, "Open an AH purchase/sale invoice in your mailbox first."
    end
    if type(GetInboxInvoiceInfo) ~= "function" or type(GetInboxHeaderInfo) ~= "function" then return nil, "Invoice API unavailable; enter the transaction manually." end
    local invoice, header = {pcall(GetInboxInvoiceInfo,inbox.openMailID)}, {pcall(GetInboxHeaderInfo,inbox.openMailID)}
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
        local item = {pcall(GetInboxItem,inbox.openMailID,1)}
        if item[1] and U.Number(item[3],1,2147483647,true) then row.itemID = item[3] end
    end
    return row
end

function L.CSV()
    local function Text(value)
        value = tostring(value or "")
        if string.match(value,"^%s*[=+@%-]") then value = "'" .. value end
        return '"' .. string.gsub(value,'"','""') .. '"'
    end
    local lines = {"UTC,Type,Name,Quantity,TotalCopper,FeeCopper,CostCopper,NetCopper,ProfitCopper,ReturnedDepositCopper,Source"}
    for _,row in ipairs(L.Records()) do
        local net,profit = L.Amounts(row)
        lines[#lines+1] = table.concat({Text(date("!%Y-%m-%dT%H:%M:%SZ",row.time)),Text(row.kind),Text(row.name),row.quantity,row.amount,row.fee,
            row.cost ~= nil and row.cost or "",net,profit ~= nil and profit or "",row.refund,Text(row.source)},",")
    end
    return table.concat(lines,"\n")
end
