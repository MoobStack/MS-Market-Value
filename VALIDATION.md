# Validation

**1.3.0-beta / 2026-11-15-beta001 · Test revision 8**

- **750/750 Lua 5.1 cases** and **23/23 Python checks/workloads** passed under America/New_York, including local-date/DST cases.
- Replaying successful partial item replies against the unchanged test7 runtime caused **101 builds in 200 simulated frames**. The revised runtime completed the same search with **one build and one publication**.
- A **16,000-item / ten-day** workload completed four keyword changes with **four builds/four publications**, despite **672 item replies**. It used **832 ms CPU** in total; the longest measured step was **4.08 ms**. No new auction requests were sent.
- The ordinary keyword workload took **766 ms** cold, **204 ms** on a later keyword and **184 ms** with no matches, retaining about **1.25 MiB** of analysis state. The 4 ms budget is cooperative; some steps exceeded it.
- New cases cover unchanged/unusable replies, delayed real progress, multi-frame checks, late variants, exact-name identity, cached visible rows, restricted values and bounded pending records. Pants variants appear immediately in All items; Resale requires each variant's earlier days and signal targets.
- All three TOCs, the **30-file** load order, pinned libraries and runtime operation checks passed. Existing scans, crafting, ledger, farming and reference-data checks remain green. Both reference datasets rebuild identically and match the Lua reader.

Metadata watches cap at **256 IDs / 1,024 exact links** per pass, with at most eight checks per frame and a 1 ms allowance inside the analysis budget. They are session-local and do not enlarge SavedVariables. Existing scan keys/history are reused.

These are fixture measurements using Lua 5.1 through Lupa 2.8, not native FPS or whole-addon RAM guarantees. Check repeated filter changes and real item-data timing in game using the [live checklist](LIVE-TEST-CHECKLIST.md). Current counts, hashes and workload output are in [evidence/TEST8.json](evidence/TEST8.json).
