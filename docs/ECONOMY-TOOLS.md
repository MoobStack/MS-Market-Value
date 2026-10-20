# Watchlists and personal ledger

Open these tools from **MS Opportunities**, or use `/msmv watch` and `/msmv ledger`. They can open away from an auctioneer; live listings need an open AH. Both windows hide in combat.

## Watchlists

Enter an item ID or paste an item link, then set any combination of **Buy at or below (g)**, **Min return %** and **Min profit (g)**. Click **Save watch**. A zero disables that target; all zeros means tracking only. Every enabled target must pass.

An item ID tracks the item-wide series; a link tracks its exact random suffix, including zero. Watchlists belong to the current market. **Watch selected** on Opportunities fills a draft with that item's targets; saving activates it.

Buy-price targets need a fresh scan. Return/profit targets also need enough earlier priced days, using the Opportunities lookback, minimum-day setting, AH cut and conservative lower-quartile resale baseline. Current-day scans are excluded from the benchmark. Missing or stale prices cannot trigger a hit. These remain asking-price estimates.

The table shows scan low, price target, estimated return, earlier priced days and status. The header shows scan age. Select a row to edit/remove it or click **View listings**. Exact variants open matching native listings where supported; any-suffix equipment uses a name search. Native filters still apply.

Local alerts fire at most once per watched item per completed scan; the checkbox disables them. Checks reuse saved data in bounded batches and start no auction requests. Up to 200 items can be watched per market.

## Personal ledger

The ledger is separate for each character and market. Record **Sale**, **Buy** or **Expense**, a name, quantity and the **whole transaction total** in gold. Enter fees separately. For a sale, **Actual cost** is the whole lot's known cost; leave it blank if unknown. Entering 0 means a deliberate zero cost.

- **Net** is sale total minus fees, or the negative of (purchase/expense total + fees).
- **Profit** is net sale proceeds minus recorded cost. Unknown cost shows **Needed**, with no profit assigned.
- **Recorded flow** is net sales minus purchases/expenses across retained entries; it is not a profit figure or wallet balance.
- **Known sale profit** includes only sales with a recorded cost. It does not independently allocate purchase records or standalone expenses to sold items.

Select a row to edit it, then **Record entry** to save. **Delete entry** can be reversed with **Undo delete** during the session, within retention. **Record sale** in crafting opens a draft; verify the actual payment/cost before committing it.

### AH invoices

Open a completed purchase or sale invoice in the native mailbox, then choose **Use open invoice**. Review the preview, add known cost if appropriate, and click **Record entry**. Import reads native invoice totals and fees; it never collects money/items or changes mail. Pending sale notices and ordinary mail are excluded. Entries are dated when recorded, not retroactively at the unknown sale time.

Returned deposits are retained as detail and excluded from profit and recorded flow. Record expired/cancelled deposits as expenses when known. Seller, sender, subject and mail body are not saved.

Forever's reviewed mail UI does not provide a durable mail ID. Similar invoice amounts/names/quantities and nearby expiry times are treated as a possible repeat. The duplicate index survives entry deletion and retention until the mail expires. Two legitimate identical transactions close together may need a **New manual entry** after review. This is a reviewed import, not automatic mailbox accounting.

### Retention and export

Keep **1–365 UTC calendar days**, default 90. Applying a shorter period removes older entries. The 2,000-entry limit refuses new records rather than dropping retained transactions. Copy CSV before removing records you need. Invoice identities are separately bounded at 4,000 and expire with their mail.

**Copy CSV** opens a selectable field. Press Ctrl+C and paste into a file/spreadsheet. Amounts are whole copper; unknown cost/profit stays blank. Source labels distinguish manual entries and invoice imports. Code packages never include your ledger or other SavedVariables.
