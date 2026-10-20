# Upgrade and rollback

**1.2.0-beta / 2026-10-20-beta001**, Test revision **2**. The addon folder, SavedVariable and root schema remain `MSMarketValue`, `MSMarketValueDB` and schema 1.

1. Finish any scan and close WoW normally. Incomplete work is session-only.
2. Back up `WTF/Account/<account>/SavedVariables/MSMarketValueDB.lua` and its `.bak`.
3. Replace `Interface/AddOns/MSMarketValue` using the Clean ZIP. Keep WTF/SavedVariables.
4. Restart. Diagnostics should identify the version/build above and Test revision 2.
5. Open a supplies vendor to learn your discounted material purchase prices. Then check a recipe with a vendor reagent.

Completed prices, daily history, preferences, markup, exclusions, positions and cooldown carry forward from 1.1.0. No AH scan is required solely to upgrade. Vendor purchase observations and market filters are new optional data; current-price and history formats stay unchanged.

Open **MS Opportunities** before the existing AH tab. Default resale filters need three earlier priced days per item, plus a fresh current scan. Same-day scans do not add earlier days. History settings still allow 1–30 calendar days; shortening retention removes older entries immediately.

Existing profit targets keep their value and now display in gold (500 silver becomes 5 gold). Resale now applies the saved price-move threshold too; use 0 to disable that check. No price-history reset is needed.

Keep code packages outside AddOns and install only their `MSMarketValue` folder. Do not mix files from different revisions. The Complete Package contains the Clean ZIP, full Git repository, source, docs, bundle and verification files.

With WoW closed, roll back using the prior Clean ZIP and your SavedVariables backup if needed. Older schema-1 versions may ignore the newer vendor/filter fields. Unsupported future sub-schemas are preserved. Code archives exclude player data. See [GIT-WORKFLOW.md](GIT-WORKFLOW.md) for repository recovery.
