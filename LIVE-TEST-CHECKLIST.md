# Live regression checks

For **1.1.0 / 2026-10-11-release001**, Forever 1.60.1 / Interface 16001.

The user reports the final beta functioning properly and successful scan resumes under multiple conditions. Supplied diagnostics show saved prices, craft valuation and one history day. The remaining checks below extend that coverage; they are not claims of completed testing.

## Upgrade and controls

- [ ] Close WoW, install the Clean ZIP and preserve WTF. Verify the release version, saved prices, history and preferences.
- [ ] With auto-open off, open Tailoring and another profession. Show profits / Hide profits and `/msmv craft` work; recipe changes respect a manual close.
- [ ] Enable auto-open, close/reopen the profession, then disable it and repeat. Check dragging, Escape, UI scales and switching to the profession overview.

## History

- [ ] Verify 1–30 day inputs, defaults and saved preferences. One day's average matches that day's unit low.
- [ ] Complete two permitted scans on the same UTC day: only the latest remains. An absent listing loses that day's sample.
- [ ] Scan on another UTC day: the average uses days with a price equally. Missing days/listings contribute no zero values.
- [ ] Reduce retention to 1 with multiple days stored: older history disappears, current prices remain. Increasing retention does not restore deleted days.
- [ ] Check automatic expiry, random suffixes, labeled item-wide fallback and separate markets.
- [ ] Reload/relog/restart normally: history and preferences survive. Partial or failed scans must not change current prices or history.

## Crafting and quotes

- [ ] Try representative recipes in each available profession, including Cooking, direct Enchanting, optional materials, multi-item output, variable yield and missing prices.
- [ ] Compare material quantities, cost, sale, profit/loss and return percentage. Profit is before fees; owned materials use market prices.
- [ ] Switch both list filters and sorts. Losses are red; unavailable values sort last. Select a row without crafting; let item data load without repeated list churn.
- [ ] Check 0% and 25% quotes, per-item quantities and the native recipe link. Insert in chat opens a draft without sending it.

## Scans and tooltips

- [ ] Hover bags, equipment, chat links and comparisons in and out of combat. Verify price order, real stack totals and no duplicate block.
- [ ] Scan, pause and resume during cooldown. Once Local copy is complete, close/reopen and resume without another request; repeat after combat.
- [ ] Lose the buffer before copying finishes: work remains paused and a fresh request waits for cooldown. Completed prices/history remain usable.
- [ ] Reload/logout ends incomplete work while retaining saved data.

For a problem, send `/msmv diagnostics`, the profession/recipe or item, exact error and a screenshot for layout issues. Capture before/after request counts for scan recovery; include UTC scan dates and retention for history.
