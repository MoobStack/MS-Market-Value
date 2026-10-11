# Using MS Market Value

`1.1.0 / 2026-10-11-release001`

## Crafting

Open a profession, select a learned recipe, and click **Show profits** beside the profession close button. It remains available with auto-open disabled, including before a recipe is selected. The same button becomes **Hide profits**. `/msmv craft` also opens the window. Closing it keeps it closed during that profession session.

**Selected recipe** follows recipe and reagent changes. Owned materials use their market value; required tools are not purchased afresh for each craft.

| Value | Calculation |
|---|---|
| Materials / craft | Required quantities × latest unit material buyouts |
| Cost / item | Material cost divided by output quantity |
| Sale / craft | Unit output buyout × output quantity |
| Gross profit / craft | Sale value minus material cost |
| Return on cost | Gross profit divided by material cost × 100 |
| Quote | Material cost × (1 + markup percentage / 100) |

Materials costing 4g and an output listed at 5g give **+1g / +25%**. A 3g output gives **-1g / -25%**. Profit is before auction fees and listing costs. An asking price does not guarantee a sale.

**Recipe list** starts with positive, fully priced recipes. Click **Show all recipes** to include losses, break-even recipes and unavailable estimates; click **Profitable only** to switch back. The choice is saved. Known values sort first, then unavailable values by recipe name. **Return %** cannot rank a zero-material-cost recipe by percentage. Click a row to select it and read its details.

Variable outputs show quantity and value ranges; ranking uses minimum yield. The list keeps its last complete results during a refresh. A filtered native-catalog fallback is labeled and leaves the profession's filters alone.

The selected recipe uses readable optional/alternative allocations. The catalog uses fixed required reagents with no optional extras. Missing material prices prevent full cost, profit and quote; missing output prices still allow a material quote. Services such as direct enchants have quotes without invented auction profits. Unresolved choices, currencies, variable material quantities, salvage and recrafting remain unavailable. Quality-dependent outputs need selection.

## Quotes

Set whole-number **Markup** from 0 to 1000 percent and click **Apply** or press Enter. The default is zero. A service quote reads `Enchant Chest - Lesser Absorption - 1g 16s 63c ea`.

The recipe name uses the native profession-book link when available. **Insert in chat** opens a draft; choose the channel and send it yourself. Ctrl+C copies the field. Fixed multi-item outputs quote per item; variable or unknown output uses **per craft**. Customer-supplied materials and separate labor fees are not modeled.

## Price history

In `/msmv`, open **Crafting & history**, enter **1–30** in **Keep price history for**, then click **Apply** or press Enter. The default is **30 days**. The window shows how many daily scans are saved for the current market.

Each completed scan replaces its UTC day's entry. The day comes from the scan's request time, even if processing finishes after midnight. Retention includes today and the preceding days: 30 means today plus the previous 29 UTC days. Expired entries are removed on loading, date rollover, scan completion or a retention change.

**Historic avg (N days)** is the arithmetic mean of the available daily lowest unit buyouts. Each day has equal weight, regardless of auction count or the number of scans. Missing days and missing buyouts are skipped. One day can supply an average. For daily prices of 10g, no listing, and 14g, the average is 12g across two days.

The upgrade imports the latest existing completed scan once, if it falls within retention. Older scans were not stored by revisions 1 and 2 and cannot be reconstructed. Shortening retention removes older days immediately; increasing it cannot restore them. Current prices remain separate and can still be shown when their history expires.

Markets remain separate by region/ruleset/faction. Matching signed random suffixes use their own daily series; a history fallback is labeled **Item-wide**. Variant and item-wide samples are not mixed within an average. History records asking prices, not completed sales.

## Item tooltips and settings

The price block orders **Vendor sell**, **Historic avg** when available, **AH low** from the recent scan, then applicable **DE expected** values. Verified public stack quantities show **Each / Stack (N)**; generic links and unavailable quantity contexts show **Each**. Totals multiply before display rounding.

Public prices remain available in combat. Restricted identifiers cannot be valued. Native primary-tooltip rebuilds wait until combat ends; comparison rebuilds remain under Blizzard's control. No duplicate price block should appear.

**Tooltips** settings control vendor, history, AH, DE, material and age display. Disabling the average hides it without stopping collection. **Crafting & history** also contains **Auto-open crafting profits**, off by default. Enabling it opens the window on the next profession session; a manual close remains respected. **Price settings** sets stale age from 1–168 hours and manages item-ID DE exclusions.

AH low uses a matching random suffix or a labeled item-wide fallback. Stale prices remain visible and dated. Missing prices show Scan required, Not listed in scan, or No buyout in scan. A blank line separates prices from the Classic disenchant material reference, which remains unverified for Forever; see [docs/DISENCHANT-MODEL.md](docs/DISENCHANT-MODEL.md).

## Scans and recovery

At an open auctioneer, select **MS Market Value → Scan entire AH**. The previous completed prices and history remain usable until every new row is accounted for. Sold and bid-only rows do not supply buyouts; a completed empty response clears current listings and replaces that day's history.

**Pause scan** or `/msmv pause` stops pricing and saving. Copying continues while the AH is open outside combat. Closure, combat and timeouts also pause. Keep the AH open until **Local copy** is **complete**; then closing/reopening and Resume continue without a new request or altered cooldown.

If rows disappear before copying finishes, progress stays paused. Retry if the original buffer returns, or use **Restart scan** after the cooldown to request fresh data. The minimum interval remains 15 minutes. Partial data never merges into a fresh scan. Changed markets, incompatible buffers or competing requests stop an incomplete copy. Reload/logout and `/msmv discard` end incomplete work, while completed prices remain.

## Saved data and reports

`MSMarketValueDB` keeps current snapshots, compact daily history, settings, exclusions, window position and cooldown. Use normal logout, exit or `/reload` to let WoW save it. Back up `WTF/Account/<account>/SavedVariables/MSMarketValueDB.lua` and its `.bak` with WoW closed. Code archives do not include personal data.

Copy `/msmv diagnostics` when reporting a problem. It identifies the release version/build, history dates/retention, crafting preferences, toggle visibility/header levels, scan progress, and catalog build/publication counts. Include the profession/recipe, exact error and a screenshot for layout issues. For resume, capture before/after diagnostics; a complete local resume must keep the request count unchanged. Follow [LIVE-TEST-CHECKLIST.md](LIVE-TEST-CHECKLIST.md).
