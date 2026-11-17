# MS Market Value 1.3.1

Released November 17, 2026 for WoW Forever 1.60.1 / Interface 16001.

## Farming and drops

- Choose saved sessions from a dated menu and return directly to the current session.
- Manage saves per character and market: keep 0–50 sessions, five by default, or delete one. Deletions and reductions that remove saves require confirmation.
- Scroll through session items and recent pickups, with quantity, unit value and total columns. New saves retain the full tracked item list and recent receipts; older summaries remain readable.
- Start the calculator idle at login. Optional death pause is enabled by default; combat, received loot or Resume restarts timing. Manual pauses stay paused.
- Keep quest rewards in the session total by default, with options to include them in hourly rates or stop recording new rewards. Peaks always exclude quest gold and items.
- Prevent duplicate quest gold/items and exclude vendor sales and buyback receipts from farming. Selling a previously counted item does not add its value again.
- Recover from missing quest, vendor, mail and trade close events so later farming receipts are classified correctly. Add diagnostics for ignored money and recovered windows.
- Count reliably identified empty corpses once when calculating personal drop rates. Reopening the same body does not add another sample.
- Prevent creature and skinning drop sections from stacking outside the tooltip. Custom sections stay hidden during looting and return on refresh.

## Watchlists

- Replace pages with scrolling, name search, a target-only filter and sortable columns. Show estimated net profit alongside return; keep target highlights separate from item-name rarity colors.
- Open the item's Buy page on left-click. Right-click or Edit changes targets in a separate dialog; add items from Buy, Opportunities or pasted/dragged links without visible item IDs.
- Add watchlist-specific settings and a passive target count. New matches or lower matched prices can open one grouped review after a scan or an AH visit; chat summaries are optional and off by default.
- Remember reviewed matches across reloads and unchanged scans. Rearm after a fresh scan shows an item outside its targets or no longer listed; defer reviews during combat, selling, purchases, typing or editing.
- Reuse visible rows and cached results for larger watchlists. Late item names and rarity updates no longer require another price analysis.

## Market, crafting and interface

- Preserve an exact modifier's earlier price when a later scan on the same UTC day no longer lists it. Keep current listings separate and never carry a sample into another date.
- Show missing-history progress and exact priced dates instead of unexplained blank estimates. Diagnostics now distinguish market-wide history from each modifier's usable earlier days.
- Replace crafting recipe pages with native scrolling while retaining search, sorting, profitability filters and recipe selection.
- Add stacked red arrows beside the Sell-page copper field. Each click adjusts unit price by one copper, with denomination rollover, price limits and native total updates.
- Add short help for unfamiliar buttons, filters and settings. **Addon interface tooltips** is enabled by default under Tooltips; switching it off hides control help and list hover details. Item-value and world-drop settings remain separate.

Prices, history, watches, targets, ledger entries, settings and personal observations carry forward. See [Updating](UPGRADE.md) for older farming-session details.
