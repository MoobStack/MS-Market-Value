# Market opportunities

At an auctioneer, open **MS Opportunities**, immediately before **MS Market Value**. `/msmv market` opens the same page. Opening it leaves scan requests and the full-scan cooldown alone.

- **Resale** shows candidates meeting both the minimum return and minimum net profit.
- **Rising** and **Falling** show large moves from the prior median price.
- **All signals** combines those views. Resale/all can sort by return or profit; rising/falling sort by movement.

The table shows per-item scan low, resale baseline, estimated net gain, return, movement and observed days. Green/red profit values show gains/losses. Select a row for its target buy price, prior low/high and, when available, recent median trend. Hover for the item tooltip. Pages retain the best 200 matches.

## Filters

| Setting | Default | Meaning |
|---|---:|---|
| Min return % | 20 | Minimum estimated return on purchase cost |
| Min profit (s) | 1 | Minimum net gain per item, in silver |
| AH cut % | 5 | Expected selling fee; set the rate appropriate to your AH |
| Lookback days | 14 | Calendar days before the current scan's UTC day |
| Min priced days | 3 | Earlier days with a matching buyout; adjustable from 2 to 29 |
| Price move % | 15 | Minimum change from the historical median |

Click **Apply** or press Enter. Filters are saved. Minimum return/profit filter resale candidates; trend views can include losses. **Recheck saved scan** repeats local calculations; run **Scan entire AH** in the other tab to obtain new market data. Keep enough history for the chosen window; the default minimum needs three prior priced days in addition to the current day. Missing days do not count, and repeated scans today cannot create earlier observations.

## How prices are compared

Each earlier day contributes its latest completed scan's lowest unit buyout. The current scan's UTC day is excluded from the benchmark. The **Baseline** is the lower quartile (25th percentile, interpolated then rounded down) of those earlier lows. It is deliberately more conservative than the median and reduces the influence of isolated high prices.

Estimated proceeds are `floor(baseline × (1 − AH cut / 100))`. Purchase cost rounds up to a whole copper per item. **Net / item** is proceeds minus purchase cost; **Return** is net gain divided by purchase cost. For a 1g baseline, a 5% cut and a 50s purchase, net gain is 45s and return is 90%.

The target buy price is the lower of the price meeting the return target and the price leaving the minimum profit. Both are rounded down. Deposits, expired listings and unsold inventory are outside this calculation.

**Move** compares the latest low with the prior median. It flags a high or low ask, not a guaranteed continuing trend. With five earlier priced observations, details also compare the median of the two latest observations plus the current price against the preceding three observations. Gaps in recorded days remain gaps; these are observation groups, not necessarily consecutive days.

## Data quality

Stale or future-dated scans cannot supply current signals. Matching suffixes, including ordinary suffix zero, use separate series; an item-wide fallback cannot manufacture a variant opportunity. Known vendor supplies are excluded. Auction counts and listed units do not reveal demand, completed sales or how much remains at the lowest price.

Results stay in place until a complete analysis is ready. A new scan, history change or filter change triggers a fresh calculation; reopening an unchanged page reuses its result. Work pauses when hidden or in combat. Large-data limits are reported in the status line.

Check the live listings before buying. These are candidates to investigate, not guaranteed arbitrage profits.
