MS Market Value **0.1.0-beta — build001** (`2026-10-04-beta001`). Mark this candidate as a pre-release when publishing.

User-started full-house scans save the latest completed per-item minimum buyout prices and add vendor sell, AH buyout and estimated disenchant values to item tooltips. A complete scan replaces the previous snapshot; interrupted or failed scans retain it. Saved data is account-wide with separate realm/region snapshots.

Material estimates show possible quantities, probabilities and expected quantities. Expected DE value uses material prices from the saved AH scan and becomes unavailable when a possible material has no price. Snapshot age/stale flags and settings are included.

**Compatibility target:** WoW Forever 1.60.1 / Interface 16001. **Validation:** 45/45 headless Lua 5.1 behavioral tests pass; live-client qualification is pending. **DE limitation:** Classic reference probabilities/eligibility are unverified for Forever and are labeled in the tooltip.

Install the **Clean ZIP**. Extract `MSMarketValue` into the active client's `Interface/AddOns`, restart WoW, then open an auctioneer and select **Scan entire AH**. `/msmv` opens settings. Use the **Git Repository ZIP**, **Source ZIP**, or **bundle** for development/recovery and the **SHA256 manifest** to verify downloads.

Version stays **0.1.0-beta** for all revisions before the first finalized release. Build IDs, tags and asset names identify candidates. See the repository changelog and live test checklist for current evidence.

MoobStack is an independent community addon publisher and is not affiliated with or endorsed by Blizzard Entertainment. World of Warcraft and related marks belong to their respective owners.
