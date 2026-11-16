# Future improvements

These are follow-up ideas, outside the 1.2.0 release:

- Inventory cost allocation, with an explicit policy for purchased, crafted and looted items, to improve realized-profit reporting.
- A crafting batch planner and shared shopping list, separating replacement value from cash needed for missing materials.
- Per-recipe service charges.
- Compact price charts and personal sale-rate context when enough observations exist.
- Stronger transaction reconciliation where the client exposes useful identifiers.

Keep storage bounded, reuse saved data and avoid background auction requests. Verify Forever disenchant outcomes before adding DE arbitrage signals.
