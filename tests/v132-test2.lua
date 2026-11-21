local fresh, craftingWorld, row, link, test, equal, near, truth, findLine, secret = ...
local DAY = 86400

local function Scan(world, addon, rows)
    world.rows = rows
    truth(addon.Scanner.Start())
    addon.Scanner.OnResponse()
    world:drain()
end

local function SameDay(world, addon, rows)
    world:advance(901)
    Scan(world, addon, rows)
end

local function Prices(rows)
    local world, addon = fresh()
    world.wall = math.floor(world.wall / DAY) * DAY + 7200
    world:load()
    Scan(world, addon, rows)
    return world, addon
end

local function Analyze(addon, view)
    addon.Market.Ensure(view)
    for _ = 1, 50 do
        if not addon.Market.job then return end
        addon.Market.Tick()
    end
    error("opportunities did not publish")
end

test("intraday history keeps every price scan, weights its lows equally, and skips missing buyouts", function()
    local world, addon = Prices({row(100, 1, 1000, -5), row(100, 2, 600, -6), row(200, 1, 900)})
    SameDay(world, addon, {row(100, 4, 800, -5), row(100, 1, 2000, -5), row(200, 1, 0)})
    SameDay(world, addon, {})
    local day = world:priceDay()
    equal(#day.intraday.scans, 3)
    for _, scan in ipairs(day.intraday.scans) do truth(type(scan.encoded) == "string") end
    equal(day.variants["100:-5"], 600)
    equal(day.variants["100:-6"], 300)
    equal(day.prices[100], 250)
    equal(day.prices[200], 900)
    equal(addon.DB.Price(100), nil)
    equal(addon.History.Status().days, 1)
    local view = addon.History.Pricing(nil, "intraday")
    equal(addon.History.Average(100, link(100, -5), view).scans, 2)
    equal(addon.History.Average(200, nil, view).scans, 1)
    equal(addon.History.Record(addon.DB.Snapshot()), false)
    equal(#day.intraday.scans, 3)
end)

test("rollover drops raw scans and retains equal-weight daily means across dates", function()
    local world, addon = Prices({row(100, 1, 1000)})
    SameDay(world, addon, {row(100, 1, 400)})
    SameDay(world, addon, {row(100, 1, 700)})
    local first = world:priceDay()
    local date = math.floor(world.wall / DAY)
    world.wall = (date + 1) * DAY + 1
    addon.History.Maintain()
    equal(first.intraday, nil)
    equal(first.prices[100], 700)
    equal(addon.History.Status().scansToday, 0)
    addon.DB.Settings().priceBasis = "intraday"
    equal(addon.History.Estimate(100), nil)
    equal(addon.History.Average(100).value, 700)
    Scan(world, addon, {row(100, 1, 300)})
    equal(addon.History.Estimate(100).value, 300)
    equal(addon.History.Average(100).value, 500)
    equal(addon.History.Average(100).days, 2)
end)

test("reload restores a full same-day batch and closed-client rollover prunes it", function()
    local world, addon = Prices({row(100, 1, 900, -5)})
    SameDay(world, addon, {row(100, 1, 300, -5)})
    addon.DB.Settings().priceBasis, addon.DB.Settings().marketPriceBasis = "intraday", "daily"
    local same, second = fresh(addon.DB.data)
    same.wall = world.wall + 901
    same:load()
    equal(second.History.Status().scansToday, 2)
    equal(second.History.Estimate(100, link(100, -5)).value, 600)
    local basis = second.History.IntradayBaseline(nil, second.DB.Snapshot())
    equal(second.History.EarlierScans(basis, "variants", "100:-5"), 900)
    Scan(same, second, {row(100, 1, 600, -5)})
    equal(second.History.Estimate(100, link(100, -5)).scans, 3)
    equal(second.Market.PriceBasis(), "daily")
    local later, third = fresh(second.DB.data)
    later.wall = same.wall + DAY
    later:load()
    equal(third.History.Status().scansToday, 0)
    equal(later:priceDay().intraday, nil)
    equal(third.History.Average(100, link(100, -5)).value, 600)
    equal(third.History.Estimate(100, link(100, -5)), nil)
end)

test("a scan started before UTC midnight joins the correct date when completed later", function()
    local world, addon = Prices({row(100, 1, 1000)})
    local day = math.floor(world.wall / DAY)
    world.wall = (day + 1) * DAY - 2
    world.rows = {row(100, 1, 400)}
    truth(addon.Scanner.Start())
    world.wall = (day + 1) * DAY + 2
    addon.History.Maintain()
    equal(#world:priceDay().intraday.scans, 1)
    addon.Scanner.OnResponse()
    world:drain()
    local rolled = world:priceDay()
    equal(rolled.prices[100], 700)
    equal(rolled.intraday, nil)
    equal(addon.History.Status().scansToday, 0)
    equal(addon.History.Average(100).firstDay, day)
end)

test("upgrading seeds just the latest same-day saved snapshot and preserves earlier daily records", function()
    local world, addon = Prices({row(100, 1, 1000)})
    world.wall = world.wall + DAY
    Scan(world, addon, {row(100, 1, 400, -5)})
    world:priceDay().intraday = nil
    local login, after = fresh(addon.DB.data)
    login.wall = world.wall + 901
    login:load()
    equal(after.History.Status().scansToday, 1)
    Scan(login, after, {row(100, 1, 200, -5)})
    equal(after.History.Status().scansToday, 2)
    equal(after.History.Average(100, link(100, -5)).value, 300)
    equal(after.History.Average(100).value, 650)
end)

test("global estimates feed tooltips crafting disenchant and farming with the selected period", function()
    local world, addon = craftingWorld()
    world.wall = world.wall + DAY
    Scan(world, addon, {row(100, 1, 200), row(101, 1, 200), row(200, 1, 500)})
    world.items[100] = {vendor=1}
    equal(addon.Crafting.Analyze(1, world.form).cost, 500)
    near(addon.Valuation.DisenchantValue({{id=100,expected=2}}).value, 300)
    equal(addon.Farm.Price(link(100), "loot"), 142)
    addon.UI.ShowStandalone()
    local switch = addon.UI.priceBasis
    equal(switch.dailyLabel:GetText(), "Daily")
    equal(switch.intradayLabel:GetText(), "Intraday")
    truth(switch.thumb.points[1][4] < 0)
    truth(switch.dailyLabel.color[1] > switch.intradayLabel.color[1])
    addon.DB.Settings().marketPriceBasis = "daily"
    switch.scripts.OnClick()
    truth(switch.thumb.points[1][4] > 0)
    truth(switch.intradayLabel.color[1] > switch.dailyLabel.color[1])
    equal(addon.Market.PriceBasis(), "daily")
    equal(addon.DB.Settings().priceBasis, "intraday")
    equal(addon.Crafting.Analyze(1, world.form).cost, 600)
    near(addon.Valuation.DisenchantValue({{id=100,expected=2}}).value, 400)
    equal(addon.Farm.Price(link(100), "loot"), 190)
    local lines = addon.Tooltips.Lines(100, link(100))
    truth(findLine(lines, "Intraday avg (1 scan)"))
    truth(findLine(lines, "AH low"))
    world:openAH()
    equal(addon.UI.priceBasis, switch)
    truth(switch.thumb.points[1][4] > 0)
    world.combat = true
    addon.UI.Refresh()
    equal(switch:IsEnabled(), false)
    switch.scripts.OnClick()
    equal(addon.DB.Settings().priceBasis, "intraday")
end)

test("Opportunities use earlier scans for the exact modifier and overrides only affect that page", function()
    local world, addon = Prices({row(100, 1, 1000, -5)})
    SameDay(world, addon, {row(100, 1, 500, -5), row(100, 1, 200, -6)})
    world:openAH()
    addon.MarketUI.view = "listed"
    Analyze(addon, "listed")
    equal(addon.Market.PriceBasis(), "daily")
    equal(addon.Market.rows[1].baseline, nil)
    addon.MarketUI.priceBasis.scripts.OnClick(nil, "LeftButton")
    equal(addon.DB.Settings().priceBasis, "daily")
    equal(addon.Market.PriceBasis(), "intraday")
    equal(#addon.Market.rows, 0)
    Analyze(addon, "listed")
    local matches = {}
    for _, result in ipairs(addon.Market.rows) do matches[result.suffix] = result end
    equal(matches[-5].current, 500)
    equal(matches[-5].baseline, 1000)
    equal(matches[-5].profit, 450)
    equal(matches[-5].scans, 1)
    equal(matches[-6].needsHistory, true)
    addon.MarketUI.Refresh()
    truth(addon.MarketUI.age.text:find("Intraday baseline", 1, true))
    addon.MarketUI.priceBasis.scripts.OnClick(nil, "RightButton")
    equal(addon.DB.Settings().marketPriceBasis, "addon")
    equal(addon.Market.PriceBasis(), "daily")
    addon.DB.Settings().priceBasis = "intraday"
    equal(addon.Market.PriceBasis(), "intraday")
    equal(world.requests, 2)
end)

test("watchlist profit estimates follow the addon period independently of Opportunities", function()
    local world, addon = Prices({row(100, 1, 1000, -5)})
    SameDay(world, addon, {row(100, 1, 500, -5)})
    truth(addon.Watchlist.Save(link(100, -5), 500, 0, 1))
    addon.DB.Settings().marketPriceBasis = "intraday"
    addon.Watchlist.Ensure()
    addon.Watchlist.Tick()
    equal(addon.Watchlist.MatchCount(), 0)
    addon.DB.Settings().priceBasis = "intraday"
    addon.Watchlist.Ensure()
    addon.Watchlist.Tick()
    equal(addon.Watchlist.MatchCount(), 1)
    equal(addon.Watchlist.rows[1].buy, 500)
    equal(addon.Watchlist.rows[1].baseline, 1000)
    equal(addon.Watchlist.rows[1].scans, 1)
end)

test("the optional packing API only stores smaller readable payloads", function()
    local world, addon = fresh()
    world:load()
    C_EncodingUtil = { CompressString = function() return "abc" end, EncodeBase64 = function() return "YWJj" end }
    local rows = {}
    for id = 1000, 1199 do rows[#rows+1] = row(id, 2, 801) end
    Scan(world, addon, rows)
    equal(world:priceDay().intraday.scans[1].encoded, "zYWJj")
    C_EncodingUtil.CompressString = function() return secret end
    SameDay(world, addon, rows)
    local scans = world:priceDay().intraday.scans
    equal(scans[2].encoded:sub(1, 1), "p")
    equal(addon.History.Average(1000).value, 400.5)
end)
