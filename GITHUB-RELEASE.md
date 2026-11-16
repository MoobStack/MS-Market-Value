# MS Market Value 1.3.0 beta — Test revision 8

Same testing version and build: `1.3.0-beta / 2026-11-15-beta001`.

- Fix repeated Opportunities refreshes after searches and filter changes. Duplicate item replies no longer trigger another full analysis.
- Use available names and rarity even when vendor metadata is missing. Cache visible-row data and keep background checks bounded.
- Preserve exact modifier identities and add diagnostics for history gaps and other signal filters.

Use **All items** with `pants` to browse current matching variants. **Resale** requires three earlier priced UTC days for each exact variant by default, plus its profit and movement targets. The market-wide saved-day count is not each variant’s sample count.

Close WoW and replace the addon folder using the Clean ZIP. Keep SavedVariables. No scan/history reset is needed. `/msmv diagnostics` should show **Test revision: 8**.

Apply several keyword/rarity changes, wait for results, and check that build/publication counts settle. Compare All items with Resale. If a variant is still missing, include diagnostics showing the current-modifier and history/filter counts.

This remains a test build; no official 1.3 release was published.
