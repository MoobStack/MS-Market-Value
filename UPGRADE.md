# Upgrade and rollback

**1.2.0-beta / 2026-10-20-beta001** · Test revision **8**

1. Finish or discard incomplete scans and close WoW normally.
2. Back up `WTF/Account/<account>/SavedVariables/MSMarketValueDB.lua` and its `.bak`.
3. Replace `Interface/AddOns/MSMarketValue` with the Clean ZIP's addon folder. Keep WTF/SavedVariables.
4. Restart and check **Test revision: 8** in `/msmv diagnostics`.

Completed prices, daily history, vendor observations, watches, ledger records and settings carry forward. No scan or history reset is needed. Retention remains separate: market history 1–30 days; ledger 1–365 days, default 90.

Open `/msmv → Ledger`. **Loot** totals the money looted each local day. **Other** includes repairs, training, respecs, postage, flights and other expenses; its dropdown lets you tick several categories. Switching type filters disables that category restriction; All includes everything. The period report includes loot and Other totals.

Loot and other-spending tracking are enabled by default, with separate checkboxes in Ledger settings. Tracking begins after installation; earlier costs and loot cannot be reconstructed. Unrecognized wallet deductions appear as Unclassified. Existing Expense rows are retained under Other → Legacy expense. Old rows, local timestamps, UTC market-history days and prior settings remain intact. CSV adds Category.

Gold in completed player trades remains Tips received/given. Reclassify craft payments in the editor instead of recording them again with Record sale. Craft costs remain labeled estimates until actual cost replaces them. The ledger holds up to 10,000 records; back up/export before shortening retention.

Install only the `MSMarketValue` folder, not the full repository. Keep package components outside AddOns and do not mix revisions. The Complete Package contains the Clean ZIP, full repository/history, source, docs, bundle and validation files.

For rollback, close WoW and restore both the earlier Clean ZIP and the matching SavedVariables backup. Earlier betas may not understand the new transaction kinds. Future/invalid schemas remain preserved rather than overwritten. See [GIT-WORKFLOW.md](GIT-WORKFLOW.md) for source recovery.
