# Watchlists and personal ledger

Use `/msmv watch` and `/msmv ledger`, or open either tool from **MS Opportunities**. Both windows hide in combat; observed transactions can still be saved.

## Watchlists

On the native Buy page, open an item and click **Watch item** in its header. Set **Buy at or below (g)**, **Min return %** and **Min profit (g)**, then **Save watch**. Opening an existing watch preserves its targets. You can also select a watchlist row to edit it, use **Watch selected** on Opportunities, or paste an item link/ID.

Zero turns a target off; all zeros means tracking only. Every enabled target must pass. Commodity/ID watches use item-wide prices; ordinary item links and Buy item headers retain the exact random suffix. Up to 200 watches are saved per market.

Buy targets need a fresh scan. Profit/return also need enough earlier priced days, using the Opportunities lookback, minimum-day setting, AH cut and conservative resale baseline. Current-day scans are excluded. Missing/stale prices cannot trigger a hit. These are asking-price estimates, not guaranteed sales.

**View listings** opens native listings at an auctioneer. Native filters still apply. Local alerts fire once per watched item per completed scan. Watch checks reuse saved data in bounded batches and start no AH requests.

## Automatic transactions

Tracking is on by default. The ledger checkboxes can disable AH or vendor tracking separately.

| Type | When it is recorded |
|---|---|
| AH buy | A captured native buyout/server quote is followed by the matching purchase success. Completed purchase invoices fill in transactions not observed live. Bids and failed requests are excluded. |
| AH sale | A completed seller invoice loads in the open mailbox. This includes sales made while logged out. Pending sale notices are excluded. |
| Vendor buy / sale | An observed merchant action produces matching bag quantities, item prices and wallet changes. Gold-only normal purchases, buybacks and sales are supported. |
| Commission | You press **Record sale** beneath a craft quote, or enter a commission manually. |

The addon observes these actions. It does not buy, sell, post, craft, collect mail or send chat for you. No mail bodies, counterparties or sender details are stored. Vendor trades require readable bag data; equipped-item sales, currency costs, refunds and unmatched/mixed changes may need manual entry. Repair fees and unrelated wallet changes are not vendor sales.

Purchase receipts persist for mailbox reconciliation. Reopening the mailbox, reloading, collecting mail or deleting a ledger row should not duplicate a recognised invoice. Several identical invoices visible together are counted separately; fast collection checks the matching visible group first. Forever exposes no durable invoice ID: identical transactions with nearby expiry times, removed/replaced between observations, can remain ambiguous. Review those cases manually; the addon cannot guarantee a complete audit trail from this API. Unknown purchase metadata or delayed native invoice data can also require the mailbox fallback.

Live purchases and commissions use the observation time. Mail backfills use the first recording time; the original sale/purchase time is not supplied. A mailbox-only entry is not backdated. Returned deposits are kept as detail and excluded from income, cash flow and profit. Expired/cancelled deposits are not inferred.

## Commissions

The separate box below **Craft quote** accepts:

- **Price / ea (g):** unit price received. Blank uses the quote. Variable-output recipes use price per craft.
- **Total tip (g):** added once to the transaction; default 0.
- **Quantity:** items, service applications or variable-output crafts; default 1.

**Record sale** writes the commission immediately and resets those fields. Use it for direct player sales/services; AH sales are tracked separately from invoices. With a 2g unit price, quantity 3 and a 25s tip, income is 6g 25s.

Own-material cost comes from the selected recipe and is marked **Est.** Customer-material services have zero own material cost. Missing costs stay unknown. Select the entry and enter **Actual cost** to replace an estimate. A blank actual-cost field preserves an existing craft estimate while editing other details.

## Filters and reports

The ledger is separate for each character and market. Select **All transactions**, AH sales, AH purchases, commissions, vendor sales, vendor purchases or legacy expenses. Choose **Today**, **Last 7 days**, **Last 30 days**, **All retained** or **Custom dates**. Custom dates use `YYYY-MM-DD` in UTC, including both full days; click **Apply dates**.

Rows show UTC date/time, type, item, quantity, net, cost, profit and source. Hover for the full name, exact amounts, tip, deposit detail and cost basis. Every report and CSV export follows the current type/date filters.

- **Income:** sale/commission/vendor-sale amount plus tip, less fees.
- **Spending:** purchase and legacy-expense amounts plus fees.
- **Cash flow:** income minus spending. It is neither profit nor a wallet balance.
- **Known P/L:** income entries with a recorded cost, excluding estimated costs.
- **Est. craft P/L:** commission income minus its saved material estimate.
- **Cost needed:** income with no usable cost. Blank is unknown; entering 0 deliberately records zero cost.

Purchase records are not automatically allocated to sold inventory. Sales with unknown costs do not acquire a profit just because another purchase exists. Fees/costs cover the whole lot; the tip is separate. Changing a row's quantity does not recalculate its total or actual cost.

## Edits, retention and CSV

Select a row to edit it, then **Record entry**. **New manual entry** provides AH sale/buy, commission and vendor sale/buy types. Old Expense records remain under **Legacy expense**. **Use open invoice** remains available for review, with duplicate checks. **Delete entry** has a session-only **Undo delete** within retention.

Keep 1–365 UTC calendar days, default 90. Shortening retention removes older records immediately. The 10,000-entry cap refuses new records instead of discarding retained data. Export/remove old entries if full. Confirmed live transactions waiting for space keep their original timestamps in a saved queue of up to 100; free ledger space to resume recording. Queued records still follow the chosen retention period. Receipt/invoice indexes are separately bounded at 20,000; purchase receipts expire after 31 days, and invoice identities expire with the mail.

**Copy CSV** opens a selectable field. Press Ctrl+C to copy it. Amounts are whole copper; unknown cost/profit is blank, and the cost-basis column distinguishes estimates from recorded costs. Code packages never include your SavedVariables.
