# Validation

Build `2026-10-04-beta002`; version `0.1.0-beta`; target Interface 16001 / client 1.60.1 / 70205.

## Completed checks and user evidence

| Layer | Result | Evidence/limit |
|---|---|---|
| Lua syntax | PASS | All eleven runtime Lua files parse under Lua 5.1.5 |
| Behavioral fixtures | **63/63 PASS** | Controlled native API/frame doubles load the actual bundled tab libraries |
| TOC/source contracts | PASS | Interface, fixed beta version, build metadata, SavedVariables, load order and three identical manifests |
| Library integrity | PASS | Bundled files match the pinned hashes in `tools/vendor.json`; attribution/terms included |
| Runtime operation checks | PASS | No dynamic evaluation, legacy query scanner, repeated search enumeration, protected purchase/post/cast or automatic chat |
| Build001 user report | Partial native evidence | Correct client, modern APIs and tooltip callback installed; IDLE with failed realm/region gate and no snapshot |
| Build002 native client | **PENDING RETEST** | Scan completion, coverage, UI layout/taint/coexistence and native disk persistence not yet tested |
| GitHub CI | **PENDING** | Workflow prepared; no remote action run claimed |

## Behavioral coverage

The original 45 cases cover row/CPU budgets, zero-based iteration, stack/suffix prices, bid-only/sold distinctions, replacement/removal, explicit empty responses, pending data/timeouts, cancellation, conflicts, hostile restricted values, schema preservation, serialized saved data, DE brackets/expectations/missing prices, native tooltip guards/duplicates/staleness, settings and money formatting.

Build002 adds 18 cases: public realm/portal fallback scanning; missing or failing normalized API; all recognized region/portal mappings; native-key precedence; build001 snapshot/cooldown reuse across a fresh session; named-portal isolation; pre-request failures without cooldown; restricted/throwing lookup diagnostics; portal changes during scanning; tab creation without a popup; scanning from the tab; native/shared-addon tab switching without extending native indices; delayed frame loading and tick retries; retired popup preference; reopen/reuse; slash/manual docking; and combat gates.

The other addon tab is a fixture, not a running Auctionator installation. Tests cannot prove native event timing, display layout, frame taint, actual server coverage or WoW disk saving. The user's live build001 report is preserved in [docs/BUILD002-INVESTIGATION.md](docs/BUILD002-INVESTIGATION.md); it did not expose the failed lookup's exact value.

## Delivery packaging gates

`tools/package.py` requires a clean checkout at the exact annotated tag and checks Git objects, ZIP CRCs, and runtime byte parity against source/tag. It creates/verifies the complete Git bundle and writes SHA-256 checksums. Build002 history contains the unchanged build001 tag.

A companion `*-Validation.json` records the delivered commit/tag, archive/bundle checks, restored-bundle test result, checksum verification and reproducible Clean/Source bytes. Git Repository ZIP metadata is not promised identical after additional local Git operations.

## Pending native qualification

Use [LIVE-TEST-CHECKLIST.md](LIVE-TEST-CHECKLIST.md). Retest market diagnostics, successful native scan/material coverage, scrolling tab layout, native/Auctionator switching and bag-use taint behavior, interruption, tooltips and reload/relog/restart persistence. Actual Forever DE loot remains a separate evidence task.

## Reproduce

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

Local passes establish the tested logic; they do not establish Blizzard approval or verified Forever DE probabilities. Keep live status pending until the exact build's native scenarios are exercised.
