# Upgrade and rollback

**1.2.0-beta / 2026-10-20-beta001** · Test revision **7**

1. Finish or discard incomplete scans and close WoW normally.
2. Back up `WTF/Account/<account>/SavedVariables/MSMarketValueDB.lua` and its `.bak`.
3. Replace `Interface/AddOns/MSMarketValue` with the Clean ZIP's addon folder. Keep WTF/SavedVariables.
4. Restart and check **Test revision: 7** in `/msmv diagnostics`.

Completed prices, daily history, vendor observations, watches, ledger records and settings carry forward. No scan or history reset is needed. Retention remains separate: market history 1–30 days; ledger 1–365 days, default 90.

Open `/msmv` anywhere and click **Ledger**, or use `/msmv ledger`. **Period report** shows all activity for the chosen dates; **Transactions** provides eight direct type filters, including tips received and given. Tracking and retention controls are under **Ledger settings**. The editor now uses a Type dropdown, and active panels stay visible during refresh so filter clicks apply immediately.

Ledger dates, periods and retention now follow the computer’s local calendar, including daylight-saving changes. Saved timestamps are unchanged; price-history days remain UTC. CSV adds LocalTime while retaining UTC for reference.

AH, vendor and trade-tip tracking are enabled by default and can be disabled separately. Completed trade gold starts as Tips received/given. Reclassify craft payments in the editor instead of recording the same payment again with Record sale; enter 0 cost for a pure tip. Open the mailbox to discover completed AH sales and unobserved purchases. Prices from scans are never treated as completed sales. **Watch item** on the native Buy page fills editable targets; **Record sale** under crafting now records a commission immediately, using the quote when price is blank.

Existing Expense records are retained under **Legacy expense**. New entries offer commissions and vendor trades. Material costs saved by craft commissions are marked estimates; enter actual cost to replace them. The ledger holds up to 10,000 records. Back up/export before shortening retention.

Install only the `MSMarketValue` folder, not the full repository. Keep package components outside AddOns and do not mix revisions. The Complete Package contains the Clean ZIP, full repository/history, source, docs, bundle and validation files.

For rollback, close WoW and restore both the earlier Clean ZIP and the matching SavedVariables backup. Earlier betas may not understand the new transaction kinds. Future/invalid schemas remain preserved rather than overwritten. See [GIT-WORKFLOW.md](GIT-WORKFLOW.md) for source recovery.
