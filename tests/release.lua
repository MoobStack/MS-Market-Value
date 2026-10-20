local fresh,craftingWorld,test,equal,truth=...
local function sameData(actual,expected)
    if type(expected)~="table"then return equal(actual,expected)end
    truth(type(actual)=="table")
    for key,value in pairs(expected)do sameData(actual[key],value)end
    for key in pairs(actual)do truth(expected[key]~=nil,"unexpected saved field")end
end

test("beta-to-stable upgrade retains all money tools settings and recorded cost bases",function()
    local w,A=craftingWorld();local L=A.Ledger;local saved=A.DB.data
    w.vendorItems={{id=2320,price=45,stackCount=5,numAvailable=-1,isPurchasable=true,hasExtendedCost=false}}
    w:event("MERCHANT_SHOW")
    truth(A.Watchlist.Save(100,1000,20,100))
    truth(L.Record({kind="sale",name="Costed sale",quantity=1,amount=1000,fee=50,cost=400}))
    truth(L.Record({kind="commission",name="Craft",quantity=1,amount=600,cost=300,estimatedCost=true,source="Craft quote"}))
    truth(L.Record({kind="expense",category="repair",name="Repairs",quantity=1,amount=30}))
    truth(L.AddLoot(100,math.floor(w.wall),L.LocalDay(w.wall)))
    saved.version,saved.build="1.2.0-beta","2026-10-20-beta001"
    saved.settings.serviceLabor=120;saved.settings.serviceMinimum=500;saved.settings.ledgerDays=60
    saved.settings.trackLoot=false;saved.settings.trackOther=false;saved.settings.trackTrade=false
    local roots={markets=saved.markets,history=saved.history,vendorBuy=saved.vendorBuy,watchlists=saved.watchlists,ledger=saved.ledger}
    local rows=L.Records();local sum=L.Summary();local first=rows[1].time
    local w2,A2=fresh(saved);w2.wall=w.wall;w2:load()
    equal(A2.VERSION,"1.2.0");equal(A2.BUILD,"2026-10-20-release001");equal(A2.TEST_REVISION,nil)
    for key,value in pairs(roots)do sameData(A2.DB.data[key],value)end
    equal(#A2.Ledger.Records(),4);equal(A2.Ledger.Records()[1].time,first)
    equal(A2.Ledger.Summary().flow,sum.flow);equal(A2.Ledger.Summary().profit,sum.profit);equal(A2.Ledger.Summary().estimatedProfit,sum.estimatedProfit)
    equal(#A2.Watchlist.Entries(),1);equal(A2.Vendor.Price(2320),9)
    equal(A2.DB.Settings().serviceLabor,120);equal(A2.DB.Settings().serviceMinimum,500);equal(A2.DB.Settings().ledgerDays,60)
    equal(A2.DB.Settings().trackLoot,false);equal(A2.DB.Settings().trackOther,false);equal(A2.DB.Settings().trackTrade,false)
    equal(A2.DB.data.version,"1.2.0");equal(w2.requests,0)
end)

test("beta pending loot and expense confirmations settle once after the stable upgrade",function()
    local w,A=fresh();w:load();local L=A.Ledger;L.limit=1
    truth(L.Record({kind="buy",name="Existing entry",quantity=1,amount=10}))
    local stamp=math.floor(w.wall);local day=L.LocalDay(stamp)
    A.Transactions.Enqueue({kind="loot",name="Money looted",quantity=1,amount=100,cost=0,fee=0,source="Loot",time=stamp,lootDay=day,autoKey="loot:"..day})
    A.Transactions.Enqueue({kind="expense",category="repair",name="Item repairs",quantity=1,amount=30,fee=0,source="Game expense",time=stamp,autoKey="beta-pending-repair"})
    equal(#A.Transactions.queue,2)
    local saved=A.DB.data;saved.version,saved.build="1.2.0-beta","2026-10-20-beta001"
    local w2,A2=fresh(saved);w2.wall=w.wall;w2:load();A2.Transactions.Tick();w2:advance(2);A2.Transactions.Tick()
    equal(#A2.Transactions.queue,0);equal(#A2.Ledger.Records(),3)
    equal(A2.Ledger.View({kind="loot"})[1].amount,100);equal(A2.Ledger.View({kind="loot"})[1].time,stamp)
    equal(A2.Ledger.View({kind="expense"})[1].category,"repair");equal(A2.Ledger.View({kind="expense"})[1].time,stamp)
    A2.Transactions.Tick();equal(#A2.Ledger.Records(),3);equal(A2.Ledger.Summary().flow,60);equal(w2.requests,0)
end)
