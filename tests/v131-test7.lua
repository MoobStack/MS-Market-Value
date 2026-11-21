local fresh,craftingWorld,row,link,test,equal,truth=...
local function enter(widget) truth(widget and widget.scripts.OnEnter);widget.scripts.OnEnter(widget) end
local function leave(widget) if widget.scripts.OnLeave then widget.scripts.OnLeave(widget) end end
local function click(widget)widget.scripts.OnClick(widget,"LeftButton")end
local function text()local lines={};for _,line in ipairs(GameTooltip.lines)do lines[#lines+1]=line.left end;return table.concat(lines," ")end
local function world()
    local w,A=fresh();w:load();A.UI.Create();return w,A,A.Help
end

test("interface help defaults on and an explicit off choice survives reload",function()
    local w,A,H=world();truth(H.Enabled());equal(A.DB.Settings().showInterfaceTips,true)
    A.DB.Settings().showInterfaceTips=false
    local w2,B=fresh(A.DB.data);w2:load();equal(B.Help.Enabled(),false)
    equal(B.DB.Settings().showAuction,true);equal(B.DB.Settings().showDrops,true);equal(w2.requests,0)
end)
test("main tooltip controls fit eight rows and opt-out hides help immediately",function()
    local _,A,H=world();local box=A.UI.checks.showInterfaceTips
    equal(box.label.text,"Addon interface tooltips")
    local rows, panel = {}, A.UI.tooltipSettings
    for _, check in pairs(A.UI.checks) do
        if check:GetParent() == panel then rows[#rows + 1] = check end
    end
    equal(#rows, 8)
    table.sort(rows, function(a, b) return a.points[1][5] > b.points[1][5] end)
    local bottom = 0
    for _, check in ipairs(rows) do
        local top = -check.points[1][5]
        truth(top >= bottom)
        bottom = top + check:GetHeight()
    end
    truth(bottom <= panel:GetHeight())
    enter(A.UI.restartButton);truth(GameTooltip:IsShown());truth(text():find("unfinished",1,true))
    box:SetChecked(false);click(box);equal(GameTooltip:IsShown(),false);equal(H.owner,nil)
    enter(A.UI.restartButton);equal(GameTooltip:IsShown(),false)
    box:SetChecked(true);click(box);enter(A.UI.restartButton);truth(GameTooltip:IsShown())
end)
test("interface opt-out leaves item-value and world-drop preferences intact",function()
    local _,A=world();local settings=A.DB.Settings()
    local before={};for _,key in ipairs({"showVendor","showHistory","showAuction","showDisenchant","showMaterials","showAge","showDrops","showHarvestDrops"})do before[key]=settings[key]end
    A.UI.checks.showInterfaceTips:SetChecked(false);click(A.UI.checks.showInterfaceTips)
    for key,value in pairs(before)do equal(settings[key],value)end
    truth(A.UI.DiagnosticsText():find("Interface tooltips: enabled=false",1,true))
end)
test("item-price tooltip content remains available when interface help is off",function()
    local w,A=world();w.items[100]={name="Test",vendor=100}
    A.DB.Settings().showInterfaceTips=false
    local found=false
    for _,line in ipairs(A.Tooltips.Lines(100,link(100),1))do if line.left=="Vendor sell"then found=true end end
    truth(found);equal(A.Help.Enabled(),false)
end)
test("help hooks preserve native input clicks focus and prior hover scripts",function()
    local _,A,H=world();local box=CreateFrame("EditBox",nil,UIParent);local enters,leaves,clicks=0,0,0
    box:SetScript("OnEnter",function()enters=enters+1 end);box:SetScript("OnLeave",function()leaves=leaves+1 end)
    box:SetScript("OnClick",function()clicks=clicks+1 end);box:SetFocus();box:SetText("0.25")
    H.Bind(box,"Amount in gold.");enter(box);click(box);leave(box)
    equal(enters,1);equal(leaves,1);equal(clicks,1);equal(box:GetText(),"0.25");truth(box:HasFocus())
    A.DB.Settings().showInterfaceTips=false;enter(box);click(box);leave(box)
    equal(enters,2);equal(leaves,2);equal(clicks,2);equal(GameTooltip:IsShown(),false)
end)
test("repeated help bindings replace text without stacking handlers or frames",function()
    local w,_,H=world();local button=CreateFrame("Button",nil,UIParent);local count=H.count
    H.Bind(button,"First description.");local handler=button.scripts.OnEnter;local frames=w.createdFrames
    for _=1,200 do H.Bind(button,"Updated description.")end
    equal(button.scripts.OnEnter,handler);equal(H.count,count+1);equal(w.createdFrames,frames)
    enter(button);equal(#GameTooltip.lines,1);equal(text(),"Updated description.");truth(button.motionWhileDisabled)
end)
test("help hides only the tooltip owned by the departing control",function()
    local _,A,H=world();local one,two=A.UI.restartButton,A.UI.scanButton
    enter(one);enter(two);leave(one);truth(GameTooltip:IsShown());equal(GameTooltip:GetOwner(),two)
    leave(two);equal(GameTooltip:IsShown(),false)
    enter(one);one:Show();one:Hide();equal(GameTooltip:IsShown(),false)
end)
test("turning help off never hides an unrelated native tooltip",function()
    local _,A,H=world();enter(A.UI.restartButton)
    local native=CreateFrame("Frame",nil,UIParent);GameTooltip:SetOwner(native,"ANCHOR_RIGHT");GameTooltip:Show()
    A.DB.Settings().showInterfaceTips=false;H.Refresh();truth(GameTooltip:IsShown());equal(GameTooltip:GetOwner(),native)
    equal(H.owner,nil);leave(A.UI.restartButton);truth(GameTooltip:IsShown())
end)
test("quarter-second refresh handles external interface preference changes",function()
    local _,A=world();enter(A.UI.scanButton);truth(GameTooltip:IsShown())
    A.DB.Settings().showInterfaceTips=false;A.eventFrame.scripts.OnUpdate(A.eventFrame,.25)
    equal(GameTooltip:IsShown(),false);equal(A.Help.owner,nil)
end)
test("all interface sections bind concise explanations to their less obvious controls",function()
    local w,A=world();A.CraftingUI.Create();A.MarketUI.Create(CreateFrame("Frame",nil,UIParent))
    A.EconomyUI.Create();A.FarmingUI.Create();A.FarmingUI.ManageSessions();A.WatchUI.CreateSettings()
    local c,m,e,f,v=A.CraftingUI,A.MarketUI,A.EconomyUI,A.FarmingUI,A.WatchUI
    local controls={A.UI.scanButton,A.UI.stopButton,A.UI.restartButton,A.UI.staleBox,A.UI.retentionBox,
        c.sortProfit,c.sortReturn,c.insertQuote,c.recordSale,c.quoteBox,c.searchBox,c.customerMaterials,
        m.views.deals,m.views.listed,m.recheck,m.qualityMenu,m.searchBox,m.watchSelected,
        e.settingsTab,e.csvButton,e.importInvoiceButton,e.deleteEntry,e.undo,e.dateFirst,e.retention,
        f.sessionMenu,f.manageButton,f.pause,f.reset,f.currentButton,f.questMenu,f.dropSort,f.dropQuality,f.mode,f.scope,f.historyLimit,
        v.searchBox,v.only,v.headers.status,v.headers.roi,v.remove}
    for _,group in ipairs({A.UI.checks,c.priceInputs,c.saleInputs,m.inputs,e.ledgerInputs,e.watchInputs,v.checks})do
        for _,control in pairs(group)do controls[#controls+1]=control end
    end
    for _,control in ipairs(controls)do
        truth(control.msmvHelp,"missing control help")
        enter(control);truth(GameTooltip:IsShown());truth(#text()<=180,"keep help concise");leave(control)
    end
    equal(w.requests,0)
end)
test("craft help explains draft chat and money fields without submitting actions",function()
    local w,A=craftingWorld();A.CraftingUI.Show();local ui=A.CraftingUI
    enter(ui.insertQuote);truth(text():find("before sending",1,true));leave(ui.insertQuote)
    enter(ui.saleInputs.price);truth(text():find("per item or service",1,true));leave(ui.saleInputs.price)
    enter(ui.saleInputs.tip);truth(text():find("whole commission",1,true));leave(ui.saleInputs.tip)
    enter(ui.priceInputs.serviceMinimum);truth(text():find("Minimum service quote",1,true));leave(ui.priceInputs.serviceMinimum)
    equal(w.chatDraft,nil)
end)
test("recipe and material hover details respect opt-out while selection stays usable",function()
    local _,A=craftingWorld();local ui=A.CraftingUI;ui.Show();ui.mode="profit";ui.Refresh()
    local button=ui.catalogRows[1];truth(button.row);enter(button);truth(GameTooltip:IsShown());leave(button)
    A.DB.Settings().showInterfaceTips=false;enter(button);truth(button.highlight:IsShown());equal(GameTooltip:IsShown(),false);leave(button)
    click(button);equal(ui.mode,"recipe");local material=ui.materialRows[1];truth(material.material)
    enter(material);equal(GameTooltip:IsShown(),false)
    A.DB.Settings().showInterfaceTips=true;enter(material);truth(GameTooltip:IsShown());leave(material)
end)
test("market row details are gated without changing hover selection or inline details",function()
    local _,A=world();local ui=A.MarketUI;ui.Create(CreateFrame("Frame",nil,UIParent))
    local button=ui.rows[1];button.row={id=100,link=link(100),name="Test",needsHistory=true,days=0}
    enter(button);truth(GameTooltip:IsShown());leave(button)
    A.DB.Settings().showInterfaceTips=false;enter(button);equal(GameTooltip:IsShown(),false);equal(ui.hovered,button.row)
    truth(ui.detail.text:find("Test",1,true));leave(button);equal(ui.hovered,nil)
end)
test("farming item hover retains highlighting with interface help disabled",function()
    local _,A=world();local ui=A.FarmingUI;ui.Show("session");local button=ui.rows[1]
    button.item={id=100,link=link(100),name="Test",mode="Vendor",time=A.Util.Now()}
    enter(button);truth(GameTooltip:IsShown());leave(button)
    A.DB.Settings().showInterfaceTips=false;enter(button);truth(button.highlight:IsShown());equal(GameTooltip:IsShown(),false)
    leave(button);equal(button.highlight:IsShown(),false)
end)
test("watchlist row help can be disabled without breaking target editing or search",function()
    local w,A=fresh();w:start({row(100,1,500)});w:drain();truth(A.Watchlist.Save(100,600,0,0));A.Watchlist.Ensure()
    for _=1,100 do if not A.Watchlist.job then break end;A.Watchlist.Tick()end
    A.EconomyUI.Show("watch");local ui=A.WatchUI;local button=ui.rows[1];truth(button.row)
    enter(button);truth(GameTooltip:IsShown());leave(button)
    A.DB.Settings().showInterfaceTips=false;enter(button);truth(button.highlight:IsShown());equal(GameTooltip:IsShown(),false)
    button.scripts.OnClick(button,"RightButton");truth(ui.editor:IsShown());equal(w.itemSearches or 0,0)
    ui.editor:Hide();ui.searchBox:SetText("[no match]");equal(#ui.View(),0)
end)
test("ledger row help opt-out preserves click-to-edit and whole-lot field explanations",function()
    local _,A=world();truth(A.Ledger.Record({kind="sale",name="Test sale",quantity=2,amount=10000,fee=500,cost=4000}))
    local e=A.EconomyUI;e.Show("ledger");e.SetLedgerView("transactions");local button=e.ledgerRows[1];truth(button.row)
    enter(button);truth(GameTooltip:IsShown());leave(button)
    A.DB.Settings().showInterfaceTips=false;enter(button);equal(GameTooltip:IsShown(),false);click(button);truth(e.editorFrame:IsShown())
    A.DB.Settings().showInterfaceTips=true;enter(e.ledgerInputs.cost);truth(text():find("Leave blank if unknown",1,true));leave(e.ledgerInputs.cost)
end)
test("small farming display keeps its hover behavior when help is disabled",function()
    local _,A=world();A.FarmingUI.HUD();local ui=A.FarmingUI
    local display=ui.hud;truth(display);A.DB.Settings().showInterfaceTips=false
    enter(display);equal(ui.hovered,true);equal(GameTooltip:IsShown(),false);leave(display);equal(ui.hovered,false)
end)
