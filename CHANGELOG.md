# Changelog

Release history and the four 1.1.0 beta revisions are retained below.

## 1.1.0 — 2026-10-11

Build `2026-10-11-release001`; annotated tag `v1.1.0`.

- Add selected-recipe crafting costs, sale value, gross profit/loss, return percentage and markup quotes with native recipe links when available.
- Add stable recipe rankings by profit or return, with profitable-only and all-recipes views. Services can receive material quotes without an invented sale estimate.
- Add daily price history with 1–30 day retention and tooltip averages/sample counts. Each UTC day's latest completed scan replaces its entry; partial scans never enter history.
- Add a profession Show profits / Hide profits toggle and optional auto-open. Keep tooltip prices visible in combat.
- Improve scan pause/resume, copied-buffer recovery and recipe-list stability. Preserve existing prices, history, settings and all earlier Git tags.
- Promote the final beta to stable metadata and shorten the release, user and recovery docs.

**239/239 local Lua 5.1 tests pass.** The user reports revision 4 functioning properly. Supplied diagnostics show 96,590 saved auction rows, 3,179 priced items, a complete craft valuation and one history day. See [docs/RELEASE-1.1.0.md](docs/RELEASE-1.1.0.md) for the evidence and remaining coverage. DE outcomes remain a Classic reference.

## 1.1.0-beta — Test revision 4 — 2026-10-11

Same version and build, `2026-10-11-beta001`; tag `v1.1.0-beta-test4`.

- Fix the missing profession toggle reported in Tailoring. It now follows the native border/title level rather than just the recipe page and sits beside the close button. Auto-open can remain disabled.
- Hide the toggle and profit window immediately when the crafting page closes. Keep manual opening through `/msmv craft`.
- Add toggle visibility, header levels and crafting-window state to diagnostics. Update installation, live checks and release notes.

**238/238 local Lua 5.1 tests pass.** Eleven new cases include a header regression that fails against revision 3. Button appearance, history rollover and native saving still need live checks. Previous scans, settings, history and Git tags are retained.

## 1.1.0-beta — Test revision 3 — 2026-10-11

Same version and build, `2026-10-11-beta001`; tag `v1.1.0-beta-test3`.

- Add daily price history with 1–30 day retention, defaulting to 30. Each UTC day's latest completed scan replaces its entry; partial scans never enter history.
- Show Historic avg and its sample-day count between vendor and recent AH prices. Missing listings/days are skipped; suffixes and markets stay separate. Import the last existing complete scan once, when it is within retention.
- Add Show profits / Hide profits in the profession title bar, above Forever's raised crafting page. Auto-open is optional and off by default.
- Add Show all recipes / Profitable only. Losses, break-even and unpriced learned recipes can be viewed; unknown values remain unavailable and sort last.
- Add Crafting & history settings, saved preferences and history diagnostics. Update the guide, release notes and native checklist.

**227/227 local Lua 5.1 checks pass.** The user reports successful revision 2 resumes under multiple conditions. New history, controls and native saving need revision 3 checks. Official 1.1.0 remains pending.

## 1.1.0-beta — Test revision 2 — 2026-10-11

Same version and build, `2026-10-11-beta001`; tag `v1.1.0-beta-test2`.

- Copy auction price rows locally so a completed copy survives closing/reopening the AH. Pause keeps pricing stopped while unread rows continue copying at the open auctioneer.
- Use complete public prices without waiting for item names. An early buffer loss keeps progress paused; a fresh restart becomes available after the original cooldown. Partial prices never replace or mix with completed scans.
- Shorten quotes to `Recipe - price ea`, using the native profession-book recipe link when available. Insert in chat opens a draft. Fixed multi-item outputs quote per item; variable/unknown yields stay per craft.
- Keep profitable recipes visible until a complete refresh is ready. Item-data events update names without clearing or repricing the list; repeated unchanged list events no longer restart it.
- Add local-copy and catalog build/publication diagnostics. Update the guide, live checks and recovery notes.

**169/169 local Lua 5.1 checks pass.** The Test revision 1 report was from client build 70338; these fixes still need a native retest. Price history follows in a later revision of this beta.

## 1.1.0-beta — Test revision 1 — 2026-10-11

Build `2026-10-11-beta001`; tag `v1.1.0-beta-test1`.

- Added selected-recipe material costs, per-craft sale value, gross profit/loss and percentage return on material cost.
- Added a profitable-recipe list for the open profession, sortable by profit or return. Minimum output is used for variable-yield ranking.
- Added copyable craft quotes with saved markup. Non-auctionable services can show material quotes.
- Included readable selected optional/alternative reagents. Missing prices and unsupported recipe shapes stay unavailable rather than producing a misleading profit.
- Kept public tooltip prices and available actual-stack totals visible during combat.
- Added pause/resume for the current session's incomplete scans, including response/item-data timeouts. Resume retains accepted rows and retry progress without sending another full-scan request or changing the cooldown.
- Preserved schema-1 completed prices/settings and all release history. Shortened the user guide and updated the test, upgrade and Git instructions.

Local Lua 5.1 checks cover the new calculations, native UI lifecycle and scan interruptions. Live profession/UI/buffer checks remain pending. Reload/logout ends incomplete work because the native buffer is session-only.

Price history is next, under the same version/build with a new test revision. Official 1.1.0 publication follows both features and live verification.

## 1.0.0 — 2026-10-04 UTC

| Release detail | Value |
|---|---|
| Build identifier | `2026-10-04-release001` |
| Annotated Git tag | `v1.0.0` |
| Target | WoW Forever 1.60.1 / 70205 / Interface 16001 |

Added and changed:

- Stacked item tooltips show per-item and actual stack totals under **Each / Stack (N)**. Native item GUID/location or matching bag/equipment context supplies the quantity; generic links and inaccessible contexts retain each-only values.
- Vendor, AH and applicable **DE expected** values now share the price block. Material estimates follow a blank line and remain per item.
- Stack totals multiply the original unit value before money rounding. Missing DE material prices still prevent a complete total; a known subtotal remains explicitly labeled **DE priced portion only**.
- Promoted metadata, all three TOCs, documentation and release validation to stable **1.0.0**. Schema 1, the realmless market keys, prior prices/settings/exclusions/cooldown and all three beta commits/tags are preserved. Build003 users do not need a new scan solely for this update.

Validation and native evidence:

- **90/90** local Lua 5.1 checks pass, including 12 new quantity, display, rounding, restriction and beta-to-stable cache cases.
- Runtime syntax, metadata/load order, three identical TOCs, pinned-library integrity and operation checks pass.
- The user reported build003 **COMPLETE** on `forever|90|pvp|Horde`: **104,763 rows**, **2,856 priced items**, **6,329 replication events**, **6,328 same-count updates**, one full-scan request, and the AH tab installed. The user reported that behavior appeared to work as intended.
- This report establishes a successful native PvP scan and stored in-memory snapshot. It does not establish a reload/restart disk round-trip, every material/variant's coverage, other rulesets, or the new 1.0.0 stack layout. Those checks remain listed separately.
- Forever DE outcomes and special eligibility remain a labeled, unverified Classic reference.

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
