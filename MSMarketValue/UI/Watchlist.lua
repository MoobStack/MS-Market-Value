local _,A=...
local U,D,W,E=A.Util,A.DB,A.Watchlist,A.EconomyUI
local UI={offset=0,search="",rows={},headers={}}
A.WatchUI=UI
local ROWS,STEP=10,29
local columns={{"Item","name",8,203},{"Scan each","current",219,96,true},{"Buy target","target",319,96,true},
    {"Net / item","profit",419,96,true},{"Return","roi",519,60,true},{"Status","status",583,96}}
local ranks={["TARGET MET"]=0,Watching=1,["More history needed"]=2,["Tracking only"]=3,["Not listed"]=4,["Fresh scan needed"]=5}
local function Label(parent,text,x,y,width)
    local label=parent:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    label:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);label:SetSize(width,16);label:SetWordWrap(false);label:SetJustifyH("LEFT");label:SetText(text)
    return label
end
local function Button(parent,text,x,y,width,callback)
    local button=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);button:SetSize(width,24);button:SetText(text);button:SetScript("OnClick",callback)
    return button
end
local function Fill(parent,r,g,b,a)
    local texture=parent:CreateTexture(nil,"BACKGROUND");texture:SetAllPoints(parent);texture:SetColorTexture(r,g,b,a);return texture
end
local function Box(parent,x,y,width)
    local box=CreateFrame("EditBox",nil,parent,"InputBoxTemplate")
    box:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);box:SetSize(width,24);box:SetAutoFocus(false);box:SetMaxLetters(2048)
    box:SetScript("OnEscapePressed",function(self)self:ClearFocus()end);return box
end
local function Inset(parent,y,height)
    local frame=CreateFrame("Frame",nil,parent,"InsetFrameTemplate")
    frame:SetPoint("TOPLEFT",parent,"TOPLEFT",12,y);frame:SetSize(766,height);return frame
end
local function Dialog(name,title,height)
    local frame=CreateFrame("Frame",name,UIParent,"PortraitFrameTemplate")
    frame:SetSize(500,height);frame:SetPoint("CENTER",UIParent,"CENTER",0,0);frame:SetFrameStrata("DIALOG");frame:SetClampedToScreen(true)
    frame:SetTitle(title);frame.CloseButton:SetScript("OnClick",function()frame:Hide()end)
    U.ManageWindow(frame);table.insert(UISpecialFrames,name);frame:Hide();return frame
end
local function HideTooltip()if GameTooltip then GameTooltip:Hide()end end
local function Message(text)
    E.messages.watch=text;if UI.editorMessage and UI.editor:IsShown()then UI.editorMessage:SetText(text)end;E.Refresh();return false
end
function UI.Name(row)
    return U.String(row.name) and not row.name:match("^Item %d+$") and row.name or "Item data loading"
end

function UI.View()
    local settings=D.Settings()
    local key=table.concat({W.publications,W.metadataRevision,settings.watchSort,tostring(settings.watchSortDesc),tostring(settings.watchReadyOnly),tostring(W.Current()),UI.search},"|")
    if UI.viewKey==key then return UI.view end
    local rows={};local words={}
    for word in UI.search:lower():gmatch("%S+")do words[#words+1]=word end
    for _,row in ipairs(W.rows)do
        local matches=not settings.watchReadyOnly or row.matched and W.Current()
        local name=UI.Name(row):lower()
        for _,word in ipairs(words)do if not name:find(word,1,true)then matches=false;break end end
        if matches then rows[#rows+1]=row end
    end
    local sort=settings.watchSort
    local function Value(row)
        if sort=="name"then return UI.Name(row):lower()end
        if sort=="status"then return ranks[row.status]or 6 end
        if sort=="target"then return row.watch.maxBuy>0 and row.watch.maxBuy or nil end
        return row[sort]
    end
    table.sort(rows,function(a,b)
        local x,y=Value(a),Value(b)
        if x~=y then
            if x==nil then return false end;if y==nil then return true end
            if settings.watchSortDesc then return x>y else return x<y end
        end
        if sort=="status"then
            x,y=a.targetGap or -math.huge,b.targetGap or -math.huge
            if x~=y then return x>y end
            x,y=a.profit or -math.huge,b.profit or -math.huge
            if x~=y then return x>y end
        end
        x,y=UI.Name(a):lower(),UI.Name(b):lower()
        return x~=y and x<y or x==y and a.key<b.key
    end)
    UI.view,UI.viewKey=rows,key;return rows
end
function UI.Sort(key)
    if U.Combat()then return end
    local settings=D.Settings()
    if settings.watchSort==key then settings.watchSortDesc=not settings.watchSortDesc
    else settings.watchSort=key;settings.watchSortDesc=key=="profit"or key=="roi"end
    UI.offset=0;HideTooltip();E.Refresh()
end
function UI.Scroll(offset)
    if not U.Number(offset,0,100000)then return end
    UI.offset=math.max(0,math.min(math.floor(offset),math.max(0,#UI.View()-ROWS)))
    HideTooltip();E.Refresh()
end
local function Wheel(_,delta)
    if U.Number(delta,-100,100)then UI.Scroll(math.max(0,UI.offset-delta*3))end
end
function UI.Open(row)
    if not row then return Message("Choose a watched item first.")end
    E.selectedWatch=row.key
    if W.job then return Message("Wait for the updated watchlist results.")end
    if A.MarketUI.OpenListings(row,"watch")then E.frame:Hide();return true end
    return Message(A.MarketUI.message)
end

function UI.Tooltip(button,row)
    if not GameTooltip then return end
    GameTooltip:SetOwner(button,"ANCHOR_RIGHT");GameTooltip:ClearLines()
    GameTooltip:AddLine(UI.Name(row),U.ItemColor(row.link,row.quality))
    GameTooltip:AddLine(row.suffix~=nil and "Exact modifier"or"Any modifier / item-wide prices",.61,.66,.70)
    GameTooltip:AddDoubleLine("Scan each",row.current and U.Coins(row.current)or"Unavailable")
    GameTooltip:AddDoubleLine("Buy at or below",row.watch.maxBuy>0 and U.Coins(row.watch.maxBuy)or"Off")
    GameTooltip:AddDoubleLine("Minimum return",row.watch.minReturn.."%")
    GameTooltip:AddDoubleLine("Minimum profit",U.Coins(row.watch.minProfit))
    if row.profit then GameTooltip:AddDoubleLine("Estimated net / item",A.CraftingUI.SignedMoney(row.profit))end
    if row.targetGap then GameTooltip:AddDoubleLine("Below buy target",string.format("%+.1f%%",row.targetGap))end
    GameTooltip:AddDoubleLine("Earlier priced UTC days",row.days.." / "..D.Settings().marketMinDays)
    if row.units then GameTooltip:AddDoubleLine("Listed units in scan",tostring(row.units))end
    GameTooltip:AddLine(row.status)
    GameTooltip:AddLine("Left-click: Buy page. Right-click or Edit: targets.",.61,.66,.70,true);GameTooltip:Show()
end

function UI.HideChildren()
    if UI.editor then UI.editor:Hide()end;if UI.settings then UI.settings:Hide()end
end
function UI.Edit(row)
    if U.Combat()then return Message("Edit watchlists outside combat.")end
    E.selectedWatch=row.key;UI.input=row.suffix~=nil and row.link or row.id;UI.editorMarket=U.MarketKey()
    local v=E.watchInputs
    v.item:SetText(tostring(UI.input));v.item:Hide();v.item:ClearFocus()
    E.watchItemLabel:SetText(UI.Name(row));E.watchItemLabel:SetTextColor(U.ItemColor(row.link,row.quality))
    UI.source:SetText(row.suffix~=nil and "Exact modifier"or"Any modifier / item-wide prices")
    v.itemPrice:SetText(U.GoldText(row.watch.maxBuy));v.roi:SetText(tostring(row.watch.minReturn));v.profit:SetText(U.GoldText(row.watch.minProfit))
    UI.editorMessage:SetText("All enabled targets must pass. Zero turns a target off.")
    UI.remove:Show();UI.editor:Show();U.FocusWindow(UI.editor);E.Refresh()
end
function UI.New()
    if U.Combat()then return Message("Edit watchlists outside combat.")end
    UI.input,UI.editorMarket,E.selectedWatch=nil,U.MarketKey(),nil
    E.watchItemLabel:SetText("Add a watched item");E.watchItemLabel:SetTextColor(.90,.89,.84)
    UI.source:SetText("Paste or drag an item link, or use Watch item on the Buy page.")
    local v=E.watchInputs;v.item:SetText("");v.item:Show();v.itemPrice:SetText("0");v.roi:SetText("0");v.profit:SetText("0")
    UI.editorMessage:SetText("Price and profit targets are gold amounts per item.")
    UI.remove:Hide();UI.editor:Show();U.FocusWindow(UI.editor);v.item:SetFocus()
end
function UI.Draft(row,source)
    if not row or U.Combat()then return end
    E.Show("watch")
    local key=row.variantKey or(row.suffix~=nil and U.VariantKey(row.link))or(row.id..":"..(row.suffix~=nil and row.suffix or"*"))
    local existing
    for _,watch in ipairs(W.Entries())do if watch.key==key then existing=watch.entry;break end end
    UI.Edit({key=key,id=row.id,suffix=row.suffix,link=row.link,name=row.name,quality=U.ItemQuality(row.link),watch=existing or {
        maxBuy=math.min(100000000,math.floor(row.maxBuy or row.buy or 0)),
        minReturn=source=="buy"and 0 or D.Settings().marketMinReturn,minProfit=source=="buy"and 0 or D.Settings().marketMinProfit}})
    if not existing then E.selectedWatch=nil;UI.remove:Hide()end
end
function UI.Save()
    if U.Combat()then return Message("Edit watchlists outside combat.")end
    if UI.editorMarket~=U.MarketKey()then return Message("The market changed. Select the item again.")end
    local v=E.watchInputs;local input=UI.input or v.item:GetText()
    if not UI.input and not U.ItemID(input)then return Message("Paste or drag an item link, or use Watch item on the Buy page.")end
    local buy,roi,profit=U.ParseGold(v.itemPrice:GetText()),tonumber(v.roi:GetText()),U.ParseGold(v.profit:GetText())
    local ok,key=W.Save(input,buy,roi,profit)
    if not ok then return Message(key)end
    E.selectedWatch=key;E.messages.watch="Watch saved. All enabled targets must pass."
    UI.editor:Hide();W.Ensure();UI.viewKey=nil;E.Refresh();return true
end
function UI.Drop()
    if U.Combat()or UI.input or type(GetCursorInfo)~="function"then return end
    local data={pcall(GetCursorInfo)}
    if data[1] and U.String(data[2]) and data[2]=="item"and U.ItemID(data[4])then
        E.watchInputs.item:SetText(data[4]);U.Call(ClearCursor)
    end
end

function UI.ShowSettings()
    if U.Combat()then return end
    UI.CreateSettings()
    for key,button in pairs(UI.checks)do button:SetChecked(D.Settings()[key])end
    UI.settings:Show();U.FocusWindow(UI.settings)
end
function UI.CreateSettings()
    if UI.settings then return end
    local frame=Dialog("MSMarketValueWatchSettings","MS Market Value - Watchlist settings",280);UI.settings=frame;UI.checks={}
    local definitions={{"watchAlerts","Watchlist alerts"},{"watchOpenOnScan","Open watchlist after a scan finds targets"},
        {"watchOpenOnAH","Open watchlist when visiting the AH"},{"watchChatAlerts","Also show one chat summary"}}
    for index,definition in ipairs(definitions)do
        local key=definition[1];local button=CreateFrame("CheckButton",nil,frame,"UICheckButtonTemplate")
        button:SetPoint("TOPLEFT",frame,"TOPLEFT",18,-42-(index-1)*34);button:SetSize(26,26)
        Label(frame,definition[2],50,-49-(index-1)*34,420)
        button:SetScript("OnClick",function(self)
            if not U.Combat()then D.Settings()[key]=self:GetChecked()==true end
            self:SetChecked(D.Settings()[key])
        end);UI.checks[key]=button
    end
    local help=Label(frame,"New matches and lower matched prices are grouped into one review. Unchanged prices stay quiet. Alerts wait while you sell or edit.",22,-193,452)
    help:SetSize(452,42);help:SetWordWrap(true);help:SetTextColor(.61,.66,.70)
    Button(frame,"Done",370,-242,100,function()frame:Hide()end)
end

function UI.Create(parent)
    local panel=CreateFrame("Frame",nil,parent);panel:SetAllPoints(parent);E.watchPanel=panel
    local toolbar=Inset(panel,-98,68)
    Label(toolbar,"Search",14,-15,50);UI.searchBox=Box(toolbar,68,-10,225);UI.searchBox:SetMaxLetters(100)
    UI.searchBox:SetScript("OnTextChanged",function(self)
        UI.search=self:GetText();UI.offset=0;E.Refresh()
    end)
    UI.only=CreateFrame("CheckButton",nil,toolbar,"UICheckButtonTemplate");UI.only:SetPoint("TOPLEFT",toolbar,"TOPLEFT",316,-9);UI.only:SetSize(26,26)
    UI.only:SetScript("OnClick",function(self)D.Settings().watchReadyOnly=self:GetChecked()==true;UI.offset=0;E.Refresh()end)
    Label(toolbar,"Targets met only",348,-16,160)
    Button(toolbar,"Add watch",630,-10,118,UI.New)
    UI.summary=Label(toolbar,"",14,-44,730)
    local list=Inset(panel,-176,334);UI.list=list;list:EnableMouseWheel(true);list:SetScript("OnMouseWheel",Wheel)
    for _,column in ipairs(columns)do
        local key=column[2];local button=CreateFrame("Button",nil,list)
        button:SetPoint("TOPLEFT",list,"TOPLEFT",column[3]+10,-5);button:SetSize(column[4],20)
        button.text=Label(button,column[1],0,-2,column[4]);button.text:SetFontObject("GameFontNormalSmall")
        button.text:SetJustifyH(column[5]and"RIGHT"or"LEFT")
        button:SetScript("OnClick",function()UI.Sort(key)end);UI.headers[key]=button
    end
    for index=1,ROWS do
        local button=CreateFrame("Button",nil,list);button:SetPoint("TOPLEFT",list,"TOPLEFT",10,-31-(index-1)*STEP);button:SetSize(724,STEP-1)
        Fill(button,.12,.13,.15,index%2==0 and .5 or .15)
        button.ready=Fill(button,.12,.34,.19,.42);button.ready:Hide()
        button.highlight=Fill(button,.72,.55,.20,.16);button.highlight:Hide()
        button.labels={}
        for number,column in ipairs(columns)do
            local label=Label(button,"",column[3],-6,column[4]);label:SetJustifyH(column[5]and"RIGHT"or"LEFT");button.labels[number]=label
        end
        button.labels[6]:SetFontObject("GameFontNormalSmall")
        button.edit=Button(button,"Edit",684,-2,38,function()if button.row then UI.Edit(button.row)end end)
        button:RegisterForClicks("LeftButtonUp","RightButtonUp")
        button:SetScript("OnClick",function(self,mouse)
            if self.row then if mouse=="RightButton"then UI.Edit(self.row)else UI.Open(self.row)end end
        end)
        button:SetScript("OnEnter",function(self)self.highlight:Show();if self.row then UI.Tooltip(self,self.row)end end)
        button:SetScript("OnLeave",function(self)self.highlight:Hide();HideTooltip()end)
        button:EnableMouseWheel(true);button:SetScript("OnMouseWheel",Wheel);UI.rows[index]=button
    end
    E.watchRows=UI.rows
    UI.scrollbar=CreateFrame("Slider",nil,list,"UIPanelScrollBarTemplate")
    UI.scrollbar:SetPoint("TOPRIGHT",list,"TOPRIGHT",-4,-41);UI.scrollbar:SetPoint("BOTTOMRIGHT",list,"BOTTOMRIGHT",-4,19)
    UI.scrollbar:SetWidth(16);UI.scrollbar:SetValueStep(1);UI.scrollbar:SetObeyStepOnDrag(true)
    UI.scrollbar:SetScript("OnValueChanged",function(_,value)if not UI.syncScroll then UI.Scroll(value)end end)
    UI.empty=Label(list,"",24,-103,690);UI.empty:SetSize(690,70);UI.empty:SetWordWrap(true)
    UI.count=Label(panel,"",18,-525,730)
    E.watchDetail=Label(panel,"Left-click an item for its Buy page. Right-click or Edit to change targets.",18,-550,740)
    UI.editor=Dialog("MSMarketValueWatchEditor","MS Market Value - Watch targets",282)
    E.watchItemLabel=Label(UI.editor,"",22,-43,452);E.watchItemLabel:SetHeight(20)
    UI.source=Label(UI.editor,"",22,-68,452);UI.source:SetTextColor(.61,.66,.70)
    E.watchInputs={item=Box(UI.editor,28,-94,444),itemPrice=Box(UI.editor,28,-149,132),roi=Box(UI.editor,190,-149,110),profit=Box(UI.editor,330,-149,142)}
    local inputs=E.watchInputs;inputs.item:SetScript("OnReceiveDrag",UI.Drop)
    inputs.item:SetScript("OnTextChanged",function(self)
        if not UI.input then
            local valid=U.ItemID(self:GetText())
            E.watchItemLabel:SetText(valid and(U.LinkName(self:GetText())or"Selected item")or"Add a watched item")
            E.watchItemLabel:SetTextColor(U.ItemColor(valid and self:GetText()or nil,valid and U.ItemQuality(self:GetText())or nil))
        end
    end)
    Label(UI.editor,"Buy at or below "..U.coin.gold,22,-128,145);Label(UI.editor,"Min return %",184,-128,120);Label(UI.editor,"Min profit "..U.coin.gold,324,-128,145)
    UI.editorMessage=Label(UI.editor,"",22,-188,452);UI.editorMessage:SetSize(452,38);UI.editorMessage:SetWordWrap(true)
    UI.remove=Button(UI.editor,"Remove watch",22,-239,128,function()
        if W.Remove(E.selectedWatch)then E.selectedWatch=nil;UI.editor:Hide();W.Ensure();UI.viewKey=nil;E.Refresh()end
    end)
    Button(UI.editor,"Cancel",260,-239,98,function()UI.editor:Hide()end);Button(UI.editor,"Save watch",370,-239,108,UI.Save)
    UI.editor:SetScript("OnHide",function()for _,input in pairs(E.watchInputs)do input:ClearFocus()end end)
end

function UI.Refresh()
    UI.only:SetChecked(D.Settings().watchReadyOnly)
    local rows=UI.View();UI.offset=math.max(0,math.min(UI.offset,math.max(0,#rows-ROWS)))
    local current=W.Current();local matched=W.MatchCount()
    UI.summary:SetText(matched.." target"..(matched==1 and""or"s").." met  |  "..#W.rows.." watched"..(W.job and"  |  Updating..."or""))
    for index,button in ipairs(UI.rows)do
        local row=rows[UI.offset+index];button.row=row
        if row then
            local ready=row.matched and current
            local status=W.job and"Updating"or row.status=="More history needed"and(row.days.."/"..D.Settings().marketMinDays.." days")or
                row.status=="Fresh scan needed"and"Scan needed"or row.status=="Not listed"and"Not listed"or row.status=="Tracking only"and"Tracking"or row.status
            if not current and not W.job and row.matched then status="Scan needed"end
            local values={UI.Name(row),row.current and U.Coins(row.current)or"--",row.watch.maxBuy>0 and U.Coins(row.watch.maxBuy)or"Off",
                row.profit and A.CraftingUI.SignedMoney(row.profit)or"--",row.roi and string.format("%+.0f%%",row.roi)or"--",status}
            for number,value in ipairs(values)do button.labels[number]:SetText(value);button.labels[number]:SetTextColor(.90,.89,.84)end
            button.labels[1]:SetTextColor(U.ItemColor(row.link,row.quality))
            button.labels[6]:SetTextColor(ready and .35 or .61,ready and .95 or .66,ready and .48 or .70)
            if ready then button.ready:Show()else button.ready:Hide()end
            button.edit:SetEnabled(not U.Combat());button:Show()
        else button:Hide()end
    end
    for key,header in pairs(UI.headers)do
        local active=D.Settings().watchSort==key
        header.text:SetTextColor(active and 1 or .72,active and .82 or .73,active and 0 or .70)
    end
    UI.syncScroll=true;UI.scrollbar:SetMinMaxValues(0,math.max(0,#rows-ROWS));UI.scrollbar:SetValue(UI.offset);UI.syncScroll=false
    if #rows>ROWS then UI.scrollbar:Show()else UI.scrollbar:Hide()end
    if #rows==0 then
        UI.empty:SetText(W.job and"Checking targets from the saved scan..."or #W.rows==0 and"Your watchlist is empty. Use Watch item on the Buy page, Watch selected on Opportunities, or Add watch with an item link."or"No watches match these filters.")
        UI.empty:Show()
    else UI.empty:Hide()end
    local sorted=D.Settings().watchSort
    for _,column in ipairs(columns)do if column[2]==sorted then sorted=column[1];break end end
    UI.count:SetText((#rows>0 and(UI.offset+1).."-"..math.min(UI.offset+ROWS,#rows)or"0").." / "..#rows.." shown  |  Sort: "..sorted..(D.Settings().watchSortDesc and" (descending)"or" (ascending)"))
    E.status:SetText(W.reason or E.messages.watch or"Targets use saved asking prices. Profit and return include the configured AH cut; verify live listings before buying.")
    if E.frame:IsShown()and not UI.editor:IsShown()and current then W.Acknowledge()end
end

function UI.CanAlert(open)
    local ah=AuctionHouseFrame
    if not U.Table(ah)or ah.IsForbidden and ah:IsForbidden()or U.Call(ah.IsShown,ah)~=true then return false end
    if U.Table(ah.BuyDialog)and U.Call(ah.BuyDialog.IsShown,ah.BuyDialog)==true then return false end
    if not open then return true end
    if A.Scanner.active or A.MarketUI.pendingVariant then return false end
    for _,frame in ipairs({UI.editor or false,UI.settings or false,E.editorFrame or false,E.csvFrame or false,A.UI.frame or false,A.CraftingUI.frame or false})do
        if frame and frame:IsShown()then return false end
    end
    if E.frame and E.frame:IsShown()and E.mode~="watch"then return false end
    if U.Call(GetCurrentKeyBoardFocus)then return false end
    for _,name in ipairs({"ItemSellFrame","CommoditiesSellFrame"})do
        local frame=ah[name];if U.Table(frame)and U.Call(frame.IsVisible,frame)==true then return false end
    end
    return true
end
function UI.OpenAlert(matches)
    if E.frame and E.frame:IsShown()and E.mode=="watch"then E.Refresh();return false end
    E.Show("watch")
    UI.searchBox:ClearFocus()
    local rows=UI.View()
    local visible=false
    for _,row in ipairs(rows)do for _,match in ipairs(matches)do if row.key==match.key then visible=true;break end end;if visible then break end end
    if not visible and UI.search~=""then UI.searchBox:SetText("");rows=UI.View()end
    for index,row in ipairs(rows)do
        local found=false;for _,match in ipairs(matches)do if row.key==match.key then found=true;break end end
        if found then UI.offset=math.max(0,index-1);break end
    end
    E.Refresh();return true
end
function UI.UpdateBadge()
    local count=W.MatchCount()
    if A.MarketUI.watchButton then A.MarketUI.watchButton:SetText(count>0 and("Watchlists ("..count..")")or"Watchlists")end
end
