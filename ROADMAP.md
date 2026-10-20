# Next steps

The current testing line is **1.2.0-beta / 2026-10-20-beta001**, Test revision **3**. Hold this version/build until publication.

First verify vendor purchase costs, the revised crafting layout and Opportunities item navigation on Forever. The supplied revision 2 report shows a completed scan and service quote; no vendor purchase prices have been recorded yet.

## Recommended additions

| Priority | Feature | Purpose |
|---|---|---|
| 1 | Net crafting profit and break-even | Include the chosen AH cut and show the minimum sale price; keep deposits explicit |
| 2 | Batch planner and shopping list | Choose craft quantities, combine shared reagents and show stock versus purchases needed, including vendor supplies |
| 3 | Service pricing | Add a fixed labor fee/minimum charge and a customer-supplied-materials quote mode for enchants |
| 4 | Watchlists and price-quality context | Save target buy prices/returns, track materials or loot, and show observation count, scan age and price swings alongside alerts |
| 5 | Personal profit records | Track observed purchases, sales and fees to compare realized results with estimates |

These are proposed follow-ups, not features in revision 3. A batch planner should keep replacement cost separate from cash needed to buy missing materials; owned items still have value. Price alerts should reuse stored scans and wait for player clicks to inspect listings. Account for actual fill prices before treating a batch as profitable.

Future efficiency work can reduce selected-recipe revaluation when reliable recipe/allocation change detection is available. Keep the current frame budgets, atomic results and bounded caches. Avoid a background full scan per alert or item.

Asking-price history does not provide completed sales or reliable demand. A sales ledger needs observed transactions and duplicate-safe reconciliation; do not treat disappearing listings as sales. Verify Forever DE outcomes before adding disenchant-arbitrage alerts. Compact price charts can follow once the core decisions and data quality are clear.
