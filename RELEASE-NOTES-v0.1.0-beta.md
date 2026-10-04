# MS Market Value 0.1.0-beta

Current candidate **build002**, `2026-10-04-beta002`, prepared 2026-10-04 UTC. Tag: `v0.1.0-beta-build002`.

Build001 diagnostics showed working modern APIs and tooltip callback installation, but the realm/region gate stopped scans before a request. Build002 tolerates a missing/empty normalized realm and zero/unavailable region through accessible public realm-name and login-portal fallbacks. Diagnostics include the market key, public lookup values/sources, session request count and AH tab status. Unknown identifiers produce a specific reason without consuming a cooldown.

The requested **MS Market Value** Auction House tab replaces the automatic settings popup. Select it for scan, stop, diagnostics and scrolling settings. Buy stays selected when opening the auctioneer. `/msmv` selects/leaves the tab while there and opens a manual window elsewhere. LibAHTab minor 5 and LibStub minor 2 are bundled and attributed; no separate addon installation is needed.

Schema stays 1. Completed snapshots, numeric keys, settings, exclusions and cooldowns are preserved. Complete scans still replace the prior snapshot; interrupted/failed scans retain it. Per-unit prices, suffix lookup, vendor values and the labeled Classic DE reference model retain their existing contract.

**Local checks:** 63/63 Lua 5.1 tests pass, including 18 new market/tab cases. Syntax, TOCs and bundled-library integrity checks pass. **Native status:** build002 scan, tab visuals/taint/coexistence and disk persistence need a client retest. **DE status:** probabilities and item exceptions remain unverified for Forever.

Replace the addon folder using the Clean ZIP with WoW closed; preserve WTF/SavedVariables. Restart WoW, open an auctioneer, select **MS Market Value**, and click **Scan entire AH** once. Copy diagnostics if the attempt remains IDLE or fails. See [UPGRADE.md](UPGRADE.md) and [LIVE-TEST-CHECKLIST.md](LIVE-TEST-CHECKLIST.md).

All revisions before the first finalized release remain **0.1.0-beta**. Build002 advances the build ID/tag while preserving build001. Full Git/source/bundle/checksum assets are supplied alongside the installable ZIP.
