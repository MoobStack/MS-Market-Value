# MS Market Value

Auction prices, crafting profits and a personal gold ledger for **WoW Forever**.

**Version 1.2.0** · Client 1.60.1 · Interface 16001 · By MoobStack

## Install

Close WoW and extract the **Clean ZIP** into `Interface/AddOns`, so the addon is at `Interface/AddOns/MSMarketValue`. Keep your WTF/SavedVariables folder when updating. Libraries are included; no separate download is needed.

Open `/msmv` for settings, **Ledger** and **Watchlists**. At an auctioneer, the addon adds **MS Opportunities** and **MS Market Value** tabs.

## What it does

| Tool | Features |
|---|---|
| **Auction scans** | Save the full AH’s prices. Pause and resume within the same session, including after closing the AH once its local copy is complete. |
| **Item tooltips** | Vendor sell price, historic average, recent AH low and applicable disenchant estimates. Prices remain available in combat; known stack quantities show each and stack totals. |
| **Price history** | Keep 1–30 days of prices, using each UTC day’s latest completed scan. Averages use the days with available prices. |
| **Crafting profits** | Material costs, net profit after the chosen AH cut, return on cost and break-even prices. Search and rank learned recipes; include unprofitable recipes when needed. Normal vendor materials use your observed purchase price. |
| **Craft quotes** | Numeric item/service quotes with markup, labor, minimum charges and customer-supplied materials. Native recipe links where available. Copy a quote, open a chat draft or record a completed commission with price, tip and quantity. |
| **Market opportunities** | Find resale candidates, rising prices and falling prices from saved scans. Filter by price movement, return and minimum profit in decimal gold. Click an item to open its live Buy listings. |
| **Watchlists** | Add items from the Buy page or Opportunities. Edit buy-price, return and profit targets; receive local alerts after saved scans. |
| **Personal ledger** | Record AH purchases and mailbox sales, vendor trades, commissions, trade gold, daily loot and expenses such as repairs, training, respecs, postage and flights. |
| **Reports and filters** | Income, spending, cash flow and separate recorded/estimated profit totals. Filter by local dates and transaction type, combine Other expense categories, edit entries and copy filtered CSV. |

## Getting started

1. At an auctioneer, choose **MS Market Value → Scan entire AH**. Keep the AH open until **Local copy** is complete. New full scans have a 15-minute minimum interval; unfinished scans end on reload/logout.
2. Visit a supplies vendor to learn your discounted material prices. Open a profession and click **Show profits**, or use `/msmv craft`. Automatic opening is optional.
3. Check **MS Opportunities** after collecting history. Its default needs three earlier priced days per item. Use **Watch item** on the Buy page to save a target.
4. Open `/msmv ledger` anywhere outside combat. Choose a period, review totals or filter Transactions. **Other** has category checkboxes. Tracking options and 1–365-day ledger retention are in **Ledger settings**.

## Reading the numbers

AH prices are asking prices, not guaranteed sales. Crafting and resale estimates include the configured AH cut, default 5%, but exclude deposits and unsold stock. Known vendor supplies need a current vendor observation; inflated AH listings are not substituted.

The ledger records observed activity. AH sales appear when completed invoices load in the mailbox. Trade gold starts as tips; reclassify craft payments instead of recording them twice. Unknown costs remain unknown. Cash flow includes recorded spending; profit cards cover income entries with known costs. Unrecognized deductions appear as **Unclassified**.

Disenchant values use an **unverified Classic reference** for Forever. No buying, selling, crafting, mail collection or chat sending is automated.

## Help

Use `/msmv diagnostics` when reporting a problem. Include the client build, what happened and any error text.

[User guide](DOCUMENTATION.md) · [What changed in 1.2.0](CHANGELOG.md) · [Money tools](docs/ECONOMY-TOOLS.md) · [Upgrade](UPGRADE.md) · [Compatibility](COMPATIBILITY.md) · [Validation](VALIDATION.md) · [Source and recovery](GIT-WORKFLOW.md)

MoobStack is an independent community publisher, unaffiliated with Blizzard Entertainment. World of Warcraft and related marks belong to their owners.
