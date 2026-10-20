# MS Market Value 1.2.0 beta

Build `2026-10-20-beta001` · Test revision **5**

- Add **Watch item** to the native Buy item/commodity headers, with editable targets and existing-watch values.
- Record crafting commissions directly below the quote: optional unit price, total tip and quantity. Blank price uses the quote; quantity defaults to 1, tip to 0.
- Track confirmed AH purchases and completed mailbox invoices, reconciling purchases instead of counting them twice. Track vendor trades when bag quantities and money agree.
- Add transaction-type and UTC date filters, filtered CSV and separate income, spending, cash-flow, known-profit and estimated-crafting reports.
- Retain legacy expenses, increase ledger capacity to 10,000, and cache/batch the new work.

**446/446 local Lua 5.1 tests pass.** Automatic tracking, mailbox event ordering and native layout still need Forever testing. Sales/backfills are dated when first recorded from mail; identical invoices replaced between observations can require manual review. Material estimates are labeled and unknown costs do not become zero.

Close WoW, replace the addon folder using the Clean ZIP and keep SavedVariables. Use `/msmv watch` and `/msmv ledger`. The full repository includes all documentation and earlier tags.
