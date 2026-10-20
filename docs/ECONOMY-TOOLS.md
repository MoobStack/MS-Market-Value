# Watchlists and personal ledger

Open `/msmv` and choose **Watchlists** or **Ledger**. `/msmv watch` and `/msmv ledger` work outside the AH. Windows hide in combat; automatic observations can still be saved.

## Watchlists

Click **Watch item** on the Buy page, **Watch selected** on Opportunities, or paste an item link/ID. Set a maximum buy price, minimum return and minimum profit, then **Save watch**. Select a saved row to edit its targets.

Zero disables a target; all enabled targets must pass. Buy targets need fresh prices. Profit/return also need enough earlier priced days. Item links preserve their suffix; numeric IDs use item-wide prices. Up to 200 watches are saved per market. **View listings** opens native listings at an auctioneer. Alerts run locally after completed scans and send no auction request.

## What the ledger records

| Type | Source |
|---|---|
| AH purchases | Captured buyout/commodity quote plus matching success; completed mail invoices fill missing observations |
| AH sales | Completed seller invoices loaded in the mailbox, including sales made while offline |
| Vendor purchases/sales | Observed merchant actions with matching item quantities, prices and wallet changes |
| Commissions | **Record sale** below a craft quote, manual entry or a reclassified trade payment |
| Tips received/given | Readable final gold offers followed by a completed player trade |
| Loot | Dedicated loot-money messages, added to one local daily total |
| Other | Identified expenses or unrecognized outgoing wallet changes |

Tracking starts after installation. Loot is one row per character, market and local day, including reloads. Group shares use your share only; guild deposits are excluded. Its timestamp is the first recorded award that day. Earlier loot cannot be reconstructed.

Other categories include repairs, training, respecs, postage, flights, mailed gold, bank/storage, other services, manual spending, Unclassified and legacy expenses. Native details must agree with a wallet deduction; matching merchant item values can also separate repairs from a combined vendor update. Guild-funded repairs without personal cost are excluded. Failed actions without payment create no expense.

Select **Other** in Transactions and tick several categories. Select all or clear them to narrow the list. Another type ignores this category mask; **All** includes everything. Rename or categorize Unclassified entries in the editor.

## Reports and edits

Choose Today, 7 days, 30 days, All retained or inclusive custom local dates. Date boundaries follow the computer’s local calendar, including daylight-saving changes.

| Value | Meaning |
|---|---|
| Income | Recorded sales, commissions, received tips and loot, less fees |
| Spending | Purchases, given tips and Other expenses, including fees |
| Cash flow | Income minus spending; not a wallet balance |
| Recorded-cost profit/loss | Income minus actual cost, for income rows with a recorded cost; loot has zero cost |
| Estimated craft profit/loss | Commission income minus its saved material estimate |

The profit cards cover costed income entries, so they do not subtract period purchases or Other spending. Blank cost is unknown; 0 deliberately records zero cost. Purchase lots are not automatically allocated to sales. Tips and fees apply to the whole transaction; changing quantity does not recalculate totals.

Click an activity total to see its transactions. Click a row to edit it, or choose **New entry**. The Type dropdown changes its classification; Other spending also has a category dropdown. **Delete entry** has a session-only Undo. CSV exports all period rows from the report or filtered rows from Transactions, with local/UTC timestamps, copper amounts, cost basis and category.

For a craft commission, blank price uses the quote; quantity defaults to 1 and total tip to 0. With 2g per item, quantity 3 and a 25s tip, income is 6g 25s. Craft material costs remain estimates until actual cost replaces them.

Trade gold starts as tips because its purpose is unavailable. Reclassify craft payments rather than recording them twice with Record sale. Incoming cost starts unknown; use 0 for a pure tip.

## Retention and limits

Ledger settings control each tracker independently. Keep 1–365 days, default 90. The ledger holds 10,000 entries; up to 100 confirmed transactions can wait in a saved queue when full. Daily queued loot merges by day. Free space or shorten retention to continue; back up/export first.

AH sales are dated when first recorded from mail. The API supplies no original sale date or durable invoice ID, so indistinguishable replacements can remain ambiguous. Vendor currency costs, unsupported item changes and delayed/restricted wallet values may need manual review. Refundable AH deposits, active bids and trade wallet movements are excluded from generic expenses; expired deposits are not inferred. Bank deposits and mailed gold are wallet outflows even when transferring money to yourself.

No buying, selling, crafting, mail collection or trade action is automated. Mail bodies and counterparties are not stored.
