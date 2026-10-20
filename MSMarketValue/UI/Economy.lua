local _, A = ...
local U,D,W,L = A.Util,A.DB,A.Watchlist,A.Ledger
local E = { mode = "watch", watchPage = 1, ledgerPage = 1, kind = "sale", messages = {} }
A.EconomyUI = E
local kinds, titles = {"sale","buy","expense"}, {sale="Sale",buy="Buy",expense="Expense"}
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
    local v=E.watchInputs
    v.item:SetText(row.suffix~=nil and row.link or tostring(row.id))
    v.itemPrice:SetText(U.GoldText(row.watch.maxBuy));v.roi:SetText(tostring(row.watch.minReturn));v.profit:SetText(U.GoldText(row.watch.minProfit))
    E.Refresh()
end
function E.WatchDraft(row)
    if not row or U.Combat() then return end
    E.Show("watch")
    E.watchInputs.item:SetText(row.suffix~=nil and row.link or tostring(row.id))
    E.watchInputs.itemPrice:SetText(U.GoldText(math.min(100000000,math.floor(row.maxBuy or row.buy or 0))))
    E.watchInputs.roi:SetText(tostring(D.Settings().marketMinReturn));E.watchInputs.profit:SetText(U.GoldText(D.Settings().marketMinProfit))
    E.selectedWatch=nil;E.messages.watch="Draft from Opportunities. Review the targets and click Save watch.";E.Refresh()
end
function E.ViewWatch()
    for _,row in ipairs(W.rows)do if row.key==E.selectedWatch then
        if A.MarketUI.OpenListings(row,"watch")then E.frame:Hide()else Message(A.MarketUI.message)end;return
    end end
    Message("Select a current watchlist row first.")
end

function E.NewManual()
    E.entryID,E.invoiceDraft,E.ledgerItemID=nil,nil,nil;E.kind="sale"
    if not E.ledgerInputs then return end
    local v=E.ledgerInputs
    E.kindButton:SetText("Sale");v.name:SetText("");v.quantity:SetText("1");v.amount:SetText("");v.fee:SetText("0");v.cost:SetText("")
    E.messages.ledger="Enter actual transaction totals. A blank sale cost stays unknown."
end
function E.LoadLedger(row)
    E.entryID,E.kind,E.ledgerItemID=row.id,row.kind,row.itemID
    E.invoiceDraft=row.invoiceKey and row or nil
    local v=E.ledgerInputs;E.kindButton:SetText(titles[row.kind]);v.name:SetText(row.name);v.quantity:SetText(tostring(row.quantity))
    v.amount:SetText(U.GoldText(row.amount));v.fee:SetText(U.GoldText(row.fee));v.cost:SetText(row.cost~=nil and U.GoldText(row.cost)or"")
    E.messages.ledger="Editing entry "..row.id..". Record entry saves the changes.";E.Refresh()
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
        fee=U.ParseGold(v.fee:GetText(),1000000000000),itemID=E.ledgerItemID}
    local cost=v.cost:GetText()
    if cost~="" then input.cost=U.ParseGold(cost,1000000000000);if input.cost==nil then return Message("Enter a valid cost, or leave cost blank if unknown.")end end
    local invoice=E.invoiceDraft
    if invoice and invoice.kind==input.kind and invoice.name==input.name and invoice.quantity==input.quantity and invoice.amount==input.amount and invoice.fee==input.fee then
        input.invoiceKey,input.invoiceExpiry,input.refund=invoice.invoiceKey,invoice.invoiceExpiry,invoice.refund
    end
    local ok,why=L.Record(input,E.entryID)
    if not ok then return Message(why)end
    E.NewManual();E.messages.ledger="Entry recorded. Balances cover retained records only.";E.ledgerPage=1;E.Refresh();return true
end
function E.DraftSale(row)
    if not row or U.Combat()then return end
    E.Show("ledger");E.NewManual()
    E.ledgerInputs.name:SetText(row.name);E.ledgerInputs.quantity:SetText("1")
    local quote=A.Crafting.DisplayQuote(row)
    if quote then E.ledgerInputs.amount:SetText(U.GoldText(math.floor(quote+.5)))end
    E.messages.ledger="Draft from a quote. Confirm the actual payment and actual cost before recording.";E.Refresh()
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
        box:SetSize(670,420);box:SetMaxLetters(1000000);scroll:SetScrollChild(box)
        box:SetScript("OnEscapePressed",function()f:Hide()end);E.csvFrame,E.csvBox=f,box
        table.insert(UISpecialFrames,"MSMarketValueLedgerCSV")
    end
    E.csvBox:SetText(L.CSV());E.csvFrame:Show();E.csvBox:SetFocus();E.csvBox:HighlightText()
end

function E.Create()
    if E.frame then return end
    local f=CreateFrame("Frame","MSMarketValueEconomy",UIParent,"PortraitFrameTemplate")
    f:SetSize(790,610);f:SetPoint("CENTER",UIParent,"CENTER",0,0);f:SetFrameStrata("DIALOG");f:SetClampedToScreen(true)
    f:SetTitle("MS Market Value - Money tools");f:EnableMouse(true);f:SetMovable(true);f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function(self)if not U.Combat()then self:StartMoving()end end)
    f:SetScript("OnDragStop",function(self)self:StopMovingOrSizing()end)
    f.CloseButton:SetScript("OnClick",function()f:Hide()end);E.frame=f;table.insert(UISpecialFrames,"MSMarketValueEconomy")
    E.scope=Label(f,"",72,-39,700)
    E.watchTab=Button(f,"Watchlists",16,-63,140,function()E.mode="watch";E.Refresh()end)
    E.ledgerTab=Button(f,"Personal ledger",166,-63,168,function()E.mode="ledger";E.Refresh()end)
    E.status=Label(f,"",16,-573,756);E.status:SetHeight(30);E.status:SetWordWrap(true)
    local watch=CreateFrame("Frame",nil,f);watch:SetAllPoints(f);E.watchPanel=watch
    local filters=Inset(watch,-98,105)
    Label(filters,"Item ID / pasted item link",14,-10,278);Label(filters,"Buy at or below (g)",310,-10,110)
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
    E.ledgerInputs={name=Box(editor,129,-31,385),quantity=Box(editor,537,-31,60,true),amount=Box(editor,20,-91,125),fee=Box(editor,164,-91,110),cost=Box(editor,290,-91,145)}
    E.ledgerInputs.name:SetMaxLetters(256)
    for _,key in ipairs({"amount","fee","cost"})do E.ledgerInputs[key]:SetMaxLetters(24)end
    Label(editor,"Total amount (g)",14,-70,130);Label(editor,"Fees (g)",158,-70,112);Label(editor,"Actual cost (g, optional)",284,-70,155)
    Button(editor,"Record entry",650,-31,100,E.RecordLedger)
    Button(editor,"Use open invoice",448,-91,166,E.ImportInvoice)
    Button(editor,"New manual entry",624,-91,126,function()E.NewManual();E.Refresh()end)
    Label(editor,"Keep days",14,-141,88);E.retention=Box(editor,108,-135,57,true);E.retention:SetMaxLetters(3)
    Button(editor,"Apply",180,-135,74,E.ApplyRetention)
    E.deleteEntry=Button(editor,"Delete entry",283,-135,112,function()if L.Remove(E.entryID)then E.NewManual();E.Refresh()end end)
    E.undo=Button(editor,"Undo delete",405,-135,112,function()L.Undo();E.Refresh()end)
    Button(editor,"Copy CSV",530,-135,112,E.CopyCSV)
    Label(editor,"Sale amount is before fees. Cost is the whole lot's actual cost; blank means unknown.",14,-169,736)
    local entries=Inset(ledger,-296,207)
    local ledgerColumns={{"Type",0,55},{"Item / note",59,222},{"Qty",285,34,true},{"Net",323,110,true},{"Cost",437,110,true},{"Profit",551,112,true},{"Source",667,76}}
    E.ledgerRows=TableRows(entries,ledgerColumns,6,28,E.LoadLedger,function(button,row)
        if not GameTooltip then return end
        GameTooltip:SetOwner(button,"ANCHOR_RIGHT");GameTooltip:ClearLines();GameTooltip:AddLine(row.name,1,.82,0)
        GameTooltip:AddLine(date("!%Y-%m-%d %H:%M UTC",row.time).." - "..row.source)
        GameTooltip:AddDoubleLine("Total",U.Money(row.amount));GameTooltip:AddDoubleLine("Fees",U.Money(row.fee))
        if row.refund>0 then GameTooltip:AddDoubleLine("Returned deposit (excluded)",U.Money(row.refund))end
        GameTooltip:AddLine("Click to edit. A blank cost is not treated as zero.");GameTooltip:Show()
    end)
    E.ledgerPrevious=Button(ledger,"Previous",14,-512,100,function()E.ledgerPage=math.max(1,E.ledgerPage-1);E.Refresh()end)
    E.ledgerPageText=Label(ledger,"",126,-518,480)
    E.ledgerNext=Button(ledger,"Next",680,-512,90,function()E.ledgerPage=E.ledgerPage+1;E.Refresh()end)
    E.ledgerTotals=Label(ledger,"",16,-544,754);E.ledgerTotals:SetHeight(26);E.ledgerTotals:SetWordWrap(true)
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
        local rows=L.Records();local pages=math.max(1,math.ceil(#rows/6));E.ledgerPage=math.max(1,math.min(E.ledgerPage,pages))
        for index,b in ipairs(E.ledgerRows)do
            local row=rows[(E.ledgerPage-1)*6+index];b.row=row
            if row then
                local net,profit=L.Amounts(row)
                local values={titles[row.kind],row.name,tostring(row.quantity),Signed(net),row.cost~=nil and U.Money(row.cost)or(row.kind=="sale"and"Needed"or"--"),profit~=nil and Signed(profit)or"--",row.source=="AH invoice"and"Invoice"or"Manual"}
                for n,value in ipairs(values)do b.labels[n]:SetText(value)end
                b.labels[6]:SetTextColor(profit and profit>=0 and .35 or 1,profit and profit>=0 and .87 or .65,.38);b:Show()
            else b:Hide()end
        end
        E.ledgerPageText:SetText(#rows.." entries | Page "..E.ledgerPage.." / "..pages)
        E.ledgerPrevious:SetEnabled(E.ledgerPage>1);E.ledgerNext:SetEnabled(E.ledgerPage<pages)
        E.deleteEntry:SetEnabled(E.entryID~=nil and not U.Combat());E.undo:SetEnabled(L.lastDeleted~=nil and not U.Combat())
        if not E.retention:HasFocus()then E.retention:SetText(tostring(D.Settings().ledgerDays))end
        local sums=L.Summary()
        E.ledgerTotals:SetText("Net sales "..U.Money(sums.sales).." | Purchases/expenses "..U.Money(sums.spend).." | Recorded flow "..Signed(sums.flow).."\nKnown sale profit "..Signed(sums.profit).." | "..sums.unknown.." sales need cost. Returned deposits excluded.")
        E.status:SetText(L.reason or E.messages.ledger or"Ledger records observed/reported transactions, not price-scan estimates.")
    end
end
function E.Show(mode)
    if U.Combat()then return U.Print("Open money tools outside combat.")end
    if not D.data or A.disabledReason then return end
    E.Create();E.mode=mode=="ledger"and"ledger"or"watch";W.Ensure();E.frame:Show();E.Refresh()
end
