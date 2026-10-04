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
    for _, method in ipairs({ "SetFrameLevel", "SetHitRectInsets", "SetClampedToScreen", "EnableMouse", "SetMovable", "RegisterForDrag", "StartMoving", "StopMovingOrSizing", "SetBackdrop", "SetBackdropColor", "SetBackdropBorderColor", "SetJustifyH", "SetFontObject", "SetMultiLine", "SetAutoFocus", "SetMaxLetters", "SetNumeric", "SetStatusBarTexture", "SetStatusBarColor", "SetMinMaxValues" }) do
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
    _G.LibStub, _G.AuctionHouseFrame, _G.AuctionHouseFrameDisplayMode = nil, nil, nil
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
            return nil, nil, row.quantity, 2, true, 20, nil, 0, 0,
                   row.buyout, 0, nil, nil, nil, nil, row.saleStatus or 0, row.id, row.allInfo
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
    equal(A.Scanner.state, "FAILED"); equal(A.DB.Snapshot(), old)
end)
test("request timeout and a late response keep the old snapshot", function()
    local w, A, old = initial(); w:advance(901); truth(A.Scanner.Start()); w:advance(121)
    equal(A.Scanner.state, "FAILED"); A.Scanner.OnResponse(); equal(A.DB.Snapshot(), old)
end)
test("auction-house close cancels safely", function()
    local w, A, old = initial(); newScan(w, {row(200, 1, 100)})
    A.auctionOpen = false; A.Scanner.Tick(); equal(A.Scanner.state, "CANCELLED"); equal(A.DB.Snapshot(), old)
end)
test("combat cancels a scan and suppresses tooltip calculations", function()
    local w, A, old = initial(); newScan(w, {row(200, 1, 100)})
    w.combat = true; A.Scanner.Tick(); equal(A.DB.Snapshot(), old)
    GameTooltip.data = {id = 100}; A.Tooltips.Handle(GameTooltip, GameTooltip.data)
    equal(GameTooltip:NumLines(), 0); equal(w.itemCalls, nil)
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
test("combat and forbidden frames suppress quantity API reads and native getter failures recover", function()
    local w, A = initial(); local tooltip = bagTooltip(w, 100, 20)
    w.combat = true; equal(A.Tooltips.StackCount(tooltip, tooltip.data, 100), 1)
    w.combat = false; tooltip.forbidden = true
    equal(A.Tooltips.StackCount(tooltip, tooltip.data, 100), 1); equal(w.containerReads, nil)
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
test("1.0.0 retains the completed beta003 market, settings, exclusions and cooldown without rescanning", function()
    local w, A = fresh(); w.realm="ClassicBetaPvP2"; w.region=90
    w:start({row(100,1,500)}); w:drain()
    local saved, snapshot = A.DB.data, A.DB.Snapshot()
    saved.version, saved.build = "0.1.0-beta", "2026-10-04-beta003"
    snapshot.version, snapshot.build = saved.version, saved.build
    saved.settings.staleHours=72; saved.excludedItems[300]=true
    local w2,A2 = fresh(saved); w2.realm="ClassicBetaPvP2"; w2.region=90; w2:load()
    equal(A2.VERSION,"1.0.0"); equal(A2.DB.Price(100).low,500); equal(A2.DB.Snapshot(),snapshot)
    equal(A2.DB.data.settings.staleHours,72); equal(A2.DB.data.excludedItems[300],true)
    equal(A2.Scanner.RemainingCooldown(),900); equal(w2.requests,0)
end)

print(string.format("RESULT: %d/%d behavioral tests passed (Lua %s). Live-client validation pending.", testCount, testCount, _VERSION))
