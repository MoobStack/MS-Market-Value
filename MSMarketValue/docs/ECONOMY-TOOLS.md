# Watchlists and the ledger

## Watchlists

Use Watch item on the AH Buy page, Watch selected on Opportunities, or `/msmv watch`. Add watch also accepts a pasted or dragged item link. Item IDs are not needed. Existing broader watches still follow the lowest item-wide price; equipment choices and pasted links retain their exact modifier.

Search filters the items already on your watchlist by name. Use the AH Buy page to find new items, then Watch item to add one. Enable Targets met only or click a column heading to sort. The list scrolls with the mouse wheel or native scrollbar. Target status comes first by default, with the largest discount to the buy target first among matching rows. Item names use rarity colors; a separate TARGET MET marker and subtle row highlight identify matches.

Left-click a row to open its native Buy page. Broader equipment watches open a name search so you can choose the modifier. Right-click or Edit opens the target dialog, which also contains Remove watch. Set a maximum buy price, minimum return or minimum profit, all per item. Price/profit inputs are gold amounts. Zero turns a target off, and all enabled targets must pass. All zero means tracking only.

| Column | Meaning |
|---|---|
| Scan each | Lowest unit asking price in the saved scan |
| Buy target | Your maximum unit purchase price, or Off |
| Net / item | Estimated resale proceeds after the AH cut, less the scan price |
| Return | Estimated net profit divided by the scan price |
| Status | Target met, watching, tracking, missing history or a scan/listing gap |

Profit and return follow **Price settings**. Daily compares with earlier priced UTC dates, and Intraday compares with earlier scans today. A buy-price-only target can match after one scan. Hover for targets, sample counts, listed units and the difference from your buy target. Review live listings before buying. Keep up to 200 watches per market.

Watch settings stays within the watchlist. By default, new matches or lower matched prices can open one grouped review after a scan or on an AH visit. Reviewed results stay quiet across repeat visits, unchanged scans and reloads. A fresh scan showing a watch out of target or unlisted rearms it for a later match. An already-open watchlist updates in place.

Reviews wait during combat, selling, purchase confirmation, typing or editing. They use saved scans without background auction searches. Chat summaries are optional and off by default. Turn off Watchlist alerts to keep just the passive target count and row highlights. Existing disabled-alert choices are preserved.

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
