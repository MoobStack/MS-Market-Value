local _, A = ...
local U, D, H = A.Util, A.DB, A.History
local M = { rows = {}, builds = 0, publications = 0 }
A.Market = M
local MAX_PRICE, MAX_RESULTS, MAX_ITEMS = 1000000000000, 500, 50000
M.limit=MAX_RESULTS

local function Price(value) return U.Number(value, 0, MAX_PRICE) and value > 0 end
local function Quantile(values, fraction)
    local position = (#values - 1) * fraction + 1
    local low = math.floor(position)
    return values[low] + ((values[low + 1] or values[low]) - values[low]) * (position - low)
end

function M.Evaluate(current, samples, settings)
    if not Price(current) or not U.Table(samples) or #samples < settings.marketMinDays then return nil end
    local values, chronological = {}, {}
    for _, value in ipairs(samples) do
        if not Price(value) then return nil end
        values[#values + 1], chronological[#chronological + 1] = value, value
    end
    table.sort(values)
    -- The lower quartile is deliberately below the median. One inflated day
    -- should not create a resale signal or an unrealistic target sell price.
    local median, baseline = Quantile(values, 0.5), math.floor(Quantile(values, 0.25))
    local buy = math.ceil(current)
    local proceeds = math.floor(baseline * (100 - settings.marketFee) / 100)
    local profit = proceeds - buy
    local row = { current = current, buy = buy, baseline = baseline, median = median,
        low = values[1], high = values[#values], days = #values, profit = profit,
        roi = profit / buy * 100, movement = (current - median) / median * 100,
        maxBuy = math.max(0, math.floor(math.min(proceeds / (1 + settings.marketMinReturn / 100), proceeds - settings.marketMinProfit))) }
    -- Compare prices directly so an exact percentage boundary is inclusive.
    local drop = current < median and current <= median * (100 - settings.marketMove) / 100
    local rise = current > median and current >= median * (100 + settings.marketMove) / 100
    row.deal = profit >= settings.marketMinProfit and profit > 0 and row.roi >= settings.marketMinReturn and
        (settings.marketMove == 0 or drop)
    row.rising, row.falling = rise, drop
    if #chronological >= 5 then
        local recent = { chronological[#chronological - 1], chronological[#chronological], current }
        local older = { chronological[#chronological - 4], chronological[#chronological - 3], chronological[#chronological - 2] }
        table.sort(recent); table.sort(older)
        row.trend = (recent[2] / older[2] - 1) * 100
    end
    return row
end

local function Signature(view, sort)
    local s = D.Settings()
    return table.concat({ view, sort, s.marketLookback, s.marketMinDays, s.marketFee,
        s.marketMinReturn, s.marketMinProfit, s.marketMove, s.marketLowMin, s.marketLowMax,
        s.marketStockMin, s.marketStockMax, s.marketStockDrop, s.marketSearch, s.marketQuality,A.Vendor.revision }, "|")
end

local function Fresh(snapshot)
    return snapshot and U.Number(snapshot.startedAt, 0, U.Now()) and not D.IsStale(snapshot)
end

function M.Clear(reason)
    M.job, M.rows, M.snapshot, M.reason, M.ready = nil, {}, nil, reason, true
    M.source, M.signature, M.examined, M.eligible = nil, nil, 0, 0
    M.variantIndex=nil
end

function M.Ensure(view, sort, force)
    H.Maintain()
    view = (view == "rising" or view == "falling" or view == "all" or view=="listed") and view or "deals"
    sort = sort == "profit" and "profit" or "return"
    local market = U.MarketInfo()
    local key, snapshot = market.key, D.Snapshot(market)
    if not Fresh(snapshot) then M.Clear(snapshot and "The saved scan is stale. Complete a fresh AH scan for current signals." or "Complete an AH scan to look for opportunities."); return end
    if not H.data then M.Clear(H.reason or "Price history is unavailable."); return end
    local signature = Signature(view, sort)
    if M.key ~= key then M.rows, M.snapshot, M.job = {}, nil, nil end
    M.key = key
    -- Item replies can arrive continuously. Finish the current pass, then
    -- refresh once, rather than restarting it every quarter second.
    if not force and M.job and M.source==snapshot and M.historyRevision==H.revision and M.signature==signature then
        if M.metadataDirty then M.job.metadataDirty=true;M.metadataDirty=nil end
        return
    end
    force=force or M.metadataDirty;M.metadataDirty=nil
    if not force and M.source == snapshot and M.historyRevision == H.revision and M.signature == signature then return end
    M.source, M.historyRevision, M.signature = snapshot, H.revision, signature
    M.waiting,M.waitOrder,M.waitCursor={},{},1
    local settings = {}
    for name, value in pairs(D.Settings()) do if U.String(name) and string.sub(name, 1, 6) == "market" then settings[name] = value end end
    local day, records = math.floor(snapshot.startedAt / 86400), {}
    local days = H.Days(market) or {}
    for date = day - settings.marketLookback, day - 1 do
        local record = days[date]
        if record and record.startedAt < snapshot.startedAt then records[#records + 1] = record end
    end
    local modern=snapshot.variantFormat==2
    local index=M.variantIndex
    if index and (index.snapshot~=snapshot or not modern and
        (index.historyRevision~=H.revision or index.lookback~=settings.marketLookback)) then index=nil end
    local maps = { snapshot.variants }
    -- Current scans already identify every precise variant. Historic maps
    -- are only needed to protect old item-wide scans from mixed baselines.
    if not modern then for _, record in ipairs(records) do maps[#maps + 1] = record.variants end end
    local words={}
    for word in string.gmatch(string.lower(settings.marketSearch),"%S+") do words[#words+1]=word end
    M.job = { snapshot = snapshot, records = records, settings = settings, maps = maps, vendorKnown = A.Vendor.KnownItems(),
        mapIndex = 1, variants = index and index.variants or {}, currentVariants=index and index.currentVariants or {},
        phase = index and "prices" or "variants", words=words, rows = {}, examined = 0, eligible = 0,
        view = view, sort = sort, day = day, started = U.Mono() }
    M.ready, M.reason = false, nil
    M.builds = M.builds + 1
end

function M.QualityAllowed(mask,quality)
    if mask==63 and quality==nil then return true end
    return U.Number(mask,0,63,true) and U.Number(quality,0,5,true) and math.floor(mask/2^quality)%2==1
end

local function WaitForInfo(id)
    if M.waiting and not M.waiting[id] and #M.waitOrder<256 then
        M.waiting[id]=true;M.waitOrder[#M.waitOrder+1]=id
    end
end

local function DisplayName(row,item)
    local name=U.ItemName(row.link,item and item.name,row.scannedName) or A.Crafting.MaterialName(row.id)
    if row.itemWide then return name .. " (item-wide; rescan)" end
    if row.suffix and row.suffix~=0 and not U.LinkName(row.link) then return name .. " (variant " .. row.suffix .. ")" end
    return name
end

function M.RequestVisibleInfo(rows)
    for _,row in ipairs(rows) do
        local item=A.Valuation.ItemInfo(row.link)
        row.quality=U.ItemQuality(row.link,row.scannedQuality or (item and item.quality))
        row.r,row.g,row.b=U.ItemColor(row.link,row.quality)
        if not item or row.quality==nil then A.Drops.RequestName(row.id) end
        if item then row.name=DisplayName(row,item) end
    end
    local count=M.waitOrder and #M.waitOrder or 0
    for _=1,math.min(20,count) do
        local id=M.waitOrder[M.waitCursor];M.waitCursor=M.waitCursor%count+1
        if M.waiting[id] then A.Drops.RequestName(id) end
    end
end

local function Identity(key, variant)
    if variant then
        return U.SplitVariant(key)
    end
    if U.Number(key, 1, 2147483647, true) then return key end
end

local function Better(a, b, job)
    local av, bv
    if job.view == "rising" then av, bv = a.movement, b.movement
    elseif job.view == "falling" then av, bv = -a.movement, -b.movement
    elseif job.sort == "profit" then av, bv = a.profit, b.profit
    else av, bv = a.roi, b.roi end
    av,bv=av or -math.huge,bv or -math.huge
    if av == bv then return a.key < b.key end
    return av > bv
end

local function Include(job, row)
    if job.view=="listed" then return true end
    if job.view == "deals" then return row.deal end
    if job.view == "rising" then return row.rising end
    if job.view == "falling" then return row.falling end
    return row.deal or row.rising or row.falling
end

local function Matches(words,name)
    name=string.lower(name)
    for _,word in ipairs(words) do if not string.find(name,word,1,true) then return false end end
    return true
end

local function SupplyAllowed(settings,units,lowUnits,stockMove)
    return not ((settings.marketLowMin>0 and (not lowUnits or lowUnits<settings.marketLowMin)) or
        (settings.marketLowMax>0 and (not lowUnits or lowUnits>settings.marketLowMax)) or
        (settings.marketStockMin>0 and (not units or units<settings.marketStockMin)) or
        (settings.marketStockMax>0 and (not units or units>settings.marketStockMax)) or
        (settings.marketStockDrop>0 and (not stockMove or stockMove > -settings.marketStockDrop)))
end

-- Keep only the best 500 in a worst-first heap. Broad searches avoid
-- repeatedly shifting a sorted 500-row array for every matching item.
local function Retain(job,row)
    local rows=job.rows
    if #rows<MAX_RESULTS then
        rows[#rows+1]=row
        local child=#rows
        while child>1 do
            local parent=math.floor(child/2)
            if not Better(rows[parent],rows[child],job) then break end
            rows[parent],rows[child]=rows[child],rows[parent];child=parent
        end
    elseif Better(row,rows[1],job) then
        rows[1]=row
        local parent=1
        while parent*2<=#rows do
            local child=parent*2
            if child<#rows and Better(rows[child],rows[child+1],job) then child=child+1 end
            if not Better(rows[parent],rows[child],job) then break end
            rows[parent],rows[child]=rows[child],rows[parent];parent=child
        end
    end
end

local function Evaluate(job, key, entry, variant)
    job.examined = job.examined + 1
    local id, suffix, bonuses = Identity(key, variant)
    if not id or job.settings.marketQuality==0 or (not variant and job.variants[id] and (job.view~="listed" or job.currentVariants[id])) or (job.vendorKnown[id] and job.view~="listed") or
       not U.Table(entry) or not Price(entry.low) then return end
    local s=job.settings
    local units=U.Number(entry.units,1,1000000000,true) and entry.units or nil
    local lowUnits=U.Number(entry.lowUnits,1,1000000000,true) and entry.lowUnits or nil
    local previous=job.snapshot.previousSupply
    local prior=U.Table(previous) and U.Table(previous[variant and "variants" or "prices"]) and previous[variant and "variants" or "prices"][key]
    local stockMove=units and U.Number(prior,1,1000000000,true) and (units/prior-1)*100 or nil
    if not SupplyAllowed(s,units,lowUnits,stockMove) then return end
    local display=U.Table(entry.display) and entry.display or nil
    local scannedQuality=display and U.Number(display[1],0,8,true) and display[1] or nil
    if scannedQuality and not M.QualityAllowed(s.marketQuality,scannedQuality) then return end
    -- Ordinary links have a complete name. A modified item's generic link
    -- can gain its suffix when native data loads, so resolve those first.
    local linkedName=U.LinkName(entry.link)
    if #job.words>0 and variant and suffix==0 and not bonuses and linkedName and not Matches(job.words,linkedName) then return end
    local item=A.Valuation.ItemInfo(entry.link or id)
    local quality=U.ItemQuality(entry.link or id,scannedQuality or (item and item.quality))
    if not item and scannedQuality==nil and s.marketQuality~=63 then WaitForInfo(id) end
    if quality==nil and s.marketQuality~=63 then
        WaitForInfo(id);job.qualityMissing=(job.qualityMissing or 0)+1;return
    end
    if not M.QualityAllowed(job.settings.marketQuality,quality) then return end
    local scannedName=display and U.String(display[2]) and display[2] or nil
    local name=U.ItemName(entry.link,item and item.name,scannedName)
    if #job.words>0 then
        if not name then WaitForInfo(id);return end
        if not Matches(job.words,name) then
            if not item and (variant and (suffix~=0 or bonuses) or not linkedName and not scannedName) then
                WaitForInfo(id);job.nameMissing=(job.nameMissing or 0)+1
            end
            return
        end
    end
    local equipment=item and (item.classID==2 or item.classID==4) and item.quality>=2
    local legacyEquipment=(equipment and (not U.String(entry.link) or not variant)) or
        (job.snapshot.variantFormat~=2 and not U.String(entry.link))
    local values = {}
    for _, record in ipairs(job.records) do
        local value = (variant and record.variants or record.prices)[key]
        if Price(value) and (not equipment or suffix~=0 or record.variantFormat==2) then values[#values + 1] = value end
    end
    local row=not legacyEquipment and M.Evaluate(entry.low, values, job.settings) or nil
    if job.view=="listed" and not row then row={current=entry.low,buy=math.ceil(entry.low),days=#values,needsHistory=true} end
    if not row or not Include(job, row) then return end
    row.id, row.suffix, row.key, row.variantKey, row.hasBonuses = id, suffix, tostring(key), variant and key or nil,bonuses
    row.itemWide=legacyEquipment
    row.link = U.String(entry.link) and U.ItemID(entry.link) == id and entry.link or
        ("item:" .. id .. ":0:0:0:0:0:" .. (suffix or 0) .. ":0")
    row.scannedName=scannedName
    row.scannedQuality=scannedQuality
    row.name = DisplayName(row,item)
    row.quality=quality
    row.r,row.g,row.b=U.ItemColor(entry.link,quality)
    row.units, row.lowUnits, row.stockMove = units, lowUnits, stockMove
    row.lowBuyout = row.lowUnits and U.Number(entry.lowBuyout,0,9007199254740991) and entry.lowBuyout or nil
    job.eligible = job.eligible + 1
    Retain(job,row)
end

local function Publish(job)
    table.sort(job.rows,function(a,b)return Better(a,b,job)end)
    M.rows, M.snapshot, M.settings = job.rows, job.snapshot, job.settings
    M.examined, M.eligible, M.truncated = job.examined, job.eligible, job.truncated
    M.ready, M.job = true, nil
    M.publications = M.publications + 1
    if job.metadataDirty then M.metadataDirty=true end
    M.reason = job.reason or (((job.qualityMissing or 0)>0 or (job.nameMissing or 0)>0) and "Some item names or rarity data is loading. Results update when it arrives.") or
        (#M.rows == 0 and (job.view=="listed" and "No current items match these filters." or
        ("No matching signals. Use All items for current variants; signals need " .. job.settings.marketMinDays .. " earlier priced UTC days per variant.")) or nil)
end

function M.Tick()
    if U.Combat() or not D.data or A.disabledReason then return end
    local job = M.job
    if not job then return end
    if M.key ~= U.MarketKey() then M.Clear("Market changed; checking the new market."); return end
    if job.snapshot ~= D.Snapshot() or M.historyRevision ~= H.revision then M.job = nil; return end
    if not Fresh(job.snapshot) then M.Clear("The saved scan is stale. Complete a fresh AH scan."); return end
    local start = debugprofilestop and debugprofilestop() or 0
    for _ = 1, 2000 do
        if job.phase == "variants" then
            local map = job.maps[job.mapIndex]
            if not map then
                M.variantIndex={snapshot=job.snapshot,historyRevision=M.historyRevision,lookback=job.settings.marketLookback,
                    variants=job.variants,currentVariants=job.currentVariants}
                job.phase, job.cursor, job.mapIndex = "prices", nil, 1
            else
                local key = next(map, job.cursor)
                job.cursor = key
                if key == nil then job.mapIndex = job.mapIndex + 1
                else
                    job.prepared = (job.prepared or 0) + 1
                    local id = Identity(key, true)
                    if id and job.snapshot.prices[id] ~= nil then
                        job.variants[id] = true
                        if job.mapIndex==1 then job.currentVariants[id]=true end
                    end
                    if job.prepared >= 500000 then
                        job.reason = "History is too large for this analysis. Reduce the lookback window."
                        job.rows, job.truncated = {}, true; Publish(job); return
                    end
                end
            end
        else
            local variant = job.phase == "prices-variants"
            local map = variant and job.snapshot.variants or job.snapshot.prices
            local key, entry = next(map, job.cursor)
            job.cursor = key
            if key == nil then
                if variant then Publish(job); return else job.phase = "prices-variants" end
            else
                Evaluate(job, key, entry, variant)
                if job.examined >= MAX_ITEMS then job.truncated = true; Publish(job); return end
            end
        end
        if debugprofilestop and debugprofilestop() - start >= A.FRAME_BUDGET_MS then return end
    end
end

function M.Name(row)
    if row.name then return row.name end
    local value = A.Valuation.ItemInfo(row.link)
    row.name = DisplayName(row,value)
    return row.name
end

function M.OnItemInfo(id)
    if M.waiting and M.waiting[id] then M.waiting[id]=nil;M.metadataDirty=true end
    for _, row in ipairs(M.rows) do if row.id == id then
        row.name = nil
        local item=A.Valuation.ItemInfo(row.link)
        row.quality=U.ItemQuality(row.link,row.scannedQuality or (item and item.quality))
        row.r,row.g,row.b=U.ItemColor(row.link,row.quality)
    end end
end
