local _, A = ...
local U, D, H, M = A.Util, A.DB, A.History, A.Market
local W = { rows = {}, revision = 0, publications = 0, metadataPending={}, metadataRevision=0, alertBatches=0, alertOpens=0 }
A.Watchlist = W
local MAX_ITEMS = 200

function W.Initialize()
    local saved = D.data.watchlists
    if saved == nil then saved = { schema = 1, markets = {} }; D.data.watchlists = saved end
    if not U.Table(saved) or not U.Accessible(saved.schema) or saved.schema ~= 1 or not U.Table(saved.markets) then
        W.reason = "Unsupported watchlist data preserved."; return
    end
    W.data = saved
end

local function Profile(create)
    local key = D.ProfileKey(W.data, "markets", U.MarketInfo(), "")
    if not W.data or not key then return nil end
    local profile = W.data.markets[key]
    if profile == nil and create then profile = { entries = {} }; W.data.markets[key] = profile end
    if profile and U.Table(profile) and U.Table(profile.entries) then return profile end
end

local function Valid(row)
    return U.Table(row) and U.Number(row.id, 1, 2147483647, true) and
        U.Accessible(row.variantKey) and (row.variantKey==nil or U.SplitVariant(row.variantKey)==row.id) and
        U.Accessible(row.link) and (row.link==nil or (U.String(row.link) and #row.link<=2048 and U.ItemID(row.link)==row.id)) and
        U.Accessible(row.suffix) and (row.suffix == nil or U.Number(row.suffix, -2147483647, 2147483647, true)) and
        U.Number(row.maxBuy, 0, 100000000, true) and U.Number(row.minReturn, 0, 1000, true) and
        U.Number(row.minProfit, 0, 100000000, true)
end

function W.Entries()
    local profile, result, visited = Profile(false), {}, 0
    for key, row in pairs(profile and profile.entries or {}) do
        visited = visited + 1
        if visited > 400 then W.reason = "Oversized watchlist preserved; restore a valid backup."; return {} end
        if U.String(key) and Valid(row) and key == (row.variantKey or (row.id .. ":" .. (row.suffix or "*"))) then
            result[#result + 1] = { key = key, entry = row }
            if #result > MAX_ITEMS then W.reason = "More than 200 watches saved; restore a valid backup."; return {} end
        end
    end
    table.sort(result, function(a,b) return a.key < b.key end)
    if W.data then W.reason = nil end
    return result
end

function W.Save(input, maxBuy, minReturn, minProfit)
    if U.Combat() then return false, "Edit watchlists outside combat." end
    local id, suffix, variant
    if U.Number(input, 1, 2147483647, true) then id = input
    elseif U.String(input) then
        if string.match(input, "^%s*%d+%s*$") then id = tonumber(input)
        else
            id = U.ItemID(input)
            variant = U.VariantKey(input)
            if variant then local parsed;parsed,suffix=U.SplitVariant(variant) end
        end
    end
    local row = { id = id, suffix = suffix, variantKey=variant, link=variant and input or nil,
        maxBuy = maxBuy, minReturn = minReturn, minProfit = minProfit }
    if not Valid(row) then return false, "Choose an item ID/link and valid price/return targets." end
    local profile = Profile(true)
    if not profile then return false, W.reason or "The current market is unavailable." end
    local key = variant or (id .. ":" .. (suffix or "*"))
    local entries = W.Entries()
    if W.reason then return false, W.reason end
    if profile.entries[key] == nil and #entries >= MAX_ITEMS then return false, "Watchlist limit: 200 items per market." end
    local info = A.Valuation.ItemInfo(suffix ~= nil and input or id)
    row.name = U.LinkName(row.link) or (info and info.name) or ("Item " .. id)
    local old = profile.entries[key]
    row.quality=U.ItemQuality(row.link or id,info and info.quality)
    if Valid(old) then
        row.lastAlertAt=old.lastAlertAt
        if old.maxBuy==maxBuy and old.minReturn==minReturn and old.minProfit==minProfit then
            row.alertActive,row.lastAlertPrice=old.alertActive,old.lastAlertPrice
        end
    end
    profile.entries[key] = row; W.revision = W.revision + 1
    return true, key
end

function W.Remove(key)
    if U.Combat() or not U.String(key) then return false end
    local profile = Profile(false)
    if not profile or not profile.entries[key] then return false end
    profile.entries[key] = nil; W.revision = W.revision + 1; return true
end

function W.Metadata(row)
    W.metadataReading=true
    local info=A.Valuation.ItemInfo(row.suffix~=nil and row.link or row.id)
    local previous=not row.name:match("^Item %d+$")and row.name or nil
    local name=U.ItemName(row.link,info and info.name,previous)
    local quality=U.ItemQuality(row.link,row.quality or (info and info.quality))
    if name~=row.name or quality~=row.quality then
        row.name,row.quality=name or row.name,quality
        row.watch.name,row.watch.quality=row.name,quality
        W.metadataRevision=W.metadataRevision+1
    end
    W.metadataReading=false;return info
end

function W.OnItemInfo(id)
    if W.metadataReading then return end
    for _,row in ipairs(W.rows)do if row.id==id then W.metadataPending[id]=true;return end end
end

local function Evaluate(job, watch)
    local entry = watch.entry
    local row = { id = entry.id, suffix = entry.suffix, variantKey=entry.variantKey,
        hasBonuses=entry.variantKey and select(3,U.SplitVariant(entry.variantKey)), key = watch.key, watch = entry,
        name = U.String(entry.name) and entry.name or ("Item " .. entry.id), days = 0, matched = false,
        quality=U.Number(entry.quality,0,8,true) and entry.quality or nil }
    row.link = entry.link or ("item:" .. row.id .. ":0:0:0:0:0:" .. (row.suffix or 0) .. ":0")
    local item=W.Metadata(row)
    if not job.fresh then row.status = "Fresh scan needed"; return row end
    local series = row.suffix ~= nil and job.snapshot.variants or job.snapshot.prices
    local index = row.variantKey or (row.suffix ~= nil and (row.id .. ":" .. row.suffix) or row.id)
    local price = series[index]
    if not U.Table(price) or not U.Number(price.low, 0, 1000000000000) or price.low <= 0 then
        row.status = "Not listed"; return row
    end
    row.current, row.buy = price.low, math.ceil(price.low)
    row.units=U.Number(price.units,0,1000000000,true) and price.units or nil
    row.targetGap=entry.maxBuy>0 and (entry.maxBuy-row.buy)/entry.maxBuy*100 or nil
    local preciseEquipment=row.suffix==0 and item and (item.classID==2 or item.classID==4) and item.quality>=2
    local map = row.suffix ~= nil and "variants" or "prices"
    local settings = { marketMinDays = job.minDays, marketFee = job.fee, marketMove = 0,
        marketMinReturn = entry.minReturn, marketMinProfit = entry.minProfit }
    local estimate
    if job.basis == "intraday" then
        local record, average, scans = job.intraday, nil, 0
        if record and (not preciseEquipment or record.variantFormat == 2) then
            average, scans = H.EarlierScans(record, map, index)
        end
        row.scans = scans
        estimate = M.EvaluateIntraday(row.current, average, scans, settings)
    else
        local samples = {}
        for _, record in ipairs(job.history) do
            local value = record[map][index]
            if U.Number(value, 0, 1000000000000) and value > 0 and
               (not preciseEquipment or record.variantFormat == 2) then samples[#samples + 1] = value end
        end
        row.days = #samples
        estimate = M.Evaluate(row.current, samples, settings)
    end
    if estimate then
        for _, key in ipairs({ "profit", "roi", "baseline", "median", "low", "high", "maxBuy", "movement" }) do row[key] = estimate[key] end
    end
    local priceTarget, profitTarget = entry.maxBuy > 0, entry.minReturn > 0 or entry.minProfit > 0
    if not priceTarget and not profitTarget then row.status = "Tracking only"
    elseif profitTarget and not estimate then row.status = "More history needed"
    else
        row.matched = (not priceTarget or row.buy <= entry.maxBuy) and
            (not profitTarget or (row.profit >= entry.minProfit and row.roi >= entry.minReturn and row.profit > 0))
        row.status = row.matched and "TARGET MET" or "Watching"
    end
    return row
end

function W.Ensure()
    if not W.data then return end
    H.Maintain()
    local market = U.MarketInfo()
    local key, snapshot = market.key, D.Snapshot(market)
    local fresh = snapshot ~= nil and U.Number(snapshot.startedAt, 0, U.Now()) and not D.IsStale(snapshot)
    local s = D.Settings()
    local signature = table.concat({ W.revision, H.revision or 0, s.priceBasis, s.marketLookback, s.marketMinDays, s.marketFee, tostring(fresh) }, "|")
    if W.key ~= key then W.rows, W.snapshot, W.arrivalRequested, W.signature = {}, nil, nil, nil end
    W.key = key
    if W.source == snapshot and W.signature == signature then return end
    W.source, W.signature = snapshot, signature
    local intraday = s.priceBasis == "intraday"
    W.job = { key = key, snapshot = snapshot, fresh = fresh, basis = s.priceBasis, entries = W.Entries(), rows = {}, cursor = 1,
        history = not intraday and H.PriorRecords(snapshot, s.marketLookback, market) or nil,
        intraday = intraday and H.IntradayBaseline(market, snapshot) or nil,
        signature = signature, revision = W.revision, historyRevision = H.revision, lookback = s.marketLookback, minDays = s.marketMinDays, fee = s.marketFee }
end

function W.Tick()
    if U.Combat() then return end
    local job = W.job
    if not job then
        local start=debugprofilestop and debugprofilestop()or 0
        for _=1,20 do
            if not W.metadataJob then
                local id=next(W.metadataPending);if not id then return end
                W.metadataPending[id]=nil;W.metadataJob={id=id,cursor=1}
            end
            local check=W.metadataJob;local row=W.rows[check.cursor]
            if row then
                if row.id==check.id then W.Metadata(row)end
                check.cursor=check.cursor+1
            else W.metadataJob=nil end
            if debugprofilestop and debugprofilestop()-start>=A.FRAME_BUDGET_MS then return end
        end
        return
    end
    local settings = D.Settings()
    if job.key ~= U.MarketKey() or job.snapshot ~= D.Snapshot() or job.historyRevision ~= H.revision or job.signature ~= W.signature or
       job.basis ~= settings.priceBasis or job.revision ~= W.revision or job.fee ~= settings.marketFee or
       job.lookback ~= settings.marketLookback or job.minDays ~= settings.marketMinDays or
       (job.fresh and (D.IsStale(job.snapshot) or not U.Number(job.snapshot.startedAt,0,U.Now()))) then W.job = nil; W.signature = nil; return end
    local start = debugprofilestop and debugprofilestop() or 0
    for _ = 1, 20 do
        local watch = job.entries[job.cursor]
        if not watch then
            W.rows, W.snapshot, W.job = job.rows, job.snapshot, nil
            W.metadataJob=nil
            W.publishedRevision=job.revision
            W.publishedBasis, W.publishedHistoryRevision = job.basis, job.historyRevision
            W.publications = W.publications + 1
            for _, row in ipairs(W.rows) do
                local entry=row.watch
                if job.fresh and not row.matched then entry.alertActive=false end
                -- Adopt an already-delivered legacy notice without repeating
                -- it. Future alerts compare prices as well as the match state.
                if row.matched and entry.lastAlertPrice==nil and U.Number(entry.lastAlertAt,0,U.Now()) and entry.lastAlertAt==job.snapshot.startedAt then
                    entry.alertActive,entry.lastAlertPrice=true,row.buy
                end
            end
            return
        end
        job.rows[#job.rows + 1] = Evaluate(job, watch); job.cursor = job.cursor + 1
        if debugprofilestop and debugprofilestop() - start >= A.FRAME_BUDGET_MS then return end
    end
end

function W.Current()
    local snapshot=D.Snapshot()
    return not W.job and W.key==U.MarketKey() and W.snapshot==snapshot and snapshot~=nil and
        W.publishedBasis == D.Settings().priceBasis and W.publishedHistoryRevision == H.revision and
        W.publishedRevision==W.revision and U.Number(snapshot.startedAt,0,U.Now()) and not D.IsStale(snapshot)
end

function W.MatchCount()
    local count=0
    if W.Current() then for _,row in ipairs(W.rows)do if row.matched then count=count+1 end end end
    return count
end

function W.Acknowledge()
    if not W.Current() then return end
    for _,row in ipairs(W.rows)do if row.matched then
        row.watch.alertActive,row.watch.lastAlertPrice,row.watch.lastAlertAt=true,row.buy,W.snapshot.startedAt
    end end
end

function W.Dismiss()
    W.Acknowledge();W.arrivalRequested,W.scanRequested=nil,nil
end

function W.OnAuctionShow()
    if A.Scanner.House() ~= "faction" then return end
    W.Ensure()
    local snapshot=D.Snapshot()
    W.arrivalRequested=snapshot and U.Number(snapshot.startedAt,0,U.Now())and not D.IsStale(snapshot)and snapshot or nil
end

function W.AlertTick()
    if U.Combat() or A.Scanner.House() ~= "faction" or not W.Current() then return end
    local settings=D.Settings()
    local scan=W.scanRequested==W.snapshot
    local arrival=W.arrivalRequested==W.snapshot
    if not scan and not arrival then W.scanRequested,W.arrivalRequested=nil,nil;return end
    if not settings.watchAlerts then W.scanRequested,W.arrivalRequested=nil,nil;return end
    local open=scan and settings.watchOpenOnScan or arrival and settings.watchOpenOnAH
    if not open and not settings.watchChatAlerts then W.scanRequested,W.arrivalRequested=nil,nil;return end
    local matches={}
    for _,row in ipairs(W.rows)do if row.matched then
        local entry=row.watch
        local active=U.Accessible(entry.alertActive)and entry.alertActive==true
        if not active or not U.Number(entry.lastAlertPrice,0,1000000000000,true) or row.buy<entry.lastAlertPrice then
            matches[#matches+1]=row
        end
    end end
    if #matches==0 then W.scanRequested,W.arrivalRequested=nil,nil;return end
    if not A.WatchUI.CanAlert(open==true) then return end
    if open and A.WatchUI.OpenAlert(matches)then W.alertOpens=W.alertOpens+1 end
    if settings.watchChatAlerts then U.Print(#matches.." new or improved watchlist target(s) met. Type /msmv watch to review.")end
    W.Acknowledge();W.scanRequested,W.arrivalRequested=nil,nil
    W.alertBatches=W.alertBatches+1;W.lastAlertCount=#matches
end
