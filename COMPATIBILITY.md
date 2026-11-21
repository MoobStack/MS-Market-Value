# Compatibility

MS Market Value 1.3.3 targets **WoW Forever 1.60.1 / Interface 16001**. Live diagnostics confirmed faction and neutral scanning on client build 71037 with realm names hidden. The standard, Camelot and Forever TOCs load the same addon.

- Use one full AH scanner at a time. Prices are kept separate by region, ruleset and faction.
- Public tooltip prices and read-only reports can remain available in combat. Scans, live Buy navigation, profession controls and transaction editing wait until combat ends.
- Ordinary learned recipes and gold-only vendor supplies are supported. Unreadable data, currency costs or unsupported recipe shapes can leave an estimate incomplete.
- Drop observations include only loot exposed by the client. Reliably identified empty inspections count, but hidden group loot, unopened corpses and ambiguous interactions cannot be counted as failed drops.
- Included drop and disenchant references are estimates, not verified Forever probabilities.
- Ledger tracking depends on native confirmations. Some indistinguishable mail invoices or unclear wallet changes can require manual review.

Saved-data schema is 1. Invalid or newer saved-data formats are preserved rather than silently replaced. The addon does not automate purchases, sales, crafting, mail collection or trades.
