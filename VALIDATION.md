# Validation

**1.3.0-beta / 2026-11-15-beta001 · Test revision 2**

- **640/640 Lua 5.1 cases** and **8/8 offline importer checks** passed. This includes the existing scan, history, crafting and ledger coverage.
- New cases cover bonus-based modifiers, legacy history boundaries, exact Buy navigation, twelve-row scrolling, native loot-source pairs, missing-GUID tooltips, gathering, mail/trade exclusions, category totals and window focus.
- A tracking workload with 12,800 drop item counters, a full 2,048-source ring and 500 farming item types retained under **4.8 MiB of additional Lua state**.
- The 5,000-item / 15-day market workload retained at most **500 results**. Measured processing steps stayed below **4.9 ms** on the test host; the target is 4 ms. An isolated run retained about **15.7 MiB**, including its saved price/history data. These figures describe synthetic workloads, not total addon memory or native FPS.
- All three TOCs, 26-file load order, pinned libraries and runtime operation checks passed. No automatic purchases, loot actions, web requests or chat sending were added.

The optional Mudfin Oracle pack contains 132 sampled rows from Wowhead Forever. It is not a verified server-rate database and covers one NPC only.

The new layouts, native layering and loot/gathering event order still need a Forever check. See the [live checklist](LIVE-TEST-CHECKLIST.md) and [farming guide](docs/FARMING-AND-DROPS.md).

The last live result for 1.2.1 was a complete 140,222-row scan with two saved UTC days. It does not qualify the new beta features.
