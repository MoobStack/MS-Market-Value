# Live checks

Test **1.3.0-beta / 2026-11-15-beta001**, revision **1**. Keep SavedVariables when updating. Include `/msmv diagnostics`, the action taken and any error text when reporting a problem.

Check the new features first:

- **Opportunities:** scan, search a modifier name and click its exact listing. Verify 25 units at 50s show a 12g 50s combined buyout. Try quantity limits and compare stock after a second scan.
- **Drops:** inspect several corpses of one creature, reopen one and compare counts. Test party/raid loot and a current quest item. Check that missing reference data stays labeled unavailable.
- **Farming:** collect loot and quest rewards. Compare gold, item quantities and the vendor/AH threshold. Pause/resume, reload, hide/hover and reset. Check that selling a recorded item does not add its value again.
- **Reset scope:** use a small sample to check creature, zone and dungeon resets, then compare another character.

The supplied results support successful scans/resumes, crafting, trade tips, responsive filters, daily loot and personal repairs. Continue checking less common paths as they occur:

- **Scans:** complete a scan; pause/close/reopen/resume after Local copy completes. Confirm no extra full request. Check early buffer loss and cooldown behavior separately.
- **Tooltips/history:** check the ruleset and recovered day count after updating. Complete a scan on another UTC day, then reload and confirm the day remains. Inspect single items, stacks and links, including combat.
- **Crafting:** open/close from the profession button with auto-open off. Check an item craft, service quote, missing material, vendor discount and all-recipes/search views. Verify native recipe links and commission totals.
- **Opportunities/watchlists:** apply movement/profit targets, open item and commodity listings, save/edit a Buy-page watch and check later alerts.
- **AH/mail/vendor ledger:** buy an item/commodity, load completed sale mail, collect quickly and reopen/reload. Check duplicates, multiple identical invoices, buybacks and vendor trades.
- **Trades:** receive/give gold, then cancel another trade. Reclassify a craft payment without adding it twice.
- **Loot/expenses:** loot repeatedly and after reload. Check group shares, personal/guild repairs, vendor-plus-repair updates, training, respecs, flights and successful/failed mail. Confirm correct amounts and no failed-action expense.
- **Reports/UI:** verify income minus spending equals cash flow. Compare category/date-filtered rows with CSV. Check Other multi-selects, large amounts and normal UI scale. Profit cards should keep unknown/estimated costs separate.
- **Saving:** disable/re-enable trackers independently; reload/relog and confirm settings, data and queued records. Back up before shortening retention or rolling back.

Client fonts, layering, taint/coexistence, every recipe shape and disk persistence cannot be established by fixture frames. Forever disenchant probabilities remain unverified.
