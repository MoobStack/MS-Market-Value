# User guide

MS Market Value **1.3.0 beta** for WoW Forever. See the [README](README.md) for installation and a feature overview.

## Scans and tooltips

At an auctioneer, open **MS Market Value → Scan entire AH**. A new completed scan replaces current prices; partial or failed scans keep the previous snapshot. New full requests have a 15-minute minimum interval.

Pause/resume works within the current session. Keep the AH open until **Local copy** is complete; after that, closing/reopening it does not require another full request. If the server buffer disappears before copying finishes, retry or restart when the cooldown allows. Reload/logout ends unfinished work.

Tooltips show **Vendor sell**, **Historic avg**, **AH low**, then applicable **DE expected** values. Known quantities show each/stack totals. Public prices remain available in combat. Stale prices are dated; missing prices remain unavailable. Tooltip fields and item exclusions are configurable.

History keeps 1–30 UTC days, default 30. The number next to **Historic avg** is how many days had a price for that item. Each day uses the latest completed scan, dated by request time. Scanning twice on the same UTC day still counts as one day. **Crafting & history** shows the total saved days for the market.

## Crafting and quotes

Open a profession and click **Show profits**, or use `/msmv craft`. The button also closes the window. Auto-open is off by default and can be changed under **Crafting & history**.

Select a recipe to see its materials, cost, output value, net profit, return and break-even price. Vendor supplies use observed player purchase costs; other materials use their market replacement value, including materials you own. Visit a supplier when a vendor price is missing. Missing or unsupported recipe data does not become a zero cost.

The recipe list can show profitable recipes or all learned recipes. Search by name and sort by profit/return; select a row to open the native recipe. Minimum yield determines ranking for variable outputs. The last complete list stays visible during refresh.

With 4g of materials, a 5g sale and a 5% AH cut, estimated net profit is **75s**, or **18.75%**. Deposits and unsold stock are excluded.

Under **Pricing**, set the AH cut, material markup and service charges:

- Your materials: `max(minimum charge, materials × (1 + markup / 100) + labor)`.
- Customer materials: `max(minimum charge, labor)`.

Service recipes show quotes instead of auction-profit fields. Fixed-output item quotes are per item; variable/unknown outputs are per craft. The recipe name uses a native link when available. **Insert in chat** opens a draft for you to send.

Below the quote, **Record sale** adds a commission. Price is per unit; blank uses the quote. Quantity defaults to 1 and total tip to 0. Own-material costs are saved as estimates; customer-material services have zero own material cost. Enter actual cost later in the ledger when known.

## Opportunities, watchlists and ledger

**MS Opportunities** finds resale and price-movement signals using saved history. Minimum profit accepts decimal gold: `0.25` means 25s. Resale must meet the price-drop, return and profit filters. Left-click a result to open live listings; right-click for detail. See [market calculations](docs/MARKET-OPPORTUNITIES.md).

Modifier names and links come from the scan, including modern bonus-based variants. Each variant has its own prices and history. **All items** includes current prices without a movement estimate when history is missing. The scrolling list shows 12 rows; **Filters** expands the controls, and Apply collapses them again. Quantity filters use units, not listing counts; zero disables a limit. **Low buyout** is the cost of all units at that lowest price. Stock decline compares two completed scans and does not prove that items sold. Keyword search matches every word. Rescan after updating for precise modifier and quantity data. Older item-wide days are kept but cannot supply a specific modifier’s baseline.

Use **Watch item** on the Buy page or **Watch selected** on Opportunities. Edit the price/return/profit targets, then save. Zero disables a target; every enabled target must pass. Alerts are local and evaluated after completed scans.

Open `/msmv ledger` anywhere, including combat. **Period report** covers all types for the selected local dates. **Transactions** filters by type; **Other** lets you combine expense categories. All includes every type and category. Outside combat, click a row to edit it; use the Type dropdown to reclassify payments. CSV follows the active period/type/category filter.

**Ledger settings** has independent AH, vendor, trade-tip, loot and other-spending tracking. Retention is 1–365 local calendar days, default 90. Shortening it removes older records. Back up/export anything you need first. [Money tools](docs/ECONOMY-TOOLS.md) explains tracking, reports and limits.

## Commands and support

Use `/msmv farm` for the session report and settings. The centered display shows **Average** for the whole session and an optional **Session** total. Adjust its width, lock its position or show it only on hover. The report adds a recent 60-minute rate and a located five-minute peak with quests excluded.

Idle pause defaults to five minutes, adjustable from 5–60 or Off. Combat and your own loot resume it; the timer stays active during combat. Manual pauses stay paused. Use `/msmv drops` for reference/personal mode and resets. Reference data is the default; personal collection stays enabled in either mode. The [farming guide](docs/FARMING-AND-DROPS.md) explains counting and valuation.

The main window, ledger, farming report and diagnostics can open in combat. Scans, live searches and profession controls still wait until combat ends. **Opportunities → Filters → Rarity** offers six colored choices from Poor through Legendary; Apply saves the selection. Drop tooltip names use item-quality colors too. See [reference data](docs/REFERENCE-PACKS.md) for coverage and update instructions.

| Command | Action |
|---|---|
| `/msmv` | Open AH settings or the standalone window |
| `/msmv scan` | Start a scan or resume paused work |
| `/msmv pause` or `stop` | Pause incomplete work |
| `/msmv resume` | Resume at an auctioneer, outside combat |
| `/msmv restart` or `discard` | Start fresh when allowed, or discard unfinished work |
| `/msmv craft`, `market`, `watch`, `ledger` | Open the named tool; market needs an auctioneer |
| `/msmv status` or `diagnostics` | Show status or a copyable problem report |

Saved data is in `WTF/Account/<account>/SavedVariables/MSMarketValueDB.lua`. Close WoW before making backups. Code packages exclude player data. For rollback and known limits, see [Upgrade](UPGRADE.md) and [Compatibility](COMPATIBILITY.md).
