local fresh, row, test, equal, truth = ...

local function Visit(world, npc)
    world:event("AUCTION_HOUSE_CLOSED")
    world.auctioneer = npc
    world:openAH()
end

local function Scan(world, addon, rows)
    world.rows = rows
    truth(addon.Scanner.Start())
    addon.Scanner.OnResponse()
    world:drain()
    equal(addon.Scanner.state, "COMPLETE")
end

test("a faction full scan blocks neutral requests after switching characters", function()
    local w, A = fresh()
    w:load()
    Visit(w, 8673)
    Scan(w, A, {row(100, 1, 1000)})
    local saved = A.DB.data
    local alt, B = fresh(saved)
    alt.guid, alt.wall = "Player-1-neutral-alt", w.wall + 60
    alt:load()
    Visit(alt, 8661)
    equal(B.Scanner.House(), "neutral")
    equal(B.Scanner.RemainingCooldown(), 840)
    equal(B.UI.scanButton:IsEnabled(), false)
    truth(B.UI.DiagnosticsText():find("shared=840", 1, true))
    equal(B.Scanner.Start(), false)
    equal(B.Scanner.state, "IDLE")
    equal(alt.requests, 0)
    equal(B.Scanner.RemainingCooldown(), 840)

    alt:advance(840)
    B.UI.Refresh()
    truth(B.UI.scanButton:IsEnabled())
    alt.ready = false
    equal(B.Scanner.Start(), false)
    equal(alt.requests, 0)
    equal(B.Scanner.RemainingCooldown(), 0)
    alt.ready = true
    Scan(alt, B, {row(100, 1, 500)})
    equal(B.DB.NeutralSnapshot().prices[100].low, 500)
    equal(B.DB.Snapshot().prices[100].low, 1000)
    Visit(alt, 8673)
    equal(B.Scanner.Start(), false)
    equal(B.Scanner.RemainingCooldown(), 900)
    equal(alt.requests, 1)
end)

test("upgrading uses the later saved faction or neutral deadline", function()
    for _, deadlines in ipairs({ {500, 700}, {700, 500} }) do
        local first, A = fresh()
        first:load()
        local saved = A.DB.data
        saved.cooldownUntil = first.wall + deadlines[1]
        saved.neutralCooldownUntil = first.wall + deadlines[2]

        local w, B = fresh(saved)
        w.wall = first.wall
        w:load()
        equal(B.Scanner.RemainingCooldown(), 700)
        equal(B.DB.data.neutralCooldownUntil, nil)
    end
end)

test("a neutral scan with no response can retry once the shared cooldown expires", function()
    local w, A = fresh()
    w:load()
    Visit(w, 8661)
    Scan(w, A, {row(100, 1, 500)})
    local previous = A.DB.NeutralSnapshot()
    w:advance(900)
    truth(A.Scanner.Start())
    w:advance(A.REQUEST_TIMEOUT + 1)
    equal(A.Scanner.state, "PAUSED")
    equal(A.Scanner.resumeState, "WAITING")
    equal(A.Scanner.responseCount, 0)
    equal(A.DB.NeutralSnapshot(), previous)
    equal(A.UI.restartButton:IsEnabled(), false)
    truth(A.UI.statusText:GetText():find("No reply", 1, true))

    w:advance(A.Scanner.RemainingCooldown())
    A.UI.Refresh()
    equal(A.UI.scanButton.text, "Restart scan")
    A.UI.scanButton.scripts.OnClick()
    equal(w.requests, 3)
    equal(A.Scanner.state, "WAITING")
    equal(A.DB.NeutralSnapshot(), previous)
    w.rows = {row(100, 1, 400)}
    A.Scanner.OnResponse()
    w:drain()
    equal(A.Scanner.state, "COMPLETE")
    equal(A.DB.NeutralSnapshot().prices[100].low, 400)
end)

test("neutral scans replace only the shared neutral snapshot and never add faction price history", function()
    local w, A = fresh()
    w.realm = "ClassicBetaPvP2"
    w:load()
    Visit(w, 8673)
    Scan(w, A, {row(100, 1, 1000)})
    local faction = A.DB.Snapshot()
    local revision = A.History.revision
    equal(faction.auctionHouse, "faction")
    w:advance(901)
    Visit(w, 8661)
    Scan(w, A, {row(100, 1, 300), row(101, 1, 500)})
    local first = A.DB.NeutralSnapshot()
    equal(first.auctionHouse, "neutral")
    equal(first.prices[101].low, 500)
    w:advance(901)
    Visit(w, 258878)
    Scan(w, A, {row(100, 1, 450)})
    local neutral = A.DB.NeutralSnapshot()
    equal(neutral.prices[100].low, 450)
    equal(neutral.prices[101], nil)
    equal(neutral.previousSupply, nil)
    equal(A.DB.Snapshot(), faction)
    equal(A.DB.Price(100).low, 1000)
    equal(A.History.Status().scansToday, 1)
    equal(A.History.revision, revision)
    equal(A.Watchlist.scanRequested, nil)
    w.faction = "Alliance"
    equal(A.DB.Snapshot(), nil)
    equal(A.DB.NeutralSnapshot(), neutral)
    w.realm = "ClassicBetaNormal1"
    equal(A.DB.NeutralSnapshot(), nil)
end)

test("unknown auctioneers require a choice and paused scans cannot switch house types", function()
    local w, A = fresh()
    w:load()
    Visit(w, false)
    equal(A.Scanner.House(), nil)
    equal(A.Scanner.Start(), false)
    equal(w.requests, 0)
    truth(A.UI.houseChoice:IsShown())
    truth(A.Scanner.SelectHouse("neutral"))
    w.rows = {row(100, 1, 350)}
    truth(A.Scanner.Start())
    Visit(w, 8673)
    A.Scanner.OnResponse()
    equal(A.Scanner.work, nil)
    equal(A.Scanner.Resume(), false)
    equal(w.requests, 1)
    Visit(w, 9858)
    truth(A.Scanner.Resume())
    A.Scanner.OnResponse()
    w:drain()
    equal(A.DB.Snapshot(), nil)
    equal(A.DB.NeutralSnapshot().prices[100].low, 350)
    w:event("AUCTION_HOUSE_CLOSED")
    equal(A.Scanner.House(), nil)
end)

test("known faction and neutral locations identify a house when the auctioneer is hidden", function()
    local w, A = fresh()
    local mapID = 1454
    C_Map = {
        GetBestMapForUnit = function() return mapID end,
        GetMapInfo = function(id) return id == 9001 and { parentMapID = 1446 } or nil end,
    }
    w:load()
    Visit(w, false)
    equal(A.Scanner.House(), "faction")
    mapID = 9001
    Visit(w, false)
    equal(A.Scanner.House(), "neutral")
    truth(A.Scanner.Start())
    equal(A.UI.houseChoice, nil)
    A.Scanner.Discard("Fixture complete.")
    mapID = 1454
    Visit(w, 258878)
    equal(A.Scanner.House(), "neutral")
end)

test("arbitrage compares exact matches in both directions and deducts the selling house cut", function()
    local w, A = fresh()
    w:load()
    Visit(w, 8673)
    Scan(w, A, {row(100, 1, 1000), row(101, 1, 500), row(102, 1, 5000, -1), row(103, 1, 1000)})
    w:advance(901)
    Visit(w, 15677)
    Scan(w, A, {row(100, 1, 400), row(101, 1, 1200), row(102, 1, 100, -2), row(103, 1, 1050)})
    A.MarketUI.Show()
    A.MarketUI.views.arbitrage.scripts.OnClick()
    while A.Market.job do A.Market.Tick() end
    A.MarketUI.Refresh()
    equal(#A.Market.rows, 2)
    local first, second = A.Market.rows[1], A.Market.rows[2]
    equal(first.id, 100)
    equal(first.buyHouse, "neutral")
    equal(first.profit, 550)
    equal(first.factionAverage, 1000)
    equal(second.id, 101)
    equal(second.buyHouse, "faction")
    equal(second.profit, 520)
    equal(w.requests, 2)
    w.items[100], w.items[101] = {name="Test A"}, {name="Test B"}
    local ah = w:nativeSearch()
    A.Market.Ensure("arbitrage", "return", true)
    truth(A.Market.job)
    local firstButton, secondButton = A.MarketUI.rows[1], A.MarketUI.rows[2]
    secondButton.scripts.OnClick(secondButton, "LeftButton")
    equal(w.itemSearches, 1)
    equal(w.searchedKey.itemID, 101)
    equal(ah.selectedBrowse.minPrice, 1200)

    w:advance(1)
    A.MarketUI.Show()
    firstButton.scripts.OnClick(firstButton, "LeftButton")
    equal(w.itemSearches, 2)
    equal(w.searchedKey.itemID, 100)
    equal(ah.selectedBrowse.minPrice, 400)
    equal(w.browseSearches, 0)
    equal(w.requests, 2)

    Visit(w, 8673)
    equal(A.MarketUI.OpenListings(second), false)
    equal(w.itemSearches, 2)
    truth(A.UI.DiagnosticsText():find("Visit a neutral auctioneer to open these listings.", 1, true))
    Visit(w, 15677)
    w:advance(901)
    Scan(w, A, {row(100, 1, 100)})
    A.Market.Ensure("arbitrage", "return")
    while A.Market.job do A.Market.Tick() end
    equal(#A.Market.rows, 1)
    equal(A.Market.rows[1].profit, 850)
    w:advance(25*3600)
    A.Market.Ensure("arbitrage")
    equal(#A.Market.rows, 0)
end)

test("clicking a faction buy resolves the exact modifier in the neutral Browse results", function()
    local w, A = fresh()
    w:load()
    local function Modified(price, bonus)
        local item = row(15166, 1, price)
        item.link = "|cff1eff00|Hitem:15166:0:0:0:0:0:0:234:40:0:0:0:1:" .. bonus .. "|h[Imposing Gloves]|h|r"
        return item
    end
    local faction, neutral = Modified(500, 5661), Modified(1200, 5661)
    local differentModifier = Modified(100, 5662)
    Visit(w, 8673)
    Scan(w, A, {faction})
    w:advance(900)
    Visit(w, 8661)
    Scan(w, A, {neutral, differentModifier})

    local ui = A.MarketUI
    A.MarketUI.Show()
    while A.Market.job do A.Market.Tick() end
    ui.Refresh()
    equal(#A.Market.rows, 1)
    equal(A.Market.rows[1].buyHouse, "faction")
    w.items[15166] = {name="Imposing Gloves", equipment=true}
    local ah = w:nativeSearch()
    local browse = {}
    C_AuctionHouse.GetBrowseResults = function() return browse end
    C_AuctionHouse.GetItemKeySampleLink = function(key)
        return key.itemSuffix == 9001 and neutral.link or differentModifier.link
    end
    function ah.SearchBar:GetSearchText() return self.searchText end

    local button = ui.rows[1]
    button.scripts.OnClick(button, "LeftButton")
    equal(w.browseSearches, 1)
    equal(w.itemSearches, 0)
    browse = {
        {itemKey={itemID=15166, itemLevel=45, itemSuffix=9002, battlePetSpeciesID=0}},
        {itemKey={itemID=15166, itemLevel=45, itemSuffix=9001, battlePetSpeciesID=0}},
    }
    w:event("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
    equal(w.itemSearches, 1)
    equal(w.searchedKey.itemSuffix, 9001)
    equal(ah.selectedBrowse.minPrice, 1200)
    equal(ui.pendingVariant, nil)
    equal(w.requests, 2)
end)

test("Arbitrage Basis changes the exact faction comparison and keeps the saved asking price for buys", function()
    local w, A = fresh()
    w.wall = w.wall - w.wall % 86400 + 3600
    w:load()
    Visit(w, 8673)
    Scan(w, A, {row(100, 1, 4800, -1), row(100, 1, 100, -2), row(101, 1, 500)})
    w:advance(86400)
    Scan(w, A, {row(100, 1, 800, -1), row(100, 1, 100, -2), row(101, 1, 3500)})
    w:advance(900)
    Scan(w, A, {row(100, 1, 1200, -1), row(100, 1, 100, -2), row(101, 1, 3500)})
    w:advance(900)
    Visit(w, 8661)
    Scan(w, A, {row(100, 1, 2000, -1), row(100, 1, 200, -3), row(101, 1, 2500)})

    local ui = A.MarketUI
    A.MarketUI.Show()
    local function Results()
        while A.Market.job do A.Market.Tick() end
        ui.Refresh()
        local byID = {}
        for _, result in ipairs(A.Market.rows) do byID[result.id] = result end
        return byID
    end
    truth(ui.priceBasis:IsShown())
    equal(ui.priceBasis.text, "Basis: Daily avg")
    local rows = Results()
    equal(#A.Market.rows, 1)
    equal(rows[100].factionAverage, 2900)
    equal(rows[100].days, 2)
    equal(rows[100].buyHouse, "neutral")
    equal(rows[100].sell, 2900)
    equal(rows[100].profit, 755)

    ui.priceBasis.scripts.OnClick(ui.priceBasis, "LeftButton")
    equal(ui.priceBasis.text, "Basis: Intraday avg")
    rows = Results()
    equal(#A.Market.rows, 2)
    equal(rows[100].variantKey, "100:-1")
    equal(rows[100].factionAverage, 1000)
    equal(rows[100].scans, 2)
    equal(rows[100].buyHouse, "faction")
    equal(rows[100].buy, 1200)
    equal(rows[100].profit, 500)
    equal(rows[101].buyHouse, "neutral")
    equal(rows[101].profit, 825)
    equal(A.DB.Settings().priceBasis, "daily")
    truth(A.UI.DiagnosticsText():find("Arbitrage price basis: faction=intraday", 1, true))

    w:advance(86400 - w.wall % 86400)
    ui.Ensure()
    Results()
    equal(#A.Market.rows, 0)
    ui.priceBasis.scripts.OnClick(ui.priceBasis, "RightButton")
    rows = Results()
    equal(rows[100].buyHouse, "neutral")
    equal(rows[100].profit, 755)
    equal(w.requests, 4)
end)

test("faction Opportunities keeps the price toggle and restores its view after a neutral visit", function()
    local w, A = fresh()
    w:load()
    Visit(w, 8673)
    Scan(w, A, {row(100, 1, 1000)})
    A.MarketUI.Show()
    local ui = A.MarketUI
    equal(ui.views.arbitrage:IsShown(), false)
    ui.views.arbitrage.scripts.OnClick()
    equal(ui.view, "deals")
    ui.views.falling.scripts.OnClick()
    truth(ui.priceBasis:IsShown())
    truth(ui.priceBasis:IsEnabled())
    equal(ui.priceBasis.text, "Basis: Daily avg")
    ui.priceBasis.scripts.OnClick(ui.priceBasis, "LeftButton")
    equal(A.Market.PriceBasis(), "intraday")
    equal(ui.priceBasis.text, "Basis: Intraday avg")
    Visit(w, 8661)
    A.MarketUI.Show()
    truth(ui.views.arbitrage:IsShown())
    equal(ui.view, "arbitrage")
    truth(ui.priceBasis:IsShown())
    truth(ui.priceBasis:IsEnabled())
    equal(ui.priceBasis.text, "Basis: Intraday avg")
    ui.views.falling.scripts.OnClick()
    truth(ui.priceBasis:IsEnabled())
    ui.views.arbitrage.scripts.OnEnter(ui.views.arbitrage)
    truth(GameTooltip:IsShown())
    truth(GameTooltip.lines[1].left:find("latest neutral scan", 1, true))
    ui.views.arbitrage.scripts.OnLeave(ui.views.arbitrage)
    ui.views.arbitrage.scripts.OnClick()
    equal(ui.view, "arbitrage")
    truth(ui.priceBasis:IsShown())
    truth(A.Market.reason:find("neutral AH scan", 1, true))
    Visit(w, 8673)
    A.MarketUI.Show()
    equal(ui.view, "falling")
    equal(ui.views.arbitrage:IsShown(), false)
    truth(ui.priceBasis:IsShown())
    truth(ui.priceBasis:IsEnabled())
    equal(ui.priceBasis.text, "Basis: Intraday avg")
    ui.priceBasis.scripts.OnClick(ui.priceBasis, "RightButton")
    equal(A.DB.Settings().marketPriceBasis, "addon")
    equal(A.Market.PriceBasis(), "daily")
    Visit(w, 8661)
    A.MarketUI.Show()
    equal(ui.view, "falling")
    local w2, B = fresh(A.DB.data)
    w2.wall = w.wall
    w2:load()
    Visit(w2, 8661)
    B.MarketUI.Show()
    equal(B.MarketUI.view, "arbitrage")
    equal(w.requests, 1)
end)
