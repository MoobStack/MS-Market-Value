# Using MS Market Value

`1.2.0-beta / 2026-10-20-beta001` · Test revision 7

## Crafting

Open a profession, select a learned recipe, and click **Show profits** beside the profession close button. It remains available with auto-open disabled, including before a recipe is selected. The same button becomes **Hide profits**. `/msmv craft` also opens the window. Closing it keeps it closed during that profession session.

**Selected recipe** follows recipe and reagent changes. Vendor materials use the player’s observed purchase cost; other owned materials use their market value; required tools are not purchased afresh for each craft.

| Value | Calculation |
|---|---|
| Materials / craft | Required quantities × vendor purchase cost or latest AH unit buyout |
| Cost / item | Material cost divided by output quantity |
| Sale after AH cut | Unit output buyout × output quantity, less the configured AH cut; rounded down |
| Net profit / craft | Sale after AH cut minus material cost |
| Net return on cost | Net profit divided by material cost × 100 |
| Item quote | Material cost × (1 + markup percentage / 100), divided by fixed output count |

With 4g of materials, a 5g output and a 5% AH cut, net profit is **75s / 18.75%**. Break-even is **4g 21s 06c** per item for a one-item craft. Deposits, expired listings and unsold stock are excluded. An asking price does not guarantee a sale.

The crafting window uses aligned material columns: **Reagent**, **Qty**, **Source** and **Total**. Sources distinguish AH lows, vendor purchase costs and supplies that need a vendor visit. Hover a material for its tooltip.

**Recipe list** starts with fully priced recipes having positive net profit. Click **Show all recipes** to include losses, break-even recipes and unavailable estimates; click **Profitable only** to switch back. The choice is saved. Known values sort first, then unavailable values by recipe name. **Return %** cannot rank a zero-material-cost recipe by percentage. Search by recipe name, then click a row to select it and read its details. Hover for the full name and valuation reason. Search matches plain text without changing native profession filters; it clears when changing professions. It reuses the published valuations.

Variable outputs show quantity and value ranges; ranking uses minimum yield. The list keeps its last complete results during a refresh. A filtered native-catalog fallback is labeled and leaves the profession's filters alone.

The selected recipe uses readable optional/alternative allocations. The catalog uses fixed required reagents with no optional extras. Missing material prices prevent full cost, profit and quote; missing output prices still allow a material quote. Services such as direct enchants show **Materials / service** and **Quote / service**, with the auction-only fields hidden. In the list, **Net / Quote** shows a service's numeric quote; its return column says **Service**. The status counts usable service quotes separately from recipes needing price data. Customer-material quotes can remain available when material prices are missing. Unresolved choices, currencies, variable material quantities, salvage and recrafting remain unavailable. Quality-dependent outputs need selection.

## Vendor materials and market opportunities

Visit a supplies vendor once to learn your actual purchase prices, including current discounts and bundle quantities. Normal unlimited-stock, gold-only items use those costs in recipes, rankings and quotes. Material rows say **vendor** or **visit supplier**. Prices are per character and market, expire after seven days, and need refreshing after a detected reputation-tier change. Unseen known supplies remain unavailable rather than using marked-up AH prices. [Vendor costs](docs/VENDOR-COSTS.md) covers the details.

At an auctioneer, **MS Opportunities** appears immediately before **MS Market Value**. Resale, Rising, Falling and All signals use completed scans already stored by the addon. The default requires three earlier priced days per item. Same-day scans do not add days. Resale applies the minimum price drop as well as both profit targets. Enter minimum profit in gold: `0.25` is 25s; up to four decimal places are accepted. A price move of `0` disables the resale drop filter. Left-click a row to open its native live listings; right-click for details. Results exclude stale scans and keep matching suffix series separate. [Market opportunities](docs/MARKET-OPPORTUNITIES.md) explains the filters and calculations.

## Quotes

Set whole-number **Markup** from 0 to 1000 percent and click **Apply** or press Enter. The default is zero. Under **Pricing**, service quotes also support **Labor per service (g)**, **Minimum service quote (g)** and **Customer supplies materials**. These settings apply to services across professions. Your materials use `max(minimum, materials × (1 + markup / 100) + labor)`. Customer-material service quotes use `max(minimum, labor)`. Service quotes round up to a whole copper; ordinary item quotes keep their existing output handling. A service quote reads `Enchant Chest - Lesser Absorption - 1g 16s 63c ea`.

The recipe name uses the native profession-book link when available. **Insert in chat** opens a draft; choose the channel and send it yourself. Ctrl+C copies the field. Fixed multi-item outputs quote per item; variable or unknown output uses **per craft**. Below the quote, **Record commission** has optional **Price / ea (g)**, **Total tip (g)** and **Quantity** fields. Price is per item/application, or per craft for variable/unknown output. Blank price uses the displayed quote. Quantity defaults to 1 and tip to 0. **Record sale** immediately records that payment as a commission; it does not open a draft. The tip is added once, not multiplied by quantity. Use it for completed direct player sales/services; AH sales are recorded from invoices.

Own-material commissions save the current material cost as an estimate; customer-material services record zero own material cost. Missing material cost stays unknown. Enter actual cost in the ledger to replace an estimate. Quote, tip and quantity fields reset after a successful entry.

## Watchlists and ledger

Open `/msmv` anywhere and click **Ledger** or **Watchlists**. The direct commands `/msmv ledger` and `/msmv watch` also work outside the AH. Both tools have a **Settings** button to return. The native Buy item header has a **Watch item** button that fills editable targets and preserves an existing watch’s settings.

The ledger opens on **Period report**. Income, spending and cash flow appear first, followed by AH sales/purchases, vendor sales/purchases, commissions and tips received/given. Recorded-cost profit/loss and estimated craft profit/loss have separate cards; sales needing a cost are counted rather than given a profit. Click an activity total to see its transactions.

**Transactions** has eight visible filters: All, AH purchases, AH sales, vendor purchases, vendor sales, commissions, tips received and tips given. Each click applies immediately; periodic refresh keeps the active panel visible. The date controls apply across both views: Today, 7 days, 30 days, All retained or inclusive custom local dates. The period report always includes all types. CSV copies all period records from the report, or just the selected type from Transactions. **New entry** and row edits open a separate window with a **Type** dropdown. **Ledger settings** holds independent AH, vendor and trade-tip tracking plus 1–365 local-calendar-day retention. CSV includes local time and UTC; stored timestamps and market-history UTC days are unchanged.

Gold exchanged in a completed trade starts as **Tip received** or **Tip given**. The game does not identify its purpose. Reclassify a craft payment as Commission and enter its cost; avoid adding the same payment again with Record sale. Incoming trade cost is unknown by default; use 0 for a pure tip. See [money tools](docs/ECONOMY-TOOLS.md) for calculations and tracking limits.

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

`MSMarketValueDB` keeps current snapshots, compact daily history, vendor observations, watchlists, this character’s ledger, settings, exclusions, window position and cooldown. Use normal logout, exit or `/reload` to let WoW save it. Back up `WTF/Account/<account>/SavedVariables/MSMarketValueDB.lua` and its `.bak` with WoW closed. Code archives do not include personal data.

Copy `/msmv diagnostics` when reporting a problem. It identifies the version/build and test revision, vendor observations, market analysis counts, history dates/retention, crafting preferences, toggle visibility/header levels, scan progress, catalog build/publication counts, transaction observers, queued confirmations and Buy-page watch buttons. Include the profession/recipe, exact error and a screenshot for layout issues. For resume, capture before/after diagnostics; a complete local resume must keep the request count unchanged. Follow [LIVE-TEST-CHECKLIST.md](LIVE-TEST-CHECKLIST.md).
