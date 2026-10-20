# MS Market Value 1.2.0 beta

Build `2026-10-20-beta001` · Test revision **1**

- Crafting uses your observed vendor purchase cost for normal vendor materials, including discounts and purchase bundles. Costs feed recipes, rankings and quotes; AH markups no longer replace a known vendor price.
- **MS Opportunities** appears before the existing AH tab. Find resale candidates, rising/falling prices and target buy prices from saved daily history.
- Set minimum return, net profit, AH cut, lookback and significant movement. Results use a conservative historical baseline, separate item variants and skip stale scans.
- Analysis is local, bounded and cached. The complete list updates together; it makes no auction requests or purchases.

Close WoW, install the Clean ZIP's addon folder and keep SavedVariables. Visit a supplies vendor to learn the prices offered to your character. Known supplies without a usable observation say **visit supplier**. The market tool defaults to three earlier priced days per item; same-day scans do not add days.

For Forever 1.60.1 / Interface 16001. **291/291 local Lua 5.1 tests pass**; the new features need in-game confirmation. The full Git repository includes all docs, tests and earlier history. Asking prices do not guarantee sales; estimated net excludes deposits and unsold stock.
