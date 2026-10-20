# Upgrade and rollback

Release **1.2.0**, build `2026-10-20-release001`.

1. Finish or discard incomplete scans, then close WoW normally.
2. Back up `WTF/Account/<account>/SavedVariables/MSMarketValueDB.lua` and its `.bak`.
3. Replace `Interface/AddOns/MSMarketValue` with the Clean ZIP’s addon folder. Keep WTF/SavedVariables.
4. Restart and check `/msmv diagnostics` shows **1.2.0** with no test-revision label.

Existing prices, history, vendor observations, watches, ledger records and settings carry forward. No new scan or data reset is required just to update. Loot/expense collection starts when its tracker is installed and enabled; earlier activity cannot be reconstructed.

Price history keeps 1–30 UTC days. Ledger retention is separate: 1–365 local days, default 90. Shortening either removes older data; export/back up first.

The Complete Package contains the Clean ZIP, source, full Git repository/history, documentation, bundle and validation files. Install only the Clean ZIP’s `MSMarketValue` folder; keep source/recovery files outside AddOns.

For rollback, close WoW and restore both an earlier Clean ZIP and its matching SavedVariables backup. Older versions may reject newer ledger types. See [source recovery](GIT-WORKFLOW.md).
