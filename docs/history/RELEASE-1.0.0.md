# 1.0.0 release evidence and tooltip behavior

## Native baseline supplied by the user

The user reported that build003 appeared to function as intended and requested stack prices plus the first stable release. Their diagnostics establish:

| Detail | Observed value |
|---|---|
| Addon | `0.1.0-beta / 2026-10-04-beta003` |
| Client | `1.60.1 / 70205 / Interface 16001` |
| Scan state | COMPLETE |
| Requests this session | 1 |
| Replication events | 6,329 |
| Same-count updates | 6,328 |
| Market | `forever|90|pvp|Horde` |
| Identity | realmless-ruleset; pvp; GetNormalizedRealmName reporting alias |
| Reporting aliases | ClassicBetaPvP2 / Classic Beta PvP 2 |
| Native region / portal | 90 / test |
| AH tab | installed |
| Snapshot rows / priced items | 104,763 / 2,856 |
| Bid-only / sold rows | 5 / 0 |
| Snapshot start UTC | `2026-10-04T08:07:09Z` |
| Tooltip | callback installed; ready; addon enabled |
| DE profile | classic-reference-1; Forever unverified |

The recorded lifecycle was WAITING → PROCESSING → RESOLVING → COMPLETE, followed by “Snapshot replaced.” This confirms that the prior duplicate-event failure did not recur during the reported scan. The report shows a complete in-memory snapshot and general positive feedback, not a dedicated disk round-trip, full listing/material audit, other rulesets or native tests of the new 1.0.0 tooltip.

## Quantity and display

Version 1.0.0 resolves the actual hovered stack using an accessible native item GUID/location, or matching bag/player-equipment getter context. Returned item IDs must match; counts must be positive bounded integers. Failed, unknown, secret, forbidden or malformed contexts fall back to each-only pricing. Maximum capacity and total owned quantity are never used. Counts are not saved or cached across different stacks.

The price block uses Blizzard's ordinary tooltip lines. When N > 1, the right heading is **Each / Stack (N)**; each money row follows the same order. For a synthetic three-item example:

| Price row | Each | Stack (3) |
|---|---:|---:|
| Vendor sell | 12s 34c | 37s 02c |
| AH low | 9s 00c | 27s 00c |
| DE expected, if modeled | 2s 98c | 8s 93c |

The DE example uses 297.5c per item; its stack is 892.5c before rounding. Totals multiply unrounded values, which avoids accumulating displayed rounding errors. These are calculation fixtures, not live market quotes or a claim that this synthetic equipment is ordinarily stackable.

Snapshot age remains in the price block. A blank line precedes **Disenchant estimate**, with item level and per-item material ranges/chances/averages. The estimate value appears once, in the price block. Unpriced outcomes keep the full total unavailable and place any labeled priced subtotal in that same block. The reference-model qualification stays visible even when detailed material rows are hidden.

Generic chat/catalog/auction item links show each-only values unless native data identifies an actual readable stack. They do not borrow an arbitrary owned stack. Child-item contexts are not assigned their parent's quantity. Comparison decoration remains supported; Blizzard owns comparison rebuilding.

## Release contract

Stable identity is `1.0.0 / 2026-10-04-release001`, annotated tag `v1.0.0`. Schema 1, scan implementation and market namespace remain unchanged. Build003 snapshots/settings/exclusions/cooldowns are reused without rescanning. Beta commits and annotated tag objects remain immutable.

All 90 local checks pass, including 12 new stack/block/restriction/upgrade cases. Native follow-up is in [LIVE-TEST-CHECKLIST.md](../../LIVE-TEST-CHECKLIST.md); primary API links are in [RESEARCH.md](../RESEARCH.md). The stable designation does not promote the Classic reference DE data to verified Forever loot.
