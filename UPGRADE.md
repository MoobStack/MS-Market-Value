# Upgrade and rollback

**1.2.0-beta / 2026-10-20-beta001** · Test revision **5**

1. Finish or discard incomplete scans and close WoW normally.
2. Back up `WTF/Account/<account>/SavedVariables/MSMarketValueDB.lua` and its `.bak`.
3. Replace `Interface/AddOns/MSMarketValue` with the Clean ZIP's addon folder. Keep WTF/SavedVariables.
4. Restart and check **Test revision: 5** in `/msmv diagnostics`.

Completed prices, daily history, vendor observations, watches, ledger records and settings carry forward. No scan or history reset is needed. Retention remains separate: market history 1–30 days; ledger 1–365 days, default 90.

AH/vendor tracking is enabled by default and can be disabled separately in the ledger. Open the mailbox to discover completed AH sales and unobserved purchases. Prices from scans are never treated as completed sales. **Watch item** on the native Buy page fills editable targets; **Record sale** under crafting now records a commission immediately, using the quote when price is blank.

Existing Expense records are retained under **Legacy expense**. New entries offer commissions and vendor trades. Material costs saved by craft commissions are marked estimates; enter actual cost to replace them. The ledger cap is now 10,000 records. Back up/export before shortening retention.

Install only the `MSMarketValue` folder, not the full repository. Keep package components outside AddOns and do not mix revisions. The Complete Package contains the Clean ZIP, full repository/history, source, docs, bundle and validation files.

For rollback, close WoW and restore both the earlier Clean ZIP and the matching SavedVariables backup. Earlier betas may not understand the new transaction kinds. Future/invalid schemas remain preserved rather than overwritten. See [GIT-WORKFLOW.md](GIT-WORKFLOW.md) for source recovery.
