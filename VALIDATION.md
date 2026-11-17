# Validation

MS Market Value **1.3.1-beta, test revision 2** passed **846 Lua cases and 23 Python checks/workloads** with Lua 5.1 API/frame fixtures. The 33 new regressions cover login/death/ghost timing, manual pause, session retention and deletion, complete archive details and both scrolling lists.

Storage checks saved and reloaded 50 sessions with 25,000 item rows and 1,000 recent receipts, then reduced retention to five. Character/market separation, confirmed removals, older summaries and the running session were checked. Recipe scrolling makes no new valuation or auction requests; selection follows the visible row.

All 30 runtime Lua files pass syntax, load-order, identity and operation checks. Current guide links and installed copies were checked. Existing farming, drop, market, crafting and ledger regressions remain included.

Results and runtime hashes are in `evidence/TEST-1.3.1-2.json`; the local log is `evidence/TEST-1.3.1-2-validation.txt`. Synthetic CPU/memory figures do not establish native FPS or total addon memory. Follow the [in-game checks](RELEASE-NOTES-v1.3.1-beta-test2.md) for native event timing, mouse input and appearance before accepting a final release.
