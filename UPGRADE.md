# Upgrade and rollback

Current test: `1.1.0-beta / 2026-10-11-beta001`, **Test revision 4**. Folder, SavedVariable name and root schema remain `MSMarketValue`, `MSMarketValueDB`, and 1.

## Install

1. Finish any running scan and close WoW normally. Incomplete work is session-only.
2. Back up `WTF/Account/<account>/SavedVariables/MSMarketValueDB.lua` and its `.bak`. Keep the prior Clean ZIP.
3. Replace `Interface/AddOns/MSMarketValue` with the Clean ZIP's addon folder. Keep WTF/SavedVariables.
4. Restart Forever, check **Test revision: 4** in `/msmv diagnostics`, and confirm existing prices/preferences.
5. Follow [LIVE-TEST-CHECKLIST.md](LIVE-TEST-CHECKLIST.md).

Do not mix runtime files or install the outer source repository as an addon.

## What carries forward

Schema-1 completed scans, market keys, existing settings, exclusions, position, markup and cooldown are retained. No scan is needed solely to upgrade. Older realm-keyed prices remain isolated from detected ruleset caches.

New settings default to 30 history days, visible averages, manual crafting-window opening and profitable-only recipes. **Show profits** sits beside the profession close button and works with auto-open disabled. `/msmv craft` also opens it. Change auto-open and days retained in **/msmv → Crafting & history**.

The latest existing complete scan is imported once into its request-time UTC day if it falls within retention. Earlier scans were not stored by revisions 1 and 2. Subsequent completed scans replace that day's entry. Partial scans never enter history. Shortening retention deletes older days; it leaves current prices intact.

The session's complete local auction copy survives AH closure, but not reload/logout or addon replacement. Keep the AH open until Local copy is complete. A fresh request still respects the saved cooldown.

## Rollback and recovery

With WoW closed, restore the prior Clean ZIP. Earlier schema-1 versions ignore the new settings/history but do not maintain them; on returning to a revision with history, complete a new scan to refresh history. Keep a SavedVariables backup if you need the exact prior daily data. Future root schemas are preserved and refused; an unsupported history sub-schema is preserved while current pricing continues.

Clean restores game files. Source/Git Repository ZIPs and the bundle restore code and Git history. Your SavedVariables backup restores personal prices and preferences. Move matching addon/account data only while the clients are closed, then verify normal saving in the game.
