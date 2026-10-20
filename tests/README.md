# Behavioral fixtures

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

**465 cases** load the real runtime and pinned libraries under Lua 5.1. `run.lua` contains scan, tooltip, crafting, daily history and upgrade fixtures. `market.lua` adds vendor purchase costs, discount/source isolation, resale/target math, suffix-safe comparisons, stable ranking and AH integration. Revision 2 adds movement-boundary regressions, exact gold/copper parsing, draft preservation, cached Apply and click-only item/commodity navigation, with stale, combat, throttle and incomplete-copy guards. `crafting-ui.lua` covers service presentation, search caching/isolation, published summaries, source columns and markup behavior. `economy.lua` adds net/break-even math, service charges, watchlist targets/alerts/scopes, manual ledger accounting, invoice preview/deduplication and money-tool UI. `transactions.lua` adds 58 checks for confirmed buys, commodities, mailbox/backfill/deduplication, fast collection, vendor reconciliation, commissions, date/type reports, Buy-page watch controls and restricted values. `ledger-ui.lua` adds 19 cases for portable navigation, whole-period totals, all six direct filters, source drill-downs, dates/CSV, separate cost bases, losses, editor validation, settings and cached refreshes. Restricted-value sentinels catch unsafe inspection and arithmetic.

For the optional 5,000-item / 15-day synthetic workload:

```bash
MSMV_BENCHMARK=1 python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

`market-performance.lua` reports CPU time, bounded update steps and Lua memory growth including fixture data. `economy-performance.lua` checks 200 watches over 15 days and cached views of 2,000 ledger entries. `transactions-performance.lua` checks 500 invoices, 10,000 ledger rows and cached filtered reporting, with no auction requests. These are not native FPS measurements. Fixtures do not contact an auction server, render client artwork, establish taint behavior or prove disk persistence. Native functions are replaced only in fixtures. See [VALIDATION.md](../VALIDATION.md) and [LIVE-TEST-CHECKLIST.md](../LIVE-TEST-CHECKLIST.md).
