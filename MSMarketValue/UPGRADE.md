# Updating to 1.3.1-beta

1. Close WoW and back up `WTF/Account/<account>/SavedVariables/MSMarketValueDB.lua` and its `.bak` file.
2. Replace `Interface/AddOns/MSMarketValue` with the Clean ZIP's folder. Keep WTF/SavedVariables.
3. Start the game and check that `/msmv diagnostics` shows 1.3.1-beta, test revision 3.

Prices, history, preferences, watchlists, ledger, session totals/time and personal observations are kept. Updating from earlier 1.3.1 test builds keeps recent and peak history. Updating directly from 1.3.0 starts that coverage fresh because older receipts may have been misclassified. Older saved summaries retain their totals and averages; unverifiable recent rates and peaks show Not recorded. Start a new session for a clean comparison.

The calculator starts idle at login and pauses on death by default. Resume, combat or received loot starts it; resurrection alone does not. The death option is in Farming settings.

Use Manage on the Session page to keep 0–50 saved sessions or delete one after confirmation. New saves include all tracked items; older summaries still contain only the original top ten. Existing saves are not deleted by the update.

Quest rewards default to the session total only. Farming settings can include them in hourly rates or stop recording new rewards; peaks always exclude quests. Previously excluded rewards are not added retroactively. Empty-corpse samples are collected going forward; missed bodies cannot be reconstructed.

Only install the Clean ZIP in AddOns. Keep source archives elsewhere. To roll back, close WoW and restore both the older addon and its matching SavedVariables backup. Unfinished auction scans do not survive reload or logout.

See the [test notes](RELEASE-NOTES-v1.3.1-beta-test3.md) for the checks to try before release.

This build retains future exact-modifier observations across later scans on the same day, improves missing-history explanations and recovers stale farming receipt context. Existing records remain as recorded; diagnostics alone cannot reconstruct previously ignored or misclassified pickups.
