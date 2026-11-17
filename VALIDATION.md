# Validation

MS Market Value **1.3.1-beta, test revision 6** passed **924 Lua cases and 23 Python checks/workloads** using Lua 5.1 API/frame fixtures. The 47 focused Sell/watchlist cases also passed before the complete run.

Updated Sell checks cover the 28×24 panel-button hit areas, native arrow atlas and orientation, centered 1×2 placement and the price warning below copper. Existing cases retain one-copper changes, silver/gold rollover, zero/input limits, native total callbacks, manual edits and repeated AH opening.

Watchlist search is retained and still filters saved watches. Its 200-watch workload passed 200 scrolls and 200 searches with no new frames, price-analysis publications or metadata reads during scrolling. Alerts, editing and native Buy navigation remain covered.

All 32 runtime Lua files pass syntax, load-order, identity and operation checks. Earlier market, farming, session, crafting, ledger and drop coverage remains included. Results and runtime hashes are in `evidence/TEST-1.3.1-6.json`; the local log is `evidence/TEST-1.3.1-6-validation.txt`.

The native AH source was checked for the sort-arrow atlas and direction. Fixtures do not render game textures or prove live-client spacing, FPS or event timing. Confirm the red buttons, arrow size and price-warning placement in game using the [test notes](RELEASE-NOTES-v1.3.1-beta-test6.md).
