# Changelog

Public version **0.1.0-beta** is fixed until the first finalized release. Each candidate has a separate build identifier, archive filename, checksums, commit, and annotated build tag. New beta builds add entries beneath the same primary version; they do not increment the TOC version.

## 0.1.0-beta

### Build001 — 2026-10-04 UTC

| Build detail | Value |
|---|---|
| Build identifier | `2026-10-04-beta001` |
| Git tag | `v0.1.0-beta-build001` |
| Target | WoW Forever 1.60.1 / Interface 16001 |

Added:

- Complete replication scan using the supported modern auction-house API and its completion event.
- Processing capped at 100 rows or approximately four milliseconds per tick.
- Delayed item-data retries with a timeout and no duplicate accumulation.
- Account-wide `MSMarketValueDB` with one complete replacement snapshot per realm/region.
- Per-unit minimum buyout prices, auction/quantity counts, bid-only distinction, sold-row exclusion, signed random suffix lookup, and labeled item-wide fallback.
- Native vendor sell prices for one item.
- Classic reference disenchant outcomes for modeled uncommon, rare, and epic equipment.
- Material quantity ranges, outcome probabilities, expected quantities, expected gross value, and explicit missing-price handling.
- Scan age, configurable stale threshold, tooltip visibility settings, saved window position, item-specific DE exclusions, and copyable diagnostics.
- Secret/restricted-value checks, forbidden-tooltip checks, modern postprocessing callbacks, and out-of-combat feature execution.
- Persistent 15-minute minimum scan interval, request timeout, cancellation, replication conflict detection, buffer-change refusal, and future-schema preservation.
- Source, architecture, compatibility, Git, release, upgrade, research, validation, and live-test documentation.
- Lua 5.1 behavioral fixtures and tagged archive/bundle generation.

Validation:

- **45/45** headless behavioral tests pass under Lua 5.1.5.
- Runtime syntax and TOC/source contract checks pass.
- Live-client scan, UI, disk persistence, and actual Forever disenchant behavior remain pending.

Known limits:

- Forever-specific disenchant probabilities and special eligibility are unverified. The Classic reference is labeled in tooltips.
- Prices are observed asking prices and may become stale between scans.
- The local minimum scan interval cannot override a longer server cooldown.
- Complete price persistence depends on WoW successfully writing and reloading SavedVariables.
