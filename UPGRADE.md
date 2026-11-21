# Updating MS Market Value

1. Close WoW and back up `WTF/Account/<account>/SavedVariables/MSMarketValue.lua` and its `.bak` file.
2. Replace `Interface/AddOns/MSMarketValue` with the Clean ZIP's folder. Keep SavedVariables.
3. Open `/msmv diagnostics` to verify the version is **1.3.2**.

Prices, history, settings, watches, targets, ledger entries and personal observations carry forward. No new scan is required to keep existing records; regular scans add fresh prices and modifier history.

If prompted, choose your character's Auction House ruleset. PvP is the default choice. You can change it in **MS Market Value → Price snapshot → Change ruleset**. Personal activity can record before you choose. A scan requires a confirmed ruleset.

Farming starts idle at login. Resume, combat or received loot starts timing. Death pause is on by default, and a manual pause stays paused. Quest rewards default to the session total; peaks always exclude them.

Use **Session → Manage** to keep 0–50 saved sessions, five by default, or delete a selected save. New saves retain the full tracked item list. Older summaries keep their original top ten items and cannot recover missing details.

Upgrading from 1.3.0 keeps session totals and time but starts recent-rate and peak coverage fresh. Compatible rate history is retained. Unverifiable older saved rates show Not recorded. Empty-corpse samples are collected going forward.

Interface help starts enabled under Tooltips and can be switched off there. Watchlist alerts retain your saved choices; their settings are on the watchlist page.

Only the Clean ZIP belongs in AddOns. To roll back, close WoW and restore the older addon with its matching SavedVariables backup. Unfinished scans do not survive reload or logout.

[Release notes](RELEASE-NOTES-v1.3.2.md) · [User guide](DOCUMENTATION.md)
