local fresh,row,link,test,equal,near,truth,secret=...
local function world(saved)
    local w,A=fresh(saved)
    UnitName=function()return "Test creature"end
    C_Map={GetBestMapForUnit=function()return 10 end}
    GetInstanceInfo=function()return "Test zone","none",1,"Normal",5,false,false,0 end
    GetRealZoneText=function()return "Test zone"end
    Enum.TooltipDataType.Unit=2
    w:load();A.LootReference.classicQuery=nil;return w,A
end
local function guid(id,spawn,kind)
    return ((kind=="herbalism" or kind=="mining") and "GameObject" or "Creature").."-0-1-1-1-"..id.."-"..(spawn or 1)
end
local function observe(A,source,spawn,items,kind,group)
    truth(A.Drops.Observe(guid(source,spawn,kind),items,nil,group or "solo",kind or "loot"))
end
local function ids(rows)
    local result={};for _,r in ipairs(rows)do result[#result+1]=r.id end;return table.concat(result,",")
end
local function byID(rows)local result={};for _,r in ipairs(rows)do result[r.id]=r end;return result end
local function source()
    local w,A=world()
    w.items[100]={name="Quest token",quality=1,classID=12,vendor=0}
    w.items[101]={name="Common supply",quality=1,vendor=1}
    w.items[102]={name="Green supply",quality=2,vendor=1000}
    w.items[103]={name="Rare supply",quality=3,vendor=100000}
    C_QuestLog={IsOnQuest=function(id)return id==42 end,IsComplete=function()return false end}
    truth(A.LootReference.Register("Test rates",function()
        return {{id=100,rate=1,samples=400,questID=42,questItem=true},
            {id=101,rate=80,samples=400},{id=102,rate=20,samples=400},{id=103,rate=50,samples=400}}
    end,false))
    return w,A
end

test("drop display defaults to descending rates with all rarities and preserves observation tracking",function()
    local _,A=world();equal(A.DB.Settings().dropSort,"rate_desc");equal(A.DB.Settings().dropQuality,63)
    truth(A.DB.Settings().dropTracking);equal(A.DB.Settings().dropMode,"reference")
end)

test("needed quests precede rate-high rate-low and expected-value orderings",function()
    local _,A=source()
    equal(ids(A.Drops.Rows(1000)),"100,101,103,102")
    A.DB.Settings().dropSort="rate_asc";equal(ids(A.Drops.Rows(1000)),"100,102,103,101")
    A.DB.Settings().dropSort="value";equal(ids(A.Drops.Rows(1000)),"100,103,102,101")
    equal(A.LootReference.Rows(1000)[2].id,101)
end)

test("all 64 rarity masks filter only other drops and always retain a needed quest",function()
    local _,A=source()
    for mask=0,63 do
        A.DB.Settings().dropQuality=mask;local rows=A.Drops.Rows(1000);local found=byID(rows)
        equal(rows[1].id,100);truth(rows[1].wanted)
        for id,q in pairs({[101]=1,[102]=2,[103]=3})do
            equal(found[id]~=nil,math.floor(mask/2^q)%2==1)
        end
    end
    A.DB.Settings().dropQuality=0;equal(ids(A.Drops.Rows(1000)),"100")
end)

test("sorting and rarity changes invalidate cached views without changing source records",function()
    local _,A=source();local first=A.Drops.Rows(1000);equal(A.Drops.Rows(1000),first)
    local reference=A.LootReference.Rows(1000)
    A.DB.Settings().dropSort="rate_asc";local second=A.Drops.Rows(1000);truth(second~=first)
    A.DB.Settings().dropQuality=8;equal(ids(A.Drops.Rows(1000)),"100,103")
    equal(A.LootReference.Rows(1000),reference);equal(#reference,4);equal(reference[2].rate,80)
    equal(A.Drops.Profile().cells,0);equal(A.Drops.Profile().mobs,0)
end)

test("rate sorting has stable item-ID ties when drop rates and values are equal",function()
    local _,A=world();A.LootReference.Register("Ties",function()return {{id=103,rate=10},{id=101,rate=10},{id=102,rate=10}}end,false)
    for _,sort in ipairs({"rate_desc","rate_asc","value"})do A.DB.Settings().dropSort=sort;equal(ids(A.Drops.Rows(1000)),"101,102,103")end
end)

test("rarity filtering happens before the visible item limit so common items cannot displace rare ones",function()
    local w,A=source();A.DB.Settings().dropQuality=8;A.DB.Settings().dropRows=2
    A.Drops.Tooltip(GameTooltip,{type=2,guid=guid(1000)})
    equal(GameTooltip.lines[3].left,"|cffffd100Quest: |rQuest token")
    equal(GameTooltip.lines[4].left,"Rare supply");equal(#GameTooltip.lines,5)
    equal(w.requests,0)
end)

test("unknown rarity stays visible only with all selected and resolves after a bounded metadata request",function()
    local w,A=world();A.LootReference.Register("Unknown rarity",function()return {{id=200,rate=10,name="Uncached item"}}end,false)
    equal(#A.Drops.Rows(1000),1);A.DB.Settings().dropQuality=8;equal(#A.Drops.Rows(1000),0)
    truth(w.loadRequests>0);truth(w.loadRequests<=10)
    w.items[200]={name="Rare item",quality=3};A.Drops.Event("GET_ITEM_INFO_RECEIVED",200,true)
    equal(#A.Drops.Rows(1000),1);equal(A.Drops.Rows(1000)[1].quality,3)
end)

test("unknown-rarity requests stay bounded on a large filtered source",function()
    local w,A=world();local items={};for id=200,299 do items[#items+1]={id=id,rate=1,name="Unknown"}end
    A.LootReference.Register("Missing metadata",function()return items end,false)
    A.DB.Settings().dropQuality=8;equal(#A.Drops.Rows(1000),0);truth(w.loadRequests<=10)
    for _=1,100 do A.Drops.Rows(1000)end;truth(w.loadRequests<=10);equal(w.requests,0)
end)

test("reference mode fills missing items after Forever and Classic without combining sample counts",function()
    local w,A=world()
    for id=100,102 do w.items[id]={name="Item "..id,quality=id==101 and 2 or 3}end
    A.LootReference.Register("Forever fixture",function()return {{id=100,rate=25,samples=400}}end,false,"everloot")
    A.LootReference.classicQuery=function()return {{id=101,rate=15,origin="classic"}}end
    observe(A,1000,1,{{id=100,quantity=1},{id=101,quantity=1},{id=102,quantity=1}},nil,"solo")
    observe(A,1000,2,{{id=102,quantity=1}},nil,"party");observe(A,1000,3,{},nil,"raid")
    local rows,n=A.Drops.Rows(1000);local found=byID(rows);equal(n,3);equal(#rows,3)
    equal(found[100].origin,"everloot");equal(found[100].rate,25);equal(found[100].samples,400)
    equal(found[101].origin,"classic");equal(found[101].rate,15);equal(found[101].samples,nil)
    equal(found[102].origin,"personal");near(found[102].rate,200/3);equal(found[102].hits,2);equal(found[102].samples,3)
    A.DB.Settings().dropQuality=8;A.DB.Settings().dropSort="rate_asc"
    equal(ids(A.Drops.Rows(1000)),"100,102");equal(A.Drops.Profile().cells,4)
    A.DB.Settings().dropMode="observed";found=byID(A.Drops.Rows(1000));near(found[100].rate,100/3);equal(found[100].samples,3)
end)

test("a new personal gap appears while reference mode is active and survives reload with display choices",function()
    local _,A=world();A.LootReference.Register("Reference",function()return {{id=100,rate=10,samples=400}}end,false)
    equal(#A.Drops.Rows(1000),1)
    observe(A,1000,1,{{id=90000,quantity=1,quality=3,link=link(90000)}})
    observe(A,1000,2,{})
    A.DB.Settings().dropQuality=8;A.DB.Settings().dropSort="rate_asc"
    local found=byID(A.Drops.Rows(1000));equal(found[90000].samples,2);equal(found[90000].rate,50)
    local _,B=world(A.DB.data);B.LootReference.Register("Reference",function()return {{id=100,rate=10,samples=400}}end,false)
    equal(B.DB.Settings().dropQuality,8);equal(B.DB.Settings().dropSort,"rate_asc");equal(B.DB.Settings().dropMode,"reference")
    found=byID(B.Drops.Rows(1000));equal(found[90000].origin,"personal");equal(found[90000].samples,2);equal(found[90000].hits,1)
end)

test("personal-only and whole-source fallback obey display choices without crossing harvesting modes",function()
    local w,A=world();A.LootReference.Register("Empty",function()return {}end,false)
    w.items[100]={quality=3};w.items[101]={quality=2}
    observe(A,2000,1,{{id=100,quantity=1,quality=3}});observe(A,2000,2,{})
    observe(A,2000,3,{{id=101,quantity=1,quality=2}},"herbalism")
    A.DB.Settings().dropQuality=8
    equal(ids(A.Drops.Rows(2000)),"100");equal(#A.Drops.Rows(2000,"herbalism"),0)
    A.Drops.Tooltip(GameTooltip,{type=2,guid=guid(2000)})
    equal(GameTooltip.lines[2].right,"Personal fallback")
    truth(GameTooltip.lines[3].right:find("1/2 personal",1,true))
    A.DB.Settings().dropMode="observed";equal(ids(A.Drops.Rows(2000)),"100")
end)

test("inactive quest-only entries remain hidden and completed quests no longer bypass rarity choices",function()
    local _,A=source();C_QuestLog.IsOnQuest=function()return false end
    A.Drops.Event("QUEST_LOG_UPDATE");A.DB.Settings().dropQuality=0;equal(#A.Drops.Rows(1000),0)
    C_QuestLog.IsOnQuest=function()return true end;C_QuestLog.IsComplete=function()return true end
    A.Drops.Event("QUEST_LOG_UPDATE");equal(#A.Drops.Rows(1000),0)
    A.DB.Settings().dropQuality=63;local rows=A.Drops.Rows(1000);equal(rows[#rows].id,100);equal(rows[#rows].wanted,false)
end)

test("filtered-empty tooltips explain rarity selection without claiming the source has no data",function()
    local _,A=world();A.LootReference.Register("Reference",function()return {{id=100,rate=10,name="Normal item"}}end,false)
    A.DB.Settings().dropQuality=0;A.Drops.Tooltip(GameTooltip,{type=2,guid=guid(1000)})
    equal(GameTooltip.lines[3].left,"No drops match the selected rarities.")
end)

test("drop rarity menu has six colored checkboxes and operates independently of auction rarity",function()
    local _,A=world();A.DB.Settings().marketQuality=4;local ui=A.FarmingUI;ui.Show("drops");ui.dropQuality:OpenMenu()
    local options=ui.dropQuality.menuDescription.items;equal(#options,7);equal(options[1].data,"all")
    local names={"Poor","Common","Uncommon","Rare","Epic","Legendary"}
    local colors={"9d9d9d","ffffff","1eff00","0070dd","a335ee","ff8000"}
    for i=1,6 do equal(options[i+1].data,i-1);equal(options[i+1].text,"|cff"..colors[i]..names[i].."|r")end
    ui.dropQuality:Pick("all");equal(A.DB.Settings().dropQuality,0);equal(ui.dropQuality:GetText(),"Quest drops only")
    ui.dropQuality:Pick(3);equal(A.DB.Settings().dropQuality,8);equal(ui.dropQuality:GetText(),"|cff0070ddRare|r")
    equal(A.DB.Settings().marketQuality,4);truth(A.Drops.tipDirty)
end)

test("drop sort menu exposes both rate directions and expected-value sorting",function()
    local _,A=world();local ui=A.FarmingUI;ui.Show("drops");ui.dropSort:OpenMenu()
    equal(#ui.dropSort.menuDescription.items,3)
    for _,key in ipairs({"rate_desc","rate_asc","value"})do truth(ui.dropSort:Pick(key));equal(A.DB.Settings().dropSort,key)end
    equal(ui.dropSort:GetText(),"Expected item value");truth(ui.reference:GetText():find("Missing items and entire sources",1,true))
end)

test("tooltip item-limit editing validates its range and refreshes owned drop sections",function()
    local _,A=world();local ui=A.FarmingUI;ui.Show("drops");ui.maxDrops:SetText("10")
    ui.applyDrops.scripts.OnClick();equal(A.DB.Settings().dropRows,10);truth(A.Drops.tipDirty)
    ui.maxDrops:SetText("11");ui.applyDrops.scripts.OnClick();equal(A.DB.Settings().dropRows,10)
    equal(ui.message,"Choose 1-10 tooltip items.")
end)

test("changing sort and rarity rebuilds a currently owned tooltip without duplicate sections",function()
    local _,A=source();GameTooltip.data={type=2,guid=guid(1000)};GameTooltip.info={getterName="GetUnit",getterArgs={"mouseover"}}
    GameTooltip:Show();A.Drops.CheckTooltip()
    function GameTooltip:RebuildFromTooltipInfo()self:ClearLines();A.Drops.Tooltip(self,self.data)end
    local ui=A.FarmingUI;ui.Show("drops");ui.dropSort:Pick("rate_asc");A.Drops.CheckTooltip()
    equal(GameTooltip.lines[4].left,"Green supply")
    ui.dropQuality:Pick("all");ui.dropQuality:Pick(3);A.Drops.CheckTooltip()
    equal(GameTooltip.lines[3].left,"|cffffd100Quest: |rQuest token");equal(GameTooltip.lines[4].left,"Rare supply")
    local lines=#GameTooltip.lines;A.Drops.CheckTooltip();equal(#GameTooltip.lines,lines)
end)

test("invalid display settings repair safely and explicit none or expected-value choices survive upgrades",function()
    local _,A=world();local saved=A.DB.data;saved.settings.dropSort="invalid";saved.settings.dropQuality=64
    local _,B=world(saved);equal(B.DB.Settings().dropSort,"rate_desc");equal(B.DB.Settings().dropQuality,63)
    B.DB.Settings().dropSort="value";B.DB.Settings().dropQuality=0
    local _,C=world(B.DB.data);equal(C.DB.Settings().dropSort,"value");equal(C.DB.Settings().dropQuality,0)
    C.DB.Settings().dropSort=secret;C.DB.Settings().dropQuality=secret
    local _,E=world(C.DB.data);equal(E.DB.Settings().dropSort,"rate_desc");equal(E.DB.Settings().dropQuality,63)
end)

test("restricted or unsupported item rarities cannot break display filtering",function()
    local _,A=world();truth(A.Drops.QualityAllowed(63,secret));equal(A.Drops.QualityAllowed(8,secret),false)
    equal(A.Drops.QualityAllowed(8,6),false);truth(A.Drops.QualityAllowed(63,6))
    equal(A.Drops.QualityAllowed(8,3),true);equal(A.Drops.QualityAllowed(8,2),false)
end)

test("drop diagnostics expose sort rarity limit quest priority and personal-gap behavior",function()
    local _,A=world();local text=A.UI.DiagnosticsText()
    truth(text:find("Drop display: sort=rate_desc; rarity_mask=63; max_items=4; needed_quests=always_first; personal_gaps=true",1,true))
end)
