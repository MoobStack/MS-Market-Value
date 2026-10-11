# MS Market Value 1.1.0

Crafting analysis and daily price history join the Auction House scanner and item tooltips.

- See material cost, sale value, profit or loss and percentage return for the selected recipe. Sort recipes by profit or return, with an option to show unprofitable and unpriced recipes.
- Copy craft quotes with markup and a native recipe link when available, or insert a chat draft.
- Keep 1–30 days of prices, using each UTC day's latest completed scan. Tooltips show the historic average and sample-day count alongside vendor, recent AH and disenchant values.
- Open or close profits from the profession's Show profits / Hide profits button. Auto-open is optional and off by default.
- Keep saved tooltip prices visible in combat. Pause and resume scans; a complete local copy survives closing and reopening the AH without another request.

Close WoW and replace the addon folder using the Clean ZIP. Keep WTF/SavedVariables to retain prices, history and settings. No new scan is required just to upgrade.

For WoW Forever 1.60.1 / Interface 16001. Build `2026-10-11-release001`; tag `v1.1.0`. **239/239 local Lua 5.1 tests pass**, and the user reports the final beta functioning properly. Full source, tests, documentation and prior Git history are included in the repository package.

Prices are asking prices; profit is before fees. Missing prices and unsupported recipes stay unavailable. Disenchant outcomes remain an unverified Classic reference for Forever.
