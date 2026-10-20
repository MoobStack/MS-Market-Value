local _, A = ...
local U,D,W,L = A.Util,A.DB,A.Watchlist,A.Ledger
local E = { mode = "watch", watchPage = 1, ledgerPage = 1, kind = "sale", messages = {} }
A.EconomyUI = E
local kinds, titles = {"sale","buy","commission","vendor_sale","vendor_buy","tip_received","tip_given","expense"}, {sale="AH sale",buy="AH buy",commission="Commission",vendor_sale="Vendor sale",vendor_buy="Vendor buy",tip_received="Tip received",tip_given="Tip given",expense="Other spending",loot="Loot"}
local function Label(parent,text,x,y,width,right)
    local f=parent:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);f:SetSize(width,16);f:SetWordWrap(false)
    f:SetJustifyH(right and "RIGHT" or "LEFT");f:SetText(text);return f
end
local function Button(parent,text,x,y,width,fn)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);b:SetSize(width,25);b:SetText(text);b:SetScript("OnClick",fn);return b
end
local function Inset(parent,y,height)
    local f=CreateFrame("Frame",nil,parent,"InsetFrameTemplate")
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",12,y);f:SetSize(766,height);return f
end
local function Box(parent,x,y,width,numeric)
    local b=CreateFrame("EditBox",nil,parent,"InputBoxTemplate")
    b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);b:SetSize(width,24);b:SetAutoFocus(false);b:SetNumeric(numeric==true);b:SetMaxLetters(512)
    b:SetScript("OnEscapePressed",function(self)self:ClearFocus()end);return b
end
local function Message(text)
    E.messages[E.mode]=text;E.Refresh();return false
end
local function Signed(v)return A.CraftingUI.SignedMoney(v)end
local function Visible(frame,shown)
    if frame:IsShown()~=shown then if shown then frame:Show()else frame:Hide()end end
end
local function TableRows(parent,columns,count,step,click,enter)
    local result={}
    for _,col in ipairs(columns)do Label(parent,col[1],col[2]+10,-8,col[3],col[4]):SetFontObject("GameFontNormalSmall")end
    for index=1,count do
        local b=CreateFrame("Button",nil,parent)
        b:SetPoint("TOPLEFT",parent,"TOPLEFT",10,-31-(index-1)*step);b:SetSize(746,step-1)
        local bg=b:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints(b);bg:SetColorTexture(.12,.13,.15,index%2==0 and .5 or .15)
        b.labels={};for n,col in ipairs(columns)do b.labels[n]=Label(b,"",col[2],-5,col[3],col[4])end
        b:SetScript("OnClick",function(self)if self.row then click(self.row)end end)
        b:SetScript("OnEnter",function(self)if self.row and enter then enter(self,self.row)end end)
        b:SetScript("OnLeave",function()if GameTooltip then GameTooltip:Hide()end end)
        result[index]=b
    end
    return result
end

function E.SaveWatch()
    local v=E.watchInputs
    local buy,roi,profit=U.ParseGold(v.itemPrice:GetText()),tonumber(v.roi:GetText()),U.ParseGold(v.profit:GetText())
    local ok,why=W.Save(v.item:GetText(),buy,roi,profit)
    if not ok then return Message(why)end
    E.selectedWatch=why;E.messages.watch="Watch saved. All enabled targets must be met.";W.Ensure();E.Refresh();return true
end
function E.SelectWatch(row)
    E.selectedWatch=row.key
    E.watchItemLabel:SetText(row.name)
    local v=E.watchInputs
    v.item:SetText(row.suffix~=nil and row.link or tostring(row.id))
    v.itemPrice:SetText(U.GoldText(row.watch.maxBuy));v.roi:SetText(tostring(row.watch.minReturn));v.profit:SetText(U.GoldText(row.watch.minProfit))
    E.Refresh()
end
function E.WatchDraft(row,source)
    if not row or U.Combat() then return end
    E.Show("watch")
    local key=row.id..":"..(row.suffix~=nil and row.suffix or "*")
    local existing
    for _,watch in ipairs(W.Entries())do if watch.key==key then existing=watch.entry;break end end
    E.watchInputs.item:SetText(row.suffix~=nil and row.link or tostring(row.id))
    E.watchItemLabel:SetText(row.name or ("Selected item "..row.id))
    E.watchInputs.itemPrice:SetText(U.GoldText(existing and existing.maxBuy or math.min(100000000,math.floor(row.maxBuy or row.buy or 0))))
    E.watchInputs.roi:SetText(tostring(existing and existing.minReturn or(source=="buy"and 0 or D.Settings().marketMinReturn)))
    E.watchInputs.profit:SetText(U.GoldText(existing and existing.minProfit or(source=="buy"and 0 or D.Settings().marketMinProfit)))
    E.selectedWatch=existing and key or nil
    E.messages.watch=existing and"Edit this item's saved targets, then Save watch."or"Item selected. Set your targets and click Save watch.";E.Refresh()
end

function E.WatchFromBuy(frame,commodity)
    if U.Combat()or not A.auctionOpen or not U.Table(frame)then return end
    local display=commodity and U.Table(frame.BuyDisplay)and frame.BuyDisplay.ItemDisplay or frame.ItemDisplay
    local key=U.Table(display)and display.itemKey or frame.itemKey
    if U.Table(display)and type(display.GetItemKey)=="function"then
        local ok,value=pcall(display.GetItemKey,display);if ok and U.Table(value)then key=value end
    end
    local id
    if U.Table(key)then id=key.itemID end
    if not U.Number(id,1,2147483647,true)and commodity and type(frame.GetItemID)=="function"then
        local ok,value=pcall(frame.GetItemID,frame);if ok then id=value end
    end
    if not U.Number(id,1,2147483647,true)then return U.Print("Choose an item on the Buy page first.")end
    local suffix
    if not commodity and U.Table(key)then suffix=key.itemSuffix end
    if not U.Accessible(suffix)then return end
    if suffix~=nil and not U.Number(suffix,-2147483647,2147483647,true)then return end
    local itemLink="item:"..id..":0:0:0:0:0:"..(suffix or 0)..":0"
    local item=A.Valuation.ItemInfo(itemLink)
    local displayLink=item and item.link or itemLink
    local price=D.Price(id,itemLink)
    E.WatchDraft({id=id,suffix=suffix,link=displayLink,name=item and item.name or ("Selected item "..id),buy=price and price.low},"buy")
end
function E.InstallBuyButtons()
    if U.Combat()or not U.Table(AuctionHouseFrame)then return end
    E.buyButtons=E.buyButtons or{}
    for _,definition in ipairs({{"ItemBuyFrame",false},{"CommoditiesBuyFrame",true}})do
        local native=AuctionHouseFrame[definition[1]]
        if U.Table(native)and not E.buyButtons[native]then
            local commodity=definition[2]
            local display=commodity and U.Table(native.BuyDisplay)and native.BuyDisplay.ItemDisplay or native.ItemDisplay
            if U.Table(display)then
                local b=CreateFrame("Button",nil,display,"UIPanelButtonTemplate")
                b:SetSize(108,22);b:SetPoint("BOTTOMRIGHT",display,"BOTTOMRIGHT",-8,5);b:SetText("Watch item")
                b:SetScript("OnClick",function()E.WatchFromBuy(native,commodity)end)
                b:SetScript("OnEnter",function(self)if GameTooltip then GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:AddLine("Add this item or edit its watchlist targets.");GameTooltip:Show()end end)
                b:SetScript("OnLeave",function()if GameTooltip then GameTooltip:Hide()end end)
                b:Show();E.buyButtons[native]=b
            end
        end
    end
end
function E.ViewWatch()
    for _,row in ipairs(W.rows)do if row.key==E.selectedWatch then
        if A.MarketUI.OpenListings(row,"watch")then E.frame:Hide()else Message(A.MarketUI.message)end;return
    end end
    Message("Select a current watchlist row first.")
end

function E.SyncKind()
    if E.kindDropdown then E.kindDropdown:GenerateMenu()end
    if E.categoryDropdown then E.categoryDropdown:GenerateMenu()end
end
function E.SetKind(kind)
    if U.Combat()or not titles[kind]then return end
    E.kind=kind;E.kindDropdown:Update();E.Refresh()
end
function E.NewManual()
    E.entryID,E.invoiceDraft,E.ledgerItemID,E.originalRow=nil,nil,nil,nil;E.kind="sale";E.expenseCategory="misc"
    if not E.ledgerInputs then return end
    local v=E.ledgerInputs
    E.SyncKind();v.name:SetText("");v.quantity:SetText("1");v.amount:SetText("");v.fee:SetText("0");v.tip:SetText("0");v.cost:SetText("")
    E.messages.ledger="Select a transaction to edit it, or choose New entry."
end
function E.LoadLedger(row)
    E.entryID,E.kind,E.ledgerItemID,E.originalRow=row.id,row.kind,row.itemID,row
    E.invoiceDraft=row.invoiceKey and row or nil;E.expenseCategory=L.Category(row)or"misc"
    local v=E.ledgerInputs;E.SyncKind();v.name:SetText(row.name);v.quantity:SetText(tostring(row.quantity))
    v.amount:SetText(U.GoldText(row.amount));v.fee:SetText(U.GoldText(row.fee));v.tip:SetText(U.GoldText(row.tip or 0));v.cost:SetText(row.cost~=nil and not row.estimatedCost and U.GoldText(row.cost)or"")
    E.ledgerView="transactions";E.editorFrame:Show()
    E.messages.ledger="Editing entry "..row.id..". "..(row.estimatedCost and "Cost is a craft estimate; enter an actual cost to replace it." or "Record entry saves the changes.");E.Refresh()
end
function E.ImportInvoice()
    local row,why=L.ReadOpenInvoice()
    if not row then return Message(why)end
    E.NewManual();E.kind,E.invoiceDraft,E.ledgerItemID=row.kind,row,row.itemID
    local v=E.ledgerInputs;E.SyncKind();v.name:SetText(row.name);v.quantity:SetText(tostring(row.quantity))
    v.amount:SetText(U.GoldText(row.amount));v.fee:SetText(U.GoldText(row.fee))
    E.editorFrame:Show()
    E.messages.ledger="Invoice preview. Enter actual cost if known, then Record entry. Deposit refunds are excluded from profit.";E.Refresh();return true
end
function E.RecordLedger()
    local v=E.ledgerInputs
    local tip=0
    if L.Income(E.kind)then tip=U.ParseGold(v.tip:GetText(),1000000000000)end
    local input={kind=E.kind,name=v.name:GetText(),quantity=tonumber(v.quantity:GetText()),amount=U.ParseGold(v.amount:GetText(),1000000000000),
        fee=U.ParseGold(v.fee:GetText(),1000000000000),tip=tip,itemID=E.ledgerItemID,category=E.kind=="expense"and E.expenseCategory or nil,
        lootDay=E.kind=="loot"and E.originalRow and E.originalRow.lootDay or nil}
    local cost=v.cost:GetText()
    if cost=="" and E.originalRow and E.originalRow.estimatedCost then input.cost=E.originalRow.cost;input.estimatedCost=true end
    if cost~="" then input.cost=U.ParseGold(cost,1000000000000);if input.cost==nil then return Message("Enter a valid cost, or leave cost blank if unknown.")end end
    if input.fee==nil or input.tip==nil then return Message("Enter valid fees and a total tip (0 is allowed).")end
    if E.originalRow then input.recipeID=E.originalRow.recipeID end
    local invoice=E.invoiceDraft
    if invoice and invoice.kind==input.kind and invoice.name==input.name and invoice.quantity==input.quantity and invoice.amount==input.amount and invoice.fee==input.fee then
        input.invoiceKey,input.invoiceExpiry,input.refund=invoice.invoiceKey,invoice.invoiceExpiry,invoice.refund
    end
    local ok,why=L.Record(input,E.entryID)
    if not ok then return Message(why)end
    E.NewManual();E.editorFrame:Hide();E.messages.ledger="Entry recorded. Balances cover retained records only.";E.ledgerPage=1;E.Refresh();return true
end
function E.ApplyRetention()
    local days=tonumber(E.retention:GetText())
    if U.Combat()or not U.Number(days,1,365,true)then return Message("Choose ledger retention from 1 to 365 days.")end
    D.data.settings.ledgerDays=days;L.maintained=nil;L.Maintain();E.messages.ledger="Retention saved; older ledger entries removed.";E.Refresh();return true
end
function E.CopyCSV()
    if U.Combat()then return end
    if not E.csvFrame then
        local f=CreateFrame("Frame","MSMarketValueLedgerCSV",UIParent,"PortraitFrameTemplate")
        f:SetSize(740,530);f:SetPoint("CENTER",UIParent,"CENTER",0,0);f:SetFrameStrata("DIALOG");f:SetClampedToScreen(true)
        f:SetTitle("MS Market Value - Ledger CSV");f.CloseButton:SetScript("OnClick",function()f:Hide()end)
        Label(f,"Ctrl+C to copy. Amounts are whole copper; a blank profit means cost is unknown.",20,-40,700)
        local scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT",f,"TOPLEFT",20,-70);scroll:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-35,20)
        local box=CreateFrame("EditBox",nil,scroll);box:SetMultiLine(true);box:SetAutoFocus(false);box:SetFontObject("GameFontHighlightSmall")
        box:SetSize(670,420);box:SetMaxLetters(10000000);scroll:SetScrollChild(box)
        box:SetScript("OnEscapePressed",function()f:Hide()end);E.csvFrame,E.csvBox=f,box
        table.insert(UISpecialFrames,"MSMarketValueLedgerCSV")
    end
    E.csvBox:SetText(L.CSV(E.CurrentFilter()));E.csvFrame:Show();E.csvBox:SetFocus();E.csvBox:HighlightText()
end

function E.PeriodFilter()
    local range=L.Range(E.period or "30d",E.appliedFirst,E.appliedLast)
    return range or {first=0,last=0}
end
function E.CurrentFilter()
    local range=E.PeriodFilter();range.kind=E.ledgerView=="transactions"and(E.filterKind or"all")or"all"
    if range.kind=="expense"then range.categories=E.otherCategories end
    return range
end
function E.ApplyDates()
    local range,why=L.Range("custom",E.dateFirst:GetText(),E.dateLast:GetText())
    if not range then return Message(why)end
    E.appliedFirst,E.appliedLast=E.dateFirst:GetText(),E.dateLast:GetText();E.period="custom";E.ledgerPage=1
    E.messages.ledger="Showing the selected local dates. Reports and CSV use these filters.";E.Refresh();return true
end

local periods={{"today","Today",78},{"7d","7 days",78},{"30d","30 days",86},{"all","All retained",108},{"custom","Custom",86}}
local filters={{"all","All",62},{"buy","AH purchases",124},{"sale","AH sales",96},{"vendor_buy","Vendor purchases",150},{"vendor_sale","Vendor sales",124},{"commission","Commissions",142},{"tip_received","Tips received",128},{"tip_given","Tips given",116},{"loot","Loot",84},{"expense","Other",84}}
local LEDGER_ROWS=8
local function Count(n)return n..(n==1 and " entry"or" entries")end
local function Accent(label,value)
    label:SetTextColor(value<0 and 1 or .35,value<0 and .38 or .87,.38)
end
function E.SetLedgerView(view)
    if U.Combat()or(view~="report"and view~="transactions"and view~="options")then return end
    E.ledgerView=view
    if E.editorFrame then E.editorFrame:Hide()end
    E.Refresh()
end
function E.SetFilter(kind)
    if U.Combat()or(kind~="all"and not titles[kind])then return end
    E.filterKind,E.ledgerPage,E.ledgerView=kind,1,"transactions"
    if kind~="expense"and E.otherDropdown then E.otherDropdown:CloseMenu()end
    E.Refresh()
end
function E.SelectOther(category)
    if U.Combat()then return end
    E.otherCategories=E.otherCategories or{}
    if category=="all"or category=="none"then
        for _,entry in ipairs(L.expenseCategories)do E.otherCategories[entry[1]]=category=="all"end
    elseif L.categoryTitles[category]then E.otherCategories[category]=not E.otherCategories[category]end
    E.ledgerPage=1;E.Refresh()
end
function E.OtherTitle()
    local count=0;for _,entry in ipairs(L.expenseCategories)do if E.otherCategories[entry[1]]then count=count+1 end end
    return count==#L.expenseCategories and"All other expenses"or(count==0 and"No categories"or(count.." categories selected"))
end

function E.SetPeriod(period)
    if U.Combat()then return end
    for _,entry in ipairs(periods)do if entry[1]==period then E.period=period;E.ledgerPage=1;E.Refresh();return end end
end
function E.OpenEditor()
    if U.Combat()then return end
    E.NewManual();E.messages.ledger="Enter actual totals for the whole transaction. Leave cost blank if unknown.";E.editorFrame:Show();E.Refresh()
end
local function Card(parent,title,x,y,width,height)
    local f=CreateFrame("Frame",nil,parent,"InsetFrameTemplate")
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);f:SetSize(width,height)
    f.title=Label(f,title,12,-10,width-24);f.title:SetFontObject("GameFontNormal")
    f.value=Label(f,"",12,-33,width-24);f.value:SetFontObject("GameFontNormalLarge");f.value:SetHeight(26)
    f.note=Label(f,"",12,-64,width-24)
    return f
end
function E.CreateLedger(f)
    local ledger=CreateFrame("Frame",nil,f);ledger:SetAllPoints(f);E.ledgerPanel=ledger
    local dates=Inset(ledger,-98,90)
    Label(dates,"Period",14,-16,48):SetFontObject("GameFontNormal")
    E.period,E.filterKind,E.ledgerView="30d","all","report";E.periodButtons={}
    local x=70
    for _,entry in ipairs(periods)do
        local key,title,width=entry[1],entry[2],entry[3]
        E.periodButtons[key]=Button(dates,title,x,-9,width,function()E.SetPeriod(key)end);x=x+width+8
    end
    E.periodText=Label(dates,"",562,-16,186,true)
    Label(dates,"From",14,-55,38);E.dateFirst=Box(dates,62,-49,110)
    Label(dates,"To",192,-55,24);E.dateLast=Box(dates,225,-49,110)
    E.dateFirst:SetMaxLetters(10);E.dateLast:SetMaxLetters(10)
    E.dateFirst:SetText(date("%Y-%m-%d",L.Range("30d").first));E.dateLast:SetText(date("%Y-%m-%d",U.Now()))
    E.appliedFirst,E.appliedLast=E.dateFirst:GetText(),E.dateLast:GetText()
    Button(dates,"Apply dates",355,-49,112,E.ApplyDates)
    Label(dates,"Local dates: YYYY-MM-DD",490,-55,258)
    E.reportTab=Button(ledger,"Period report",16,-198,132,function()E.SetLedgerView("report")end)
    E.transactionsTab=Button(ledger,"Transactions",156,-198,142,function()E.SetLedgerView("transactions")end)
    E.optionsTab=Button(ledger,"Ledger settings",306,-198,122,function()E.SetLedgerView("options")end)
    E.csvButton=Button(ledger,"Copy period CSV",440,-198,154,function()E.CopyCSV()end)
    E.newEntry=Button(ledger,"New entry",610,-198,160,E.OpenEditor)

    local report=CreateFrame("Frame",nil,ledger);report:SetAllPoints(ledger);E.reportPanel=report
    local totals=Inset(report,-232,434)
    E.report={};E.reportCards={}
    for _,entry in ipairs({{"income","Income",14},{"spend","Spending",264},{"flow","Cash flow",514}})do
        local key,title,left=entry[1],entry[2],entry[3]
        local card=Card(totals,title,left,-12,236,82);E.reportCards[key]=card;E.report[key]=card.value
    end
    Label(totals,"Income sources",14,-111,352):SetFontObject("GameFontNormal")
    Label(totals,"Spending sources",390,-111,360):SetFontObject("GameFontNormal")
    E.activityRows={}
    local function Activity(key,title,left,top)
        local row=CreateFrame("Button",nil,totals);row:SetPoint("TOPLEFT",totals,"TOPLEFT",left,top);row:SetSize(360,27)
        local bg=row:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints(row);bg:SetColorTexture(.14,.15,.17,.5)
        row.title=Label(row,title,10,-5,164);row.value=Label(row,"",176,-5,174,true)
        row:SetScript("OnClick",function()E.SetFilter(key)end)
        row:SetScript("OnEnter",function(self)if GameTooltip then GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:ClearLines();GameTooltip:AddLine("View "..string.lower(title).." for this period.");GameTooltip:Show()end end)
        row:SetScript("OnLeave",function()if GameTooltip then GameTooltip:Hide()end end)
        E.activityRows[key]=row
    end
    Activity("sale","AH sales",14,-136);Activity("vendor_sale","Vendor sales",14,-166);Activity("commission","Commissions",14,-196)
    Activity("buy","AH purchases",390,-136);Activity("vendor_buy","Vendor purchases",390,-166);Activity("expense","Other spending",390,-196)
    Activity("tip_received","Tips received",14,-226);Activity("tip_given","Tips given",390,-226)
    Activity("loot","Loot",14,-256)
    E.reportCards.profit=Card(totals,"Recorded-cost profit / loss",14,-298,360,92)
    E.reportCards.estimate=Card(totals,"Estimated craft profit / loss",390,-298,360,92)
    E.report.profit,E.report.estimate=E.reportCards.profit.value,E.reportCards.estimate.value
    E.report.unknown=Label(totals,"",14,-406,736)

    local transactions=CreateFrame("Frame",nil,ledger);transactions:SetAllPoints(ledger);E.transactionsPanel=transactions
    local types=Inset(transactions,-232,100)
    E.filterTitle=Label(types,"Transactions: All",14,-9,730);E.filterTitle:SetFontObject("GameFontNormal")
    E.filterButtons={};x=14
    for index,entry in ipairs(filters)do
        if index==7 then x=14 end
        local key,title,width=entry[1],entry[2],entry[3]
        E.filterButtons[key]=Button(types,title,x,index>6 and -66 or -33,width,function()E.SetFilter(key)end);x=x+width+8
    end
    E.otherHelp=Label(types,"Edit a row to change its details.",466,-73,282)
    E.otherCategories={};for _,entry in ipairs(L.expenseCategories)do E.otherCategories[entry[1]]=true end
    E.otherDropdown=CreateFrame("DropdownButton",nil,types,"WowStyle1DropdownTemplate")
    E.otherDropdown:SetPoint("TOPLEFT",types,"TOPLEFT",466,-66);E.otherDropdown:SetSize(282,25);E.otherDropdown:SetDefaultText("All other expenses")
    E.otherDropdown:SetupMenu(function(_,root)
        root:SetTag("MENU_MSMARKETVALUE_OTHER_FILTER")
        root:CreateButton("Select all categories",E.SelectOther,"all")
        root:CreateButton("Clear categories",E.SelectOther,"none")
        for _,entry in ipairs(L.expenseCategories)do
            root:CreateCheckbox(entry[2],function(key)return E.otherCategories[key]==true end,E.SelectOther,entry[1])
        end
    end)
    transactions:SetScript("OnHide",function()E.otherDropdown:CloseMenu()end)
    local entries=Inset(transactions,-342,262)
    local columns={{"Date local",0,84},{"Type",90,88},{"Item / note",184,158},{"Qty",346,28,true},{"Net",386,96,true},{"Cost",494,98,true},{"Profit",606,82,true},{"Source",704,40}}
    E.ledgerRows=TableRows(entries,columns,LEDGER_ROWS,28,E.LoadLedger,function(button,row)
        if not GameTooltip then return end
        GameTooltip:SetOwner(button,"ANCHOR_RIGHT");GameTooltip:ClearLines();GameTooltip:AddLine(row.name,1,.82,0)
        GameTooltip:AddLine(date("%Y-%m-%d %H:%M local",row.time).." - "..row.source)
        if L.Category(row)then GameTooltip:AddDoubleLine("Category",L.categoryTitles[L.Category(row)])end
        if row.kind=="loot"then GameTooltip:AddLine("Daily total; time is the first recorded loot award.",.8,.8,.8,true)end
        GameTooltip:AddDoubleLine("Total before tip",U.Money(row.amount));GameTooltip:AddDoubleLine("Tip",U.Money(row.tip or 0))
        GameTooltip:AddDoubleLine("Fees",U.Money(row.fee))
        local net,profit=L.Amounts(row)
        GameTooltip:AddDoubleLine("Net",Signed(net))
        if row.cost~=nil then GameTooltip:AddDoubleLine(row.estimatedCost and"Estimated cost"or"Recorded cost",U.Money(row.cost))end
        if profit~=nil then GameTooltip:AddDoubleLine(row.estimatedCost and"Estimated profit / loss"or"Profit / loss",Signed(profit))end
        if row.source=="AH mail"then GameTooltip:AddLine("Date: first recorded from mail.",.8,.8,.8,true)end
        if row.refund>0 then GameTooltip:AddDoubleLine("Returned deposit (excluded)",U.Money(row.refund))end
        GameTooltip:AddLine("Click to edit this transaction.");GameTooltip:Show()
    end)
    E.ledgerEmpty=Label(entries,"No transactions match this type and period.",20,-108,726);E.ledgerEmpty:SetJustifyH("CENTER")
    E.ledgerPrevious=Button(transactions,"Previous",14,-615,100,function()E.ledgerPage=math.max(1,E.ledgerPage-1);E.Refresh()end)
    E.ledgerPageText=Label(transactions,"",126,-621,520)
    E.ledgerNext=Button(transactions,"Next",680,-615,90,function()E.ledgerPage=E.ledgerPage+1;E.Refresh()end)

    local options=CreateFrame("Frame",nil,ledger);options:SetAllPoints(ledger);E.optionsPanel=options
    local settings=Inset(options,-232,404)
    Label(settings,"Automatic tracking",14,-14,730):SetFontObject("GameFontNormal")
    E.autoAH=CreateFrame("CheckButton",nil,settings,"UICheckButtonTemplate")
    E.autoAH:SetPoint("TOPLEFT",settings,"TOPLEFT",10,-43);E.autoAH:SetSize(26,26)
    E.autoAH:SetScript("OnClick",function(self)if U.Combat()then return end;D.data.settings.trackAH=self:GetChecked()==true;A.Transactions.RequestMail();E.Refresh()end)
    Label(settings,"Track AH transactions",43,-50,320)
    E.autoVendor=CreateFrame("CheckButton",nil,settings,"UICheckButtonTemplate")
    E.autoVendor:SetPoint("TOPLEFT",settings,"TOPLEFT",10,-77);E.autoVendor:SetSize(26,26)
    E.autoVendor:SetScript("OnClick",function(self)if U.Combat()then return end;D.data.settings.trackVendor=self:GetChecked()==true;A.Transactions.ResetVendor();E.Refresh()end)
    Label(settings,"Track vendor purchases and sales",43,-84,320)
    E.autoTrade=CreateFrame("CheckButton",nil,settings,"UICheckButtonTemplate")
    E.autoTrade:SetPoint("TOPLEFT",settings,"TOPLEFT",10,-112);E.autoTrade:SetSize(26,26)
    E.autoTrade:SetScript("OnClick",function(self)if U.Combat()then return end;D.data.settings.trackTrade=self:GetChecked()==true;A.Transactions.ResetTrade();E.Refresh()end)
    Label(settings,"Track player trade gold as tips",43,-119,320)
    local function CashOption(key,text,y)
        local b=CreateFrame("CheckButton",nil,settings,"UICheckButtonTemplate")
        b:SetPoint("TOPLEFT",settings,"TOPLEFT",390,y);b:SetSize(26,26)
        b:SetScript("OnClick",function(self)if U.Combat()then return end;D.data.settings[key]=self:GetChecked()==true;if key=="trackOther"then A.Cash.Reset()end;E.Refresh()end)
        Label(settings,text,423,y-7,320);return b
    end
    E.autoLoot=CashOption("trackLoot","Track daily loot income",-43)
    E.autoOther=CashOption("trackOther","Track other spending",-77)
    local help=Label(settings,"AH sales load from completed mail invoices. Loot is totaled each local day. Other spending uses confirmed wallet deductions; unrecognized costs appear as Unclassified. Reclassify trade payments instead of recording them twice.",14,-154,730);help:SetHeight(48);help:SetWordWrap(true)
    Label(settings,"Retention",14,-224,730):SetFontObject("GameFontNormal")
    Label(settings,"Keep transactions for",14,-260,164);E.retention=Box(settings,190,-253,57,true);E.retention:SetMaxLetters(3)
    Label(settings,"days (1-365)",267,-260,130);Button(settings,"Apply",410,-253,90,E.ApplyRetention)
    local retentionHelp=Label(settings,"A shorter retention period removes older entries. Copy the records you need before applying it.",14,-297,730);retentionHelp:SetHeight(34);retentionHelp:SetWordWrap(true)
    Button(settings,"View other spending",14,-349,196,function()E.SetFilter("expense")end)
    E.queueText=Label(settings,"",230,-356,514)

    local editor=CreateFrame("Frame","MSMarketValueTransaction",f,"PortraitFrameTemplate")
    editor:SetSize(790,310);editor:SetPoint("CENTER",f,"CENTER",0,0);editor:SetFrameStrata("DIALOG");editor:SetFrameLevel(f:GetFrameLevel()+20)
    editor:SetClampedToScreen(true);editor:SetTitle("MS Market Value - Transaction")
    if editor.PortraitContainer and editor.PortraitContainer.portrait then editor.PortraitContainer.portrait:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")end
    editor.CloseButton:SetScript("OnClick",function()editor:Hide()end);editor:SetScript("OnHide",function()E.messages.ledger=nil;if E.kindDropdown then E.kindDropdown:CloseMenu()end;if E.categoryDropdown then E.categoryDropdown:CloseMenu()end end);E.editorFrame=editor;table.insert(UISpecialFrames,"MSMarketValueTransaction")
    local fields=Inset(editor,-42,188)
    Label(fields,"Type",14,-10,160);Label(fields,"Item / transaction",186,-10,342);Label(fields,"Qty",548,-10,60)
    E.kindDropdown=CreateFrame("DropdownButton",nil,fields,"WowStyle1DropdownTemplate")
    E.kindDropdown:SetPoint("TOPLEFT",fields,"TOPLEFT",14,-29);E.kindDropdown:SetSize(160,25);E.kindDropdown:SetDefaultText("Choose type")
    E.kindDropdown:SetupMenu(function(_,root)
        root:SetTag("MENU_MSMARKETVALUE_TRANSACTION_TYPE")
        local function Selected(kind)return E.kind==kind end
        for _,kind in ipairs(kinds)do root:CreateRadio(titles[kind],Selected,E.SetKind,kind)end
        if E.originalRow and E.originalRow.kind=="loot"then root:CreateRadio(titles.loot,Selected,E.SetKind,"loot")end
    end)
    E.ledgerInputs={name=Box(fields,191,-31,331),quantity=Box(fields,553,-31,60,true),amount=Box(fields,20,-91,102),fee=Box(fields,143,-91,80),tip=Box(fields,245,-91,80),cost=Box(fields,347,-91,106)}
    E.ledgerInputs.name:SetMaxLetters(256)
    for _,key in ipairs({"amount","fee","tip","cost"})do E.ledgerInputs[key]:SetMaxLetters(24)end
    Label(fields,"Total before tip (g)",14,-70,125);Label(fields,"Fees (g)",137,-70,90);Label(fields,"Total tip (g)",239,-70,90);Label(fields,"Actual cost (g)",341,-70,112)
    Button(fields,"Record entry",650,-31,100,E.RecordLedger)
    E.importInvoiceButton=Button(fields,"Use open invoice",473,-91,145,E.ImportInvoice)
    E.categoryLabel=Label(fields,"Expense category",473,-70,145)
    E.categoryDropdown=CreateFrame("DropdownButton",nil,fields,"WowStyle1DropdownTemplate")
    E.categoryDropdown:SetPoint("TOPLEFT",fields,"TOPLEFT",473,-89);E.categoryDropdown:SetSize(145,25);E.categoryDropdown:SetDefaultText("Other spending")
    E.categoryDropdown:SetupMenu(function(_,root)
        root:SetTag("MENU_MSMARKETVALUE_EXPENSE_CATEGORY")
        for _,entry in ipairs(L.expenseCategories)do
            root:CreateRadio(entry[2],function(key)return E.expenseCategory==key end,function(key)
                if U.Combat()then return end;E.expenseCategory=key;E.Refresh()
            end,entry[1])
        end
    end)
    Button(fields,"Clear fields",624,-91,126,function()E.NewManual();E.Refresh()end)
    E.deleteEntry=Button(fields,"Delete entry",14,-135,128,function()
        if L.Remove(E.entryID)then E.NewManual();E.messages.ledger="Entry deleted. Undo delete can restore it.";E.Refresh()end
    end)
    E.undo=Button(fields,"Undo delete",154,-135,128,function()L.Undo();E.Refresh()end)
    Button(fields,"Cancel",650,-135,100,function()editor:Hide()end)
    Label(fields,"Amounts and cost cover the whole lot. Blank cost is unknown; tips are added to income.",14,-169,736)
    E.editorStatus=Label(editor,"",22,-244,746);E.editorStatus:SetHeight(48);E.editorStatus:SetWordWrap(true)
    editor:Hide()
end
function E.RefreshLedger()
    local range=E.PeriodFilter()
    E.periodText:SetText(E.period=="all"and"All retained records"or(date("%Y-%m-%d",range.first).." - "..date("%Y-%m-%d",range.last)))
    for _,entry in ipairs(periods)do E.periodButtons[entry[1]]:SetText((entry[1]==E.period and"|cffffd100"or"")..entry[2]..(entry[1]==E.period and"|r"or""))end
    E.reportTab:SetText(E.ledgerView=="report"and"|cffffd100Period report|r"or"Period report")
    E.transactionsTab:SetText(E.ledgerView=="transactions"and"|cffffd100Transactions|r"or"Transactions")
    E.optionsTab:SetText(E.ledgerView=="options"and"|cffffd100Ledger settings|r"or"Ledger settings")
    Visible(E.reportPanel,E.ledgerView=="report");Visible(E.transactionsPanel,E.ledgerView=="transactions");Visible(E.optionsPanel,E.ledgerView=="options")
    E.csvButton:SetText(E.ledgerView=="transactions"and"Copy filtered CSV"or"Copy period CSV")
    E.ledgerInputs.tip:SetEnabled(L.Income(E.kind))
    Visible(E.importInvoiceButton,E.kind~="expense");Visible(E.categoryLabel,E.kind=="expense");Visible(E.categoryDropdown,E.kind=="expense")
    E.categoryDropdown:Update()
    E.deleteEntry:SetEnabled(E.entryID~=nil and not U.Combat());E.undo:SetEnabled(L.lastDeleted~=nil and not U.Combat())
    E.editorStatus:SetText(L.reason or E.messages.ledger or"")
    if E.ledgerView=="report"then
        local sums=L.Summary(range)
        E.report.income:SetText(U.Money(sums.sales));E.report.spend:SetText(U.Money(sums.spend));E.report.flow:SetText(Signed(sums.flow));Accent(E.report.flow,sums.flow)
        E.reportCards.income.note:SetText("Tips included: "..U.Money(sums.tips))
        E.reportCards.spend.note:SetText("Purchases, tips and expenses")
        E.reportCards.flow.note:SetText(Count(#sums.rows).." in this period")
        for kind,row in pairs(E.activityRows)do row.value:SetText(U.Money(math.abs(sums.byKind[kind]or 0)))end
        E.report.profit:SetText(sums.known>0 and Signed(sums.profit)or"--");
        if sums.known>0 then Accent(E.report.profit,sums.profit)else E.report.profit:SetTextColor(.65,.65,.65)end
        E.report.estimate:SetText(sums.estimated>0 and Signed(sums.estimatedProfit)or"--");
        if sums.estimated>0 then Accent(E.report.estimate,sums.estimatedProfit)else E.report.estimate:SetTextColor(.65,.65,.65)end
        E.reportCards.profit.note:SetText(sums.known>0 and(Count(sums.known).." with recorded cost")or"No recorded costs")
        E.reportCards.estimate.note:SetText(sums.estimated>0 and(Count(sums.estimated).." using material estimates")or"No crafting estimates")
        E.report.unknown:SetText("Costs: "..sums.known.." recorded | "..sums.estimated.." estimated | "..sums.unknown.." needed")
        E.status:SetText(L.reason or"Period totals include all transaction types. Click an activity total to view its transactions.")
    elseif E.ledgerView=="transactions"then
        local names={all="All",buy="AH purchases",sale="AH sales",vendor_buy="Vendor purchases",vendor_sale="Vendor sales",commission="Commissions",tip_received="Tips received",tip_given="Tips given",expense="Other spending",loot="Loot"}
        E.filterTitle:SetText("Transactions: "..names[E.filterKind])
        Visible(E.otherDropdown,E.filterKind=="expense");Visible(E.otherHelp,E.filterKind~="expense")
        E.otherDropdown:OverrideText(E.OtherTitle())
        for _,entry in ipairs(filters)do E.filterButtons[entry[1]]:SetText((entry[1]==E.filterKind and"|cffffd100"or"")..entry[2]..(entry[1]==E.filterKind and"|r"or""))end
        local rows=L.View(E.CurrentFilter());local pages=math.max(1,math.ceil(#rows/LEDGER_ROWS));E.ledgerPage=math.max(1,math.min(E.ledgerPage,pages))
        for index,b in ipairs(E.ledgerRows)do
            local row=rows[(E.ledgerPage-1)*LEDGER_ROWS+index];b.row=row
            if row then
                local net,profit=L.Amounts(row)
                local sourceNames={["AH invoice"]="Invoice",["AH purchase"]="Live AH",["AH mail"]="Mail",["Craft quote"]="Craft",["Player trade"]="Trade",Vendor="Vendor",Manual="Manual",Loot="Loot",["Game expense"]="Game"}
                local values={date(row.kind=="loot"and"%m-%d total"or"%m-%d %H:%M",row.time),L.Category(row)and L.categoryTitles[L.Category(row)]or titles[row.kind],row.name,tostring(row.quantity),Signed(net),
                    row.cost~=nil and((row.estimatedCost and"Est. "or"")..U.Money(row.cost))or(L.Income(row.kind)and"Needed"or"--"),
                    profit~=nil and((row.estimatedCost and"Est. "or"")..Signed(profit))or"--",sourceNames[row.source]}
                for n,value in ipairs(values)do b.labels[n]:SetText(value)end
                if profit~=nil then Accent(b.labels[7],profit)else b.labels[7]:SetTextColor(.65,.65,.65)end
                b:Show()
            else b:Hide()end
        end
        if #rows==0 then E.ledgerEmpty:Show()else E.ledgerEmpty:Hide()end
        E.ledgerPageText:SetText(Count(#rows).." | Page "..E.ledgerPage.." / "..pages)
        E.ledgerPrevious:SetEnabled(E.ledgerPage>1);E.ledgerNext:SetEnabled(E.ledgerPage<pages)
        E.status:SetText(L.reason or E.messages.ledger or"Select a transaction to edit it. CSV uses this type and period; Period report covers all types.")
    else
        E.autoAH:SetChecked(D.Settings().trackAH);E.autoVendor:SetChecked(D.Settings().trackVendor);E.autoTrade:SetChecked(D.Settings().trackTrade);E.autoLoot:SetChecked(D.Settings().trackLoot);E.autoOther:SetChecked(D.Settings().trackOther)
        if not E.retention:HasFocus()then E.retention:SetText(tostring(D.Settings().ledgerDays))end
        E.queueText:SetText(#A.Transactions.queue.." confirmed transactions waiting for ledger space")
        E.status:SetText(L.reason or E.messages.ledger or"Tracking and retention apply to this character's ledger.")
    end
end

function E.Create()
    if E.frame then return end
    local f=CreateFrame("Frame","MSMarketValueEconomy",UIParent,"PortraitFrameTemplate")
    f:SetSize(790,610);f:SetPoint("CENTER",UIParent,"CENTER",0,0);f:SetFrameStrata("DIALOG");f:SetClampedToScreen(true)
    f:SetTitle("MS Market Value - Money tools");
    if f.PortraitContainer and f.PortraitContainer.portrait then f.PortraitContainer.portrait:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")end
    f:EnableMouse(true);f:SetMovable(true);f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function(self)if not U.Combat()then self:StartMoving()end end)
    f:SetScript("OnDragStop",function(self)self:StopMovingOrSizing()end)
    f.CloseButton:SetScript("OnClick",function()f:Hide()end);E.frame=f;table.insert(UISpecialFrames,"MSMarketValueEconomy")
    E.scope=Label(f,"",72,-39,700)
    E.ledgerTab=Button(f,"Ledger",16,-63,164,function()E.mode="ledger";E.Refresh()end)
    E.watchTab=Button(f,"Watchlists",190,-63,140,function()E.mode="watch";E.Refresh()end)
    E.settingsTab=Button(f,"Settings",340,-63,140,function()A.UI.OpenSettings()end)
    f:SetScript("OnHide",function()if E.editorFrame then E.editorFrame:Hide()end;if GameTooltip then GameTooltip:Hide()end end)
    E.status=Label(f,"",16,-573,756);E.status:SetHeight(30);E.status:SetWordWrap(true)
    local watch=CreateFrame("Frame",nil,f);watch:SetAllPoints(f);E.watchPanel=watch
    local filters=Inset(watch,-98,105)
    E.watchItemLabel=Label(filters,"Item ID / pasted item link",14,-10,278);Label(filters,"Buy at or below (g)",310,-10,110)
    Label(filters,"Min return %",430,-10,90);Label(filters,"Min profit (g)",534,-10,100)
    E.watchInputs={item=Box(filters,20,-31,272),itemPrice=Box(filters,315,-31,98),roi=Box(filters,435,-31,80,true),profit=Box(filters,539,-31,95)}
    E.watchInputs.itemPrice:SetText("0");E.watchInputs.roi:SetText("0");E.watchInputs.profit:SetText("0")
    Button(filters,"Save watch",650,-31,100,E.SaveWatch)
    E.alerts=CreateFrame("CheckButton",nil,filters,"UICheckButtonTemplate")
    E.alerts:SetPoint("TOPLEFT",filters,"TOPLEFT",10,-69);E.alerts:SetSize(26,26)
    E.alerts:SetScript("OnClick",function(self)if not U.Combat()then D.data.settings.watchAlerts=self:GetChecked()==true end end)
    Label(filters,"Local alerts after saved scans. A 0 target is off; all 0 means tracking only.",43,-76,700)
    local tableFrame=Inset(watch,-212,264)
    local columns={{"Item",0,230},{"Scan low",234,100,true},{"Buy target",338,100,true},{"Return",442,72,true},{"Days",518,40,true},{"Status",562,178}}
    E.watchRows=TableRows(tableFrame,columns,7,29,E.SelectWatch,function(button,row)
        if not GameTooltip then return end
        GameTooltip:SetOwner(button,"ANCHOR_RIGHT");GameTooltip:ClearLines();GameTooltip:AddLine(row.name,1,.82,0)
        GameTooltip:AddLine(row.suffix~=nil and ("Exact suffix: "..row.suffix)or"Any suffix / item-wide series")
        GameTooltip:AddDoubleLine("Min return",row.watch.minReturn.."%");GameTooltip:AddDoubleLine("Min profit",U.Money(row.watch.minProfit))
        if row.profit then GameTooltip:AddDoubleLine("Estimated net / item",Signed(row.profit))end
        GameTooltip:AddLine(row.status);GameTooltip:Show()
    end)
    E.watchPrevious=Button(watch,"Previous",14,-488,100,function()E.watchPage=math.max(1,E.watchPage-1);E.Refresh()end)
    E.watchPageText=Label(watch,"",126,-493,255)
    E.watchNext=Button(watch,"Next",680,-488,90,function()E.watchPage=E.watchPage+1;E.Refresh()end)
    E.watchView=Button(watch,"View listings",388,-488,140,E.ViewWatch)
    E.watchRemove=Button(watch,"Remove watch",538,-488,132,function()
        if W.Remove(E.selectedWatch)then E.selectedWatch=nil;W.Ensure();E.Refresh()end
    end)
    E.watchDetail=Label(watch,"",16,-532,754);E.watchDetail:SetHeight(30);E.watchDetail:SetWordWrap(true)

    E.CreateLedger(f)
    E.NewManual();f:Hide()
end

function E.Refresh()
    if not E.frame then return end
    local market,player=U.MarketKey(),U.PlayerKey()
    if E.market~=market or E.player~=player then
        E.market,E.player,E.selectedWatch=market,player,nil;E.watchPage,E.ledgerPage=1,1;E.NewManual()
    end
    local identity=U.MarketInfo()
    local label=identity.label or "Market unavailable"
    E.scope:SetText("Personal ledger | "..label)
    E.frame:SetTitle(E.mode=="watch"and"MS Market Value - Watchlists"or"MS Market Value - Ledger")
    if E.mode == "watch" then
        local snapshot = W.snapshot or D.Snapshot()
        E.scope:SetText(label .. "  |  Scan: " .. (snapshot and U.Age(snapshot.startedAt) or "none") .. (W.job and " (checking targets)" or ""))
    end
    E.watchTab:SetText(E.mode=="watch"and"|cffffd100Watchlists|r"or"Watchlists")
    E.ledgerTab:SetText(E.mode=="ledger"and"|cffffd100Ledger|r"or"Ledger")
    E.frame:SetHeight(E.mode=="watch"and 610 or 720)
    E.status:ClearAllPoints();E.status:SetPoint("TOPLEFT",E.frame,"TOPLEFT",16,E.mode=="watch"and -573 or -683)
    if E.mode=="watch"then
        E.watchPanel:Show();E.ledgerPanel:Hide();E.alerts:SetChecked(D.Settings().watchAlerts)
        local pages=math.max(1,math.ceil(#W.rows/7));E.watchPage=math.max(1,math.min(E.watchPage,pages))
        local selected
        for _,row in ipairs(W.rows)do if row.key==E.selectedWatch then selected=row;break end end
        for index,b in ipairs(E.watchRows)do
            local row=W.rows[(E.watchPage-1)*7+index];b.row=row
            if row then
                local values={row.name,row.current and U.Money(row.current)or"Unavailable",row.watch.maxBuy>0 and U.Money(row.watch.maxBuy)or"Off",row.roi and string.format("%+.0f%%",row.roi)or"--",tostring(row.days),row.status}
                for n,value in ipairs(values)do b.labels[n]:SetText(value)end
                b.labels[6]:SetTextColor(row.matched and .35 or .83,row.matched and .87 or .86,.38);b:Show()
            else b:Hide()end
        end
        E.watchPageText:SetText(#W.rows.." watched | Page "..E.watchPage.." / "..pages)
        E.watchPrevious:SetEnabled(E.watchPage>1);E.watchNext:SetEnabled(E.watchPage<pages)
        E.watchView:SetEnabled(selected~=nil and selected.current~=nil and not W.job and not U.Combat())
        E.watchRemove:SetEnabled(selected~=nil and not U.Combat())
        E.watchDetail:SetText(selected and (selected.name..": "..selected.status..". "..selected.days.." earlier priced days. Targets use per-item prices and the configured AH cut.")or"Select a row to edit its targets. Item IDs track any suffix; item links track an exact suffix. Buy/return/profit targets combine.")
        E.status:SetText(W.reason or E.messages.watch or (W.job and"Checking watchlist targets from saved data..."or"Watchlists reuse saved scans and prior history. No background auction search is started."))
    else
        E.watchPanel:Hide();E.ledgerPanel:Show()
        E.RefreshLedger()
    end
end
function E.Show(mode)
    if U.Combat()then return U.Print("Open money tools outside combat.")end
    if not D.data or A.disabledReason then return end
    if A.UI.frame then A.UI.frame:Hide()end
    E.Create();E.mode=mode=="ledger"and"ledger"or"watch";W.Ensure();E.frame:Show();E.Refresh()
end
