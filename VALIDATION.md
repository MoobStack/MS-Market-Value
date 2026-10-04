# Validation

Version `1.0.0`; build `2026-10-04-release001`; tag `v1.0.0`; target Interface 16001 / client 1.60.1 / 70205.

## Completed checks and user evidence

| Layer | Result | Evidence and limits |
|---|---|---|
| Lua syntax | PASS | All eleven runtime Lua files parse under Lua 5.1.5 |
| Behavioral fixtures | **90/90 PASS** | Controlled native API/frame doubles load the actual bundled libraries |
| TOC/source contracts | PASS | Stable version/tag, build metadata, SavedVariables, load order and three identical TOCs |
| Library integrity | PASS | Pinned hashes in `tools/vendor.json`; original attribution and terms retained |
| Runtime operations | PASS | No dynamic evaluation, legacy query scanner, protected purchase/post/cast or automatic chat |
| Build003 native PvP scan | **COMPLETE reported** | 104,763 rows; 2,856 priced items; one request; 6,329 events and 6,328 same-count updates |
| Build003 tab/tooltip report | General positive feedback | Tab installed, callback ready; user said behavior appeared to function as intended; no dedicated taint/scale results supplied |
| 1.0.0 stack tooltip | Native check pending | Each/stack quantities, prices and spacing pass local cases; no exact-release client report yet |
| Native SavedVariables | Round-trip pending | The report shows a complete saved in-memory snapshot, not reload/relog/full-restart evidence |
| Other markets and DE loot | Not qualified | PvP report does not qualify Normal, other regions/factions or Forever loot probabilities |
| GitHub CI | Pending execution | Read-only workflow prepared; no remote run claimed |

The successful user report is preserved in [docs/RELEASE-1.0.0.md](docs/RELEASE-1.0.0.md). The reported snapshot started at `2026-10-04T08:07:09Z` on `forever|90|pvp|Horde`, with 5 bid-only and 0 sold rows. COMPLETE accounts for every row in the returned replication buffer; independent native listing checks are still needed for market/material coverage.

## Behavioral coverage

The original 45 cases cover budgets, zero-based rows, prices/suffixes, bid-only/sold rows, complete replacement/empty responses, pending data/timeouts, cancellation/conflicts, restricted values, schema/serialized data, DE brackets/expectations/missing prices, tooltip guards/duplicates/staleness, settings and money formatting.

Build002 added 18 market/portal/cooldown/session and AH-tab lifecycle cases. Build003 replaced the old blanket second-event refusal and added 15 cases for repeated scan updates, retry preservation, primary-only refresh, region 90, host sharing, ruleset/faction isolation, old caches and native hardcore/alias boundaries.

Version 1.0.0 adds 12 cases covering actual bag counts, matched GUIDs, equipment context, generic links, mismatched/restricted/malformed quantities, combat/forbidden/API failures, changing stack sizes and tooltip deduplication, fractional rounding/suffixes, DE block order and spacing, partial DE stack values, display options/zero vendor values, and reuse of build003 prices/settings/exclusions/cooldown.

Fixtures never infer quantity from maximum capacity or total owned items. The native quantity helpers are checked against the pinned Forever definitions. Material ranges remain per item and the stack DE total scales the original expected value.

Frame doubles cannot prove visual fit, native taint or coexistence with a running Auctionator. Serialization into a fresh namespace does not prove WoW disk saving. Historical beta failures remain documented in the build002/build003 investigations.

## Delivery gates

`tools/package.py` requires a clean checkout at the exact annotated tag, checks Git objects, ZIP CRC and runtime/source/tag byte parity, and creates/verifies a complete Git bundle. All three beta commits and tag objects are preserved.

The companion `*-Validation.json` records the delivered commit/tag, restored bundle tests, repository ZIP restore, checksum verification and reproducible Clean/Source bytes. Git Repository ZIP metadata can change after local Git operations. Packaging does not publish to GitHub.

## Native follow-up and reproduction

Use [LIVE-TEST-CHECKLIST.md](LIVE-TEST-CHECKLIST.md) for the new stacked tooltip, DE placement/spacing, first-hover comparisons, disk lifecycle, Normal/PvP/faction isolation, listing coverage and taint/coexistence.

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

The stable version records the finalized release identity. It does not change the Classic DE model's unverified Forever coverage or imply Blizzard endorsement.
