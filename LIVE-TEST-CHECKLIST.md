# Live checks

Test **1.3.0-beta / 2026-11-15-beta001**, revision **5**. Keep SavedVariables when updating. Include `/msmv diagnostics`, the action taken and any error text when reporting a problem.

Check the new features first:

- **Idle:** confirm five minutes is enabled by default; stop looting and check the whole grace period counts. Loot gold or an item to resume. Try 60, reject 61, disable/reload and check the preference. Manual pauses, mail and trades must not resume it.
- **Prices/colors:** compare green/blue items with Opportunities rows before hovering. Select several Rarity checkboxes, Apply, then try All/None. Check drop tooltip name colors and coin icons at normal UI scale. Copy a quote and CSV; both should remain plain text.
- **Combat:** first open `/msmv`, ledger, farming and diagnostics during combat. Check periods and ledger filters; verify scans/live AH searches wait until combat ends. Repeat with the AH already open and check for taint errors.
- **Quest loot:** open a corpse, leave an item, close/reopen and compare counts. Pick up only one item and verify farming values only that receipt. Check an active quest item, then abandon/complete the quest and rehover; ordinary trade goods should remain visible.

- **Opportunities:** apply several keyword/rarity changes against the same scan, including `of the`, and confirm the list settles without repeatedly restarting. Check all six rarity labels and an initially generic modifier name. Then open All items, search Imposing Gloves and compare several modifiers with the Buy page. Scroll through more than 12 results and collapse/apply filters. Click an exact modifier, including while its item details load. Verify 25 units at 50s show a 12g 50s combined buyout. Try quantity limits and compare stock after a second scan.
- **Drops:** loot Mudfin Oracle, then hover it while alive and dead, including combat. Confirm a sample list or an explanation appears. Inspect several corpses, reopen one and compare counts. Test party/raid loot and a current quest item. Check that missing reference entries use personal rates with separate counts, and that unsupported sources with no samples remain unknown.
- **Harvesting:** gather several herbs/ore nodes and skin a previously looted corpse. Check normal/rare materials, source names, separate sample counts and the tooltip option. Repeat after reload.
- **Farming:** collect loot, quest rewards and harvested materials. Check the three totals and source menu. Receive mail/trade gold and confirm no farming increase; loot again afterward. Compare gold, item quantities and the vendor/AH threshold. Pause/resume, reload, hide/hover and reset. Check that selling a recorded item does not add its value again.
- **Windows:** overlap the main, Farming, Ledger and diagnostic windows. Bring each forward and confirm its border, title, controls and text stay together.
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
