# Upgrade and rollback

Test **1.3.0-beta**, build `2026-11-15-beta001`, revision **9**.

1. Finish or discard incomplete scans, then close WoW normally.
2. Back up `WTF/Account/<account>/SavedVariables/MSMarketValueDB.lua` and its `.bak`.
3. Replace `Interface/AddOns/MSMarketValue` with the Clean ZIP’s addon folder. Keep WTF/SavedVariables.
4. Disable any older `MSMarketValueReference` pilot, then restart. Check `/msmv diagnostics` shows test revision **9** and the bundled Everloot reference.

This fix uses your existing completed scan and history; no wipe or history restart is needed. Existing prices, history, watches, ledger entries and beta farming/drop samples carry forward. From revision 2 onward, scans already have precise modifiers; a fresh scan adds native names and rarity. Older item-wide history stays saved but cannot identify a modifier's movement. All items shows current variants immediately; signals need enough earlier precise priced days. Missed drops cannot be reconstructed.

Profiles predating bundled data select Reference once. Later display choices are remembered. Personal tracking remains on by default; an explicitly disabled tracker stays off. Forever samples take priority over Classic fallback, then personal gap filling. Rarity choices still run from Poor through Legendary.

The farming display labels the whole-session rate **Average** and the optional total **Session**. Its width and position lock are in Farming settings. Recent/peak history began in revision 7; older sessions retain their totals. Peak farming excludes quests.

Idle pause defaults to five minutes for profiles without an explicit choice. Set 5–60 minutes or Off; the choice is remembered. Combat entry and your loot resume automatic idle, combat keeps the timer active, and the countdown restarts after combat. Manual pauses stay paused. Older timeouts above 60 minutes are reduced to 60.

Compatible PvP scans still saved under earlier host names are used automatically. No new scan is required for recovery. Unfinished, deleted or overwritten scans cannot be recreated. If 1.2.0 saved more than one profile for the same character or watchlist, the addon keeps using one and leaves the others in SavedVariables.

Price history keeps 1–30 UTC days. Ledger retention is separate: 1–365 local days, default 90. Shortening either removes older data; export/back up first.

Install only the Clean ZIP’s `MSMarketValue` folder. Keep source and recovery files outside AddOns.

For rollback, close WoW and restore both an earlier Clean ZIP and its matching SavedVariables backup. Older versions may reject newer ledger types. See [source recovery](GIT-WORKFLOW.md).
