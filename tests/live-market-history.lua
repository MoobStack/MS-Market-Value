local function coin(amount) return _G.MSMarketValue.Util.Coins(amount) end
local fresh, row, link, test, equal, truth, bagTooltip, findLine, secret = ...
local hostA, hostB, hostC = "CAMWOWUS2Realm8PvP", "CAMWOWUS3Realm12PvP", "CAMWOWUS2Realm20PvP"
local oldA, oldB, oldC = "1|" .. hostA, "1|" .. hostB, "1|" .. hostC
local pvp = "forever|1|pvp|Horde"
local day = 86400

local function Prior(A, key, stamp, rows)
    local snapshot = A.DB.NewSnapshot(key, #rows, stamp)
    snapshot.version, snapshot.build = "1.2.0", "2026-10-20-release001"
    for _, entry in ipairs(rows) do A.DB.AddRow(snapshot, entry.id, entry.quantity, entry.buyout, entry.link, 0) end
    snapshot.complete, snapshot.finishedAt = true, stamp + 1
    A.DB.data.markets[key] = snapshot
    truth(A.History.Record(snapshot))
    return snapshot
end

local function Scan(w, A, rows)
    w.rows = rows
    truth(A.Scanner.Start())
    A.Scanner.OnResponse()
    w:drain()
end

local function Live(saved, realm, faction, region)
    local w, A = fresh(saved)
    w.realm, w.faction, w.region = realm or hostA, faction or "Horde", region or 1
    w:load()
    return w, A
end

test("completed scans on different live reporting hosts add days to one market", function()
    local w, A = Live()
    Scan(w, A, {row(100, 1, 600)})
    w:advance(day)
    w.realm = hostB
    Scan(w, A, {row(100, 1, 200)})
    equal(A.History.Status().days, 2)
    equal(A.Util.MarketKey(), pvp)
    equal(A.DB.Snapshot().marketKey, pvp)
    equal(A.DB.Price(100).low, 200)
    local tooltip = bagTooltip(w, 100, 2)
    A.Tooltips.Handle(tooltip, tooltip.data)
    equal(findLine(tooltip.lines, "Historic avg (2 days)").right, coin(400) .. " / " .. coin(800))
end)

test("live reporting names recognize rulesets without guessing unknown names", function()
    local w, A = Live()
    w.realm = secret
    GetRealmName = function() return "CAMWOW US2 Realm 8 PvP" end
    equal(A.Util.MarketKey(), pvp)
    for token, ruleset in pairs({Normal="normal", RP="roleplaying", RPPvP="roleplayingpvp", Hardcore="hardcore"}) do
        w.realm = "CAMWOWUS2Realm8" .. token
        equal(A.Util.MarketKey(), "forever|1|" .. ruleset .. "|Horde")
    end
    for _, realm in ipairs({"ARealm8PvP", "CAMWOWUS2Realm8Unknown", "CAMWOWXX2Realm8PvP", "CAMWOWUSRealm8PvP"}) do
        w.realm = realm
        equal(A.Util.MarketKey(), "1|" .. realm)
    end
    w.realm, w.hardcore = hostA, true
    equal(A.Util.MarketKey(), "forever|1|hardcore|Horde")
    w.hardcore, w.faction = false, secret
    equal(A.Util.MarketKey(), nil)
end)

test("upgrading recovers retained PvP host days and keeps only the latest scan on each day", function()
    local w, A = fresh(); w:load()
    local first = Prior(A, oldA, w.wall - 3 * day, {row(100, 1, 1200, -7)})
    Prior(A, oldB, w.wall - 2 * day, {row(100, 1, 1500, -7), row(101, 1, 500)})
    Prior(A, oldC, w.wall - 2 * day + 10, {row(100, 1, 900, -7)})
    local recent = Prior(A, oldB, w.wall - 60, {row(100, 1, 300, -7)})
    local saved = A.DB.data
    local w2, A2 = Live(saved)
    equal(w2.requests, 0)
    local status = A2.History.Status()
    equal(status.days, 3); equal(status.legacyDays, 3); equal(status.legacyHosts, 3)
    equal(A2.History.Average(100).value, 800)
    equal(A2.History.Average(100, link(100, -7)).days, 3)
    equal(A2.History.Average(101), nil)
    equal(A2.DB.Snapshot().legacyMarketKey, oldB)
    equal(A2.DB.Price(100).low, 300)
    equal(A2.DB.Price(101), nil)
    equal(saved.markets[pvp], nil)
    equal(saved.markets[oldA], first); equal(saved.markets[oldB], recent)
    local diagnostics = A2.UI.DiagnosticsText()
    truth(string.find(diagnostics, "Earlier reporting hosts: 3; recovered UTC days=3", 1, true))
    truth(string.find(diagnostics, "Snapshot recovered from: " .. oldB, 1, true))
    Scan(w2, A2, {row(100, 1, 600, -7)})
    equal(A2.DB.Snapshot(), saved.markets[pvp])
    equal(A2.History.Status().days, 3); equal(A2.History.Status().legacyDays, 2)
    equal(A2.History.Average(100).value, 900)
    truth(A2.History.SetRetention(1))
    equal(A2.History.Average(100).days, 1); equal(A2.History.Average(100).value, 600)
    truth(A2.History.SetRetention(30)); equal(A2.History.Status().days, 1)
end)

test("legacy price recovery excludes other regions rulesets and beta markets", function()
    local w, A = fresh(); w:load()
    local normalHost = "CAMWOWUS2Realm8Normal"
    Prior(A, "1|" .. normalHost, w.wall - 3 * day, {row(100, 1, 400)})
    Prior(A, "1|CAMWOWUS2Realm8RPPvP", w.wall - 2 * day, {row(100, 1, 500)})
    Prior(A, "3|CAMWOWEU2Realm8PvP", w.wall - day, {row(100, 1, 600)})
    Prior(A, "forever|110|pvp|Horde", w.wall - day, {row(100, 1, 700)})
    Prior(A, oldA, w.wall - 60, {row(100, 1, 100)})
    local saved = A.DB.data
    local _, A2 = Live(saved)
    equal(A2.History.Status().days, 1); equal(A2.History.Average(100).value, 100)
    local _, normal = Live(saved, normalHost)
    equal(normal.History.Status().days, 0); equal(normal.History.Status().legacyHosts, 1)
    equal(normal.DB.Snapshot(), nil)
    truth(saved.markets["1|" .. normalHost])
    local _, opposite = Live(saved, hostB, "Alliance")
    equal(opposite.History.Status().days, 0); equal(opposite.DB.Snapshot(), nil)
    truth(string.find(opposite.History.Status().legacyReason, "different faction", 1, true))
end)

test("conflicting legacy PvP faction observations block inferred price recovery", function()
    local w, A = fresh(); w:load()
    local snapshot = Prior(A, oldA, w.wall - day, {row(100, 1, 100)})
    local saved = A.DB.data
    saved.vendorBuy.characters[oldB .. "|Alliance|Player-1-alt"] = {prices = {}}
    local _, A2 = Live(saved)
    equal(A2.History.Status().days, 0); equal(A2.DB.Snapshot(), nil)
    truth(string.find(A2.History.Status().legacyReason, "both factions", 1, true))
    equal(saved.markets[oldA], snapshot)
end)

test("opportunities and watchlists use the same recovered days as tooltips", function()
    local w, A = fresh(); w:load()
    Prior(A, oldA, w.wall - 3 * day, {row(100, 1, 1200)})
    Prior(A, oldB, w.wall - 2 * day, {row(100, 1, 1200)})
    Prior(A, oldC, w.wall - day, {row(100, 1, 1200)})
    local w2, A2 = Live(A.DB.data)
    Scan(w2, A2, {row(100, 1, 200)})
    truth(A2.Watchlist.Save(100, 300, 20, 100))
    A2.Watchlist.Ensure(); A2.Market.Ensure("deals", "profit")
    for _ = 1, 20 do A2.Watchlist.Tick(); A2.Market.Tick() end
    equal(A2.History.Average(100).days, 4)
    equal(A2.Market.rows[1].days, 3)
    equal(A2.Market.rows[1].profit, 940)
    equal(A2.Watchlist.rows[1].days, 3)
    equal(A2.Watchlist.rows[1].matched, true)
end)

test("the live host upgrade retains character records and queued transactions across reload", function()
    local w, A = fresh(); w:load()
    local base, guid = A.Util.MarketKey(), w.guid
    truth(A.Ledger.Record({kind="buy", name="Prior purchase", quantity=1, amount=40}))
    local staged = A.Ledger.Stage({kind="buy", name="Queued purchase", quantity=1, amount=60,
        time=w.wall, source="AH purchase", autoKey="purchase:upgrade"})
    truth(staged)
    w.vendorItems = {{id=2320, price=45, stackCount=5, numAvailable=-1, isPurchasable=true, hasExtendedCost=false}}
    w:event("MERCHANT_SHOW")
    truth(A.Watchlist.Save(100, 300, 20, 100))
    local saved, oldPlayer = A.DB.data, oldA .. "|" .. guid
    local ledger, vendor, watches = saved.ledger.characters, saved.vendorBuy.characters, saved.watchlists.markets
    local profile = ledger[base .. "|" .. guid]
    staged[1].player = oldPlayer
    ledger[oldPlayer], ledger[base .. "|" .. guid] = profile, nil
    vendor[oldA .. "|Horde|" .. guid], vendor[base .. "|Horde|" .. guid] = vendor[base .. "|Horde|" .. guid], nil
    watches[oldA], watches[base] = watches[base], nil
    local _, A2 = Live(saved)
    equal(A2.Util.PlayerKey(), oldPlayer); equal(#A2.Ledger.Records(), 1)
    equal(A2.Vendor.Price(2320), 9); equal(#A2.Watchlist.Entries(), 1)
    A2.Transactions.Tick()
    equal(#A2.Ledger.Records(), 2); equal(#profile.pending, 0)
    local w3, A3 = Live(saved, hostB)
    equal(A3.Util.PlayerKey(), oldPlayer); equal(#A3.Ledger.Records(), 2)
    equal(A3.Vendor.Price(2320), 9); equal(#A3.Watchlist.Entries(), 1)
    equal(saved.ledger.characters[pvp .. "|" .. guid], nil)
    w3.guid = "Player-1-other"
    equal(#A3.Ledger.Records(), 0); equal(A3.Vendor.Price(2320), nil)
end)
