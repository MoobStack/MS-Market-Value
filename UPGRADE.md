# Upgrade and rollback

Current test: `1.1.0-beta / 2026-10-11-beta001`, **Test revision 2**. The addon folder, SavedVariable name and schema remain `MSMarketValue`, `MSMarketValueDB`, and 1.

## Install this test revision

1. Finish a running scan and close WoW normally. Paused scans are session-only and cannot survive an addon replacement/restart.
2. Back up `WTF/Account/<account>/SavedVariables/MSMarketValueDB.lua` and its `.bak` if present. Keep the prior Clean ZIP.
3. Replace `Interface/AddOns/MSMarketValue` with the new Clean ZIP's `MSMarketValue` folder. Keep WTF/SavedVariables.
4. Restart the Forever client and open `/msmv diagnostics`. Confirm the version, build, and **Test revision: 2**.
5. Verify saved prices and settings, then follow [LIVE-TEST-CHECKLIST.md](LIVE-TEST-CHECKLIST.md).

Do not mix files from different revisions or install the outer source repository as an addon. Restart the client for this update.

## What carries forward

Existing 1.0.0, build003 and earlier 1.1.0-beta schema-1 completed snapshots, market keys, settings, exclusions, window position and cooldown remain. No new scan is needed solely for this upgrade. Existing quote markup is kept; a missing setting defaults to zero.

Older build001/build002 realm-keyed records remain stored, but are not merged into the later ruleset keys. If that ruleset has no completed snapshot yet, its first successful scan is still required. See the historical entries in [CHANGELOG.md](CHANGELOG.md).

Incomplete work is not saved between game sessions. Pause/resume uses the current session's local auction copy once copying finishes. Keep the AH open until Local copy is complete. Restarting retains the last completed prices and request cooldown; it does not preserve an unfinished buffer.

Price history is planned for the next test revision and does not exist in this package.

## Roll back or move installations

With WoW closed, restore the earlier Clean ZIP's addon folder. Both 1.0.0 and this test use schema 1; the additional markup setting is harmless to 1.0.0. Restore a matching SavedVariables backup only if needed, with WoW closed. Future schemas are preserved and refused rather than silently downgraded.

The Clean ZIP restores game files. Source/Git Repository ZIPs and the bundle restore code and history. Your account SavedVariables backup restores personal prices and settings. When moving clients, copy the matching addon and account data while both clients are closed, then verify that the game saves them normally.
