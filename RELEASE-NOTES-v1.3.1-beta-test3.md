# MS Market Value 1.3.1-beta — Test revision 3

Build `2026-11-16-beta001`. This remains a test build.

## Changes

- Keep an exact modifier's latest priced observation for its UTC day when a later scan no longer lists it. Current listings still use the newest scan, and samples never carry into another date.
- Show exact-history progress, such as 2/3 days, where a missing baseline previously appeared as a blank net value. Hover or right-click for priced UTC dates.
- Add diagnostic coverage counts, the scan date and sample exact-variant keys with their daily prices. A selected row is included in the report.
- Recover farming after missing quest, merchant, mail or trade close events. Use native window visibility and world transitions; clear stale quest context on turn-in, combat and real world loot.
- Keep quest echo protection, transaction exclusions, manual/death pause and quest-free peaks. Diagnostics now identify why money messages were excluded.

## Understanding the November 17 report

Exact modern bonus-variant tracking entered this code on November 15. For a November 17 scan, only November 15 and 16 can be earlier dates from that format. The default needs three earlier priced UTC dates for the same variant. Today's scan and several scans on one day cannot supply another earlier day. The market's 12-day total includes older item-wide prices.

November 18 is the earliest possible qualifying date if that exact variant was priced on November 15, 16 and 17 and is scanned again on November 18. Missing listings can make coverage lower. Once history is sufficient, Resale still requires the configured profit, return and movement targets. Defaults are unchanged.

A same-day scan previously replaced the whole daily variant map. This could erase a priced modifier after it disappeared from later listings, reducing its coverage on subsequent days. The fix retains those exact observations going forward. Previously discarded observations cannot be reconstructed from these logs.

The supplied logs do not contain the actual saved keys or their daily prices. The new report makes those values visible so a key mismatch or missing samples can be checked directly.

## Install and check

Close WoW, back up SavedVariables and replace the MSMarketValue folder using the Clean ZIP. Keep SavedVariables; existing prices, history, sessions and observations are retained. Diagnostics should show test revision 3.

1. At the AH, complete a scan and search All items for `of the`. Check each row's day count. Hover or right-click a variant to see its earlier UTC dates.
2. With a representative variant selected, copy diagnostics. The Market history window, modified prior days and history sample lines show the coverage used by the calculation.
3. Use a new farming session for a clean comparison. Turn in a quest, then fight and loot. Ordinary gold/items should appear under Loot, and the recent rate should reflect them. A completed five-active-minute window can set a farming peak; quests must not raise it.
4. Visit and leave a vendor, mailbox or trade, then return to farming. Purchases/transfers should stay excluded, while subsequent world loot counts normally.

A local replay reproduced all 19 later money awards being ignored by test revision 2 after a missing quest close. The fix counted them and kept quest gold out of the peak. Another replay recovered farming after a missing merchant close. Native behavior still needs confirmation. Earlier missed or misclassified receipts cannot be repaired from the diagnostics alone.
