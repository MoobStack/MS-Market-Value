# MS Market Value 0.1.0-beta

Current candidate **build003**, `2026-10-04-beta003`, prepared 2026-10-04 UTC. Tag: `v0.1.0-beta-build003`.

Build003 addresses the supplied first-hover `ShoppingTooltip1` error and the scan failure after a second replication event. MSMV now requests rebuilds only for readable getter-backed primary item tooltips; comparisons stay under the native comparison manager. Additional replication events with an unchanged row count preserve progress and can wake pending item-data retries. They do not restart the scan, issue another request or duplicate accepted rows. Changed/unreadable counts and competing replication requests still preserve the previous complete snapshot.

Forever markets now use detected region/ruleset/faction keys. Native beta region `90` is accepted. Known PvP reporting hosts share a PvP cache; Normal/PvE has its own cache. Normal/PvP detection currently uses bounded reporting aliases, and diagnostics expose that source. Unknown aliases stay isolated; cross-faction AH pooling remains unqualified, so faction caches are separate.

The AH pane uses full-width native Blizzard inset textures and borders, stock buttons/checkboxes/inputs and two settings columns. All settings fit without a settings scrollbar. Manual settings and copy diagnostics use native portrait frames. Buy remains selected when opening the auctioneer; `/msmv` selects/leaves the tab at the AH and opens the manual window elsewhere.

Schema stays 1. Old snapshots, settings, exclusions and cooldowns remain stored. **A fresh complete scan is required for the new ruleset key**; old realm-keyed data is never automatically promoted or merged. Complete scans replace that market's snapshot; failed/interrupted scans keep prior completed data. Per-unit/suffix prices, vendor values and the explicitly unverified Classic DE model remain available.

**Local checks:** 78/78 Lua 5.1 tests pass, including 15 additional cases and the corrected repeated-event case. Syntax, TOCs, metadata and bundled-library hashes pass. **Native status:** user reports establish the old build's request/tab/failures; build003 scan coverage, first-hover behavior, visual fit/taint/coexistence and disk saving need a client retest. **DE status:** Forever probabilities and item exceptions remain unverified.

Replace the addon folder using the Clean ZIP with WoW closed and preserve WTF/SavedVariables. Restart, select **MS Market Value** at an auctioneer, and scan once when cooldown permits. Copy `/msmv diagnostics` if it fails. See [UPGRADE.md](UPGRADE.md), [docs/BUILD003-INVESTIGATION.md](docs/BUILD003-INVESTIGATION.md) and [LIVE-TEST-CHECKLIST.md](LIVE-TEST-CHECKLIST.md).

All revisions before the first finalized release remain **0.1.0-beta**. Build003 adds a new immutable tag and retains build001/build002. Complete Git/source/bundle/checksum assets accompany the installable ZIP. No GitHub publication is claimed.
