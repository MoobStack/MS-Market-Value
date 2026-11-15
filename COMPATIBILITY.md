# Compatibility

**MS Market Value 1.3.0 beta** targets **WoW Forever 1.60.1 / Interface 16001**. It uses modern auction, profession, item and tooltip APIs. The standard, `_Camelot` and `_Forever` TOCs load the same addon. Different clients or Interface versions need an API review.

Live checks cover builds 70338, 70450 and 70790 on PvP/Horde. Build 70790 confirmed recovery of a saved scan and a new day of price history. See [Validation](VALIDATION.md).

## Supported behavior and limits

- Full scans use one user-started replication request. Resume can use the complete session-local copy; unfinished work does not survive reload/logout. Use one full scanner at a time.
- Recognized live reporting hosts share prices within the same region, ruleset and faction. Earlier host prices lacked a faction, so recovery is limited to ordinary PvP where the saved data is consistent with a single faction. Other legacy prices stay in SavedVariables.
- Native learned recipe schematics support ordinary item-reagent crafts and service quotes. Unresolved variants, currency costs, variable reagent quantities, salvage and recrafting cannot provide complete estimates. Quality-dependent output requires selection.
- Vendor costs require current player observations of unlimited, gold-only supplies. Other discount changes may require another vendor visit.
- AH sales come from completed mailbox invoices. Original transaction times and durable invoice IDs are unavailable, so some identical replacements remain ambiguous.
- Expense and trade tracking needs readable native amounts/context. Unrecognized wallet deductions can be retained as Unclassified; delayed, restricted or combined data can need manual review.
- Public tooltip prices remain available in combat. Restricted identifiers are not read; unknown stack quantities show each-item values.
- Disenchant estimates use an unverified Classic reference. Forever outcomes and skill eligibility are not established.

Saved-data schema remains 1. Existing prices, settings, history, watches and ledger records carry forward. Invalid/future roots are preserved. Back up SavedVariables before rollback, because older versions may not understand newer transaction kinds.

The addon performs no automated purchases, sales, crafting, disenchanting, mail collection or trades. Bundled libraries and source references are listed in [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md) and [docs/RESEARCH.md](docs/RESEARCH.md).

The new loot/farming paths were reviewed against build 70938 and checked locally. Their event timing, group-loot visibility and visual layout still need live testing. Personal drop rates use exposed corpses or harvests; a hidden or unlooted kill is not treated as a failed drop. Authoritative Forever reference rates are not included.
