# Changelog

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
