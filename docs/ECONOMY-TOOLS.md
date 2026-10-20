# Watchlists and personal ledger

Open `/msmv` anywhere and click **Ledger** or **Watchlists**. Direct commands `/msmv ledger` and `/msmv watch` and the links from **MS Opportunities** remain available. Both tools have a **Settings** button to return. Windows hide in combat; observed transactions can still be saved.

## Watchlists

On the native Buy page, open an item and click **Watch item** in its header. Set **Buy at or below (g)**, **Min return %** and **Min profit (g)**, then **Save watch**. Opening an existing watch preserves its targets. You can also select a watchlist row to edit it, use **Watch selected** on Opportunities, or paste an item link/ID.

Zero turns a target off; all zeros means tracking only. Every enabled target must pass. Commodity/ID watches use item-wide prices; ordinary item links and Buy item headers retain the exact random suffix. Up to 200 watches are saved per market.

Buy targets need a fresh scan. Profit/return also need enough earlier priced days, using the Opportunities lookback, minimum-day setting, AH cut and conservative resale baseline. Current-day scans are excluded. Missing/stale prices cannot trigger a hit. These are asking-price estimates, not guaranteed sales.

**View listings** opens native listings at an auctioneer. Native filters still apply. Local alerts fire once per watched item per completed scan. Watch checks reuse saved data in bounded batches and start no AH requests.

## Automatic transactions

Tracking is on by default. The checkboxes under **Ledger settings** can disable AH, vendor or trade-tip tracking separately.

| Type | When it is recorded |
|---|---|
| AH buy | A captured native buyout/server quote is followed by the matching purchase success. Completed purchase invoices fill in transactions not observed live. Bids and failed requests are excluded. |
| AH sale | A completed seller invoice loads in the open mailbox. This includes sales made while logged out. Pending sale notices are excluded. |
| Vendor buy / sale | An observed merchant action produces matching bag quantities, item prices and wallet changes. Gold-only normal purchases, buybacks and sales are supported. |
| Commission | You press **Record sale** beneath a craft quote, enter a commission manually, or reclassify a trade payment. |
| Tip received / given | Both final gold offers were captured and the client reports a completed player trade. Incoming and outgoing gold stay separate. |

The addon observes these actions. It does not buy, sell, post, craft, collect mail or send chat for you. No mail bodies, counterparties or sender details are stored. Vendor trades require readable bag data; equipped-item sales, currency costs, refunds and unmatched/mixed changes may need manual entry. Repair fees and unrelated wallet changes are not vendor sales.

Purchase receipts persist for mailbox reconciliation. Reopening the mailbox, reloading, collecting mail or deleting a ledger row should not duplicate a recognised invoice. Several identical invoices visible together are counted separately; fast collection checks the matching visible group first. Forever exposes no durable invoice ID: identical transactions with nearby expiry times, removed/replaced between observations, can remain ambiguous. Review those cases manually; the addon cannot guarantee a complete audit trail from this API. Unknown purchase metadata or delayed native invoice data can also require the mailbox fallback.

Live purchases and commissions use the observation time. Mail backfills use the first recording time; the original sale/purchase time is not supplied. A mailbox-only entry is not backdated. Returned deposits are kept as detail and excluded from income, cash flow and profit. Expired/cancelled deposits are not inferred.

## Player trade gold

Trade tracking is on by default. A completed trade records gold received and gold given as separate tip entries. Accepting, closing or cancelling the window does not create a transaction. Unreadable final amounts are not guessed from wallet changes; record those manually.

The client does not say whether gold is a tip, a craft payment or another payment. For a craft payment, select the trade entry, choose **Commission** in the Type dropdown, enter its cost and save. Avoid recording the same payment again with **Record sale**. Incoming cost starts unknown; enter 0 for a pure tip. Trades do not automatically link to recipes or existing manual sales.

## Commissions

The separate box below **Craft quote** accepts:

- **Price / ea (g):** unit price received. Blank uses the quote. Variable-output recipes use price per craft.
- **Total tip (g):** added once to the transaction; default 0.
- **Quantity:** items, service applications or variable-output crafts; default 1.

**Record sale** writes the commission immediately and resets those fields. Use it for direct player sales/services; AH sales are tracked separately from invoices. With a 2g unit price, quantity 3 and a 25s tip, income is 6g 25s.

Own-material cost comes from the selected recipe and is marked **Est.** Customer-material services have zero own material cost. Missing costs stay unknown. Select the entry and enter **Actual cost** to replace an estimate. A blank actual-cost field preserves an existing craft estimate while editing other details.

## Period report and transactions

The ledger is separate for each character and market. Choose **Today**, **7 days**, **30 days**, **All retained** or **Custom**. Custom dates use `YYYY-MM-DD` in your computer’s local time, including both full days; click **Apply dates**. Dates carry across the views. Days follow local midnights, including daylight-saving changes. Saved timestamps and UTC market-history days remain unchanged.

**Period report** always covers all transaction types in that period. The top cards show income, spending and cash flow. Below them, income sources show AH sales, vendor sales, commissions and tips received; spending sources show AH purchases, vendor purchases, tips given and legacy expenses. Click a source total to open those transactions.

| Report value | Meaning |
|---|---|
| Income | AH/vendor sales, commissions and tips received, less fees |
| Spending | AH/vendor purchases, tips given and legacy expenses, including fees |
| Cash flow | Income minus spending; not a wallet balance |
| Recorded-cost profit / loss | Income minus recorded cost, for income entries with an actual cost |
| Estimated craft profit / loss | Commission income minus its saved material estimate |
| Cost coverage | Counts of income entries with recorded cost, estimated cost or cost still needed |

A profit card shows `--` when it has no costed entries. Blank cost is unknown; entering 0 deliberately records zero cost. Purchase records are not automatically allocated to sold inventory, so unknown-cost sales stay outside profit/loss. Estimates remain separate from recorded-cost profit. Fees/costs cover the whole lot; tips are separate. Changing quantity does not recalculate totals or actual cost.

**Transactions** has eight visible filters: **All**, **AH purchases**, **AH sales**, **Vendor purchases**, **Vendor sales**, **Commissions**, **Tips received** and **Tips given**. A click filters immediately. Rows show local date/time, type, item, quantity, net, cost, profit and source. Hover for full names, exact amounts, deposit detail and cost basis; click a row to edit it. The report keeps its all-type totals when a transaction filter changes.

## Edits, retention and CSV

Select a row to edit it in a separate window, then **Record entry**. The **Type** dropdown provides AH sale/buy, commission, vendor sale/buy and tip received/given choices. Draft amounts stay in place when changing type. The legacy-expense choice remains available while editing an existing legacy row. Old Expense records remain under **Legacy expenses**, accessible from the period report or Ledger settings. **Use open invoice** remains available for review, with duplicate checks. **Delete entry** has a session-only **Undo delete** within retention.

In **Ledger settings**, keep 1–365 local calendar days, default 90. Shortening retention removes older records immediately. The 10,000-entry cap refuses new records instead of discarding retained data. Export/remove old entries if full. Confirmed live transactions waiting for space keep their original timestamps in a saved queue of up to 100; free ledger space to resume recording. Queued records still follow the chosen retention period. Receipt/invoice indexes are separately bounded at 20,000; purchase receipts expire after 31 days, and invoice identities expire with the mail.

**Copy period CSV** includes all transactions in the selected period. From Transactions, **Copy filtered CSV** includes only the chosen type and period. Both open a selectable field. Press Ctrl+C to copy it. The first columns are LocalTime and UTC, so repeated DST hours remain distinguishable. Amounts are whole copper; unknown cost/profit is blank, and the cost-basis column distinguishes estimates from recorded costs. Code packages never include your SavedVariables.
