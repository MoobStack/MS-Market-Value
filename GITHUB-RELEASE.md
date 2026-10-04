MS Market Value **0.1.0-beta — build002** (`2026-10-04-beta002`). Mark this candidate as a pre-release when publishing.

Build002 fixes the market lookup gate that prevented build001 from sending a scan when a normalized realm or numeric region was unavailable. Guarded public realm-name and login-portal fallbacks resolve the market; expanded diagnostics expose lookup sources and the session request count. Matching existing numeric keys, complete snapshots and cooldowns are retained.

Scan controls and settings now live in a new **MS Market Value** Auction House tab with a vertical scrollbar. Opening an auctioneer keeps Buy selected and no longer opens a settings popup. `/msmv` selects/leaves the tab at the AH and opens a manual window elsewhere. Pinned LibAHTab and LibStub are bundled with original notices, requiring no separately installed addon.

User-started full scans save per-item minimum buyout prices; complete scans replace the previous snapshot while failures/interruption retain it. Tooltips show vendor prices, AH buyouts and Classic reference disenchant quantities/probabilities/value. Missing material prices prevent a complete DE total.

**Target:** Forever 1.60.1 / 70205 / Interface 16001. **Local validation:** 63/63 Lua 5.1 tests pass. User diagnostics confirmed build001 startup/API/callback availability and the failed market lookup. **Build002 native scan/tab/persistence retest remains pending.** Forever DE probabilities and special eligibility remain unverified and labeled.

Install the **Clean ZIP**, replacing `MSMarketValue` in the active client's `Interface/AddOns` without changing WTF/SavedVariables. Restart WoW, open an auctioneer, select **MS Market Value**, then click **Scan entire AH**. Use the Git Repository ZIP, Source ZIP or complete bundle for development/recovery; verify asset hashes against the SHA256 manifest.

Version remains **0.1.0-beta** until the first finalized release. Build002 has a new immutable tag; build001 history/tag remain available. Preparing these assets does not publish a release.

MoobStack is independent and is not affiliated with or endorsed by Blizzard Entertainment. World of Warcraft and related marks belong to their respective owners.
