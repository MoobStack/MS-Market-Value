# Roadmap to 1.1.0

All testing uses `1.1.0-beta / 2026-10-11-beta001`. Test revision numbers advance without changing that version or build. Official `1.1.0` follows completion and live verification of both features.

## First: crafting and fixes

Test revision 1 adds recipe costs, gross profit/loss, return percentage, profitable-recipe sorting, and copyable markup quotes. It also keeps tooltip prices available in combat and pauses/resumes incomplete scans in the current session.

Test revision 2 fixes the reported AH buffer-loss recovery, recipe-list churn and quote wording/links. It retains the same beta version/build.

Check native recipe quantities and output prices in each profession, service quotes for Enchanting, reagent changes, visual fit, and closing/reopening after Local copy is complete. Report any unsupported native recipe shape before it is assigned a price.

## Next: price history

- Retain up to **30 calendar days** of completed pricing data, with a user setting for days kept.
- Keep the **most recent completed scan for each day** in each market. Repeated scans replace that day's entry.
- Average the available daily unit prices; show the observation count and avoid treating missing listings as zero.
- Preserve the latest complete snapshot separately for current prices and crafting.
- Order the tooltip price block: **vendor**, **historic average** when available, **recent scan**, then **DE expected**.
- Prune expired history and apply retention changes consistently. Keep markets and item variants isolated.

Daily boundaries, existing-data seeding and the exact average label will be documented with that implementation. Neither test revision 1 nor 2 collects history.

## Release checks

Verify native crafting UI and arithmetic, combat hovers, pause/resume, settings and completed-price persistence, price history pruning/averaging, scale and AH-addon coexistence. Keep the successful earlier PvP scan evidence and every existing Git tag.

Forever-specific disenchant probabilities and special eligibility remain a separate evidence task. Buying, posting and crafting automation are not planned for 1.1.0.
