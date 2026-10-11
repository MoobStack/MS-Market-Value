# Architecture

`1.1.0-beta / 2026-10-11-beta001` · Test revision 1 · Saved-data schema 1

## Runtime

The three identical TOCs load 13 Lua files. Bootstrap creates the addon namespace, followed by the bundled libraries, utilities/database, DE data and valuation, crafting analysis, scanner, tooltips, both UI modules, and event wiring. Original code uses the per-addon namespace; `MSMarketValue` and the TOC's `MSMarketValueDB` are its public globals. Blizzard functions are not replaced.

| Module | Responsibility |
|---|---|
| `Core/Util.lua` | Public-value guards, item/suffix and market keys, money and age formatting |
| `Core/Database.lua` | Schema-1 initialization, atomic completed snapshots, price lookup and settings |
| `Core/Valuation.lua`, `Data/Disenchant.lua` | Native metadata and labeled Classic DE estimates |
| `Crafting/Analysis.lua` | Native schematic/selection adapter, costs, quotes and batched recipe ranking |
| `Auction/Scanner.lua` | One replication request, bounded processing, retry queue, pause/resume |
| `Integrations/Tooltips.lua` | Public item decoration, verified stack quantities and duplicate prevention |
| `UI/Window.lua`, `UI/Crafting.lua` | Native scan/settings/diagnostics and profession analysis windows |
| `Core/Events.lua` | Initialization, native events, update budgets and slash commands |

LibStub minor 2 and LibAHTab minor 5 retain their pinned bytes, licenses and provenance. LibAHTab coordinates addon tabs without changing Blizzard's tab indices.

## Scanning

A new request requires initialized data, Interface 16001, a supported API, an open auctioneer, no combat, server readiness, an available market key, and an expired persisted request interval. It records the 15-minute cooldown before sending one `C_AuctionHouse.ReplicateItems` request.

The response starts PROCESSING over zero-based rows. Each 0.05-second tick handles at most 100 rows or approximately four milliseconds. Rows lacking item metadata enter RESOLVING, with one native load request per unresolved item ID. Retries preserve accepted rows and normally wait half a second between passes.

Pause stores the preceding phase and leaves work, cursor, pending queue, retry cursor, partially completed retry pass, and load-request set intact. It never writes partial prices. Combat, auction closure, a 120-second response timeout and a 45-second item-data timeout pause. A response received while paused can stage rows without committing them.

Resume validates the current market and existing readable buffer count, restores the phase, and gives waiting/resolving work a fresh timeout budget. It calls no replication request and changes no cooldown. A partially accepted retry pass continues at its existing cursor to avoid counting rows twice.

Changed counts, inaccessible row data, a changed market, or an observed competing replication request discard staged work. The secure request observer covers paused work too. The API has no generation token; request observation and count checks remain the boundary. Incomplete buffers are session-only and do not survive reload/logout.

Commit verifies row totals and the market key before replacing the completed snapshot in one assignment. An explicit completed empty response is valid. Sold and bid-only rows are accounted for but do not contribute buyouts.

## Crafting

The adapter reads the visible `ProfessionsFrame.CraftingPage.SchematicForm`, native recipe info, schematic and output data. It uses learned recipe IDs from the full catalog where available, otherwise a labeled filtered catalog. It never modifies profession filters or the native transaction.

Fixed required reagents come from schematics. Public native transaction allocations choose required alternatives and optional materials for the selected recipe; copied item/quantity/slot fields are validated before valuation. Currency and variable quantity costs, unresolved choices, salvage and recrafting remain unavailable. Native output quantity ranges produce conservative minimum and maximum gross returns. Non-item services retain material quotes without an auction sale estimate.

Catalog valuation runs in batches of 20 recipes with a four-millisecond budget on 0.25-second ticks while the profession is open. Price replacement, profession/list events and item-data events invalidate it. Selected recipe values follow the native form on those ticks. Ranking caches sorted fully priced positive results by profit or return; minimum yield determines order. Selecting a rank row calls native `OpenRecipe`, never a crafting action.

## Tooltips and UI

`TooltipDataProcessor` decorates only registered public item tooltips. Item IDs and quantity contexts are checked before use. GUID/location or matching bag/equipment context can supply an actual stack count; unknown contexts show each-only values. Values multiply before display rounding.

Decoration reads saved prices during combat. Unreadable item data is not inspected. Native getter-backed primary tooltip rebuilds remain outside combat; comparison rebuilds remain owned by Blizzard. A reentrancy guard and recorded line count prevent recursive refresh and duplicate blocks.

Scan/settings controls use native inset and portrait templates. Their controls move between the AH tab and manual window. The separate draggable crafting portrait has Selected recipe and Profitable recipes views, scrollable materials, and a copyable quote. Closing it suppresses automatic reopening until requested or a new profession session. Combat hides addon controls while price decoration remains available.

## Saved data and builds

Schema 1 retains `markets`, settings, exclusions, window position and `cooldownUntil`. This beta adds only `settings.quoteMarkup`, an integer 0–1000 defaulting to zero. Completed price records keep unit minimum, listed units and auction count; personal auction rows and sellers are not saved. Existing schema-1 snapshots remain usable.

Known Forever markets use region/ruleset/faction keys; host suffixes do not split a detected ruleset. Unknown aliases remain isolated and old caches are not promoted automatically. History is not yet stored; its implementation belongs to the next test revision.

The testing version and build remain fixed. `TEST_REVISION` and the matching build.json/TOC fields advance for each immutable test tag. Packaging requires a clean tagged checkout and verifies runtime/source/tag parity. Lua 5.1 fixtures exercise behavior; live UI, buffer retention and client disk persistence require native checks.
