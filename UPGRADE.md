# Upgrade and rollback

Release **1.2.1**, build `2026-11-06-release001`.

1. Finish or discard incomplete scans, then close WoW normally.
2. Back up `WTF/Account/<account>/SavedVariables/MSMarketValueDB.lua` and its `.bak`.
3. Replace `Interface/AddOns/MSMarketValue` with the Clean ZIP’s addon folder. Keep WTF/SavedVariables.
4. Restart and check `/msmv diagnostics` shows **1.2.1**. On a recognized live PvP host it also shows the ruleset and any recovered days.

Compatible PvP scans still saved under earlier host names are used automatically. No new scan is required for recovery. Unfinished, deleted or overwritten scans cannot be recreated. If 1.2.0 saved more than one profile for the same character or watchlist, the addon keeps using one and leaves the others in SavedVariables.

Price history keeps 1–30 UTC days. Ledger retention is separate: 1–365 local days, default 90. Shortening either removes older data; export/back up first.

Install only the Clean ZIP’s `MSMarketValue` folder. Keep source and recovery files outside AddOns.

For rollback, close WoW and restore both an earlier Clean ZIP and its matching SavedVariables backup. Older versions may reject newer ledger types. See [source recovery](GIT-WORKFLOW.md).
