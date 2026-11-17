local _, A = ...
local U, D, F, P = A.Util, A.DB, A.Farm, A.Drops
local UI={page="session",view="items",historyIndex=0,offset=0,source="all"}
A.FarmingUI=UI
local sourceLabels={all="All sources",loot="Loot",quest="Quests",harvesting="Harvesting",
    herbalism="Herbalism",mining="Mining",skinning="Skinning"}
local dropSorts={{"rate_desc","Drop rate: high to low"},{"rate_asc","Drop rate: low to high"},{"value","Expected item value"}}

local function QualityLabel(quality)
    local name=_G["ITEM_QUALITY"..quality.."_DESC"]
    local r,g,b=U.ItemColor(nil,quality)
    return string.format("|cff%02x%02x%02x%s|r",math.floor(r*255+.5),math.floor(g*255+.5),math.floor(b*255+.5),
        U.String(name) and name or U.qualityNames[quality+1])
end

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
        elseif key=="farmPauseOnDeath" then F.ConfigureDeath(self:GetChecked()==true)
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
    panel:SetPoint("TOPLEFT",parent,"TOPLEFT",12,-72);panel:SetSize(736,584);return panel
end

local function RateText(summary,rate)
    local state=summary.idlePaused and "  |  Idle" or summary.paused and "  |  Paused" or
        summary.elapsed<60 and "  |  Starting" or ""
    return U.Coins(rate) .. " / h" .. state
end

local function Muted(font) font:SetTextColor(.61,.66,.70);return font end
local function Duration(seconds)
    return math.floor(seconds/3600) .. "h " .. math.floor(seconds/60)%60 .. "m " .. math.floor(seconds%60) .. "s"
end

local function SessionLabel(record,index)
    local minutes=math.floor(record.elapsed/60)
    local duration=minutes>=60 and (math.floor(minutes/60).."h "..(minutes%60).."m") or (minutes.."m")
    return "Saved session "..index..": "..date("%b %d %H:%M",record.startedAt).." · "..duration.." · "..U.Money(record.total)
end

function UI.SelectSession(index)
    local profile=F.Profile()
    local record
    if profile and U.Number(index,1,#profile.history,true) then record=profile.history[index] end
    UI.historyRecord,UI.historyIndex=record,record and index or 0
    UI.view,UI.offset=record and "history" or "items",0
    UI.confirmDelete,UI.manageMessage=nil,nil
    UI.confirmSession,UI.message=false,nil
    if UI.frame then UI.Refresh() end
    return U.Number(index,0,0,true) or record~=nil
end

function UI.Scroll(offset)
    if not U.Number(offset) or not UI.rows then return end
    UI.offset=math.max(0,math.min(math.floor(offset),math.max(0,#(UI.visibleItems or {})-#UI.rows)))
    if GameTooltip then GameTooltip:Hide() end
    UI.Refresh()
end

function UI.RefreshManagement()
    if not UI.manager or not UI.manager:IsShown() then return end
    local profile=F.Profile();local count=profile and #profile.history or 0
    local record=UI.historyRecord
    if UI.managerTarget~=record then UI.confirmDelete,UI.manageMessage=nil,nil;UI.managerTarget=record end
    UI.managerCount:SetText(count.." saved sessions · limit "..F.HistoryLimit())
    if not UI.historyLimit:HasFocus() then UI.historyLimit:SetText(tostring(F.HistoryLimit())) end
    UI.managerSelected:SetText(record and SessionLabel(record,UI.historyIndex) or "Current session selected. Choose a saved session to delete it.")
    UI.deleteSession:SetEnabled(record~=nil)
    UI.deleteSession:SetText(UI.confirmDelete==record and record~=nil and "Confirm delete" or "Delete selected")
    UI.applyHistory:SetText(UI.confirmLimit and "Confirm limit" or "Apply")
    UI.managerStatus:SetText(UI.manageMessage or "Keep 0-50 for this character and market. Oldest saves are replaced first; 0 stops saving. The current session stays.")
end

function UI.ApplyHistoryLimit()
    local value=tonumber(UI.historyLimit:GetText())
    local profile=F.Profile()
    if not U.Number(value,0,50,true) or not profile then UI.manageMessage="Choose a whole number from 0 to 50.";UI.confirmLimit=nil;UI.RefreshManagement();return end
    local removed=math.max(0,#profile.history-value)
    local confirm=UI.confirmLimit
    if removed>0 and not (confirm and confirm.value==value and confirm.profile==profile and confirm.revision==F.historyRevision) then
        UI.confirmLimit={value=value,profile=profile,revision=F.historyRevision}
        UI.manageMessage="This removes "..removed.." oldest saved session(s). Click Confirm limit to apply."
        UI.RefreshManagement();return
    end
    local ok,reason=F.SetHistoryLimit(value)
    UI.confirmLimit=nil;UI.manageMessage=ok and "Session limit saved." or reason
    UI.historyLimit:ClearFocus();UI.Refresh()
end

function UI.ManageSessions()
    UI.Create()
    if not UI.manager then
        local frame=CreateFrame("Frame","MSMarketValueFarmSessions",UI.frame,"BasicFrameTemplateWithInset")
        frame:SetSize(440,250);frame:SetPoint("CENTER");frame:SetFrameStrata("DIALOG");frame:SetClampedToScreen(true)
        Label(frame,"Manage farming sessions",16,-5,386,true)
        UI.manager=frame
        UI.managerCount=Label(frame,"",18,-38,400)
        Label(frame,"Keep saved sessions",18,-73,188)
        UI.historyLimit=Box(frame,210,-66,62);UI.historyLimit:SetNumeric(true);UI.historyLimit:SetMaxLetters(2)
        UI.historyLimit:SetScript("OnEnterPressed",UI.ApplyHistoryLimit)
        UI.historyLimit:SetScript("OnTextChanged",function(_,user)if user then UI.confirmLimit=nil;UI.manageMessage=nil;UI.RefreshManagement() end end)
        UI.applyHistory=Button(frame,"Apply",286,-66,130,UI.ApplyHistoryLimit)
        UI.managerSelected=Muted(Label(frame,"",18,-107,400));UI.managerSelected:SetHeight(36);UI.managerSelected:SetWordWrap(true)
        UI.deleteSession=Button(frame,"Delete selected",18,-150,184,function()
            local record=UI.historyRecord
            if not record then return end
            if UI.confirmDelete~=record then
                UI.confirmDelete=record;UI.manageMessage="Delete only this saved session? Click Confirm delete to remove it."
            else
                local ok,reason=F.DeleteSession(record);UI.confirmDelete=nil
                if ok then UI.SelectSession(0);UI.manageMessage="Saved session deleted." else UI.manageMessage=reason end
            end
            UI.RefreshManagement()
        end)
        Button(frame,"Done",286,-150,130,function()frame:Hide()end)
        UI.managerStatus=Muted(Label(frame,"",18,-190,400));UI.managerStatus:SetHeight(48);UI.managerStatus:SetWordWrap(true)
        frame:SetScript("OnHide",function()UI.confirmDelete,UI.confirmLimit,UI.manageMessage=nil,nil,nil end)
        U.ManageWindow(frame);UISpecialFrames[#UISpecialFrames+1]="MSMarketValueFarmSessions"
        frame:Hide()
    end
    UI.manager:Show();UI.RefreshManagement();U.FocusWindow(UI.manager)
end

function UI.LayoutHUD()
    if not UI.hudContent then return end
    UI.hudRate:SetWidth(0);UI.hudTotal:SetWidth(0)
    local labels=math.max(UI.hudRateLabel:GetStringWidth(),D.Settings().farmShowTotal and UI.hudTotalLabel:GetStringWidth() or 0)
    local values=math.max(UI.hudRate:GetStringWidth(),D.Settings().farmShowTotal and UI.hudTotal:GetStringWidth() or 0)
    local available=D.Settings().farmHUDWidth-28
    local valueWidth=math.max(1,math.min(values,available-labels-18))
    UI.hudContent:SetSize(labels+18+valueWidth,D.Settings().farmShowTotal and 40 or 18)
    UI.hudRateLabel:SetSize(labels,18);UI.hudTotalLabel:SetSize(labels,18)
    for index,font in ipairs({UI.hudRate,UI.hudTotal}) do
        font:ClearAllPoints();font:SetPoint("TOPLEFT",UI.hudContent,"TOPLEFT",labels+18,index==1 and 0 or -22)
        font:SetSize(valueWidth,18)
    end
end

function UI.UpdateHUD(summary)
    if not UI.hudRate then return end
    summary=summary or F.Summary()
    local rate=summary.paused and summary.perHour or (UI.displayRate or 0)
    local total=summary.paused and summary.total or (UI.displayTotal or 0)
    local rateText,totalText=RateText(summary,rate),U.Coins(total)
    local changed=UI.hudRateText~=rateText or UI.hudTotalText~=totalText
    if UI.hudRateText~=rateText then UI.hudRate:SetText(rateText);UI.hudRateText=rateText end
    if UI.hudTotalText~=totalText then UI.hudTotal:SetText(totalText);UI.hudTotalText=totalText end
    if changed then UI.LayoutHUD() end
end

function UI.HUD()
    if not D.data or A.disabledReason then return end
    if not UI.hud then
        local frame=CreateFrame("Button","MSMarketValueFarmHUD",UIParent,"BackdropTemplate")
        frame:SetClampedToScreen(true);frame:SetMovable(true);frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton");frame:RegisterForClicks("LeftButtonUp","RightButtonUp")
        frame:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=12,
            insets={left=3,right=3,top=3,bottom=3}})
        frame:SetBackdropColor(.04,.035,.025,.88);frame:SetBackdropBorderColor(.62,.48,.20,.9)
        local pos=D.data.farmHUD
        if U.Table(pos) and U.Number(pos.x,-10000,10000) and U.Number(pos.y,-10000,10000) then frame:SetPoint("CENTER",UIParent,"CENTER",pos.x,pos.y)
        else frame:SetPoint("TOP",UIParent,"TOP",0,-100) end
        UI.hudContent=CreateFrame("Frame",nil,frame)
        UI.hudContent:SetPoint("CENTER",frame,"CENTER",0,0)
        UI.hudContent:Show()
        UI.hudRateLabel=Muted(Label(UI.hudContent,"Average",0,0,60))
        UI.hudTotalLabel=Muted(Label(UI.hudContent,"Session",0,-22,60))
        UI.hudRateLabel:SetJustifyH("RIGHT");UI.hudTotalLabel:SetJustifyH("RIGHT")
        UI.hudRate=Label(UI.hudContent,"",78,0,200)
        UI.hudTotal=Label(UI.hudContent,"",78,-22,200)
        frame:SetScript("OnDragStart",function(self)
            if D.Settings().farmHUDLocked then return end
            self.dragging=true;self:StartMoving()
        end)
        frame:SetScript("OnDragStop",function(self)
            if not self.dragging then return end
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
    UI.hud:SetSize(D.Settings().farmHUDWidth,D.Settings().farmShowTotal and 56 or 34)
    if D.Settings().farmShowTotal then UI.hudTotal:Show();UI.hudTotalLabel:Show()
    else UI.hudTotal:Hide();UI.hudTotalLabel:Hide() end
    if D.Settings().farmShow then UI.hud:Show() else UI.hud:Hide() end
    UI.hud:SetAlpha(D.Settings().farmHover and not UI.hovered and 0 or 1)
    UI.UpdateHUD()
    UI.LayoutHUD()
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
    if summary.paused then UI.displayRate,UI.displayTotal=summary.perHour,summary.total
    else
        UI.displayRate=(UI.displayRate or 0)+(summary.perHour-(UI.displayRate or 0))*factor
        UI.displayTotal=(UI.displayTotal or 0)+(summary.total-(UI.displayTotal or 0))*factor
    end
    UI.UpdateHUD(summary)
    UI.refreshElapsed=(UI.refreshElapsed or 0)+dt
    if UI.refreshElapsed>=1 then UI.refreshElapsed=0;if UI.frame and UI.frame:IsShown() then UI.Refresh() end end
end

function UI.Create()
    if UI.frame then return end
    local frame=CreateFrame("Frame","MSMarketValueFarming",UIParent,"PortraitFrameTemplate")
    frame:SetSize(760,680);frame:SetPoint("CENTER");frame:SetClampedToScreen(true)
    frame:SetFrameStrata("DIALOG")
    if frame.PortraitContainer and frame.PortraitContainer.portrait then
        frame.PortraitContainer.portrait:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
    end
    if frame.SetTitle then frame:SetTitle("MS Market Value - Farming & drops") end
    frame:SetMovable(true);frame:EnableMouse(true);frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart",function(self)self:StartMoving()end);frame:SetScript("OnDragStop",function(self)self:StopMovingOrSizing()end)
    if frame.CloseButton then frame.CloseButton:SetScript("OnClick",function()frame:Hide()end) end
    frame:SetScript("OnHide",function()if UI.manager then UI.manager:Hide() end;if GameTooltip then GameTooltip:Hide() end end)
    UISpecialFrames[#UISpecialFrames+1]="MSMarketValueFarming"
    UI.frame=frame;UI.tabs={}
    for i,entry in ipairs({{"session","Session"},{"settings","Farming settings"},{"drops","Drop rates"}}) do
        local page=entry[1]
        UI.tabs[page]=Button(frame,entry[2],16+(i-1)*244,-39,236,function()UI.page=page;UI.Refresh()end)
    end
    UI.session=Panel(frame);UI.settings=Panel(frame);UI.drops=Panel(frame)
    local session=UI.session
    UI.sessionMenu=CreateFrame("DropdownButton",nil,session,"WowStyle1DropdownTemplate")
    UI.sessionMenu:SetPoint("TOPLEFT",session,"TOPLEFT",16,-8);UI.sessionMenu:SetSize(390,25)
    UI.sessionMenu:SetDefaultText("Current session")
    UI.sessionMenu:SetupMenu(function(_,root)
        if root.SetScrollMode then root:SetScrollMode(300) end
        root:CreateRadio("Current session",function()return UI.historyRecord==nil end,function()UI.SelectSession(0)end,0)
        local profile=F.Profile()
        for index,record in ipairs(profile and profile.history or {}) do
            local saved=record
            root:CreateRadio(SessionLabel(record,index),function()return UI.historyRecord==saved end,function()
                local current=F.Profile()
                for i,r in ipairs(current and current.history or {})do if r==saved then UI.SelectSession(i);return end end
                UI.SelectSession(0)
            end,index)
        end
    end)
    UI.sessionTitle=UI.sessionMenu
    UI.manageButton=Button(session,"Manage",416,-10,66,UI.ManageSessions)
    UI.metricValues={}
    for i,title in ipairs({"Session value","Active time","Hourly average","Recent · 60m"}) do
        local x=16+(i-1)*178
        Muted(Label(session,title,x,-45,170))
        UI.metricValues[i]=Label(session,"",x,-66,170)
    end
    UI.total,UI.rate=UI.metricValues[1],UI.metricValues[3]
    Muted(Label(session,"Peak farming · best 5 active minutes",16,-99,238))
    UI.peakValue=Label(session,"",260,-99,152);UI.peakValue:SetJustifyH("RIGHT")
    UI.peakLocation=Muted(Label(session,"",430,-96,288));UI.peakLocation:SetHeight(36);UI.peakLocation:SetWordWrap(true)
    UI.rateNote=Muted(Label(session,"",16,-134,702))
    UI.rateNote:SetHeight(30);UI.rateNote:SetWordWrap(true)
    UI.categoryTotals={};UI.categoryNotes={}
    for i,title in ipairs({"Loot","Quests","Harvesting"}) do
        local x=16+(i-1)*238
        Muted(Label(session,title,x,-173,86))
        UI.categoryTotals[i]=Label(session,"",x+88,-173,140)
        UI.categoryNotes[i]=Muted(Label(session,"",x,-196,228))
    end
    UI.pause=Button(session,"Pause",492,-10,98,function()local _,reason=F.Pause(not F.Summary().paused);UI.message=reason;UI.Refresh()end)
    UI.reset=Button(session,"Reset session",600,-10,118,function()
        if not UI.confirmSession then UI.confirmSession=true;UI.reset:SetText("Confirm reset");return end
        UI.confirmSession=false;local ok,reason=F.Reset();UI.message=reason;UI.displayRate,UI.displayTotal=0,0;UI.Refresh()
    end)
    UI.itemsButton=Button(session,"Items",16,-226,98,function()UI.view=UI.historyRecord and "history" or "items";UI.offset=0;UI.Refresh()end)
    UI.recentButton=Button(session,"Recent pickups",122,-226,130,function()UI.view="recent";UI.offset=0;UI.Refresh()end)
    UI.currentButton=Button(session,"Current session",260,-226,142,function()UI.SelectSession(0)end)
    UI.sourceMenu=CreateFrame("DropdownButton",nil,session,"WowStyle1DropdownTemplate")
    UI.sourceMenu:SetPoint("TOPLEFT",session,"TOPLEFT",414,-226);UI.sourceMenu:SetSize(304,24)
    if UI.sourceMenu.SetupMenu then UI.sourceMenu:SetupMenu(function(_,root)
        for _,key in ipairs({"all","loot","quest","harvesting","herbalism","mining","skinning"}) do
            local source=key
            root:CreateRadio(sourceLabels[source],function()return UI.source==source end,function()
                UI.source=source;UI.offset=0;UI.Refresh()
            end)
        end
    end) end
    UI.breakdownTitle=Muted(Label(session,"",16,-258,440))
    UI.listCount=Muted(Label(session,"",462,-258,256));UI.listCount:SetJustifyH("RIGHT")
    local list=CreateFrame("Frame",nil,session,"InsetFrameTemplate");UI.list=list
    list:SetPoint("TOPLEFT",session,"TOPLEFT",12,-282);list:SetSize(712,274)
    local function Wheel(_,delta)if U.Number(delta) then UI.Scroll(UI.offset-delta*3) end end
    list:EnableMouseWheel(true);list:SetScript("OnMouseWheel",Wheel)
    local header=CreateFrame("Frame",nil,list);header:SetPoint("TOPLEFT",list,"TOPLEFT",4,-4);header:SetSize(680,20)
    local backdrop=header:CreateTexture(nil,"BACKGROUND");backdrop:SetAllPoints(header);backdrop:SetColorTexture(.22,.18,.09,.45)
    for _,entry in ipairs({{"Item / receipt",8,285},{"Source",300,90},{"Qty",396,50},{"Each",454,100},{"Total",561,105}}) do
        local label=Muted(Label(header,entry[1],entry[2],-2,entry[3]));if entry[2]>=396 then label:SetJustifyH("RIGHT") end
    end
    UI.rows={}
    for i=1,12 do
        local button=CreateFrame("Button",nil,list);button:SetPoint("TOPLEFT",list,"TOPLEFT",6,-28-(i-1)*20);button:SetSize(678,20)
        local shade=button:CreateTexture(nil,"BACKGROUND");shade:SetAllPoints(button);shade:SetColorTexture(.12,.13,.15,i%2==0 and .50 or .15)
        button.highlight=button:CreateTexture(nil,"BACKGROUND");button.highlight:SetAllPoints(button);button.highlight:SetColorTexture(.72,.55,.20,.18);button.highlight:Hide()
        button.name=Label(button,"",8,-2,285);button.source=Muted(Label(button,"",300,-2,90))
        button.quantity=Label(button,"",396,-2,50);button.quantity:SetJustifyH("RIGHT")
        button.unit=Label(button,"",454,-2,100);button.unit:SetJustifyH("RIGHT")
        button.total=Label(button,"",561,-2,105);button.total:SetJustifyH("RIGHT")
        button:EnableMouseWheel(true);button:SetScript("OnMouseWheel",Wheel)
        button:SetScript("OnEnter",function(self)
            local item=self.item
            if item and GameTooltip then
                self.highlight:Show()
                GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
                if U.String(item.link) then GameTooltip:SetHyperlink(item.link) else GameTooltip:ClearLines();GameTooltip:AddLine(item.name) end
                if item.mode then GameTooltip:AddDoubleLine("Session valuation",item.mode) end
                if item.time then GameTooltip:AddDoubleLine("Received",date("%b %d %H:%M:%S",item.time)) end
                GameTooltip:Show()
            end
        end)
        button:SetScript("OnLeave",function(self)self.highlight:Hide();if GameTooltip then GameTooltip:Hide() end end)
        UI.rows[i]=button
    end
    UI.empty=Muted(Label(list,"No recorded income yet.",16,-42,620))
    UI.scrollbar=CreateFrame("Slider",nil,list,"UIPanelScrollBarTemplate")
    UI.scrollbar:SetPoint("TOPRIGHT",list,"TOPRIGHT",-4,-43);UI.scrollbar:SetPoint("BOTTOMRIGHT",list,"BOTTOMRIGHT",-4,22)
    UI.scrollbar:SetWidth(16);UI.scrollbar:SetValueStep(1);UI.scrollbar:SetObeyStepOnDrag(true)
    UI.scrollbar:SetScript("OnValueChanged",function(_,value)if not UI.syncScroll then UI.Scroll(value) end end)
    UI.note=Muted(Label(session,"",16,-562,702));UI.note:SetHeight(20);UI.note:SetWordWrap(true)
    UI.checks={}
    local settings=UI.settings
    Muted(Label(settings,"Acquisition value; sales and cash flow stay in the ledger.",14,-12,706))
    Check(settings,"Track farming sessions","farmTracking",14,-41)
    Check(settings,"Show the farming display","farmShow",14,-75,285)
    Check(settings,"Show session total","farmShowTotal",334,-75,280)
    Check(settings,"Show only on hover","farmHover",14,-109,285)
    Check(settings,"Lock display position","farmHUDLocked",334,-109,280)
    Check(settings,"Use current AH value after the configured AH cut","farmUseAuction",14,-143)
    Label(settings,"Quest rewards",18,-185,130)
    UI.questMenu=CreateFrame("DropdownButton",nil,settings,"WowStyle1DropdownTemplate")
    UI.questMenu:SetPoint("TOPLEFT",settings,"TOPLEFT",154,-177);UI.questMenu:SetSize(484,25)
    UI.questMenu:SetupMenu(function(_,root)
        for _,entry in ipairs({{"session","Session total only"},{"hourly","Session total and hourly rates"},{"off","Do not record new quest rewards"}})do
            local mode=entry[1]
            root:CreateRadio(entry[2],function()
                return mode==(not D.Settings().farmIncludeQuest and "off" or D.Settings().farmQuestInRate and "hourly" or "session")
            end,function()
                D.data.settings.farmIncludeQuest=mode~="off";D.data.settings.farmQuestInRate=mode=="hourly"
                F.summary=nil;UI.Refresh();UI.HUD()
            end,mode)
        end
    end)
    Label(settings,"Use AH value only when it beats vendor value by",18,-223,390)
    UI.threshold=Box(settings,410,-216,70);UI.threshold:SetNumeric(true)
    Label(settings,"%",490,-223,24)
    Button(settings,"Apply",534,-216,104,function()
        local value=tonumber(UI.threshold:GetText())
        if not U.Number(value,0,1000,true) then UI.message="Enter a threshold from 0 to 1000%.";UI.Refresh();return end
        D.data.settings.farmThreshold=value;UI.threshold:ClearFocus();F.summary=nil;UI.message=nil;UI.Refresh()
    end)
    UI.idleCheck=Check(settings,"Auto-pause when idle","farmIdle",14,-254,232)
    UI.idleMinutes=Box(settings,264,-254,58);UI.idleMinutes:SetNumeric(true)
    Label(settings,"minutes (5-60)",336,-261,183)
    UI.applyIdle=Button(settings,"Apply",534,-254,104,function()
        local ok,reason=F.ConfigureIdle(D.Settings().farmIdle,tonumber(UI.idleMinutes:GetText()))
        UI.message=reason
        if ok then UI.idleMinutes:ClearFocus() end
        UI.Refresh()
    end)
    Label(settings,"Display width",18,-309,224)
    UI.hudWidth=Box(settings,264,-302,58);UI.hudWidth:SetNumeric(true)
    Muted(Label(settings,"pixels (240-520)",336,-309,183))
    UI.applyWidth=Button(settings,"Apply",534,-302,104,function()
        local width=tonumber(UI.hudWidth:GetText())
        if not U.Number(width,240,520,true) then UI.message="Choose a width from 240 to 520 pixels."
        else D.data.settings.farmHUDWidth=width;UI.hudWidth:ClearFocus();UI.message=nil;UI.HUD() end
        UI.Refresh()
    end)
    UI.deathCheck=Check(settings,"Pause on death until combat, loot or manual resume","farmPauseOnDeath",14,-342,660)
    local help=Muted(Label(settings,"The calculator starts idle after login. Combat, received loot or Resume starts it; resurrection alone does not. A manual pause stays paused.\n\nIdle time starts after combat or your last loot. Drag the unlocked display to move it; right-click pauses or resumes.\n\nHourly figures follow the quest choice above; peaks always exclude quests. Items count when acquired, and sales are separate. Quest rewards and bound items use vendor value; stale AH data also falls back to vendor value.",18,-387,700))
    help:SetHeight(146);help:SetWordWrap(true)
    UI.settingsStatus=Label(settings,"",18,-557,700)
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
                    D.data.settings.dropMode=mode;D.data.settings.dropModeConfigured=true;P.InvalidateDisplay();UI.Refresh()
                end)
            end
        end)
    end
    Label(drops,"Max items",400,-91,80)
    UI.maxDrops=Box(drops,480,-84,50);UI.maxDrops:SetNumeric(true)
    UI.applyDrops=Button(drops,"Apply",542,-84,96,function()
        local count=tonumber(UI.maxDrops:GetText())
        if U.Number(count,1,10,true) then D.data.settings.dropRows=count;P.InvalidateDisplay();UI.maxDrops:ClearFocus();UI.message=nil
        else UI.message="Choose 1-10 tooltip items." end
        UI.Refresh()
    end)
    Label(drops,"Sort",18,-131,80)
    UI.dropSort=CreateFrame("DropdownButton",nil,drops,"WowStyle1DropdownTemplate")
    UI.dropSort:SetPoint("TOPLEFT",drops,"TOPLEFT",108,-123);UI.dropSort:SetSize(274,25)
    UI.dropSort:SetupMenu(function(_,root)
        for _,entry in ipairs(dropSorts)do
            local sort=entry[1]
            root:CreateRadio(entry[2],function()return D.Settings().dropSort==sort end,function()
                D.data.settings.dropSort=sort;P.InvalidateDisplay();UI.Refresh()
            end,sort)
        end
    end)
    Label(drops,"Rarity",400,-131,80)
    UI.dropQuality=CreateFrame("DropdownButton",nil,drops,"WowStyle1DropdownTemplate")
    UI.dropQuality:SetPoint("TOPLEFT",drops,"TOPLEFT",480,-123);UI.dropQuality:SetSize(224,25)
    UI.dropQuality:SetDefaultText("All rarities")
    UI.dropQuality:SetupMenu(function(_,root)
        root:CreateCheckbox("All rarities",function()return D.Settings().dropQuality==63 end,function()
            D.data.settings.dropQuality=D.Settings().dropQuality==63 and 0 or 63;P.InvalidateDisplay();UI.Refresh()
        end,"all")
        for quality=0,5 do
            local q=quality
            root:CreateCheckbox(QualityLabel(q),function()return P.QualityAllowed(D.Settings().dropQuality,q)end,function()
                D.data.settings.dropQuality=D.Settings().dropQuality+(P.QualityAllowed(D.Settings().dropQuality,q) and -2^q or 2^q)
                P.InvalidateDisplay();UI.Refresh()
            end,q)
        end
    end)
    local priority=Muted(Label(drops,"Needed quest drops always stay visible and first. Sort and rarity choices apply to the other drops.\nUnknown rarity stays visible with All rarities selected.",18,-161,700))
    priority:SetHeight(42);priority:SetWordWrap(true)
    UI.reference=Label(drops,"",18,-211,700);UI.reference:SetHeight(60);UI.reference:SetWordWrap(true)
    local desc=Muted(Label(drops,"Personal rates count inspected corpses or harvests, including visible group loot. Herbs, ore and skinning have separate samples; unseen kills are not counted.",18,-279,700))
    desc:SetHeight(42);desc:SetWordWrap(true)
    Muted(Label(drops,"Reset personal observations",18,-340,400))
    UI.scope=CreateFrame("DropdownButton",nil,drops,"WowStyle1DropdownTemplate")
    UI.scope:SetPoint("TOPLEFT",drops,"TOPLEFT",18,-367);UI.scope:SetSize(212,25)
    UI.resetScope="monster"
    if UI.scope.SetupMenu then UI.scope:SetupMenu(function(_,root)
        for _,entry in ipairs({{"monster","Creature / node name or ID"},{"zone","Current zone"},{"dungeon","Current dungeon"},{"all","All my observations"}}) do
            local scope=entry[1]
            root:CreateRadio(entry[2],function()return UI.resetScope==scope end,function()UI.resetScope=scope;UI.confirmDrops=false;UI.Refresh()end)
        end
    end) end
    UI.monster=Box(drops,244,-367,254)
    UI.monster:SetScript("OnTextChanged",function(_,user)
        if user then UI.confirmDrops=false;UI.clearDrops:SetText("Reset selected") end
    end)
    UI.clearDrops=Button(drops,"Reset selected",510,-367,128,function()
        if not UI.confirmDrops then UI.confirmDrops=true;UI.clearDrops:SetText("Confirm reset");return end
        UI.confirmDrops=false;local ok,reason=P.Reset(UI.resetScope,UI.monster:GetText());UI.message=reason;UI.Refresh()
    end)
    UI.dropStatus=Label(drops,"",18,-407,700);UI.dropStatus:SetHeight(78);UI.dropStatus:SetWordWrap(true)
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
    if not UI.hudWidth:HasFocus() then UI.hudWidth:SetText(tostring(D.Settings().farmHUDWidth)) end
    UI.settingsStatus:SetText(UI.message or "Idle pause is optional. Offline and loading time are excluded.")
    if UI.mode.Update then UI.mode:Update() end
    if UI.dropSort.Update then UI.dropSort:Update() end
    local count,label=0
    for quality=0,5 do if P.QualityAllowed(D.Settings().dropQuality,quality) then count=count+1;label=QualityLabel(quality) end end
    if UI.dropQuality.OverrideText then UI.dropQuality:OverrideText(count==6 and "All rarities" or count==0 and "Quest drops only" or count==1 and label or (count.." rarities selected")) end
    if UI.scope.Update then UI.scope:Update() end
    if UI.sourceMenu.Update then UI.sourceMenu:Update() end
    if UI.questMenu.Update then UI.questMenu:Update() end
    UI.clearDrops:SetText(UI.confirmDrops and "Confirm reset" or "Reset selected")
    UI.reference:SetText(D.Settings().dropMode=="reference" and
        ("Reference: "..A.LootReference.DisplayLabel()..". Forever entries take priority, then Classic.\nMissing items and entire sources use your personal observations. Rates and sample counts stay separate. Classic rates are unverified for Forever.") or
        "Personal display: only this character's observations for the current area and source. Reference data remains available in the Display menu; collecting personal observations works in either mode.")
    local profile=P.Profile()
    UI.dropStatus:SetText(UI.message or P.reason or ((profile and profile.mobs or 0) .. " source records; " ..
        (profile and profile.cells or 0) .. " item counters. Reset affects this character only."))
    local live=F.Summary()
    local farming=F.Profile()
    local history=UI.historyRecord
    if history then
        local found=false
        for index,record in ipairs(farming and farming.history or {})do if record==history then UI.historyIndex=index;found=true;break end end
        if not found then UI.historyRecord,UI.historyIndex,UI.view,UI.offset=nil,0,"items",0;history=nil end
    end
    UI.currentButton:SetEnabled(history~=nil);UI.recentButton:SetEnabled(history==nil or history.recent~=nil)
    local summary=history or live
    local rateValue=history and F.HourlyValue(history)
    local average=history and (history.elapsed>=60 and rateValue and rateValue/history.elapsed*3600 or 0) or live.perHour
    local state=live.idlePaused and " · Idle" or live.paused and " · Paused" or ""
    UI.sessionMenu:OverrideText(history and SessionLabel(history,UI.historyIndex) or ("Current session"..state))
    local recent=live.recentRate
    local savedPeak=summary.peak
    if history then
        recent=D.Settings().farmQuestInRate and (history.recentTotalRate or history.recentRate) or history.recentFarmRate
        savedPeak=U.Number(history.ratePolicy,2,2,true) and history.peak or nil
    end
    UI.total:SetText(U.Coins(summary.total))
    UI.metricValues[2]:SetText(Duration(summary.elapsed))
    UI.rate:SetText(summary.elapsed>=60 and (U.Coins(average) .. " / h") or "Starting")
    UI.metricValues[4]:SetText(recent and ((summary.recentDuration or summary.elapsed)>=60 and
        (U.Coins(recent) .. " / h") or (not history and live.idlePaused and "Waiting" or "Starting")) or "Not recorded")
    local peak=U.Table(savedPeak) and U.Number(savedPeak.rate,0,1000000000000) and savedPeak
    UI.peakValue:SetText(peak and peak.rate>0 and (U.Coins(peak.rate) .. " / h") or history and "Not recorded" or live.idlePaused and "Waiting · 5m" or "Building · 5m")
    local location=peak and peak.location
    UI.peakLocation:SetText(A.FarmMetrics.ValidLocation(location) and (location.zone ..
        (location.x and string.format(" · %.1f, %.1f",location.x,location.y) or "") .. " · " .. date("%b %d %H:%M",location.time)) or
        (history and "Farming peak unavailable for this saved session." or "A completed five-minute farming window sets the first peak."))
    UI.rateNote:SetText((D.Settings().farmQuestInRate and "Hourly includes quests; " or "Hourly excludes quests; ")..
        "peak always excludes quests. Recent/peak use pickup prices."..
        ((summary.metricsSince and summary.metricsSince>0) and " Coverage starts at the update." or "")..
        ((summary.metricMissing or 0)>0 and (" "..summary.metricMissing.." unpriced pickups.") or ""))
    UI.categoryTotals[1]:SetText(U.Coins((summary.coins or 0)+(summary.lootValue or 0)))
    UI.categoryTotals[2]:SetText(U.Coins((summary.questCoins or 0)+(summary.questValue or 0)))
    UI.categoryTotals[3]:SetText(U.Coins(summary.harvestValue or 0))
    UI.categoryNotes[1]:SetText("Gold: " .. U.Coins(summary.coins or 0) .. " + items")
    UI.categoryNotes[2]:SetText("Gold: " .. U.Coins(summary.questCoins or 0) .. " + rewards")
    UI.categoryNotes[3]:SetText("Herbs, ore and skins")
    UI.pause:SetText(live.paused and "Resume" or "Pause");UI.reset:SetText(UI.confirmSession and "Confirm reset" or "Reset session")
    UI.pause:SetEnabled(not history and not live.dead);UI.reset:SetEnabled(not history)
    local rows
    if UI.view=="recent" and summary.recent then
        rows=summary.recent;UI.breakdownTitle:SetText("Recent pickups · value when received")
    elseif history then
        rows=history.items or history.top
        UI.breakdownTitle:SetText(history.items and "Saved items · value when saved" or "Saved summary · top items only")
    else
        rows=summary.items;UI.breakdownTitle:SetText("Items · current valuation")
    end
    local filtered={}
    for _,item in ipairs(rows) do
        if UI.source=="all" or item.source==UI.source or (UI.source=="harvesting" and F.Harvest(item.source)) then
            filtered[#filtered+1]=item
        end
    end
    rows=filtered;UI.visibleItems=rows
    local maximum=math.max(0,#rows-#UI.rows)
    UI.offset=math.max(0,math.min(UI.offset,maximum))
    UI.syncScroll=true;UI.scrollbar:SetMinMaxValues(0,maximum);UI.scrollbar:SetValue(UI.offset);UI.scrollbar:SetEnabled(maximum>0);UI.syncScroll=false
    UI.listCount:SetText(#rows.." entries"..(#rows>0 and (" · "..(UI.offset+1).."-"..math.min(#rows,UI.offset+#UI.rows)) or ""))
    for i,button in ipairs(UI.rows) do
        local item=rows[UI.offset+i]
        if button.item~=item then button.highlight:Hide() end
        button.item=item
        if item then
            local total=item.total or item.amount
            local unit=item.unit or (item.quantity and item.quantity>0 and total and total/item.quantity)
            button.name:SetText(item.name);button.source:SetText(sourceLabels[item.source] or "")
            button.quantity:SetText(item.quantity or "-")
            button.unit:SetText(unit and U.Coins(unit) or item.quantity and "Unknown" or "-")
            button.total:SetText(total and U.Coins(total) or "Unknown");button:Show()
        else button:Hide() end
    end
    if #rows==0 then UI.empty:Show() else UI.empty:Hide() end
    UI.note:SetText(UI.message or F.reason or (history and "Saved values from this session.") or
        (live.dead and "Paused on death · After resurrection, Resume, combat or received loot starts timing.") or
        (live.idleReason=="login" and "Idle after login · Resume, combat or received loot starts timing.") or
        (live.idleReason=="death" and "Idle after death · Resume, combat or received loot starts timing.") or
        (live.idlePaused and "Idle · Combat or your next loot resumes the session.") or
        (live.paused and "Paused manually · Click Resume when you are ready.") or
        ((summary.unknown or 0)>0 and (summary.unknown .. " acquired items need item data; excluded from the estimate.")) or
        "Acquired items and quest rewards are valued once. Mail, trades and sale proceeds stay in the ledger.")
    UI.RefreshManagement()
end

function UI.Show(page)
    UI.Create();UI.page=page=="drops" and "drops" or page=="settings" and "settings" or "session"
    if UI.page=="session" then UI.SelectSession(0) end
    UI.Refresh();UI.frame:Show();U.FocusWindow(UI.frame)
end
