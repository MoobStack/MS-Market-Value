# Changelog

## 1.3.1-beta — Test revision 6 · 2026-11-17

- Enlarge the Sell-page arrow buttons from 18×16 to 28×24 each. Use red game-style panel buttons and clearer native AH arrow icons.
- Center the pair beside copper and place the native price warning below the field so the wider controls fit. Keep one-copper steps, rollover and native total updates.
- Retain watchlist search as a filter for items already watched. Add a tooltip explaining its scope and point users to the Buy page for new items.

See the [test notes](RELEASE-NOTES-v1.3.1-beta-test6.md) for appearance and price-entry checks.

## 1.3.1-beta — Test revision 5 · 2026-11-17

- Replace watchlist pages with ten scrolling rows, name search, a target-only filter and clickable sort headings. Put target status first by default and show estimated net profit alongside return.
- Use rarity colors for item names and a separate target-met marker/highlight for buying signals. Add a passive target count to the Watchlists button.
- Open the native Buy page on left-click; use right-click or Edit for a separate target dialog. Remove visible item IDs and accept item links or items added from Buy/Opportunities.
- Give the watchlist its own settings. Add quiet grouped reviews after scans or AH entry, with optional chat summaries off by default.
- Remember reviewed matches across reloads and unchanged scans. Alert again for a new match or lower matched price; defer reviews during combat, selling, purchase confirmation, typing or editing.
- Keep existing watches, thresholds and exact-modifier choices. Refresh late names/rarity without restarting price analysis, and keep the 200-watch limit.

See the [test notes](RELEASE-NOTES-v1.3.1-beta-test5.md) for the new layout and in-game alert checks.

## 1.3.1-beta — Test revision 4 · 2026-11-17

- Add stacked up/down arrows beside the copper field on the native AH Sell page. Each click changes the primary unit/buyout price by one copper.
- Handle silver/gold rollover, stop at zero and respect the gold field's limit. Keep native quantity, totals, validation and keyboard editing.
- Use the game's arrow textures, retain the native price warning and reuse controls when the AH reopens. Report their installation in diagnostics.

See the [test notes](RELEASE-NOTES-v1.3.1-beta-test4.md) for the Sell-page checks and the latest market/farming diagnostics.

## 1.3.1-beta — Test revision 3 · 2026-11-17

- Preserve exact-modifier observations when a later scan on the same UTC day no longer lists them. Keep current listings fresh and never carry samples across dates.
- Replace blank missing-baseline net values with exact-history progress; show priced UTC dates in row details and tooltips.
- Add scan-date, compatible-history and per-variant coverage diagnostics with sample keys and daily prices. Keep signal thresholds and existing history unchanged.
- Recover stale quest/transaction-window state so missing close events cannot keep rejecting or misclassifying later farming receipts.
- Preserve quest echo deduplication, vendor/mail/trade exclusions, manual/death pause and quest-free peaks. Report money exclusion reasons.

See the [test notes](RELEASE-NOTES-v1.3.1-beta-test3.md) for the November 17 coverage explanation and in-game checks.

## 1.3.1-beta — Test revision 2 · 2026-11-17

- Add a 0–50 saved-session limit and confirmed deletion of individual saves. Limits and records stay separate by character and market.
- Retain complete item breakdowns and recent receipts in new saves while preserving older summaries.
- Expand the session item area, add quantity/unit/total columns and replace page buttons with native scrolling.
- Replace crafting recipe pagination with an eleven-row scrolling list; preserve search, sorting, filters, hover details and recipe selection.
- Start timing idle at login until manual resume, combat or received loot. Quest rewards alone do not resume an idle timer.
- Add optional death pause, enabled by default. Exclude death/ghost time and wait for a trigger after resurrection; keep manual pauses paused.

See the [test notes](RELEASE-NOTES-v1.3.1-beta-test2.md) for in-game checks.

## 1.3.1-beta — Test revision 1 · 2026-11-16

- Include reliably identified empty corpses in personal drop-rate denominators without counting reopened bodies twice.
- Replace session cycling with a dated session menu and a direct Current session button.
- Default quest rewards to session totals only, with optional hourly inclusion. Five-minute peaks always exclude quest gold and items.
- Prevent generic loot messages and dedicated quest events from counting the same reward twice, including delayed event order.
- Exclude vendor and buyback receipts from farming; sale proceeds stay separate in the ledger.
- Prevent corpse and skinning drop sections from stacking outside the tooltip during looting.
- Keep totals and observations on upgrade, but restart recent/peak coverage and hide unverifiable older saved rates.

This is a test build. See the [test notes](RELEASE-NOTES-v1.3.1-beta-test1.md) for in-game checks.

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
