# Using MS Market Value

`1.1.0-beta / 2026-10-11-beta001` · Test revision **2**

## Crafting costs and profit

Open a profession and select a learned recipe. **Selected recipe** shows the cost of materials for one craft, cost per output item, total sale value, gross profit or loss, and percentage return on material cost. The window follows recipe and reagent selection changes while open. Use the profession's **MS Market Value** button or `/msmv craft` to reopen it.

Material quantities come from the native recipe schematic. Prices come from the latest completed scan for the current market. Materials already in your bags have the same market cost as materials you buy. Required tools are not purchased afresh for each craft.

| Value | Calculation |
|---|---|
| Materials / craft | Sum of required quantities × unit material buyouts |
| Cost / item | Material cost divided by output quantity |
| Sale / craft | Unit output buyout × output quantity |
| Gross profit / craft | Sale value minus material cost |
| Return on cost | Gross profit divided by material cost × 100 |
| Quote | Material cost × (1 + markup percentage / 100) |

For example, materials costing 4g and an output listed at 5g give a 1g gross profit and **+25%** return. A 3g output gives **-1g** and **-25%**. These values are before auction fees and listing costs.

Recipes producing a range of quantities show the corresponding cost and profit ranges. **Profitable recipes** ranks by the minimum output. Choose **Profit / craft** or **Return %**, then click a row to select that recipe through the native profession UI. The list includes only positive, fully priced estimates in the open profession. It keeps the last complete list visible during a refresh and replaces it once; unrelated item-data events do not restart it. If the full native catalog is unavailable, it uses and labels the current profession filters without changing them.

The adapter uses native recipe data across professions, including Cooking. Direct enchants and other services without an auctionable result show their material cost and quote; there is no invented output sale price. Select alternative reagents completely before pricing them. The selected recipe includes readable optional reagent allocations. The catalog uses fixed required materials with no optional extras. Quality-dependent outputs need selection before they can be valued. Currency costs, variable reagent quantities, salvage and recrafting are left unavailable in this test revision.

A missing material price makes full cost, profit and quote unavailable. The materials list identifies missing prices. A missing output price still allows a quote when all material prices are known. The scan's age and stale status are shown above the recipe tabs.

## Craft quotes

Enter a whole-number **Markup** from 0 to 1000 percent and click **Apply** or press Enter. The default is zero. Quotes use full material cost plus markup.

A direct enchant reads `Enchant Chest - Lesser Absorption - 1g 16s 63c ea`. The recipe name uses the same native link as shift-clicking the profession book, when available. Click **Insert in chat** to open a draft with the link intact; choose the channel and send it yourself. The quote field also supports Ctrl+C.

For a fixed multi-item output, **ea** divides the craft quote by the number produced. A variable or unknown output uses **per craft**, since it has no single per-item price. Missing native links fall back to the recipe name.

The addon does not send the quote or craft anything automatically. Customer-supplied materials and a separate labor fee are not modeled in this revision; adjust those in your agreement with the customer.

## Full scans and interruptions

At an open auctioneer, select **MS Market Value** and click **Scan entire AH**. One full-snapshot request reads every returned auction row in small batches. The previous complete snapshot remains usable until the new scan finishes.

| State | Meaning |
|---|---|
| WAITING | The server response has not arrived |
| PROCESSING | Copying auction rows locally and reading prices |
| RESOLVING | Waiting for missing auction price fields |
| PAUSED | Progress retained; use Resume scan |
| COMPLETE | All rows accounted for and saved prices replaced |
| CANCELLED | Incomplete work explicitly discarded |
| FAILED | Invalid data, a changed market/buffer, or a competing request stopped the scan |

**Pause scan**, `/msmv pause`, and `/msmv stop` retain progress. Pause stops pricing and saving; unread rows continue copying while the AH is open. Combat, auction closure and data timeouts also pause.

Keep the AH open until **Local copy** says **complete**. Then it can be closed and reopened safely. Outside combat at an auctioneer, **Resume scan** or `/msmv resume` uses that local copy without another request or a changed cooldown. A response received while paused stays staged until Resume.

If the native buffer disappears before copying finishes, progress remains PAUSED. Retry if the original buffer returns. If it does not, **Restart scan** becomes available after the cooldown; clicking it starts a fresh snapshot without mixing partial data. `/msmv restart` offers the same operation. The original **15-minute minimum interval** and server limits still apply.

A changed market, incompatible buffer, restricted data or a competing request during an incomplete copy prevents unsafe merging. A complete local copy is independent of later native buffer changes. `/msmv discard` abandons unfinished work. Reloading or quitting also ends it; completed prices and settings remain.

Only a fully processed response replaces prices. An explicit completed empty response clears that market's listings. Missing or partial responses do not. Bid-only and sold rows do not supply buyout prices.

## Item tooltips

The price block shows **Vendor sell**, **AH low**, and applicable **DE expected** values. A stack with a public, verified quantity shows **Each / Stack (N)**. Generic links and unavailable quantity contexts show **Each**. Totals multiply the original unit price before display rounding.

Prices remain available in combat on supported public item tooltips. Restricted item identifiers cannot be valued; unavailable stack quantities fall back to each-item prices. Native primary-tooltip rebuilds remain deferred until combat ends. Comparison tooltip rebuilds remain under Blizzard's control.

**AH low** is the lowest observed unit buyout, not a confirmed sale. A matching signed random suffix uses its own price; a fallback is labeled **item-wide**. Stale prices remain visible and dated. **Scan required**, **Not listed in scan**, and **No buyout in scan** describe missing auction values.

A blank line separates price values from the per-item disenchant material ranges and chances. DE expected value sums probability-weighted quantities at market prices. Every possible material needs a price; a known subtotal is labeled separately when the full estimate is unavailable. The Classic reference model remains unverified for Forever. See [docs/DISENCHANT-MODEL.md](docs/DISENCHANT-MODEL.md).

## Settings and saved data

The AH tab and `/msmv` settings window control vendor, AH, DE, material and age display; stale age accepts 1–168 hours. Item-ID exclusions can suppress and restore DE estimates. Craft quote markup is saved account-wide.

`MSMarketValueDB` retains settings, exclusions, cooldown, window position and one completed snapshot per market. Known Forever rulesets use region/ruleset/faction keys. Reporting-host numbers share a detected ruleset cache; different rulesets or unqualified factions do not. Older realm caches remain untouched.

Use a normal logout, exit or `/reload` to let WoW write completed prices and settings. Back up `WTF/Account/<account>/SavedVariables/MSMarketValueDB.lua` and its `.bak` while the client is closed. Code archives do not contain personal prices. A future saved-data schema is preserved and disables this build rather than being overwritten.

## Reporting a problem

Open `/msmv diagnostics` and copy the text. Include the recipe name/ID, profession, selected reagent choices, scan age, exact Lua error, and a screenshot if the layout is wrong. Diagnostics identify **Test revision: 2** and show local-copy progress, resume phase, recipe-link availability, and catalog build/publication counts.

For a pause problem, capture diagnostics before pausing and after resuming. Resuming a complete local copy must leave the request count unchanged. A fresh restart after a lost incomplete buffer adds one request. For crafting, compare native quantities and individual material/output AH prices with the displayed totals.

Price history is the next feature in this beta. It is not collected by test revision 2.
