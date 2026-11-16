# Validation

**1.3.0-beta / 2026-11-15-beta001 · Test revision 7**

- **734/734 Lua 5.1 cases** and **23/23 Python checks/workloads** passed. Lua cases also passed under America/New_York, including local-date/DST fixtures.
- Every Classic source matched the real Lua decoder: **1,284,783 creature/item/mode chances across 5,213 sources/modes**. Every Everloot count and percentage matched its immutable export: **1,876 rates / 243 sources/modes**. Both rebuilds were byte-identical.
- The Classic module is **840,643 bytes**, retaining about **1.91 MiB** packed in Lua. The largest source had 564 rows; the full validation run measured up to **2.53 ms** per decode. Everloot retained about **34 KiB** packed. Both share the eight-source / 4,096-row cache and stay out of SavedVariables.
- A **ten-hour / 12,000-receipt** farming workload retained about **23 KiB**, with 60 minute buckets, five saved locations and 20 recent pickups. It used about 1.35 seconds of CPU for the complete simulated workload. The configured maximum is 61 buckets; work and storage do not grow with session length.
- New cases cover combat-aware idle, manual pauses, located five-minute peaks, quest exclusion, recent history, upgrades/reloads, HUD centering/spacing/width/lock and saved-session figures. Existing scan, crafting, ledger and exclusion checks remain green.
- The 16,000-item / ten-day keyword workload took **856 ms** cold and **197 ms** on a later keyword, retaining about **1.25 MiB** of analysis state. Other reference, ledger and transaction workloads passed. The 4 ms processing budget is cooperative; individual steps can exceed it.
- All three TOCs, 29-file load order, pinned libraries, build identity and runtime operation checks passed. No automated purchases, loot actions, uploads or chat sending were added.

These are component measurements using Lua 5.1 through Lupa 2.8, not total addon RAM or native FPS guarantees. Classic rates are unverified for Forever. Native fonts, layering, map coordinates, taint/coexistence, event ordering and WoW disk persistence still need the [live checks](LIVE-TEST-CHECKLIST.md).

Hashes, limits and workload output are in [evidence/TEST7.json](evidence/TEST7.json).
