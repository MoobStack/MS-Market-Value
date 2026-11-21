# Changelog

## 1.3.3 — 2026-11-21

- Save only the latest neutral AH scan per region and ruleset. Faction prices, history, tools and watchlists use the faction dataset.
- Identify the house from known auctioneers or locations. Ask when neither is recognized and resume paused scans only at the original house type.
- Share the game's 15-minute full-scan cooldown across faction and neutral auction houses and characters. Allow a fresh request after the cooldown if the server never replied.
- Add **Arbitrage** and its hover help at neutral auction houses. Use **Basis** to compare the latest neutral prices with exact faction Daily or Intraday averages. Profit estimates include the selling house’s cut.
- Keep the Daily/Intraday switch in regular Opportunities views. Returning from a neutral house restores your previous regular view and price basis.
- Mark base-item price fallbacks with a short **Any variant** note in item tooltips.
- Open Buy listings from Opportunities when a paused scan is still waiting for its first response. Copying auction rows still takes priority once they arrive.
- Keep current Opportunities rows clickable and hold the scroll position while item details refresh.
- Open the item's live neutral listings from every Arbitrage row. **Buy from** shows where to purchase.
- Open Arbitrage on the first visit to Opportunities at a neutral auctioneer each login.

## 1.3.2 — 2026-11-21

### Auction House and rulesets

- Restore full AH scans when Forever hides realm names. Detect the ruleset from the client and keep prices separate by region, ruleset and faction.
- Ask for a character's ruleset when detection is unavailable, with PvP selected initially. **Change ruleset** in Price snapshot lets you revise the choice or return to automatic detection.
- Keep saved scans, price history and watches available after the realm name change. Farming, drop observations, vendor costs and the ledger can record activity before the character's first AH visit.

### Prices and opportunities

- Keep the lowest unit price from each completed scan for each item and exact modifier. At the UTC day change, retain the day's averages and discard the individual price samples.
- Add the **Daily / Intraday** switch under Price settings. The selected average feeds item tooltips, crafting, disenchant estimates, farming, drop value sorting and watchlist estimates.
- Add a separate **Basis** control to Opportunities. Intraday signals compare the latest scan with earlier scans from the same UTC day. Right-click **Basis** to follow Price settings.
- Enable **Return** and **Profit** sorting in **Rising** and **Falling** alongside **Movement**.

### Interface

- Add a draggable gold minimap button that opens the addon. Hide it under Tooltips.
- Give the Price snapshot panel a full-width progress bar, put the version above it and show today's scan count. Diagnostics report the ruleset source, selected price averages and intraday scan counts.

## 1.3.1 — 2026-11-17

### Farming and drops

- Choose saved sessions from a dated menu and return directly to the current session.
- Manage saves per character and market: keep 0–50 sessions, five by default, or delete one. Deletions and reductions that remove saves require confirmation.
- Scroll through session items and recent pickups, with quantity, unit value and total columns. New saves retain the full tracked item list and recent receipts; older summaries remain readable.
- Start the calculator idle at login. Optional death pause is enabled by default; combat, received loot or Resume restarts timing. Manual pauses stay paused.
- Keep quest rewards in the session total by default, with options to include them in hourly rates or stop recording new rewards. Peaks always exclude quest gold and items.
- Prevent duplicate quest gold/items and exclude vendor sales and buyback receipts from farming. Selling a previously counted item does not add its value again.
- Recover from missing quest, vendor, mail and trade close events so later farming receipts are classified correctly. Add diagnostics for ignored money and recovered windows.
- Count reliably identified empty corpses once when calculating personal drop rates. Reopening the same body does not add another sample.
- Prevent creature and skinning drop sections from stacking outside the tooltip. Custom sections stay hidden during looting and return on refresh.

### Watchlists

- Replace pages with scrolling, name search, a target-only filter and sortable columns. Show estimated net profit alongside return; keep target highlights separate from item-name rarity colors.
- Open the item's Buy page on left-click. Right-click or Edit changes targets in a separate dialog; add items from Buy, Opportunities or pasted/dragged links without visible item IDs.
- Add watchlist-specific settings and a passive target count. New matches or lower matched prices can open one grouped review after a scan or an AH visit; chat summaries are optional and off by default.
- Remember reviewed matches across reloads and unchanged scans. Rearm after a fresh scan shows an item outside its targets or no longer listed; defer reviews during combat, selling, purchases, typing or editing.
- Reuse visible rows and cached results for larger watchlists. Late item names and rarity updates no longer require another price analysis.

### Market, crafting and interface

- Preserve an exact modifier's earlier price when a later scan on the same UTC day no longer lists it. Keep current listings separate and never carry a sample into another date.
- Show missing-history progress and exact priced dates instead of unexplained blank estimates. Diagnostics now distinguish market-wide history from each modifier's usable earlier days.
- Replace crafting recipe pages with native scrolling while retaining search, sorting, profitability filters and recipe selection.
- Add stacked red arrows beside the Sell-page copper field. Each click adjusts unit price by one copper, with denomination rollover, price limits and native total updates.
- Add short help for unfamiliar buttons, filters and settings. **Addon interface tooltips** is enabled by default under Tooltips; switching it off hides control help and list hover details. Item-value and world-drop settings remain separate.

Prices, history, watches, targets, ledger entries, settings and personal observations carry forward. See [Updating](UPGRADE.md) for older farming-session details.

## 1.3.0 — 2026-11-16

### Farming

- Add farming sessions with acquired gold, item value and separate loot, quest and harvesting totals.
- Show the whole-session hourly average, recent 60-minute rate and best completed five-minute farming rate. Peaks save the zone, available coordinates and time; quest rewards cannot inflate them.
- Add a centered, movable gold display with adjustable width, position lock, optional session total and hover-only mode.
- Add automatic idle pause, on by default after five minutes. Choose 5–60 minutes or Off; combat and qualifying loot resume the timer, while manual pauses stay paused.
- Value acquired items using vendor prices or a qualifying AH estimate. Show unpriced items, exclude mail and trades, and prevent duplicate quest/loot income.
- Add item/source filters, recent pickups and five saved session summaries. Pauses, loading screens and offline time do not count as active farming.

### Drop rates

- Add creature, skinning, herbalism and mining drop tooltips with bundled references and personal observations.
- Fill missing reference items and sources with personal drops, keeping each source's rates and sample counts separate. Personal-only display is also available.
- Track visible corpse and group loot once, including items left behind. Protect against reopening, partial looting and reload duplicates; unseen kills do not enter the sample count.
- Keep needed quest drops visible and first. Hide quest-only items when their quest is absent, without deleting observations.
- Add high-to-low and low-to-high rate sorting, expected-item-value sorting, six colored rarity choices and a 1–10-item display limit.
- Add resets by creature/node, zone, dungeon or character, with collection and harvesting-tooltip controls.

### Market and interface

- Keep full modifier names, links and separate prices/history for random suffixes and bonus-based variants, including watchlists and live Buy navigation.
- Add keyword, rarity, low-price quantity, total stock and stock-decline filters. Show units at the lowest price and their combined buyout.
- Add All items for current prices before enough history exists, a scrolling 12-row list and collapsible filters. Explain missing variant history separately from other signal filters.
- Use coin icons in displayed money and rarity colors in item names. Quotes, exports and numeric inputs stay plain text.
- Allow the main window, money tools, farming report and diagnostics to open in combat. Protected actions still wait until combat ends.

### Fixes

- Stop Opportunities from endlessly rebuilding after searches or filter changes. Retain resolved item data when native replies are repeated, partial or temporarily unavailable.
- Resolve generic modifier names without hovering and prevent one modifier from borrowing another's name, history or Buy listing.
- Improve creature/node identification and loot-source reading when tooltip data is incomplete. Refresh changed drop tooltips without duplicate sections.
- Correct idle timing and automatic resume around combat, reloads and loading screens; prevent manual pauses from resuming themselves.
- Keep overlapping addon windows on separate layers so their titles and controls remain usable.
- Reduce repeated item lookups and reuse prepared market results so large scans and repeated filter changes do less work.

Existing prices, history, settings, watchlists, ledger entries and personal records carry forward. A new scan adds the newer modifier and supply details; older history remains saved.

## 1.2.1 — 2026-11-06

- Keep compatible auction prices and history together when the game changes reporting hosts.
- Preserve access to existing ledger, watchlist and vendor profiles.

## 1.2.0 — 2026-10-20

- Add market opportunities, watchlists, crafting quotes and service charges.
- Add the personal ledger, activity reports, transaction editing and CSV exports.
- Use observed vendor purchase costs in crafting calculations.

## 1.1.0 — 2026-10-11

- Add crafting profit analysis, recipe rankings and daily price history.
- Improve scan controls, profession integration and public tooltip prices in combat.

## 1.0.0 — 2026-10-04

- Release full AH scans, saved tooltip prices, stack totals and disenchant estimates.
