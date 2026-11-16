local _, A = ...
local U = A.Util
local M={}
A.FarmMetrics=M
local MAX=1000000000000

function M.New(elapsed)
    return {schema=1,startedElapsed=elapsed,closedMinute=math.floor(elapsed/60)-1,buckets={},missing=0,peak={rate=0}}
end

function M.ValidLocation(location)
    return U.Table(location) and U.String(location.zone) and #location.zone<=180 and
        U.Number(location.time,0,U.Now()) and
        (location.x==nil or (U.Number(location.x,0,100) and U.Number(location.y,0,100)))
end

-- Old sessions keep their totals. New rate history starts at the upgrade;
-- earlier pickups are never assigned invented timestamps.
function M.Validate(session)
    if not U.Accessible(session.metrics) then return false end
    if session.metrics==nil then session.metrics=M.New(session.elapsed) end
    local data=session.metrics
    if not U.Table(data) or not U.Number(data.schema,1,1,true) or not U.Table(data.buckets) or
       not U.Number(data.startedElapsed,0,session.elapsed) or
       not U.Number(data.closedMinute,-1,5256000,true) or
       not U.Number(data.missing,0,1000000000,true) or not U.Table(data.peak) or
       not U.Number(data.peak.rate,0,MAX) then return false end
    local count=0
    for minute,bucket in pairs(data.buckets) do
        count=count+1
        if count>61 or not U.Number(minute,0,math.floor(session.elapsed/60),true) or not U.Table(bucket) or
           not U.Number(bucket.total,0,MAX) or not U.Number(bucket.farm,0,bucket.total) then return false end
        if bucket.location and not M.ValidLocation(bucket.location) then return false end
    end
    if data.peak.location and not M.ValidLocation(data.peak.location) then return false end
    return true
end

function M.Location()
    local zone=U.Call(GetRealZoneText) or U.Call(GetZoneText)
    local result={zone=U.String(zone) and zone:sub(1,180) or "Unknown zone",time=U.Now()}
    local map=U.Call(C_Map and C_Map.GetBestMapForUnit,"player")
    if U.Number(map,1,2147483647,true) then
        local position=U.Call(C_Map and C_Map.GetPlayerMapPosition,map,"player")
        if U.Table(position) or (U.Accessible(position) and type(position)=="userdata") then
            if type(position.GetXY)=="function" then
                local ok,x,y=pcall(position.GetXY,position)
                if ok and U.Number(x,0,1) and U.Number(y,0,1) then result.x,result.y=x*100,y*100 end
            end
        end
    end
    return result
end

-- A minute ring bounds both saved data and per-tick work. Only five complete
-- active minutes can set a peak; quest turn-ins never enter its numerator.
function M.Advance(session)
    local data=session.metrics
    if not data then return end
    local current=math.floor(session.elapsed/60)
    local first=math.max(data.closedMinute+1,math.ceil(data.startedElapsed/60)+4)
    for ending=first,math.min(current-1,first+60) do
        local value,location=0,nil
        for minute=ending-4,ending do
            local bucket=data.buckets[minute]
            if bucket then
                value=value+bucket.farm
                if bucket.location and (not location or bucket.location.time>location.time) then location=bucket.location end
            end
        end
        local rate=value*12
        if rate>data.peak.rate and U.Number(rate,0,MAX) then data.peak={rate=rate,location=location} end
    end
    data.closedMinute=current-1
    for minute,bucket in pairs(data.buckets) do
        if minute<current-60 then data.buckets[minute]=nil
        elseif minute<current-5 then bucket.location=nil end
    end
end

function M.Record(session,amount,quest)
    local data=session.metrics
    if not data then return end
    if not U.Number(amount,0,MAX) then data.missing=math.min(1000000000,data.missing+1);return end
    local minute=math.floor(session.elapsed/60)
    local bucket=data.buckets[minute]
    if not bucket then bucket={total=0,farm=0};data.buckets[minute]=bucket end
    bucket.total=math.min(MAX,bucket.total+amount)
    if not quest then
        bucket.farm=math.min(bucket.total,bucket.farm+amount)
        if amount>0 then bucket.location=M.Location() end
    end
end

function M.Summary(session,result)
    local data=session.metrics
    if not data then return end
    local value,cutoff=0,session.elapsed-3600
    for minute,bucket in pairs(data.buckets) do
        local fraction=math.max(0,math.min(1,(minute*60+60-cutoff)/60))
        value=value+bucket.total*fraction
    end
    local duration=math.min(3600,session.elapsed-data.startedElapsed)
    result.recentDuration=duration
    result.recentRate=duration>=60 and value/duration*3600 or 0
    result.peak=data.peak
    result.metricMissing=data.missing
    result.metricsSince=data.startedElapsed
end
