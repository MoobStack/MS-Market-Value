# Validation

MS Market Value **1.3.1-beta, test revision 7** passed **942 Lua cases and 23 Python checks/workloads** using Lua 5.1 API/frame fixtures.

The 18 added regressions cover the default-on and saved-off preference, immediate hiding, native tooltip ownership, handler preservation, descriptions across addon controls, list hover opt-out, and Sell-button help. Item values and world-drop preferences remain separate. Row highlighting, editing, search and native price callbacks stay covered.

Sell checks verify 26×22 red panel buttons, arrow orientation, centered placement, one-copper steps, denomination rollover, price limits and total updates. All 33 runtime Lua files pass syntax, load-order, identity and operation checks.

The full run also includes market metadata/reply replays, a 200-watch scrolling workload, 50 saved sessions, crafting, transactions, farming and drop coverage. The watchlist workload allocated no new frames or pricing publications while scrolling. These fixture timings do not establish native FPS or memory use.

Results and runtime hashes are in `evidence/TEST-1.3.1-7.json`; the log is `evidence/TEST-1.3.1-7-validation.txt`. Follow the [test notes](RELEASE-NOTES-v1.3.1-beta-test7.md) to confirm tooltip placement, the seven-row settings layout and button size in game. No live-client verification is claimed.
