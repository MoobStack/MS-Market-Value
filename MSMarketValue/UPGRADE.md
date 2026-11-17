# Updating to 1.3.1-beta

1. Close WoW and back up `WTF/Account/<account>/SavedVariables/MSMarketValueDB.lua` and its `.bak` file.
2. Replace `Interface/AddOns/MSMarketValue` with the Clean ZIP's folder. Keep WTF/SavedVariables.
3. Start the game and check that `/msmv diagnostics` shows 1.3.1-beta, test revision 1.

Prices, history, preferences, watchlists, ledger, session totals/time and personal observations are kept. Recent and peak farming coverage starts fresh because older receipts may have been misclassified. Older saved summaries retain their totals and averages; unverifiable recent rates and peaks show Not recorded. Start a new session for a clean comparison.

Quest rewards now default to the session total only. Farming settings can include them in hourly rates or stop recording new rewards; peaks always exclude quests. Previously excluded rewards are not added retroactively. Empty-corpse samples are collected going forward; missed bodies cannot be reconstructed.

Only install the Clean ZIP in AddOns. Keep source archives elsewhere. To roll back, close WoW and restore both the older addon and its matching SavedVariables backup. Unfinished auction scans do not survive reload or logout.

See the [test notes](RELEASE-NOTES-v1.3.1-beta-test1.md) for the checks to try before release.
