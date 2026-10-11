-- Headless behavioral fixtures. Run from the repository root with Lua 5.1.
-- These fixtures cannot establish live-client API, UI, or persistence behavior.
local testCount = 0
local function equal(actual, expected, message)
    if actual ~= expected then error((message or "assertion") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2) end
end
local function near(actual, expected)
    if not actual or math.abs(actual - expected) > 0.000001 then error("numeric expectation failed", 2) end
end
local function truth(value, message) if not value then error(message or "expected true", 2) end end
local function test(name, callback)
    local ok, reason = pcall(callback)
    if not ok then error("FAIL " .. name .. ": " .. tostring(reason), 0) end
    testCount = testCount + 1
    print("PASS " .. name)
end

local secret = setmetatable({}, {
    __index = function() error("restricted value inspected") end,
    __tostring = function() error("restricted value formatted") end,
    __eq = function() error("restricted value compared") end,
    __lt = function() error("restricted value compared") end,
    __add = function() error("restricted value calculated") end,
})

local function link(id, suffix)
    return "|cff1eff00|Hitem:" .. id .. ":0:0:0:0:0:" .. (suffix or 0) .. ":0:60:0|h[Test]|h|r"
end

local function widget(name)
    local w = { name = name, shown = false, scripts = {}, lines = {}, points = {}, text = "", enabled = true }
    function w:SetScript(key, fn) self.scripts[key] = fn end
    function w:HookScript(key, fn)
        local old = self.scripts[key]
        self.scripts[key] = function(...) if old then old(...) end; fn(...) end
    end
    function w:RegisterEvent(event) self.events = self.events or {}; self.events[event] = true end
    function w:Show() self.shown = true; if self.scripts.OnShow then self.scripts.OnShow(self) end end
    function w:Hide() self.shown = false; if self.scripts.OnHide then self.scripts.OnHide(self) end end
    function w:IsShown() return self.shown end
    function w:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
    function w:SetParent(parent) self.parent = parent end
    function w:GetParent() return self.parent end
    function w:IsObjectType(kind) return kind == "Frame" end
    function w:GetFrameLevel() return self.level or 1 end
    function w:GetFrameStrata() return self.strata or (self.parent and self.parent:GetFrameStrata()) or "MEDIUM" end
    function w:SetFrameStrata(value) self.strata = value end
    function w:IsForbidden() return self.forbidden or false end
    function w:SetPoint(...) self.points[#self.points + 1] = { ... } end
    function w:ClearAllPoints() self.points = {} end
    function w:GetCenter() return 960, 540 end
    function w:SetSize(width, height) self.width, self.height = width, height end
    function w:SetWidth(width) self.width = width end
    function w:SetHeight(height) self.height = height end
    function w:CreateFontString() return widget() end
    function w:SetText(text) self.text = text end
    function w:SetTextColor(...) self.color = { ... } end
    function w:GetText() return self.text end
    function w:SetChecked(value) self.checked = value end
    function w:GetChecked() return self.checked end
    function w:SetEnabled(value) truth(type(value) == "boolean", "SetEnabled needs a boolean"); self.enabled = value end
    function w:SetFocus() self.focus = true end
    function w:ClearFocus() self.focus = false end
    function w:HasFocus() return self.focus or false end
    function w:HighlightText() self.highlighted = true end
    function w:SetScrollChild(child) self.scrollChild = child end
    function w:SetValue(value) self.value = value end
    function w:NumLines() return #self.lines end
    function w:GetItem() return "Test", self.link end
    function w:GetPrimaryTooltipInfo() return self.info end
    function w:GetPrimaryTooltipData() return self.data end
    function w:AddLine(left) self.lines[#self.lines + 1] = { left = left } end
    function w:AddDoubleLine(left, right) self.lines[#self.lines + 1] = { left = left, right = right } end
    function w:RebuildFromTooltipInfo()
        self.rebuilds = (self.rebuilds or 0) + 1
        self.lines = { {left = "Native item"} }
        if self.processor then self.processor(self, self.data) end
    end
    function w:SetFrameLevel(value) self.level = value end
    for _, method in ipairs({ "SetHitRectInsets", "SetClampedToScreen", "EnableMouse", "SetMovable", "RegisterForDrag", "StartMoving", "StopMovingOrSizing", "SetBackdrop", "SetBackdropColor", "SetBackdropBorderColor", "SetJustifyH", "SetFontObject", "SetMultiLine", "SetAutoFocus", "SetMaxLetters", "SetNumeric", "SetStatusBarTexture", "SetStatusBarColor", "SetMinMaxValues" }) do
        w[method] = function() end
    end
    return w
end

local function fresh(saved)
    local world = { wall = 1800000000, mono = 0, cpu = 0, rows = {}, requests = 0, loadRequests = 0, items = {}, realm = "FixtureRealm", region = 1, portal = "us", faction = "Horde", hardcore = false, combat = false, ready = true, interface = 16001, messages = {}, locations = {}, containers = {}, equipment = {} }
    _G.MSMarketValueDB = saved
    _G.issecretvalue = function(v) return rawequal(v, secret) end
    _G.canaccessvalue = function(v) return not rawequal(v, secret) end
    _G.GetServerTime = function() return world.wall end
    _G.time = GetServerTime
    _G.GetTime = function() return world.mono end
    _G.GetNormalizedRealmName = function() return world.realm end
    _G.GetRealmName = GetNormalizedRealmName
    _G.GetCurrentRegion = function() return world.region end
    _G.UnitFactionGroup = function() return world.faction end
    _G.C_GameRules = { IsHardcoreActive = function() return world.hardcore end }
    _G.GetCVar = function() return world.legacyPortal end
    _G.C_CVar = { GetCVar = function() return world.portal end }
    _G.InCombatLockdown = function() return world.combat end
    _G.GetBuildInfo = function() return "1.60.1", "70205", "Oct 3 2026", world.interface end
    _G.debugprofilestop = function() world.cpu = world.cpu + 0.01; return world.cpu end
    _G.DEFAULT_CHAT_FRAME = { AddMessage = function(_, message) world.messages[#world.messages + 1] = message end }
    _G.SlashCmdList, _G.UISpecialFrames = {}, {}
    _G.UIParent = widget("UIParent")
    UIParent:Show()
    _G.LibStub, _G.AuctionHouseFrame, _G.AuctionHouseFrameDisplayMode = nil, nil, nil
    _G.ProfessionsFrame, _G.C_TradeSkillUI = nil, nil
    _G.ChatFrameUtil, _G.ChatFrame_OpenChat = nil, nil
    _G.WOW_PROJECT_MAINLINE, _G.WOW_PROJECT_CAMELOT = 1, 14
    _G.WOW_PROJECT_ID = WOW_PROJECT_CAMELOT
    _G.strmatch = string.match
    _G.PanelTemplates_TabResize = function(tab) tab.resized = true end
    _G.PanelTemplates_DeselectTab = function(tab) tab.selected = false end
    _G.PanelTemplates_SelectTab = function(tab) tab.selected = true end
    _G.GameFontHighlightSmall = {}
    _G.GameTooltip, _G.ItemRefTooltip = widget("GameTooltip"), widget("ItemRefTooltip")
    _G.ShoppingTooltip1, _G.ShoppingTooltip2 = widget("ShoppingTooltip1"), widget("ShoppingTooltip2")
    _G.ItemRefShoppingTooltip1, _G.ItemRefShoppingTooltip2 = nil, nil
    _G.Enum = { TooltipDataType = { Item = 0 } }
    _G.C_Container = { GetContainerItemInfo = function(bag, slot)
        world.containerReads = (world.containerReads or 0) + 1
        return world.containers[tostring(bag) .. ":" .. tostring(slot)]
    end }
    _G.ItemLocation = { CreateFromEquipmentSlot = function(_, slot) return world.equipment[slot] or {} end }
    _G.date = os.date
    _G.CreateFrame = function(_, name, parent, template)
        world.createdFrames = (world.createdFrames or 0) + 1
        local w = widget(name); w.parent, w.template = parent, template
        if template == "PortraitFrameTemplate" then
            w.CloseButton = widget()
            function w:SetTitle(text) self.title = text end
        end
        if name then _G[name] = w end
        return w
    end
    _G.TooltipDataProcessor = { AddTooltipPostCall = function(_, callback)
        world.tooltipCallback = callback
        for _, t in ipairs({ GameTooltip, ItemRefTooltip, ShoppingTooltip1, ShoppingTooltip2 }) do t.processor = callback end
    end }
    _G.C_AuctionHouse = {
        ReplicateItems = function() world.requests = world.requests + 1; if world.refuse then error("native refusal") end end,
        IsThrottledMessageSystemReady = function() return world.ready end,
        GetNumReplicateItems = function() return world.overrideCount or #world.rows end,
        GetReplicateItemInfo = function(index)
            local row = world.rows[index + 1]
            if not row then error("bad auction index") end
            local quantity, buyout = row.quantity, row.buyout
            -- Truly pending price data differs from a missing item name.
            if row.allInfo == false and not row.publicPrices then quantity, buyout = nil, nil end
            return nil, nil, quantity, 2, true, 20, nil, 0, 0,
                   buyout, 0, nil, nil, nil, nil, row.saleStatus or 0, row.id, row.allInfo
        end,
        GetReplicateItemLink = function(index) return world.rows[index + 1].link end,
    }
    _G.hooksecurefunc = function(tbl, key, callback)
        local original = tbl[key]
        tbl[key] = function(...) original(...); callback(...) end
    end
    _G.C_Item = {
        GetItemLocation = function(guid) return world.locations[guid] end,
        GetItemID = function(location) return location.itemID end,
        GetStackCount = function(location)
            world.stackReads = (world.stackReads or 0) + 1
            return location.stackCount
        end,
        GetItemCount = function() error("total ownership is not a hovered stack") end,
        GetItemMaxStackSize = function() error("maximum stack size is not a hovered stack") end,
        RequestLoadItemDataByID = function() world.loadRequests = world.loadRequests + 1 end,
        GetItemInfo = function(item)
            world.itemCalls = (world.itemCalls or 0) + 1
            local id = type(item) == "number" and item or tonumber(string.match(item, "item:(%d+)"))
            local info = world.items[id]
            if not info then return nil end
            return info.name or "Fixture Item", type(item) == "string" and item or link(id),
                   info.quality or 2, info.level or 17, 0, "Armor", "Cloth", 1,
                   info.equipLoc or "INVTYPE_CHEST", 1, info.vendor or 100,
                   info.classID or 4, info.subclassID or 1, 2, 0, nil, false
        end,
    }
    local A = {}
    for line in io.lines("MSMarketValue/MSMarketValue.toc") do
        if string.match(line, "%.lua$") then
            local file = string.gsub(line, "\\", "/")
            assert(loadfile("MSMarketValue/" .. file))("MSMarketValue", A)
        end
    end
    world.A = A
    function world:makeAH()
        local ah = widget("AuctionHouseFrame")
        ah:SetSize(800, 538)
        ah:SetParent(UIParent)
        ah.Tabs, ah.numTabs = { widget(), widget(), widget() }, 3
        ah.BuyContent, ah.SellContent, ah.AuctionsContent = widget(), widget(), widget()
        _G.AuctionHouseFrameDisplayMode = { Buy = { "BuyContent" }, Sell = { "SellContent" }, Auctions = { "AuctionsContent" } }
        function ah:SetTitle(text) self.title = text end
        function ah:SetDisplayMode(mode)
            self.displayMode = mode
            for _, modes in pairs(AuctionHouseFrameDisplayMode) do
                for _, key in ipairs(modes) do self[key]:Hide() end
            end
            for _, key in ipairs(mode) do self[key]:Show() end
        end
        ah:SetScript("OnShow", function(self) self:SetDisplayMode(AuctionHouseFrameDisplayMode.Buy) end)
        _G.AuctionHouseFrame = ah
        return ah
    end
    function world:event(event, arg1, arg2)
        A.eventFrame.scripts.OnEvent(A.eventFrame, event, arg1, arg2)
    end
    function world:openAH()
        local ah = AuctionHouseFrame or self:makeAH()
        ah:Show()
        self:event("AUCTION_HOUSE_SHOW")
        return ah
    end
    function world:load()
        A.eventFrame.scripts.OnEvent(A.eventFrame, "ADDON_LOADED", "MSMarketValue")
        A.eventFrame.scripts.OnEvent(A.eventFrame, "PLAYER_LOGIN")
        A.auctionOpen = true
    end
    function world:advance(seconds)
        self.mono, self.wall = self.mono + seconds, self.wall + seconds
        A.Scanner.Tick()
    end
    function world:start(rows)
        self.rows = rows
        self:load()
        truth(A.Scanner.Start())
        A.Scanner.OnResponse()
    end
    function world:drain()
        for _ = 1, 10000 do
            if not A.Scanner.active then return end
            self:advance(0.05)
        end
        error("scan did not terminate")
    end
    function world:openProfession()
        self.recipes, self.recipeIDs = self.recipes or {}, self.recipeIDs or {}
        self.allocations, self.modified = self.allocations or {}, self.modified or {}
        _G.C_TradeSkillUI = {
            GetAllRecipeIDs = function() self.catalogCalls = (self.catalogCalls or 0) + 1; return self.recipeIDs end,
            GetRecipeInfo = function(id) return self.recipes[id] and self.recipes[id].info end,
            GetRecipeSchematic = function(id) return self.recipes[id] and self.recipes[id].schematic end,
            GetRecipeOutputItemData = function(id, reagents) self.outputReagents = reagents; return self.recipes[id] and self.recipes[id].output end,
            GetBaseProfessionInfo = function() return { professionID = self.professionID or 164 } end,
            OpenRecipe = function(id) self.selectedID = id; self.openRecipeCalls = (self.openRecipeCalls or 0) + 1 end,
        }
        local profession = widget("ProfessionsFrame")
        profession:SetParent(UIParent)
        for key, level in pairs({ NineSlice = 500, PortraitContainer = 400, TitleContainer = 510, CloseButton = 510 }) do
            profession[key] = widget()
            profession[key]:SetParent(profession)
            profession[key]:SetFrameLevel(level)
            profession[key]:Show()
        end
        local form = widget()
        local transaction = {
            CreateReagentInfoTbl = function() return self.allocations end,
            CreateCraftingReagentInfoTbl = function() return self.modified end,
            GetAllocationItemGUID = function() return nil end,
        }
        function form:GetRecipeInfo() return self.recipesWorld.recipes[self.recipesWorld.selectedID] and self.recipesWorld.recipes[self.recipesWorld.selectedID].info end
        function form:GetTransaction() return transaction end
        function form:GetCurrentRecipeLevel() return 1 end
        function form:GetOutputOverrideQualityID() return self.recipesWorld.outputQuality end
        form.recipesWorld = self
        profession.CraftingPage = widget()
        profession.CraftingPage:SetParent(profession)
        profession.CraftingPage:SetFrameLevel(100)
        profession.CraftingPage.SchematicForm = form
        profession.CraftingPage:Show(); profession:Show()
        _G.ProfessionsFrame = profession
        self.form = form
        return form
    end
    return world, A
end

local function row(id, quantity, buyout, suffix, allInfo)
    return { id = id, quantity = quantity, buyout = buyout, link = link(id, suffix), allInfo = allInfo == nil and true or allInfo }
end

local function initial()
    local w, A = fresh()
    w:start({row(100, 1, 900)})
    w:drain()
    return w, A, A.DB.Snapshot()
end

local function newScan(w, rows)
    w:advance(901)
    w.rows = rows
    truth(w.A.Scanner.Start())
    w.A.Scanner.OnResponse()
end

test("saved data is untouched until ADDON_LOADED", function()
    local saved = {schema = 1, settings = {}, markets = {}}
    local _, A = fresh(saved)
    equal(MSMarketValueDB, saved)
    equal(A.DB.data, nil)
end)
test("modern startup installs the tooltip callback and scan observer", function()
    local w, A = fresh(); w:load()
    truth(A.Tooltips.installed); truth(A.Scanner.observerInstalled); equal(A.disabledReason, nil)
end)
test("scan reads zero-based first and last rows, normalizes stacks and excludes bids and sold auctions", function()
    local w, A = fresh()
    local sold = row(103, 1, 50); sold.saleStatus = 1
    w:start({row(100, 10, 1000), row(100, 2, 300, -5), row(101, 1, 0), sold, row(104, 5, 555)})
    w:drain()
    local snap = A.DB.Snapshot()
    equal(snap.totalRows, 5); equal(snap.processedRows, 5); equal(snap.distinctItems, 2)
    equal(snap.prices[100].low, 100); equal(snap.prices[100].units, 12)
    equal(snap.variants["100:-5"].low, 150)
    equal(snap.prices[101], nil); equal(snap.prices[103], nil)
    near(snap.prices[104].low, 111)
    equal(snap.bidOnlyRows, 1); equal(snap.soldRows, 1)
end)
test("a complete new scan replaces all previous items without historical carryover", function()
    local w, A, old = initial()
    newScan(w, {row(200, 1, 3000)}); w:drain()
    truth(A.DB.Snapshot() ~= old); equal(A.DB.Price(100), nil); equal(A.DB.Price(200).low, 3000)
end)
test("a completed empty-market response replaces the previous snapshot", function()
    local w, A = initial(); newScan(w, {})
    equal(A.Scanner.state, "COMPLETE"); equal(A.DB.Snapshot().totalRows, 0); equal(A.DB.Price(100), nil)
end)
test("starting and partly processing a scan does not alter the old snapshot", function()
    local w, A, old = initial(); local rows = {}
    for i = 1, 250 do rows[i] = row(200 + i, 1, i) end
    newScan(w, rows); A.Scanner.Tick()
    equal(A.DB.Snapshot(), old); equal(A.Scanner.work.processedRows, 100)
    A.Scanner.Stop(); equal(A.DB.Snapshot(), old)
end)
test("processing yields within the row budget", function()
    local w, A = fresh(); local rows = {}
    for i = 1, 501 do rows[i] = row(1000 + i, 1, i) end
    w:start(rows); A.Scanner.Tick(); equal(A.Scanner.work.processedRows, 100)
    w:drain(); equal(A.DB.Snapshot().processedRows, 501)
end)
test("processing also yields on its CPU budget", function()
    local w, A = fresh(); local rows = {}
    for i = 1, 50 do rows[i] = row(1000 + i, 1, i) end
    w:start(rows)
    debugprofilestop = function() w.cpu = w.cpu + 2; return w.cpu end
    A.Scanner.Tick(); equal(A.Scanner.work.processedRows, 2)
    w:drain(); equal(A.DB.Snapshot().processedRows, 50)
end)
test("delayed item data retries without double-counting or repeated load requests", function()
    local w, A = fresh()
    w:start({row(100, 1, 100, 0, false),row(101, 1, 200),row(100, 1, 300, 0, false)})
    A.Scanner.Tick(); equal(A.Scanner.state, "RESOLVING"); equal(w.loadRequests, 1)
    w.rows[1].allInfo, w.rows[3].allInfo = true, true
    w:advance(0.6); w:drain()
    equal(A.DB.Snapshot().processedRows, 3); equal(A.DB.Snapshot().prices[100].auctions, 2)
end)
test("unresolved item data timeout keeps the old snapshot", function()
    local w, A, old = initial()
    newScan(w, {row(200, 1, 100, 0, false)})
    A.Scanner.Tick(); w:advance(46)
    equal(A.Scanner.state, "PAUSED"); equal(A.DB.Snapshot(), old)
end)
test("request timeout and a late response keep the old snapshot", function()
    local w, A, old = initial(); w:advance(901); truth(A.Scanner.Start()); w:advance(121)
    equal(A.Scanner.state, "PAUSED"); A.Scanner.OnResponse(); equal(A.DB.Snapshot(), old)
end)
test("auction-house close pauses safely", function()
    local w, A, old = initial(); newScan(w, {row(200, 1, 100)})
    A.auctionOpen = false; A.Scanner.Tick(); equal(A.Scanner.state, "PAUSED"); equal(A.DB.Snapshot(), old)
end)
test("combat pauses a scan and retains public tooltip prices", function()
    local w, A, old = initial(); newScan(w, {row(200, 1, 100)})
    w.combat = true; A.Scanner.Tick(); equal(A.DB.Snapshot(), old)
    GameTooltip.data = {id = 100}; A.Tooltips.Handle(GameTooltip, GameTooltip.data)
    truth(GameTooltip:NumLines() > 0); truth(w.itemCalls > 0); equal(A.Scanner.state, "PAUSED")
end)
test("another addon's replication request invalidates the staged snapshot", function()
    local w, A, old = initial(); newScan(w, {row(200, 1, 100)})
    C_AuctionHouse.ReplicateItems(); equal(A.Scanner.state, "FAILED"); equal(A.DB.Snapshot(), old)
end)
test("changed replication count invalidates the staged snapshot", function()
    local w, A, old = initial(); newScan(w, {row(200, 1, 100)})
    w.overrideCount = 2; A.Scanner.Tick(); equal(A.Scanner.state, "FAILED"); equal(A.DB.Snapshot(), old)
end)
test("same-count replication events continue processing without restarting or double-counting", function()
    local w, A, old = initial(); local rows = {}
    for i = 1, 250 do rows[i] = row(200, 1, i) end
    newScan(w, rows); A.Scanner.Tick()
    local staged = A.Scanner.work
    equal(staged.processedRows, 100)
    w:event("REPLICATE_ITEM_LIST_UPDATE"); w:event("REPLICATE_ITEM_LIST_UPDATE")
    equal(A.Scanner.state, "PROCESSING"); equal(A.Scanner.work, staged)
    equal(staged.processedRows, 100); equal(A.DB.Snapshot(), old)
    w:drain(); equal(A.Scanner.state, "COMPLETE")
    equal(A.DB.Snapshot().processedRows, 250)
    equal(A.DB.Price(200).auctions, 250); equal(A.DB.Price(200).units, 250)
    equal(w.requests, 2); equal(A.Scanner.responseCount, 3); equal(A.Scanner.dataUpdateCount, 2)
end)
test("replication updates accelerate pending data retries without resetting a partial retry pass", function()
    local w, A = fresh(); local rows = {}
    for i = 1, 205 do rows[i] = row(200, 1, 500, 0, false) end
    w:start(rows); A.Scanner.Tick(); A.Scanner.Tick(); A.Scanner.Tick()
    equal(A.Scanner.state, "RESOLVING"); equal(w.loadRequests, 1)
    for i = 1, 50 do rows[i].allInfo = true end
    w:event("REPLICATE_ITEM_LIST_UPDATE"); A.Scanner.Tick()
    equal(A.Scanner.work.processedRows, 50); equal(A.Scanner.retryCursor, 101)
    for i = 101, 120 do rows[i].allInfo = true end
    w:event("REPLICATE_ITEM_LIST_UPDATE"); A.Scanner.Tick(); A.Scanner.Tick()
    equal(A.Scanner.work.processedRows, 70); equal(#A.Scanner.pending, 135)
    for _, r in ipairs(rows) do r.allInfo = true end
    w:event("REPLICATE_ITEM_LIST_UPDATE"); A.Scanner.Tick()
    equal(A.Scanner.work.processedRows, 170)
    w:event("REPLICATE_ITEM_LIST_UPDATE"); A.Scanner.Tick()
    equal(A.Scanner.state, "COMPLETE"); equal(A.DB.Price(200).auctions, 205)
    equal(A.DB.Price(200).units, 205); equal(w.requests, 1); equal(w.loadRequests, 1)
end)
test("changed or unreadable counts in additional replication events keep the old snapshot", function()
    for _, count in ipairs({2, secret, -1, 1.5}) do
        local w, A, old = initial(); newScan(w, {row(200, 1, 100)})
        w.overrideCount = count; w:event("REPLICATE_ITEM_LIST_UPDATE")
        equal(A.Scanner.state, "FAILED"); equal(A.DB.Snapshot(), old)
    end
end)
test("late replication events after completion do not reopen or modify the saved scan", function()
    local w, A, old = initial(); local responses = A.Scanner.responseCount
    w:event("REPLICATE_ITEM_LIST_UPDATE"); equal(A.Scanner.state, "COMPLETE")
    equal(A.DB.Snapshot(), old); equal(A.Scanner.responseCount, responses); equal(w.requests, 1)
end)
test("switching realm does not expose a different market's prices", function()
    local w, A = initial(); w.realm = "AnotherRealm"
    equal(A.DB.Snapshot(), nil); equal(A.DB.Price(100), nil)
end)
test("changing market during a scan prevents commit", function()
    local w, A = initial(); newScan(w, {row(200, 1, 100)})
    w.region = 2; A.Scanner.Tick(); equal(A.Scanner.state, "FAILED")
end)
test("malformed auction quantities fail without replacing the snapshot", function()
    local w, A, old = initial(); newScan(w, {row(200, 0, 100)})
    w:drain(); equal(A.Scanner.state, "FAILED"); equal(A.DB.Snapshot(), old)
end)
test("negative buyouts and fractional item IDs are refused", function()
    for _, r in ipairs({row(200, 1, -1), row(200.5, 1, 100)}) do
        local w, A = fresh(); w:start({r}); w:drain(); equal(A.Scanner.state, "FAILED"); equal(A.DB.Snapshot(), nil)
    end
end)
test("oversized and restricted replication counts are refused", function()
    for _, count in ipairs({1000001, secret, -1, 1.5}) do
        local w, A = fresh(); w:load(); w.overrideCount = count
        truth(A.Scanner.Start()); A.Scanner.OnResponse(); equal(A.Scanner.state, "FAILED")
    end
end)
test("restricted auction fields are neither compared nor formatted", function()
    local w, A, old = initial(); local r = row(200, 1, 100); r.buyout = secret
    newScan(w, {r}); w:drain(); equal(A.Scanner.state, "FAILED"); equal(A.DB.Snapshot(), old)
end)
test("missing auction links retain a labeled item-wide price", function()
    local w, A = fresh(); local r = row(100, 2, 300); r.link = nil
    w:start({r}); w:drain()
    local price, mode = A.DB.Price(100, link(100, -5)); equal(price.low, 150); equal(mode, "item-wide")
end)
test("server readiness, combat, and auction availability gate requests", function()
    local w, A = fresh(); w:load(); w.ready = false; equal(A.Scanner.Start(), false)
    w.ready = true; w.combat = true; equal(A.Scanner.Start(), false)
    w.combat = false; A.auctionOpen = false; equal(A.Scanner.Start(), false); equal(w.requests, 0)
end)
test("a client request refusal leaves prices and cooldown intact", function()
    local w, A, old = initial(); w:advance(901); w.refuse = true
    equal(A.Scanner.Start(), false); equal(A.DB.Snapshot(), old); truth(A.Scanner.RemainingCooldown() > 0)
end)
test("full-scan cooldown persists through an independently loaded addon session", function()
    local _, A = initial(); local saved = A.DB.data
    local w2, A2 = fresh(saved); w2:load()
    equal(A2.Scanner.Start(), false); equal(w2.requests, 0); equal(A2.DB.Price(100).low, 900)
end)
test("full saved-data serialization restores prices in a new session", function()
    local _, A = initial()
    local function serialize(v)
        if type(v) == "string" then return string.format("%q", v) end
        if type(v) ~= "table" then return tostring(v) end
        local parts = {}
        for k, value in pairs(v) do parts[#parts + 1] = "[" .. serialize(k) .. "]=" .. serialize(value) end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    local saved = assert(loadstring("return " .. serialize(A.DB.data)))()
    local w2, A2 = fresh(saved); w2:load()
    equal(A2.DB.Price(100).low, 900); equal(A2.DB.Snapshot().complete, true)
end)
test("future schemas remain untouched and disable this build", function()
    local saved = {schema = 99, markets = {retained = true}, settings = {}}
    local w, A = fresh(saved); w:load()
    truth(A.disabledReason); equal(MSMarketValueDB, saved); equal(saved.markets.retained, true); equal(A.DB.data, nil)
    local _, A2 = initial(); local valid = A2.DB.Snapshot(); valid.bidOnlyItems = "malformed"
    local w3, A3 = fresh(A2.DB.data); w3:load(); equal(A3.DB.Snapshot(), nil)
end)
test("unsupported clients are disabled before saved data is initialized", function()
    local w, A = fresh(); w.interface = 11200; w:load()
    truth(A.disabledReason); equal(MSMarketValueDB, nil); equal(A.Tooltips.installed, nil)
end)
test("item-wide and exact signed-suffix prices are distinguishable", function()
    local w, A = fresh(); w:start({row(100, 1, 1000, 0),row(100, 1, 5000, -5)}); w:drain()
    local price, mode = A.DB.Price(100, link(100, -5)); equal(price.low, 5000); equal(mode, "variant")
    price, mode = A.DB.Price(100, link(100, 9)); equal(price.low, 1000); equal(mode, "item-wide")
end)
test("green armor and weapons have distinct probability-weighted values", function()
    local w, A = fresh(); w:start({row(10940, 1, 100),row(10939, 1, 200),row(10978, 1, 1000)}); w:drain()
    w.items[300] = {level = 17, quality = 2, classID = 4}
    w.items[301] = {level = 17, quality = 2, classID = 2, subclassID = 7, equipLoc = "INVTYPE_WEAPON"}
    local armor = A.Valuation.Outcomes(A.Valuation.ItemInfo(300))
    local weapon = A.Valuation.Outcomes(A.Valuation.ItemInfo(301))
    near(A.Valuation.DisenchantValue(armor).value, 297.5)
    near(A.Valuation.DisenchantValue(weapon).value, 325)
end)
test("a missing possible material prevents a complete DE total", function()
    local w, A = fresh(); w:start({row(10940, 1, 100),row(10939, 1, 200)}); w:drain()
    w.items[300] = {level = 17}
    local outcomes = A.Valuation.Outcomes(A.Valuation.ItemInfo(300))
    local value = A.Valuation.DisenchantValue(outcomes)
    equal(value.complete, false); equal(value.value, nil); equal(#value.missing, 1); near(value.subtotal, 247.5)
end)
test("disenchant estimates use item level rather than required character level", function()
    local w, A = fresh(); w:load(); w.items[300] = {level = 26}
    local outcomes = A.Valuation.Outcomes(A.Valuation.ItemInfo(300)); equal(outcomes[1].id, 11083)
end)
test("all green bracket boundaries have exhaustive, normalized outcomes", function()
    local w, A = fresh(); w:load()
    for _, bracket in ipairs(A.DEProfile.green) do
        for _, level in ipairs({bracket[1], bracket[2]}) do
            for _, class in ipairs({2,4}) do
                local outcomes = A.Valuation.Outcomes({id = 300, quality = 2, level = level, classID = class, subclassID = 1, equipLoc = "INVTYPE_WEAPON"})
                local total = 0
                for _, outcome in ipairs(outcomes) do
                    total = total + outcome.probability
                    truth(outcome.min <= outcome.max); truth(outcome.probability > 0)
                end
                near(total, 1)
            end
        end
    end
end)
test("rare and epic profiles retain quantity and probability distinctions", function()
    local w, A = fresh(); w:load()
    local rare = A.Valuation.Outcomes({id=300, quality=3, level=60, classID=4, subclassID=1, equipLoc="INVTYPE_CHEST"})
    near(rare[1].probability, 0.995); equal(rare[2].id, 20725); near(rare[2].probability, 0.005)
    local epic = A.Valuation.Outcomes({id=300, quality=4, level=65, classID=4, subclassID=1, equipLoc="INVTYPE_CHEST"})
    equal(epic[1].min,1); equal(epic[1].max,2); near(epic[1].expected,1.5)
end)
test("white gear, bags, shirts, fishing poles and excluded items have no DE estimate", function()
    local w, A = fresh(); w:load()
    for _, info in ipairs({
        {id=300, quality=1, level=20, classID=4, subclassID=1, equipLoc="INVTYPE_CHEST"},
        {id=300, quality=2, level=20, classID=1, subclassID=0, equipLoc="INVTYPE_BAG"},
        {id=300, quality=2, level=20, classID=4, subclassID=0, equipLoc="INVTYPE_BODY"},
        {id=300, quality=2, level=20, classID=2, subclassID=20, equipLoc="INVTYPE_2HWEAPON"},
    }) do equal(A.Valuation.Outcomes(info), nil) end
    A.DB.Exclude(300, true)
    equal(A.Valuation.Outcomes({id=300, quality=2, level=20, classID=4, subclassID=1, equipLoc="INVTYPE_CHEST"}), nil)
end)
test("unknown item-level brackets are not extrapolated", function()
    local w, A = fresh(); w:load()
    local outcomes, reason = A.Valuation.Outcomes({id=300, quality=2, level=66, classID=4, subclassID=1, equipLoc="INVTYPE_CHEST"})
    equal(outcomes, nil); equal(reason, "no-profile")
end)
test("duplicate item-tooltip callbacks append only one section", function()
    local w, A = initial(); w.items[100] = {level = 17}; GameTooltip.data = {id = 100}; GameTooltip.link = link(100)
    A.Tooltips.Handle(GameTooltip, GameTooltip.data); local count = GameTooltip:NumLines()
    truth(count > 2); A.Tooltips.Handle(GameTooltip, GameTooltip.data); equal(GameTooltip:NumLines(), count)
end)
test("restricted item IDs and tooltip data are ignored without inspecting them", function()
    local w, A = fresh(); w:load()
    A.Tooltips.Handle(GameTooltip, {id = secret}); A.Tooltips.Handle(GameTooltip, secret)
    equal(GameTooltip:NumLines(), 0)
end)
test("forbidden and unregistered tooltips receive no addon lines", function()
    local w, A = fresh(); w:load(); GameTooltip.forbidden = true
    A.Tooltips.Handle(GameTooltip, {id = 100}); equal(GameTooltip:NumLines(), 0)
    local other = widget(); A.Tooltips.Handle(other, {id = 100}); equal(other:NumLines(), 0)
end)
test("uncached item tooltips keep AH information and mark vendor/DE as loading", function()
    local _, A = initial(); local lines = A.Tooltips.Lines(100, link(100))
    equal(lines[2].right, "Item data loading"); equal(lines[3].right, "9s 00c")
end)
test("stale prices are still available and explicitly marked", function()
    local w, A = initial(); w:advance(86401)
    truth(A.DB.IsStale(A.DB.Snapshot())); local lines = A.Tooltips.Lines(100, link(100))
    truth(string.find(lines[#lines].right, "stale")); equal(A.DB.Price(100).low, 900)
end)
test("UI exposes all settings and generates copyable diagnostics", function()
    local w, A = initial(); A.UI.Create(); A.UI.frame:Show()
    truth(A.UI.checks.showVendor); truth(A.UI.checks.showAuction); truth(A.UI.checks.showDisenchant)
    truth(A.UI.checks.showMaterials); truth(A.UI.checks.showAge); equal(A.UI.checks.openAtAH, nil)
    A.UI.ShowDiagnostics(); truth(A.UI.diagnostics:IsShown()); truth(A.UI.diagnosticsEdit.highlighted)
    truth(string.find(A.UI.diagnosticsEdit:GetText(), "70205"))
end)
test("slash commands use the loaded addon and unknown commands provide help", function()
    local w, A = fresh(); w:load(); SlashCmdList.MSMARKETVALUE(""); truth(A.UI.frame:IsShown())
    SlashCmdList.MSMARKETVALUE("status"); SlashCmdList.MSMARKETVALUE("unknown"); truth(#w.messages >= 3)
end)
test("money formatting distinguishes missing, zero, sub-copper, silver and gold values", function()
    local _, A = fresh()
    equal(A.Util.Money(nil), "Unavailable"); equal(A.Util.Money(0), "0c")
    equal(A.Util.Money(0.5), "<1c"); equal(A.Util.Money(123), "1s 23c")
    equal(A.Util.Money(12345), "1g 23s 45c"); equal(A.Util.Money(secret), "Unavailable")
    equal(A.Util.Money(9007199254740991), "900719925474g 09s 91c")
end)

test("empty normalized realm and zero native region use public realm and login portal", function()
    local w, A = fresh(); w.region = 0; w.realm = "Test Realm-Name"
    GetNormalizedRealmName = function() return "" end
    w:start({row(100, 2, 1000)}); w:drain()
    equal(w.requests, 1); equal(A.Scanner.requestCount, 1)
    equal(A.DB.Snapshot().marketKey, "1|TestRealmName"); equal(A.DB.Price(100).low, 500)
    local info = A.Util.MarketInfo()
    equal(info.realmSource, "GetRealmName"); equal(info.regionSource, "C_CVar.GetCVar(portal)")
end)
test("missing or failing normalized realm API falls back without an error", function()
    for _, fn in ipairs({false, function() error("lookup failed") end}) do
        local w, A = fresh(); GetNormalizedRealmName = fn or nil
        equal(A.Util.MarketKey(), "1|FixtureRealm")
    end
end)
test("named regions and modern or legacy portal values identify the same market", function()
    local mappings = {us=1, kr=2, eu=3, tw=4, cn=5}
    for portal, region in pairs(mappings) do
        local w, A = fresh(); w.region = 0; w.portal = string.upper(portal)
        equal(A.Util.MarketKey(), tostring(region) .. "|FixtureRealm")
        w.region = nil; w.portal = nil; w.legacyPortal = " " .. portal .. " "
        equal(A.Util.MarketKey(), tostring(region) .. "|FixtureRealm")
        w.region = string.upper(portal); w.legacyPortal = nil
        equal(A.Util.MarketKey(), tostring(region) .. "|FixtureRealm")
    end
end)
test("native numeric region and existing normalized realm keys take precedence", function()
    local w, A, old = initial(); w.portal = "eu"
    equal(A.DB.Snapshot(), old)
    w.realm = "Normalized-Realm"
    equal(A.Util.MarketKey(), "1|Normalized-Realm")
end)
test("falling back to a matching portal retains build001 snapshots and reload persistence", function()
    local w, A, old = initial(); w.region = 0
    equal(A.DB.Snapshot(), old); equal(A.DB.Price(100).low, 900)
    local w2, A2 = fresh(A.DB.data); w2.region = nil; w2:load()
    equal(A2.DB.Price(100).low, 900); equal(A2.Scanner.RemainingCooldown(), 900)
end)
test("named test portals do not share region or other portal prices", function()
    local w, A = fresh(); w.region = 0; w.portal = "beta"
    w:start({row(100, 1, 500)}); w:drain()
    equal(A.DB.Snapshot().marketKey, "portal:beta|FixtureRealm")
    w.portal = "public-test"; equal(A.DB.Snapshot(), nil)
    w.portal = "us"; equal(A.DB.Snapshot(), nil)
    w.portal = "beta"; equal(A.DB.Price(100).low, 500)
end)
test("unavailable market identity consumes no request or cooldown and explains the source", function()
    local w, A = fresh(); w:load(); w.region = 0; w.portal = nil
    local ok, reason = A.Scanner.Start()
    equal(ok, false); truth(string.find(reason, "Region and login portal"))
    equal(w.requests, 0); equal(A.Scanner.requestCount, 0); equal(A.Scanner.RemainingCooldown(), 0)
    for _, portal in ipairs({"0", " ", "us/invalid"}) do
        w.portal = portal; equal(A.Scanner.Start(), false); equal(w.requests, 0)
    end
    w.region = 1; w.realm = ""
    ok, reason = A.Scanner.Start(); equal(ok, false); truth(string.find(reason, "Realm name"))
end)
test("restricted and throwing market APIs are reported without exposing values", function()
    local w, A = fresh(); w.region = secret; w.portal = secret
    GetNormalizedRealmName = function() return secret end
    GetRealmName = function() error("not ready") end
    local info = A.Util.MarketInfo(); equal(info.key, nil)
    equal(info.normalizedRealm, "restricted"); equal(info.realmName, "error"); equal(info.nativeRegion, "restricted")
    w:load(); truth(string.find(A.UI.DiagnosticsText(), "Native region: restricted"))
end)
test("a portal change during a fallback scan preserves the original snapshot", function()
    local w, A, old = initial(); w.region = 0
    newScan(w, {row(200, 1, 100)}); w.portal = "eu"; w:drain()
    equal(A.Scanner.state, "FAILED"); w.portal = "us"; equal(A.DB.Snapshot(), old)
end)
test("opening the AH adds one tab and keeps the native Buy pane selected", function()
    local w, A = fresh(); w:load(); local ah = w:openAH()
    truth(A.UI.tabInstalled); truth(A.UI.tabButton)
    equal(ah.numTabs, 3); equal(#ah.Tabs, 3)
    equal(A.UI.panel:IsShown(), false); equal(A.UI.frame:IsShown(), false)
    truth(ah.BuyContent:IsShown()); equal(A.UI.content:GetParent(), A.UI.panel)
    equal(A.UI.content:GetFrameStrata(), ah:GetFrameStrata())
    truth(string.find(A.UI.DiagnosticsText(), "Auction House tab: installed"))
end)
test("AH tab opens working scan controls and native tabs restore the original pane", function()
    local w, A = fresh(); w:load(); local ah = w:openAH()
    A.UI.tabButton.scripts.OnClick(); truth(A.UI.panel:IsShown()); equal(ah.BuyContent:IsShown(), false)
    w.rows = {row(100, 1, 123)}; A.UI.scanButton.scripts.OnClick()
    equal(w.requests, 1); w:event("REPLICATE_ITEM_LIST_UPDATE"); w:drain()
    equal(A.DB.Price(100).low, 123)
    ah:SetDisplayMode(AuctionHouseFrameDisplayMode.Buy)
    equal(A.UI.panel:IsShown(), false); truth(ah.BuyContent:IsShown()); equal(A.UI.tabButton.selected, false)
end)
test("shared tab library coordinates another addon without changing Blizzard tab indices", function()
    local w, A = fresh(); w:load(); local ah = w:makeAH(); ah:Show()
    local lib, other = LibStub("LibAHTab-1-0"), widget()
    lib:CreateTab("OtherAddonFixture", other, "Other addon")
    w:event("AUCTION_HOUSE_SHOW"); A.UI.tabButton.scripts.OnClick()
    truth(A.UI.panel:IsShown()); equal(other:IsShown(), false)
    lib:SetSelected("OtherAddonFixture"); truth(other:IsShown()); equal(A.UI.panel:IsShown(), false)
    A.UI.tabButton.scripts.OnClick(); truth(A.UI.panel:IsShown()); equal(other:IsShown(), false)
    equal(ah.numTabs, 3); equal(#ah.Tabs, 3); equal(#lib.internalState.Tabs, 2)
end)
test("delayed AH frame loading installs the tab after the SHOW event", function()
    local w, A = fresh(); w:load(); w:event("AUCTION_HOUSE_SHOW")
    equal(A.UI.tabInstalled, nil); equal(A.UI.frame, nil)
    local ah = w:makeAH(); ah:Show(); w:event("ADDON_LOADED", "Blizzard_AuctionHouseUI")
    truth(A.UI.tabInstalled); equal(A.UI.frame:IsShown(), false)
end)
test("AH installation retries on a later tick when the native frame becomes visible", function()
    local w, A = fresh(); w:load(); w:makeAH(); w:event("AUCTION_HOUSE_SHOW")
    equal(A.UI.tabInstalled, nil)
    AuctionHouseFrame:Show(); A.eventFrame.scripts.OnUpdate(A.eventFrame, 0.25)
    truth(A.UI.tabInstalled)
end)
test("legacy automatic-popup setting is retained but does not open or select settings", function()
    local w, A = fresh({schema=1, markets={}, settings={openAtAH=true}}); w:load()
    A.UI.Toggle(); truth(A.UI.frame:IsShown())
    w:openAH(); equal(A.UI.frame:IsShown(), false); equal(A.UI.panel:IsShown(), false)
    equal(A.DB.data.settings.openAtAH, true)
end)
test("reopening the auction house reuses the same tab and defaults to Buy", function()
    local w, A = fresh(); w:load(); local ah = w:openAH()
    A.UI.tabButton.scripts.OnClick(); local button = A.UI.tabButton
    ah:Hide(); w:event("AUCTION_HOUSE_CLOSED"); equal(A.UI.panel:IsShown(), false)
    w:openAH(); equal(A.UI.tabButton, button); equal(A.UI.panel:IsShown(), false)
    equal(#LibStub("LibAHTab-1-0").internalState.Tabs, 1)
end)
test("slash menu moves controls between the AH tab and manual window", function()
    local w, A = fresh(); w:load(); local ah = w:openAH()
    SlashCmdList.MSMARKETVALUE(""); truth(A.UI.panel:IsShown()); equal(A.UI.frame:IsShown(), false)
    SlashCmdList.MSMARKETVALUE(""); equal(A.UI.panel:IsShown(), false); truth(ah.BuyContent:IsShown())
    ah:Hide(); w:event("AUCTION_HOUSE_CLOSED")
    SlashCmdList.MSMARKETVALUE(""); truth(A.UI.frame:IsShown()); equal(A.UI.content:GetParent(), A.UI.frame)
    equal(A.UI.content:GetFrameStrata(), "DIALOG")
    w:openAH(); equal(A.UI.frame:IsShown(), false); equal(A.UI.content:GetParent(), A.UI.panel)
end)
test("combat defers tab creation and hides addon controls until out of combat", function()
    local w, A = fresh(); w:load(); w.combat = true; w:openAH()
    equal(A.UI.tabInstalled, nil); equal(A.UI.frame, nil)
    w.combat = false; w:event("PLAYER_REGEN_ENABLED"); truth(A.UI.tabInstalled)
    A.UI.tabButton.scripts.OnClick(); truth(A.UI.panel:IsShown())
    w.combat = true; w:event("PLAYER_REGEN_DISABLED")
    equal(A.UI.panel:IsShown(), false); equal(A.UI.tabButton.enabled, false)
    A.UI.tabButton.scripts.OnClick(); equal(A.UI.panel:IsShown(), false)
    w.combat = false; w:event("PLAYER_REGEN_ENABLED"); equal(A.UI.tabButton.enabled, true)
end)


test("first-hover item-cache refresh never rebuilds comparison or custom tooltips", function()
    local w, A = fresh(); w:load()
    local comparisons = {ShoppingTooltip1, ShoppingTooltip2, widget("ItemRefShoppingTooltip1"), widget("ItemRefShoppingTooltip2"), widget("OtherAllowedTooltip")}
    local attempted = 0
    for _, tooltip in ipairs(comparisons) do
        A.Tooltips.Allow(tooltip)
        tooltip.info = {append = true, getterName = "GetItemByID"}
        tooltip.data = {id = 270018, type = 0}; tooltip.link = link(270018)
        tooltip.RebuildFromTooltipInfo = function()
            attempted = attempted + 1
            error("insert: table expected, got nil")
        end
        tooltip:Show(); A.Tooltips.Handle(tooltip, tooltip.data)
        truth(tooltip:NumLines() > 0)
    end
    w:event("GET_ITEM_INFO_RECEIVED", 270018, true)
    A.eventFrame.scripts.OnUpdate(A.eventFrame, 0.25)
    equal(attempted, 0); equal(A.Tooltips.refreshing, false)
end)
test("getter-backed primary item refresh updates loaded values without duplicate sections", function()
    local w, A = initial()
    for _, tooltip in ipairs({GameTooltip, ItemRefTooltip}) do
        tooltip.info = {getterName = "GetItemByID"}
        tooltip.data = {id = 100, type = 0}; tooltip.link = link(100)
        tooltip:Show(); A.Tooltips.Handle(tooltip, tooltip.data)
    end
    w.items[100] = {level = 17, vendor = 4321}
    w:event("GET_ITEM_INFO_RECEIVED", 100, true)
    A.eventFrame.scripts.OnUpdate(A.eventFrame, 0.25)
    for _, tooltip in ipairs({GameTooltip, ItemRefTooltip}) do
        equal(tooltip.rebuilds, 1)
        local headers, vendor = 0
        for _, line in ipairs(tooltip.lines) do
            if line.left == A.TITLE then headers = headers + 1 end
            if line.left == "Vendor sell" then vendor = line.right end
        end
        equal(headers, 1); equal(vendor, "43s 21c")
    end
end)
test("primary refresh requires readable getter-backed non-append item information", function()
    local w, A = fresh(); w:load(); GameTooltip:Show()
    GameTooltip.data = {id = 100, type = 0}
    for _, info in ipairs({false, secret, {}, {getterName=secret}, {getterName="GetItemByID", append=true}, {getterName="GetItemByID", append=1}, {getterName="GetItemByID", append=secret}}) do
        GameTooltip.info = info or nil; A.Tooltips.RefreshVisible()
        equal(GameTooltip.rebuilds, nil)
    end
    GameTooltip.info = {getterFunction=function() end}
    for _, data in ipairs({secret, {id=100, type=secret}, {id=100, type=1}, {id=secret, type=0}}) do
        GameTooltip.data = data; A.Tooltips.RefreshVisible(); equal(GameTooltip.rebuilds, nil)
    end
    GameTooltip.data = {id=100, type=0}; A.Tooltips.RefreshVisible()
    equal(GameTooltip.rebuilds, 1)
end)
test("primary refresh skips combat and forbidden frames and resists recursive refresh", function()
    local w, A = fresh(); w:load(); GameTooltip:Show()
    GameTooltip.info = {getterName="GetItemByID"}; GameTooltip.data = {id=100, type=0}
    w.combat = true; A.Tooltips.RefreshVisible(); equal(GameTooltip.rebuilds, nil)
    w.combat = false; GameTooltip.forbidden = true
    local shown = GameTooltip.IsShown
    GameTooltip.IsShown = function(self)
        if self.forbidden then error("forbidden frame inspected") end
        return shown(self)
    end
    A.Tooltips.RefreshVisible(); equal(GameTooltip.rebuilds, nil)
    GameTooltip.forbidden = false
    local original = GameTooltip.RebuildFromTooltipInfo
    GameTooltip.RebuildFromTooltipInfo = function(self)
        A.Tooltips.RefreshVisible(); original(self)
    end
    A.Tooltips.RefreshVisible(); equal(GameTooltip.rebuilds, 1); equal(A.Tooltips.refreshing, false)
end)
test("primary refresh recovers after failing native getters or rebuilds", function()
    local w, A = fresh(); w:load(); GameTooltip:Show()
    GameTooltip.data = {id=100, type=0}
    local getter = GameTooltip.GetPrimaryTooltipInfo
    GameTooltip.GetPrimaryTooltipInfo = function() error("not ready") end
    A.Tooltips.RefreshVisible(); equal(GameTooltip.rebuilds, nil); equal(A.Tooltips.refreshing, false)
    GameTooltip.GetPrimaryTooltipInfo = getter; GameTooltip.info = {getterName="GetItemByID"}
    local rebuild = GameTooltip.RebuildFromTooltipInfo
    GameTooltip.RebuildFromTooltipInfo = function() error("not ready") end
    A.Tooltips.RefreshVisible(); equal(A.Tooltips.refreshing, false)
    GameTooltip.RebuildFromTooltipInfo = rebuild
    A.Tooltips.RefreshVisible(); equal(GameTooltip.rebuilds, 1)
end)

test("Forever beta region 90 and PvP reporting hosts share one ruleset cache", function()
    local w, A = fresh(); w.realm = "ClassicBetaPvP2"; w.region = 90; w.portal = "test"
    w:start({row(100, 2, 1000)}); w:drain()
    equal(A.Util.MarketKey(), "forever|90|pvp|Horde")
    local snapshot = A.DB.Snapshot()
    equal(snapshot.ruleset, "pvp"); equal(snapshot.region, "90"); equal(snapshot.faction, "Horde")
    local info = A.Util.MarketInfo()
    equal(info.regionSource, "GetCurrentRegion"); equal(info.kind, "realmless-ruleset")
    truth(string.find(info.rulesetSource, "Forever reporting alias", 1, true))
    w.realm = "ClassicBetaPvP1"; equal(A.DB.Snapshot(), snapshot); equal(A.DB.Price(100).low, 500)
    w.realm = "ForeverPvP3"; equal(A.DB.Snapshot(), snapshot)
end)
test("Normal and PvP rulesets and unqualified faction markets remain isolated", function()
    local w, A = fresh(); w.realm = "ClassicBetaPvP2"; w.region = 90
    w:start({row(100, 1, 500)}); w:drain()
    w.realm = "ClassicBetaNormal1"; equal(A.DB.Price(100), nil)
    equal(A.Util.MarketKey(), "forever|90|normal|Horde")
    w:advance(901); w.rows = {row(200, 1, 600)}
    truth(A.Scanner.Start()); A.Scanner.OnResponse(); w:drain()
    w.realm = "ClassicBetaPvE2"; equal(A.DB.Price(200).low, 600)
    w.realm = "ClassicBetaPvP2"; equal(A.DB.Price(100).low, 500); equal(A.DB.Price(200), nil)
    w.faction = "Alliance"; equal(A.DB.Price(100), nil)
    w.faction = "Horde"; equal(A.DB.Price(100).low, 500)
    w.region = 1; equal(A.DB.Price(100), nil)
end)
test("reporting-host changes during a scan remain valid and ruleset changes preserve previous prices", function()
    local w, A = fresh(); w.realm = "ClassicBetaPvP2"; w.region = 90
    w:start({row(100, 1, 500)}); w.realm = "ClassicBetaPvP1"; w:drain()
    equal(A.Scanner.state, "COMPLETE"); local old = A.DB.Snapshot()
    newScan(w, {row(200, 1, 600)}); w.realm = "ClassicBetaNormal1"; w:drain()
    equal(A.Scanner.state, "FAILED"); w.realm = "ClassicBetaPvP2"; equal(A.DB.Snapshot(), old)
end)
test("ruleset snapshots persist across an independent session and a different reporting host", function()
    local w, A = fresh(); w.realm = "ClassicBetaPvP2"; w.region = 90
    w:start({row(100, 1, 500)}); w:drain()
    local w2, A2 = fresh(A.DB.data); w2.realm = "ClassicBetaPvP1"; w2.region = 90; w2:load()
    equal(A2.DB.Price(100).low, 500); equal(A2.Scanner.RemainingCooldown(), 900)
end)
test("legacy realm snapshots are kept but never promoted into detected ruleset caches", function()
    local w, A, old = initial(); local key = old.marketKey
    w.realm = "ClassicBetaPvP2"; w.region = 90
    equal(A.DB.Snapshot(), nil); equal(A.DB.data.markets[key], old)
    w:advance(901); w.rows = {row(200, 1, 600)}
    truth(A.Scanner.Start()); A.Scanner.OnResponse(); w:drain()
    equal(A.DB.Price(100), nil); equal(A.DB.Price(200).low, 600); equal(A.DB.data.markets[key], old)
end)
test("ruleset detection uses the native hardcore API and bounded reporting aliases", function()
    local w, A = fresh(); w.hardcore = true; w.realm = ""; w.region = 90
    equal(A.Util.MarketKey(), "forever|90|hardcore|Horde")
    equal(A.Util.MarketInfo().rulesetSource, "C_GameRules.IsHardcoreActive")
    w.hardcore = false
    for alias, ruleset in pairs({["Classic Beta Normal 1"]="normal", ["Forever-RP2"]="roleplaying", ["WoWForeverHardcore1"]="hardcore"}) do
        w.realm = alias; equal(A.Util.MarketInfo().ruleset, ruleset)
    end
    for _, alias in ipairs({"PvPRealm", "ClassicBetaPvP2Unexpected", "UnknownForeverRealm"}) do
        w.realm = alias; local info = A.Util.MarketInfo()
        equal(info.ruleset, nil); equal(info.kind, "isolated-alias"); equal(info.key, "90|" .. alias)
    end
    w.realm = "UnknownForeverRealm"; C_GameRules.GetForeverExperiencePreset = function() return 1 end
    equal(A.Util.MarketInfo().ruleset, nil)
end)
test("restricted faction blocks a ruleset request and restricted hardcore values are not inspected", function()
    local w, A = fresh(); w.realm = "ClassicBetaPvP2"; w.region = 90; w.faction = secret; w.hardcore = secret
    w:load(); local ok, reason = A.Scanner.Start()
    equal(ok, false); truth(string.find(reason, "Player faction")); equal(w.requests, 0)
    equal(A.Scanner.RemainingCooldown(), 0)
    local info = A.Util.MarketInfo(); equal(info.nativeFaction, "restricted"); equal(info.ruleset, "pvp")
    C_GameRules.IsHardcoreActive = function() error("not ready") end; w.faction = "Horde"
    equal(A.Util.MarketKey(), "forever|90|pvp|Horde")
end)


local function findLine(lines, left)
    for index, line in ipairs(lines) do
        if line.left == left then return line, index end
    end
end

local function bagTooltip(w, itemID, count, bag, slot)
    bag, slot = bag or 0, slot or 1
    GameTooltip.info = {getterName="GetBagItem", getterArgs={bag, slot}}
    GameTooltip.data = {id=itemID, type=0}
    GameTooltip.link = link(itemID)
    w.containers[tostring(bag) .. ":" .. tostring(slot)] = {itemID=itemID, stackCount=count}
    return GameTooltip
end

test("bag totals use the hovered slot count and never total ownership or maximum capacity", function()
    local w, A = initial(); w.items[100] = {vendor=1234, quality=1}
    local tooltip = bagTooltip(w, 100, 3)
    A.Tooltips.Handle(tooltip, tooltip.data)
    equal(findLine(tooltip.lines, A.TITLE).right, "Each / Stack (3)")
    equal(findLine(tooltip.lines, "Vendor sell").right, "12s 34c / 37s 02c")
    equal(findLine(tooltip.lines, "AH low").right, "9s 00c / 27s 00c")
    equal(findLine(tooltip.lines, "DE expected"), nil)
end)
test("matched item GUIDs identify one actual stack and mismatched GUIDs use a verified bag slot", function()
    local w, A = initial(); local tooltip = bagTooltip(w, 100, 3)
    tooltip.data.guid = "Fixture-Stack"
    w.locations["Fixture-Stack"] = {itemID=100, stackCount=20}
    equal(A.Tooltips.StackCount(tooltip, tooltip.data, 100), 20)
    w.locations["Fixture-Stack"].itemID = 101
    equal(A.Tooltips.StackCount(tooltip, tooltip.data, 100), 3)
    w.containers["0:1"].itemID = 101
    equal(A.Tooltips.StackCount(tooltip, tooltip.data, 100), 1)
end)
test("owned equipment contexts provide quantities while target and child contexts stay each-only", function()
    local w, A = fresh(); w:load()
    GameTooltip.data = {id=100, type=0}
    GameTooltip.info = {getterName="GetInventoryItem", getterArgs={"player", 18}}
    w.equipment[18] = {itemID=100, stackCount=12}
    equal(A.Tooltips.StackCount(GameTooltip, GameTooltip.data, 100), 12)
    GameTooltip.info.getterArgs[1] = "target"
    equal(A.Tooltips.StackCount(GameTooltip, GameTooltip.data, 100), 1)
    GameTooltip.info = {getterName="GetBagItemChild", getterArgs={0,1}}
    w.containers["0:1"] = {itemID=100, stackCount=20}
    equal(A.Tooltips.StackCount(GameTooltip, GameTooltip.data, 100), 1)
end)
test("generic item links do not acquire an arbitrary owned quantity", function()
    local w, A = initial(); w.items[100] = {quality=1}
    ItemRefTooltip.info = {getterName="GetHyperlink", getterArgs={link(100)}}
    ItemRefTooltip.data = {id=100, type=0, quantity=secret, stackCount=secret}
    ItemRefTooltip.link = link(100)
    w.locations["Unrelated-Stack"] = {itemID=100, stackCount=20}
    A.Tooltips.Handle(ItemRefTooltip, ItemRefTooltip.data)
    equal(findLine(ItemRefTooltip.lines, A.TITLE).right, "Each")
    equal(findLine(ItemRefTooltip.lines, "AH low").right, "9s 00c")
end)
test("restricted or malformed quantity contexts keep usable each-only prices", function()
    local w, A = initial(); local tooltip = bagTooltip(w, 100, 20)
    for _, args in ipairs({secret, {secret,1}, {0,secret}, {0,0}, {0,1.5}}) do
        tooltip.info.getterArgs = args
        equal(A.Tooltips.StackCount(tooltip, tooltip.data, 100), 1)
    end
    equal(w.containerReads, nil)
    tooltip.info.getterArgs = {0,1}
    for _, count in ipairs({secret, 0, -1, 1.5, 1000001, math.huge, "20"}) do
        w.containers["0:1"].stackCount = count
        equal(A.Tooltips.StackCount(tooltip, tooltip.data, 100), 1)
        equal(A.Tooltips.Lines(100, link(100), count)[1].right, "Each")
    end
    w.containers["0:1"] = secret
    equal(A.Tooltips.StackCount(tooltip, tooltip.data, 100), 1)
    w.containers["0:1"] = {itemID=secret, stackCount=20}
    equal(A.Tooltips.StackCount(tooltip, tooltip.data, 100), 1)
    tooltip.info = nil; tooltip.data.guid = secret
    equal(A.Tooltips.StackCount(tooltip, tooltip.data, 100), 1)
    tooltip.data.guid = "Fixture-Stack"
    w.locations["Fixture-Stack"] = secret
    equal(A.Tooltips.StackCount(tooltip, tooltip.data, 100), 1)
    w.locations["Fixture-Stack"] = {itemID=secret, stackCount=secret}
    equal(A.Tooltips.StackCount(tooltip, tooltip.data, 100), 1)
end)
test("combat permits public quantity reads while forbidden frames stay protected", function()
    local w, A = initial(); local tooltip = bagTooltip(w, 100, 20)
    w.combat = true; equal(A.Tooltips.StackCount(tooltip, tooltip.data, 100), 20)
    w.combat = false; tooltip.forbidden = true
    equal(A.Tooltips.StackCount(tooltip, tooltip.data, 100), 1); equal(w.containerReads, 1)
    tooltip.forbidden = false
    C_Container.GetContainerItemInfo = function() error("not ready") end
    equal(A.Tooltips.StackCount(tooltip, tooltip.data, 100), 1)
    tooltip.GetPrimaryTooltipInfo = function() error("not ready") end
    equal(A.Tooltips.StackCount(tooltip, tooltip.data, 100), 1)
end)
test("same-item stack changes refresh totals after native clear without duplicate addon sections", function()
    local w, A = initial(); local tooltip = bagTooltip(w, 100, 3)
    A.Tooltips.Handle(tooltip, tooltip.data); local lineCount = tooltip:NumLines()
    A.Tooltips.Handle(tooltip, tooltip.data); equal(tooltip:NumLines(), lineCount)
    w.containers["0:1"].stackCount = 7
    tooltip.lines = {{left="Native item"}}
    A.Tooltips.Handle(tooltip, tooltip.data)
    equal(findLine(tooltip.lines, A.TITLE).right, "Each / Stack (7)")
    equal(findLine(tooltip.lines, "AH low").right, "9s 00c / 63s 00c")
    local sections = 0
    for _, line in ipairs(tooltip.lines) do if line.left == A.TITLE then sections = sections + 1 end end
    equal(sections, 1)
end)
test("stack totals multiply unrounded unit prices and preserve exact suffix selection", function()
    local w, A = fresh(); w:start({row(100,5,111,0),row(100,5,555,-5)}); w:drain()
    local each = A.Tooltips.Lines(100, link(100,0), 3)
    equal(findLine(each,"AH low").right, "22c / 67c")
    local suffix = A.Tooltips.Lines(100, link(100,-5), 3)
    equal(findLine(suffix,"AH low").right, "1s 11c / 3s 33c")
    local fallback = A.Tooltips.Lines(100, link(100,9), 3)
    equal(findLine(fallback,"AH low (item-wide)").right, "22c / 67c")
end)
test("DE expected each and stack values share the price block before spaced per-item materials", function()
    local w, A = fresh(); w:start({row(300,1,1000),row(10940,1,100),row(10939,1,200),row(10978,1,1000)}); w:drain()
    w.items[300] = {level=17, vendor=100}
    local lines = A.Tooltips.Lines(300, link(300), 3)
    local value, valueIndex = findLine(lines,"DE expected")
    equal(value.right, "2s 98c / 8s 93c")
    local _, headerIndex = findLine(lines,"Disenchant estimate")
    truth(valueIndex < headerIndex); equal(lines[headerIndex-1].left, " ")
    truth(findLine(lines,"Auction snapshot") ~= nil)
    local _, ageIndex = findLine(lines,"Auction snapshot"); truth(ageIndex < headerIndex)
    local copies = 0
    for _, line in ipairs(lines) do if line.left == "DE expected" then copies = copies + 1 end end
    equal(copies,1); truth(findLine(lines,"One possible outcome per item.") ~= nil)
    equal(findLine(lines,"DE value (expected, each)"),nil)
end)
test("unpriced DE materials keep the full total unavailable and stack-scale only the labeled subtotal", function()
    local w, A = fresh(); w:start({row(10940,1,100),row(10939,1,200)}); w:drain()
    w.items[300] = {level=17}
    local lines = A.Tooltips.Lines(300, link(300), 2)
    equal(findLine(lines,"DE expected").right,"Unavailable")
    equal(findLine(lines,"DE priced portion only").right,"2s 48c / 4s 95c")
    equal(findLine(lines,"Unpriced materials").right,"1")
    local _, partialIndex = findLine(lines,"DE priced portion only")
    local _, headerIndex = findLine(lines,"Disenchant estimate")
    truth(partialIndex < headerIndex)
end)
test("display options and zero vendor values retain their meaning in a stack price block", function()
    local w, A = fresh(); w:load(); w.items[300] = {level=17,vendor=0}
    local lines = A.Tooltips.Lines(300, link(300), 20)
    equal(findLine(lines,"Vendor sell").right,"No vendor sale")
    equal(findLine(lines,"AH low").right,"Scan required")
    A.DB.data.settings.showMaterials = false
    lines = A.Tooltips.Lines(300, link(300), 20)
    truth(findLine(lines,"DE expected") ~= nil); truth(findLine(lines,"Disenchant estimate") ~= nil)
    equal(findLine(lines,"One possible outcome per item."),nil)
    A.DB.data.settings.showDisenchant = false
    lines = A.Tooltips.Lines(300, link(300), 20)
    equal(findLine(lines,"DE expected"),nil); equal(findLine(lines,"Disenchant estimate"),nil)
    A.DB.data.settings.showVendor, A.DB.data.settings.showAuction = false, false
    equal(#A.Tooltips.Lines(300, link(300),20),0)
end)
test("beta upgrade retains the completed beta003 market, settings, exclusions and cooldown without rescanning", function()
    local w, A = fresh(); w.realm="ClassicBetaPvP2"; w.region=90
    w:start({row(100,1,500)}); w:drain()
    local saved, snapshot = A.DB.data, A.DB.Snapshot()
    saved.version, saved.build = "0.1.0-beta", "2026-10-04-beta003"
    snapshot.version, snapshot.build = saved.version, saved.build
    saved.settings.staleHours=72; saved.excludedItems[300]=true
    local w2,A2 = fresh(saved); w2.realm="ClassicBetaPvP2"; w2.region=90; w2:load()
    equal(A2.VERSION,"1.1.0-beta"); equal(A2.DB.Price(100).low,500); equal(A2.DB.Snapshot(),snapshot)
    equal(A2.DB.data.settings.staleHours,72); equal(A2.DB.data.excludedItems[300],true)
    equal(A2.Scanner.RemainingCooldown(),900); equal(w2.requests,0)
end)

local function craftRecipe(id, outputID, minimum, maximum, slots)
    return {
        info = { recipeID = id, name = "Recipe " .. id, learned = true, supportsQualities = false },
        schematic = { recipeID = id, quantityMin = minimum or 1, quantityMax = maximum or minimum or 1,
            outputItemID = outputID, isRecraft = false, reagentSlotSchematics = slots or {
                { reagents = {{itemID = 100}}, quantityRequired = 2, required = true, dataSlotIndex = 1, variableQuantities = {} },
                { reagents = {{itemID = 101}}, quantityRequired = 1, required = true, dataSlotIndex = 2, variableQuantities = {} },
            } },
        output = { itemID = outputID, hyperlink = outputID and link(outputID) or nil },
    }
end

local function craftingWorld()
    local w, A = fresh()
    w:start({row(100,1,100),row(101,1,200),row(102,1,50),row(200,1,900),row(201,1,300),row(202,1,500)})
    w:drain()
    w.recipes = { [1] = craftRecipe(1,200), [2] = craftRecipe(2,201), [3] = craftRecipe(3,202,2,4) }
    w.recipeIDs, w.selectedID = {1,2,3}, 1
    w:openProfession()
    -- Existing crafting UI fixtures exercise explicitly enabled auto-open.
    -- Revision 3 checks the new manual default separately below.
    A.DB.data.settings.craftAutoOpen = true
    return w, A
end

test("paused processing resumes during cooldown with one request and no duplicate rows", function()
    local w, A = fresh(); local rows = {}
    for index=1,251 do rows[index]=row(100,1,100+index) end
    w:start(rows); A.Scanner.Tick(); equal(A.Scanner.work.processedRows,100)
    local cooldown=A.DB.data.cooldownUntil
    truth(A.Scanner.Pause()); w:advance(100); equal(A.Scanner.state,"PAUSED")
    truth(A.Scanner.Start()); w:drain()
    equal(w.requests,1); equal(A.DB.data.cooldownUntil,cooldown)
    equal(A.DB.Snapshot().processedRows,251); equal(A.DB.Price(100).auctions,251); equal(A.DB.Price(100).units,251)
end)
test("a response arriving while paused is staged and committed only after resume", function()
    local w,A=fresh(); w:load(); w.rows={row(100,1,100)}
    truth(A.Scanner.Start()); truth(A.Scanner.Pause()); A.Scanner.OnResponse()
    equal(A.Scanner.resumeState,"PROCESSING"); equal(A.DB.Snapshot(),nil)
    truth(A.Scanner.Resume()); w:drain(); equal(A.DB.Price(100).low,100); equal(w.requests,1)
end)
test("an empty response while paused replaces prices only on resume", function()
    local w,A,old=initial(); w:advance(901); w.rows={}
    truth(A.Scanner.Start()); truth(A.Scanner.Pause()); A.Scanner.OnResponse()
    equal(A.DB.Snapshot(),old); truth(A.Scanner.Resume()); w:drain()
    equal(A.DB.Snapshot().totalRows,0); equal(w.requests,2)
end)
test("waiting resume makes no duplicate request and later server data completes", function()
    local w,A=fresh(); w:load(); w.rows={row(100,1,100)}
    truth(A.Scanner.Start()); truth(A.Scanner.Pause()); w:advance(500)
    truth(A.Scanner.Resume()); equal(A.Scanner.state,"WAITING"); equal(w.requests,1)
    A.Scanner.OnResponse(); w:drain(); equal(A.DB.Price(100).low,100)
end)
test("resuming midway through a pending retry preserves its accepted rows", function()
    local w,A=fresh(); local rows={}
    for index=1,205 do rows[index]=row(100,1,100,0,false) end
    w:start(rows); while A.Scanner.state=="PROCESSING" do A.Scanner.Tick() end
    for _,entry in ipairs(rows) do entry.allInfo=true end
    w:advance(0.6); equal(A.Scanner.work.processedRows,100)
    truth(A.Scanner.Pause()); truth(A.Scanner.Resume()); w:drain()
    equal(A.DB.Price(100).units,205); equal(A.DB.Price(100).auctions,205); equal(w.loadRequests,1)
end)
test("missing item data can be picked up after the resolution timeout", function()
    local w,A=fresh(); w:start({row(100,1,100,0,false)})
    A.Scanner.Tick(); w:advance(46); equal(A.Scanner.state,"PAUSED")
    w.rows[1].allInfo=true; truth(A.Scanner.Resume()); w:drain()
    equal(A.DB.Price(100).low,100); equal(w.requests,1)
end)
test("combat and AH close require safe reopen before resuming the same buffer", function()
    local w,A=fresh(); w:start({row(100,1,100)})
    w.combat=true; w:event("PLAYER_REGEN_DISABLED"); equal(A.Scanner.state,"PAUSED")
    equal(A.Scanner.Resume(),false); w.combat=false; w:event("AUCTION_HOUSE_CLOSED")
    equal(A.Scanner.Resume(),false); w:event("AUCTION_HOUSE_SHOW")
    truth(A.Scanner.Resume()); w:drain(); equal(w.requests,1); equal(A.DB.Price(100).low,100)
end)
test("a paused scan rejects a replaced buffer and retains the full-scan cooldown", function()
    local w,A,old=initial(); newScan(w,{row(200,1,100)})
    truth(A.Scanner.Pause()); w.overrideCount=2
    equal(A.Scanner.Resume(),false); equal(A.Scanner.state,"FAILED")
    equal(A.DB.Snapshot(),old); truth(A.Scanner.RemainingCooldown()>0); equal(w.requests,2)
end)
test("another addon invalidates a paused same-count buffer", function()
    local w,A,old=initial(); newScan(w,{row(200,1,100)})
    truth(A.Scanner.Pause()); C_AuctionHouse.ReplicateItems()
    equal(A.Scanner.state,"FAILED"); equal(A.Scanner.Resume(),false); equal(A.DB.Snapshot(),old)
end)
test("paused same-count readiness events retain cursor and market changes prevent resume", function()
    local w,A=fresh(); local rows={}
    for index=1,151 do rows[index]=row(100,1,100) end
    w:start(rows); A.Scanner.Tick(); truth(A.Scanner.Pause()); A.Scanner.OnResponse()
    equal(A.Scanner.cursor,100); equal(A.Scanner.dataUpdateCount,1)
    w.region=2; equal(A.Scanner.Resume(),false); equal(A.Scanner.state,"FAILED")
end)
test("pause resume and discard commands expose the intended lifecycle", function()
    local w,A=fresh(); w:start({row(100,1,100)})
    SlashCmdList.MSMARKETVALUE("pause"); equal(A.Scanner.state,"PAUSED")
    SlashCmdList.MSMARKETVALUE("resume"); truth(A.Scanner.active)
    SlashCmdList.MSMARKETVALUE("stop"); truth(A.Scanner.paused)
    SlashCmdList.MSMARKETVALUE("discard"); equal(A.Scanner.work,nil); equal(A.Scanner.state,"CANCELLED")
    equal(w.requests,1); truth(A.Scanner.RemainingCooldown()>0)
end)
test("scan controls enable resume while cooldown is active", function()
    local w,A=fresh(); w:openAH(); w:start({row(100,1,100)})
    A.Scanner.Pause(); A.UI.Refresh()
    equal(A.UI.scanButton.text,"Resume scan"); equal(A.UI.scanButton.enabled,true); equal(A.UI.stopButton.enabled,false)
    A.UI.scanButton.scripts.OnClick(); truth(A.Scanner.active); equal(w.requests,1)
end)
test("combat item tooltips retain vendor AH and DE values without duplicates", function()
    local w,A=initial(); w.items[100]={quality=2,level=17,vendor=100}
    w.combat=true; local tooltip=bagTooltip(w,100,20)
    A.Tooltips.Handle(tooltip,tooltip.data); local count=tooltip:NumLines()
    equal(findLine(tooltip.lines,A.TITLE).right,"Each / Stack (20)")
    truth(findLine(tooltip.lines,"Vendor sell")); truth(findLine(tooltip.lines,"AH low")); truth(findLine(tooltip.lines,"DE expected"))
    A.Tooltips.Handle(tooltip,tooltip.data); equal(tooltip:NumLines(),count)
    tooltip.lines={}; tooltip.data={id=secret}; A.Tooltips.Handle(tooltip,tooltip.data); equal(tooltip:NumLines(),0)
end)
test("crafting shows total raw cost profit and return on cost", function()
    local w,A=craftingWorld(); local value=A.Crafting.Analyze(1,w.form)
    equal(value.cost,400); equal(value.saleMin,900); equal(value.profitMin,500); equal(value.returnMin,125)
    equal(value.quote,400); equal(#value.materials,2); equal(value.materials[1].quantity,2)
end)
test("crafting losses are negative and percentage uses material cost", function()
    local w,A=craftingWorld(); local value=A.Crafting.Analyze(2,w.form)
    equal(value.profitMin,-100); equal(value.returnMin,-25)
    equal(A.CraftingUI.SignedMoney(value.profitMin),"-1s 00c")
end)
test("crafting multi-output yield scales sale and unit costs conservatively", function()
    local w,A=craftingWorld(); local value=A.Crafting.Analyze(3,w.form)
    equal(value.quantityMin,2); equal(value.quantityMax,4)
    equal(value.saleMin,1000); equal(value.saleMax,2000)
    equal(value.profitMin,600); equal(value.profitMax,1600)
    equal(value.unitCostMin,100); equal(value.unitCostMax,200); equal(value.returnMin,150)
end)
test("quotes add configurable markup once without rounding material inputs", function()
    local w,A=craftingWorld(); A.DB.data.settings.quoteMarkup=25
    near(A.Crafting.Analyze(1,w.form).quote,500)
    near(A.Crafting.Quote(2/3,50),1)
    equal(A.Crafting.Quote(400,-1),nil); equal(A.Crafting.Quote(400,1001),nil)
    equal(A.Crafting.Quote(secret,25),nil)
end)
test("missing material prices keep profit and quote unavailable", function()
    local w,A=craftingWorld(); w.recipes[1].schematic.reagentSlotSchematics[2].reagents={{itemID=999}}
    local value=A.Crafting.Analyze(1,w.form)
    equal(value.cost,nil); equal(value.quote,nil); equal(value.profitMin,nil)
    equal(value.subtotal,200); equal(value.missing[1],999)
end)
test("missing output price retains a complete material quote", function()
    local w,A=craftingWorld(); w.recipes[1].output={itemID=999}
    local value=A.Crafting.Analyze(1,w.form)
    equal(value.cost,400); equal(value.quote,400); equal(value.profitMin,nil); truth(value.reason)
end)
test("direct enchants and other services receive material quotes without invented sale values", function()
    local w,A=craftingWorld(); w.recipes[4]=craftRecipe(4,nil); w.recipes[4].info.isEnchantingRecipe=true
    local value=A.Crafting.Analyze(4,w.form)
    equal(value.cost,400); equal(value.quote,400); equal(value.service,true); equal(value.saleMin,nil)
end)
test("required alternative reagents are priced only after complete selection", function()
    local w,A=craftingWorld(); local slot=w.recipes[1].schematic.reagentSlotSchematics[1]
    slot.reagents={{itemID=100},{itemID=102}}
    equal(A.Crafting.Analyze(1).cost,nil)
    w.allocations={{dataSlotIndex=1,reagent={itemID=102},quantity=2}}
    equal(A.Crafting.Analyze(1,w.form).cost,300)
    w.allocations[1].quantity=1; equal(A.Crafting.Analyze(1,w.form).cost,nil)
end)
test("selected optional materials are included and unselected slots are omitted", function()
    local w,A=craftingWorld()
    w.recipes[1].schematic.reagentSlotSchematics[3]={required=false,quantityRequired=1,dataSlotIndex=3,reagents={{itemID=102}},variableQuantities={}}
    equal(A.Crafting.Analyze(1).cost,400)
    w.modified={{dataSlotIndex=3,reagent={itemID=102},quantity=1}}
    equal(A.Crafting.Analyze(1,w.form).cost,450); equal(w.outputReagents[1].reagent.itemID,102)
end)
test("a fixed reagent is costed in full when only part is owned", function()
    local w,A=craftingWorld(); w.allocations={{dataSlotIndex=1,reagent={itemID=100},quantity=1}}
    equal(A.Crafting.Analyze(1,w.form).cost,400)
end)
test("malformed or restricted reagent choices never produce a profit", function()
    for _,bad in ipairs({secret,-1,1.5}) do
        local w,A=craftingWorld(); w.recipes[1].schematic.reagentSlotSchematics[1].quantityRequired=bad
        equal(A.Crafting.Analyze(1,w.form).profitMin,nil)
    end
    local w,A=craftingWorld(); w.allocations={{dataSlotIndex=1,reagent={itemID=secret},quantity=2}}
    equal(A.Crafting.Analyze(1,w.form).cost,nil)
end)
test("currencies and variable reagent quantities are not assigned fictitious market values", function()
    local w,A=craftingWorld(); local slot=w.recipes[1].schematic.reagentSlotSchematics[1]
    slot.reagents={{currencyID=1}}; equal(A.Crafting.Analyze(1).cost,nil)
    slot.reagents={{itemID=100}}; slot.variableQuantities={{quantity=2}}
    equal(A.Crafting.Analyze(1).cost,nil)
end)
test("stale and mismatched selected reagent slots are rejected", function()
    local w,A=craftingWorld(); w.allocations={{dataSlotIndex=9,reagent={itemID=102},quantity=1}}
    equal(A.Crafting.Analyze(1,w.form).cost,nil)
    w.allocations[1].dataSlotIndex=1; equal(A.Crafting.Analyze(1,w.form).cost,nil)
end)
test("quality output recipes require selection for a ranking price", function()
    local w,A=craftingWorld(); w.recipes[1].info.supportsQualities=true
    equal(A.Crafting.Analyze(1).profitMin,nil)
    equal(A.Crafting.Analyze(1,w.form).profitMin,500)
end)
test("unlearned recipes and non-fixed salvage or recraft recipes are excluded", function()
    local w,A=craftingWorld(); w.recipes[1].info.learned=false
    equal(A.Crafting.Analyze(1),nil)
    w.recipes[1].info.learned=true; w.recipes[1].info.isSalvageRecipe=true
    equal(A.Crafting.Analyze(1).cost,nil)
end)
test("zero material cost has no divided-by-zero return percentage", function()
    local w,A=craftingWorld(); w.recipes[1].schematic.reagentSlotSchematics={}
    local value=A.Crafting.Analyze(1,w.form)
    equal(value.cost,0); equal(value.profitMin,900); equal(value.returnMin,nil); equal(value.quote,0)
end)
test("profit catalog is batched and ranks only profitable fully priced recipes", function()
    local w,A=craftingWorld(); A.Crafting.Tick()
    local rows=A.Crafting.Ranked("profit")
    equal(#rows,2); equal(rows[1].recipeID,3); equal(rows[2].recipeID,1)
    equal(A.Crafting.selected.recipeID,1); equal(A.Crafting.ready,true)
    w.recipeIDs={}
    for index=1,45 do w.recipeIDs[index]=index; w.recipes[index]=craftRecipe(index,200) end
    A.Crafting.Invalidate(); A.Crafting.Tick(); equal(A.Crafting.cursor,21); equal(A.Crafting.ready,false)
    A.Crafting.Tick(); A.Crafting.Tick(); equal(A.Crafting.ready,true); equal(#A.Crafting.Ranked("profit"),45)
end)
test("profit and return sorting use separate metrics with deterministic ties", function()
    local w,A=craftingWorld()
    A.Crafting.rows={
        {recipeID=1,name="A",profitMin=1000,returnMin=10},
        {recipeID=2,name="B",profitMin=500,returnMin=100},
        {recipeID=3,name="C",profitMin=500,returnMin=100},
    }
    equal(A.Crafting.Ranked("profit")[1].recipeID,1)
    local rows=A.Crafting.Ranked("return"); equal(rows[1].recipeID,2); equal(rows[2].recipeID,3)
end)
test("catalog ignores duplicate and unlearned IDs without changing profession filters", function()
    local w,A=craftingWorld(); w.recipeIDs={1,1,2,3}; w.recipes[2].info.learned=false
    A.Crafting.Tick(); equal(#A.Crafting.rows,2); equal(w.catalogCalls,1)
end)
test("new complete prices and profession changes rebuild the catalog", function()
    local w,A=craftingWorld(); A.Crafting.Tick(); equal(A.Crafting.selected.profitMin,500)
    newScan(w,{row(100,1,200),row(101,1,200),row(200,1,900)}); w:drain()
    A.Crafting.Tick(); equal(A.Crafting.selected.cost,600); equal(A.Crafting.selected.profitMin,300)
    equal(w.catalogCalls,2); w.professionID=171; A.Crafting.Tick(); equal(w.catalogCalls,3)
end)
test("selected recipe and selected optional reagents refresh without changing native state", function()
    local w,A=craftingWorld(); A.Crafting.Tick(); equal(A.Crafting.selected.recipeID,1)
    w.selectedID=2; A.Crafting.Tick(); equal(A.Crafting.selected.profitMin,-100)
    equal(w.openRecipeCalls,nil); equal(w.requests,1)
end)
test("native crafting panel displays values and quote markup and preserves close behavior", function()
    local w,A=craftingWorld(); A.Crafting.Tick()
    truth(A.CraftingUI.frame:IsShown()); equal(A.CraftingUI.values[1].text,"4s 00c")
    equal(A.CraftingUI.values[4].text,"+5s 00c"); equal(A.CraftingUI.values[5].text,"+125.0%")
    A.CraftingUI.frame.CloseButton.scripts.OnClick(); A.Crafting.Tick(); equal(A.CraftingUI.frame:IsShown(),false)
    A.CraftingUI.opener.scripts.OnClick(); truth(A.CraftingUI.frame:IsShown())
    w.selectedID=2; A.Crafting.Tick(); equal(A.CraftingUI.values[4].text,"-1s 00c"); equal(A.CraftingUI.values[5].text,"-25.0%")
end)
test("profit recipe buttons select through the native API without crafting", function()
    local w,A=craftingWorld(); A.Crafting.Tick(); A.CraftingUI.mode="profit"; A.CraftingUI.Refresh()
    local button=A.CraftingUI.catalogRows[1]; equal(button.recipeID,3)
    button.scripts.OnClick(button); equal(w.selectedID,3); equal(w.openRecipeCalls,1); equal(w.requests,1)
end)
test("crafting closes with professions and defers combat work", function()
    local w,A=craftingWorld(); A.Crafting.Tick(); local calls=w.catalogCalls
    w.combat=true; w:event("PLAYER_REGEN_DISABLED"); A.Crafting.Tick()
    equal(A.CraftingUI.frame:IsShown(),false); equal(w.catalogCalls,calls)
    w.combat=false; ProfessionsFrame:Hide(); A.Crafting.Tick(); equal(A.CraftingUI.opener:IsShown(),false)
    ProfessionsFrame:Show(); A.Crafting.Tick(); truth(A.CraftingUI.frame:IsShown())
end)
test("unsupported native profession APIs report cleanly and keep auction prices", function()
    local w,A=craftingWorld(); C_TradeSkillUI.GetAllRecipeIDs=nil
    A.Crafting.Tick(); truth(A.Crafting.reason); equal(A.Crafting.selected.cost,400); equal(A.DB.Price(100).low,100)
    C_TradeSkillUI.GetRecipeSchematic=nil; equal(A.Crafting.Supported(),false); equal(A.Crafting.Analyze(1),nil)
end)
test("test revision diagnostics identify resumable progress and crafting support", function()
    local w,A=craftingWorld(); A.Crafting.Tick()
    local text=A.UI.DiagnosticsText(); truth(string.find(text,"Test revision: 4",1,true))
    truth(string.find(text,"Crafting API: true",1,true)); truth(string.find(text,"Selected recipe: 1",1,true))
    equal(A.VERSION,"1.1.0-beta"); equal(A.BUILD,"2026-10-11-beta001")
end)
test("filtered native catalog fallback is labeled and leaves the user's filters intact", function()
    local w,A=craftingWorld(); C_TradeSkillUI.GetAllRecipeIDs=nil
    C_TradeSkillUI.GetFilteredRecipeIDs=function() return {2,3} end
    A.Crafting.Tick(); equal(A.Crafting.catalogScope,"filtered")
    equal(#A.Crafting.Ranked("profit"),1); equal(A.Crafting.Ranked("profit")[1].recipeID,3)
    A.CraftingUI.mode="profit"; A.CraftingUI.Refresh()
    truth(string.find(A.CraftingUI.catalogNote.text,"current filters",1,true))
end)
test("public combat prices survive inaccessible quantities as each-only values", function()
    local w,A=initial(); w.combat=true; local tooltip=bagTooltip(w,100,20)
    w.containers["0:1"].stackCount=secret
    A.Tooltips.Handle(tooltip,tooltip.data)
    equal(findLine(tooltip.lines,A.TITLE).right,"Each"); truth(findLine(tooltip.lines,"AH low"))
end)
test("crafting output values outside the exact copper range remain quote-only", function()
    local w,A=craftingWorld(); A.DB.Snapshot().prices[200].low=9007199254740991
    A.DB.Snapshot().variants["200:0"].low=9007199254740991
    w.recipes[1].schematic.quantityMin=2; w.recipes[1].schematic.quantityMax=2
    local value=A.Crafting.Analyze(1,w.form)
    equal(value.cost,400); equal(value.saleMin,nil); equal(value.profitMin,nil); truth(value.reason)
end)
test("a missing selected output quality cannot substitute a generic recipe output", function()
    local w,A=craftingWorld(); w.recipes[1].info.supportsQualities=true; w.recipes[1].output={}
    local value=A.Crafting.Analyze(1,w.form)
    equal(value.cost,400); equal(value.profitMin,nil); truth(value.reason)
    w.recipes[1].output={itemID=secret}; equal(A.Crafting.Analyze(1,w.form).profitMin,nil)
end)
test("native output hyperlinks identify an item when the output ID is not yet cached", function()
    local w,A=craftingWorld(); w.recipes[1].output={hyperlink=link(200)}
    w.recipes[1].schematic.outputItemID=nil
    local value=A.Crafting.Analyze(1,w.form)
    equal(value.outputID,200); equal(value.profitMin,500)
end)
test("1.0.0 settings and snapshot survive beta upgrade with a safe quote default", function()
    local w,A=initial(); local snapshot=A.DB.Snapshot(); local saved=A.DB.data
    saved.version="1.0.0"; saved.settings.quoteMarkup=nil; saved.settings.staleHours=72
    local w2,A2=fresh(saved); w2:load(); equal(A2.DB.Snapshot(),snapshot)
    equal(A2.DB.Settings().quoteMarkup,0); equal(A2.DB.Settings().staleHours,72); equal(w2.requests,0)
end)

test("public auction prices do not wait for cosmetic item information", function()
    local w,A=fresh(); local value=row(100,3,1000,0,false); value.publicPrices=true
    w:start({value}); w:drain()
    equal(A.Scanner.state,"COMPLETE"); near(A.DB.Price(100).low,1000/3); equal(w.loadRequests,0)
end)
test("closing and reopening after copying resumes with an empty native buffer", function()
    local w,A,old=initial(); local rows={}
    for i=1,250 do rows[i]=row(200,2,1000) end
    newScan(w,rows); A.Scanner.Tick(); truth(A.Scanner.localReady); equal(A.Scanner.work.processedRows,100)
    local cooldown=A.DB.data.cooldownUntil
    w:event("AUCTION_HOUSE_CLOSED"); w.rows={}; w:event("REPLICATE_ITEM_LIST_UPDATE")
    equal(A.Scanner.state,"PAUSED"); equal(A.DB.Snapshot(),old)
    w:event("AUCTION_HOUSE_SHOW"); truth(A.Scanner.Resume()); w:drain()
    equal(A.Scanner.state,"COMPLETE"); equal(A.DB.Price(200).auctions,250); equal(A.DB.Price(200).units,500)
    equal(w.requests,2); equal(A.DB.data.cooldownUntil,cooldown)
end)
test("a local copy needs no native auction row getters to resume", function()
    local w,A=fresh(); local rows={}
    for i=1,151 do rows[i]=row(100,1,100) end
    w:start(rows); A.Scanner.Tick(); truth(A.Scanner.Pause())
    C_AuctionHouse.GetNumReplicateItems=function() error("native buffer cleared") end
    C_AuctionHouse.GetReplicateItemInfo=function() error("native rows cleared") end
    C_AuctionHouse.GetReplicateItemLink=function() error("native links cleared") end
    truth(A.Scanner.Resume()); w:drain(); equal(A.DB.Price(100).auctions,151); equal(w.requests,1)
end)
test("paused copying protects unread rows without changing completed or staged prices", function()
    local w,A,old=initial(); local rows={}
    for i=1,1601 do rows[i]=row(200,1,100) end
    newScan(w,rows); A.Scanner.Tick(); truth(A.Scanner.Pause())
    local staged=A.Scanner.work.processedRows
    for _=1,20 do A.eventFrame.scripts.OnUpdate(A.eventFrame,0.016) end
    truth(A.Scanner.localReady); equal(A.Scanner.work.processedRows,staged); equal(A.DB.Snapshot(),old)
    w:event("AUCTION_HOUSE_CLOSED"); w.rows={}; w:event("AUCTION_HOUSE_SHOW")
    truth(A.Scanner.Resume()); w:drain(); equal(A.DB.Price(200).auctions,1601); equal(w.requests,2)
end)
test("an early buffer loss keeps the incomplete scan and cooldown", function()
    local w,A,old=initial(); local rows={}
    for i=1,251 do rows[i]=row(200,1,100) end
    A.COPY_BATCH_SIZE=100; newScan(w,rows); A.Scanner.Tick(); equal(A.Scanner.work.processedRows,100)
    local staged=A.Scanner.work; local cooldown=A.DB.data.cooldownUntil
    w:event("AUCTION_HOUSE_CLOSED"); w.rows={}; w:event("AUCTION_HOUSE_SHOW")
    local ok,reason=A.Scanner.Resume()
    equal(ok,false); truth(string.find(reason,"Progress kept",1,true)); equal(A.Scanner.state,"PAUSED")
    equal(A.Scanner.work,staged); equal(A.DB.Snapshot(),old); equal(A.DB.data.cooldownUntil,cooldown); equal(w.requests,2)
end)
test("a temporarily absent buffer can resume without another request", function()
    local w,A=fresh(); local rows={}
    for i=1,251 do rows[i]=row(100,1,100) end
    A.COPY_BATCH_SIZE=100; w:start(rows); A.Scanner.Tick(); A.Scanner.Pause()
    w.overrideCount=0; equal(A.Scanner.Resume(),false); w.overrideCount=nil
    truth(A.Scanner.Resume()); w:drain(); equal(A.DB.Price(100).auctions,251); equal(w.requests,1)
end)
test("lost-buffer restart waits for the cooldown and never mixes partial prices", function()
    local w,A,old=initial(); local rows={}
    for i=1,251 do rows[i]=row(200,1,100) end
    A.COPY_BATCH_SIZE=100; newScan(w,rows); A.Scanner.Tick(); A.Scanner.Pause()
    w.rows={}; equal(A.Scanner.Resume(),false)
    local staged=A.Scanner.work
    equal(A.Scanner.Restart(),false); equal(A.Scanner.work,staged); equal(A.DB.Snapshot(),old)
    w:advance(901); truth(A.Scanner.Resume()); equal(A.Scanner.state,"WAITING"); equal(w.requests,3)
    equal(A.DB.Snapshot(),old); w.rows={row(200,1,900),row(300,1,800)}
    A.Scanner.OnResponse(); w:drain(); equal(A.DB.Price(200).low,900); equal(A.DB.Price(200).auctions,1)
    equal(A.DB.Snapshot().processedRows,2)
end)
test("same-count replacement rows cannot be merged with an incomplete local copy", function()
    local w,A,old=initial(); local rows={}
    for i=1,251 do rows[i]=row(200,1,100) end
    A.COPY_BATCH_SIZE=100; newScan(w,rows); A.Scanner.Tick(); A.Scanner.Pause()
    rows[1]=row(200,1,999)
    equal(A.Scanner.Resume(),false); equal(A.Scanner.state,"FAILED"); equal(A.DB.Snapshot(),old)
end)
test("a competing scan cannot overwrite a complete local copy", function()
    local w,A=fresh(); local rows={}
    for i=1,151 do rows[i]=row(100,1,100) end
    w:start(rows); A.Scanner.Tick(); A.Scanner.Pause(); truth(A.Scanner.localReady)
    C_AuctionHouse.ReplicateItems(); w.rows={row(200,1,999)}; A.Scanner.OnResponse()
    equal(A.Scanner.state,"PAUSED"); truth(A.Scanner.Resume()); w:drain()
    equal(A.DB.Price(100).auctions,151); equal(A.DB.Price(200),nil)
end)
test("resolved copied rows survive native buffer loss during a paused retry", function()
    local w,A=fresh(); w:start({row(100,1,100,0,false)})
    A.Scanner.Tick(); equal(A.Scanner.state,"RESOLVING"); A.Scanner.Pause()
    w.rows[1].allInfo=true; w.mono=w.mono+0.6; A.Scanner.CopyTick(); truth(A.Scanner.localReady)
    w:event("AUCTION_HOUSE_CLOSED"); w.rows={}; w:event("AUCTION_HOUSE_SHOW")
    truth(A.Scanner.Resume()); w:drain(); equal(A.DB.Price(100).low,100); equal(w.requests,1)
end)
test("copying respects its row and CPU budgets", function()
    local w,A=fresh(); local rows={}
    for i=1,1001 do rows[i]=row(100,1,100) end
    w:start(rows); A.COPY_BATCH_SIZE=50; A.Scanner.CopyTick(); equal(A.Scanner.copiedRows,50)
    debugprofilestop=function() w.cpu=w.cpu+2; return w.cpu end
    A.Scanner.CopyTick(); equal(A.Scanner.copiedRows,52); equal(A.Scanner.work.processedRows,0)
end)
test("the reported 98455-row scan can copy and resume without loading item names", function()
    local w,A=fresh(); local rows={}
    for i=1,98455 do local value=row(100,2,200,0,false); value.publicPrices=true; rows[i]=value end
    w:start(rows); A.Scanner.Pause()
    for _=1,1000 do if A.Scanner.localReady then break end; A.Scanner.CopyTick() end
    truth(A.Scanner.localReady); equal(A.Scanner.copiedRows,98455); equal(A.Scanner.work.processedRows,0)
    equal(w.loadRequests,0); w:event("AUCTION_HOUSE_CLOSED"); w.rows={}; w:event("AUCTION_HOUSE_SHOW")
    truth(A.Scanner.Resume()); w:drain()
    equal(A.DB.Snapshot().totalRows,98455); equal(A.DB.Price(100).auctions,98455); equal(A.DB.Price(100).units,196910)
    equal(w.requests,1)
end)
test("item-data event floods do not rebuild or empty a completed profitability list", function()
    local w,A=craftingWorld(); A.Crafting.Tick(); local rows=A.Crafting.rows; local ranked=A.Crafting.Ranked("profit")
    local calls=w.itemCalls; local builds=A.Crafting.builds
    w.items[100]={name="Loaded material"}
    for i=1,100 do
        w:event("GET_ITEM_INFO_RECEIVED",100,true); w:event("GET_ITEM_INFO_RECEIVED",10000+i,true); A.Crafting.Tick()
        equal(A.Crafting.rows,rows); equal(A.Crafting.Ranked("profit"),ranked)
    end
    equal(A.Crafting.builds,builds); equal(A.Crafting.publications,1)
    truth(w.itemCalls<=calls+1)
end)
test("a rebuilding profitability list publishes only the complete replacement", function()
    local w,A=craftingWorld(); A.Crafting.Tick(); local rows=A.Crafting.rows; local ranked=A.Crafting.Ranked("profit")
    w.recipeIDs={}
    for i=1,45 do w.recipeIDs[i]=i; w.recipes[i]=craftRecipe(i,200) end
    A.Crafting.Invalidate(); A.Crafting.Tick(); equal(A.Crafting.ready,false)
    equal(A.Crafting.rows,rows); equal(A.Crafting.Ranked("profit"),ranked)
    w:event("GET_ITEM_INFO_RECEIVED",101,true); w:event("TRADE_SKILL_LIST_UPDATE")
    A.Crafting.Tick(); equal(A.Crafting.cursor,41); equal(A.Crafting.rows,rows)
    A.Crafting.Tick(); truth(A.Crafting.ready); equal(#A.Crafting.Ranked("profit"),45); equal(A.Crafting.publications,2)
end)
test("repeated native list updates leave identical recipe valuations and builds stable", function()
    local w,A=craftingWorld(); A.Crafting.Tick(); local rows=A.Crafting.rows
    for i=1,40 do
        w.mono=w.mono+0.25; w.recipeIDs=i%2==0 and {3,2,1,1} or {1,2,3}
        w:event("TRADE_SKILL_LIST_UPDATE"); A.Crafting.Tick(); equal(A.Crafting.rows,rows)
    end
    equal(A.Crafting.builds,1); equal(A.Crafting.publications,1); truth(w.catalogCalls<=12)
end)
test("new recipe IDs and newly learned recipes refresh a stable catalog", function()
    local w,A=craftingWorld(); w.recipes[2].info.learned=false; A.Crafting.Tick()
    equal(#A.Crafting.rows,2); w.recipes[2].info.learned=true; w:event("NEW_RECIPE_LEARNED",2)
    A.Crafting.Tick(); equal(#A.Crafting.rows,3); equal(A.Crafting.builds,2)
    w.recipes[4]=craftRecipe(4,200); w.recipeIDs={1,2,3,4}; w:event("TRADE_SKILL_LIST_UPDATE"); A.Crafting.Tick()
    equal(#A.Crafting.rows,4); equal(A.Crafting.builds,3)
end)
test("loading a material name updates labels without repricing or reordering recipes", function()
    local w,A=craftingWorld(); A.Crafting.Tick(); local rows=A.Crafting.rows
    w.items[100]={name="Loaded material"}; w:event("GET_ITEM_INFO_RECEIVED",100,true)
    equal(A.Crafting.selected.materials[1].name,"Loaded material")
    equal(A.Crafting.rows,rows); equal(A.Crafting.builds,1); equal(rows[1].materials[1].name,"Loaded material")
end)
test("the profit page retains the source timestamp until new valuations publish", function()
    local w,A=craftingWorld(); A.Crafting.Tick(); local old=A.Crafting.publishedSnapshot
    w.recipeIDs={}
    for i=1,45 do w.recipeIDs[i]=i; w.recipes[i]=craftRecipe(i,200) end
    newScan(w,{row(100,1,200),row(101,1,200),row(200,1,900)}); w:drain(); A.Crafting.Tick()
    equal(A.Crafting.publishedSnapshot,old); A.Crafting.Tick(); A.Crafting.Tick()
    equal(A.Crafting.publishedSnapshot,A.DB.Snapshot()); equal(A.Crafting.rows[1].cost,600)
end)
test("a profession change does not show the previous profession's recipe list", function()
    local w,A=craftingWorld(); A.Crafting.Tick(); w.professionID=171; w.recipeIDs={}
    for i=1,45 do w.recipeIDs[i]=i; w.recipes[i]=craftRecipe(i,200) end
    A.Crafting.Tick(); equal(#A.Crafting.rows,0); equal(A.Crafting.ready,false)
    A.Crafting.Tick(); A.Crafting.Tick(); equal(#A.Crafting.rows,45)
end)
test("service quotes use the requested concise ea format", function()
    local w,A=craftingWorld()
    equal(A.Crafting.QuoteText({recipeID=1,name="Enchant Chest - Lesser Absorption",quote=11663,service=true}),
        "Enchant Chest - Lesser Absorption - 1g 16s 63c ea")
end)
test("native recipe hyperlinks are preserved verbatim in quotes", function()
    local w,A=craftingWorld(); local native="|cffffd000|Henchant:7426|h[Enchant Chest - Lesser Absorption]|h|r"
    C_TradeSkillUI.GetRecipeLink=function(id) equal(id,1); return native end
    equal(A.Crafting.QuoteText({recipeID=1,name="Fallback",quote=11663,service=true}),native .. " - 1g 16s 63c ea")
end)
test("missing restricted malformed or failing recipe links use a plain name", function()
    local w,A=craftingWorld(); local value={recipeID=1,name="Recipe",quote=400,quantityMin=1,quantityMax=1}
    for _,linkValue in ipairs({false,secret,"not a recipe link","|Henchant:1|hbroken"}) do
        C_TradeSkillUI.GetRecipeLink=function() return linkValue end
        equal(A.Crafting.QuoteText(value),"Recipe - 4s 00c ea")
    end
    C_TradeSkillUI.GetRecipeLink=function() error("not ready") end
    equal(A.Crafting.QuoteText(value),"Recipe - 4s 00c ea")
end)
test("fixed multi-item output quotes charge per item and round only the displayed total", function()
    local w,A=craftingWorld(); w.recipes[1].schematic.quantityMin=3; w.recipes[1].schematic.quantityMax=3
    A.DB.data.settings.quoteMarkup=20
    equal(A.Crafting.QuoteText(A.Crafting.Analyze(1,w.form)),"Recipe 1 - 1s 60c ea")
    A.DB.data.settings.quoteMarkup=0
    equal(A.Crafting.QuoteText(A.Crafting.Analyze(1,w.form)),"Recipe 1 - 1s 33c ea")
end)
test("variable or unknown output keeps an unambiguous per-craft quote", function()
    local w,A=craftingWorld(); equal(A.Crafting.QuoteText(A.Crafting.Analyze(3)),"Recipe 3 - 4s 00c per craft")
    equal(A.Crafting.QuoteText({recipeID=1,name="Recipe",quote=400}),"Recipe - 4s 00c per craft")
    equal(A.Crafting.QuoteText({recipeID=1,name="Recipe"}),nil)
end)
test("Insert in chat opens a native linked draft without sending it", function()
    local w,A=craftingWorld(); local native="|Henchant:1|h[Recipe 1]|h"
    C_TradeSkillUI.GetRecipeLink=function() return native end
    ChatFrameUtil={OpenChat=function(text) w.draft=text; w.drafts=(w.drafts or 0)+1 end}
    A.Crafting.Tick(); equal(A.CraftingUI.insertQuote.enabled,true); A.CraftingUI.insertQuote.scripts.OnClick()
    equal(w.draft,native .. " - 4s 00c ea"); equal(w.drafts,1); equal(w.requests,1)
    w.combat=true; A.CraftingUI.InsertQuote(); equal(w.drafts,1)
    w.combat=false; ProfessionsFrame:Hide(); A.CraftingUI.InsertQuote(); equal(w.drafts,1)
end)
test("the legacy native chat opener remains supported when available", function()
    local w,A=craftingWorld(); ChatFrame_OpenChat=function(text) w.draft=text end
    A.Crafting.Tick(); A.CraftingUI.InsertQuote(); equal(w.draft,"Recipe 1 - 4s 00c ea")
end)
test("a recipe or markup change cannot leave a focused old quote in the UI", function()
    local w,A=craftingWorld(); A.Crafting.Tick(); local box=A.CraftingUI.quoteBox
    box:SetFocus(); box:SetText("Old quote"); w.selectedID=2; A.Crafting.Tick()
    equal(box:HasFocus(),false); equal(box.text,"Recipe 2 - 4s 00c ea")
    box:SetFocus(); A.DB.data.settings.quoteMarkup=20; A.Crafting.Tick()
    equal(box:HasFocus(),false); equal(box.text,"Recipe 2 - 4s 80c ea")
end)
test("missing material prices disable the chat draft button", function()
    local w,A=craftingWorld(); ChatFrameUtil={OpenChat=function() error("no quote should be inserted") end}
    A.DB.Snapshot().prices[100]=nil; A.Crafting.Tick(); equal(A.CraftingUI.insertQuote.enabled,false)
    equal(A.CraftingUI.quoteText,nil); A.CraftingUI.InsertQuote()
end)
test("diagnostics distinguish copied progress and stable catalog publications", function()
    local w,A=craftingWorld(); A.Crafting.Tick(); local text=A.UI.DiagnosticsText()
    truth(string.find(text,"Test revision: 4",1,true)); truth(string.find(text,"Local auction copy: complete",1,true))
    truth(string.find(text,"Recipe catalog builds: 1",1,true)); truth(string.find(text,"Recipe catalog publications: 1",1,true))
end)

test("copying checks the retained row before a lost partial buffer returns", function()
    local w,A,old=initial(); local rows={}
    for i=1,251 do rows[i]=row(200,1,100) end
    A.COPY_BATCH_SIZE=100; newScan(w,rows); A.Scanner.Tick(); A.Scanner.Pause()
    w.overrideCount=0; equal(A.Scanner.Resume(),false); w.overrideCount=nil; rows[1]=row(200,1,999)
    A.Scanner.CopyTick(); equal(A.Scanner.state,"FAILED"); equal(A.DB.Snapshot(),old)
end)
test("a changed signed suffix is rejected before resuming an incomplete copy", function()
    local w,A=fresh(); local rows={}
    for i=1,251 do rows[i]=row(100,1,100,10) end
    A.COPY_BATCH_SIZE=100; w:start(rows); A.Scanner.Tick(); A.Scanner.Pause(); rows[1].link=link(100,20)
    equal(A.Scanner.Resume(),false); equal(A.Scanner.state,"FAILED"); equal(A.DB.Snapshot(),nil)
end)
test("a new market clears the previous profitability list while rebuilding", function()
    local w,A=craftingWorld(); A.Crafting.Tick(); w.recipeIDs={}
    for i=1,45 do w.recipeIDs[i]=i; w.recipes[i]=craftRecipe(i,200) end
    w.region=2; A.Crafting.Tick(); equal(#A.Crafting.rows,0); equal(A.Crafting.publishedSnapshot,nil)
    A.Crafting.Tick(); A.Crafting.Tick(); equal(#A.Crafting.Ranked("profit"),0)
end)

test("a synchronous item-name event cannot recurse or restart the catalog", function()
    local w,A=craftingWorld(); A.Crafting.Tick(); local getter=C_Item.GetItemInfo
    w.items[100]={name="Loaded material"}; local reads=0
    C_Item.GetItemInfo=function(id)
        reads=reads+1; truth(reads<3,"item-name getter recursed")
        w:event("GET_ITEM_INFO_RECEIVED",id,true); return getter(id)
    end
    w:event("GET_ITEM_INFO_RECEIVED",100,true)
    equal(reads,1); equal(A.Crafting.selected.materials[1].name,"Loaded material"); equal(A.Crafting.builds,1)
end)
test("a competing request during item loading safely abandons the native copy", function()
    local w,A,old=initial(); newScan(w,{row(200,1,100,0,false)})
    C_Item.RequestLoadItemDataByID=function() C_AuctionHouse.ReplicateItems() end
    A.Scanner.CopyTick(); equal(A.Scanner.state,"FAILED"); equal(A.Scanner.work,nil); equal(A.DB.Snapshot(),old)
end)

local function nextDayScan(w, rows)
    w.wall = math.floor(w.wall / 86400) * 86400 + 86400 + 100
    newScan(w, rows); w:drain()
end

test("history defaults to thirty days with manual crafting and profitable-only views", function()
    local w,A=fresh(); w:load()
    equal(A.DB.Settings().historyDays,30); equal(A.DB.Settings().showHistory,true)
    equal(A.DB.Settings().craftAutoOpen,false); equal(A.DB.Settings().showAllRecipes,false)
    equal(A.History.Status().days,0); equal(A.History.Average(100),nil)
end)
test("one completed scan provides a one-day unit-price average", function()
    local _,A=initial(); local value=A.History.Average(100,link(100))
    equal(value.value,900); equal(value.days,1); equal(value.mode,"variant")
    equal(A.History.Status().days,1)
end)
test("the latest same-day scan replaces prices rather than accumulating samples", function()
    local w,A=initial(); newScan(w,{row(100,1,500),row(200,1,700)}); w:drain()
    equal(A.History.Average(100).value,500); equal(A.History.Average(100).days,1)
    equal(A.History.Status().days,1); equal(A.History.Average(200).value,700)
end)
test("a same-day replacement removes items absent from the final scan", function()
    local w,A=initial(); newScan(w,{row(200,1,700)}); w:drain()
    equal(A.History.Average(100),nil); equal(A.DB.Price(100),nil)
end)
test("an older completed scan cannot overwrite the latest history for a day", function()
    local w,A,old=initial(); newScan(w,{row(100,1,500)}); w:drain()
    local latest=A.DB.Snapshot(); A.DB.data.markets[old.marketKey]=old
    equal(A.History.Record(old),false); equal(A.History.Average(100).value,500)
    A.DB.data.markets[old.marketKey]=latest
end)
test("daily averages weight each available day once despite different auction counts", function()
    local w,A=initial(); nextDayScan(w,{row(100,2,300),row(100,1,200),row(100,10,5000)})
    local average=A.History.Average(100)
    equal(average.days,2); equal(average.value,525); equal(A.DB.Price(100).low,150)
end)
test("missing listings and missing calendar days are not zero-valued samples", function()
    local w,A=initial(); nextDayScan(w,{row(200,1,600)})
    w.wall=w.wall+86400; nextDayScan(w,{row(100,1,300)})
    local value=A.History.Average(100); equal(value.days,2); equal(value.value,600)
    equal(A.History.Status().days,3)
end)
test("a previous daily price stays historical when the item disappears from current prices", function()
    local w,A=initial(); nextDayScan(w,{row(200,1,600)})
    equal(A.DB.Price(100),nil); equal(A.History.Average(100).value,900)
    local lines=A.Tooltips.Lines(100,link(100))
    equal(findLine(lines,"Historic avg (1 day)").right,"9s 00c")
    equal(findLine(lines,"AH low").right,"Not listed in scan")
end)
test("a completed empty daily scan is retained without inventing prices", function()
    local w,A=initial(); nextDayScan(w,{})
    equal(A.History.Status().days,2); equal(A.History.Average(100).days,1)
    equal(A.DB.Snapshot().totalRows,0)
end)
test("a same-day empty scan removes that day's earlier sample", function()
    local w,A=initial(); newScan(w,{}); w:drain()
    equal(A.History.Status().days,1); equal(A.History.Average(100),nil)
end)
test("bid-only and sold rows never supply historical buyout values", function()
    local w,A=initial(); local sold=row(200,1,500); sold.saleStatus=1
    nextDayScan(w,{row(100,1,0),sold})
    equal(A.History.Average(100).days,1); equal(A.History.Average(200),nil)
end)
test("partial and paused scans do not replace historical prices", function()
    local w,A=initial(); local rows={}; for i=1,250 do rows[i]=row(100,1,100) end
    newScan(w,rows); A.Scanner.Tick(); truth(A.Scanner.Pause())
    equal(A.History.Average(100).value,900); equal(A.History.Average(100).days,1)
    truth(A.Scanner.Resume()); w:drain(); equal(A.History.Average(100).value,100)
end)
test("failed scans and invalid commits keep history unchanged", function()
    local w,A=initial(); newScan(w,{row(100,0,100)}); w:drain()
    equal(A.Scanner.state,"FAILED"); equal(A.History.Average(100).value,900)
    local incomplete=A.DB.NewSnapshot(A.Util.MarketKey(),2,w.wall)
    equal(A.DB.Commit(incomplete),false); equal(A.History.Record(incomplete),false)
    equal(A.History.Average(100).value,900)
end)
test("history uses the scan request's UTC day when completion crosses midnight", function()
    local w,A=fresh(); w.wall=math.floor(w.wall/86400)*86400+86399
    w:start({row(100,1,700)}); local started=A.Scanner.work.startedAt
    w.wall=w.wall+2; w:drain()
    equal(A.History.Average(100).firstDay,math.floor(started/86400))
    equal(A.History.Average(100).days,1)
end)
test("thirty-day retention keeps today plus the preceding twenty-nine days", function()
    local w,A=fresh(); w:start({row(100,1,100)}); w:drain()
    for i=1,31 do nextDayScan(w,{row(100,1,100+i)}) end
    local average=A.History.Average(100); equal(A.History.Status().days,30)
    equal(average.days,30); near(average.value,116.5); equal(average.lastDay-average.firstDay,29)
end)
test("shortening retention prunes older days immediately and keeps current prices", function()
    local w,A=initial(); nextDayScan(w,{row(100,1,600)}); nextDayScan(w,{row(100,1,300)})
    local snapshot=A.DB.Snapshot(); truth(A.History.SetRetention(2))
    equal(A.History.Status().days,2); equal(A.History.Average(100).value,450)
    equal(A.DB.Snapshot(),snapshot); truth(A.History.SetRetention(1)); equal(A.History.Average(100).value,300)
end)
test("increasing retention cannot restore pruned daily history", function()
    local w,A=initial(); nextDayScan(w,{row(100,1,600)})
    truth(A.History.SetRetention(1)); truth(A.History.SetRetention(30))
    equal(A.History.Status().days,1); equal(A.History.Average(100).value,600)
    local w2,A2=fresh(A.DB.data); w2.wall=w.wall; w2:load()
    equal(A2.History.Status().days,1); equal(A2.History.Average(100).value,600)
end)
test("retention rejects zero fractions out-of-range and restricted inputs", function()
    local _,A=initial()
    for _,bad in ipairs({0,-1,31,1.5,"7",secret,math.huge,0/0}) do
        equal(A.History.SetRetention(bad),false); equal(A.DB.Settings().historyDays,30)
    end
    truth(A.History.SetRetention(30)); truth(A.History.SetRetention(1))
end)
test("UTC day rollover prunes expired history without another scan", function()
    local w,A=initial(); A.History.SetRetention(1); truth(A.History.Average(100))
    w.wall=math.floor(w.wall/86400)*86400+86400
    A.eventFrame.scripts.OnUpdate(A.eventFrame,0.25)
    equal(A.History.Status().days,0); equal(A.History.Average(100),nil); equal(A.DB.Price(100).low,900)
end)
test("history keeps factions regions and Forever rulesets separate", function()
    local w,A=fresh(); w.realm="ClassicBetaPvP2"; w.region=110
    w:start({row(100,1,900)}); w:drain(); truth(A.History.Average(100))
    w.faction="Alliance"; equal(A.History.Average(100),nil)
    w.faction="Horde"; w.region=1; equal(A.History.Average(100),nil)
    w.region=110; w.realm="ClassicBetaHardcore1"; equal(A.History.Average(100),nil)
    w.realm="ClassicBetaPvP9"; equal(A.History.Average(100).value,900)
end)
test("daily history pruning refreshes an already visible primary tooltip", function()
    local w,A=initial(); A.History.SetRetention(1)
    GameTooltip.info={getterName="GetItemByID"}; GameTooltip.data={id=100,type=0}; GameTooltip.link=link(100)
    GameTooltip:Show(); A.Tooltips.Handle(GameTooltip,GameTooltip.data)
    truth(findLine(GameTooltip.lines,"Historic avg (1 day)"))
    w.wall=math.floor(w.wall/86400)*86400+86400
    A.eventFrame.scripts.OnUpdate(A.eventFrame,0.25)
    equal(findLine(GameTooltip.lines,"Historic avg (1 day)"),nil); equal(GameTooltip.rebuilds,1)
    truth(findLine(GameTooltip.lines,"AH low"))
end)
test("history pruning defers primary tooltip rebuilds until combat ends", function()
    local w,A=initial(); A.History.SetRetention(1)
    GameTooltip.info={getterName="GetItemByID"}; GameTooltip.data={id=100,type=0}; GameTooltip.link=link(100)
    GameTooltip:Show(); A.Tooltips.Handle(GameTooltip,GameTooltip.data)
    w.combat=true; w.wall=math.floor(w.wall/86400)*86400+86400
    A.eventFrame.scripts.OnUpdate(A.eventFrame,0.25)
    equal(GameTooltip.rebuilds,nil); equal(A.refreshTooltips,true)
    w.combat=false; w:event("PLAYER_REGEN_ENABLED"); A.eventFrame.scripts.OnUpdate(A.eventFrame,0.25)
    equal(GameTooltip.rebuilds,1); equal(findLine(GameTooltip.lines,"Historic avg (1 day)"),nil)
end)
test("random suffix averages never blend other variants into a matching series", function()
    local w,A=fresh(); w:start({row(100,1,900,-5),row(100,1,100,-6)}); w:drain()
    nextDayScan(w,{row(100,1,300,-6)})
    local exact=A.History.Average(100,link(100,-5)); equal(exact.value,900); equal(exact.days,1); equal(exact.mode,"variant")
    equal(A.History.Average(100,link(100,-6)).value,200)
    local fallback=A.History.Average(100,link(100,-7)); equal(fallback.mode,"item-wide"); equal(fallback.value,200)
end)
test("mismatched item links cannot choose another item's historical variant", function()
    local w,A=fresh(); w:start({row(100,1,900),row(200,1,100)}); w:drain()
    equal(A.History.Average(100,link(200)).value,900); equal(A.History.Average(secret),nil)
    equal(A.History.Average(100,secret).value,900)
end)
test("historical unit prices retain fractions and stack multiplication precedes rounding", function()
    local w,A=fresh(); w:start({row(100,3,10)}); w:drain(); nextDayScan(w,{row(100,3,11)})
    near(A.History.Average(100,link(100)).value,3.5)
    equal(findLine(A.Tooltips.Lines(100,link(100),3),"Historic avg (2 days)").right,"4c / 11c")
end)
test("large valid historical prices average without an overflowing sum", function()
    local w,A=fresh(); w:start({row(100,1,9007199254740991)}); w:drain()
    nextDayScan(w,{row(100,1,9007199254740991)})
    equal(A.History.Average(100).value,9007199254740991); equal(A.History.Average(100).days,2)
end)
test("upgrading imports only the last existing complete snapshot without a server request", function()
    local w,A=initial(); local snapshot=A.DB.Snapshot(); local saved=A.DB.data; saved.history=nil
    local w2,A2=fresh(saved); w2:load()
    equal(A2.DB.Snapshot(),snapshot); equal(A2.History.Average(100).value,900)
    equal(A2.History.Status().days,1); equal(w2.requests,0)
end)
test("migration skips incomplete expired and differently keyed saved snapshots", function()
    local _,A=initial(); local saved=A.DB.data; saved.history=nil
    local snapshot=A.DB.Snapshot(); snapshot.complete=false
    local w2,A2=fresh(saved); w2:load(); equal(A2.History.Status().days,0)
    snapshot.complete=true; snapshot.startedAt=w2.wall-31*86400; saved.history=nil
    local w3,A3=fresh(saved); w3:load(); equal(A3.History.Status().days,0)
    snapshot.startedAt=w3.wall; snapshot.marketKey="wrong"; saved.history=nil
    local w4,A4=fresh(saved); w4:load(); equal(A4.History.Status().days,0)
end)
test("history survives a saved-table serialization and independent addon load", function()
    local w,A=initial(); nextDayScan(w,{row(100,1,300)})
    local function serialize(value)
        if type(value)=="number" or type(value)=="boolean" then return tostring(value) end
        if type(value)=="string" then return string.format("%q",value) end
        local entries={}; for k,v in pairs(value) do entries[#entries+1]="["..serialize(k).."]="..serialize(v) end
        return "{"..table.concat(entries,",").."}"
    end
    local saved=assert(loadstring("return "..serialize(A.DB.data)))()
    local w2,A2=fresh(saved); w2.wall=w.wall; w2:load()
    equal(A2.History.Average(100).value,600); equal(A2.History.Average(100).days,2)
    equal(w2.requests,0); equal(A2.DB.Price(100).low,300)
end)
test("invalid saved retention values use the thirty-day default", function()
    for _,bad in ipairs({0,31,1.5,"7",secret,0/0}) do
        local w,A=fresh({schema=1,markets={},settings={historyDays=bad}}); w:load()
        equal(A.DB.Settings().historyDays,30); equal(A.disabledReason,nil)
    end
end)
test("malformed and future history roots are preserved without disabling current prices", function()
    for _,history in ipairs({{schema=99,markets={keep=true}},"malformed",secret}) do
        local _,A=initial(); local saved=A.DB.data; saved.history=history
        local w2,A2=fresh(saved); w2:load()
        truth(rawequal(A2.DB.data.history,history)); equal(A2.History.Average(100),nil)
        truth(A2.History.reason); equal(A2.DB.Price(100).low,900); equal(A2.disabledReason,nil)
        newScan(w2,{row(100,1,500)}); w2:drain(); equal(A2.DB.Price(100).low,500)
        truth(rawequal(A2.DB.data.history,history))
    end
end)
test("malformed daily records and future timestamps do not enter the average", function()
    local w,A=initial(); local key=A.Util.MarketKey(); local today=math.floor(w.wall/86400)
    A.DB.data.history.markets[key][today-1]={startedAt=w.wall-2*86400,prices={[100]=100},variants={}}
    A.DB.data.history.markets[key][today+1]={startedAt=w.wall+86400,prices={[100]=100},variants={}}
    A.DB.data.history.markets[key][today-2]=secret
    A.DB.data.history.markets[key]["wrong"]={startedAt=w.wall,prices={[100]=100},variants={}}
    A.DB.data.history.markets["malformed"]=secret
    local w2,A2=fresh(A.DB.data); w2:load()
    equal(A2.History.Status().days,1); equal(A2.History.Average(100).value,900)
end)
test("saved historical prices discard restricted invalid and noncanonical keys", function()
    local w,A=initial(); local day=math.floor(w.wall/86400); local key=A.Util.MarketKey()
    local record=A.DB.data.history.markets[key][day]
    record.prices={[100]=900,[200]=secret,[201]=-1,[202]=0,[203]=math.huge,[204]=0/0,[0]=100,["100"]=1}
    record.variants={["100:0"]=900,["100:-5"]=secret,["0100:0"]=100,["100:00"]=100,["999999999999:0"]=100}
    local w2,A2=fresh(A.DB.data); w2:load()
    equal(A2.History.Average(100).value,900); equal(A2.History.Average(200),nil)
    equal(A2.History.Average(201),nil); equal(A2.History.Average(202),nil)
    equal(A2.History.data.markets[key][day].variants["0100:0"],nil)
end)
test("history stores numeric lows without retaining auction rows sellers or mutable price records", function()
    local _,A,snapshot=initial(); local day=math.floor(snapshot.startedAt/86400)
    local record=A.History.data.markets[snapshot.marketKey][day]
    equal(type(record.prices[100]),"number"); equal(record.prices[100],900)
    equal(record.rows,nil); equal(record.sellers,nil); equal(record.processedRows,nil)
    snapshot.prices[100].low=100; equal(record.prices[100],900)
end)
test("average cache invalidates on completed replacement and retention change", function()
    local w,A=initial(); local first=A.History.Average(100); equal(A.History.Average(100),first)
    equal(A.History.Average(200),nil); newScan(w,{row(100,1,500),row(200,1,700)}); w:drain()
    truth(A.History.Average(100)~=first); equal(A.History.Average(200).value,700)
    nextDayScan(w,{row(100,1,300)}); equal(A.History.Average(100).value,400)
    A.History.SetRetention(1); equal(A.History.Average(100).value,300)
end)
test("average caching stays bounded when many different missing items are queried", function()
    local _,A=initial()
    for id=1000,5500 do equal(A.History.Average(id),nil) end
    truth(A.History.cacheEntries<=4096); equal(A.History.Average(100).value,900)
end)
test("tooltips order vendor history recent scan and disenchant in the price block", function()
    local w,A=initial(); w.items[100]={quality=2,level=17,classID=4}
    local lines=A.Tooltips.Lines(100,link(100))
    local _,vendor=findLine(lines,"Vendor sell"); local _,history=findLine(lines,"Historic avg (1 day)")
    local _,auction=findLine(lines,"AH low"); local _,de=findLine(lines,"DE expected")
    truth(vendor<history and history<auction and auction<de)
end)
test("the historic-average display can be disabled without deleting collected data", function()
    local _,A=initial(); A.DB.data.settings.showHistory=false
    equal(findLine(A.Tooltips.Lines(100,link(100)),"Historic avg (1 day)"),nil)
    equal(A.History.Average(100).value,900); A.DB.data.settings.showHistory=true
    truth(findLine(A.Tooltips.Lines(100,link(100)),"Historic avg (1 day)"))
end)
test("history-only tooltips remain useful while unpriced items have no empty section", function()
    local _,A=initial(); local settings=A.DB.data.settings
    settings.showVendor=false; settings.showAuction=false; settings.showDisenchant=false
    local lines=A.Tooltips.Lines(100,link(100)); truth(findLine(lines,"Historic avg (1 day)"))
    equal(#A.Tooltips.Lines(999,link(999)),0)
end)
test("historical averages decorate public combat item tooltips once", function()
    local w,A=initial(); w.combat=true; local tooltip=bagTooltip(w,100,20)
    A.Tooltips.Handle(tooltip,tooltip.data); local count=tooltip:NumLines()
    equal(findLine(tooltip.lines,"Historic avg (1 day)").right,"9s 00c / 1g 80s 00c")
    A.Tooltips.Handle(tooltip,tooltip.data); equal(tooltip:NumLines(),count)
end)
test("item-wide history fallback is visibly labeled", function()
    local _,A=initial(); local lines=A.Tooltips.Lines(100,link(100,-999))
    equal(findLine(lines,"History scope").right,"Item-wide")
    equal(findLine(lines,"Historic avg (1 day)").right,"9s 00c")
end)
test("settings expose retention and auto-open with working category buttons", function()
    local _,A=initial(); A.UI.Create(); A.UI.frame:Show()
    equal(A.UI.retentionBox.text,"30"); truth(A.UI.checks.showHistory); truth(A.UI.checks.craftAutoOpen)
    truth(A.UI.tooltipSettings:IsShown()); equal(A.UI.craftSettings:IsShown(),false)
    A.UI.craftSettingsTab.scripts.OnClick(); truth(A.UI.craftSettings:IsShown()); equal(A.UI.tooltipSettings:IsShown(),false)
    A.UI.tooltipSettingsTab.scripts.OnClick(); truth(A.UI.tooltipSettings:IsShown())
end)
test("retention Apply validates entries prunes data and preserves focused input", function()
    local w,A=initial(); nextDayScan(w,{row(100,1,300)}); A.UI.Create()
    A.UI.retentionBox:SetText("0"); A.UI.retentionApply.scripts.OnClick(); equal(A.DB.Settings().historyDays,30)
    A.UI.retentionBox:SetText("1"); A.UI.retentionBox:SetFocus(); A.UI.Refresh(); equal(A.UI.retentionBox.text,"1")
    A.UI.retentionBox.scripts.OnEnterPressed(); equal(A.DB.Settings().historyDays,1)
    equal(A.History.Status().days,1); equal(A.History.Average(100).value,300)
    equal(A.UI.retentionBox:HasFocus(),false)
end)
test("new profession sessions stay closed by default and expose a top toggle", function()
    local w,A=craftingWorld(); A.DB.data.settings.craftAutoOpen=false; A.Crafting.Tick()
    equal(A.CraftingUI.frame:IsShown(),false); truth(A.CraftingUI.opener:IsShown())
    equal(A.CraftingUI.opener.text,"Show profits")
    equal(A.CraftingUI.opener.points[1][1],"RIGHT"); equal(A.CraftingUI.opener.points[1][2],ProfessionsFrame.CloseButton)
    equal(A.CraftingUI.opener:GetParent(),ProfessionsFrame.CraftingPage); truth(A.CraftingUI.opener:IsVisible())
    A.CraftingUI.opener.scripts.OnClick(); truth(A.CraftingUI.frame:IsShown())
    equal(A.CraftingUI.opener.text,"Hide profits"); equal(A.CraftingUI.values[1].text,"4s 00c")
    A.CraftingUI.opener.scripts.OnClick(); equal(A.CraftingUI.frame:IsShown(),false)
    A.Crafting.Tick(); equal(A.CraftingUI.frame:IsShown(),false)
end)
test("auto-open settings survive loading and enable opening on the next profession session", function()
    local w,A=craftingWorld(); A.Crafting.Tick(); A.UI.Create()
    local check=A.UI.checks.craftAutoOpen; check:SetChecked(false); check.scripts.OnClick(check)
    equal(A.DB.Settings().craftAutoOpen,false)
    ProfessionsFrame:Hide(); A.Crafting.Tick(); ProfessionsFrame:Show(); A.Crafting.Tick()
    equal(A.CraftingUI.frame:IsShown(),false)
    check:SetChecked(true); check.scripts.OnClick(check)
    A.Crafting.Tick(); equal(A.CraftingUI.frame:IsShown(),false)
    ProfessionsFrame:Hide(); A.Crafting.Tick(); ProfessionsFrame:Show(); A.Crafting.Tick(); truth(A.CraftingUI.frame:IsShown())
    local w2,A2=fresh(A.DB.data); w2:load(); equal(A2.DB.Settings().craftAutoOpen,true)
end)
test("the profession toggle stays above Forever's raised crafting page", function()
    local w,A=craftingWorld(); ProfessionsFrame.CraftingPage:SetFrameLevel(100); A.Crafting.Tick()
    truth(A.CraftingUI.opener:GetFrameLevel()>ProfessionsFrame.CraftingPage:GetFrameLevel())
    ProfessionsFrame.CraftingPage:SetFrameLevel(160); A.Crafting.Tick()
    truth(A.CraftingUI.opener:GetFrameLevel()>ProfessionsFrame.CraftingPage:GetFrameLevel())
end)
test("the manual toggle clears Forever's level 500 border and level 510 title", function()
    local _,A=craftingWorld(); A.DB.data.settings.craftAutoOpen=false; A.Crafting.Tick()
    local button=A.CraftingUI.opener
    for _,frame in ipairs({ProfessionsFrame.NineSlice,ProfessionsFrame.TitleContainer,ProfessionsFrame.CloseButton,ProfessionsFrame.CraftingPage}) do
        truth(button:GetFrameLevel()>frame:GetFrameLevel(),"toggle covered by native header")
    end
    truth(button:IsVisible()); equal(A.CraftingUI.frame:IsShown(),false)
    button.scripts.OnClick(); truth(A.CraftingUI.frame:IsShown())
end)
test("the profession toggle follows changes to header levels and strata", function()
    local _,A=craftingWorld(); A.Crafting.Tick()
    ProfessionsFrame.TitleContainer:SetFrameLevel(830); ProfessionsFrame.TitleContainer:SetFrameStrata("HIGH")
    A.Crafting.Tick(); truth(A.CraftingUI.opener:GetFrameLevel()>830); equal(A.CraftingUI.opener:GetFrameStrata(),"HIGH")
    ProfessionsFrame.NineSlice:SetFrameLevel(920); ProfessionsFrame.NineSlice:SetFrameStrata("DIALOG")
    A.Crafting.Tick(); truth(A.CraftingUI.opener:GetFrameLevel()>920); equal(A.CraftingUI.opener:GetFrameStrata(),"DIALOG")
end)
test("manual opening needs neither an auto-open setting nor a selected priced recipe", function()
    local w,A=craftingWorld(); A.DB.data.settings.craftAutoOpen=false; w.selectedID=nil; A.DB.data.markets={}
    A.Crafting.Tick(); truth(A.CraftingUI.opener:IsVisible()); equal(A.CraftingUI.frame:IsShown(),false)
    A.CraftingUI.opener.scripts.OnClick(); truth(A.CraftingUI.frame:IsShown())
    equal(A.CraftingUI.recipeName.text,"Select a learned recipe"); equal(A.CraftingUI.values[1].text,"Unavailable")
end)
test("switching to the profession book immediately hides the profits window and toggle", function()
    local _,A=craftingWorld(); A.DB.data.settings.craftAutoOpen=false; A.Crafting.Tick()
    A.CraftingUI.opener.scripts.OnClick(); truth(A.CraftingUI.frame:IsShown())
    ProfessionsFrame.CraftingPage:Hide(); truth(ProfessionsFrame:IsShown())
    equal(A.CraftingUI.opener:IsVisible(),false); equal(A.CraftingUI.frame:IsShown(),false)
    ProfessionsFrame.CraftingPage:Show(); A.Crafting.Tick()
    truth(A.CraftingUI.opener:IsVisible()); equal(A.CraftingUI.frame:IsShown(),false)
end)
test("replacing the native page reuses and reanchors the toggle without stale hide hooks", function()
    local w,A=craftingWorld(); A.Crafting.Tick()
    local button,oldPage=A.CraftingUI.opener,ProfessionsFrame.CraftingPage
    w:openProfession(); A.Crafting.Tick()
    equal(A.CraftingUI.opener,button); equal(button:GetParent(),ProfessionsFrame.CraftingPage)
    equal(button.points[1][2],ProfessionsFrame.CloseButton); equal(#button.points,1)
    oldPage:Hide(); truth(button:IsVisible()); truth(A.CraftingUI.frame:IsShown())
end)
test("unchanged profession refreshes do not create more controls or anchors", function()
    local w,A=craftingWorld(); A.Crafting.Tick(); local count,button=w.createdFrames,A.CraftingUI.opener
    for i=1,40 do A.Crafting.Tick() end
    equal(w.createdFrames,count); equal(A.CraftingUI.opener,button); equal(#button.points,1)
end)
test("a missing native close button uses a guarded title-bar anchor", function()
    local _,A=craftingWorld(); ProfessionsFrame.CloseButton=nil; A.Crafting.Tick()
    truth(A.CraftingUI.opener:IsVisible()); equal(A.CraftingUI.opener.points[1][1],"TOPRIGHT")
    equal(A.CraftingUI.opener.points[1][2],ProfessionsFrame)
    truth(A.CraftingUI.opener:GetFrameLevel()>ProfessionsFrame.TitleContainer:GetFrameLevel())
end)
test("crafting diagnostics report manual visibility and actual header levels", function()
    local _,A=craftingWorld(); A.DB.data.settings.craftAutoOpen=false
    truth(string.find(A.UI.DiagnosticsText(),"Crafting toggle: not created",1,true)); equal(A.CraftingUI.opener,nil)
    A.Crafting.Tick(); local text=A.UI.DiagnosticsText()
    truth(string.find(text,"Crafting toggle: shown; visible=true; strata=MEDIUM; level=511",1,true))
    truth(string.find(text,"Profession header levels: border=500; title=510; page=100",1,true))
    truth(string.find(text,"Crafting window: hidden",1,true))
    A.CraftingUI.opener.scripts.OnClick(); truth(string.find(A.UI.DiagnosticsText(),"Crafting window: shown",1,true))
end)
test("restricted header values are neither compared nor formatted by controls or diagnostics", function()
    local _,A=craftingWorld()
    ProfessionsFrame.NineSlice.GetFrameLevel=function() return secret end
    ProfessionsFrame.TitleContainer.GetFrameStrata=function() return secret end
    A.Crafting.Tick(); truth(A.CraftingUI.opener:IsVisible())
    truth(string.find(A.UI.DiagnosticsText(),"border=unavailable; title=510",1,true))
end)
test("a forbidden profession page cannot create a manual toggle", function()
    local _,A=craftingWorld(); ProfessionsFrame.CraftingPage.forbidden=true
    A.Crafting.Tick(); equal(A.CraftingUI.opener,nil); equal(A.CraftingUI.frame,nil)
    SlashCmdList.MSMARKETVALUE("craft"); equal(A.CraftingUI.frame,nil)
end)
test("direct crafting updates in combat cannot create manual controls", function()
    local w,A=craftingWorld(); w.combat=true
    A.CraftingUI.Update(); equal(A.CraftingUI.opener,nil); equal(A.CraftingUI.frame,nil)
end)
test("manual close stays closed through refreshes even when auto-open is enabled", function()
    local w,A=craftingWorld(); A.Crafting.Tick(); A.CraftingUI.opener.scripts.OnClick()
    for i=1,20 do A.Crafting.Tick() end
    equal(A.CraftingUI.frame:IsShown(),false); equal(A.CraftingUI.opener.text,"Show profits")
    ProfessionsFrame:Hide(); A.Crafting.Tick(); ProfessionsFrame:Show(); A.Crafting.Tick(); truth(A.CraftingUI.frame:IsShown())
end)
test("the crafting slash command opens a manually configured window on first use", function()
    local w,A=craftingWorld(); A.DB.data.settings.craftAutoOpen=false
    SlashCmdList.MSMARKETVALUE("craft"); truth(A.CraftingUI.frame:IsShown()); equal(A.CraftingUI.opener.text,"Hide profits")
end)
test("craft toggling in combat cannot show or change native UI", function()
    local w,A=craftingWorld(); A.DB.data.settings.craftAutoOpen=false; A.Crafting.Tick()
    w.combat=true; A.CraftingUI.opener.scripts.OnClick(); equal(A.CraftingUI.frame:IsShown(),false)
    SlashCmdList.MSMARKETVALUE("craft"); equal(A.CraftingUI.frame:IsShown(),false)
end)
test("all-recipes ranking includes losses break-even and unknown values last", function()
    local w,A=craftingWorld()
    w.recipes[4]=craftRecipe(4,999); w.recipes[5]=craftRecipe(5,200); w.recipes[5].schematic.reagentSlotSchematics[1].quantityRequired=7
    w.recipeIDs={1,2,3,4,5}; A.Crafting.Tick()
    local all=A.Crafting.Ranked("profit",true); equal(#all,5)
    equal(all[1].recipeID,3); equal(all[2].recipeID,1); equal(all[3].profitMin,0)
    equal(all[4].recipeID,2); equal(all[4].profitMin,-100); equal(all[5].recipeID,4); equal(all[5].profitMin,nil)
    equal(#A.Crafting.Ranked("profit"),2)
end)
test("all-recipes return sorting places undefined percentages after known losses", function()
    local _,A=craftingWorld(); A.Crafting.rows={
        {recipeID=1,name="A",profitMin=900,returnMin=nil,cost=0},
        {recipeID=2,name="B",profitMin=-100,returnMin=-25,cost=400},
        {recipeID=3,name="C",profitMin=500,returnMin=125,cost=400},
        {recipeID=4,name="D",profitMin=nil,returnMin=nil},
    }
    local all=A.Crafting.Ranked("return",true)
    equal(#all,4); equal(all[1].recipeID,3); equal(all[2].recipeID,2); equal(all[3].recipeID,1); equal(all[4].recipeID,4)
    equal(#A.Crafting.Ranked("return"),1)
end)
test("unknown recipe values sort deterministically by name and ID", function()
    local _,A=craftingWorld(); A.Crafting.rows={
        {recipeID=3,name="B"},{recipeID=2,name="A"},{recipeID=1,name="A"},
    }
    local all=A.Crafting.Ranked("profit",true)
    equal(all[1].recipeID,1); equal(all[2].recipeID,2); equal(all[3].recipeID,3)
end)
test("all-recipes mode shows service quotes without inventing auction profitability", function()
    local w,A=craftingWorld(); w.recipes[4]=craftRecipe(4,nil); w.recipes[4].info.isEnchantingRecipe=true
    w.recipeIDs={1,2,3,4}; A.Crafting.Tick()
    local all=A.Crafting.Ranked("profit",true); equal(#all,4)
    equal(all[4].recipeID,4); equal(all[4].cost,400); equal(all[4].profitMin,nil); equal(all[4].service,true)
end)
test("show-all button updates row counts pages and red negative values without a rebuild", function()
    local w,A=craftingWorld(); A.Crafting.Tick(); A.CraftingUI.mode="profit"; A.CraftingUI.Refresh()
    local published=A.Crafting.rows; local builds=A.Crafting.builds; A.CraftingUI.page=2
    A.CraftingUI.showAllButton.scripts.OnClick(); equal(A.DB.Settings().showAllRecipes,true)
    equal(A.CraftingUI.page,1); equal(A.Crafting.rows,published); equal(A.Crafting.builds,builds)
    equal(A.CraftingUI.showAllButton.text,"Profitable only")
    equal(A.CraftingUI.catalogRows[3].profit.text,"-1s 00c"); equal(A.CraftingUI.catalogRows[3].percent.text,"-25.0%")
    equal(A.CraftingUI.catalogRows[3].profit.color[1],1); truth(string.find(A.CraftingUI.pageText.text,"3 recipes",1,true))
    A.CraftingUI.showAllButton.scripts.OnClick(); equal(A.DB.Settings().showAllRecipes,false)
    equal(A.CraftingUI.showAllButton.text,"Show all recipes"); equal(A.CraftingUI.catalogRows[3]:IsShown(),false)
end)
test("unpriced all-recipes rows display unavailable rather than zero or no cost", function()
    local w,A=craftingWorld(); w.recipeIDs={4}; w.recipes[4]=craftRecipe(4,999)
    A.Crafting.Tick(); A.CraftingUI.mode="profit"; A.DB.data.settings.showAllRecipes=true; A.CraftingUI.Refresh()
    equal(A.CraftingUI.catalogRows[1].profit.text,"Unavailable"); equal(A.CraftingUI.catalogRows[1].percent.text,"Unavailable")
    A.CraftingUI.catalogRows[1].scripts.OnClick(A.CraftingUI.catalogRows[1])
    equal(w.selectedID,4); truth(string.find(A.CraftingUI.reason.text,"no buyout",1,true))
end)
test("all-recipes setting persists and ranking caches both filter modes independently", function()
    local _,A=craftingWorld(); A.Crafting.Tick()
    local profitable=A.Crafting.Ranked("profit"); local all=A.Crafting.Ranked("profit",true)
    equal(A.Crafting.Ranked("profit"),profitable); equal(A.Crafting.Ranked("profit",true),all); truth(all~=profitable)
    A.DB.data.settings.showAllRecipes=true
    local w2,A2=fresh(A.DB.data); w2:load(); equal(A2.DB.Settings().showAllRecipes,true)
end)
test("the all-recipes list keeps its completed snapshot during staged refreshes", function()
    local w,A=craftingWorld(); A.Crafting.Tick(); local all=A.Crafting.Ranked("profit",true)
    w.recipeIDs={}; for id=1,45 do w.recipeIDs[id]=id; w.recipes[id]=craftRecipe(id,201) end
    A.Crafting.Invalidate(); A.Crafting.Tick(); equal(A.Crafting.Ranked("profit",true),all)
    A.Crafting.Tick(); equal(A.Crafting.Ranked("profit",true),all)
    A.Crafting.Tick(); equal(#A.Crafting.Ranked("profit",true),45); equal(#A.Crafting.Ranked("profit"),0)
end)
test("history diagnostics report revision retention dates and crafting preferences", function()
    local _,A=initial(); local text=A.UI.DiagnosticsText()
    truth(string.find(text,"Test revision: 4",1,true)); truth(string.find(text,"retention=30 days",1,true))
    truth(string.find(text,"History dates UTC:",1,true)); truth(string.find(text,"Craft auto-open: false",1,true))
    truth(string.find(text,"Recipe list filter: profitable only",1,true))
end)

print(string.format("RESULT: %d/%d behavioral tests passed (Lua %s). Live-client validation pending.", testCount, testCount, _VERSION))
