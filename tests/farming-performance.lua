local fresh,truth,equal=...
local w,A=fresh();w:load();A.Farm.Tick();A.Farm.ConfigureIdle(false,5)
collectgarbage("collect");local before=collectgarbage("count");local start=os.clock()
for minute=1,600 do
    for receipt=1,20 do
        truth(A.Farm.AddMoney(1,receipt%5==0))
        w:advance(3);A.Farm.Tick()
    end
end
local took=(os.clock()-start)*1000
local session=A.Farm.Profile().current
local buckets,locations=0,0
for _,bucket in pairs(session.metrics.buckets)do
    buckets=buckets+1;if bucket.location then locations=locations+1 end
end
truth(buckets<=61);truth(locations<=6);equal(#session.recent,20)
equal(A.Farm.Summary().total,12000);truth(A.Farm.Summary().peak.rate>0)
collectgarbage("collect");local retained=collectgarbage("count")-before
truth(retained<128,"Rate tracking grew beyond 128 KiB")
print(string.format("FARMING_BENCHMARK active_minutes=600 receipts=12000 minute_buckets=%d saved_locations=%d retained_kib=%.2f cpu_ms=%.2f requests=%d",buckets,locations,retained,took,w.requests))
