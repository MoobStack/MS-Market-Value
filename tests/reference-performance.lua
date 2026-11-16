local fresh,truth,equal=...
local w,A=fresh();w:load()
A.LootReference.classicQuery=nil -- Isolate the synthetic counted pack; real layers have separate coverage.
collectgarbage("collect");local before=collectgarbage("count")
assert(loadfile("tests/tmp/reference-workload.lua"))()
collectgarbage("collect");local packed=collectgarbage("count")-before
equal(A.LootReference.cachedRows,0)
local maximum,total=0,0
for source=1,32 do
    local start=os.clock();local rows=A.LootReference.Rows(source)
    local took=(os.clock()-start)*1000;maximum=math.max(maximum,took);total=total+took
    equal(#rows,500);truth(A.LootReference.cachedRows<=4096)
end
equal(#A.LootReference.order,8);equal(A.LootReference.cachedRows,4000)
collectgarbage("collect")
print(string.format("REFERENCE_BENCHMARK sources=1000 rows=500000 packed_lua_kib=%.0f retained_with_cache_kib=%.0f decoded_cache_rows=%d max_decode_ms=%.2f total_decode_ms=%.2f requests=%d",
    packed,collectgarbage("count")-before,A.LootReference.cachedRows,maximum,total,w.requests))
