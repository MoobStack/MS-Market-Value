local _, A = ...
local U, D, F, P = A.Util, A.DB, A.Farm, A.Drops
local UI={page="session",view="items",historyIndex=0,listPage=1,source="all"}
A.FarmingUI=UI
local sourceLabels={all="All sources",loot="Loot",quest="Quests",harvesting="Harvesting",
    herbalism="Herbalism",mining="Mining",skinning="Skinning"}

local function Label(parent,text,x,y,width,normal)
    local font=parent:CreateFontString(nil,"OVERLAY",normal and "GameFontNormal" or "GameFontHighlightSmall")
    font:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);font:SetSize(width,18);font:SetJustifyH("LEFT")
    font:SetWordWrap(false);font:SetText(text);return font
end
local function Button(parent,text,x,y,width,callback)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);b:SetSize(width,24);b:SetText(text);b:SetScript("OnClick",callback);return b
end
local function Check(parent,text,key,x,y,width)
    local b=CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate")
    b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);b:SetSize(26,26)
    Label(parent,text,x+29,y-5,width or 530)
    b:SetScript("OnClick",function(self)
        if key=="farmIdle" then F.ConfigureIdle(self:GetChecked()==true,D.Settings().farmIdleMinutes)
        else D.data.settings[key]=self:GetChecked()==true end
        F.summary=nil;UI.Refresh();UI.HUD()
    end)
    b.key=key;UI.checks[#UI.checks+1]=b;return b
end
local function Box(parent,x,y,width)
    local b=CreateFrame("EditBox",nil,parent,"InputBoxTemplate")
    b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);b:SetSize(width,24);b:SetAutoFocus(false);b:SetMaxLetters(80)
    b:SetScript("OnEscapePressed",function(self)self:ClearFocus()end);return b
end
local function Panel(parent)
    local panel=CreateFrame("Frame",nil,parent,"InsetFrameTemplate")
    panel:SetPoint("TOPLEFT",parent,"TOPLEFT",12,-72);panel:SetSize(656,414);return panel
end

function UI.HUD()
    if not D.data or A.disabledReason then return end
    if not UI.hud then
        local frame=CreateFrame("Button","MSMarketValueFarmHUD",UIParent,"BackdropTemplate")
        frame:SetSize(188,52);frame:SetClampedToScreen(true);frame:SetMovable(true);frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton");frame:RegisterForClicks("LeftButtonUp","RightButtonUp")
        frame:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=12,
            insets={left=3,right=3,top=3,bottom=3}})
        frame:SetBackdropColor(.04,.035,.025,.88);frame:SetBackdropBorderColor(.62,.48,.20,.9)
        local pos=D.data.farmHUD
        if U.Table(pos) and U.Number(pos.x,-10000,10000) and U.Number(pos.y,-10000,10000) then frame:SetPoint("CENTER",UIParent,"CENTER",pos.x,pos.y)
        else frame:SetPoint("TOP",UIParent,"TOP",0,-100) end
        UI.hudRate=Label(frame,"MS Farming",12,-8,164,true)
        UI.hudTotal=Label(frame,"Starting session...",12,-29,164)
        frame:SetScript("OnDragStart",function(self)self.dragging=true;self:StartMoving()end)
        frame:SetScript("OnDragStop",function(self)
            self:StopMovingOrSizing();self.dragging=false
            local x,y=self:GetCenter();local px,py=UIParent:GetCenter()
            if U.Number(x) and U.Number(y) and U.Number(px) and U.Number(py) then D.data.farmHUD={x=x-px,y=y-py} end
        end)
        frame:SetScript("OnEnter",function()UI.hovered=true;UI.HUD()end)
        frame:SetScript("OnLeave",function()UI.hovered=false;UI.HUD()end)
        frame:SetScript("OnClick",function(self,mouse)
            if self.dragging then return end
            if mouse=="RightButton" then local summary=F.Summary();F.Pause(not summary.paused) else UI.Show("session") end
        end)
        UI.hud=frame
    end
    if D.Settings().farmShow then UI.hud:Show() else UI.hud:Hide() end
    UI.hud:SetAlpha(D.Settings().farmHover and not UI.hovered and 0 or 1)
end

function UI.Animate(elapsed)
    local display=UI.hud and UI.hud:IsVisible() and (not D.Settings().farmHover or UI.hovered)
    if not display and not (UI.frame and UI.frame:IsVisible()) then return end
    if not U.Number(elapsed,0,60) then return end
    UI.animationElapsed=(UI.animationElapsed or 0)+elapsed
    if UI.animationElapsed<.1 then return end
    local dt=UI.animationElapsed;UI.animationElapsed=0
    local summary=F.Summary()
    local factor=1-math.exp(-dt/1.2)
    UI.displayRate=(UI.displayRate or 0)+(summary.perHour-(UI.displayRate or 0))*factor
    UI.displayTotal=(UI.displayTotal or 0)+(summary.total-(UI.displayTotal or 0))*factor
    if UI.hudRate then
        UI.hudRate:SetText(summary.elapsed<60 and "Farming - first minute" or (U.Coins(UI.displayRate) .. " / hour"))
        UI.hudTotal:SetText((summary.idlePaused and "Idle | " or summary.paused and "Paused | " or "Est. ") .. U.Coins(UI.displayTotal) .. " | " .. math.floor(summary.elapsed/60) .. "m")
    end
    UI.refreshElapsed=(UI.refreshElapsed or 0)+dt
    if UI.refreshElapsed>=1 then UI.refreshElapsed=0;if UI.frame and UI.frame:IsShown() then UI.Refresh() end end
end

function UI.Create()
    if UI.frame then return end
    local frame=CreateFrame("Frame","MSMarketValueFarming",UIParent,"PortraitFrameTemplate")
    frame:SetSize(680,510);frame:SetPoint("CENTER");frame:SetClampedToScreen(true)
    frame:SetFrameStrata("DIALOG")
    if frame.PortraitContainer and frame.PortraitContainer.portrait then
        frame.PortraitContainer.portrait:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
    end
    if frame.SetTitle then frame:SetTitle("MS Market Value - Farming & drops") end
    frame:SetMovable(true);frame:EnableMouse(true);frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart",function(self)self:StartMoving()end);frame:SetScript("OnDragStop",function(self)self:StopMovingOrSizing()end)
    if frame.CloseButton then frame.CloseButton:SetScript("OnClick",function()frame:Hide()end) end
    UISpecialFrames[#UISpecialFrames+1]="MSMarketValueFarming"
    UI.frame=frame;UI.tabs={}
    for i,entry in ipairs({{"session","Session"},{"settings","Farming settings"},{"drops","Drop rates"}}) do
        local page=entry[1]
        UI.tabs[page]=Button(frame,entry[2],16+(i-1)*212,-39,204,function()UI.page=page;UI.Refresh()end)
    end
    UI.session=Panel(frame);UI.settings=Panel(frame);UI.drops=Panel(frame)
    local session=UI.session
    UI.rate=Label(session,"",14,-12,350,true)
    UI.total=Label(session,"",14,-37,626,true)
    UI.categoryTotals={};UI.categoryNotes={}
    for i,title in ipairs({"Loot","Quests","Harvesting"}) do
        local x=14+(i-1)*211
        Label(session,title,x,-66,200,true)
        UI.categoryTotals[i]=Label(session,"",x,-85,200)
        UI.categoryNotes[i]=Label(session,"",x,-104,200)
    end
    UI.pause=Button(session,"Pause",430,-12,98,function()F.Pause(not F.Summary().paused);UI.Refresh()end)
    UI.reset=Button(session,"Reset session",536,-12,106,function()
        if not UI.confirmSession then UI.confirmSession=true;UI.reset:SetText("Confirm reset");return end
        UI.confirmSession=false;local ok,reason=F.Reset();UI.message=reason;UI.displayRate,UI.displayTotal=0,0;UI.Refresh()
    end)
    UI.itemsButton=Button(session,"Items",14,-133,98,function()UI.view="items";UI.historyIndex=0;UI.listPage=1;UI.Refresh()end)
    UI.recentButton=Button(session,"Recent pickups",120,-133,130,function()UI.view="recent";UI.historyIndex=0;UI.listPage=1;UI.Refresh()end)
    UI.historyButton=Button(session,"Previous sessions",258,-133,142,function()
        local profile=F.Profile();local count=profile and #profile.history or 0
        if count>0 then UI.historyIndex=UI.historyIndex%count+1;UI.view="history";UI.listPage=1 end;UI.Refresh()
    end)
    UI.sourceMenu=CreateFrame("DropdownButton",nil,session,"WowStyle1DropdownTemplate")
    UI.sourceMenu:SetPoint("TOPLEFT",session,"TOPLEFT",410,-133);UI.sourceMenu:SetSize(230,24)
    if UI.sourceMenu.SetupMenu then UI.sourceMenu:SetupMenu(function(_,root)
        for _,key in ipairs({"all","loot","quest","harvesting","herbalism","mining","skinning"}) do
            local source=key
            root:CreateRadio(sourceLabels[source],function()return UI.source==source end,function()
                UI.source=source;UI.listPage=1;UI.Refresh()
            end)
        end
    end) end
    UI.breakdownTitle=Label(session,"",14,-166,626,true)
    UI.lines={}
    for i=1,7 do UI.lines[i]=Label(session,"",14,-191-(i-1)*21,626) end
    UI.prev=Button(session,"Previous",14,-344,98,function()UI.listPage=UI.listPage-1;UI.Refresh()end)
    UI.pageText=Label(session,"",126,-350,360)
    UI.next=Button(session,"Next",542,-344,98,function()UI.listPage=UI.listPage+1;UI.Refresh()end)
    UI.note=Label(session,"",14,-376,626);UI.note:SetHeight(34);UI.note:SetWordWrap(true)
    UI.checks={}
    local settings=UI.settings
    Label(settings,"Acquisition value, not sale proceeds or net cash flow.",14,-12,626,true)
    Check(settings,"Track farming sessions","farmTracking",14,-41)
    Check(settings,"Show the small farming display","farmShow",14,-75)
    Check(settings,"Hide the display until the cursor is over it","farmHover",14,-109)
    Check(settings,"Use current AH value after the configured AH cut","farmUseAuction",14,-143)
    Check(settings,"Include quest gold and received reward items","farmIncludeQuest",14,-177)
    Label(settings,"Use AH value only when it beats vendor value by",18,-223,390)
    UI.threshold=Box(settings,410,-216,70);UI.threshold:SetNumeric(true)
    Label(settings,"%",490,-223,24)
    Button(settings,"Apply",534,-216,104,function()
        local value=tonumber(UI.threshold:GetText())
        if not U.Number(value,0,1000,true) then UI.message="Enter a threshold from 0 to 1000%.";UI.Refresh();return end
        D.data.settings.farmThreshold=value;UI.threshold:ClearFocus();F.summary=nil;UI.message=nil;UI.Refresh()
    end)
    UI.idleCheck=Check(settings,"Auto-pause after no loot","farmIdle",14,-254,232)
    UI.idleMinutes=Box(settings,264,-254,58);UI.idleMinutes:SetNumeric(true)
    Label(settings,"minutes (5-60)",336,-261,183)
    UI.applyIdle=Button(settings,"Apply",534,-254,104,function()
        local ok,reason=F.ConfigureIdle(D.Settings().farmIdle,tonumber(UI.idleMinutes:GetText()))
        UI.message=reason
        if ok then UI.idleMinutes:ClearFocus() end
        UI.Refresh()
    end)
    local help=Label(settings,"Quest rewards and bound items use vendor value; stale AH data falls back to the vendor.\n\nIdle pause counts the full grace period. Your next loot, harvest or included quest reward resumes it. Manual pauses stay paused. Drag the display to move it; right-click to pause or resume.",18,-302,616)
    help:SetHeight(77);help:SetWordWrap(true)
    UI.settingsStatus=Label(settings,"",18,-388,616)
    local drops=UI.drops
    Check(drops,"Collect personal loot observations","dropTracking",14,-10)
    Check(drops,"Show drop tooltips","showDrops",14,-44,265)
    Check(drops,"Include harvesting tooltips","showHarvestDrops",320,-44,285)
    Label(drops,"Display",18,-91,80)
    UI.mode=CreateFrame("DropdownButton",nil,drops,"WowStyle1DropdownTemplate")
    UI.mode:SetPoint("TOPLEFT",drops,"TOPLEFT",108,-83);UI.mode:SetSize(274,25)
    if UI.mode.SetupMenu then
        UI.mode:SetupMenu(function(_,root)
            for _,entry in ipairs({{"observed","Personal drops"},{"reference","Reference data"}}) do
                local mode=entry[1]
                root:CreateRadio(entry[2],function()return D.Settings().dropMode==mode end,function()
                    D.data.settings.dropMode=mode;P.cache=nil;UI.Refresh()
                end)
            end
        end)
    end
    Label(drops,"Max items",400,-91,80)
    UI.maxDrops=Box(drops,480,-84,50);UI.maxDrops:SetNumeric(true)
    Button(drops,"Apply",542,-84,96,function()
        local count=tonumber(UI.maxDrops:GetText())
        if U.Number(count,1,10,true) then D.data.settings.dropRows=count;UI.maxDrops:ClearFocus();UI.message=nil
        else UI.message="Choose 1-10 tooltip items." end
        UI.Refresh()
    end)
    UI.reference=Label(drops,"",18,-127,616);UI.reference:SetHeight(48);UI.reference:SetWordWrap(true)
    local desc=Label(drops,"Needed quest items come first, then expected item value. Personal rates use inspected corpses or harvests, including visible group loot. Herbs, ore and skinning have separate samples; unseen kills are not counted.",18,-179,616)
    desc:SetHeight(55);desc:SetWordWrap(true)
    Label(drops,"Reset personal observations",18,-244,400,true)
    UI.scope=CreateFrame("DropdownButton",nil,drops,"WowStyle1DropdownTemplate")
    UI.scope:SetPoint("TOPLEFT",drops,"TOPLEFT",18,-270);UI.scope:SetSize(212,25)
    UI.resetScope="monster"
    if UI.scope.SetupMenu then UI.scope:SetupMenu(function(_,root)
        for _,entry in ipairs({{"monster","Creature / node name or ID"},{"zone","Current zone"},{"dungeon","Current dungeon"},{"all","All my observations"}}) do
            local scope=entry[1]
            root:CreateRadio(entry[2],function()return UI.resetScope==scope end,function()UI.resetScope=scope;UI.confirmDrops=false;UI.Refresh()end)
        end
    end) end
    UI.monster=Box(drops,244,-270,254)
    UI.monster:SetScript("OnTextChanged",function(_,user)
        if user then UI.confirmDrops=false;UI.clearDrops:SetText("Reset selected") end
    end)
    UI.clearDrops=Button(drops,"Reset selected",510,-270,128,function()
        if not UI.confirmDrops then UI.confirmDrops=true;UI.clearDrops:SetText("Confirm reset");return end
        UI.confirmDrops=false;local ok,reason=P.Reset(UI.resetScope,UI.monster:GetText());UI.message=reason;UI.Refresh()
    end)
    UI.dropStatus=Label(drops,"",18,-314,616);UI.dropStatus:SetHeight(78);UI.dropStatus:SetWordWrap(true)
    frame:SetScript("OnHide",function()UI.confirmSession,UI.confirmDrops=false,false end)
    U.ManageWindow(frame)
    frame:Hide()
end

function UI.Refresh()
    if not UI.frame or not D.data then return end
    for page,button in pairs(UI.tabs) do
        button:SetEnabled(UI.page~=page)
        if UI.page==page then UI[page]:Show() else UI[page]:Hide() end
    end
    for _,box in ipairs(UI.checks) do box:SetChecked(D.Settings()[box.key]) end
    if not UI.threshold:HasFocus() then UI.threshold:SetText(tostring(D.Settings().farmThreshold)) end
    if not UI.maxDrops:HasFocus() then UI.maxDrops:SetText(tostring(D.Settings().dropRows)) end
    if not UI.idleMinutes:HasFocus() then UI.idleMinutes:SetText(tostring(D.Settings().farmIdleMinutes)) end
    UI.settingsStatus:SetText(UI.message or "Idle pause is optional. Offline and loading time are excluded.")
    if UI.mode.Update then UI.mode:Update() end
    if UI.scope.Update then UI.scope:Update() end
    if UI.sourceMenu.Update then UI.sourceMenu:Update() end
    UI.clearDrops:SetText(UI.confirmDrops and "Confirm reset" or "Reset selected")
    UI.reference:SetText("Reference: " .. A.LootReference.label .. ". Missing items use your personal rates, marked personal. Sample counts stay separate; server drop settings are not available.")
    local profile=P.Profile()
    UI.dropStatus:SetText(UI.message or P.reason or ((profile and profile.mobs or 0) .. " source records; " ..
        (profile and profile.cells or 0) .. " item counters. Reset affects this character only."))
    local summary=F.Summary()
    UI.rate:SetText(summary.elapsed<60 and "First minute - collecting a useful sample" or U.Coins(summary.perHour) .. " per hour")
    UI.total:SetText("Session value: " .. U.Coins(summary.total) .. " | " .. math.floor(summary.elapsed/60) .. "m " .. math.floor(summary.elapsed%60) .. "s")
    UI.categoryTotals[1]:SetText(U.Coins((summary.coins or 0)+(summary.lootValue or 0)))
    UI.categoryTotals[2]:SetText(U.Coins((summary.questCoins or 0)+(summary.questValue or 0)))
    UI.categoryTotals[3]:SetText(U.Coins(summary.harvestValue or 0))
    UI.categoryNotes[1]:SetText("Gold: " .. U.Coins(summary.coins or 0) .. " + items")
    UI.categoryNotes[2]:SetText("Gold: " .. U.Coins(summary.questCoins or 0) .. " + rewards")
    UI.categoryNotes[3]:SetText("Herbs, ore and skins")
    UI.pause:SetText(summary.paused and "Resume" or "Pause");UI.reset:SetText(UI.confirmSession and "Confirm reset" or "Reset session")
    local rows=UI.view=="recent" and summary.recent or summary.items
    UI.breakdownTitle:SetText(UI.view=="recent" and "Recent pickups - value when received" or "Item breakdown - current valuation")
    if UI.view=="history" then
        local farming=F.Profile()
        local history=farming and farming.history[UI.historyIndex]
        rows=history and history.top or {}
        UI.breakdownTitle:SetText(history and ("Session " .. UI.historyIndex .. ": " .. U.Coins(history.total) .. " in " ..
            math.floor(history.elapsed/60) .. "m - " .. date("%b %d %H:%M",history.startedAt)) or "No previous sessions")
    end
    local filtered={}
    for _,item in ipairs(rows) do
        if UI.source=="all" or item.source==UI.source or (UI.source=="harvesting" and F.Harvest(item.source)) then
            filtered[#filtered+1]=item
        end
    end
    rows=filtered
    local pages=math.max(1,math.ceil(#rows/#UI.lines))
    UI.listPage=math.max(1,math.min(UI.listPage,pages))
    UI.prev:SetEnabled(UI.listPage>1);UI.next:SetEnabled(UI.listPage<pages)
    UI.pageText:SetText("Page " .. UI.listPage .. " / " .. pages .. " | " .. #rows .. " entries")
    for i,label in ipairs(UI.lines) do
        local item=rows[(UI.listPage-1)*#UI.lines+i]
        if item then
            label:SetText((sourceLabels[item.source] and (sourceLabels[item.source] .. ": ") or "") ..
                (item.quantity and (item.quantity .. " x ") or "") .. item.name .. "  -  " ..
                U.Coins(item.total or item.amount) .. (item.mode and (" (" .. item.mode .. ")") or ""))
        else label:SetText(i==1 and "No recorded income yet." or "") end
    end
    UI.note:SetText(UI.message or F.reason or (summary.idlePaused and "Idle - the next loot, harvest or included quest reward resumes the session.") or (summary.unknown>0 and (summary.unknown .. " acquired items need item data; excluded from the estimate.") or
        "Items are valued once. Mail, trades and sale proceeds are excluded; cash flow stays in the ledger."))
end

function UI.Show(page)
    UI.Create();UI.page=page=="drops" and "drops" or page=="settings" and "settings" or "session"
    UI.Refresh();UI.frame:Show();U.FocusWindow(UI.frame)
end
