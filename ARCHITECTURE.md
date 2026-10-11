# Architecture

`1.1.0-beta / 2026-10-11-beta001` · Test revision 2 · Saved-data schema 1

## Runtime

The three identical TOCs load 13 Lua files. Bootstrap creates the addon namespace, followed by the bundled libraries, utilities/database, DE data and valuation, crafting analysis, scanner, tooltips, both UI modules, and event wiring. Original code uses the per-addon namespace; `MSMarketValue` and the TOC's `MSMarketValueDB` are its public globals. Blizzard functions are not replaced.

| Module | Responsibility |
|---|---|
| `Core/Util.lua` | Public-value guards, item/suffix and market keys, money and age formatting |
| `Core/Database.lua` | Schema-1 initialization, atomic completed snapshots, price lookup and settings |
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

Fixed required reagents come from schematics. Public native transaction allocations choose required alternatives and optional materials for the selected recipe; copied item/quantity/slot fields are validated before valuation. Currency and variable quantity costs, unresolved choices, salvage and recrafting remain unavailable. Native output quantity ranges produce conservative minimum and maximum gross returns. Non-item services retain material quotes without an auction sale estimate.

Catalog valuation runs in batches of 20 recipes with a four-millisecond budget on 0.25-second ticks while the profession is open. Staged rows publish atomically after the full catalog completes. The preceding list and source timestamp remain visible during a same-market refresh. Profession or market changes clear unrelated rows. Price replacement, profession/data-source changes and learned-recipe events rebuild it. Native list events check the sorted unique ID set at most once a second and rebuild only on a change. Item-data events update pending material names without repricing or sorting. Selected recipe values follow the native form on those ticks. Ranking caches sorted fully priced positive results by profit or return; minimum yield determines order. Selecting a rank row calls native `OpenRecipe`, never a crafting action.

## Tooltips and UI

`TooltipDataProcessor` decorates only registered public item tooltips. Item IDs and quantity contexts are checked before use. GUID/location or matching bag/equipment context can supply an actual stack count; unknown contexts show each-only values. Values multiply before display rounding.

Decoration reads saved prices during combat. Unreadable item data is not inspected. Native getter-backed primary tooltip rebuilds remain outside combat; comparison rebuilds remain owned by Blizzard. A reentrancy guard and recorded line count prevent recursive refresh and duplicate blocks.

Scan/settings controls use native inset and portrait templates. Their controls move between the AH tab and manual window. The separate draggable crafting portrait has Selected recipe and Profitable recipes views, scrollable materials, and a copyable native-linked quote with a user-clicked chat-draft button. Fixed-yield quotes divide by output count for ea; unknown/variable yields remain per craft. ChatFrameUtil.OpenChat is preferred, with the legacy opener as fallback. No chat send is called. Closing it suppresses automatic reopening until requested or a new profession session. Combat hides addon controls while price decoration remains available.

## Saved data and builds

Schema 1 retains `markets`, settings, exclusions, window position and `cooldownUntil`. This beta adds only `settings.quoteMarkup`, an integer 0–1000 defaulting to zero. Completed price records keep unit minimum, listed units and auction count; personal auction rows and sellers are not saved. Existing schema-1 snapshots remain usable.

Known Forever markets use region/ruleset/faction keys; host suffixes do not split a detected ruleset. Unknown aliases remain isolated and old caches are not promoted automatically. History is not yet stored; its implementation belongs to the next test revision.

The testing version and build remain fixed. `TEST_REVISION` and the matching build.json/TOC fields advance for each immutable test tag. Packaging requires a clean tagged checkout and verifies runtime/source/tag parity. Lua 5.1 fixtures exercise behavior; live UI, buffer retention and client disk persistence require native checks.
