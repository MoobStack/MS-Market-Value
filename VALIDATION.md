# Validation

**1.2.0-beta / 2026-10-20-beta001** · Test revision **1** · Tag `v1.2.0-beta-test1`

| Check | Result |
|---|---|
| Lua 5.1 behavior | **291/291 passed** |
| Runtime syntax | All 17 Lua files passed |
| Identity | Fixed beta version/build; three identical TOCs; test revision 1 |
| Dependencies | Pinned LibStub/LibAHTab bytes and notices retained |
| Operations | No automatic auction request from market analysis; no purchases, postings, crafts or chat sends |
| Prior release | 1.1.0 runtime/data baseline preserved in Git |
| New native features | Vendor prices and opportunities UI need in-game confirmation |

The 52 added cases cover merchant discounts and bundle sizes, per-player/market prices, stale or unknown vendor costs, discount changes, quote/ranking integration, conservative resale math, fees/targets, missing days, outliers, suffix isolation, stale scans, bounded ranking, caching, interruption and both AH tabs. Existing scan, combat tooltip, crafting, history, recovery and upgrade checks remain.

## Performance check

A synthetic Lua 5.1 workload with **5,000 items across 15 days** completed analysis in **203 update steps**, using **383.68 ms** total CPU with a **5.31 ms** maximum step in this environment. It retained the best 200 matches and made zero auction requests. The runtime budget is approximately four milliseconds per frame; a completed operation or garbage collection can exceed the target slightly. This is not a game-client FPS measurement.

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
MSMV_BENCHMARK=1 python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

The delivery report records the exact commit/tag, independent archive restores, retained tags, byte comparisons and hashes. Packaging requires a clean checkout at the annotated test tag. The supplied ZIPs contain no player SavedVariables.

## Native testing

The accepted 1.1.0 diagnostics came from Forever 1.60.1 / 70338 / Interface 16001 on PvP/Horde, with saved prices, a craft valuation and one retained history day. They do not validate the new 1.2.0 changes. See [docs/RELEASE-1.1.0.md](docs/RELEASE-1.1.0.md) for prior evidence.

Check a supplier and recipe, the two AH tabs, one eligible item and reload persistence. Frame doubles do not render native artwork or establish taint behavior. Historic asking prices do not establish demand or completed sales; the configured AH cut needs the user's chosen rate. DE outcomes remain an unverified Classic reference. The short [live checklist](LIVE-TEST-CHECKLIST.md) covers those checks.
