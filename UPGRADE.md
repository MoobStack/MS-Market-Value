# Upgrade and rollback

**1.1.0 / 2026-10-11-release001** uses the same `MSMarketValue` folder, `MSMarketValueDB` SavedVariable and schema 1.

## Install

1. Finish any scan and close WoW normally. Incomplete work is session-only.
2. Back up `WTF/Account/<account>/SavedVariables/MSMarketValueDB.lua` and its `.bak`; keep the prior Clean ZIP.
3. Replace `Interface/AddOns/MSMarketValue` with the new Clean ZIP's addon folder. Keep WTF/SavedVariables.
4. Restart Forever. `/msmv diagnostics` should begin `MS Market Value 1.1.0 / 2026-10-11-release001`.

Do not mix runtime files or install the outer source repository as an addon.

Completed prices, history, preferences, markup, exclusions, positions and cooldown carry forward. No new scan is required solely to upgrade. Old realm-keyed caches remain isolated from detected ruleset markets.

New users get 30 history days, visible averages, profitable-only recipes and manual crafting-window opening. Click **Show profits** beside the profession close button, or use `/msmv craft`. Change auto-open and history length in **/msmv → Crafting & history**.

If upgrading from 1.0.0 or early 1.1.0 betas, history imports the latest complete saved scan once if it falls within retention. Earlier days cannot be reconstructed. Reducing retention removes older history, while leaving current prices intact.

## Rollback and recovery

With WoW closed, restore the previous Clean ZIP and, if needed, your SavedVariables backup. Older schema-1 versions may ignore history and newer preferences. Unsupported future root schemas are preserved and refused; an unsupported history sub-schema leaves current pricing usable.

The Git Repository ZIP includes all source, documentation and `.git` history. The bundle offers another Git recovery path; see [GIT-WORKFLOW.md](GIT-WORKFLOW.md). Code archives never include personal SavedVariables.
