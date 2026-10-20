# Architecture

`1.2.0-beta / 2026-10-20-beta001` · Test revision 6 · Saved-data schema 1

## Runtime

The three identical TOCs load 21 Lua files. Bootstrap creates the addon namespace, followed by the bundled libraries, utilities/database/vendor/history, DE data and valuation, crafting analysis, market analysis, transaction observation, scanner, tooltips, four UI modules, and event wiring. Original code uses the per-addon namespace; `MSMarketValue` and the TOC's `MSMarketValueDB` are its public globals. Blizzard functions are not replaced.

| Module | Responsibility |
|---|---|
| `Core/Util.lua` | Public-value guards, item/suffix and market keys, money and age formatting |
| `Core/Database.lua` | Schema-1 initialization, atomic completed snapshots, price lookup and settings |
| `Core/Vendor.lua` | Per-player merchant purchase observations, bundle costs and discount invalidation |
| `Market/Analysis.lua`, `UI/Market.lua` | Bounded history analysis, stable top-200 rankings and the opportunities AH tab |
| `Core/Watchlist.lua`, `Core/Ledger.lua`, `UI/Economy.lua` | Saved target checks, scoped ledger, filtered reports and money-tools UI |
| `Core/Transactions.lua` | Secure post-observers, confirmed purchases, mailbox reconciliation and verified vendor trades |
| `Core/History.lua` | Compact daily unit lows, UTC retention, migration and cached averages |
| `Core/Valuation.lua`, `Data/Disenchant.lua` | Native metadata and labeled Classic DE estimates |
| `Crafting/Analysis.lua` | Native schematic/selection adapter, costs, quotes and batched recipe ranking |
| `Auction/Scanner.lua` | One replication request, bounded local copying/processing, retries and recovery |
| `Integrations/Tooltips.lua` | Public item decoration, verified stack quantities and duplicate prevention |
| `UI/Window.lua`, `UI/Crafting.lua` | Native scan/settings/diagnostics and profession analysis windows |
| `Core/Events.lua` | Initialization, native events, update budgets and slash commands |

LibStub minor 2 and LibAHTab minor 5 retain their pinned bytes, licenses and provenance. LibAHTab coordinates addon tabs without changing Blizzard's tab indices.

## Scanning

A new request requires initialized data, Interface 16001, a supported API, an open auctioneer, no combat, server readiness, an available market key, and an expired persisted request interval. It records the 15-minute cooldown before sending one `C_AuctionHouse.ReplicateItems` request.

The response starts PROCESSING over zero-based rows. Local copying runs every frame with a maximum of 1,000 rows or approximately four milliseconds. Pricing runs on 0.05-second ticks, at most 100 rows or four milliseconds. A pricing tick may also advance copying. Only public validated item ID, quantity, buyout, sale status and an optional link are retained; no seller fields are copied. Aggregated rows release their temporary copy.

The native allInfo flag includes cosmetic item readiness. Valid public pricing fields can be copied without waiting for names or textures. Missing price fields receive one item-load request per ID and bounded retries. Accepted rows are never counted twice.

Pause retains phase, staging, copy progress, accepted rows and retry cursors. It stops pricing/commit; copying continues while an auctioneer is open and combat is absent. Closure, combat and timeouts pause. A response while paused can stage/copy data without committing prices.

Once every row has been copied or aggregated, Resume uses only local data. It does not query native rows, send a request, or alter cooldown. A cleared native buffer before copying finishes leaves work paused. A returning buffer must match its count and retained anchor row/link. If still unavailable after the cooldown, a user-requested Resume/Restart can start a fresh request, replacing incomplete staging without merging it into new data.

Changed markets, incompatible counts/anchors, restricted data and observed competing requests invalidate an unfinished native copy. A complete local copy survives later native changes and requests. The API exposes no generation token; count/anchor checks and request observation cannot prove an unobserved replacement is identical. Temporary copies remain session-only and end on reload/logout.

Commit verifies row totals and the market key before replacing the completed snapshot in one assignment. An explicit completed empty response is valid. Sold and bid-only rows are accounted for but do not contribute buyouts.

## Crafting

The adapter reads the visible `ProfessionsFrame.CraftingPage.SchematicForm`, native recipe info, schematic and output data. It uses learned recipe IDs from the full catalog where available, otherwise a labeled filtered catalog. It never modifies profession filters or the native transaction.

Fixed required reagents come from schematics. Public native transaction allocations choose required alternatives and optional materials for the selected recipe; copied item/quantity/slot fields are validated before valuation. Currency and variable quantity costs, unresolved choices, salvage and recrafting remain unavailable. Native output quantity ranges produce conservative minimum and maximum gross returns plus fee-adjusted net values. Non-item services retain material quotes without an auction sale estimate.

Catalog valuation runs in batches of 20 recipes with a four-millisecond budget on 0.25-second ticks while the profession is open. Staged rows publish atomically after the full catalog completes. The preceding list and source timestamp remain visible during a same-market refresh. Profession or market changes clear unrelated rows. Price replacement, profession/data-source changes and learned-recipe events rebuild it. Native list events check the sorted unique ID set at most once a second and rebuild only on a change. Item-data events update pending material names without repricing or sorting. Selected recipe values follow the native form on those ticks. Ranking caches net profit/return results separately for profitable-only and all-learned filters, with the configured AH cut in the cache identity. Gross valuation fields remain available internally. All mode includes negative, break-even and unavailable rows. Missing metrics sort last by name/ID; minimum yield determines order. Selecting a rank row calls native `OpenRecipe`, never a crafting action.

## Vendor costs and market analysis

`vendorBuy` has its own schema-1 root. Character profiles combine market key, native faction and player GUID. Each stores known unlimited-stock items, current reputation-tier signature and observed unit purchase prices/timestamps. Merchant capture accepts purchasable, unlimited, positive-gold items without extended costs; it divides the displayed bundle price by bundle quantity. Common reagent IDs identify vendor supplies without embedding unverified prices. Other unlimited items are learned from the merchant. Neither AH prices nor vendor sell values supply a purchase-cost fallback for known vendor materials.

A valid observation is usable for seven days. A changed readable reputation-tier signature clears prices while retaining known vendor identity. Merchant updates refresh timestamps; only new or changed prices invalidate recipe valuations. Vendor sell tooltips and AH snapshots retain their existing sources. No merchant purchase call is used.

Market analysis runs only while its AH pane is visible, outside combat. It uses the current completed snapshot plus earlier daily records, excluding the current scan's UTC day. History mutations advance a revision; unchanged refreshes reuse the published result. A job indexes variant series before comparing prices, omits mixed item-wide records when exact series exist, and never uses a suffix fallback. Known vendor items are excluded.

Each frame handles at most 500 entries with an approximately four-millisecond budget. A sorted bounded list retains at most 200 results. Analysis caps are 50,000 current price entries and 500,000 variant-index visits; a partial current scan is labeled, while an incomplete variant index produces no results and asks for a shorter lookback. Price lookup samples at most 30 days per entry. Source changes cancel unpublished work. Completed rows replace the list atomically; no auction request, purchase, posting or automatic craft is performed.

The lower quartile of earlier daily lows supplies a conservative resale baseline. Proceeds round down after the configured AH cut; purchase unit cost rounds up. Return uses net gain divided by purchase cost. Significant movement compares the latest low with the historical median. Resale requires a drop meeting that threshold in addition to both net-profit targets; zero disables its drop check. Rising/falling retain direction and exclude unchanged prices. With five earlier observations, a separate recent-versus-older three-point median provides context. Asking-price data cannot establish liquidity or a sale rate.

## Tooltips and UI

`TooltipDataProcessor` decorates only registered public item tooltips. Item IDs and quantity contexts are checked before use. GUID/location or matching bag/equipment context can supply an actual stack count; unknown contexts show each-only values. Values multiply before display rounding.

Decoration reads saved prices during combat. Unreadable item data is not inspected. Native getter-backed primary tooltip rebuilds remain outside combat; comparison rebuilds remain owned by Blizzard. A reentrancy guard and recorded line count prevent recursive refresh and duplicate blocks.

The opportunities pane groups profit and history filters in a native inset, with an aligned table, alternating row backgrounds, hover/selection highlights and a separate details area. Minimum profit is displayed as decimal gold and parsed into whole copper without floating rounding; its saved value is unchanged. Draft input survives refresh/focus changes, Escape restores the focused field, and unchanged Apply reuses analysis.

Only a row left-click can open live listings. Readable native item keys preserve suffixes and equipment level. The native frame selects the appropriate item/commodity pane and performs its own QueryItem; unavailable exact-key support falls back to the native name search. There are no scheduled lookups or purchase calls. Guards cover combat, closed/forbidden frames, stale/replaced results, unapplied inputs, incomplete local scan copying, throttling and rapid repeated clicks. Native filters remain in effect.

Scan/settings controls use native inset and portrait templates. Their controls move between the AH tab and manual window. The separate draggable crafting portrait has Selected recipe and Recipe list views, a Show all recipes / Profitable only filter, aligned scrollable material columns, and a copyable native-linked quote with a user-clicked chat-draft button. Recipe rows use native insets, alternating backgrounds and hover details. Service recipes display cost/quote instead of inapplicable auction-profit fields. Published counts distinguish priced recipes, services, other quote-only entries and missing data.

Recipe search filters the current cached ranking by case-insensitive plain text. It keeps one result cache keyed by ranked source, count and normalized query; an empty query reuses the ranking directly. A new published catalog or profession invalidates the view, and changing professions clears the search. Catalog summaries cache by published source/count and pricing settings. These controls do not revalue recipes, change native filters or request auctions. The selected view and list use net profit/return after the configurable AH cut. Proceeds round down per craft; break-even unit prices round up and are checked against the minimum cost-recovering proceeds. Deposits and expired listings are excluded from this estimate.

Service quotes compute material recovery plus markup and labor, subject to a minimum; customer-material mode uses labor/minimum alone. Numeric service quotes are calculated from current settings rather than a stale catalog quote. This permits charge-only quotes with missing material prices and avoids a native revaluation on pricing changes. Ordinary item quotes retain their existing behavior. Fixed-yield quotes divide by output count for ea; unknown/variable yields remain per craft. ChatFrameUtil.OpenChat is preferred, with the legacy opener as fallback. No chat send is called. The named title-bar toggle belongs to CraftingPage and anchors beside the native close button. It follows the highest actual level and strata of the page, border, portrait, title and close button; following the page alone left it below the native header. Hiding the page immediately hides both addon controls. Diagnostics report toggle visibility, strata and level, native header levels, and crafting-window state. Auto-open defaults to off and applies on a new profession session; manual closure stays respected during that session. Combat hides addon controls while price decoration remains available.

## Watchlists and ledger

Watchlists have a schema-1 market map capped at 200 targets per market. Numeric IDs use item-wide series; links use exact suffix series. Buy thresholds can work without history; net-return/profit thresholds reuse the market evaluator with prior days, conservative baseline and configured cut. At most 20 watches or roughly four milliseconds are processed per frame. Snapshot/history/criteria/fee changes cancel unpublished work. Results publish together, and alert timestamps persist per item/scan. Alerts are local chat messages, with no background AH request.

The ledger keeps schema-1 character/market profiles, up to 10,000 entries, 1–365 UTC retention and separate 20,000-entry receipt/invoice indexes. Existing rows and legacy expenses remain valid. Optional tips, commission costs and receipt fields are additive. Automatic writes change saved tables and can run in combat; manual edits and UI remain outside combat.

`Transactions.lua` observes native calls with `hooksecurefunc`; it does not replace or invoke transaction functions. A buyout intent captures selected quantity/price and commits only for its auction-ID completion. Commodities require the last server quote, matching confirmation arguments and success. Pending intents expire after 120 seconds. Persisted purchase receipts reconcile later invoices, including after reload or ledger deletion. Unknown native purchase context falls back to completed mailbox invoices.

A stable inbox read stages public completed buyer/seller fields in batches of 10, then commits in bounded batches. Mail-update generations and player scope cancel stale work. User collection hooks also capture a matching visible invoice group (up to 100 messages) before the background reader catches up. Signature/expiry matching recognises previous imports and simultaneous multiplicity. No durable mail ID is exposed: close identical replacements remain an acknowledged reconciliation limit. Native mail actions, bodies and counterparties are not invoked/read/stored. Mail backfills use first-recorded time, not an invented sale time.

Vendor observation takes a bag/wallet baseline at merchant open. Merchant actions mark it dirty; bag/money events wait for a short settling interval. Gold-only buy prices or item sell values must explain the item deltas and the exact wallet change. Unmatched data is rejected after three seconds and reported; no wallet-only inference is made. Normal/buyback prices remain separate. Closing the merchant allows the pending confirmation to settle. Idle tracking reads no bags or item metadata.

Commissions record immediately from a clicked craft sale: unit price × quantity plus one total tip. Fixed output uses per-item quote/cost; variable output uses per-craft values. Customer-material services have zero own material cost. Other material costs are saved estimates, separately reported until actual cost replaces them. Missing cost differs from zero. Income, spending, cash flow, known P/L and estimated craft P/L are separate; returned deposits are excluded.

The standalone `/msmv` settings window and AH settings tab both link to the same portable ledger. The ledger separates Period report, Transactions and Ledger settings; manual entry/editing uses a child portrait window. Report summaries always use all types for the selected UTC period. Transactions use one of six direct type filters, with legacy expenses reachable from the report/settings. CSV follows the active view: all period rows for reports, filtered rows for Transactions. Scope changes clear editor context, and combat hides both windows.

UTC/type filtering, summaries and CSV reuse the same cached row views. Record ordering uses a linear reverse for normal append order, with a sorted fallback for undo or out-of-order confirmations. Views/summaries cache by source and criteria. The auto-receipt key index uses constant-time lookup. Date ranges stay stable within the day. A full ledger keeps at most 100 confirmed live records in a validated saved queue, retries after space is freed and preserves their observation timestamps across reloads. Retention still applies; retained entries are never silently evicted.

## Daily history

Only successful completed snapshot commits call history recording. The request timestamp determines the UTC day (`floor(startedAt / 86400)`); the latest request replaces that day atomically, including removal of absent listings. The completed current snapshot is independent and history never fills current-price gaps. Empty completed scans retain an empty daily entry; paused/failed/partial scans do not write history.

Retention includes today plus the preceding N−1 days. Loading, rollover, recording and setting changes prune older/future entries across markets. Lowering retention deletes entries immediately; later increasing it cannot restore them. An incremental mean avoids oversized sums, gives each available daily low equal weight, and skips missing/invalid prices. A suffix average uses only matching days; item-wide fallback uses its own series. Tooltip totals multiply the fractional average before formatting.

Average caching is limited to 4,096 queried item/variant/market keys and invalidated by record, pruning or retention changes. Calendar lookups use at most 30 daily entries. Only numeric prices and request times are saved, without copies of auction rows or sellers.

## Saved data and builds

Schema 1 retains `markets`, settings, exclusions, window position and `cooldownUntil`. Version 1.1.0 adds `quoteMarkup` (0–1000, default 0), `historyDays` (1–30, default 30), `showHistory` (true), `craftAutoOpen` (false), and `showAllRecipes` (false) settings. Completed price records keep unit minimum, listed units and auction count; personal auction rows and sellers are not saved. Existing schema-1 snapshots remain usable.

Known Forever markets use region/ruleset/faction keys; host suffixes do not split a detected ruleset. Unknown aliases remain isolated and old caches are not promoted automatically. History has its own optional schema-1 root: `history = { schema = 1, markets = { [marketKey] = { [UTCday] = { startedAt, prices, variants } } } }`. Prices/variants contain only numeric unit lows. Initialization validates/prunes saved history, and first upgrade imports the latest existing complete snapshot per market once if it is in retention. An unsupported history root is preserved and leaves current pricing active.

The v1.2.0 testing line holds `1.2.0-beta / 2026-10-20-beta001` fixed and advances `testRevision` with immutable `v1.2.0-beta-testN` tags. Local main and `v1.1.0` retain the previous release. Prior tags remain immutable. Packaging requires a clean tagged checkout and verifies runtime/source/tag parity. Lua 5.1 fixtures exercise behavior; live UI, buffer retention and client disk persistence require native checks.
