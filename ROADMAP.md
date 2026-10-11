# Roadmap to 1.1.0

Testing stays on `1.1.0-beta / 2026-10-11-beta001`. Immutable test tags distinguish revisions. Official `1.1.0` follows live verification of crafting, history and the scan/tooltip fixes.

## Implemented for testing

- Revision 1: recipe cost, gross profit/loss, return percentage, recipe ranking and markup quotes; combat prices and pause/resume.
- Revision 2: local auction-copy recovery, stable recipe publication, concise native-linked quotes and recovery diagnostics.
- Revision 3: daily history, 1–30 day retention, tooltip averages/sample days, crafting toggle/auto-open preference and an all-recipes filter.

The user reports successful revision 2 resumes under multiple test conditions. Revision 3 still needs daily rollover, retention, native saving and UI checks. Every profession needs representative recipes, including services, missing prices and variable output. Follow [LIVE-TEST-CHECKLIST.md](LIVE-TEST-CHECKLIST.md).

## Useful follow-ups

- Optional auction-cut-aware net profit, with gross profit still clearly identified. Confirm Forever's fee rules before assuming a percentage; deposits and relisting need separate treatment.
- A material shopping list for a chosen craft count, with owned/missing quantities and a draft quote for customer-supplied materials plus a labor fee.
- A small price trend view with dates and sample counts. Daily asking-price history does not establish sale volume or liquidity.

These are proposals, not implemented features or release requirements. Forever-specific disenchant probabilities remain a separate evidence task. Buying, posting and crafting automation are not planned for 1.1.0.
