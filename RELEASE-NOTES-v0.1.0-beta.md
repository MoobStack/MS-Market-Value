# MS Market Value 0.1.0-beta

Initial candidate **build001**, `2026-10-04-beta001`, prepared 2026-10-04 UTC.

MS Market Value records a native full-auction-house response, saves the completed minimum buyout prices, and adds vendor sell, AH buyout and reference disenchant values to item tooltips. It targets WoW Forever Interface 16001 and uses its modern auction and tooltip APIs.

Complete scans replace the prior market snapshot. Cancelled, timed-out, restricted or otherwise incomplete scans retain it. Prices are per item, normalized from stack buyouts, with signed suffix lookup and a labeled item-wide fallback. Scan age and stale status are visible by default.

Possible DE materials include ranges, probabilities and expected quantities. Expected material values use the same saved AH snapshot. Any missing possible material price prevents a complete DE total; a priced portion is labeled separately.

**Model status:** DE outcomes/eligibility are Classic reference estimates and are not verified Forever loot data. **Client status:** 45/45 local Lua 5.1 behavioral tests pass; native client testing remains pending.

Install the Clean ZIP's `MSMarketValue` folder in the active Forever AddOns directory, restart WoW, open an auctioneer and click **Scan entire AH**. `/msmv` opens settings; `/msmv diagnostics` provides copyable evidence. All revisions before the first finalized release retain version **0.1.0-beta** and advance build IDs.

See README, DOCUMENTATION, COMPATIBILITY and LIVE-TEST-CHECKLIST before recording qualification. Full Git/source/bundle/checksum assets are supplied separately from the installable ZIP.
