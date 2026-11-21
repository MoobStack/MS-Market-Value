# Market opportunities

Open MS Opportunities at an auctioneer. **Basis** chooses the reference for this page. Right-click it to follow the addon setting. Changing the basis rechecks saved prices.

## Views

| View | Shows |
|---|---|
| Resale | Prices meeting your drop, return and net-profit targets |
| Rising / Falling | Movement above or below the selected reference |
| All signals | The available signals together |
| All items | Current prices, including modifiers without enough history |
| Arbitrage | Compare prices for cross-house trades while at a neutral auctioneer |

Use keywords, six rarity choices and supply filters, then Apply. Keywords match every word. Zero disables a quantity limit; minimum profit accepts decimal gold, so `0.25` means 25s. The list shows 12 rows at a time and retains up to 500 matches.

Click **Sort** to switch between return and net profit per item. In Rising and Falling, **Movement** puts the largest rise or fall first. Changing the sort keeps the current filters and uses the saved scan.

## Arbitrage

Save a faction scan and a neutral scan. **Arbitrage** opens on your first visit to Opportunities at a neutral auctioneer each login. Use **Basis** to compare the latest neutral price with the exact faction average. Daily gives each saved UTC date equal weight. Intraday uses today’s faction scans. Each side needs a fresh scan with the exact item or modifier.

**Spread** measures the neutral price against the faction average. **Buy from** and **Stock** show the suggested buying house and its saved stock. The details below the list show the last scanned buy price and estimated sale price.

Profit uses the configured faction sale cut and a 15% neutral sale cut. Search, rarity, quantity, minimum profit, and return filters apply. Historical price movement and stock decline apply to the faction views. Estimates exclude deposits and depend on the item selling.

## Reading the columns

Each is the lowest unit price. At low is the number of units offered at that price; Low buyout is their combined cost. Stock is total listed quantity. Stock decline compares two completed scans and does not prove that items sold.

With **Daily avg**, Resale uses the lower quartile of earlier daily averages and Movement uses their median. With **Intraday avg**, both use the mean of today's earlier scans. Net profit subtracts the current unit cost from estimated proceeds after the AH cut. Return expresses that profit as a percentage of cost.

## History and modifiers

Daily needs three earlier priced UTC dates per exact modifier by default. Intraday needs a priced observation for that modifier in an earlier scan today. It excludes the newest scan from the reference. A date with several scans still counts as one Daily sample. Each finished date keeps its average price and releases the individual scan records.

When a baseline is missing, Net / item shows progress such as **2/3 days**. Hover or right-click for exact coverage dates. Return and Move remain unavailable until there is enough history. Enough history permits calculation; a Resale result still has to meet the price-drop, profit and return filters.

Diagnostics list the current scan date, earlier compatible dates, modifier coverage counts and a few exact keys with daily prices. Selecting a row includes that variant in the report. This helps distinguish missing samples from a filter rejection.

Left-click a faction result at a faction auctioneer to open live listings. In Arbitrage, left-click any row to check the exact item’s neutral listings. If **Buy from** says **Faction**, use those listings to check the selling market. Current rows stay clickable while item details load. Use **Watch selected** on faction results to save targets.
