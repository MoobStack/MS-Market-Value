# MS Market Value 1.3.0 beta — Test revision 9

Same testing version and build: `1.3.0-beta / 2026-11-15-beta001`.

- Fix filtered Opportunities searches that keep updating after item data is briefly resolved and then becomes incomplete again.
- Keep verified item fields across automatic rebuilds and changes to keywords, rarity and view. Partial replies cannot erase previously learned fields.
- Preserve exact modifier identities, completed scans, history and all test7 farming/estimator changes. Add metadata-cache diagnostics.

Close WoW and replace `Interface/AddOns/MSMarketValue` using the Clean ZIP. Keep WTF/SavedVariables. No scan or history reset is needed. `/msmv diagnostics` should show **Test revision: 9**.

Search `pants`, change rarity and quantity filters, and switch between Resale and All items. Once any genuinely new item data has loaded, results should settle and the build/publication counters should stop increasing. If the issue persists, include the full diagnostics with the new **Market metadata cache** line.

The supplied diagnostics already find **340 matching entries, including 241 modified variants**. Of those matches, 256 need more exact-variant history and 79 are excluded by other signal criteria, leaving five Resale results. All items shows current matches without requiring enough prior days, while still applying rarity and supply filters.

This remains a test build. Native client event ordering and UI behavior need in-game confirmation. Nothing was pushed or officially published.
