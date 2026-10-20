# Build003 investigation

User evidence: **MS Market Value 0.1.0-beta / 2026-10-04-beta002**, **Forever 1.60.1 / 70205 / Interface 16001**, reported 2026-10-04. Two supplied errors also trace the earlier tooltip refresh path. The user identifies a realmless game with PvP and Normal rulesets and provided an Auction House screenshot.

## Observed failures

| Evidence | What it establishes |
|---|---|
| `ShoppingTooltip1`, TooltipDataHandler.lua:280, `insert` expected a table but got nil | MSMV's RefreshVisible called native RebuildFromTooltipInfo on a comparison frame; native info was append=false at failure |
| Session request count 1; WAITING then PROCESSING | The build002 market gate resolved and a native request/response occurred |
| FAILED: replication buffer was refreshed during this scan | MSMV's blanket second-event refusal fired; it does not prove that every second event represents a new snapshot |
| Native region 90, portal test, alias ClassicBetaPvP2 | The old 1–10 region bound rejected a usable beta identifier and selected portal fallback |
| AH tab installed plus screenshot | The native tab was present; the body was a narrow flat dark scrolling rectangle with duplicate heading and unused horizontal space |
| No saved snapshot | No complete native scan had been committed in that market |

The report does not establish a successful scan, the Normal reporting alias, cross-faction market pooling, disk persistence, or the revised layout. Player item GUIDs and the screenshot itself are not included in release archives.

## Comparison-tooltip fix

The reviewed native generic rebuild forces the first info entry to append=false. Comparison creation instead clears lines, adds its header and calls ProcessInfo with append=true and precomputed item data. A generic rebuild can clear handler info before the native table insertion, matching the supplied infoList error. A pcall does not repair native state or prevent secure native error reporting.

Build003 never requests a generic rebuild of ShoppingTooltip, ItemRefShoppingTooltip or custom allowed frames. Those still receive MSMV lines through the supported item postprocessing callback. Refresh requests are limited to allowed, visible, non-forbidden GameTooltip and ItemRefTooltip frames with readable getter-backed, non-append primary item info and accessible item data/type/ID. Combat, missing/throwing getters, restricted inputs and recursive refresh are skipped. The native comparison manager owns comparison rebuilding; deferred values may require the next native refresh/rehover.

## Replication-event fix

The first active event initializes one staging snapshot and its zero-based row range. Additional events in PROCESSING/RESOLVING with an unchanged readable count preserve the existing staging table, cursor, accepted rows and partial retry pass. Resolution updates can wake the next pending-data retry immediately. Accepted rows are never accumulated again, and another replication request is not sent.

Count changes or unreadable counts still fail safely. An observed competing ReplicateItems request, context change, timeout, close or combat also preserves the prior complete snapshot. Late events after completion/cancellation/failure do not reopen a scan. Diagnostics expose response and same-count update counters.

The reviewed event has no scan generation identifier. Same-count handling assumes the current replication buffer belongs to the one observed request unless another request/count/context change is detected. It is not proof that undetected native replacement with an identical count is impossible. Run one full scanner at a time and qualify actual native coverage separately.

## Realmless identity and upgrade

Forever's official ruleset description treats Normal, PvP, Roleplaying and Hardcore as separate ecosystems. A reporting name such as ClassicBetaPvP2 is an internal alias, not a traditional independent realm market.

Detected keys are `forever|region|ruleset|faction`. Native positive integer regions now include 90. Hardcore uses C_GameRules.IsHardcoreActive when true. Other rulesets use conservative anchored alias forms: ClassicBeta/Forever/WoWForever, a recognized Normal/PvE/PvP/RP/Roleplaying/Hardcore token and optional numeric suffix. The source is labeled in diagnostics. The Classic/Modern Forever experience preset and player PvP flag are not market selectors. No verified native Normal/PvP getter was established in the reviewed definitions.

Only ClassicBetaPvP2/region 90 is supplied live evidence. Other accepted forms are tested mappings that still need client confirmation. Unknown aliases remain isolated. Faction caches remain separate because this client's cross-faction AH pooling has not been established. Missing faction on a detected ruleset blocks the request before consuming a cooldown.

Old realm-keyed snapshots stay stored, schema remains 1, and settings/exclusions/cooldowns are retained. They are never automatically promoted or merged into a detected ruleset cache. One fresh complete scan is needed for the new namespace. A reporting-host number change within the same detected region/ruleset/faction keeps that cache; changing Normal/PvP does not.

## Native UI revision

The existing stock AH tab is retained through the bundled shared library. A 768×460 content frame now attaches directly to the native AH body. Full-width scan controls and two settings columns use InsetFrameTemplate with the client's marble background/nine-slice border, native fonts, stock controls and the native status-bar texture. The narrow opaque backdrop, duplicate inner title and settings scrollbar are removed. Manual settings and diagnostics inherit PortraitFrameTemplate, stock backgrounds, portrait/title regions and close buttons. Diagnostics alone keep a scrolling copy field.

This references existing client resources; no screenshot artwork or external image asset is bundled. Native visual fit, scale, taint and Auctionator coexistence remain pending.

## Validation and provenance

All **78/78** local Lua 5.1 cases pass. The prior blanket second-event refusal expectation was replaced, and 15 cases cover scan-update/retry behavior, refresh ownership/access/reentrancy, beta regions, host sharing, ruleset/faction isolation, persistence and legacy-data retention. Syntax, TOC metadata/load order, bundled-source hashes and runtime operation checks pass.

Primary sources are linked in [RESEARCH.md](../RESEARCH.md), including the exact reviewed 1.60.1/70205 source commit. [LIVE-TEST-CHECKLIST.md](../../LIVE-TEST-CHECKLIST.md) separates pending native checks from local fixture passes. The Classic DE reference remains unverified for Forever. Version stays **0.1.0-beta**; a new annotated build003 tag preserves the previous two tags and commits. No GitHub push or release publication is claimed.
