local fresh,row,link,test,equal,near,truth=...
local function world(saved)
    local w,A=fresh(saved)
    UnitName=function()return "Test creature"end
    C_Map={GetBestMapForUnit=function()return 10 end}
    GetInstanceInfo=function()return "Test zone","none",1,"Normal",5,false,false,0 end
    GetRealZoneText=function()return "Test zone"end
    Enum.TooltipDataType.Unit=2
    TooltipDataProcessor.AddTooltipPostCall=function(kind,callback)if kind==2 then w.unitTip=callback end end
    -- These fixtures exercise the original shared/personal fallback alone.
    w:load();A.LootReference.classicQuery=nil;return w,A
end
local function guid(id,spawn,kind)return (kind or "Creature") .. "-0-1-1-1-" .. id .. "-" .. (spawn or 1)end
local function named(id,name,suffix)return (link(id,suffix):gsub("%[Test%]",function()return "[" .. name .. "]"end))end
local function scan(w,A,entries)
    local snapshot=A.DB.NewSnapshot(A.Util.MarketKey(),#entries,w.wall)
    for _,r in ipairs(entries)do A.DB.AddRow(snapshot,r.id,r.quantity or 1,r.buyout or 100,r.link or link(r.id),0,r.quality,r.name)end
    truth(A.DB.Commit(snapshot));return snapshot
end
local function finish(A)
    for _=1,10000 do if not A.Market.job then return end;A.Market.Tick()end
    error("search did not finish")
end
local function analyze(A,view,sort,force)A.Market.Ensure(view or "listed",sort or "return",force);finish(A)end
local function items(rows)local map={};for _,r in ipairs(rows)do map[r.id]=r end;return map end
local function observe(A,source,id,spawn,group,kind,changes)
    local value={id=id,quantity=1,link=link(id)}
    for key,data in pairs(changes or {})do value[key]=data end
    truth(A.Drops.Observe(guid(source,spawn,kind=="herbalism" and "GameObject" or nil),{value},nil,group,kind))
end

test("rarity choices contain exactly six colored qualities and a select-all checkbox",function()
    local w,A=world();scan(w,A,{{id=100,quality=3}});w:openAH();A.MarketUI.Show()
    local ui=A.MarketUI;ui.qualityMenu:OpenMenu()
    local options=ui.qualityMenu.menuDescription.items
    equal(#options,7);equal(options[1].data,"all")
    local names={"Poor","Common","Uncommon","Rare","Epic","Legendary"}
    local colors={"9d9d9d","ffffff","1eff00","0070dd","a335ee","ff8000"}
    for index=1,6 do
        equal(options[index+1].data,index-1)
        equal(options[index+1].text,"|cff" .. colors[index] .. names[index] .. "|r")
    end
    ui.qualityMenu:Pick("all");ui.qualityMenu:Pick(3)
    equal(ui.qualityMenu:GetText(),"|cff0070ddRare|r")
    equal(ui.qualityMenu:Pick(6),false)
end)

test("older rarity masks retain supported choices and remove unsupported bits",function()
    local _,A=world();A.DB.Settings().marketQuality=511
    local _,B=world(A.DB.data);equal(B.DB.Settings().marketQuality,63)
    B.DB.Settings().marketQuality=64+8+4
    local _,C=world(B.DB.data);equal(C.DB.Settings().marketQuality,12)
    C.DB.Settings().marketQuality=256
    local _,D=world(C.DB.data);equal(D.DB.Settings().marketQuality,0)
    equal(D.Market.QualityAllowed(63,6),false)
end)

test("select all never includes artifact heirloom or token qualities",function()
    local w,A=world();local entries={}
    for q=0,8 do entries[#entries+1]={id=100+q,quality=q}end
    scan(w,A,entries);analyze(A)
    equal(#A.Market.rows,6);for _,r in ipairs(A.Market.rows)do truth(r.quality<=5)end
end)

test("modern keyword filters do not walk daily variant maps and reuse the current index",function()
    local w,A=world();local entries={}
    for id=1,700 do entries[#entries+1]={id=id,quality=2,link=named(id,id==400 and "Boots of the Owl" or "Other boots")}end
    for day=1,4 do scan(w,A,entries);if day<4 then w:advance(86400)end end
    local historyMaps={};for _,record in pairs(A.History.Days(A.Util.MarketInfo()))do historyMaps[record.variants]=true end
    local originalNext,historyReads,currentReads=next,0,0
    local current=A.DB.Snapshot().variants
    next=function(map,key)
        if historyMaps[map]then historyReads=historyReads+1 end
        if map==current then currentReads=currentReads+1 end
        return originalNext(map,key)
    end
    analyze(A);local index=A.Market.variantIndex
    historyReads,currentReads=0,0
    local calls=w.itemCalls or 0
    A.DB.Settings().marketSearch="OF the OWL";analyze(A)
    next=originalNext
    equal(A.Market.variantIndex,index);equal(historyReads,0)
    -- One current walk evaluates prices; there is no second index-building walk.
    equal(currentReads,701);equal(#A.Market.rows,1);equal(A.Market.rows[1].id,400)
    truth((w.itemCalls or 0)-calls<=2,"nonmatching names must not request native metadata")
end)

test("an empty keyword match does not price unrelated history or use pattern matching",function()
    local w,A=world();scan(w,A,{{id=100,link=named(100,"Boots 10% (sale).")},{id=101,link=named(101,"Boots of the Bear")}})
    local original=A.Market.Evaluate;local priced=0
    A.Market.Evaluate=function(...)priced=priced+1;return original(...)end
    A.DB.Settings().marketSearch="not-present";analyze(A);equal(#A.Market.rows,0);equal(priced,0)
    A.DB.Settings().marketSearch="10% (sale).";analyze(A);equal(#A.Market.rows,1);equal(A.Market.rows[1].id,100)
end)

test("item replies do not restart an in-progress search and schedule one refresh",function()
    local w,A=world();scan(w,A,{{id=100,quality=2},{id=101,quality=3}})
    A.Market.Ensure("listed");local job=A.Market.job;local builds=A.Market.builds
    A.MarketMetadata.Await(100,link(100),nil,true);w.items[100]={quality=2}
    A.Market.OnItemInfo(100);A.MarketMetadata.Tick(A.Market)
    A.Market.Ensure("listed");equal(A.Market.job,job);equal(A.Market.builds,builds)
    finish(A);truth(A.Market.metadataDirty)
    A.Market.Ensure("listed");finish(A);equal(A.Market.builds,builds+1)
    A.Market.Ensure("listed");equal(A.Market.builds,builds+1)
end)

test("keyword searches resolve modified names when an early item link is still generic",function()
    local w,A=world();w.items[100]={name="Imposing Gloves of the Owl",quality=2,classID=4}
    local generic="|cff1eff00|Hitem:100:0:0:0:0:0:0:0:40:0:0:0:1:5661|h[Imposing Gloves]|h|r"
    scan(w,A,{{id=100,link=generic,quality=2}})
    A.DB.Settings().marketSearch="of the owl";analyze(A)
    equal(#A.Market.rows,1);equal(A.Market.rows[1].name,"Imposing Gloves of the Owl")
    equal(A.Market.rows[1].variantKey,"100:0:b5661")
end)

test("generic modified names request missing data and enter the results without hovering",function()
    local w,A=world()
    local generic="|cff1eff00|Hitem:100:0:0:0:0:0:0:0:40:0:0:0:1:5661|h[Imposing Gloves]|h|r"
    scan(w,A,{{id=100,link=generic,quality=2}});A.DB.Settings().marketSearch="of the owl";analyze(A)
    equal(#A.Market.rows,0);truth(A.Market.reason:find("loading",1,true))
    A.Market.RequestVisibleInfo({});truth(w.loadRequests>0)
    w.items[100]={name="Imposing Gloves of the Owl",quality=2,classID=4}
    w:event("GET_ITEM_INFO_RECEIVED",100,true);A.Market.Tick();analyze(A)
    equal(#A.Market.rows,1);equal(A.Market.rows[1].name,"Imposing Gloves of the Owl")
end)

test("the bounded heap retains the same best five hundred and stable ties for every sort",function()
    local w,A=world();local entries={}
    for id=1,640 do entries[#entries+1]={id=id,quality=2,buyout=1000+(id*73)%700,link=named(id,"Sample " .. id)}end
    for day=1,4 do
        for _,r in ipairs(entries)do r.buyout=day==4 and 100+(r.id*37)%500 or 1000+(r.id*73)%700 end
        scan(w,A,entries);if day<4 then w:advance(86400)end
    end
    for _,sort in ipairs({"return","profit"})do
        local expected={}
        for _,r in ipairs(entries)do
            local baseline=1000+(r.id*73)%700
            local value=A.Market.Evaluate(r.buyout,{baseline,baseline,baseline},A.DB.Settings())
            value.key=tostring(r.id) .. ":0";expected[#expected+1]=value
        end
        table.sort(expected,function(a,b)
            local av,bv=sort=="profit" and a.profit or a.roi,sort=="profit" and b.profit or b.roi
            return av==bv and a.key<b.key or av>bv
        end)
        analyze(A,"listed",sort);equal(#A.Market.rows,500);equal(A.Market.eligible,640)
        for index=1,500 do equal(A.Market.rows[index].key,expected[index].key)end
    end
end)

test("reference gaps use personal rows while shared rates and denominators stay separate",function()
    local _,A=world();A.DB.Settings().dropMode="reference"
    A.LootReference.Register("Shared sample",function()return {{id=100,rate=25,samples=400}}end,false)
    observe(A,1000,100,1);observe(A,1000,101,2);observe(A,1000,101,3)
    local rows,n=A.Drops.Rows(1000);local by=items(rows)
    equal(#rows,2);equal(n,3);near(by[100].rate,25);equal(by[100].samples,400);equal(by[100].origin,"reference")
    near(by[101].rate,200/3);equal(by[101].samples,3);equal(by[101].hits,2);equal(by[101].origin,"personal")
    equal(A.LootReference.Rows(1000)[2],nil)
    A.DB.Settings().dropMode="observed";by=items(A.Drops.Rows(1000));near(by[100].rate,100/3)
end)

test("entire missing sources fall back to local solo party and raid samples",function()
    local w,A=world();A.DB.Settings().dropMode="reference"
    observe(A,2000,100,1,"solo");observe(A,2000,100,2,"party");observe(A,2000,101,3,"raid")
    local rows,n=A.Drops.Rows(2000);equal(n,3);equal(#rows,2);near(items(rows)[100].rate,200/3)
    w.unitTip(GameTooltip,{type=2,guid=guid(2000,4)})
    equal(GameTooltip.lines[2].right,"Personal fallback")
    truth(GameTooltip.lines[3].right:find("personal",1,true))
    local count=GameTooltip:NumLines();A.Drops.CheckTooltip();equal(GameTooltip:NumLines(),count)
end)

test("fallback labels distinguish counts without changing reference tooltip precision",function()
    local w,A=world();A.DB.Settings().dropMode="reference"
    A.LootReference.Register("Shared",function()return {{id=100,rate=.0001,samples=1000000}}end,false)
    observe(A,1000,101,1)
    w.unitTip(GameTooltip,{type=2,guid=guid(1000,2)})
    local reference,personal
    for _,line in ipairs(GameTooltip.lines)do
        if line.right and line.right:find("1000000 samples",1,true)then reference=line.right end
        if line.right and line.right:find("personal",1,true)then personal=line.right end
    end
    equal(reference,"<0.01% (1000000 samples)");equal(personal,"100.0% (1/1 personal)")
end)

test("personal gap filling respects quest eligibility source mode and current area",function()
    local _,A=world();A.DB.Settings().dropMode="reference"
    local active=false;C_QuestLog={IsOnQuest=function()return active end}
    observe(A,1000,100,1,nil,nil,{questItem=true,questID=42})
    observe(A,1000,101,2,nil,"skinning")
    observe(A,3000,102,1,nil,"herbalism")
    equal(#A.Drops.Rows(1000),0);equal(#A.Drops.Rows(1000,"skinning"),1)
    equal(#A.Drops.Rows(3000,"herbalism"),1);equal(#A.Drops.Rows(3000,"mining"),0)
    active=true;A.Drops.Event("QUEST_LOG_UPDATE");equal(#A.Drops.Rows(1000),1)
    C_Map.GetBestMapForUnit=function()return 11 end;equal(#A.Drops.Rows(1000),0)
end)

test("reset clears personal gap fillers while leaving reference rates intact",function()
    local _,A=world();A.DB.Settings().dropMode="reference"
    A.LootReference.Register("Shared",function()return {{id=100,rate=25,samples=40}}end,false)
    observe(A,1000,101,1);equal(#A.Drops.Rows(1000),2)
    truth(A.Drops.Reset("all"));local rows,n=A.Drops.Rows(1000)
    equal(#rows,1);equal(n,0);equal(rows[1].id,100);near(rows[1].rate,25)
end)

test("personal quest and rarity metadata can fill reference gaps without replacing the rate",function()
    local _,A=world();A.DB.Settings().dropMode="reference"
    local active=false;C_QuestLog={IsOnQuest=function()return active end}
    A.LootReference.Register("Shared",function()return {{id=100,rate=25,samples=40}}end,false)
    observe(A,1000,100,1,nil,nil,{questItem=true,questID=42,quality=3})
    equal(#A.Drops.Rows(1000),0)
    active=true;A.Drops.Event("QUEST_LOG_UPDATE");local rows=A.Drops.Rows(1000)
    equal(#rows,1);equal(rows[1].quality,3);equal(rows[1].rate,25);equal(rows[1].samples,40)
    equal(A.LootReference.Rows(1000)[1].questID,nil)
end)

test("new personal items invalidate only the view and survive character reload",function()
    local _,A=world();A.DB.Settings().dropMode="reference"
    observe(A,1000,100,1);local first=A.Drops.Rows(1000);equal(A.Drops.Rows(1000),first)
    observe(A,1000,101,2);equal(#A.Drops.Rows(1000),2)
    local _,B=world(A.DB.data);equal(#B.Drops.Rows(1000),2);equal(B.DB.Settings().dropMode,"reference")
end)
