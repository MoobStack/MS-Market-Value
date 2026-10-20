# Market opportunities

At an auctioneer, open **MS Opportunities**, immediately before **MS Market Value**. `/msmv market` opens the same page. Opening it leaves scan requests and the full-scan cooldown alone.

- **Resale** shows candidates meeting minimum return, minimum net profit and the required price drop.
- **Rising** and **Falling** show large moves from the prior median price.
- **All signals** combines those views. Resale/all can sort by return or profit; rising/falling sort by movement.

The table shows per-item scan low, resale baseline, estimated net gain, return, movement and observed days. Green/red profit values show gains/losses. Left-click a row to open its native live item or commodity listings. Right-click for its target buy price and history range; hovering shows those details and the item tooltip. Pages retain the best 200 matches.

## Filters

| Setting | Default | Meaning |
|---|---:|---|
| Min return % | 20 | Minimum estimated return on purchase cost |
| Min profit (g) | 0.01 | Minimum net gain per item, in gold; 0.25 means 25s |
| AH cut % | 5 | Expected selling fee; set the rate appropriate to your AH |
| Lookback days | 14 | Calendar days before the current scan's UTC day |
| Min priced days | 3 | Earlier days with a matching buyout; adjustable from 2 to 29 |
| Price move % | 15 | Minimum drop for Resale; directional change for Rising/Falling; 0 disables the resale check |

Click **Apply filters** or press Enter. Filters are saved. Gold accepts up to four decimal places (one copper), from 0 to 10,000g. Existing targets retain their value. Edited fields stay intact when focus moves or the page refreshes; Escape restores the focused field.

Resale must pass all three checks: net profit, return and price drop from the prior median. A 50% drop passes a 40% threshold but fails 60%. A positive price cannot fall by 100% or more, so a 500% threshold produces no Resale results. With movement set to 0, Rising/Falling still require a change in their respective direction. Trend views can include losses; profit targets apply only to Resale. All signals combines those rules. **Recheck saved scan** repeats local calculations; run **Scan entire AH** in the other tab to obtain new market data. Keep enough history for the chosen window; the default minimum needs three prior priced days in addition to the current day. Missing days do not count, and repeated scans today cannot create earlier observations.

## How prices are compared

Each earlier day contributes its latest completed scan's lowest unit buyout. The current scan's UTC day is excluded from the benchmark. The **Baseline** is the lower quartile (25th percentile, interpolated then rounded down) of those earlier lows. It is deliberately more conservative than the median and reduces the influence of isolated high prices.

Estimated proceeds are `floor(baseline × (1 − AH cut / 100))`. Purchase cost rounds up to a whole copper per item. **Net / item** is proceeds minus purchase cost; **Return** is net gain divided by purchase cost. For a 1g baseline, a 5% cut and a 50s purchase, net gain is 45s and return is 90%.

The target buy price is the lower of the price meeting the return target and the price leaving the minimum profit. Both are rounded down. Deposits, expired listings and unsold inventory are outside this calculation.

**Move** compares the latest low with the prior median. It flags a high or low ask, not a guaranteed continuing trend. With five earlier priced observations, details also compare the median of the two latest observations plus the current price against the preceding three observations. Gaps in recorded days remain gaps; these are observation groups, not necessarily consecutive days.

## Data quality

Stale or future-dated scans cannot supply current signals. Matching suffixes, including ordinary suffix zero, use separate series; an item-wide fallback cannot manufacture a variant opportunity. Known vendor supplies are excluded. Auction counts and listed units do not reveal demand, completed sales or how much remains at the lowest price.

Results stay in place until a complete analysis is ready. A new scan, history change or filter change triggers a fresh calculation; reopening an unchanged page reuses its result. Work pauses when hidden or in combat. Large-data limits are reported in the status line.

A left-click uses the native Buy search only while the auctioneer is open, outside combat, with current results and applied filters. Item variants keep their suffix where exact-key support is available; a native name search is the fallback. Native filters can narrow the listings. A busy AH needs another click later; lookups are never queued. Wait until an unfinished full scan has its complete local copy before searching. This does not request a full scan or reset its cooldown.

Check the live listings before buying. These are candidates to investigate, not guaranteed arbitrage profits.
