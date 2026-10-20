# Behavioral fixtures

Run from the repository root with Lua 5.1:

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
TZ=America/New_York python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

**584 cases** load the real runtime and pinned libraries. Fixtures cover scans/resume, public tooltip data and stacks, crafting/quotes, daily history, vendor costs, market math/navigation, watchlists, confirmed transactions, ledger reports, trade gold, loot/expenses, category menus and stable upgrades. Restricted-value sentinels catch unsafe reads/arithmetic. Local-date cases include 23- and 25-hour DST days under America/New_York.

For optional synthetic workloads:

```bash
MSMV_BENCHMARK=1 python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

The workloads exercise 5,000 items/15 days, 200 watches, 500 invoices and 10,000 ledger rows. They report CPU/memory and cached-view behavior, not native FPS. No auction requests are made.

Native functions and frames are fixture doubles. They cannot prove server event ordering, fonts, layering, taint, coexistence or WoW disk persistence. See [Validation](../VALIDATION.md) and [live checks](../LIVE-TEST-CHECKLIST.md).
