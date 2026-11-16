# MS Market Value 1.3.0 beta — Test revision 10

Same version and build: `1.3.0-beta / 2026-11-15-beta001`.

Open `/msmv drops` for the reorganized **Drop rates** page.

- Sort drops by rate from high to low (default), low to high, or expected item value.
- Show/hide Poor, Common, Uncommon, Rare, Epic and Legendary drops using colored checkboxes. These choices are independent of auction filters.
- Needed quest drops always stay visible and first, even when their rarity is hidden. Rarity filtering applies to other drops before the 1–10-item tooltip limit.
- Sort and rarity selections apply immediately and survive reload. Use Apply after changing Max items.

**Reference mode automatically includes personally observed items missing from both reference layers**, including a whole missing creature/node. Forever entries take priority, then Classic, then personal gaps. Each keeps its own rate and sample count. Personal collection works in either display mode when enabled. Already referenced items keep the reference rate; choose Personal drops to see your own rate for them. Filters, quest eligibility and the item limit can still hide an entry without deleting its observations.

The test9 Opportunities loop fix remains. Your supplied test9 diagnostics show ready results, matched build/publication counts and no pending watches.

Close WoW, replace Interface/AddOns/MSMarketValue from the Clean ZIP, and keep SavedVariables. Confirm `/msmv diagnostics` shows **Test revision: 10**. No new scan or history reset is required. Try both sort directions, deselect Common while tracking a needed quest drop, and compare Reference/Personal display. Native appearance and event timing still need in-game confirmation.

This remains a test build; nothing was pushed or officially published.
