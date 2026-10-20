local fresh,craftingWorld,craftRecipe,link,test,equal,near,truth,secret=...
local function world()
    local w,A=fresh();w:load()
    w.items[100]={name="Test item",vendor=50};w.items[200]={name="Other item",vendor=100}
    w.wallet=100000;GetMoney=function()return w.wallet end;NUM_BAG_SLOTS=4
    C_Container.GetContainerNumSlots=function(bag)return bag==0 and 16 or 0 end
    w.vendorItems={{id=100,name="Test item",price=500,stackCount=5,numAvailable=-1,hasExtendedCost=false}}
    BuyMerchantItem=function()w.nativeBuys=(w.nativeBuys or 0)+1 end
    BuybackItem=function()end;SellCursorItem=function()end;PickupMerchantItem=function()end
    C_Container.UseContainerItem=function()end
    C_AuctionHouse.PlaceBid=function()w.nativeBids=(w.nativeBids or 0)+1 end
    C_AuctionHouse.StartCommoditiesPurchase=function()end;C_AuctionHouse.ConfirmCommoditiesPurchase=function()end
    C_AuctionHouse.CancelCommoditiesPurchase=function()end
    A.Transactions.Install()
    function w:tick(seconds)
        self:advance(seconds or .25);A.Transactions.Tick()
    end
    function w:bag(id,quantity,slot,suffix)
        self.containers["0:"..(slot or 1)]=quantity>0 and {itemID=id,stackCount=quantity,hyperlink=link(id,suffix)}or nil
    end
    return w,A
end
local function mail(w,rows)
    w.mail=rows
    GetInboxNumItems=function()return #w.mail end
    GetInboxInvoiceInfo=function(index)
        local r=w.mail[index]
        return r.kind or "seller",r.name or "Test item",secret,r.amount or 10000,0,r.refund or 0,r.fee or 0,0,0,0,r.quantity or 1,false
    end
    GetInboxHeaderInfo=function(index)local r=w.mail[index];return nil,nil,secret,secret,0,0,(r.expiry or(w.wall+30*86400)-w.wall)/86400 end
    GetInboxItem=function(index)local r=w.mail[index];return r.name or"Test item",r.itemID,1,r.quantity or 1 end
    w:event("MAIL_SHOW")
end
local function drain(w,A)
    for _=1,2000 do
        if not A.Transactions.mailDirty and not A.Transactions.mailJob then return end
        w:advance(.25);A.Transactions.Tick()
    end
    error("Inbox job did not finish")
end
local function buy(w,A,id,price,qty)
    A.Transactions.selectedAuction={auctionID=id,itemID=100,name="Test item",amount=price or 10000,quantity=qty or 1}
    C_AuctionHouse.PlaceBid(id,price or 10000)
    w:event("AUCTION_HOUSE_PURCHASE_COMPLETED",id)
end

test("item purchase intents wait for a matching server completion",function()
    local w,A=world();A.Transactions.selectedAuction={auctionID=42,itemID=100,name="Test item",amount=10000,quantity=3}
    C_AuctionHouse.PlaceBid(42,10000);equal(#A.Ledger.Records(),0)
    w:event("AUCTION_HOUSE_PURCHASE_COMPLETED",43);equal(#A.Ledger.Records(),0)
    w:event("AUCTION_HOUSE_PURCHASE_COMPLETED",42);local r=A.Ledger.Records()[1]
    equal(r.amount,10000);equal(r.quantity,3);equal(r.kind,"buy");equal(r.source,"AH purchase");equal(w.nativeBids,1)
end)
test("bids cancelled purchases and unknown auction completions do not count as buys",function()
    local w,A=world();A.Transactions.selectedAuction={auctionID=42,itemID=100,name="Test item",amount=10000,quantity=1}
    C_AuctionHouse.PlaceBid(42,5000);w:event("AUCTION_HOUSE_PURCHASE_COMPLETED",42);equal(#A.Ledger.Records(),0)
    C_AuctionHouse.PlaceBid(42,10000);w:tick(121);w:event("AUCTION_HOUSE_PURCHASE_COMPLETED",42);equal(#A.Ledger.Records(),0)
end)
test("repeated item completion events and deleted receipt rows cannot duplicate a buy",function()
    local w,A=world();buy(w,A,42);w:event("AUCTION_HOUSE_PURCHASE_COMPLETED",42);equal(#A.Ledger.Records(),1)
    A.Ledger.Remove(A.Ledger.Records()[1].id);buy(w,A,42);equal(#A.Ledger.Records(),0)
end)
test("purchase observers can read the selected native row without controlling it",function()
    local w,A=world();local ah=w:makeAH();ah.ItemBuyFrame=CreateFrame("Frame");ah.ItemBuyFrame.ItemList={GetSelectedEntry=function()return {auctionID=33,itemKey={itemID=100},buyoutAmount=1234,quantity=2,itemLink=link(100)}end}
    C_AuctionHouse.PlaceBid(33,1234);w:event("AUCTION_HOUSE_PURCHASE_COMPLETED",33)
    equal(A.Ledger.Records()[1].quantity,2);equal(A.Ledger.Records()[1].amount,1234)
end)
test("commodity purchases use the last server total and require confirmation plus success",function()
    local w,A=world();C_AuctionHouse.StartCommoditiesPurchase(100,5)
    w:event("COMMODITY_PRICE_UPDATED",100,500);w:event("COMMODITY_PRICE_UPDATED",105,515)
    equal(#A.Ledger.Records(),0);C_AuctionHouse.ConfirmCommoditiesPurchase(100,5)
    C_AuctionHouse.CancelCommoditiesPurchase();w:event("COMMODITY_PURCHASE_SUCCEEDED")
    local r=A.Ledger.Records()[1];equal(r.amount,515);equal(r.quantity,5);equal(r.itemID,100)
    w:event("COMMODITY_PURCHASE_SUCCEEDED");equal(#A.Ledger.Records(),1)
end)
test("commodity failures expired quotes and mismatched quantities cannot produce purchases",function()
    local w,A=world();C_AuctionHouse.StartCommoditiesPurchase(100,5);w:event("COMMODITY_PRICE_UPDATED",100,500)
    C_AuctionHouse.ConfirmCommoditiesPurchase(100,4);w:event("COMMODITY_PURCHASE_SUCCEEDED");equal(#A.Ledger.Records(),0)
    C_AuctionHouse.StartCommoditiesPurchase(100,5);w:event("COMMODITY_PRICE_UPDATED",100,500);C_AuctionHouse.ConfirmCommoditiesPurchase(100,5)
    w:event("COMMODITY_PURCHASE_FAILED");w:event("COMMODITY_PURCHASE_SUCCEEDED");equal(#A.Ledger.Records(),0)
end)
test("restricted purchase identities and quotes are ignored without arithmetic",function()
    local w,A=world();A.Transactions.ObserveBid(secret,secret);A.Transactions.StartCommodity(secret,1)
    A.Transactions.StartCommodity(100,1);A.Transactions.CommodityQuote(secret,secret);A.Transactions.PurchaseCompleted(secret)
    equal(#A.Ledger.Records(),0)
end)
test("mailbox invoices automatically record sales with exact fees and excluded deposits",function()
    local w,A=world();mail(w,{{amount=10000,fee=500,refund=100,quantity=2}});drain(w,A)
    local r=A.Ledger.Records()[1];equal(r.kind,"sale");equal(r.source,"AH mail");equal(r.amount,10000);equal(r.fee,500)
    equal(A.Ledger.Summary().flow,9500);equal(A.Ledger.Summary().unknown,1);equal(r.cost,nil)
end)
test("pending sale mail does not record a completed transaction",function()
    local w,A=world();mail(w,{{kind="seller_temp_invoice"},{kind="ordinary"}});drain(w,A);equal(#A.Ledger.Records(),0)
end)
test("automatic purchase invoices reconcile a live purchase instead of counting it twice",function()
    local w,A=world();buy(w,A,55,10000,2)
    mail(w,{{kind="buyer",amount=10000,quantity=2,itemID=100}});drain(w,A)
    equal(#A.Ledger.Records(),1);equal(A.Transactions.reconciled,1);truth(A.Ledger.Records()[1].invoiceKey)
    w:event("MAIL_INBOX_UPDATE");drain(w,A);equal(#A.Ledger.Records(),1)
end)
test("unobserved purchase invoices backfill purchases without inventing market prices",function()
    local w,A=world();mail(w,{{kind="buyer",amount=3210,quantity=3}});drain(w,A)
    local r=A.Ledger.Records()[1];equal(r.kind,"buy");equal(r.amount,3210);equal(A.Ledger.Summary().spend,3210);equal(w.requests,0)
end)
test("several identical simultaneous invoices retain their multiplicity on every revisit",function()
    local w,A=world();mail(w,{{},{},{}});drain(w,A);equal(#A.Ledger.Records(),3)
    for _=1,3 do w:event("MAIL_INBOX_UPDATE");drain(w,A);equal(#A.Ledger.Records(),3)end
end)
test("manual invoice imports from the previous revision are recognised by automatic tracking",function()
    local w,A=world();mail(w,{{}});local input=A.Ledger.ReadInvoice(1);truth(A.Ledger.Record(input));drain(w,A)
    equal(#A.Ledger.Records(),1);equal(A.Ledger.Records()[1].source,"AH invoice")
end)
test("mail reorder and collected invoices do not inflate saved sales",function()
    local w,A=world();mail(w,{{amount=100},{amount=200}});drain(w,A)
    w.mail={w.mail[2],w.mail[1]};w:event("MAIL_INBOX_UPDATE");drain(w,A);equal(#A.Ledger.Records(),2)
    table.remove(w.mail,1);w:event("MAIL_INBOX_UPDATE");drain(w,A);equal(#A.Ledger.Records(),2)
end)
test("mail changes during a read cancel the unfinished inbox snapshot",function()
    local w,A=world();local rows={};for i=1,30 do rows[i]={amount=i}end;mail(w,rows)
    w:tick();equal(#A.Ledger.Records(),0);w.mail={{amount=999}};w:event("MAIL_INBOX_UPDATE");drain(w,A)
    equal(#A.Ledger.Records(),1);equal(A.Ledger.Records()[1].amount,999)
end)
test("closing the mailbox cancels its reader without collecting any attachments",function()
    local w,A=world();mail(w,{{}});w:event("MAIL_CLOSED");w:tick();equal(#A.Ledger.Records(),0);equal(w.requests,0)
end)
test("automatic ledger writes remain safe while combat hides the UI",function()
    local w,A=world();w.combat=true;buy(w,A,123);equal(#A.Ledger.Records(),1)
    equal(A.EconomyUI.frame,nil);equal(A.Ledger.Record({kind="sale",name="Manual",quantity=1,amount=1}),false)
end)
test("vendor purchases require the observed bag gain and matching wallet cost",function()
    local w,A=world();w:event("MERCHANT_SHOW");BuyMerchantItem(1,5);equal(#A.Ledger.Records(),0)
    w:bag(100,5);w.wallet=w.wallet-500;w:event("PLAYER_MONEY");w:event("BAG_UPDATE_DELAYED");w:tick()
    local r=A.Ledger.Records()[1];truth(r);equal(r.kind,"vendor_buy");equal(r.quantity,5);equal(r.amount,500)
    equal(w.nativeBuys,1);equal(A.Ledger.Summary().flow,-500)
end)
test("vendor sales use observed stack losses and the item sell value",function()
    local w,A=world();w:bag(100,3);w:event("MERCHANT_SHOW");C_Container.UseContainerItem(0,1)
    w:bag(100,0);w.wallet=w.wallet+150;w:event("PLAYER_MONEY");w:event("BAG_UPDATE_DELAYED");w:tick()
    local r=A.Ledger.Records()[1];equal(r.kind,"vendor_sale");equal(r.amount,150);equal(r.quantity,3);equal(A.Ledger.Summary().unknown,1)
end)
test("vendor batch reconciliation handles multiple items and mixed buys and sales",function()
    local w,A=world();w:bag(200,2,2);w:event("MERCHANT_SHOW");BuyMerchantItem(1,5);C_Container.UseContainerItem(0,2)
    w:bag(100,5,1);w:bag(200,0,2);w.wallet=w.wallet-300;w:event("PLAYER_MONEY");w:event("BAG_UPDATE_DELAYED");w:tick()
    equal(#A.Ledger.Records(),2);equal(A.Ledger.Summary().sales,200);equal(A.Ledger.Summary().spend,500);equal(A.Ledger.Summary().flow,-300)
end)
test("wallet-only changes bag moves and failed vendor buys are not transactions",function()
    local w,A=world();w:bag(100,1);w:event("MERCHANT_SHOW");w.wallet=w.wallet+100;w:event("PLAYER_MONEY");w:tick()
    equal(#A.Ledger.Records(),0);BuyMerchantItem(1,5);w:tick(4);equal(#A.Ledger.Records(),0)
end)
test("unmatched vendor value changes stay unrecorded and report a diagnostic reason",function()
    local w,A=world();w:event("MERCHANT_SHOW");BuyMerchantItem(1,5);w:bag(100,5);w.wallet=w.wallet-999
    w:event("PLAYER_MONEY");w:event("BAG_UPDATE_DELAYED");w:tick(4);equal(#A.Ledger.Records(),0);truth(A.Transactions.reason)
end)
test("late vendor money and inventory events can reconcile after the merchant closes",function()
    local w,A=world();w:event("MERCHANT_SHOW");BuyMerchantItem(1,5);w:event("MERCHANT_CLOSED")
    w:bag(100,5);w.wallet=w.wallet-500;w:event("BAG_UPDATE_DELAYED");w:tick()
    equal(#A.Ledger.Records(),1);equal(A.Ledger.Records()[1].kind,"vendor_buy")
end)
test("disabled tracking stops new AH and vendor records",function()
    local w,A=world();A.DB.data.settings.trackAH=false;A.DB.data.settings.trackVendor=false
    buy(w,A,42);mail(w,{{}});w:tick();w:event("MERCHANT_SHOW");BuyMerchantItem(1,5);w:bag(100,5);w.wallet=w.wallet-500;w:event("BAG_UPDATE_DELAYED");w:tick()
    equal(#A.Ledger.Records(),0)
end)
test("reinstalling observers does not multiply callbacks or native actions",function()
    local w,A=world();for _=1,10 do A.Transactions.Install()end;buy(w,A,42)
    equal(#A.Ledger.Records(),1);equal(A.Transactions.captured,1);equal(w.nativeBids,1)
end)
test("recorded purchases survive reload and reconcile later invoice delivery",function()
    local w,A=world();buy(w,A,42,10000,2);local saved=A.DB.data
    local w2,A2=fresh(saved);w2:load();mail(w2,{{kind="buyer",amount=10000,quantity=2,itemID=100}});drain(w2,A2)
    equal(#A2.Ledger.Records(),1);equal(A2.Transactions.reconciled,1)
end)

test("commission inputs use a unit price quantity and one total tip",function()
    local w,A=craftingWorld();A.Crafting.Tick();local UI=A.CraftingUI
    UI.saleInputs.price:SetText("2");UI.saleInputs.quantity:SetText("3");UI.saleInputs.tip:SetText(".25");truth(UI.RecordCommission())
    local r=A.Ledger.Records()[1];equal(r.kind,"commission");equal(r.amount,60000);equal(r.tip,2500);equal(r.quantity,3)
    equal(r.cost,1200);truth(r.estimatedCost);equal(A.Ledger.Summary().estimatedProfit,61300);equal(A.Ledger.Summary().profit,0)
    equal(UI.saleInputs.quantity.text,"1");equal(UI.saleInputs.tip.text,"0");equal(UI.RecordCommission(),false)
end)
test("fixed-yield quote defaults and material estimates use per-item quantities",function()
    local w,A=craftingWorld();w.recipes[1]=craftRecipe(1,200,2,2);A.Crafting.Tick()
    truth(A.Ledger.Commission(A.Crafting.selected,nil,0,3));local r=A.Ledger.Records()[1]
    equal(r.amount,600);equal(r.cost,600);equal(r.quantity,3)
end)
test("service customer-material commissions have zero own material cost",function()
    local w,A=craftingWorld();w.recipes[4]=craftRecipe(4,nil);w.recipeIDs={4};w.selectedID=4
    A.DB.data.settings.serviceCustomerMaterials=true;A.DB.data.settings.serviceLabor=5000;A.Crafting.Tick()
    truth(A.Ledger.Commission(A.Crafting.selected,nil,1000,2));local r=A.Ledger.Records()[1]
    equal(r.amount,10000);equal(r.cost,0);equal(r.estimatedCost,nil);equal(A.Ledger.Summary().profit,11000)
end)
test("missing material costs never turn an explicit commission into free materials",function()
    local w,A=world();truth(A.Ledger.Commission({name="Unknown recipe",recipeID=1},1000,0,1));local r=A.Ledger.Records()[1]
    equal(r.cost,nil);equal(A.Ledger.Summary().unknown,1)
    equal(A.Ledger.Commission({name="Unknown recipe",recipeID=1},nil,0,1),false)
end)
test("commission input validation is atomic and respects combat",function()
    local w,A=craftingWorld();A.Crafting.Tick();local UI=A.CraftingUI
    UI.saleInputs.price:SetText("1e5");equal(UI.RecordCommission(),false);equal(#A.Ledger.Records(),0)
    UI.saleInputs.price:SetText("");UI.saleInputs.quantity:SetText("0");equal(UI.RecordCommission(),false)
    UI.saleInputs.quantity:SetText("1");w.combat=true;equal(UI.RecordCommission(),false);equal(#A.Ledger.Records(),0)
end)
test("blank optional tip and quantity fields use their defaults",function()
    local w,A=craftingWorld();A.Crafting.Tick();local UI=A.CraftingUI
    UI.saleInputs.tip:SetText("");UI.saleInputs.quantity:SetText("");truth(UI.RecordCommission())
    local r=A.Ledger.Records()[1];equal(r.tip,0);equal(r.quantity,1);equal(r.amount,400)
end)
test("ledger cost edits replace craft estimates with actual cost without losing the tip",function()
    local w,A=world();truth(A.Ledger.Commission({name="Craft",recipeID=1,cost=500,quote=1000},nil,100,2))
    A.EconomyUI.Show("ledger");local E=A.EconomyUI;E.LoadLedger(A.Ledger.Records()[1]);equal(E.ledgerInputs.cost.text,"")
    E.ledgerInputs.cost:SetText(".08");truth(E.RecordLedger());local r=A.Ledger.Records()[1]
    equal(r.cost,800);equal(r.estimatedCost,nil);equal(r.tip,100);equal(A.Ledger.Summary().profit,300)
end)
test("editing other commission details preserves the existing estimate if cost stays blank",function()
    local w,A=world();truth(A.Ledger.Commission({name="Craft",recipeID=1,cost=500,quote=1000},nil,100,2))
    A.EconomyUI.Show("ledger");local E=A.EconomyUI;E.LoadLedger(A.Ledger.Records()[1]);truth(E.RecordLedger())
    truth(A.Ledger.Records()[1].estimatedCost);equal(A.Ledger.Records()[1].cost,1000)
end)

test("local date validation handles leap years and rejects impossible dates",function()
    local w,A=world();local L=A.Ledger
    equal(L.DateDay("1970-01-01"),0);equal(L.DateDay("2026-10-20"),20746)
    truth(L.DateDay("2028-02-29"));equal(L.DateDay("2026-02-29"),nil);equal(L.DateDay("2026-04-31"),nil)
    equal(L.DateDay("2026-13-01"),nil);equal(L.Range("custom","2026-10-21","2026-10-20"),nil)
end)
test("transaction and local date filters affect rows reports and CSV together",function()
    local w,A=world();local L=A.Ledger
    truth(L.Record({kind="sale",name="Old sale",quantity=1,amount=1000,cost=400}));w:advance(8*86400)
    truth(L.Record({kind="vendor_buy",name="Supply",quantity=1,amount=100}));truth(L.Record({kind="commission",name="Craft",quantity=1,amount=500,tip=50,cost=100}))
    local range=L.Range("7d");equal(#L.View(range),2);equal(L.Summary(range).flow,450);equal(L.Summary(range).profit,450)
    range.kind="commission";equal(#L.View(range),1);equal(L.Summary(range).flow,550);equal(L.Summary(range).tips,50)
    local csv=L.CSV(range);truth(string.find(csv,"Craft",1,true));equal(string.find(csv,"Old sale",1,true),nil);equal(string.find(csv,"Supply",1,true),nil)
end)
test("custom dates include both full local days without changing saved timestamps",function()
    local w,A=world();w.wall=1800000000;truth(A.Ledger.Record({kind="sale",name="Sale",quantity=1,amount=1}))
    local r=A.Ledger.Records()[1];local day=date("%Y-%m-%d",r.time);local range=A.Ledger.Range("custom",day,day)
    equal(#A.Ledger.View(range),1);equal(A.Ledger.Records()[1].time,r.time)
end)
test("date report caches are stable between updates and refresh at the local day boundary",function()
    local w,A=world();truth(A.Ledger.Record({kind="sale",name="Sale",quantity=1,amount=1}))
    local a=A.Ledger.View(A.Ledger.Range("today"));w:advance(1);equal(A.Ledger.View(A.Ledger.Range("today")),a)
    w:advance(86400);equal(#A.Ledger.View(A.Ledger.Range("today")),0)
end)
test("ledger UI supports commission filters dates and filtered CSV without new auctions",function()
    local w,A=world();A.EconomyUI.Show("ledger");local E=A.EconomyUI
    E.filterButtons.sale.scripts.OnClick();equal(E.filterKind,"sale");E.filterButtons.buy.scripts.OnClick();equal(E.filterKind,"buy");E.filterButtons.commission.scripts.OnClick();equal(E.filterKind,"commission")
    E.dateFirst:SetText("2026-02-30");equal(E.ApplyDates(),false)
    E.dateFirst:SetText("2026-01-01");E.dateLast:SetText("2026-12-31");truth(E.ApplyDates());equal(E.period,"custom")
    E.CopyCSV();truth(E.csvFrame:IsShown());equal(w.requests,0)
end)
test("legacy expenses survive upgrade but new entries cycle through commissions and vendors",function()
    local w,A=world();truth(A.Ledger.Record({kind="expense",name="Old expense",quantity=1,amount=10}))
    A.EconomyUI.Show("ledger");local E=A.EconomyUI;E.NewManual()
    E.kindDropdown:OpenMenu();truth(E.kindDropdown:Pick("buy"));equal(E.kind,"buy");E.kindDropdown:OpenMenu();truth(E.kindDropdown:Pick("commission"));equal(E.kind,"commission")
    local rows=A.Ledger.View({kind="expense"});equal(#rows,1);equal(rows[1].name,"Old expense")
end)

test("Buy-page watch buttons capture item suffixes and open editable targets",function()
    local w,A=world();local ah=w:nativeSearch();ah.ItemBuyFrame.ItemDisplay=CreateFrame("Frame")
    ah.ItemBuyFrame.ItemDisplay.itemKey={itemID=100,itemSuffix=-7};ah:Show();A.EconomyUI.InstallBuyButtons()
    local b=A.EconomyUI.buyButtons[ah.ItemBuyFrame];truth(b);b.scripts.OnClick();local E=A.EconomyUI
    equal(E.mode,"watch");truth(string.find(E.watchInputs.item.text,":-7:",1,true));equal(E.watchInputs.roi.text,"0")
    E.watchInputs.itemPrice:SetText(".5");truth(E.SaveWatch());equal(A.Watchlist.Entries()[1].entry.maxBuy,5000)
end)
test("opening an existing buy-page watch preserves saved targets",function()
    local w,A=world();truth(A.Watchlist.Save(link(100,-7),1234,25,100))
    local ah=w:nativeSearch();ah.ItemBuyFrame.ItemDisplay=CreateFrame("Frame");ah.ItemBuyFrame.ItemDisplay.itemKey={itemID=100,itemSuffix=-7}
    A.EconomyUI.WatchFromBuy(ah.ItemBuyFrame,false);local E=A.EconomyUI
    equal(E.watchInputs.itemPrice.text,"0.1234");equal(E.watchInputs.roi.text,"25");equal(E.watchInputs.profit.text,"0.01")
end)
test("commodity Buy-page watches use item-wide keys and never start a market request",function()
    local w,A=world();local ah=w:nativeSearch();ah.CommoditiesBuyFrame.BuyDisplay={ItemDisplay=CreateFrame("Frame")}
    ah.CommoditiesBuyFrame.BuyDisplay.ItemDisplay.itemKey={itemID=100,itemSuffix=0}
    A.EconomyUI.InstallBuyButtons();A.EconomyUI.buyButtons[ah.CommoditiesBuyFrame].scripts.OnClick();truth(A.EconomyUI.SaveWatch())
    equal(A.Watchlist.Entries()[1].key,"100:*");equal(w.requests,0);equal(w.itemSearches,0)
end)
test("repeated Buy-page refreshes create one button per native header",function()
    local w,A=world();local ah=w:nativeSearch();ah.ItemBuyFrame.ItemDisplay=CreateFrame("Frame")
    A.EconomyUI.InstallBuyButtons();local button=A.EconomyUI.buyButtons[ah.ItemBuyFrame]
    local count=w.createdFrames;for _=1,10 do A.EconomyUI.InstallBuyButtons()end
    equal(A.EconomyUI.buyButtons[ah.ItemBuyFrame],button);equal(w.createdFrames,count)
end)
test("restricted Buy-page item keys cannot become watchlist entries",function()
    local w,A=world();local ah=w:nativeSearch();ah.ItemBuyFrame.ItemDisplay=CreateFrame("Frame")
    ah.ItemBuyFrame.ItemDisplay.itemKey={itemID=secret,itemSuffix=secret};A.EconomyUI.WatchFromBuy(ah.ItemBuyFrame,false)
    equal(#A.Watchlist.Entries(),0);equal(A.EconomyUI.frame,nil)
end)

test("identical automatic invoice rows can each receive their actual cost",function()
    local w,A=world();mail(w,{{},{}});drain(w,A);local rows=A.Ledger.Records();equal(#rows,2)
    local r=rows[1];truth(A.Ledger.Record({kind=r.kind,name=r.name,quantity=r.quantity,amount=r.amount,fee=r.fee,cost=4000},r.id))
    equal(A.Ledger.Summary().profit,6000);equal(A.Ledger.Summary().unknown,1)
    w:event("MAIL_INBOX_UPDATE");drain(w,A);equal(#A.Ledger.Records(),2)
end)
test("restricted invoice contents leave the automatic ledger untouched",function()
    local w,A=world();mail(w,{{amount=secret}});drain(w,A);equal(#A.Ledger.Records(),0)
end)
test("confirmation queue retries after ledger capacity is made available",function()
    local w,A=world();A.Ledger.limit=1;buy(w,A,42);buy(w,A,43);equal(#A.Ledger.Records(),1);equal(#A.Transactions.queue,1)
    A.Ledger.Remove(A.Ledger.Records()[1].id);w:tick(3);equal(#A.Ledger.Records(),1);equal(#A.Transactions.queue,0)
    equal(A.Ledger.Records()[1].autoKey,"ah:43")
end)
test("transaction diagnostics identify enabled observers buttons and queued records",function()
    local w,A=world();local text=A.UI.DiagnosticsText()
    truth(string.find(text,"Transaction tracking: AH=true; vendor=true",1,true));truth(string.find(text,"Purchase observers: item=true; commodity=true",1,true))
end)

test("a fast native mail collection is captured before the batched reader finishes",function()
    local w,A=world();TakeInboxMoney=function()w.nativeCollect=(w.nativeCollect or 0)+1 end;A.Transactions.Install()
    mail(w,{{amount=12345}});TakeInboxMoney(1);equal(#A.Ledger.Records(),1)
    w.mail={};w:event("MAIL_INBOX_UPDATE");drain(w,A);equal(#A.Ledger.Records(),1);equal(w.nativeCollect,1)
end)
test("rapid collection and a later inbox scan cannot duplicate the same invoice",function()
    local w,A=world();TakeInboxItem=function()end;A.Transactions.Install();mail(w,{{kind="buyer",amount=12345}})
    TakeInboxItem(1,1);equal(#A.Ledger.Records(),1);drain(w,A);equal(#A.Ledger.Records(),1)
end)
test("vendor buyback uses its observed whole-stack price",function()
    local w,A=world();GetNumBuybackItems=function()return 1 end
    GetBuybackItemInfo=function()return "Test item",1,150,3,-1,true end
    GetBuybackItemLink=function()return link(100)end
    w:event("MERCHANT_SHOW");BuybackItem(1);w:bag(100,3);w.wallet=w.wallet-150;w:event("BAG_UPDATE_DELAYED");w:tick()
    equal(#A.Ledger.Records(),1);equal(A.Ledger.Records()[1].amount,150);equal(A.Ledger.Records()[1].kind,"vendor_buy")
end)
test("ledger tracking work is idle away from merchants and mailboxes",function()
    local w,A=world();local calls=w.itemCalls or 0;local reads=w.containerReads or 0
    for _=1,100 do A.Transactions.Tick()end
    equal(w.itemCalls or 0,calls);equal(w.containerReads or 0,reads);equal(w.requests,0)
end)

test("fast collection preserves several identical invoice transactions",function()
    local w,A=world();TakeInboxMoney=function()end;A.Transactions.Install();mail(w,{{},{},{}})
    TakeInboxMoney(1);equal(#A.Ledger.Records(),3)
    table.remove(w.mail,1);w:event("MAIL_INBOX_UPDATE");TakeInboxMoney(1);equal(#A.Ledger.Records(),3)
    table.remove(w.mail,1);w:event("MAIL_INBOX_UPDATE");TakeInboxMoney(1);drain(w,A);equal(#A.Ledger.Records(),3)
end)
test("a merchant's buyback stock cannot replace its normal purchase price",function()
    local w,A=world();GetNumBuybackItems=function()return 1 end
    GetBuybackItemInfo=function()return "Test item",1,150,3,-1,true end;GetBuybackItemLink=function()return link(100)end
    w:event("MERCHANT_SHOW");BuyMerchantItem(1,5);w:bag(100,5);w.wallet=w.wallet-500;w:event("BAG_UPDATE_DELAYED");w:tick()
    equal(#A.Ledger.Records(),1);equal(A.Ledger.Records()[1].amount,500)
end)

test("queued confirmed transactions survive reload with their original timestamp",function()
    local w,A=world();A.Ledger.limit=1;buy(w,A,42);buy(w,A,43)
    equal(#A.Transactions.queue,1);local saved=A.DB.data;local stamp=A.Transactions.queue[1].input.time
    local w2,A2=fresh(saved);w2.wall=w.wall+100;w2:load();A2.Transactions.Tick()
    equal(#A2.Ledger.Records(),2);equal(#A2.Transactions.queue,0)
    local found=false;for _,r in ipairs(A2.Ledger.Records())do if r.autoKey=="ah:43"then found=true;equal(r.time,stamp)end end;truth(found)
end)
test("Buy-page watch actions reject a restricted suffix before formatting it",function()
    local w,A=world();local ah=w:nativeSearch();ah.ItemBuyFrame.ItemDisplay=CreateFrame("Frame")
    ah.ItemBuyFrame.ItemDisplay.itemKey={itemID=100,itemSuffix=secret}
    A.EconomyUI.WatchFromBuy(ah.ItemBuyFrame,false);equal(A.EconomyUI.frame,nil);equal(#A.Watchlist.Entries(),0)
end)
test("delayed confirmations still obey the selected local retention period",function()
    local w,A=world();A.DB.data.settings.ledgerDays=1
    truth(A.Ledger.Record({kind="buy",name="Delayed purchase",quantity=1,amount=100,source="AH purchase",autoKey="late",time=math.floor(w.wall)-86400},nil,true))
    equal(#A.Ledger.Records(),0)
end)
