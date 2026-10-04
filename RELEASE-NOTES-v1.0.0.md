# MS Market Value 1.0.0

Release identity: `1.0.0 / 2026-10-04-release001`; annotated tag `v1.0.0`; target WoW Forever 1.60.1 / 70205 / Interface 16001.

## Tooltip changes

Vendor, AH and applicable estimated DE values share one block. A readable actual stack larger than one has an **Each / Stack (N)** heading and both values on each price row. Single items and generic links without a reliable quantity show **Each**. Totals multiply the original unit value before display rounding.

A blank line separates that price block from **Disenchant estimate**. Material quantities, chances and averages remain per item. Missing material prices keep the full DE total unavailable; any known portion is labeled **DE priced portion only**.

## Existing data

Schema 1, realmless ruleset/faction keys, completed build003 prices, settings, exclusions and cooldowns remain compatible. No scan is required solely to upgrade from build003. Earlier realm-keyed beta caches still need their first ruleset-keyed scan and are retained for rollback.

With WoW closed, replace `Interface/AddOns/MSMarketValue` from the Clean ZIP, preserve WTF, then restart. Verify the release identity in diagnostics and hover a known stack. Standard `/reload` or normal logout/exit saves data through WoW.

## Evidence and coverage

All **90/90** local Lua 5.1 checks pass. The user's build003 PvP/Horde report completed **104,763 rows** and **2,856 priced items** with one request and **6,328 same-count updates**. That supports the retained scan behavior; the new tooltip display, disk round-trips and other rulesets need their own native checks.

DE loot remains a labeled **Classic reference estimate**, unverified for Forever-specific probabilities and exceptional eligibility. It does not claim profession capability or guarantee loot/sale proceeds.

All three beta commits/tags remain unchanged. Stable publication uses `v1.0.0` without the GitHub prerelease flag. Source and recovery instructions are in [GIT-WORKFLOW.md](GIT-WORKFLOW.md); complete changes are in [CHANGELOG.md](CHANGELOG.md).
