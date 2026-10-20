local fresh,test,equal,truth=...
local function initial()
    local w,A=fresh();w:load();A.EconomyUI.Show("ledger");return w,A,A.EconomyUI
end
local function record(A,kind,amount)
    truth(A.Ledger.Record({kind=kind,name=kind,quantity=1,amount=amount}))
end

test("periodic ledger refresh never hides the active transaction panel",function()
    local w,A,E=initial();E.SetFilter("all");local hides=0
    E.transactionsPanel:SetScript("OnHide",function()hides=hides+1 end)
    for _=1,30 do A.eventFrame.scripts.OnUpdate(A.eventFrame,.25)end
    equal(hides,0);E.SetLedgerView("report");equal(hides,1)
end)
test("all eight type filters replace displayed rows immediately without waiting for a tick",function()
    local w,A,E=initial()
    for _,kind in ipairs({"sale","buy","vendor_sale","vendor_buy","commission","tip_received","tip_given"})do record(A,kind,100)end
    local mono=w.mono
    for _,kind in ipairs({"buy","tip_received","sale","tip_given","vendor_sale","commission","vendor_buy","all"})do
        E.filterButtons[kind].scripts.OnClick();equal(E.filterKind,kind);equal(w.mono,mono)
        equal(#A.Ledger.View(E.CurrentFilter()),kind=="all"and 7 or 1)
        if kind~="all"then equal(E.ledgerRows[1].row.kind,kind)end
    end
    equal(w.requests,0)
end)
test("trade tip report totals drill down without mixing received and given gold",function()
    local w,A,E=initial();record(A,"tip_received",500);record(A,"tip_given",200);E.Refresh()
    equal(E.activityRows.tip_received.value.text,"5s 00c");equal(E.activityRows.tip_given.value.text,"2s 00c")
    equal(E.report.flow.text,"+3s 00c");equal(E.report.profit.text,"--")
    E.activityRows.tip_given.scripts.OnClick();equal(E.filterKind,"tip_given");equal(E.ledgerRows[1].row.kind,"tip_given")
end)
test("the native Type dropdown selects a distant choice in one menu selection",function()
    local w,A,E=initial();E.OpenEditor();E.ledgerInputs.name:SetText("Keep draft");E.ledgerInputs.amount:SetText("12.34")
    E.kindDropdown:OpenMenu();equal(#E.kindDropdown.menuDescription.items,8);truth(E.kindDropdown:Pick("tip_given"))
    equal(E.kind,"tip_given");equal(E.kindDropdown.text,"Tip given");equal(E.ledgerInputs.name.text,"Keep draft");equal(E.ledgerInputs.amount.text,"12.34")
    equal(E.ledgerInputs.tip.enabled,false)
end)
test("refresh does not rebuild or close the open Type menu",function()
    local w,A,E=initial();E.OpenEditor();E.kindDropdown:OpenMenu();local builds=E.kindDropdown.menuBuilds
    for _=1,30 do E.Refresh()end
    equal(E.kindDropdown.menuBuilds,builds);truth(E.kindDropdown:IsMenuOpen());E.editorFrame:Hide();equal(E.kindDropdown:IsMenuOpen(),false)
end)
test("legacy expense remains selectable while editing an existing legacy row",function()
    local w,A,E=initial();record(A,"expense",100);E.LoadLedger(A.Ledger.Records()[1]);E.kindDropdown:OpenMenu()
    equal(#E.kindDropdown.menuDescription.items,8);truth(E.kindDropdown:Pick("buy"));E.kindDropdown:OpenMenu();truth(E.kindDropdown:Pick("expense"));equal(E.kind,"expense")
end)
test("local date labels and CSV preserve both local and UTC representations of the same epoch",function()
    local w,A,E=initial();record(A,"sale",100);E.SetFilter("sale");local row=A.Ledger.Records()[1];local stamp=row.time
    equal(E.ledgerRows[1].labels[1].text,date("%m-%d %H:%M",stamp))
    local csv=A.Ledger.CSV(E.CurrentFilter());truth(string.find(csv,"LocalTime,UTC,Type",1,true))
    truth(string.find(csv,date("%Y-%m-%d %H:%M:%S",stamp),1,true));truth(string.find(csv,date("!%Y-%m-%dT%H:%M:%SZ",stamp),1,true));equal(row.time,stamp)
end)
test("Today starts at local midnight and ends at the next local midnight",function()
    local w,A,E=initial();w.wall=os.time({year=2026,month=10,day=20,hour=12,min=0,sec=0})
    local range=A.Ledger.Range("today")
    equal(range.first,os.time({year=2026,month=10,day=20,hour=0,min=0,sec=0}))
    equal(range.last,os.time({year=2026,month=10,day=21,hour=0,min=0,sec=0})-1)
end)
test("custom local periods include the final second of both full calendar days",function()
    local w,A,E=initial();local range=A.Ledger.Range("custom","2026-10-19","2026-10-20")
    equal(range.first,os.time({year=2026,month=10,day=19,hour=0,min=0,sec=0}))
    equal(range.last,os.time({year=2026,month=10,day=21,hour=0,min=0,sec=0})-1)
end)
test("spring DST periods follow local calendar boundaries rather than a fixed 24 hours",function()
    local w,A,E=initial();local range=A.Ledger.Range("custom","2026-03-08","2026-03-08")
    local expected=os.time({year=2026,month=3,day=9,hour=0,min=0,sec=0})-os.time({year=2026,month=3,day=8,hour=0,min=0,sec=0})
    equal(range.last-range.first+1,expected)
    if os.getenv("TZ")=="America/New_York"then equal(expected,23*3600)end
end)
test("fall DST periods include both repeated local hours",function()
    local w,A,E=initial();local range=A.Ledger.Range("custom","2026-11-01","2026-11-01")
    local expected=os.time({year=2026,month=11,day=2,hour=0,min=0,sec=0})-os.time({year=2026,month=11,day=1,hour=0,min=0,sec=0})
    equal(range.last-range.first+1,expected)
    if os.getenv("TZ")=="America/New_York"then equal(expected,25*3600)end
end)
test("ledger retention prunes at the local midnight without changing remaining timestamps",function()
    local w,A,E=initial();w.wall=os.time({year=2026,month=10,day=20,hour=12,min=0,sec=0});A.DB.data.settings.ledgerDays=1
    local first=A.Ledger.Range("today").first
    truth(A.Ledger.Record({kind="sale",name="Yesterday",quantity=1,amount=100,time=first-1},nil,true))
    truth(A.Ledger.Record({kind="sale",name="Today",quantity=1,amount=200,time=first},nil,true))
    equal(#A.Ledger.Records(),1);equal(A.Ledger.Records()[1].name,"Today");equal(A.Ledger.Records()[1].time,first)
end)
test("a local date rollover invalidates Today while same-day refreshes reuse its rows",function()
    local w,A,E=initial();w.wall=os.time({year=2026,month=10,day=20,hour=23,min=59,sec=59});record(A,"sale",100)
    local rows=A.Ledger.View(A.Ledger.Range("today"));equal(A.Ledger.View(A.Ledger.Range("today")),rows)
    w:advance(2);equal(#A.Ledger.View(A.Ledger.Range("today")),0)
end)
test("combat closes the Type menu and blocks direct type selection",function()
    local w,A,E=initial();E.OpenEditor();E.kindDropdown:OpenMenu();w.combat=true;w:event("PLAYER_REGEN_DISABLED")
    equal(E.kindDropdown:IsMenuOpen(),false);E.SetKind("tip_given");equal(E.kind,"sale")
end)
test("diagnostics identify local time and trade observation capability",function()
    local w,A,E=initial();local text=A.UI.DiagnosticsText()
    equal(string.find(text,"Test revision:",1,true),nil);truth(string.find(text,"Ledger time: local;",1,true));truth(string.find(text,"Trade tip tracking: enabled=true;",1,true))
end)
