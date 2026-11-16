# Market opportunities

Open MS Opportunities at an auctioneer. It compares the latest completed scan with earlier daily prices without requesting another full scan.

## Views

| View | Shows |
|---|---|
| Resale | Prices meeting your drop, return and net-profit targets |
| Rising / Falling | Movement above or below the earlier median |
| All signals | The available signals together |
| All items | Current prices, including modifiers without enough history |

Use keywords, six rarity choices and supply filters, then Apply. Keywords match every word. Zero disables a quantity limit; minimum profit accepts decimal gold, so `0.25` means 25s. The list shows 12 rows at a time and retains up to 500 matches.

## Reading the columns

Each is the lowest unit price. At low is the number of units offered at that price; Low buyout is their combined cost. Stock is total listed quantity. Stock decline compares two completed scans and does not prove that items sold.

Resale uses the lower quartile of earlier daily lows, less the configured AH cut, to estimate proceeds. Net profit subtracts current unit cost; Return expresses it as a percentage. Movement compares the current low with the earlier median. Deposits and unsold listings are excluded.

## History and modifiers

The default needs three earlier priced UTC days for each exact modifier. Several scans on one UTC day still count as one day. The market's saved-day total can be higher than an individual modifier's sample count. Older item-wide equipment history is retained but cannot supply a precise modifier baseline.

Updating results keeps the previous list visible until the new one is ready. Item data is reused across filter changes. Left-click a row for live listings, right-click for details, or Watch selected to save targets. Stale scans and missing prices do not produce fresh resale signals.
