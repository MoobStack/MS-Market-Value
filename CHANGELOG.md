# Changelog

## 1.3.0 beta — Test revision 4 — 2026-11-15

Same version and build: `1.3.0-beta / 2026-11-15-beta001`.

- Enable farming idle pause by default at five minutes; allow 5–60 minutes or Off. Preserve later explicit choices and existing session totals.
- Load visible Opportunities colors before hover and color item names in drop tooltips. Keep native scan names and rarity in compact metadata.
- Add a rarity dropdown with checkboxes, applied before the result limit. Explain when precise modifier history is still missing.
- Allow the main window, ledger, farming report and diagnostics to open in combat. Keep native AH scans/searches deferred.
- Include a ready manifest, Windows build button and step-by-step Wowhead reference guide. Full-world coverage remains separate from the supplied Mudfin pilot.

## 1.3.0 beta — Test revision 3 — 2026-11-15

Same version and build: `1.3.0-beta / 2026-11-15-beta001`.

- Add optional farming idle pause, with whole-minute input, a five-minute minimum and automatic resume on farming receipts. Keep manual pauses separate.
- Use coin icons in displayed prices and item-quality colors in Opportunities. Keep copied quotes, CSV and diagnostics plain.
- Replace “observed corpses” with “corpses checked.” Hide quest-only drops when their quest is absent, retaining the samples.
- Confirm visible uncollected loot counts once across partial looting, reopening and reload. Keep it separate from farming income.
- Pack reference data as numeric counts, decode only viewed sources and cap the cache. Preserve rare-rate precision and source notes; the supplied pilot still covers Mudfin Oracle only.

## 1.3.0 beta — Test revision 2 — 2026-11-15

Same version and build: `1.3.0-beta / 2026-11-15-beta001`.

- Separate bonus-based item modifiers in prices, history, watchlists and live Buy navigation. Label old item-wide data instead of assigning it to a modifier.
- Show 12 Opportunities rows with scrolling, collapsible filters and an All items view. Keep at most 500 results.
- Fix the native loot-source reader and missing-GUID creature tooltips. Show an explanation when no samples exist.
- Add optional herbalism, mining and skinning tooltips, with separate sampling and farming categories.
- Explicitly exclude mail/trade receipts from farming. Add category totals and a source filter to the session report.
- Keep overlapping addon windows on separate layers. Add an offline Wowhead Forever reference importer with sample counts and source links.

## 1.3.0 beta — Test revision 1 — 2026-11-15

- Keep scanned item links and full modifier names in Opportunities.
- Add keyword, quantity and stock-decline filters, plus units and total buyout at the lowest price.
- Add short creature drop tooltips from personal observations, with quest priority and scoped resets.
- Add a farming session report and movable gold-per-hour estimate, with vendor/AH thresholds, pause/reset and recent sessions.
- Bound the new data stores and reuse cached calculations. Reference drop rates stay separate from personal samples.

## 1.2.1 — 2026-11-06

- Keep auction prices and history together when Forever assigns a different reporting host in the same market.
- Reuse compatible PvP scans still saved under earlier host names. Diagnostics show how many days were recovered.
- Keep existing ledger, watchlist and vendor profiles accessible after the market key changes.

## 1.2.0 — 2026-10-20

Build `2026-10-20-release001` · Tag `v1.2.0`

- Add **MS Opportunities** for resale candidates and rising/falling prices. Filter by movement, return and profit; open live Buy listings from a result.
- Use observed vendor purchase prices for normal vendor materials in crafting costs and quotes.
- Show net crafting profit after the chosen AH cut, return and break-even prices. Add recipe search, clearer material columns and numeric service quotes.
- Add service labor, minimum charges and customer-material pricing. Record commissions directly from craft quotes with price, tip and quantity.
- Add editable watchlists, Buy-page shortcuts and local target alerts after scans.
- Add a portable personal ledger with AH/vendor transactions, trade gold, commissions, daily loot and categorized expenses, including repairs, training, respecs, postage and flights.
- Add period reports, immediate type filters, Other category checkboxes, local dates, a transaction editor and filtered CSV. Keep actual costs, craft estimates and unknown costs separate.
- Preserve existing saved data. Rewrite the main guides and organize older release notes under `docs/history`.

The eight 1.2.0 testing revisions are included in Git history. This release keeps the tested runtime behavior and adds stable metadata, release checks and CI branch coverage.

## 1.1.0 — 2026-10-11

- Add crafting cost/profit analysis, recipe rankings and linked quotes.
- Add 1–30 days of daily price history and historic tooltip averages.
- Keep public tooltip prices visible in combat.
- Improve scan pause/resume and add profession-window controls.

## 1.0.0 — 2026-10-04

- Release full AH scans, saved tooltip prices, stack totals and Classic disenchant estimates for WoW Forever.
- Add AH settings, market detection, diagnostics and item exclusions.

Earlier testing notes are in [development history](docs/history/README.md). Exact source and documentation remain at their original Git tags.
