local _, A = ...
local H = { count = 0 }
A.Help = H

-- Only addon interface help uses this switch. Item values and world drop
-- tooltips keep their existing display settings.
function H.Enabled()
    return A.DB.Settings().showInterfaceTips ~= false
end

function H.Hide(owner)
    if H.owner and (not owner or H.owner == owner) then
        if GameTooltip and GameTooltip:GetOwner() == H.owner then GameTooltip:Hide() end
        H.owner = nil
    end
end

function H.Begin(owner)
    if not H.Enabled() or not GameTooltip then H.Hide(owner); return end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    H.owner = owner
    return GameTooltip
end

function H.Show(owner, text)
    if not text or text == "" then return end
    local tooltip = H.Begin(owner)
    if not tooltip then return end
    tooltip:AddLine(text, 1, 1, 1, true)
    tooltip:Show()
end

function H.Refresh()
    if not H.Enabled() then H.Hide() end
end

function H.Bind(widget, text)
    if not widget or not text then return end
    widget.msmvHelp = text
    if widget.msmvHelpBound then return end
    widget.msmvHelpBound = true
    H.count = H.count + 1
    if type(widget.SetMotionScriptsWhileDisabled) == "function" then widget:SetMotionScriptsWhileDisabled(true) end
    widget:HookScript("OnEnter", function(self)
        if not H.Enabled() then return end
        local description = self.msmvHelp
        if type(description) == "function" then description = description(self) end
        H.Show(self, description)
    end)
    widget:HookScript("OnLeave", function(self) H.Hide(self) end)
    widget:HookScript("OnHide", function(self) H.Hide(self) end)
end

local common = {
    ["Apply"] = "Save changes in this section.",
    ["Farming"] = "View your farming session, saved sessions and drop settings.",
    ["Ledger"] = "Review this character's income, spending and recorded sales.",
    ["Watchlists"] = "Track items and buying targets for this market.",
    ["Copy diagnostics"] = "Open diagnostics for copying with Ctrl+C.",
}
local buttons = {
    main = {
        ["Scan entire AH"] = "Start or resume a full auction scan. Keep the AH open until the local copy finishes.",
        ["Pause scan"] = "Pause this scan and keep its progress for resuming.",
        ["Restart scan"] = "Discard unfinished progress and request a new full scan when the cooldown allows.",
        ["Tooltips"] = "Choose which item values and interface help appear on hover.",
        ["Crafting & history"] = "Set crafting auto-open and how many pricing days to keep.",
        ["Exclude"] = "Hide the disenchant estimate for this item ID.",
        ["Restore estimate"] = "Remove this item's disenchant exclusion.",
    },
    craft = {
        ["Selected recipe"] = "View the selected recipe's materials, profit and quote.",
        ["Recipe list"] = "Browse learned recipes and compare profit or service quotes.",
        ["Pricing"] = "Set the AH cut, quote markup and service charges.",
        ["Show all recipes"] = "Switch between profitable recipes and all learned recipes.",
        ["Apply pricing"] = "Save these pricing settings and update crafting values.",
        ["Reset fields"] = "Restore the saved pricing settings in these fields.",
        ["Insert in chat"] = "Put this quote in the chat box for review before sending.",
        ["Record sale"] = "Add a commission to your ledger using the entered payment and estimated material cost.",
        ["X"] = "Clear the recipe search.",
        ["Profit / craft"] = "Sort recipes by net profit per craft or the service quote.",
        ["Return %"] = "Sort recipes by profit as a percentage of material cost.",
    },
    market = {
        ["Resale"] = "Show listings that meet your profit, return and price-movement filters against earlier prices.",
        ["Rising"] = "Show price increases that meet your movement and history filters.",
        ["Falling"] = "Show price decreases that meet your movement and history filters.",
        ["All signals"] = "Show qualifying resale, rising and falling price signals together.",
        ["All items"] = "Show current listings, including variants without enough earlier pricing days.",
        ["Arbitrage"] = "Compare the selected faction average with the latest neutral scan.",
        ["Sort: return"] = "Sort by return or net profit per item. Rising and Falling also sort by price movement.",
        ["Recheck saved scan"] = "Recalculate opportunities from saved prices without starting an auction scan.",
        ["Filters"] = "Show or hide profit, history, quantity and rarity filters.",
        ["Apply filters"] = "Save these filters and update results from the saved scan.",
        ["Apply search"] = "Apply the keyword and filters to the saved scan.",
        ["Watch selected"] = "Set buying targets for the selected item or exact modifier.",
    },
    economy = {
        ["Watch settings"] = function() return A.EconomyUI.mode == "watch" and "Choose when watchlist alerts appear." or "Open the main addon settings." end,
        ["Period report"] = "Summarize income, spending and profit for the selected dates.",
        ["Transactions"] = "Browse and edit individual entries for the selected dates.",
        ["Ledger settings"] = "Choose automatic tracking and how long to keep transactions.",
        ["Copy period CSV"] = "Open this period's transactions as CSV for copying with Ctrl+C.",
        ["New entry"] = "Record a purchase, sale, commission or expense manually.",
        ["Apply dates"] = "Show transactions between these local dates, including both dates.",
        ["Record entry"] = "Save this transaction to the ledger.",
        ["Use open invoice"] = "Fill these fields from the selected auction mail invoice for review.",
        ["Clear fields"] = "Start a new manual entry without changing saved transactions.",
        ["Delete entry"] = "Delete the selected transaction. Undo delete can restore the last deletion.",
        ["Undo delete"] = "Restore the most recently deleted transaction.",
        ["View other spending"] = "Show other expenses, such as travel, training and mailing costs.",
    },
    watch = {
        ["Add watch"] = "Add an item by pasting or dragging an item link. You can also add it from its Buy page.",
        ["Edit"] = "Change this item's buying targets or remove its watch.",
        ["Save watch"] = "Save per-item buying targets. All enabled targets must be met.",
        ["Remove watch"] = "Stop watching this item in this market.",
    },
    farm = {
        ["Session"] = "Review session totals, hourly rates, items and recent pickups.",
        ["Farming settings"] = "Set item valuation, idle behavior and the small farming display.",
        ["Drop rates"] = "Choose drop data, sorting, rarity filters and personal observation settings.",
        ["Manage"] = "Set the saved-session limit or delete the selected past session.",
        ["Delete selected"] = "Delete the selected saved session after confirmation. The current session is kept.",
        ["Pause"] = "Pause or resume the current session. A manual pause waits for manual resume.",
        ["Reset session"] = "Save this session and start a new one after confirmation, within your saved-session limit.",
        ["Items"] = "Show collected items, quantities and their estimated value for this session.",
        ["Recent pickups"] = "Show recent items and gold at their value when received.",
        ["Current session"] = "Return to the active session from a saved session.",
        ["Reset selected"] = "Clear personal drop observations in the selected scope after confirmation.",
    },
}

function H.Button(widget, scope, label)
    H.Bind(widget, (buttons[scope] or {})[label] or common[label])
end

local settings = {
    priceBasis = "Daily averages weight each UTC date equally. Intraday averages use all completed scans today (UTC).",
    marketPriceBasis = "Switch the faction price basis for Opportunities. Right-click to follow the addon setting.",
    showInterfaceTips = "Show control help and list details inside addon windows, including addon AH buttons.",
    showMinimapBadge = "Show the shortcut that opens MS Market Value from the minimap.",
    showVendor = "Add the item's vendor sell price to item tooltips.",
    showHistory = "Show historic average prices and the number of sampled UTC days on item tooltips.",
    showAuction = "Show the lowest buyout from your latest saved auction scan.",
    showDisenchant = "Show an estimated disenchant value. Reference rates are unverified for Forever.",
    showMaterials = "Show possible disenchant materials, quantities and chances.",
    showAge = "Show the scan's age and mark auction values stale after your chosen limit.",
    craftAutoOpen = "Open crafting profits automatically when you open a profession.",
    historyDays = "Keep 1-30 UTC days of auction prices. Reducing this removes older pricing days.",
    staleHours = "Mark saved auction prices stale after 1-168 hours.",
    marketFee = "AH cut used for net profit and farming AH values, from 0-30 percent.",
    quoteMarkup = "Add 0-1000 percent to material cost when calculating a crafting quote.",
    serviceLabor = "Labor charge in gold per service. Customer-material quotes use labor or the minimum, whichever is higher.",
    serviceMinimum = "Minimum service quote in gold, whether you or the customer supplies materials.",
    serviceCustomerMaterials = "Quote labor or the minimum charge when the customer supplies all materials.",
    marketMinReturn = "Minimum net profit as a percentage of the buy price, from 0-1000 percent.",
    marketMinProfit = "Minimum net profit per item in gold. For example, 0.25 is 25 silver.",
    marketLookback = "Set the Daily baseline's lookback from 1 to 30 UTC days, excluding the current scan's date.",
    marketMinDays = "Set the Daily baseline's minimum earlier priced UTC days for each exact variant.",
    marketMove = "Minimum price change from the historic baseline, in percent. Use 0 to turn this filter off.",
    marketLowMin = "Minimum quantity offered at the lowest unit price. Use 0 for no minimum.",
    marketLowMax = "Maximum quantity offered at the lowest unit price. Use 0 for no maximum.",
    marketStockMin = "Minimum total listed quantity for this item variant. Use 0 for no minimum.",
    marketStockMax = "Maximum total listed quantity for this item variant. Use 0 for no maximum.",
    marketStockDrop = "Minimum stock decrease from earlier stock levels, from 0-100 percent. Use 0 to turn it off.",
    marketQuality = "Choose which item rarities appear, then apply the filters.",
    trackAH = "Record observed auction purchases and sales in this character's ledger.",
    trackVendor = "Record vendor purchases and sales in the ledger. Farming pickups are not counted again.",
    trackTrade = "Record confirmed incoming and outgoing trade gold as tips.",
    trackLoot = "Record looted gold as a daily ledger total.",
    trackOther = "Record recognized expenses such as travel, training and mailing costs.",
    ledgerDays = "Keep 1-365 days of transactions. Reducing this removes older entries.",
    watchAlerts = "Enable grouped alerts when watched items meet all their active targets.",
    watchOpenOnScan = "Open the watchlist after a completed scan finds a new match or a lower matched price.",
    watchOpenOnAH = "Show pending watchlist matches when you visit the AH, once it is safe to open the window.",
    watchChatAlerts = "Print one local chat summary per alert batch. No messages are sent to other players.",
    watchReadyOnly = "Show only watched items that meet all active targets in the saved scan.",
    farmTracking = "Record new farming pickups and active time for this character.",
    farmShow = "Show the small farming rate display on screen.",
    farmShowTotal = "Include the session's estimated total value in the small display.",
    farmHover = "Show the small display's text only while the pointer is over it.",
    farmHUDLocked = "Lock the small display in place. Unlock it to drag it.",
    farmUseAuction = "Use the saved AH price after the AH cut when it clears your threshold above vendor value.",
    farmThreshold = "Required percent above vendor value after the AH cut, from 0-1000 percent.",
    farmIdle = "Stop active time after no combat or loot for the chosen limit. Combat or loot resumes it.",
    farmIdleMinutes = "Idle limit from 5-60 minutes since combat or the last loot pickup.",
    farmHUDWidth = "Width of the small farming display, from 240-520 pixels.",
    farmPauseOnDeath = "Pause on death until combat, loot or manual resume. Manual pauses stay paused.",
    dropTracking = "Collect personal loot observations, including checked empty corpses.",
    showDrops = "Show creature drop rates on world tooltips.",
    showHarvestDrops = "Include separate herb, ore and skinning rates on world tooltips.",
    dropRows = "Show up to 1-10 drops per tooltip section after sorting and filtering.",
    dropSort = "Keep needed quest items first, then sort by drop chance or chance times estimated item value.",
    dropQuality = "Choose which rarities appear. Needed quest items stay visible and come first.",
}

function H.Setting(widget, key)
    H.Bind(widget, settings[key])
end
