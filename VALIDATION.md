# Validation

**1.3.0-beta / 2026-11-15-beta001 · Test revision 5**

- **705/705 Lua 5.1 cases** and **13/13 Python checks/workloads** passed. Coverage includes six colored rarities, saved-mask migration, modifier names loading without hover, search refresh coalescing, ranking parity, personal reference gaps, quest filtering, resets and reloads.
- A synthetic **16,000-item / ten-day** search used **841 ms CPU** for its first full list, **197 ms** for a later keyword matching 160 items, and **210 ms** for no matches. It retained about **1.25 MiB** of analysis state after the empty search. The 4 ms budget is cooperative; the longest measured step was **5.44 ms**. Live completion time includes rendering and client metadata delays.
- The existing **5,000-item / 15-day** market workload completed in **63 steps / 252 ms CPU**, compared with **207 steps / 437 ms** recorded for test 4. Host timing varies. History and current prices remain separate, exact modifiers never share baselines, and only the best 500 results are retained.
- The **500,000-rate / 1,000-source** reference workload retained about **1.8 MiB** packed, or **3.4 MiB including 4,000 decoded rows**. Its longest measured decode was **1.40 ms**. Existing tracking caps and farming/ledger workloads still pass.
- The supplied Everloot archive passed ZIP CRC, hashes, row and source counts: **2,027 rates / 268 sources / 906 distinct items**. It has no classified loot modes and is not installed as a runtime reference pack.
- All three TOCs, 26-file load order, pinned libraries and runtime operation checks passed. No automated buying, loot actions, data uploads or chat sending were added.

These are synthetic component measurements, not total addon RAM or native FPS guarantees. Native menu colors, search timing, group/gathering event ordering, fonts, taint/coexistence and WoW disk persistence still need live checks. See the [checklist](LIVE-TEST-CHECKLIST.md).
