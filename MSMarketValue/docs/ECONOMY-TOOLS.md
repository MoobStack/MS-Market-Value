# Watchlists and the ledger

## Watchlists

Use Watch item on the AH Buy page, Watch selected on Opportunities, or `/msmv watch`. Set a maximum buy price, minimum return or minimum profit. Zero disables a target; all enabled targets must pass. Item links track the exact modifier, while a numeric ID uses item-wide prices.

Targets use saved scans. Profit and return also need earlier history. Alerts are local and do not request another auction search. View listings requires an auctioneer and usable current prices.

## Recorded activity

Open `/msmv ledger` to review AH and vendor purchases/sales, commissions, trade gold, daily loot and expenses. Tracking can be enabled separately for each source.

AH sales appear when completed seller invoices load in the mailbox. Trade gold starts as tips; reclassify a craft payment instead of recording it twice. Loot is combined into one local daily total. Other includes identified spending such as repairs, training, respecs, postage and flights; unclear deductions can appear as Unclassified.

Tracking starts after installation and depends on readable game confirmations. Earlier activity cannot be reconstructed. Some identical mail invoices remain ambiguous; review unusual entries manually.

## Reports and editing

Choose a period using local dates. Period report covers all activity; Transactions filters by type, and Other has category checkboxes. Click a row to edit it outside combat. New entry adds a manual record. Delete has a session-only Undo. CSV follows the selected dates and filters.

| Figure | Meaning |
|---|---|
| Income | Recorded sales, commissions, received tips and loot, less fees |
| Spending | Purchases, given tips and expenses, including fees |
| Cash flow | Income minus spending |
| Recorded-cost profit | Income minus actual cost for costed income entries |
| Estimated craft profit | Commission income minus its saved material estimate |

Blank cost means unknown; zero deliberately records no cost. Purchase lots are not automatically assigned to later sales. Profit totals do not subtract unrelated period purchases or Other spending. Tips and fees apply to the whole transaction.

Keep 1–365 local days, default 90, up to 10,000 entries. Export or back up before shortening retention. Reports remain readable in combat; editing waits until combat ends.
