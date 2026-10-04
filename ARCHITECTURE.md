# Architecture

Version `0.1.0-beta`, build `2026-10-04-beta001`; database schema 1.

## Runtime modules and load order

| File | Responsibility |
|---|---|
| `MSMarketValue/Bootstrap.lua` | Publisher identity, beta/build constants and public namespace |
| `Core/Util.lua` | Access checks, numeric validation, item/suffix keys, money and age formatting |
| `Core/Database.lua` | Saved data initialization, price accumulation, snapshot lookup and atomic replacement |
| `Data/Disenchant.lua` | Named reference material/outcome profiles; no executable third-party loot code |
| `Core/Valuation.lua` | Native item metadata, estimated eligibility, outcomes and expected value |
| `Auction/Scanner.lua` | Serialized replication request, bounded row processing, retries and cancellation |
| `Integrations/Tooltips.lua` | Modern item tooltip callback, accessible public tooltip allowlist and duplicate prevention |
| `UI/Window.lua` | Settings, progress, saved layout, item exclusions and diagnostic copy window |
| `Core/Events.lua` | ADDON_LOADED/login initialization, scan events, ticks and slash commands |

The addon uses the per-addon namespace supplied to Lua files. `_G.MSMarketValue` is the one intentionally published module namespace. `_G.MSMarketValueDB` is the TOC-declared persistent variable. No Blizzard function is replaced in runtime code. A secure post-hook observes replication requests to detect conflicts.

## Scan lifecycle

Start gates check client compatibility, initialized data, auction availability, combat, API support, cooldown, readiness and market identity. One replication request transitions to WAITING. A native completion event supplies the total row count and transitions to PROCESSING. Indices range from **0 to count−1**.

Processing occurs at most once per 0.05 seconds. Each tick handles at most 100 rows and checks an approximate four-millisecond budget using `debugprofilestop` when available. The row limit remains in effect if that optional profiler is absent.

Rows with incomplete item information enter a retry queue. Each unresolved item ID requests native cached item data at most once per scan. Retry passes revisit only unresolved rows and wait at least half a second between passes. The resolution deadline is 45 seconds. Accepted rows are accumulated once.

The scanner verifies the replication count and market identity on each processing/retry tick. Request timeout is 120 seconds. Another replication request or completion refresh invalidates active work. Close/combat/logout cancels it. Staging tables are session-only and never SavedVariables.

After every row is accounted for, the database checks row-category totals and the market key, stamps completion and replaces `markets[key]` in one assignment. There is no partial merge, price history append, or cross-market fallback. An explicit empty response is a valid replacement.

## Saved-data contract

| Field | Contents |
|---|---|
| `schema` | Integer 1; future schemas disable this build and are retained |
| `version`, `build` | Addon identities of the last initialization |
| `settings` | Tooltip visibility, automatic window opening and stale-hours preferences |
| `windowPosition` | Optional center-relative x/y coordinates |
| `excludedItems[itemID]` | Optional DE exclusion flag |
| `cooldownUntil` | Persisted minimum next replication request timestamp |
| `markets[marketKey]` | One completed snapshot per region/realm key |

Each snapshot records start/end timestamps, method, addon version/build, completeness, total/processed row counts, buyout/bid-only/sold counts, distinct priced items, `prices`, `variants`, and bid-only item flags.

Each price record contains `low` (unit copper minimum), `units` (quantity of included buyout listings) and `auctions` (number of included listings). Item-wide records use numeric item IDs. Suffix records use strings `itemID:suffix`. These are compact aggregates, not retained auction rows; seller identity is not stored.

Saved-data initialization occurs on this addon's `ADDON_LOADED`, not at Lua file load time. No migration from MS Auction is attempted. Invalid root structures or future schema numbers disable the build instead of silently replacing the user's data.

## Tooltip and restriction boundary

`TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, ...)` decorates registered public item tooltips. Primary item data is checked for access before reading the item ID. Restricted numeric/string values are checked before comparisons, arithmetic, formatting or table lookup. Forbidden and unregistered tooltips are skipped. The old `OnTooltipSetItem` hook is not used.

Default allowed frames are the native game tooltip, item-reference tooltip and comparison tooltips. Integrations may explicitly register an ordinary accessible tooltip through `MSMarketValue.Tooltips.Allow(frame)`. This is an internal beta API, without a stable external compatibility promise.

All feature calculations run outside combat. Tooltip refreshes are coalesced at 0.25-second intervals after successful scan/item-data events. No combat telemetry, aura analysis, secure buttons, protected actions, posting, purchasing, disenchant casting or automated communication is implemented.

## Repository tooling

`tests/run.lua` uses mocked native API boundaries under Lua 5.1. `tools/validate.py` checks identity/TOCs/source order and runs those fixtures. `tools/package.py` requires a clean checkout at the annotated build tag, produces archives and a complete bundle, verifies runtime parity against the tag and writes SHA-256 checksums. Runtime files contain none of these development dependencies.
