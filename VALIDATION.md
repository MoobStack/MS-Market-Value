# Validation

**1.3.0-beta / 2026-11-15-beta001 · Test revision 10**

- **779/779 Lua 5.1 cases** and **23/23 Python checks/workloads** passed under America/New_York, including local-date/DST cases.
- **20 new drop-display cases** cover both rate directions, expected-value sorting, quest precedence, all **64 combinations** of the six rarity choices, filtering before the row limit, unknown/restricted rarity, bounded item-data requests, immediate UI changes and persistence.
- Reference-mode fixtures retain Forever rates first and Classic rates second, append personal-only items and whole missing sources, and keep sample denominators separate. Newly observed gaps appear without changing display mode and survive reload. Harvesting modes and current-area records remain separate.
- A needed quest drop remains first and visible with every rarity mask, including none selected. Quest eligibility and completed-quest behavior stay intact. A filtered-empty tooltip explains the rarity selection.
- Live-tooltip fixtures rebuild owned sections after sorting/filter changes without duplicate entries. Invalid settings repair safely; auction rarity choices remain independent. Personal counters and shared rows are not rewritten by display controls.
- All three TOCs, **30 runtime Lua files**, metadata, pinned libraries, syntax and runtime operation checks passed. Bundled reference packs rebuild identically and match the real Lua reader. Existing scan, crafting, ledger, farming, estimator and cache-loss workloads remain green.
- The test9 market metadata/analysis and auction UI modules retain exact bytes. Its 300-frame cache-loss replay still settles after two builds/publications. The 16,000-item filter workload still makes one additional build per change with no further native item reads after warm-up. Farming computation and HUD/session blocks retain test9 bytes/text.

Your native test9 diagnostics report ready analysis, 11 builds/11 publications and no pending watches, consistent with the reported loop resolution. Test10 has not been tested in the native client yet.

Drop display changes add only validated dropSort/dropQuality settings under the existing SavedVariables schema. The completed scan format, observations, reference data and session totals are preserved. Needed quests take priority; other rows are filtered before the 1–10-row limit. Unknown rarity remains visible with All selected, otherwise up to ten bounded item-data requests are attempted per view build. These settings never send auction requests.

These are Lua 5.1/Lupa 2.8 fixture results. Native appearance, fonts, event timing, taint/coexistence and WoW disk persistence need in-game confirmation. See [live checks](LIVE-TEST-CHECKLIST.md) and [evidence/TEST10.json](evidence/TEST10.json). Benchmark output is included in that evidence; the 4 ms frame target is cooperative and some steps exceed it.
