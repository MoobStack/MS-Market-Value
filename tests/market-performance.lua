-- Optional synthetic workload. Run with MSMV_BENCHMARK=1 tools/validate.py.
local fresh, row, truth, equal = ...
local w, A = fresh(); w:load()
local before = collectgarbage("count")
local count, days = 5000, 15
for day = 1, days do
    local snapshot = A.DB.NewSnapshot(A.Util.MarketKey(), count, w.wall)
    for index = 1, count do
        local id = 100000 + index
        local entry = row(id, 1, day == days and 500 + index % 100 or 1000 + index % 100)
        A.DB.AddRow(snapshot, id, 1, entry.buyout, entry.link, 0)
    end
    truth(A.DB.Commit(snapshot))
    if day < days then w:advance(86400) end
end
debugprofilestop = function() return os.clock() * 1000 end
local start, maximum, ticks = os.clock(), 0, 0
A.Market.Ensure()
while A.Market.job do
    local tick = os.clock()
    A.Market.Tick()
    maximum, ticks = math.max(maximum, (os.clock() - tick) * 1000), ticks + 1
    truth(ticks < 10000, "benchmark work must be bounded")
end
equal(#A.Market.rows, 200); equal(A.Market.eligible, count); equal(w.requests, 0)
print(string.format("BENCHMARK items=%d days=%d ticks=%d cpu_ms=%.2f max_tick_ms=%.2f results=%d lua_kib=%.0f", count, days, ticks, (os.clock()-start)*1000, maximum, #A.Market.rows, collectgarbage("count")-before))
