# MS Market Value 1.3.1-beta — Test revision 5

Build `2026-11-16-beta001`. This remains a test build.

## Watchlist changes

- Ten scrolling rows replace page buttons. Search by name, filter to targets met and click column headings to sort. Target status comes first by default.
- Item names use rarity colors. Target-met text and a subtle row highlight identify matches independently of rarity. Net profit and return are visible together; hover for history, units and full targets.
- Left-click a row for its native Buy page. Right-click or Edit opens a separate target dialog, including Remove watch. Visible item IDs are gone; add items from Buy/Opportunities or paste/drag an item link.
- Watch settings controls notifications without opening the main addon settings. A passive target count remains available even with alerts off.

Prices and profit targets are gold amounts per item. Zero turns a target off, and all enabled targets must pass. A buy-price-only target needs no prior history. Profit and return targets still require the configured exact-history coverage. Existing watches, targets and modifier choices are kept.

## Quiet alerts

By default, a new match or lower matched price can open one grouped review after a scan or on AH entry. Chat summaries are optional and off by default. Reviewed matches stay quiet through unchanged scans, repeat visits and reloads. A fresh scan showing a watch out of target or unlisted rearms it for a later match.

Reviews wait while you are in combat, selling, confirming a purchase, typing or editing. An open watchlist updates in place. When opening a hidden watchlist, the review scrolls to a matching item and clears an older search only if it hides every new match. No auction search runs until you click an item.

Viewing matching results counts as review, including when you add or edit a watch with the list already open. Existing disabled-alert preferences remain disabled. Watch settings can turn off automatic opening or enable a single chat summary instead.

## Install and check

Close WoW, back up SavedVariables and replace the MSMarketValue folder using the Clean ZIP. Keep SavedVariables. Diagnostics should show test revision 5.

1. Open `/msmv watch`. Check names, targets, net/return columns and status colors. With more than ten watches, try the wheel and scrollbar. Search, use Targets met only and reverse a column sort.
2. At the AH, left-click an item and confirm its Buy page opens. Check an exact modifier as well as a commodity. Right-click or Edit must open targets without starting a search.
3. Edit a target, save it and reopen it. Check the same item/modifier is retained. Try Add watch with a linked item. Watch settings should stay within the watchlist; ledger settings still works as before.
4. Verify a newly met target or lower matched price produces one quiet review after a scan or AH visit. Dismissing and revisiting unchanged results should not reopen it. Check deferral while selling or editing, and confirm disabling alerts leaves the passive count/highlights available.

The supplied test revision 4 logs show both Sell arrow controls installed, farming rates recording with no ignored money messages, and only two earlier exact-variant dates. That supports the prior fixes; it does not yet provide three-date resale baselines.

Native watchlist appearance, row navigation and alert timing on client 1.60.1 / 70959 still need in-game confirmation. Include diagnostics if a review repeats unexpectedly or an item opens the wrong Buy page.
