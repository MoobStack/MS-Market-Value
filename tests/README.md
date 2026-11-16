# Behavioral fixtures

Run from the repository root with Lua 5.1:

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
TZ=America/New_York python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

**759 Lua cases** load the real runtime and pinned libraries. New coverage replays native cache loss, alternating full/partial replies, metadata retention across keyword/rarity/view changes, snapshot/market invalidation, the cache limit, exact-name identity and per-variant history, then checks the layered reference data, centered/locked/resized HUD, combat-aware idle, five-minute peaks, quest exclusion, recent history, saved sessions and upgrades. Existing scan, crafting, history, ledger and restricted-value cases remain. Local-date cases include 23- and 25-hour DST days under America/New_York.

The same command runs **22 Python checks** for importers, deterministic rebuilding, probability fixtures, archive integrity and every shipped source's agreement with the real Lua reader.

For optional synthetic workloads:

```bash
MSMV_BENCHMARK=1 python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

A twenty-third Python case generates the optional 500,000-rate / 1,000-source workload. Other workloads exercise 5,000 items/15 days, keyword searches over 16,000 items/ten days, 200 watches, 500 invoices and 10,000 ledger rows. The real Classic pack is also checked across 5,213 creature/mode sources. A four-query / 16,000-item workload checks duplicate replies and stable publications. A ten-hour / 12,000-receipt farming workload checks bounded rate history. These report component CPU/memory, not native FPS. No auction requests are made.

Native functions and frames are fixture doubles. They cannot prove server event ordering, fonts, layering, taint, coexistence or WoW disk persistence. See [Validation](../VALIDATION.md) and [live checks](../LIVE-TEST-CHECKLIST.md).
