# Architecture

Test **1.3.0-beta** · Interface **16001** · Saved-data schema **1**

## Modules

The three identical TOCs load 26 Lua files. Bootstrap creates the addon namespace, then pinned libraries, data/services, the scanner, tooltip integration, UI and event wiring. Original code uses the addon namespace; Blizzard functions are not replaced.

| Module | Responsibility |
|---|---|
| `Core/Util.lua`, `Database.lua` | Public-value guards, item/market keys, settings and atomic snapshot replacement |
| `Core/Vendor.lua`, `History.lua` | Player vendor prices and compact daily market history |
| `Data/Disenchant.lua`, `Core/Valuation.lua` | Labeled Classic DE model and saved-price valuation |
| `Crafting/Analysis.lua` | Native recipe adapter, costs, quotes and batched rankings |
| `Market/Analysis.lua`, `Core/Watchlist.lua` | History comparisons, bounded rankings, saved targets and alerts |
| `Core/Drops.lua`, `Farming.lua`, `Data/LootReference.lua` | Capped personal loot counters, acquired-value sessions and optional reference queries |
| `Core/Ledger.lua`, `Transactions.lua`, `Cash.lua` | Scoped records, reports, confirmed transactions, daily loot and expense matching |
| `Auction/Scanner.lua`, `Integrations/Tooltips.lua` | Full AH copying/processing and guarded tooltip decoration |
| `UI/*.lua`, `Core/Events.lua` | Native frames, commands, event routing and update budgets |

LibStub minor 2 and LibAHTab minor 5 retain pinned bytes and notices. The shared registry coordinates addon tabs without extending native tab arrays.

## Processing

A new full scan requires an auctioneer, supported APIs, a market key, no combat and an expired persisted cooldown. One replication request starts the 15-minute interval. Copying handles up to 1,000 rows per frame; pricing handles up to 100 per 0.05-second tick, with an approximate four-millisecond budget. Only complete row accounting can replace saved prices. Partial results never merge into a fresh scan.

Pause keeps staging and retry progress. Copying can continue at the AH outside combat. After the local copy completes, resume no longer depends on the native buffer. Before that, count/anchor checks and competing-request observation guard the buffer; the API exposes no generation token. Reload/logout discards unfinished work.

Recipe catalogs run in batches of 20 on 0.25-second ticks while a profession is open. A complete staged catalog publishes atomically; unchanged catalog events reuse it. Selected recipes include readable native allocations. Ranking, search and summaries cache by source and pricing settings. Unknown material shapes stay unavailable; minimum yield drives variable-output ranking.

Market analysis runs only while visible. Each frame handles up to 500 entries with a four-millisecond target. It indexes exact variant series and retains at most 500 results. Watch checks handle up to 20 targets per step and publish together. Both reuse saved prices; neither sends auction queries. A player click delegates live listing navigation to the native Buy UI.

Tooltip callbacks decorate accessible public item data, including during combat. Only verified quantity contexts produce stack totals. Primary-tooltip rebuilds wait until combat ends; comparison rebuilds remain native-owned.

## Saved data

`MSMarketValueDB` retains current snapshots, settings, exclusions, cooldown and optional schema-1 history/vendor/watch/ledger roots. Known Forever markets use region/ruleset/faction keys; unknown aliases stay isolated.

- For compatible legacy PvP hosts, a session view selects the newest snapshot and the newest record per UTC day. It keeps the original records in place. Profile links reuse one prior profile without merging ledgers or rewriting receipt IDs.
- History stores the latest complete scan per UTC request day, retaining 1–30 days. Missing prices are skipped; current prices stay separate. Average lookups cache up to 4,096 keys.
- Vendor observations are per character/faction/market, valid for seven days and invalidated by detected reputation-tier changes. Known vendor supplies have no AH-cost fallback.
- Watchlists hold up to 200 targets per market.
- Ledgers hold 10,000 entries per character/market, with 1–365 local-day retention. Receipt/invoice indexes cap at 20,000; confirmed pending records cap at 100. Epoch timestamps remain unchanged. CSV includes both local and UTC time.

Invalid or unsupported roots are preserved and refused. Player SavedVariables never enter code packages.

## Transactions and UI

Secure post-observers capture public intent/context without invoking the action. AH buys require matching success; completed mailbox invoices backfill buys and sales. Invoice signature/expiry matching handles visible multiplicity but cannot resolve every identical replacement. Vendor item values must explain bag and wallet changes.

Trades require captured final gold offers and a native completion message; closure alone does not count. Gold starts as tips. Commissions are explicit writes from the craft button or editor; own-material costs remain labeled estimates.

Loot parses dedicated localized money messages and updates one indexed row per local day. It does not infer loot from wallet increases. Pending loot merges by day without per-award receipts.

Expenses match native details to wallet deductions, or native repair-cost decreases to reconciled merchant changes. Session queues cap at 100 intents and 256 wallet deltas. Known actions settle before vendor reconciliation; unmatched outgoing changes can become Unclassified. Generic handling excludes auction escrow and player trades. These matching windows are policies, not a complete accounting API.

Reports and type/category/date views are cached. The active panel only changes visibility on navigation, preserving mouse clicks during refresh. Native dropdowns select types and multiple expense categories. Manual UI/editing remains outside combat; automatic saved-table writes can run in combat.

For calculations and limits, see the [user guide](DOCUMENTATION.md), [money tools](docs/ECONOMY-TOOLS.md) and [source notes](docs/RESEARCH.md).

## Farming and drops

Loot events feed per-character counters grouped by map/instance, source kind/ID and solo/party/raid context. A 2,048-source session ring prevents normal reopen duplicates; a capped 64-source, five-minute receipt index carries recent protection across reloads. Only verified native source GUIDs are attributed to creatures; ambiguous sources stay unassigned. Farming uses localized self-loot receipts and dedicated quest events, with a short queue to reconcile overlapping quest/chat receipts. Existing ledger tracking remains independent.

Optional source packs can call `MSMarketValue.LootReference.Register(label, query, verified)`. The query receives a source ID and kind (`loot`, `herbalism`, `mining` or `skinning`) and returns up to 200 `{id, rate, name?, questID?, samples?}` rows, with rate expressed as a percentage. Results cache for at most 64 sources. The optional offline importer builds a separate addon; no reference database is copied into player saved data.

Gathering casts and exposed loot-source GUIDs separate harvesting from corpse loot. Up to 128 spell-name decisions are cached. Visible object tooltips have a 0.25-second fallback check when typed callbacks are unavailable. The session keeps exact category counters and reuses cached valuations; HUD interpolation changes only the display.

Standalone portrait windows use separate 1,024-level bands for their native children. Focusing a window moves the complete band, including high-level title and border frames.

## Revision 3 details

Farming persists online inactivity and a separate automatic-pause flag. Updates stop exactly at the configured boundary; receipts resume an automatic pause without backfilling the idle gap. Manual pauses stay independent. Old sessions gain the two optional fields without clearing totals.

`Util.Coins` is for display; `Util.Money` remains plain for chat/clipboard/diagnostics. Opportunities caches each row’s native link/quality color. Quest-only filtering changes the displayed candidates, not saved hit counts.

Packed references use a source-to-string index with sorted item-ID deltas, integer hits, shared sample totals and optional quest metadata. No global reverse index or full-table expansion is built. The eight-source cache also caps at 4,096 decoded rows. One source may contain up to 4,096 rows; oversized sources are rejected instead of silently truncated. Only a few relevant missing names are requested, with a 128-ID index and a 20-per-10-second request cap.
