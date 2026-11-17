# MS Market Value 1.3.1-beta — Test revision 1

Build `2026-11-16-beta001`. This is a test build, not the final 1.3.1 release.

## Changes

- Count reliably identified empty corpses in personal drop samples, once per body. Skinning remains separate; reference percentages are unchanged.
- Choose saved farming sessions from a menu showing date, duration and value. Return directly with Current session or reopen `/msmv farm`.
- Keep quest rewards in the session total by default. A new setting can include them in hourly rates or stop recording new rewards. Peaks always exclude quests.
- Reconcile generic loot messages with quest reward events so rewards count once, even when the messages arrive in a different order.
- Exclude vendor and buyback receipts from farming. An item counts when acquired; later sale proceeds remain in the ledger.
- Hide custom drop sections while loot is open and replace changed tooltip sections cleanly, preventing stacked corpse/skinning lists outside the border.

## Install and test

Close WoW, back up SavedVariables and replace the MSMarketValue folder with the Clean ZIP. Keep your existing SavedVariables. Diagnostics should show 1.3.1-beta, test revision 1.

1. In `/msmv drops`, choose Personal drops. Inspect several empty and nonempty bodies of the same creature in one area. Check that the denominator increases once per body, including empties; reopening a body must not add another sample.
2. Pick a saved farming session from the menu, then click Current session. Try Items, closing/reopening the report and Reset session.
3. Loot an item, note the session value, then sell it. Farming value should not rise from the sale; the ledger should record the sale separately.
4. Turn in a quest with gold and an item. Each should count once in the total. Try both hourly choices. Compare completed five-minute peaks before and after the turn-in; quests must never set a peak.
5. Skin and loot a creature while its tooltip is visible. Custom drop rows should disappear while looting and return within the tooltip after it closes.

Totals, elapsed time and observations carry forward. Recent and peak coverage restarts on upgrade, and older unverifiable saved rates show Not recorded. Earlier misclassified totals are retained; start a new session for a clean comparison. Previously missed empty bodies cannot be backfilled.

Local fixture checks cover these paths. Native event timing and appearance still need in-game confirmation. If a check fails, include `/msmv diagnostics` and the steps that led to it.
