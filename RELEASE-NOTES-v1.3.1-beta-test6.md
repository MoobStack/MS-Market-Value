# MS Market Value 1.3.1-beta — Test revision 6

Build `2026-11-16-beta001`. This remains a test build.

## Changes

- Larger Sell-page buttons: each is now 28×24 instead of 18×16, with a red panel-button background and a clear native AH arrow icon. The pair stays centered beside copper.
- The native price warning sits below the copper field to keep the wider buttons clear of the listing pane. Each click still changes the unit price by one copper, with normal silver/gold rollover and total updates.
- Watchlist search is retained. It filters items already on your watchlist; a new tooltip explains this. Use the Buy page to find other items and Watch item to add them.

Existing prices, watches, targets, modifier choices, sessions, observations and alert preferences are kept.

## Install and check

Close WoW, back up SavedVariables and replace the MSMarketValue folder using the Clean ZIP. Keep SavedVariables. Diagnostics should show test revision 6.

1. On the Sell page, check that the red buttons are easy to click, point in the correct directions and fit beside copper. Check both commodities and equipment.
2. With quantity 4 and a unit price of 10c, one up-click should give 11c and a 44c total. Down should return to 10c and 40c. Also check both directions across 99c/1s and 99s 99c/1g.
3. At zero, the down button should be disabled and its icon dimmed. Manual edits and repeated AH visits should still work. If a native price warning appears, check its placement and tooltip below copper.
4. On the watchlist, search for part of a watched name. Only matching watches should appear; clearing the field restores the list. Finding a new item still happens on the native Buy page.

Native button appearance and spacing on client 1.60.1 / 70959 still need in-game confirmation. Include a Sell-page screenshot and diagnostics if a button or warning overlaps another control.
