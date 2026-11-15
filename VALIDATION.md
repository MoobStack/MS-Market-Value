# Validation

**1.3.0-beta / 2026-11-15-beta001 · Test revision 4**

- **689/689 Lua 5.1 cases** and **13/13 Python checks/workloads** passed, including the previous scan, crafting, history and ledger coverage. One Python case generates the optional large reference workload.
- New checks cover the enabled idle default and 60-minute boundary, preference migration, colors before hover, multi-select rarity filtering before the result cap, one-day modifier browsing, combat views and the documented starter CLI.
- A synthetic **500,000-rate / 1,000-source** reference pack retained about **1.8 MiB** as packed data, or **3.4 MiB including 4,000 decoded rows**. The longest measured decode was **1.15 ms**. This measures the Lua reader, not live tooltip or network timing.
- Tracking 12,800 drop item counters, 2,048 recent sources and 500 farming item types retained under **4.7 MiB of extra Lua state**. The 5,000-item / 15-day market workload includes native name/rarity metadata, retains 500 results and used about **17.1 MiB**. The longest measured step was **4.10 ms**, with a 4 ms target. Small shared metadata pairs avoid expanding every price table.
- All three TOCs, 26-file load order, pinned libraries and runtime operation checks passed. Item-name requests are bounded; no automated buying, loot actions or chat sending were added.

These are synthetic component measurements, not total addon RAM or native FPS guarantees. The compact Mudfin Oracle pilot keeps 132 exact sampled rates in 458 encoded bytes. It is not a complete world database or verified server-rate table.

Live Forever checks remain for native colors before hover, rarity menus, combat/taint behavior, coin sizing, idle behavior, quest tooltips and gathering/event timing. See the [live checklist](LIVE-TEST-CHECKLIST.md).
