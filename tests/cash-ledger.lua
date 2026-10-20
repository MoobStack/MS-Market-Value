local fresh,link,test,equal,truth,secret=...
local function world(saved,configure)
    local w,A=fresh(saved);w.realm="ClassicBetaPvP2";w.money=1000000;w.repair=0;w.calls=0;w.training={{name="Fireball",cost=120}};w.flight=77;w.postage=30
    GetMoney=function()return w.money end
    GetRepairAllCost=function()return w.repair,true end
    InRepairMode=function()return w.repairMode==true end
    function w:pay(amount)self.money=self.money-amount;self:event("PLAYER_MONEY")end
    RepairAllItems=function(guild)
        w.calls=w.calls+1
        if not w.fail then local cost=w.repair;w.repair=0;if not guild then w:pay(cost)end;w:event("MERCHANT_UPDATE")end
    end
    GetNumTrainerServices=function()return #w.training end
    GetTrainerServiceCost=function(i)return w.training[i].cost end
    GetTrainerServiceInfo=function(i)return w.training[i].name,"available"end
    BuyTrainerService=function(i)w.calls=w.calls+1;if not w.fail then w:pay(w.training[i].cost)end end
    ConfirmTalentWipeDialog_Show=function()end
    ConfirmTalentWipe=function()w.calls=w.calls+1;if not w.fail then w:pay(w.respec or 10000)end end
    NumTaxiNodes=function()return 1 end
    TaxiNodeCost=function()return w.flight end
    TaxiNodeName=function()return "Orgrimmar"end
    TakeTaxiNode=function()w.calls=w.calls+1;if not w.fail then w:event("TAXIMAP_CLOSED");w:pay(w.flight)end end
    GetSendMailPrice=function()return w.postage end
    SetSendMailMoney=function(amount)w.mailGold=amount end
    SendMail=function()w.calls=w.calls+1;if not w.fail then w:pay(w.postage+(w.mailGold or 0))end end
    PurchaseSlot=function()w.calls=w.calls+1;if not w.fail then w:pay(1000)end end
    BuyGuildBankTab=function()w.calls=w.calls+1;if not w.fail then w:pay(2000)end end
    DepositGuildBankMoney=function(amount)w.calls=w.calls+1;if not w.fail then w:pay(amount)end end
    C_StableInfo={BuyStableSlot=function()w.calls=w.calls+1;if not w.fail then w:pay(500)end end}
    GuildRegistrar_PurchaseCharter=function()w.calls=w.calls+1;if not w.fail then w:pay(100)end end
    GossipConfirmDialog_Show=function()end
    C_GossipInfo={SelectOption=function()w.calls=w.calls+1;if not w.fail then w:pay(70)end end}
    C_Container.GetContainerNumSlots=function()return 2 end
    NUM_BAG_SLOTS=0
    BuyMerchantItem=function(i,quantity)
        local item=w.vendorItems[i];local old=w.containers["0:1"];local count=(old and old.stackCount or 0)+(quantity or item.stackCount)
        w.containers["0:1"]={itemID=item.id,stackCount=count,hyperlink=link(item.id)}
        w:pay(item.price/item.stackCount*(quantity or item.stackCount));w:event("MERCHANT_UPDATE")
    end
    GOLD_AMOUNT,SILVER_AMOUNT,COPPER_AMOUNT="%d Gold","%d Silver","%d Copper"
    YOU_LOOT_MONEY,LOOT_MONEY_SPLIT="You loot %s.","Your share of the loot is %s."
    YOU_LOOT_MONEY_GUILD,LOOT_MONEY_SPLIT_GUILD="You loot %s. (%s deposited to guild bank)","Your share is %s. (%s deposited to guild bank)"
    if configure then configure(w,A)end
    w:load();A.auctionOpen=false
    function w:tick(seconds)self:advance(seconds or 3);A.Cash.Tick();A.Transactions.Tick()end
    function w:loot(amount)self:event("CHAT_MSG_MONEY","You loot "..amount..".")end
    return w,A,A.Cash,A.Ledger
end
local function expense(L,category,amount)
    local rows=L.View({kind="expense"});equal(#rows,1);equal(rows[1].category,category);equal(rows[1].amount,amount);return rows[1]
end
local function record(L,category,amount)
    truth(L.Record({kind="expense",category=category,name=category or"Old expense",quantity=1,amount=amount or 10}))
end

test("restored beta defaults enable loot and other spending independently",function()
    local w,A=world();equal(A.DB.Settings().trackLoot,true);equal(A.DB.Settings().trackOther,true);equal(A.TEST_REVISION,8)
end)
test("only the dedicated loot-money event creates loot income",function()
    local w,A,C,L=world();w:event("CHAT_MSG_SYSTEM","You loot 5 Silver.");w.money=w.money+500;w:event("PLAYER_MONEY");w:tick();equal(#L.Records(),0)
    w:loot("5 Silver");equal(#L.Records(),1);equal(L.Records()[1].amount,500)
end)
test("successive loot awards aggregate in one local daily row without receipts",function()
    local w,A,C,L=world();w:loot("1 Gold 2 Silver 3 Copper");local row=L.Records()[1];local id,stamp=row.id,row.time
    for _=1,100 do w:loot("1 Copper")end
    equal(#L.Records(),1);equal(L.Records()[1].amount,10303);equal(L.Records()[1].id,id);equal(L.Records()[1].time,stamp);equal(#L.Profile().receipts,0)
    equal(L.Summary().sales,10303);equal(L.Summary().spend,0);equal(L.Summary().unknown,0)
end)
test("a new loot award invalidates the cached daily total report",function()
    local w,A,C,L=world();w:loot("1 Silver");local old=L.Summary();equal(old.sales,100);w:loot("2 Silver");equal(L.Summary().sales,300);truth(L.Summary()~=old)
end)
test("loot day boundaries follow local midnight rather than UTC midnight",function()
    local w,A,C,L=world();w.wall=os.time({year=2026,month=10,day=20,hour=23,min=59,sec=59});w:loot("1 Silver");w:advance(2);w:loot("2 Silver")
    equal(#L.Records(),2);equal(L.Summary(L.Range("today")).sales,200)
end)
test("loot survives a reload and adds to the same day's existing row",function()
    local w,A,C,L=world();w:loot("1 Silver");local id=L.Records()[1].id
    local w2,A2,C2,L2=world(A.DB.data);w2:loot("2 Silver");equal(#L2.Records(),1);equal(L2.Records()[1].amount,300);equal(L2.Records()[1].id,id)
end)
test("loot profile is isolated by character and market",function()
    local w,A,C,L=world();w:loot("1 Silver");w.guid="Player-2";w:loot("2 Silver");equal(#L.Records(),1);equal(L.Records()[1].amount,200)
    w.guid="Player-1-fixture";equal(L.Records()[1].amount,100);w.faction="Alliance";equal(#L.Records(),0)
end)
test("local retention removes an old daily loot row and its cached day index",function()
    local w,A,C,L=world();A.DB.data.settings.ledgerDays=1;w:loot("1 Silver");w:advance(86400);w:loot("2 Silver");equal(#L.Records(),1);equal(L.Records()[1].amount,200)
end)
test("loot aggregation works automatically while in combat",function()
    local w,A,C,L=world();w.combat=true;w:loot("2 Silver");equal(L.Records()[1].amount,200)
end)
test("a full ledger queues and merges loot instead of one pending row per award",function()
    local w,A,C,L=world();L.limit=1;record(L,"misc");for _=1,25 do w:loot("1 Silver")end
    equal(#A.Transactions.queue,1);equal(A.Transactions.queue[1].input.amount,2500);truth(L.Remove(L.Records()[1].id));w:tick()
    equal(#A.Transactions.queue,0);equal(#L.Records(),1);equal(L.Records()[1].amount,2500)
end)
test("queued daily loot survives reload and retains its first local day",function()
    local w,A,C,L=world();L.limit=1;record(L,"misc");w:loot("1 Silver");w:loot("2 Silver");local stamp=A.Transactions.queue[1].input.time
    local w2,A2,C2,L2=world(A.DB.data);A2.Transactions.Tick();equal(#L2.Records(),2);equal(L2.View({kind="loot"})[1].amount,300);equal(L2.View({kind="loot"})[1].time,stamp)
end)
test("a disabled loot option leaves existing totals intact",function()
    local w,A,C,L=world();w:loot("1 Silver");A.DB.data.settings.trackLoot=false;w:loot("2 Silver");equal(L.Records()[1].amount,100)
end)
test("deleted daily loot can be undone before another award replaces it",function()
    local w,A,C,L=world();w:loot("1 Silver");truth(L.Remove(L.Records()[1].id));truth(L.Undo());w:loot("1 Silver");equal(#L.Records(),1);equal(L.Records()[1].amount,200)
end)
test("duplicate manual daily loot rows are rejected",function()
    local w,A,C,L=world();w:loot("1 Silver");equal(L.Record({kind="loot",lootDay=L.LocalDay(w.wall),name="Duplicate",quantity=1,amount=100}),false)
end)
for _,case in ipairs({{"1 Gold 2 Silver 3 Copper",10203},{"1,234 Gold",12340000},{"9 Copper",9},{"|cffffffff2 Silver|r",200},{"3 |TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t",300}})do
    test("native coin parser accepts "..case[1],function()local w,A,C=world();equal(C.ParseCoins(case[1]),case[2])end)
end
for _,text in ipairs({"5 Silver unknown", "0 Copper", "-5 Gold", "1 Gold 1 Gold", "", "a Gold"})do
    test("native coin parser refuses ambiguous value: "..text,function()local w,A,C,L=world();equal(C.ParseCoins(text),nil);w:loot(text);equal(#L.Records(),0)end)
end
test("restricted loot text and wallet values are never inspected",function()
    local w,A,C,L=world();w:event("CHAT_MSG_MONEY",secret);w.money=secret;w:event("PLAYER_MONEY");w.money=900000;w:event("PLAYER_MONEY");w:tick();equal(#L.Records(),0)
end)
test("localized positional guild loot uses only the player's first money argument",function()
    local w,A,C,L=world();YOU_LOOT_MONEY=nil;GOLD_AMOUNT,SILVER_AMOUNT,COPPER_AMOUNT="%d Or","%d Argent","%d Cuivre"
    LOOT_MONEY_SPLIT_GUILD="Guilde %2$s, votre part %1$s.";w:event("CHAT_MSG_MONEY","Guilde 8 Argent, votre part 2 Argent.")
    equal(L.Records()[1].amount,200)
end)
test("guild bank loot deposits are not added to the player's income",function()
    local w,A,C,L=world();w:event("CHAT_MSG_MONEY","You loot 2 Silver. (5 Silver deposited to guild bank)");equal(L.Records()[1].amount,200)
end)
test("repair all records the paid personal amount once despite duplicate update events",function()
    local w,A,C,L=world();w.repair=300;w:event("MERCHANT_SHOW");RepairAllItems();w:event("MERCHANT_UPDATE");w:tick();expense(L,"repair",300);equal(w.calls,1)
end)
test("guild-funded repairs do not become personal expenses",function()
    local w,A,C,L=world();w.repair=300;w:event("MERCHANT_SHOW");RepairAllItems(true);w:tick();equal(#L.Records(),0)
end)
test("failed repair attempts create no entry",function()
    local w,A,C,L=world();w.repair=300;w:event("MERCHANT_SHOW");w.fail=true;RepairAllItems();w:tick();equal(#L.Records(),0)
end)
test("individual repair cursor actions use the actual repair-cost drop",function()
    local w,A,C,L=world();w.repair=500;w:event("MERCHANT_SHOW");w.repairMode=true;w.repair=420;w:pay(80);w:event("MERCHANT_UPDATE");w:tick();expense(L,"repair",80)
end)
test("two identical individual repair costs are separate paid actions",function()
    local w,A,C,L=world();w.repair=500;w:event("MERCHANT_SHOW");w.repairMode=true
    for _=1,2 do w.repair=w.repair-80;w:pay(80);w:event("MERCHANT_UPDATE");w:advance(.05)end
    w:tick();equal(#L.Records(),2);equal(L.Summary().spend,160)
end)
test("repair mode alone cannot label an unrelated wallet deduction as repairs",function()
    local w,A,C,L=world();w.repair=500;w:event("MERCHANT_SHOW");w.repairMode=true;w:pay(80);w:tick();expense(L,"unclassified",80)
end)
test("vendor purchase plus repairs in one interval both reconcile without duplication",function()
    local w,A,C,L=world();w.items[100]={name="Thread",vendor=10};w.vendorItems={{id=100,price=100,stackCount=1,hasExtendedCost=false}}
    w.repair=30;w:event("MERCHANT_SHOW");BuyMerchantItem(1,1);RepairAllItems();w:tick(1);w:tick(3)
    equal(#L.Records(),2);equal(L.Summary().spend,130);equal(#L.View({kind="vendor_buy"}),1);expense(L,"repair",30)
end)
test("training expense includes the selected service name and actual price",function()
    local w,A,C,L=world();w:event("TRAINER_SHOW");BuyTrainerService(1);w:tick();local row=expense(L,"training",120);truth(row.name:find("Fireball",1,true));equal(w.calls,1)
end)
test("failed training and free training do not create gold expenses",function()
    local w,A,C,L=world();w:event("TRAINER_SHOW");w.fail=true;BuyTrainerService(1);w:tick();equal(#L.Records(),0)
    w.fail=false;w.training[1].cost=0;w:event("TRAINER_UPDATE");BuyTrainerService(1);w:tick();equal(#L.Records(),0)
end)
test("talent-reset dialog cancellation does not create an expense",function()
    local w,A,C,L=world();ConfirmTalentWipeDialog_Show(10000);w:tick();equal(#L.Records(),0)
end)
test("confirmed talent resets require a wallet deduction",function()
    local w,A,C,L=world();ConfirmTalentWipeDialog_Show(10000);ConfirmTalentWipe();w:tick();expense(L,"respec",10000)
end)
test("flight is classified even when the map closes before the wallet event",function()
    local w,A,C,L=world();w:event("TAXIMAP_OPENED");TakeTaxiNode(1);w:tick();local row=expense(L,"flight",77);truth(row.name:find("Orgrimmar",1,true))
end)
test("successful mail separates postage from mailed gold",function()
    local w,A,C,L=world();w:event("MAIL_SHOW");SetSendMailMoney(1000);SendMail();w:event("MAIL_SEND_SUCCESS");w:tick()
    equal(#L.Records(),2);equal(L.Summary().byCategory.postage,30);equal(L.Summary().byCategory.mail_gold,1000);equal(L.Summary().spend,1030)
end)
test("mail draft changes and a failed send create no postage entry",function()
    local w,A,C,L=world();w:event("MAIL_SHOW");SetSendMailMoney(1000);w.fail=true;SendMail();w:event("MAIL_FAILED");w:tick();equal(#L.Records(),0)
end)
test("mail success before delayed money updates still uses the frozen send totals",function()
    local w,A,C,L=world();w:event("MAIL_SHOW");SetSendMailMoney(0);w.fail=true;SendMail();w:event("MAIL_SEND_SUCCESS");w:event("MAIL_CLOSED");w:pay(30);w:tick();expense(L,"postage",30)
end)
test("unrecognized outgoing mail costs are retained as unclassified spending",function()
    local w,A,C,L=world();w:event("MAIL_SHOW");w:pay(500);w:tick();expense(L,"unclassified",500)
end)
for _,case in ipairs({{"bank slot",function()PurchaseSlot()end,"bank",1000},{"guild bank tab",function()BuyGuildBankTab()end,"bank",2000},{"guild deposit",function()DepositGuildBankMoney(300)end,"bank",300},{"stable slot",function()C_StableInfo.BuyStableSlot()end,"services",500},{"charter",function()GuildRegistrar_PurchaseCharter()end,"services",100}})do
    test("native "..case[1].." is observed as paid spending",function()local w,A,C,L=world();case[2]();w:tick();expense(L,case[3],case[4]);equal(w.calls,1)end)
end
test("confirmed gossip services use their native quoted cost",function()
    local w,A,C,L=world();GossipConfirmDialog_Show(12,"Service",70);C_GossipInfo.SelectOption(12,nil,true);w:tick();expense(L,"services",70)
end)
test("other wallet expenditures remain visible as unclassified and can be edited",function()
    local w,A,C,L=world();w:pay(45);w:tick();local row=expense(L,"unclassified",45);truth(L.Record({kind="expense",category="misc",name="Travel supplies",amount=45,quantity=1},row.id));equal(L.Records()[1].category,"misc")
end)
test("unclassified spending is kept out of AH escrow and player trades",function()
    local w,A,C,L=world();A.auctionOpen=true;w:pay(100);w:tick();A.auctionOpen=false;w:event("TRADE_SHOW");w:pay(200);w:tick();equal(#L.Records(),0)
end)
test("confirmed vendor purchases claim their wallet deduction exactly once",function()
    local w,A,C,L=world();w.items[100]={name="Thread",vendor=10};w.vendorItems={{id=100,price=100,stackCount=1,hasExtendedCost=false}}
    w:event("MERCHANT_SHOW");BuyMerchantItem(1,1);w:tick(1);w:tick(3);equal(#L.Records(),1);equal(L.Records()[1].kind,"vendor_buy");equal(L.Summary().spend,100)
end)
test("disabled other spending does not reclassify wallet deductions",function()
    local w,A,C,L=world();A.DB.data.settings.trackOther=false;w:pay(100);w:tick();equal(#L.Records(),0);w:loot("1 Silver");equal(#L.Records(),1)
end)
test("disabled vendor tracking is not bypassed by the other-spending fallback",function()
    local w,A,C,L=world();A.DB.data.settings.trackVendor=false;w:event("MERCHANT_SHOW");w:pay(100);w:tick();equal(#L.Records(),0)
end)
test("automatic other expenses are saved in combat and retain their event timestamp",function()
    local w,A,C,L=world();w.combat=true;w:pay(100);local stamp=math.floor(w.wall);w:tick();equal(L.Records()[1].time,stamp);equal(L.Records()[1].amount,100)
end)
test("queued other expenses preserve category through reload",function()
    local w,A,C,L=world();L.limit=1;record(L,"misc");w:pay(100);w:tick();equal(#A.Transactions.queue,1)
    local w2,A2,C2,L2=world(A.DB.data);A2.Transactions.Tick();equal(L2.Summary().byCategory.unclassified,100)
end)
test("stale unsuccessful intents expire even when no money changed",function()
    local w,A,C,L=world();w.fail=true;for _=1,100 do PurchaseSlot()end;equal(#C.intents,100);w:tick(11);equal(#C.intents,0);w.fail=false;PurchaseSlot();w:tick();expense(L,"bank",1000)
end)
test("restricted expense quotes never cause arithmetic on restricted values",function()
    local w,A,C,L=world();ConfirmTalentWipeDialog_Show(secret);w.repair=secret;w:event("MERCHANT_SHOW");w:pay(20);w:tick();expense(L,"unclassified",20)
end)
test("another character's pending wallet context cannot be attributed to this character",function()
    local w,A,C,L=world();w:pay(100);w.guid="Other-player";w:tick();equal(#L.Records(),0)
end)

local function ui()
    local w,A,C,L=world();A.EconomyUI.Show("ledger");return w,A,A.EconomyUI,L
end
test("Other displays all expense categories including legacy rows initially",function()
    local w,A,E,L=ui();record(L,"repair",100);record(L,"training",200);record(L,nil,300);E.SetFilter("expense")
    equal(#L.View(E.CurrentFilter()),3);truth(E.otherDropdown:IsShown());equal(E.otherDropdown.text,"All other expenses")
end)
test("Other checkboxes immediately combine selected categories and stay open",function()
    local w,A,E,L=ui();record(L,"repair",100);record(L,"training",200);record(L,"flight",300);E.SetFilter("expense");E.otherDropdown:OpenMenu();E.otherDropdown:Pick("none");E.otherDropdown:OpenMenu()
    truth(E.otherDropdown:Pick("repair"));truth(E.otherDropdown:IsMenuOpen());equal(#L.View(E.CurrentFilter()),1)
    E.otherDropdown:Pick("training");equal(#L.View(E.CurrentFilter()),2);equal(E.ledgerRows[1].row.category,"training");equal(w.mono,0)
end)
test("changing a filter deactivates Other while All includes every category and loot",function()
    local w,A,E,L=ui();record(L,"repair",100);record(L,"training",200);w:loot("1 Silver");E.SetFilter("expense");E.SelectOther("none");E.SelectOther("repair")
    E.SetFilter("loot");equal(#L.View(E.CurrentFilter()),1);equal(E.otherDropdown:IsShown(),false);E.SetFilter("all");equal(#L.View(E.CurrentFilter()),3)
end)
test("the Other menu remains stable during periodic refresh and closes when leaving",function()
    local w,A,E,L=ui();E.SetFilter("expense");E.otherDropdown:OpenMenu();local builds=E.otherDropdown.menuBuilds
    for _=1,10 do E.Refresh()end;equal(E.otherDropdown.menuBuilds,builds);truth(E.otherDropdown:IsMenuOpen());E.SetLedgerView("report");equal(E.otherDropdown:IsMenuOpen(),false)
end)
test("category filtering caches equivalent masks but responds immediately to changes",function()
    local w,A,E,L=ui();record(L,"repair");record(L,"training");local mask={repair=true};local filter={kind="expense",categories=mask};local first=L.View(filter)
    equal(L.View({kind="expense",categories={repair=true}}),first);mask.training=true;equal(#L.View(filter),2);truth(L.View(filter)~=first)
end)
test("Other categories do not narrow the whole-period report or All CSV",function()
    local w,A,E,L=ui();record(L,"repair",100);record(L,"flight",200);E.SetFilter("expense");E.SelectOther("none");E.SelectOther("repair");E.SetLedgerView("report")
    equal(E.report.spend.text,"3s 00c");E.SetFilter("all");equal(#L.View(E.CurrentFilter()),2)
end)
test("filtered CSV names expense categories and excludes unchecked ones",function()
    local w,A,E,L=ui();record(L,"repair",100);record(L,"flight",200);E.SetFilter("expense");E.SelectOther("none");E.SelectOther("repair");local csv=L.CSV(E.CurrentFilter())
    truth(csv:find('CostBasis,Category',1,true));truth(csv:find('"repair"',1,true));equal(csv:find('"flight"',1,true),nil)
end)
test("the native transaction editor supports new Other entries and category selection",function()
    local w,A,E,L=ui();E.OpenEditor();E.kindDropdown:OpenMenu();truth(E.kindDropdown:Pick("expense"));truth(E.categoryDropdown:IsShown());equal(E.importInvoiceButton:IsShown(),false)
    E.categoryDropdown:OpenMenu();truth(E.categoryDropdown:Pick("repair"));E.ledgerInputs.name:SetText("Armor repairs");E.ledgerInputs.amount:SetText("0.5");truth(E.RecordLedger());expense(L,"repair",5000)
end)
test("editing an expense as an AH purchase clears its category",function()
    local w,A,E,L=ui();record(L,"repair",100);E.LoadLedger(L.Records()[1]);E.SetKind("buy");truth(E.RecordLedger());equal(L.Records()[1].kind,"buy");equal(L.Records()[1].category,nil)
end)
test("daily loot rows display a total date and their report total has a direct filter",function()
    local w,A,E,L=ui();w:loot("1 Silver");E.Refresh();equal(E.activityRows.loot.value.text,"1s 00c");E.activityRows.loot.scripts.OnClick();equal(E.filterKind,"loot");truth(E.ledgerRows[1].labels[1].text:find("total",1,true))
end)
test("daily loot edits retain their day and future awards still aggregate",function()
    local w,A,E,L=ui();w:loot("1 Silver");E.LoadLedger(L.Records()[1]);E.ledgerInputs.amount:SetText("0.02");truth(E.RecordLedger());w:loot("1 Silver");equal(#L.Records(),1);equal(L.Records()[1].amount,300)
end)
test("unknown categories and restricted category edits are rejected",function()
    local w,A,E,L=ui();equal(L.Record({kind="expense",category="invalid",name="bad",quantity=1,amount=100}),false)
    equal(L.Record({kind="expense",category=secret,name="bad",quantity=1,amount=100}),false);equal(#L.Records(),0)
end)
test("old expense rows retain their readable legacy category after upgrade",function()
    local w,A,E,L=ui();record(L,nil,100);local w2,A2,C2,L2=world(A.DB.data);equal(L2.Category(L2.Records()[1]),"legacy");equal(L2.Summary().spend,100)
end)
test("loot and other controls are independent and diagnostic totals are available",function()
    local w,A,E,L=ui();E.SetLedgerView("options");E.autoOther:SetChecked(false);E.autoOther.scripts.OnClick(E.autoOther);equal(A.DB.Settings().trackOther,false);equal(A.DB.Settings().trackLoot,true)
    local text=A.UI.DiagnosticsText();truth(text:find("Cash tracking: loot=true; other=false;",1,true));equal(w.calls,0)
end)

test("a combined vendor sale and repairs record both even when the wallet rises",function()
    local w,A,C,L=world();w.items[100]={name="Cloth",vendor=100};w.containers["0:1"]={itemID=100,stackCount=1,hyperlink=link(100)}
    w.repair=30;w:event("MERCHANT_SHOW");A.Transactions.VendorIntent();w.containers["0:1"]=nil;w.repair=0;w.money=w.money+70
    w:event("PLAYER_MONEY");C.repairAttempt=w.mono;w:event("MERCHANT_UPDATE");w:tick(1);w:tick(3)
    equal(#L.Records(),2);equal(L.Summary().sales,100);equal(L.Summary().spend,30);equal(L.Summary().flow,70);expense(L,"repair",30)
end)
test("guild repairs while the repair cursor is active cannot consume a vendor buy",function()
    local w,A,C,L=world();w.items[100]={name="Thread",vendor=10};w.vendorItems={{id=100,price=100,stackCount=1,hasExtendedCost=false}}
    w.repair=100;w.repairMode=true;w:event("MERCHANT_SHOW");BuyMerchantItem(1,1);RepairAllItems(true);w:tick(1);w:tick(3)
    equal(#L.Records(),1);equal(L.Records()[1].kind,"vendor_buy");equal(L.Summary().spend,100)
end)
test("cash observation uses a short AH-close grace period for delayed purchase money",function()
    local w,A,C,L=world();A.auctionOpen=true;w:event("AUCTION_HOUSE_CLOSED");w:pay(100);w:tick();equal(#L.Records(),0)
    w:pay(200);w:tick();expense(L,"unclassified",200)
end)


test("turning off loot tracking does not discard a pending expense",function()
    local w,A,E,L=ui();w:pay(100);E.SetLedgerView("options");E.autoLoot:SetChecked(false);E.autoLoot.scripts.OnClick(E.autoLoot);w:tick()
    expense(L,"unclassified",100);equal(A.DB.Settings().trackLoot,false);equal(A.DB.Settings().trackOther,true)
end)
