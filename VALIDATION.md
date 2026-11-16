# Validation

**1.3.0-beta / 2026-11-15-beta001 · Test revision 9**

- **759/759 Lua 5.1 cases** and **23/23 Python checks/workloads** passed under America/New_York, including local-date/DST cases.
- A new replay alternates complete and incomplete item data for 300 simulated frames. The unchanged test8 runtime made **151 builds / 150 publications** and was still checking. Test9 made **two builds / two publications** and stayed ready.
- A **16,000-item** cache-loss workload warmed the item metadata, removed native data, then made four keyword/rarity/supply/view changes. Those changes produced **four additional builds and publications**, with **zero further native item-info reads**. There were five builds including the warm-up. The complete workload took **1,989 ms CPU**; its longest measured step was **5.90 ms**.
- The existing **16,000-item / ten-day** event workload completed four queries with four builds/publications, despite repeated replies. Cold/warm keyword queries took about **1,038 / 204 ms CPU**; warm metadata calls were zero. Retained analysis state was about **5.3 MiB** in this fixture. This includes the new metadata cache and is not total addon memory.
- New cases cover cache loss across rebuilds and filter changes, independently arriving fields, late item-class data, snapshot/market invalidation, isolated modifier identities, restricted values and the hard cache limit.
- All three TOCs, the **30-file** load order, pinned libraries, runtime syntax and operation checks passed. Both bundled reference datasets rebuild identically and match the real Lua reader. Existing scan, crafting, ledger, farming and estimator cases pass.
- Farming, estimator, scanner, history and database modules retain exact test8 bytes. The completed scan format and SavedVariables schema are unchanged. No new AH request or scan reset is required.

Verified metadata stays in a **50,000-identity snapshot/market cache** across automatic rebuilds and filter changes. Incomplete replies do not erase known fields. Complete records with known class avoid native lookups. A replacement snapshot, market change or clear resets the cache. It is session-local and never enters SavedVariables. Watches remain limited to **256 IDs / 1,024 exact links**, eight checks per frame and a 1 ms allowance inside the 4 ms cooperative analysis budget. Some measured steps exceeded the target.

These are Lua 5.1/Lupa 2.8 fixture results. Native event timing, appearance, taint/coexistence and WoW disk persistence need in-game confirmation. Reuse the saved scan, repeat nondefault filters for at least 30 seconds and confirm counters settle. See [live checks](LIVE-TEST-CHECKLIST.md) and [evidence/TEST9.json](evidence/TEST9.json).
