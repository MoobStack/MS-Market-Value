MS Market Value **1.0.0** — build `2026-10-04-release001`, tag `v1.0.0`.

Stacked items now show **Each / Stack (N)** prices using the actual hovered quantity. Vendor, lowest AH buyout and applicable **DE expected** values share one price block. Totals use unrounded unit values. A blank line separates prices from the per-item disenchant material quantities, chances and averages.

Missing material prices keep the full DE estimate unavailable; any priced subtotal remains clearly labeled. Generic item links or inaccessible quantity contexts show each-only values.

Complete, user-started auction scans save unit minimum buyouts persistently through WoW SavedVariables. Only a complete scan replaces the current region/ruleset/faction snapshot. The AH tab uses native Blizzard textures and controls; LibAHTab/LibStub are bundled.

**Upgrade:** Replace `Interface/AddOns/MSMarketValue` from the Clean ZIP with WoW closed, preserve WTF, then restart. Completed build003 prices/settings/exclusions/cooldowns carry forward without a new scan. Schema remains 1. Earlier realm-keyed caches are retained and require their first ruleset-keyed scan.

**Target:** WoW Forever 1.60.1 / 70205 / Interface 16001. **Validation:** 90/90 local Lua 5.1 checks pass. The user reported build003 native PvP/Horde completion: 104,763 rows, 2,856 priced items, one request, 6,329 events and 6,328 same-count updates, with general positive feedback. The exact 1.0.0 stack display, native disk round-trips, other rulesets and dedicated taint/coexistence checks remain follow-up coverage.

**DE model:** Labeled Classic reference estimates; Forever-specific loot probabilities and exceptional eligibility remain unverified. Values are gross asking-price estimates, before auction costs.

Install the Clean ZIP. The Source ZIP, Git Repository ZIP and complete bundle provide code/documentation/history; verify supplied assets against SHA256. All three 0.1.0-beta build tags remain immutable. This is the first stable version; publish it without the prerelease flag.

MoobStack is independent and unaffiliated with Blizzard Entertainment. World of Warcraft and related marks belong to their owners.
