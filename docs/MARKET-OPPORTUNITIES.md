# Market opportunities

At an auctioneer, **MS Opportunities** appears before **MS Market Value**. It compares the latest completed scan with earlier saved days; opening the page does not request another full scan.

## Views and filters

- **Resale:** current prices below a conservative historical baseline, after the chosen AH cut.
- **Rising / Falling:** significant movement above/below the earlier median.
- **All signals:** the available signals together.
- **All items:** current modifier prices, including those without enough earlier history for a signal.

Set lookback, minimum priced days, AH cut, price movement, minimum return and minimum profit, then **Apply**. Defaults are 14 days, three earlier priced days, 5% cut, 15% movement and 20% return. Profit accepts decimal gold with up to four places: `0.25` is 25s.

Resale requires the price drop, return and profit thresholds to pass. Movement `0` disables its drop check. Same-day scans do not add history days. Stale scans, missing prices and known vendor supplies do not produce resale candidates.

Under **Filters → Rarity**, check Poor, Common, Uncommon, Rare, Epic or Legendary, then Apply. Each label uses its rarity color. All six is the default; selecting none gives no results. The filter applies before the 500-result limit. Item colors load for visible rows without needing a hover.

## Calculations

| Value | Basis |
|---|---|
| Resale baseline | Lower quartile of earlier daily lows |
| Expected proceeds | Baseline less the configured AH cut, rounded down |
| Current unit cost | Latest unit low, rounded up |
| Net profit | Expected proceeds minus current unit cost |
| Return | Net profit divided by current unit cost × 100 |
| Price movement | Current low compared with the earlier median |

Matching random-suffix series stay separate. With enough observations, recent-versus-older median context helps show a broader trend. Results are capped at 500 and publish together; unchanged settings reuse cached analysis.

**Updating results** is active preparation. The previous list remains visible until the new list is ready. Work is spread across frames. Current scans reuse their variant index between filter changes, and keyword/supply checks run before historical valuation. Item replies only queue another analysis when usable name, rarity or item-class data changes. Verified item fields stay cached across automatic rebuilds and filter changes for the same completed scan. Incomplete or evicted native data cannot erase them and restart the same search indefinitely. The cache resets with a replacement scan or market change, stays outside SavedVariables and caps at 50,000 identities. Visible names/colors are reused between refreshes.

Left-click a result to open native live listings; right-click for details. **Watch selected** creates or edits its target. Live navigation requires an auctioneer, no combat and usable current results. Native Buy filters still apply.

These are asking-price signals. Scans record units at the low and their combined buyout, but cannot establish demand, future sale prices or the chance of a sale. Deposits and unsold listings are excluded. Check live listings before deciding to buy; purchases remain under your control.

## Modifier prices and browsing

Random suffixes and bonus-based variants have independent series. A specific modifier never borrows another modifier’s price history. Older suffix-zero equipment history may contain several modifiers; it stays saved but does not become a precise baseline. Complete new scans on later UTC days to build that history.

**All items** shows current prices even without enough history. The list shows 12 rows with a scrollbar and mouse wheel, keeping at most 500 matching results. **Filters** opens the extra fields; applying them returns to the larger list. Keyword search is always visible. Select or hover a shortened name to see the full modifier.

Use **All items** and search `pants` to browse current matching modifiers immediately. This still respects keyword, rarity and supply filters. With only one precise daily scan, signals may be absent. The default Resale view needs three earlier priced UTC days **for that exact variant**. The saved-day count at the top is market-wide. Eleven saved days do not imply eleven prices for every modifier; an old item-wide day cannot establish which modifier moved. Even with enough days, Resale still requires its return, profit and movement targets.

Clicking a bonus-based variant uses the native sample link to find its exact Buy key. If details are still loading, the addon waits briefly rather than guessing a different modifier. You still choose and purchase listings yourself.

If results are missing, diagnostics now show current/modified variant counts, matching variants, entries needing history and entries excluded by the other signal filters. Test revision 9 uses the existing scan format and keeps saved data.
