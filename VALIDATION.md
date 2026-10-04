# Validation

Build `2026-10-04-beta001`; version `0.1.0-beta`; target Interface 16001.

## Completed local checks

| Layer | Result | Evidence/limit |
|---|---|---|
| Lua syntax | PASS | All nine runtime Lua files parse under Lua 5.1.5 |
| Behavioral fixtures | **45/45 PASS** | `tests/run.lua`, run with a separately compiled Lua 5.1 interpreter |
| TOC/source contracts | PASS | Interface, fixed beta version, build metadata, SavedVariables, load order and three identical manifests |
| Runtime operation checks | PASS | No dynamic code evaluation, legacy AH query scanner, repeated per-item full enumeration, protected purchase/post/cast or automatic chat operations |
| Live WoW session | **PENDING** | No Forever client was operated during development |
| GitHub CI run | **PENDING** | Workflow is prepared; no external repository/action run is claimed |

## Behaviors covered

- First/last zero-based row handling and all returned row accounting.
- Per-unit stack prices, signed suffix lookup, item-wide fallback, bid-only and sold-row distinction.
- Complete snapshot replacement and removal of formerly listed prices.
- Explicit empty-market completion.
- Prior-snapshot preservation during partial work, cancellation, combat, AH closure, failures and late responses.
- Row/CPU budgets and delayed item-data retries without double-counting.
- Replication ownership conflicts, duplicate updates, changed buffers and market changes.
- Invalid/restricted counts, price fields, quantities and item IDs.
- Request refusal, server-readiness gates, persistent cooldown and full saved-table serialization round-trips.
- Future schema preservation and unsupported-client refusal.
- Item-level material bracket selection, exhaustive green probabilities, rare/epic ranges and weighted values.
- Missing material prices, unsupported equipment/ranges and explicit item exclusions.
- Tooltip duplicates, uncached items, age/stale flags, forbidden/restricted tooltip inputs and combat suppression.
- Settings availability, diagnostics generation, slash commands and money formatting.

The mocked server and frame implementations are defined in the fixture file, not bundled into the installed addon. They cannot prove native event timing, UI layout, taint behavior or successful disk persistence.

## Delivery packaging gates

`tools/package.py` requires a clean tagged checkout and runs Git object checks, ZIP CRC verification, and exact runtime byte parity between Clean ZIP, Source ZIP and the annotated build tag. It creates and verifies a full Git bundle and writes checksums.

The delivery also has a companion `*-Validation.json` receipt recording the actual final commit, tag, archive/bundle checks, restored-bundle test result, checksum results and reproducible Clean/Source archive result. Compare its commit/tag with your checkout; it describes those specific delivered files. Git Repository ZIP metadata is not promised identical after additional local Git operations.

## Pending live qualification

Use [LIVE-TEST-CHECKLIST.md](LIVE-TEST-CHECKLIST.md). Core pending items are successful native scan response and material coverage, partial/failure behavior, native tooltips/settings, reload/relog/restart persistence, coexistence with other addons and actual Forever DE loot observations.

Passing local tests establishes the tested logic, not Blizzard approval or verified Forever loot probabilities. The reference DE model remains marked unverified regardless of the fixture pass count.

## Reproduce local checks

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

For a changed build, add focused fixtures for the changed behavior and update this file with the resulting pass count and native evidence. Do not change PENDING to PASS without running the relevant live scenario.
