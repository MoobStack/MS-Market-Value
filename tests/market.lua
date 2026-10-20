-- Loaded by run.lua with its isolated client fixtures and assertion helpers.
local fresh, row, link, test, equal, near, truth, craftingWorld, secret = ...

local function merchant(w, items)
    w.vendorItems = items
    w:event("MERCHANT_SHOW")
end
local function supply(id, price, count)
    return { id = id, price = price, stackCount = count or 1, numAvailable = -1,
        isPurchasable = true, hasExtendedCost = false }
end
local function marketWorld(series)
    local w, A = fresh(); w:load()
    for index, rows in ipairs(series) do
        local snapshot = A.DB.NewSnapshot(A.Util.MarketKey(), #rows, w.wall)
        for _, entry in ipairs(rows) do A.DB.AddRow(snapshot, entry.id, entry.quantity, entry.buyout, entry.link, entry.saleStatus or 0) end
        truth(A.DB.Commit(snapshot))
        if index < #series then w:advance(86400) end
    end
    return w, A
end
local function simple(prices)
    local series = {}
    for _, price in ipairs(prices) do series[#series + 1] = { row(100, 1, price) } end
    return marketWorld(series)
end
local function drain(A, view, sort, force)
    A.Market.Ensure(view, sort, force)
    for _ = 1, 10000 do
        if not A.Market.job then return end
        A.Market.Tick()
    end
    error("market analysis did not finish")
end

test("normal vendor supplies are never silently priced from inflated auctions", function()
    local w, A = craftingWorld()
    w.recipes[1].schematic.reagentSlotSchematics[1].reagents = {{itemID=2320}}
    local snapshot = A.DB.Snapshot(); snapshot.prices[2320] = {low=10000}
    local value = A.Crafting.Analyze(1, w.form)
    equal(value.cost, nil); equal(value.materials[1].mode, "vendor-unseen")
    truth(string.find(value.reason, "supplier", 1, true) or string.find(value.reason, "vendor", 1, true))
end)
test("vendor bundles use actual player cost per unit in crafts profits and quotes", function()
    local w, A = craftingWorld()
    w.recipes[1].schematic.reagentSlotSchematics[1].reagents = {{itemID=2320}}
    merchant(w, {supply(2320, 45, 5)})
    A.DB.data.settings.quoteMarkup=20
    local value = A.Crafting.Analyze(1, w.form)
    equal(value.materials[1].unitPrice, 9); equal(value.materials[1].mode, "vendor")
    equal(value.cost, 218); equal(value.profitMin, 682); near(value.quote, 261.6)
    equal(A.DB.Snapshot().prices[2320],nil); equal(w.requests,1)
end)
test("vendor costing learns unlimited materials outside the common supplies list", function()
    local w, A = craftingWorld(); merchant(w,{supply(100,30)})
    equal(A.Crafting.Analyze(1,w.form).cost,260)
    equal(A.DB.Price(100).low,100)
end)
test("vendor pricing remains fixed even when the current AH material price is cheaper", function()
    local w, A = craftingWorld(); merchant(w,{supply(100,150)})
    equal(A.Crafting.Analyze(1,w.form).cost,500)
end)
test("vendor material costs do not require any completed auction scan", function()
    local w,A=craftingWorld(); merchant(w,{supply(100,10),supply(101,20)})
    A.DB.data.markets[A.Util.MarketKey()]=nil
    local value=A.Crafting.Analyze(1,w.form)
    equal(value.cost,40); equal(value.quote,40); equal(value.profitMin,nil)
end)
test("limited stock barter and unavailable vendor items cannot understate craft costs", function()
    local w,A=craftingWorld()
    local limited,barter,locked=supply(100,1),supply(101,1),supply(102,1)
    limited.numAvailable=1; barter.hasExtendedCost=true; locked.isPurchasable=false
    merchant(w,{limited,barter,locked})
    equal(A.Vendor.Price(100),nil); equal(A.Vendor.Price(101),nil); equal(A.Vendor.Price(102),nil)
    equal(A.Crafting.Analyze(1,w.form).cost,400)
end)
test("malformed and restricted merchant fields are rejected without arithmetic", function()
    local w,A=fresh(); w:load()
    local items={supply(100,0),supply(101,100,0),supply(102,-1),supply(103,100),supply(104,100)}
    items[4].price=secret; items[5].hasExtendedCost=secret
    merchant(w,items); equal(A.Vendor.Status(),0)
end)
test("legacy merchant tuples retain bundle quantities and player discounts", function()
    local w,A=fresh(); w:load(); C_MerchantFrame=nil
    GetMerchantItemInfo=function() return "Thread",1,90,5,-1,true,true,false end
    merchant(w,{supply(2320,1000)}); equal(A.Vendor.Price(2320),18)
end)
test("merchant updates invalidate completed recipe rankings only when prices change", function()
    local w,A=craftingWorld(); merchant(w,{supply(100,25)})
    A.Crafting.Tick(); equal(A.Crafting.dirty,false)
    w:advance(1); A.Vendor.Capture(); equal(A.Crafting.dirty,false)
    w.vendorItems[1].price=20; w:event("MERCHANT_UPDATE")
    A.eventFrame.scripts.OnUpdate(A.eventFrame,.25)
    equal(A.Vendor.Price(100),20); truth(A.Crafting.dirty)
end)
test("vendor observations survive a save-table reload for the same player", function()
    local w,A=fresh(); w:load(); merchant(w,{supply(2320,18)})
    local w2,A2=fresh(A.DB.data); w2:load(); equal(A2.Vendor.Price(2320),18); equal(w2.requests,0)
end)
test("vendor observations never transfer another character's discount", function()
    local w,A=fresh(); w:load(); merchant(w,{supply(2320,18)})
    local w2,A2=fresh(A.DB.data); w2.guid="Player-1-other"; w2:load()
    local price,mode=A2.Vendor.Price(2320); equal(price,nil); equal(mode,"vendor-unseen")
end)
test("vendor observations remain isolated by market and faction", function()
    local w,A=fresh(); w:load(); merchant(w,{supply(2320,18)})
    local w2,A2=fresh(A.DB.data); w2.faction="Alliance"; w2:load(); equal(A2.Vendor.Price(2320),nil)
end)
test("a changed reputation tier requires the player's refreshed vendor cost", function()
    local w,A=fresh(); w:load(); merchant(w,{supply(2320,20)})
    w.factions[1].reaction=6; w:event("UPDATE_FACTION"); equal(A.Vendor.Price(2320),nil)
    w.vendorItems[1].price=18; A.Vendor.Capture(); equal(A.Vendor.Price(2320),18)
end)
test("week-old vendor observations are unavailable rather than falling back to AH", function()
    local w,A=fresh(); w:load(); merchant(w,{supply(2320,18)})
    w:advance(8*86400)
    local price,mode=A.Vendor.Price(2320); equal(price,nil); equal(mode,"vendor-unseen")
end)
test("unknown vendor schemas are preserved without disabling existing market data", function()
    local saved={schema=1,markets={},settings={},vendorBuy={schema=99,characters={}}}
    local w,A=fresh(saved); w:load(); equal(A.DB.data.vendorBuy,saved.vendorBuy)
    truth(A.Vendor.reason); equal(A.disabledReason,nil)
end)
test("merchant learning is deferred in combat and stops when the merchant closes", function()
    local w,A=fresh(); w:load(); w.combat=true; merchant(w,{supply(2320,18)})
    equal(A.Vendor.Price(2320),nil); w.combat=false; A.Vendor.Capture(); equal(A.Vendor.Price(2320),18)
    w:event("MERCHANT_CLOSED"); w.vendorItems[1].price=100; equal(A.Vendor.Capture(),false)
    equal(A.Vendor.Price(2320),18)
end)
test("crafting material rows visibly identify the vendor source", function()
    local w,A=craftingWorld(); merchant(w,{supply(100,10)})
    A.Crafting.Tick(); A.CraftingUI.Refresh()
    equal(A.CraftingUI.materialRows[1].source.text,"Vendor")
end)

test("market targets include the configured AH cut and return on purchase cost", function()
    local w,A=simple({1000,1000,1000,500}); drain(A)
    local value=A.Market.rows[1]
    equal(value.baseline,1000); equal(value.profit,450); equal(value.roi,90)
    equal(value.maxBuy,791); equal(value.days,3); equal(w.requests,0)
end)
test("market analysis excludes today's repeat scans from the historical benchmark", function()
    local w,A=simple({1000,1000,1000,500}); drain(A)
    local first=A.Market.rows[1]
    w:advance(1000)
    local snap=A.DB.NewSnapshot(A.Util.MarketKey(),1,w.wall)
    A.DB.AddRow(snap,100,1,600,link(100),0); truth(A.DB.Commit(snap)); drain(A)
    equal(A.Market.rows[1].days,3); equal(A.Market.rows[1].baseline,first.baseline)
    equal(A.Market.rows[1].current,600)
end)
test("one inflated historical day cannot manufacture a resale opportunity", function()
    local w,A=simple({1000,1000,1000000,1000}); drain(A)
    equal(#A.Market.rows,0)
end)
test("missing days and missing listings do not count as zero-price observations", function()
    local w,A=marketWorld({{row(100,1,1000)},{row(200,1,10)},{row(100,1,1000)},{row(100,1,500)}})
    drain(A); equal(#A.Market.rows,0)
    A.DB.data.settings.marketMinDays=2; drain(A); equal(A.Market.rows[1].days,2)
end)
test("rising and falling views use significant moves from the prior median", function()
    local w,A=simple({1000,1000,1000,2000}); drain(A,"rising")
    equal(#A.Market.rows,1); equal(A.Market.rows[1].movement,100)
    drain(A,"falling"); equal(#A.Market.rows,0)
    local w2,A2=simple({1000,1000,1000,500}); drain(A2,"falling")
    equal(A2.Market.rows[1].movement,-50)
end)
test("minimum gain and return thresholds both govern resale filtering", function()
    local w,A=simple({1000,1000,1000,500})
    A.DB.data.settings.marketMinReturn=91; drain(A); equal(#A.Market.rows,0)
    A.DB.data.settings.marketMinReturn=90; A.DB.data.settings.marketMinProfit=451
    drain(A); equal(#A.Market.rows,0)
    A.DB.data.settings.marketMinProfit=450; drain(A); equal(#A.Market.rows,1)
end)
test("fee changes can remove a thin spread rather than advertising a gross gain", function()
    local w,A=simple({1000,1000,1000,900}); A.DB.data.settings.marketMinProfit=0
    A.DB.data.settings.marketMinReturn=0; A.DB.data.settings.marketMove=0; drain(A); equal(A.Market.rows[1].profit,50)
    A.DB.data.settings.marketFee=15; drain(A); equal(#A.Market.rows,0)
end)
test("target buy prices meet both user thresholds after conservative copper rounding", function()
    local w,A=simple({1001,1001,1001,333}); drain(A)
    local value=A.Market.rows[1]; local proceeds=950
    truth((proceeds-value.maxBuy)/value.maxBuy*100>=20)
    truth(proceeds-value.maxBuy>=100)
    equal(value.maxBuy,791)
end)
test("fractional unit prices round purchase cost upward and proceeds downward", function()
    local w,A=marketWorld({{row(100,3,3001)},{row(100,3,3001)},{row(100,3,3001)},{row(100,3,1000)}})
    drain(A); equal(A.Market.rows[1].buy,334); equal(A.Market.rows[1].profit,616)
end)
test("stale saved scans cannot present current resale or trend signals", function()
    local w,A=simple({1000,1000,1000,500}); drain(A); equal(#A.Market.rows,1)
    w:advance(86401); drain(A,"all"); equal(#A.Market.rows,0); truth(A.Market.reason)
    A.DB.data.settings.staleHours=72; drain(A); equal(#A.Market.rows,1)
end)
test("future-dated snapshots are unavailable rather than fresh market signals", function()
    local w,A=simple({1000,1000,1000,500}); A.DB.Snapshot().startedAt=w.wall+1
    drain(A); equal(#A.Market.rows,0)
end)
test("matching suffix series are kept separate from cheaper variants", function()
    local series={}
    for index=1,4 do series[index]={row(100,1,index==4 and 500 or 1000,-5),row(100,1,10,-6)} end
    local w,A=marketWorld(series); drain(A)
    equal(#A.Market.rows,1); equal(A.Market.rows[1].key,"100:-5"); equal(A.Market.rows[1].baseline,1000)
end)
test("an unobserved suffix never borrows an item-wide historical price", function()
    local w,A=marketWorld({{row(100,1,1000,-6)},{row(100,1,1000,-6)},{row(100,1,1000,-6)},{row(100,1,10,-5)}})
    drain(A); equal(#A.Market.rows,0)
end)
test("the ordinary zero-suffix series is not mixed with randomized equipment", function()
    local series={}
    for index=1,4 do series[index]={row(100,1,index==4 and 500 or 1000,0),row(100,1,10,-6)} end
    local w,A=marketWorld(series); drain(A)
    equal(#A.Market.rows,1); equal(A.Market.rows[1].key,"100:0")
end)
test("known vendor materials are excluded from inflated AH resale comparisons", function()
    local series={}
    for index=1,4 do series[index]={row(2320,1,index==4 and 500 or 1000)} end
    local w,A=marketWorld(series); drain(A,"all"); equal(#A.Market.rows,0)
end)
test("market data and results never leak into another region or faction", function()
    local w,A=simple({1000,1000,1000,500}); drain(A)
    w.region=2; drain(A); equal(#A.Market.rows,0); equal(A.Market.snapshot,nil)
end)
test("market analyses publish once and do not rebuild on unchanged UI refreshes", function()
    local w,A=simple({1000,1000,1000,500}); drain(A)
    local rows=A.Market.rows
    for _=1,100 do A.Market.Ensure(); A.History.Average(100) end
    equal(A.Market.builds,1); equal(A.Market.publications,1); equal(A.Market.rows,rows)
end)
test("history retention changes invalidate the market analysis cache", function()
    local w,A=simple({1000,1000,1000,500}); drain(A)
    truth(A.History.SetRetention(2)); drain(A); equal(#A.Market.rows,0); equal(A.Market.builds,2)
end)
test("market filters rerun atomically while the prior complete list remains visible", function()
    local w,A=simple({1000,1000,1000,500}); drain(A)
    local rows=A.Market.rows
    A.DB.data.settings.marketMinReturn=999; A.Market.Ensure()
    equal(A.Market.rows,rows); truth(A.Market.job); equal(A.Market.publications,1)
    drain(A); equal(#A.Market.rows,0); equal(A.Market.publications,2)
end)
test("a changed source snapshot interrupts unpublished work without partial publication", function()
    local w,A=simple({1000,1000,1000,500}); A.Market.Ensure()
    local previous=A.Market.publications
    w:advance(1000); local snap=A.DB.NewSnapshot(A.Util.MarketKey(),0,w.wall); truth(A.DB.Commit(snap))
    A.Market.Tick(); equal(A.Market.job,nil); equal(A.Market.publications,previous)
    drain(A); equal(#A.Market.rows,0)
end)
test("market processing respects the frame time budget and pauses in combat", function()
    local w,A=simple({1000,1000,1000,500}); A.Market.Ensure()
    w.combat=true; A.Market.Tick(); equal(A.Market.job.phase,"variants")
    w.combat=false
    debugprofilestop=function() w.cpu=w.cpu+5; return w.cpu end
    A.Market.Tick(); truth(A.Market.job); equal(A.Market.job.examined,0)
end)
test("ranked market results retain the best 200 rather than allocating every signal", function()
    local series={}
    for day=1,4 do
        series[day]={}
        for id=100000,100399 do series[day][#series[day]+1]=row(id,1,day==4 and (id-99900) or 1000) end
    end
    local w,A=marketWorld(series); drain(A)
    equal(#A.Market.rows,200); equal(A.Market.eligible,400)
    equal(A.Market.rows[1].id,100000); equal(A.Market.rows[200].id,100199)
end)
test("a recent three-point median can expose a sustained shift separately from one ask", function()
    local w,A=simple({1000,1000,1000,1500,1500,2000}); drain(A,"rising")
    near(A.Market.rows[1].trend,50)
end)
test("restricted invalid and zero prices never create market opportunities", function()
    local w,A=simple({1000,1000,1000,500}); local settings=A.DB.Settings()
    equal(A.Market.Evaluate(secret,{1,2,3},settings),nil)
    equal(A.Market.Evaluate(0,{1,2,3},settings),nil)
    equal(A.Market.Evaluate(1,{100,secret,100},settings),nil)
    equal(A.Market.Evaluate(0/0,{100,100,100},settings),nil)
end)

test("opportunities register immediately before settings without changing native AH tabs", function()
    local w,A=fresh(); w:load(); local ah=w:openAH()
    local tabs=LibStub("LibAHTab-1-0").internalState.Tabs
    equal(tabs[1],A.MarketUI.tabButton); equal(tabs[2],A.UI.tabButton)
    equal(#ah.Tabs,3); truth(ah.BuyContent:IsShown())
    A.MarketUI.tabButton.scripts.OnClick(); truth(A.MarketUI.panel:IsShown()); equal(A.UI.panel:IsShown(),false)
    A.UI.tabButton.scripts.OnClick(); equal(A.MarketUI.panel:IsShown(),false); truth(A.UI.panel:IsShown())
end)
test("the market slash command opens at an auctioneer and makes no scan request", function()
    local w,A=fresh(); w:load(); w:openAH(); SlashCmdList.MSMARKETVALUE("market")
    truth(A.MarketUI.panel:IsShown()); equal(w.requests,0)
end)
test("opportunities hide on combat and auction closure without duplicate tabs", function()
    local w,A=fresh(); w:load(); local ah=w:openAH(); A.MarketUI.Show()
    w.combat=true; w:event("PLAYER_REGEN_DISABLED"); equal(A.MarketUI.panel:IsShown(),false)
    A.MarketUI.tabButton.scripts.OnClick(); equal(A.MarketUI.panel:IsShown(),false)
    w.combat=false; w:event("PLAYER_REGEN_ENABLED"); A.MarketUI.Show()
    w:event("AUCTION_HOUSE_CLOSED"); equal(A.MarketUI.panel:IsShown(),false)
    ah:Hide(); w:openAH(); equal(#LibStub("LibAHTab-1-0").internalState.Tabs,2)
end)
test("market controls apply all validated targets together and display selected details", function()
    local w,A=simple({1000,1000,1000,500}); w:openAH(); A.MarketUI.Show(); drain(A); A.MarketUI.Refresh()
    A.MarketUI.inputs.marketMinReturn:SetText("80"); A.MarketUI.inputs.marketMinProfit:SetText("0.02")
    truth(A.MarketUI.Apply()); equal(A.DB.Settings().marketMinProfit,200)
    drain(A); A.MarketUI.Refresh(); A.MarketUI.rows[1].scripts.OnClick(A.MarketUI.rows[1], "RightButton")
    truth(string.find(A.MarketUI.detail.text,"buy at",1,true))
    A.MarketUI.views.rising.scripts.OnClick(); equal(A.MarketUI.sortButton.text,"Sort: movement")
end)
test("invalid market filters preserve existing settings and do not begin a rebuild", function()
    local w,A=fresh(); w:load(); w:openAH(); A.MarketUI.Show()
    local builds=A.Market.builds
    A.MarketUI.inputs.marketFee:SetText("99"); equal(A.MarketUI.Apply(),false)
    equal(A.DB.Settings().marketFee,5); equal(A.Market.builds,builds)
end)
test("market inputs reject minimum history exceeding the chosen window", function()
    local w,A=fresh(); w:load(); w:openAH(); A.MarketUI.Show()
    A.MarketUI.inputs.marketLookback:SetText("2"); A.MarketUI.inputs.marketMinDays:SetText("3")
    equal(A.MarketUI.Apply(),false); equal(A.DB.Settings().marketLookback,14)
end)
test("market filters survive reloads and invalid saved bounds restore clean defaults", function()
    local w,A=fresh(); w:load(); A.DB.data.settings.marketFee=15; A.DB.data.settings.marketMinDays=100
    local w2,A2=fresh(A.DB.data); w2:load()
    equal(A2.DB.Settings().marketFee,15); equal(A2.DB.Settings().marketMinDays,3)
end)
test("diagnostics identify beta revision vendor coverage and the market analysis", function()
    local w,A=fresh(); w:load(); merchant(w,{supply(2320,20)})
    local text=A.UI.DiagnosticsText()
    truth(string.find(text,"Test revision: 5",1,true)); truth(string.find(text,"Vendor purchase prices: 1",1,true))
    truth(string.find(text,"Market analysis:",1,true))
end)


test("newly learned vendor materials keep their source when a discount changes", function()
    local w,A=craftingWorld(); merchant(w,{supply(100,20)})
    w.factions[1].reaction=6; w:event("UPDATE_FACTION")
    local value=A.Crafting.Analyze(1,w.form)
    equal(value.cost,nil); equal(value.materials[1].mode,"vendor-unseen")
end)


test("loading faction data late preserves valid saved vendor observations", function()
    local w,A=fresh(); w:load(); merchant(w,{supply(2320,18)})
    local w2,A2=fresh(A.DB.data); w2.factions={}; w2:load()
    equal(A2.Vendor.Price(2320),18)
    w2.factions={{factionID=76,reaction=5}}; w2:event("UPDATE_FACTION")
    equal(A2.Vendor.Price(2320),18)
end)


test("tooltip average-cache eviction does not restart unchanged market analysis", function()
    local w,A=simple({1000,1000,1000,500}); drain(A)
    local revision=A.History.revision
    A.History.cache={}; A.History.cacheEntries=4096
    A.History.Average(999); equal(A.History.revision,revision)
    A.Market.Ensure(); equal(A.Market.builds,1); equal(A.Market.job,nil)
end)

-- Revision 2: movement thresholds, gold entry and explicit native lookups.
test("resale applies price movement even when return and profit targets pass", function()
    local w,A=simple({120000,120000,120000,19600})
    A.DB.data.settings.marketMinReturn=200; A.DB.data.settings.marketMinProfit=50000
    A.DB.data.settings.marketMove=500; drain(A); equal(#A.Market.rows,0)
    A.DB.data.settings.marketMove=80; drain(A); equal(#A.Market.rows,1)
    A.DB.data.settings.marketMove=90; drain(A); equal(#A.Market.rows,0)
end)
test("exact movement thresholds include the boundary and reject smaller changes", function()
    local w,A=simple({1000,1000,1000,800}); local s=A.DB.Settings()
    s.marketMove=20; s.marketMinReturn=0
    truth(A.Market.Evaluate(800,{1000,1000,1000},s).deal)
    equal(A.Market.Evaluate(800.001,{1000,1000,1000},s).deal,false)
    truth(A.Market.Evaluate(1200,{1000,1000,1000},s).rising)
    equal(A.Market.Evaluate(1199.999,{1000,1000,1000},s).rising,false)
end)
test("zero disables the resale movement requirement without treating flat prices as trends", function()
    local w,A=simple({1000,1000,1000,900}); local s=A.DB.Settings()
    s.marketMinReturn=0; s.marketMinProfit=0; s.marketMove=0
    drain(A); equal(#A.Market.rows,1)
    local flat=A.Market.Evaluate(1000,{1000,1000,1000},s)
    equal(flat.rising,false); equal(flat.falling,false)
end)
test("all signals respects movement while keeping directional alerts independent of resale profit", function()
    local w,A=simple({1000,1000,1000,500}); A.DB.data.settings.marketMove=60
    drain(A,"all"); equal(#A.Market.rows,0)
    A.DB.data.settings.marketMove=50; drain(A,"all"); equal(#A.Market.rows,1)
    local w2,A2=simple({1000,1000,1000,2000}); A2.DB.data.settings.marketMinReturn=1000
    drain(A2,"all"); equal(#A2.Market.rows,1); equal(A2.Market.rows[1].deal,false)
end)
test("gold decimal parsing converts silver and copper exactly", function()
    local w,A=fresh()
    local cases={{"0.25",2500},{".25",2500},{"2",20000},{"2.",20000},{"0.0001",1},
        {"1234.5678",12345678},{"10000",100000000},{" 0.0100 ",100},{"0",0}}
    for _,case in ipairs(cases) do equal(A.MarketUI.ParseGold(case[1]),case[2]) end
end)
test("gold entry rejects malformed fractional overprecision and out of bounds values", function()
    local w,A=fresh()
    for _,text in ipairs({"",".","1e2","-1","+1","nan","1,25","1.00001","10000.0001","1.2.3"}) do
        equal(A.MarketUI.ParseGold(text),nil,text)
    end
    equal(A.MarketUI.ParseGold(secret),nil)
end)
test("all copper settings round trip through the gold display at representative boundaries", function()
    local w,A=fresh()
    for _,copper in ipairs({0,1,9,10,99,100,999,2500,9999,10000,50000,12345678,100000000}) do
        equal(A.MarketUI.ParseGold(A.MarketUI.GoldText(copper)),copper)
    end
end)
test("saved silver-era profit targets retain their copper value and display as gold", function()
    local w,A=fresh(); w:load(); A.DB.data.settings.marketMinProfit=50000; A.DB.data.settings.marketMove=0
    local w2,A2=fresh(A.DB.data); w2:load(); w2:openAH(); A2.MarketUI.Show()
    equal(A2.MarketUI.inputs.marketMinProfit:GetText(),"5"); equal(A2.DB.Settings().marketMinProfit,50000)
    equal(A2.DB.Settings().marketMove,0); equal(A2.MarketUI.inputs.marketMinProfit.numeric,false)
end)
test("typed filters survive focus changes and periodic refreshes until applied", function()
    local w,A=simple({1000,1000,1000,500}); w:openAH(); A.MarketUI.Show(); drain(A); A.MarketUI.Refresh()
    local box=A.MarketUI.inputs.marketMinProfit
    box:SetText("0.25"); box.scripts.OnTextChanged(box,true); box:ClearFocus()
    for _=1,5 do A.eventFrame.scripts.OnUpdate(A.eventFrame,.25) end
    equal(box:GetText(),"0.25"); equal(A.DB.Settings().marketMinProfit,100)
    truth(string.find(A.MarketUI.status.text,"Changes not applied",1,true))
    truth(A.MarketUI.Apply()); equal(A.DB.Settings().marketMinProfit,2500)
end)
test("escape restores only the focused unapplied field", function()
    local w,A=fresh(); w:load(); w:openAH(); A.MarketUI.Show()
    local gold,fee=A.MarketUI.inputs.marketMinProfit,A.MarketUI.inputs.marketFee
    gold:SetText(".25"); gold.scripts.OnTextChanged(gold,true)
    fee:SetText("7"); fee.scripts.OnTextChanged(fee,true)
    gold.scripts.OnEscapePressed(gold)
    equal(gold:GetText(),"0.01"); equal(fee:GetText(),"7"); truth(A.MarketUI.dirty.marketFee)
end)
test("invalid gold does not apply any settings or restart analysis", function()
    local w,A=simple({1000,1000,1000,500}); w:openAH(); A.MarketUI.Show(); drain(A); A.MarketUI.Refresh()
    local builds=A.Market.builds
    A.MarketUI.inputs.marketFee:SetText("7"); A.MarketUI.inputs.marketMinProfit:SetText("1.00001")
    equal(A.MarketUI.Apply(),false); equal(A.DB.Settings().marketFee,5); equal(A.Market.builds,builds)
end)
test("applying unchanged filters reuses the completed analysis", function()
    local w,A=simple({1000,1000,1000,500}); w:openAH(); A.MarketUI.Show(); drain(A); A.MarketUI.Refresh()
    local builds=A.Market.builds
    truth(A.MarketUI.Apply()); equal(A.Market.builds,builds); equal(A.Market.job,nil)
end)

local function liveWorld(series, item)
    local w,A
    if series then w,A=marketWorld(series) else w,A=simple({1000,1000,1000,500}) end
    w.items[100]=item or {name="Pattern: Test Robe"}
    w:openAH(); local ah=w:nativeSearch(); A.MarketUI.Show(); drain(A); A.MarketUI.Refresh()
    return w,A,ah
end
local function click(A,mouse)
    local button=A.MarketUI.rows[1]; button.scripts.OnClick(button,mouse or "LeftButton")
end

test("a left click opens one exact native item lookup without a full scan", function()
    local w,A,ah=liveWorld(); local cooldown=A.Scanner.RemainingCooldown()
    click(A)
    equal(w.itemSearches,1); equal(w.browseSearches,0); equal(w.requests,0)
    equal(w.searchedKey.itemID,100); equal(w.searchedKey.itemLevel,0); equal(w.searchedKey.itemSuffix,0)
    equal(w.searchedContext,AuctionHouseSearchContext.BuyItems)
    equal(ah.displayMode,AuctionHouseFrameDisplayMode.ItemBuy); equal(ah.SearchBar.searchText,"Pattern: Test Robe")
    equal(A.MarketUI.panel:IsShown(),false); equal(A.Scanner.RemainingCooldown(),cooldown)
end)
test("equipment live lookups preserve the signed random suffix and item level", function()
    local series={}
    for day=1,4 do series[day]={{id=100,quantity=1,buyout=day==4 and 500 or 1000,link=link(100,-7)}} end
    local w,A,ah=liveWorld(series,{name="Test Robe of the Owl",equipment=true,level=42})
    click(A); equal(w.itemSearches,1); equal(w.searchedKey.itemSuffix,-7); equal(w.searchedKey.itemLevel,42)
end)
test("commodities open their native listings and use the commodity search context", function()
    local w,A,ah=liveWorld(nil,{name="Test Cloth",commodity=true})
    click(A); equal(w.itemSearches,1); equal(w.searchedContext,AuctionHouseSearchContext.BuyCommodities)
    equal(ah.displayMode,AuctionHouseFrameDisplayMode.CommoditiesBuy)
end)
test("right click and hover show details without issuing any item search", function()
    local w,A=liveWorld(); local button=A.MarketUI.rows[1]
    button.scripts.OnEnter(button); truth(button.highlight:IsShown()); truth(GameTooltip:IsShown())
    click(A,"RightButton"); truth(string.find(A.MarketUI.detail.text,"buy at",1,true))
    button.scripts.OnLeave(button); equal(GameTooltip:IsShown(),false)
    equal(w.itemSearches,0); equal(w.browseSearches,0); truth(A.MarketUI.panel:IsShown())
end)
test("analysis refresh sorting and rechecking never launch live searches", function()
    local w,A=liveWorld()
    for _=1,10 do A.eventFrame.scripts.OnUpdate(A.eventFrame,.25); A.MarketUI.Refresh() end
    A.MarketUI.sortButton.scripts.OnClick(); drain(A,A.MarketUI.view,A.MarketUI.sort); A.MarketUI.Refresh()
    A.MarketUI.recheck.scripts.OnClick(); drain(A,A.MarketUI.view,A.MarketUI.sort)
    equal(w.itemSearches,0); equal(w.browseSearches,0); equal(w.requests,0)
end)
test("throttled lookups wait for another player click without queuing a search", function()
    local w,A=liveWorld(); w.ready=false; click(A); equal(w.itemSearches,0)
    w.ready=true; w:advance(1); A.eventFrame.scripts.OnUpdate(A.eventFrame,.25); equal(w.itemSearches,0)
    click(A); equal(w.itemSearches,1)
end)
test("a repeated click cannot immediately duplicate the item lookup", function()
    local w,A=liveWorld(); local item=A.Market.rows[1]
    truth(A.MarketUI.OpenListings(item)); equal(A.MarketUI.OpenListings(item),false); equal(w.itemSearches,1)
    w:advance(1); truth(A.MarketUI.OpenListings(item)); equal(w.itemSearches,2)
end)
test("combat and a closed or forbidden auction frame block item lookups", function()
    local w,A,ah=liveWorld(); local item=A.Market.rows[1]
    w.combat=true; equal(A.MarketUI.OpenListings(item),false)
    w.combat=false; A.auctionOpen=false; equal(A.MarketUI.OpenListings(item),false)
    A.auctionOpen=true; ah.forbidden=true; equal(A.MarketUI.OpenListings(item),false)
    ah.forbidden=false; ah:Hide(); equal(A.MarketUI.OpenListings(item),false)
    equal(w.itemSearches,0); equal(w.browseSearches,0)
end)
test("pending analysis unapplied filters and nonpublished rows cannot open stale listings", function()
    local w,A=liveWorld(); local item=A.Market.rows[1]
    A.Market.Ensure("deals","return",true); equal(A.MarketUI.OpenListings(item),false)
    drain(A); A.MarketUI.Refresh(); item=A.Market.rows[1]
    A.MarketUI.dirty.marketFee=true; equal(A.MarketUI.OpenListings(item),false)
    A.MarketUI.dirty={}; equal(A.MarketUI.OpenListings({id=100}),false)
    equal(w.itemSearches,0)
end)
test("a stale scan changed market or replaced snapshot requires current published results", function()
    local w,A=liveWorld(); local item=A.Market.rows[1]
    w.wall=w.wall+86401; equal(A.MarketUI.OpenListings(item),false)
    w.wall=w.wall-86401; w.region=2; equal(A.MarketUI.OpenListings(item),false)
    w.region=1
    local snap=A.DB.NewSnapshot(A.Util.MarketKey(),0,w.wall); truth(A.DB.Commit(snap))
    equal(A.MarketUI.OpenListings(item),false); equal(w.itemSearches,0)
end)
test("missing exact item APIs fall back to the native Buy name search on click", function()
    local w,A,ah=liveWorld(); C_AuctionHouse.MakeItemKey=nil; click(A)
    equal(w.itemSearches,0); equal(w.browseSearches,1)
    equal(ah.displayMode,AuctionHouseFrameDisplayMode.Buy); equal(ah.SearchBar.searchText,"Pattern: Test Robe")
end)
test("uncached items do not search using invented item names or guessed keys", function()
    local w,A=liveWorld(); w.items[100]=nil; click(A)
    equal(w.itemSearches,0); equal(w.browseSearches,0); truth(A.MarketUI.message)
end)
test("restricted item keys are not forwarded into native search calls", function()
    local w,A=liveWorld(); C_AuctionHouse.MakeItemKey=function() return secret end
    click(A); equal(w.itemSearches,0); equal(w.browseSearches,1)
end)
test("native search errors are handled once without an automatic retry", function()
    local w,A,ah=liveWorld(); ah.QueryItem=function() w.itemSearches=w.itemSearches+1; error("native unavailable") end
    click(A); equal(w.itemSearches,1); equal(w.browseSearches,0); truth(A.MarketUI.message)
    w:advance(1); A.eventFrame.scripts.OnUpdate(A.eventFrame,.25); equal(w.itemSearches,1)
end)

test("live lookups wait until an incomplete full scan has its complete local copy", function()
    local w,A=liveWorld(); local item=A.Market.rows[1]
    A.Scanner.active=true; A.Scanner.localReady=false
    equal(A.MarketUI.OpenListings(item),false); equal(w.itemSearches,0)
    A.Scanner.active=false; A.Scanner.paused=true
    equal(A.MarketUI.OpenListings(item),false); equal(w.itemSearches,0)
    A.Scanner.localReady=true; truth(A.MarketUI.OpenListings(item)); equal(w.itemSearches,1)
end)
