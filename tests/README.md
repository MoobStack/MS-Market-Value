# Behavioral fixtures

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

**318 cases** load the real runtime and pinned libraries under Lua 5.1. `run.lua` contains scan, tooltip, crafting, daily history and upgrade fixtures. `market.lua` adds vendor purchase costs, discount/source isolation, resale/target math, suffix-safe comparisons, stable ranking and AH integration. Revision 2 adds movement-boundary regressions, exact gold/copper parsing, draft preservation, cached Apply and click-only item/commodity navigation, with stale, combat, throttle and incomplete-copy guards. Restricted-value sentinels catch unsafe inspection and arithmetic.

For the optional 5,000-item / 15-day synthetic workload:

```bash
MSMV_BENCHMARK=1 python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

`market-performance.lua` reports CPU time, bounded update steps and Lua memory growth including fixture data. It is not a native FPS measurement. Fixtures do not contact an auction server, render client artwork, establish taint behavior or prove disk persistence. Native functions are replaced only in fixtures. See [VALIDATION.md](../VALIDATION.md) and [LIVE-TEST-CHECKLIST.md](../LIVE-TEST-CHECKLIST.md).
