# Validation

**1.3.0-beta / 2026-11-15-beta001 · Test revision 6**

- **716/716 Lua 5.1 cases** and **18/18 Python checks/workloads** passed. New coverage checks bundled defaults, independent personal collection, display choices after reload, Rate/Session labels, the session-total option, idle resume and manual pauses.
- Every bundled rate was compared with the checked export through the real Lua reader: **1,848 rates / 238 sources/modes**. All sample counts and percentages matched. Rebuilding the module is deterministic; bad hashes, incomplete downloads and invalid source modes leave installed data unchanged.
- The **11,287-byte** dataset module retained about **33 KiB** packed and **53 KiB** with eight viewed sources cached. Its longest measured source decode was **0.185 ms**. These are component measurements; data is not copied into SavedVariables.
- The synthetic **16,000-item / ten-day** search used **848 ms CPU** cold, **200 ms** for a later keyword matching 160 items, and **192 ms** for no matches. It retained about **1.25 MiB** of analysis state. The longest step was **4.83 ms**; the 4 ms target is cooperative.
- The **500,000-rate / 1,000-source** workload still stayed within the eight-source / 4,096-row cache limit. Existing auction, crafting, ledger, mail/trade exclusions and bounded tracking checks passed.
- All three TOCs, 27-file load order, pinned libraries and runtime operation checks passed. No automated buying, loot actions, data uploads or chat sending were added.

These are component measurements, not total addon RAM or native FPS guarantees. Dataset coverage is partial and based on community samples. Native tooltip IDs, group/gathering event ordering, display layout, taint/coexistence and WoW disk persistence still need live checks. See the [checklist](LIVE-TEST-CHECKLIST.md).

Exact dataset hashes and test/workload results are in [evidence/TEST6.json](evidence/TEST6.json).
