# Behavioral fixtures

Run from the repository root with Lua 5.1:

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
TZ=America/New_York python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

**716 Lua cases** load the real runtime and pinned libraries. New coverage checks bundled reference defaults, independent personal collection, the Rate/Session display, hiding its total, idle resume and saved preferences. Existing scan, crafting, history, ledger, combat and restricted-value cases remain. Local-date cases include 23- and 25-hour DST days under America/New_York.

The same command runs **17 Python checks** for the importers, deterministic rebundling, archive integrity and every shipped rate's agreement with the real Lua reader.

For optional synthetic workloads:

```bash
MSMV_BENCHMARK=1 python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

An eighteenth Python case generates the optional 500,000-rate / 1,000-source reference workload. Other workloads exercise 5,000 items/15 days, cold/warm keyword searches over 16,000 items/ten days, 200 watches, 500 invoices and 10,000 ledger rows. They report CPU/memory and cached-view behavior, not native FPS. No auction requests are made.

Native functions and frames are fixture doubles. They cannot prove server event ordering, fonts, layering, taint, coexistence or WoW disk persistence. See [Validation](../VALIDATION.md) and [live checks](../LIVE-TEST-CHECKLIST.md).
