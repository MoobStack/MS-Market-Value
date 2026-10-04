# Changelog

Public version **0.1.0-beta** is fixed until the first finalized release. Each candidate has a separate build identifier, archive filename, checksums, commit, and annotated build tag. New beta builds add entries beneath the same primary version; they do not increment the TOC version.

## 0.1.0-beta

### Build003 — 2026-10-04 UTC

| Build detail | Value |
|---|---|
| Build identifier | `2026-10-04-beta003` |
| Git tag | `v0.1.0-beta-build003` |
| Target | WoW Forever 1.60.1 / 70205 / Interface 16001 |

Fixed:

- First-hover item-cache updates no longer call `RebuildFromTooltipInfo` on comparison tooltips. The native generic rebuild changes the comparison's append-mode info and can clear `infoList` before inserting it. Only readable, getter-backed, non-append primary GameTooltip/ItemRefTooltip item data is refreshed; other registered frames are decoration-only.
- A second `REPLICATE_ITEM_LIST_UPDATE` with the same row count no longer fails the scan. Accepted rows and cursor/retry state remain intact; updates can wake pending item-data retries. Count changes, unreadable data, market changes and another addon requesting replication still preserve the prior complete snapshot.
- Native positive region IDs, including the reported beta region `90`, take precedence over portal fallback.

Changed:

- Detected Forever market keys now use region, ruleset and faction instead of a reporting-host suffix. Known PvP hosts share one PvP cache; Normal/PvE aliases have a different cache. Hardcore uses `C_GameRules.IsHardcoreActive` when available. Other detection uses bounded Forever reporting aliases and exposes that source; unknown aliases remain isolated.
- Faction markets are conservatively separate until cross-faction AH sharing is qualified. Old realm-keyed snapshots remain stored and are not automatically promoted into a ruleset cache; a fresh successful scan is required for the new key.
- Replaced the narrow dark settings viewport with full-width `InsetFrameTemplate` groups, native textured backgrounds/borders and stock controls. Settings fit in two columns. Standalone settings and diagnostics use `PortraitFrameTemplate` and native close buttons.
- Added ruleset, ruleset source, identity kind, faction and replication-event/update counters to diagnostics. UI text now refers to markets/rulesets.
- Updated complete Git/release/upgrade/research documentation. Version stays **0.1.0-beta**, schema stays 1, and build001/build002 commits and annotated tags remain intact.

Validation:

- **78/78** local Lua 5.1 behavioral tests pass. One obsolete second-event refusal case was replaced; 15 additional scanner, tooltip and realmless-market cases were added.
- Runtime syntax, three TOCs, metadata/load order, bundled-library hashes and operation checks pass.
- User build002 diagnostics establish that one request reached WAITING/PROCESSING and the MS tab installed; they also establish the duplicate-event failure and comparison-tooltip error. The screenshot establishes the prior layout, not this revised layout.
- Build003 native scan completion/coverage, first-hover behavior, visual fit, taint/coexistence and SavedVariables disk saving remain pending. Forever DE outcomes remain an explicitly unverified Classic reference.

### Build002 — 2026-10-04 UTC

| Build detail | Value |
|---|---|
| Build identifier | `2026-10-04-beta002` |
| Git tag | `v0.1.0-beta-build002` |
| Target | WoW Forever 1.60.1 / 70205 / Interface 16001 |

Fixed:

- Build001 rejected a scan before sending its native request when a normalized realm name or numeric region was unavailable. Public realm-name and guarded login-portal fallbacks now resolve the market without guessing from language/locale.
- Existing native numeric region/realm keys remain authoritative. Recognized portal fallbacks reuse the matching numeric region key; named test portals stay separate. A genuinely missing identity still refuses the scan with a specific diagnostic reason and consumes no cooldown.

Changed:

- Added the **MS Market Value** AH tab with scan, stop, diagnostics, tooltip options and reversible item exclusions. Lower controls use a native vertical scrollbar.
- Opening an auctioneer installs the tab without selecting it or opening a settings popup. `/msmv` selects/leaves the tab while at the AH and retains a manually opened settings window elsewhere.
- Retired the automatic-popup checkbox. The old saved `openAtAH` preference is retained for rollback but has no effect in build002.
- Added lazy frame loading, tab reuse, combat guards, native tab restoration and shared coordination with other LibAHTab users.
- Bundled pinned LibAHTab minor 5 (MIT) and LibStub minor 2 (public domain), including original notices, license terms and integrity checks. No license was chosen for original MoobStack code.
- Diagnostics now show normalized/public realm names, native region, login portal, market key and sources, AH tab status, and the session's full-scan request count.
- Updated Git, upgrade, release, research and live-test documentation. Public version remains **0.1.0-beta**; schema remains 1; build001 history/tag are preserved.

Validation:

- **63/63** local Lua 5.1 behavioral tests pass, including 18 additional scan/market/tab cases.
- Syntax, TOC/load order, bundled-library integrity and runtime operation checks pass.
- User-supplied build001 diagnostics confirm client 1.60.1/70205, modern API availability and tooltip callback installation, plus the failed market lookup. They do not identify which lookup returned an unusable value.
- Build002 native scan response, tab layout/taint/coexistence and disk persistence still require a client retest. Forever DE data remains unverified.

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
