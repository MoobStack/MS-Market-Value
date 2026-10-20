local _, A = ...
local U,D,W,L = A.Util,A.DB,A.Watchlist,A.Ledger
local E = { mode = "watch", watchPage = 1, ledgerPage = 1, kind = "sale", messages = {} }
A.EconomyUI = E
local kinds, titles = {"sale","buy","commission","vendor_sale","vendor_buy"}, {sale="AH sale",buy="AH buy",commission="Commission",vendor_sale="Vendor sale",vendor_buy="Vendor buy",expense="Legacy expense"}
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

function E.NewManual()
    E.entryID,E.invoiceDraft,E.ledgerItemID,E.originalRow=nil,nil,nil,nil;E.kind="sale"
    if not E.ledgerInputs then return end
    local v=E.ledgerInputs
    E.kindButton:SetText(titles.sale);v.name:SetText("");v.quantity:SetText("1");v.amount:SetText("");v.fee:SetText("0");v.tip:SetText("0");v.cost:SetText("")
    E.messages.ledger="Enter actual transaction totals. A blank sale cost stays unknown."
end
function E.LoadLedger(row)
    E.entryID,E.kind,E.ledgerItemID,E.originalRow=row.id,row.kind,row.itemID,row
    E.invoiceDraft=row.invoiceKey and row or nil
    local v=E.ledgerInputs;E.kindButton:SetText(titles[row.kind]);v.name:SetText(row.name);v.quantity:SetText(tostring(row.quantity))
    v.amount:SetText(U.GoldText(row.amount));v.fee:SetText(U.GoldText(row.fee));v.tip:SetText(U.GoldText(row.tip or 0));v.cost:SetText(row.cost~=nil and not row.estimatedCost and U.GoldText(row.cost)or"")
    E.messages.ledger="Editing entry "..row.id..". "..(row.estimatedCost and "Cost is a craft estimate; enter an actual cost to replace it." or "Record entry saves the changes.");E.Refresh()
end
function E.ImportInvoice()
    local row,why=L.ReadOpenInvoice()
    if not row then return Message(why)end
    E.NewManual();E.kind,E.invoiceDraft,E.ledgerItemID=row.kind,row,row.itemID
    local v=E.ledgerInputs;E.kindButton:SetText(titles[row.kind]);v.name:SetText(row.name);v.quantity:SetText(tostring(row.quantity))
    v.amount:SetText(U.GoldText(row.amount));v.fee:SetText(U.GoldText(row.fee))
    E.messages.ledger="Invoice preview. Enter actual cost if known, then Record entry. Deposit refunds are excluded from profit.";E.Refresh();return true
end
function E.RecordLedger()
    local v=E.ledgerInputs
    local input={kind=E.kind,name=v.name:GetText(),quantity=tonumber(v.quantity:GetText()),amount=U.ParseGold(v.amount:GetText(),1000000000000),
        fee=U.ParseGold(v.fee:GetText(),1000000000000),tip=L.Income(E.kind)and U.ParseGold(v.tip:GetText(),1000000000000)or 0,itemID=E.ledgerItemID}
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
    E.NewManual();E.messages.ledger="Entry recorded. Balances cover retained records only.";E.ledgerPage=1;E.Refresh();return true
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

function E.CurrentFilter()
    local range=L.Range(E.period or "30d",E.appliedFirst,E.appliedLast)
    range=range or {first=0,last=0};range.kind=E.filterKind or "all"
    return range
end
function E.ApplyDates()
    local range,why=L.Range("custom",E.dateFirst:GetText(),E.dateLast:GetText())
    if not range then return Message(why)end
    E.appliedFirst,E.appliedLast=E.dateFirst:GetText(),E.dateLast:GetText();E.period="custom";E.ledgerPage=1
    E.messages.ledger="Showing the selected UTC dates. Reports and CSV use these filters.";E.Refresh();return true
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
    E.watchTab=Button(f,"Watchlists",16,-63,140,function()E.mode="watch";E.Refresh()end)
    E.ledgerTab=Button(f,"Personal ledger",166,-63,168,function()E.mode="ledger";E.Refresh()end)
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

    local ledger=CreateFrame("Frame",nil,f);ledger:SetAllPoints(f);E.ledgerPanel=ledger
    local editor=Inset(ledger,-98,188)
    Label(editor,"Type",14,-10,95);Label(editor,"Item / transaction",124,-10,390);Label(editor,"Qty",532,-10,60)
    E.kindButton=Button(editor,"Sale",14,-31,95,function()
        for index,kind in ipairs(kinds)do if kind==E.kind then E.kind=kinds[index%#kinds+1];break end end
        E.kindButton:SetText(titles[E.kind]);E.Refresh()
    end)
    E.ledgerInputs={name=Box(editor,129,-31,385),quantity=Box(editor,537,-31,60,true),amount=Box(editor,20,-91,102),fee=Box(editor,143,-91,80),tip=Box(editor,245,-91,80),cost=Box(editor,347,-91,106)}
    E.ledgerInputs.name:SetMaxLetters(256)
    for _,key in ipairs({"amount","fee","tip","cost"})do E.ledgerInputs[key]:SetMaxLetters(24)end
    Label(editor,"Total before tip (g)",14,-70,125);Label(editor,"Fees (g)",137,-70,90);Label(editor,"Total tip (g)",239,-70,90);Label(editor,"Actual cost (g)",341,-70,112)
    Button(editor,"Record entry",650,-31,100,E.RecordLedger)
    Button(editor,"Use open invoice",473,-91,145,E.ImportInvoice)
    Button(editor,"New manual entry",624,-91,126,function()E.NewManual();E.Refresh()end)
    Label(editor,"Keep days",14,-141,88);E.retention=Box(editor,108,-135,57,true);E.retention:SetMaxLetters(3)
    Button(editor,"Apply",180,-135,74,E.ApplyRetention)
    E.deleteEntry=Button(editor,"Delete entry",283,-135,112,function()if L.Remove(E.entryID)then E.NewManual();E.Refresh()end end)
    E.undo=Button(editor,"Undo delete",405,-135,112,function()L.Undo();E.Refresh()end)
    Button(editor,"Copy CSV",530,-135,112,E.CopyCSV)
    Label(editor,"Amounts and cost cover the whole lot. Blank cost is unknown; tips are added to income.",14,-169,736)
    local filters=Inset(ledger,-296,102)
    E.filterKind,E.period="all","30d"
    E.filterButton=Button(filters,"All transactions",14,-10,140,function()
        local order={"all","sale","buy","commission","vendor_sale","vendor_buy","expense"}
        for index,value in ipairs(order)do if value==E.filterKind then E.filterKind=order[index%#order+1];break end end
        E.ledgerPage=1;E.Refresh()
    end)
    E.periodButton=Button(filters,"Last 30 days",164,-10,142,function()
        local order={"all","today","7d","30d","custom"}
        for index,value in ipairs(order)do if value==E.period then E.period=order[index%#order+1];break end end
        E.ledgerPage=1;E.Refresh()
    end)
    Label(filters,"From",318,-16,36);E.dateFirst=Box(filters,361,-10,104)
    Label(filters,"To",482,-16,20);E.dateLast=Box(filters,514,-10,104)
    E.dateFirst:SetMaxLetters(10);E.dateLast:SetMaxLetters(10)
    E.dateFirst:SetText(date("!%Y-%m-%d",U.Now()-29*86400));E.dateLast:SetText(date("!%Y-%m-%d",U.Now()))
    E.appliedFirst,E.appliedLast=E.dateFirst:GetText(),E.dateLast:GetText()
    Button(filters,"Apply dates",637,-10,112,E.ApplyDates)
    E.autoAH=CreateFrame("CheckButton",nil,filters,"UICheckButtonTemplate")
    E.autoAH:SetPoint("TOPLEFT",filters,"TOPLEFT",10,-47);E.autoAH:SetSize(26,26)
    E.autoAH:SetScript("OnClick",function(self)D.data.settings.trackAH=self:GetChecked()==true;A.Transactions.RequestMail();E.Refresh()end)
    Label(filters,"Track AH transactions",43,-54,180)
    E.autoVendor=CreateFrame("CheckButton",nil,filters,"UICheckButtonTemplate")
    E.autoVendor:SetPoint("TOPLEFT",filters,"TOPLEFT",233,-47);E.autoVendor:SetSize(26,26)
    E.autoVendor:SetScript("OnClick",function(self)D.data.settings.trackVendor=self:GetChecked()==true;A.Transactions.ResetVendor();E.Refresh()end)
    Label(filters,"Track vendor trades",266,-54,185)
    Label(filters,"UTC dates | YYYY-MM-DD",490,-54,247)
    Label(filters,"Completed AH sales are added when their invoices load in your mailbox.",14,-80,730)
    local entries=Inset(ledger,-408,207)
    local ledgerColumns={{"Date UTC",0,86},{"Type",90,80},{"Item / note",174,164},{"Qty",342,30,true},{"Net",376,101,true},{"Cost",481,100,true},{"Profit",585,100,true},{"Source",689,54}}
    E.ledgerRows=TableRows(entries,ledgerColumns,6,28,E.LoadLedger,function(button,row)
        if not GameTooltip then return end
        GameTooltip:SetOwner(button,"ANCHOR_RIGHT");GameTooltip:ClearLines();GameTooltip:AddLine(row.name,1,.82,0)
        GameTooltip:AddLine(date("!%Y-%m-%d %H:%M UTC",row.time).." - "..row.source)
        GameTooltip:AddDoubleLine("Total before tip",U.Money(row.amount));GameTooltip:AddDoubleLine("Tip",U.Money(row.tip or 0));
        if row.estimatedCost then GameTooltip:AddLine("Material cost and profit are estimates. Enter actual cost to replace them.",1,.82,.3,true)end
        if row.source=="AH mail"then GameTooltip:AddLine("Date is when this invoice was first recorded, not the sale time.",.8,.8,.8,true)end
        GameTooltip:AddDoubleLine("Total",U.Money(row.amount));GameTooltip:AddDoubleLine("Fees",U.Money(row.fee))
        if row.refund>0 then GameTooltip:AddDoubleLine("Returned deposit (excluded)",U.Money(row.refund))end
        GameTooltip:AddLine("Click to edit. A blank cost is not treated as zero.");GameTooltip:Show()
    end)
    E.ledgerPrevious=Button(ledger,"Previous",14,-625,100,function()E.ledgerPage=math.max(1,E.ledgerPage-1);E.Refresh()end)
    E.ledgerPageText=Label(ledger,"",126,-631,480)
    E.ledgerNext=Button(ledger,"Next",680,-625,90,function()E.ledgerPage=E.ledgerPage+1;E.Refresh()end)
    E.report={}
    for _,field in ipairs({{"income",16,-656,180},{"spend",205,-656,175},{"flow",389,-656,190},{"tips",588,-656,182},{"profit",16,-677,250},{"estimate",280,-677,260},{"unknown",552,-677,218}})do
        E.report[field[1]]=Label(ledger,"",field[2],field[3],field[4])
    end
    E.NewManual();f:Hide()
end

function E.Refresh()
    if not E.frame then return end
    local market,player=U.MarketKey(),U.PlayerKey()
    if E.market~=market or E.player~=player then
        E.market,E.player,E.selectedWatch=market,player,nil;E.watchPage,E.ledgerPage=1,1;E.NewManual()
    end
    E.scope:SetText((E.mode=="watch"and"Watchlists: this market"or"Ledger: this character and market").."  |  "..(market or"Market unavailable"))
    if E.mode == "watch" then
        local snapshot = W.snapshot or D.Snapshot()
        E.scope:SetText((market or "Market unavailable") .. "  |  Scan: " .. (snapshot and U.Age(snapshot.startedAt) or "none") .. (W.job and " (checking targets)" or ""))
    end
    E.watchTab:SetText(E.mode=="watch"and"|cffffd100Watchlists|r"or"Watchlists")
    E.ledgerTab:SetText(E.mode=="ledger"and"|cffffd100Personal ledger|r"or"Personal ledger")
    E.frame:SetHeight(E.mode=="watch"and 610 or 730)
    E.status:ClearAllPoints();E.status:SetPoint("TOPLEFT",E.frame,"TOPLEFT",16,E.mode=="watch"and -573 or -696)
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
        local periodNames={all="All retained",today="Today",["7d"]="Last 7 days",["30d"]="Last 30 days",custom="Custom dates"}
        E.filterButton:SetText(E.filterKind=="all"and"All transactions"or titles[E.filterKind]);E.periodButton:SetText(periodNames[E.period])
        E.ledgerInputs.tip:SetEnabled(L.Income(E.kind))
        E.autoAH:SetChecked(D.Settings().trackAH);E.autoVendor:SetChecked(D.Settings().trackVendor)
        local filter=E.CurrentFilter()
        local rows=L.View(filter);local pages=math.max(1,math.ceil(#rows/6));E.ledgerPage=math.max(1,math.min(E.ledgerPage,pages))
        for index,b in ipairs(E.ledgerRows)do
            local row=rows[(E.ledgerPage-1)*6+index];b.row=row
            if row then
                local net,profit=L.Amounts(row)
                local sourceNames={["AH invoice"]="Invoice",["AH purchase"]="Live AH",["AH mail"]="Mail",["Craft quote"]="Craft",Vendor="Vendor",Manual="Manual"}
                local values={date("!%m-%d %H:%M",row.time),titles[row.kind],row.name,tostring(row.quantity),Signed(net),
                    row.cost~=nil and ((row.estimatedCost and "Est. "or"")..U.Money(row.cost))or(L.Income(row.kind)and"Needed"or"--"),
                    profit~=nil and ((row.estimatedCost and "Est. "or"")..Signed(profit))or"--",sourceNames[row.source]}
                for n,value in ipairs(values)do b.labels[n]:SetText(value)end
                b.labels[7]:SetTextColor(profit and profit>=0 and .35 or 1,profit and profit>=0 and .87 or .65,.38);b:Show()
            else b:Hide()end
        end
        E.ledgerPageText:SetText(#rows.." entries | Page "..E.ledgerPage.." / "..pages)
        E.ledgerPrevious:SetEnabled(E.ledgerPage>1);E.ledgerNext:SetEnabled(E.ledgerPage<pages)
        E.deleteEntry:SetEnabled(E.entryID~=nil and not U.Combat());E.undo:SetEnabled(L.lastDeleted~=nil and not U.Combat())
        if not E.retention:HasFocus()then E.retention:SetText(tostring(D.Settings().ledgerDays))end
        local sums=L.Summary(filter)
        E.report.income:SetText("Income: "..U.Money(sums.sales));E.report.spend:SetText("Spending: "..U.Money(sums.spend))
        E.report.flow:SetText("Cash flow: "..Signed(sums.flow));E.report.tips:SetText("Tips: "..U.Money(sums.tips))
        E.report.profit:SetText("Known P/L: "..Signed(sums.profit));E.report.estimate:SetText("Est. craft P/L: "..Signed(sums.estimatedProfit))
        E.report.unknown:SetText(sums.unknown.." income entries need cost")
        E.status:SetText(L.reason or E.messages.ledger or"Ledger records observed/reported transactions, not price-scan estimates.")
    end
end
function E.Show(mode)
    if U.Combat()then return U.Print("Open money tools outside combat.")end
    if not D.data or A.disabledReason then return end
    E.Create();E.mode=mode=="ledger"and"ledger"or"watch";W.Ensure();E.frame:Show();E.Refresh()
end
