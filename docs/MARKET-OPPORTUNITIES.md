# Market opportunities

At an auctioneer, **MS Opportunities** appears before **MS Market Value**. It compares the latest completed scan with earlier saved days; opening the page does not request another full scan.

## Views and filters

- **Resale:** current prices below a conservative historical baseline, after the chosen AH cut.
- **Rising / Falling:** significant movement above/below the earlier median.
- **All signals:** the available signals together.

Set lookback, minimum priced days, AH cut, price movement, minimum return and minimum profit, then **Apply**. Defaults are 14 days, three earlier priced days, 5% cut, 15% movement and 20% return. Profit accepts decimal gold with up to four places: `0.25` is 25s.

Resale requires the price drop, return and profit thresholds to pass. Movement `0` disables its drop check. Same-day scans do not add history days. Stale scans, missing prices and known vendor supplies do not produce resale candidates.

## Calculations

| Value | Basis |
|---|---|
| Resale baseline | Lower quartile of earlier daily lows |
| Expected proceeds | Baseline less the configured AH cut, rounded down |
| Current unit cost | Latest unit low, rounded up |
| Net profit | Expected proceeds minus current unit cost |
| Return | Net profit divided by current unit cost × 100 |
| Price movement | Current low compared with the earlier median |

Matching random-suffix series stay separate. With enough observations, recent-versus-older median context helps show a broader trend. Results are capped at 200 and publish together; unchanged settings reuse cached analysis.

Left-click a result to open native live listings; right-click for details. **Watch selected** creates or edits its target. Live navigation requires an auctioneer, no combat and usable current results. Native Buy filters still apply.

These are asking-price signals. The addon does not know demand, how much stock is available at the low, future sale prices or the chance of a sale. Deposits and unsold listings are excluded. Check live listings before deciding to buy; purchases remain under your control.
