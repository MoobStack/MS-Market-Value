local fresh, row, link, test, equal, truth, secret = ...
local pvp = "forever|1|pvp|Horde"

local function Hidden(saved, flags)
    local world, addon = fresh(saved)
    world.realm = ""
    GetBuildInfo = function() return "1.60.1", "71037", "Nov 20 2026", 16001 end
    Enum.GameRule = { HardcoreRuleset = 10, PvPRuleset = 213, RPRuleset = 214 }
    if flags then
        C_GameRules.IsGameRuleActive = function(rule) return flags[rule] end
    end
    return world, addon
end

local function Choose(addon, ruleset)
    SlashCmdList.MSMARKETVALUE("ruleset")
    local button = addon.UI.rulesetButtons[ruleset]
    truth(button:IsEnabled())
    button.scripts.OnClick(button)
end

test("public ruleset flags distinguish all five Forever markets with blank realm names", function()
    local flags = { [10] = false, [213] = false, [214] = false }
    local world, addon = Hidden(nil, flags)
    world:load()
    local function Check(ruleset)
        local market = addon.Util.MarketInfo()
        equal(market.key, "forever|1|" .. ruleset .. "|Horde")
        equal(market.rulesetSource, "C_GameRules.IsGameRuleActive")
        equal(market.pendingRuleset, nil)
    end
    Check("normal")
    flags[213] = true
    Check("pvp")
    flags[214] = true
    Check("roleplayingpvp")
    flags[213] = false
    Check("roleplaying")
    flags[10] = true
    Check("hardcore")
    world:event("PLAYER_ENTERING_WORLD")
    equal(addon.UI.rulesetFrame, nil)
end)

test("partial, restricted and throwing ruleset reads require confirmation", function()
    local flags = { [10] = false, [213] = true, [214] = secret }
    local world, addon = Hidden(nil, flags)
    world:load()
    equal(addon.Util.MarketKey(), nil)
    equal(addon.Util.MarketInfo().pendingRuleset, "pvp")
    flags[214] = nil
    equal(addon.Util.MarketKey(), nil)
    C_GameRules.IsGameRuleActive = function() error("unavailable") end
    equal(addon.Util.MarketKey(), nil)
    equal(world.requests, 0)
end)

test("71037 keeps an older PvP scan and adds the next scan to the same price history", function()
    local old, before = fresh()
    old.realm = "CAMWOWUS2Realm8PvP"
    old:start({ row(100, 1, 900) })
    old:drain()
    local saved, prior = before.DB.data, before.DB.Snapshot()
    truth(before.Watchlist.Save(100, 1000, 0, 0))
    truth(before.Ledger.Record({ kind = "buy", name = "Prior purchase", quantity = 1, amount = 900 }))
    saved.version, saved.build = "1.3.1", "2026-11-17-release001"
    local world, addon = Hidden(saved, { [10] = false, [213] = true, [214] = false })
    world.wall = old.wall + 86400
    world:load()
    equal(addon.DB.Snapshot(), prior)
    equal(addon.DB.Price(100).low, 900)
    equal(addon.History.Status().days, 1)
    equal(#addon.Watchlist.Entries(), 1)
    equal(#addon.Ledger.Records(), 1)
    world.rows = { row(100, 1, 700) }
    truth(addon.Scanner.Start())
    addon.Scanner.OnResponse()
    world:drain()
    equal(addon.Scanner.state, "COMPLETE")
    equal(world.requests, 1)
    equal(addon.DB.Snapshot().marketKey, pvp)
    equal(addon.DB.Price(100).low, 700)
    equal(addon.History.Status().days, 2)
end)

test("earlier PvP host scans remain readable with hidden realm names", function()
    local old, before = fresh()
    old:load()
    local key = "1|CAMWOWUS2Realm8PvP"
    local snapshot = before.DB.NewSnapshot(key, 1, old.wall - 86400)
    before.DB.AddRow(snapshot, 100, 1, 550, link(100), 0)
    snapshot.complete, snapshot.finishedAt = true, old.wall - 86000
    before.DB.data.markets[key] = snapshot
    truth(before.History.Record(snapshot))
    local world, addon = Hidden(before.DB.data, { [10] = false, [213] = true, [214] = false })
    world:load()
    equal(addon.DB.Snapshot().marketKey, pvp)
    equal(addon.DB.Snapshot().legacyMarketKey, key)
    equal(addon.DB.Price(100).low, 550)
    equal(addon.History.Status().days, 1)
    equal(addon.DB.data.markets[key], snapshot)
    world.faction = "Alliance"
    equal(addon.DB.Snapshot(), nil)
    equal(addon.History.Status().days, 0)
end)

test("new characters can play and retain activity before visiting an auctioneer or choosing a ruleset", function()
    local world, addon = Hidden()
    world:load(false)
    addon.auctionOpen = false
    world:event("PLAYER_ENTERING_WORLD")
    truth(addon.UI.rulesetFrame:IsShown())
    equal(addon.UI.rulesetButtons.pvp.text, "PvP (default)")
    addon.UI.rulesetFrame:Hide()
    world:event("PLAYER_ENTERING_WORLD")
    equal(addon.UI.rulesetFrame:IsShown(), false)

    GOLD_AMOUNT, SILVER_AMOUNT, COPPER_AMOUNT = "%d Gold", "%d Silver", "%d Copper"
    YOU_LOOT_MONEY = "You loot %s."
    LOOT_ITEM_SELF = "You receive loot: %s."
    world.items[100] = { vendor = 40, quality = 1 }
    world:event("PLAYER_REGEN_DISABLED")
    world:advance(30)
    world:event("PLAYER_REGEN_ENABLED")
    world:event("CHAT_MSG_LOOT", "You receive loot: " .. link(100) .. ".")
    world:event("CHAT_MSG_MONEY", "You loot 9 Copper.")
    world:advance(3)
    addon.Farm.Tick()
    addon.Transactions.Tick()
    truth(addon.Drops.Observe("Creature-0-1-1-1-1000-1", {{id=100, quantity=1, quality=1}}))
    world.vendorItems = {{id=2320, price=45, stackCount=5, numAvailable=-1, isPurchasable=true, hasExtendedCost=false}}
    world:event("MERCHANT_SHOW")
    world:event("MERCHANT_CLOSED")
    local saved, activity = addon.DB.data, addon.Farm.Profile()
    local profile, player = addon.Ledger.Profile()
    equal(activity.current.itemTypes, 1)
    equal(activity.current.coins, 9)
    truth(activity.current.elapsed >= 30)
    equal(addon.Ledger.View({kind="loot"})[1].amount, 9)
    equal(addon.Drops.Profile().mobs, 1)
    equal(addon.Vendor.Price(2320), 9)
    equal(addon.DB.Snapshot(), nil)
    equal(addon.Watchlist.Save(100, 1000, 0, 0), false)
    equal(world.requests, 0)

    world:event("PLAYER_LOGOUT")
    local login, after = Hidden(saved)
    login.wall = world.wall + 2
    login:load(false)
    after.auctionOpen = false
    login:event("PLAYER_ENTERING_WORLD")
    truth(after.UI.rulesetFrame:IsShown())
    Choose(after, "roleplayingpvp")
    equal(after.Util.MarketKey(), "forever|1|roleplayingpvp|Horde")
    equal(after.Farm.Profile(), activity)
    equal(after.Ledger.Profile(), profile)
    equal(after.Util.PlayerKey(), player)
    equal(after.Ledger.View({kind="loot"})[1].amount, 9)
    equal(after.Drops.Profile().mobs, 1)
    equal(after.Vendor.Price(2320), 9)
    equal(login.requests, 0)
end)

test("confirmation is per character and blocks scans without using cooldown or auto-starting", function()
    local world, addon = Hidden()
    world:load()
    world:openAH()
    truth(addon.UI.rulesetFrame:IsShown())
    equal(addon.UI.rulesetButton:GetText(), "Confirm ruleset")
    truth(addon.UI.snapshotText:GetText():find("Price snapshot", 1, true))
    addon.UI.rulesetFrame:Hide()
    addon.UI.rulesetButton.scripts.OnClick()
    truth(addon.UI.rulesetFrame:IsShown())
    equal(addon.UI.scanButton:IsEnabled(), false)
    local ok, reason = addon.Scanner.Start()
    equal(ok, false)
    truth(reason:find("Confirm your ruleset", 1, true))
    equal(addon.Scanner.RemainingCooldown(), 0)
    equal(world.requests, 0)
    Choose(addon, "pvp")
    truth(addon.UI.scanButton:IsEnabled())
    equal(addon.UI.rulesetButton:GetText(), "Change ruleset")
    equal(world.requests, 0)
    equal(addon.Util.MarketKey(), pvp)
    equal(addon.Util.MarketInfo().rulesetSource, "saved selection")
    local saved = addon.DB.data

    local other, alt = Hidden(saved)
    other.guid = "Player-1-other"
    other:load(false)
    other:event("PLAYER_ENTERING_WORLD")
    truth(alt.UI.rulesetFrame:IsShown())
    equal(alt.Util.MarketKey(), nil)
    Choose(alt, "normal")
    equal(alt.Util.MarketKey(), "forever|1|normal|Horde")
    other.region = 3
    equal(alt.Util.MarketKey(), nil)
    other.region, other.faction = 1, "Alliance"
    equal(alt.Util.MarketKey(), nil)

    local login, first = Hidden(saved)
    login:load(false)
    login:event("PLAYER_ENTERING_WORLD")
    equal(first.Util.MarketKey(), pvp)
    equal(first.UI.rulesetFrame, nil)
end)

test("ruleset correction and automatic detection preserve completed scans and staged work", function()
    local world, addon = Hidden(nil, { [10] = false, [213] = true, [214] = false })
    world:load()
    world.rows = { row(100, 1, 900) }
    truth(addon.Scanner.Start())
    SlashCmdList.MSMARKETVALUE("ruleset")
    local normal = addon.UI.rulesetButtons.normal
    equal(normal:IsEnabled(), false)
    normal.scripts.OnClick(normal)
    equal(addon.Util.MarketKey(), pvp)
    truth(addon.Scanner.Pause())
    normal.scripts.OnClick(normal)
    equal(addon.Util.MarketKey(), pvp)
    truth(addon.Scanner.Resume())
    addon.Scanner.OnResponse()
    world:drain()
    local completed = addon.DB.Snapshot()
    local cooldown = addon.Scanner.RemainingCooldown()

    Choose(addon, "normal")
    equal(addon.Util.MarketKey(), "forever|1|normal|Horde")
    equal(addon.DB.Snapshot(), nil)
    equal(addon.DB.data.markets[pvp], completed)
    equal(addon.Scanner.state, "IDLE")
    equal(addon.Scanner.RemainingCooldown(), cooldown)
    SlashCmdList.MSMARKETVALUE("ruleset")
    addon.UI.rulesetAuto.scripts.OnClick(addon.UI.rulesetAuto)
    equal(addon.Util.MarketKey(), pvp)
    equal(addon.DB.Snapshot(), completed)
    equal(world.requests, 1)
end)

test("a restricted player ID allows a confirmed market for the current login", function()
    local world, addon = Hidden()
    world.guid = secret
    world:load(false)
    Choose(addon, "pvp")
    equal(addon.Util.MarketKey(), pvp)
    equal(addon.Util.MarketInfo().rulesetSource, "selected for this login")
    equal(addon.DB.data.characterRulesets, nil)
    local login, after = Hidden(addon.DB.data)
    login.guid = secret
    login:load(false)
    equal(after.Util.MarketKey(), nil)
end)
