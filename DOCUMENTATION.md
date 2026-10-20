# User guide

MS Market Value **1.2.0** for WoW Forever. See the [README](README.md) for installation and a feature overview.

## Scans and tooltips

At an auctioneer, open **MS Market Value → Scan entire AH**. A new completed scan replaces current prices; partial or failed scans keep the previous snapshot. New full requests have a 15-minute minimum interval.

Pause/resume works within the current session. Keep the AH open until **Local copy** is complete; after that, closing/reopening it does not require another full request. If the server buffer disappears before copying finishes, retry or restart when the cooldown allows. Reload/logout ends unfinished work.

Tooltips show **Vendor sell**, **Historic avg**, **AH low**, then applicable **DE expected** values. Known quantities show each/stack totals. Public prices remain available in combat. Stale prices are dated; missing prices remain unavailable. Tooltip fields and item exclusions are configurable.

History keeps 1–30 UTC days, default 30. Each day uses its latest completed scan, dated by request time. The average gives each available priced day equal weight; missing days/listings are skipped. Current prices remain separate. Markets and exact random-suffix series stay isolated.

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

Use **Watch item** on the Buy page or **Watch selected** on Opportunities. Edit the price/return/profit targets, then save. Zero disables a target; every enabled target must pass. Alerts are local and evaluated after completed scans.

Open `/msmv ledger` anywhere outside combat. **Period report** covers all types for the selected local dates. **Transactions** filters by type; **Other** lets you combine expense categories. All includes every type and category. Click a row to edit it; use the Type dropdown to reclassify payments. CSV follows the active period/type/category filter.

**Ledger settings** has independent AH, vendor, trade-tip, loot and other-spending tracking. Retention is 1–365 local calendar days, default 90. Shortening it removes older records. Back up/export anything you need first. [Money tools](docs/ECONOMY-TOOLS.md) explains tracking, reports and limits.

## Commands and support

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
