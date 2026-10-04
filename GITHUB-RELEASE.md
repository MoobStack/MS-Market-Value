MS Market Value **0.1.0-beta — build003** (`2026-10-04-beta003`). Mark this candidate as a pre-release when publishing.

This revision fixes the reported comparison-tooltip refresh path and second-event scan failure. Primary item tooltips can refresh after data loads; comparison rebuilding stays with Blizzard. Same-count replication updates preserve scan progress and wake unresolved item-data retries without duplicate accumulation or another request. Count/context/conflict failures retain prior completed data.

Detected Forever markets are keyed by region, ruleset and faction. Native region `90` is accepted, reporting-host suffixes do not split a known PvP cache, and Normal/PvE stays separate. Alias-derived detection is identified in diagnostics; unknown aliases remain isolated. Cross-faction market sharing is unqualified. Old realm-keyed snapshots remain stored but require a new successful scan before prices exist under the ruleset key.

The **MS Market Value** AH pane now uses full-width native textured inset frames and stock controls, with two settings columns and no settings scrollbar. Manual settings and diagnostics use native portrait windows. Opening an auctioneer keeps Buy selected and opens no standalone popup. LibAHTab/LibStub remain bundled with original terms.

User-started full scans save minimum buyout prices per unit. Complete scans replace the market's prior snapshot; failures keep it. Tooltips include vendor prices, AH buyouts and labeled Classic reference disenchant quantities/probabilities/value. Missing material prices prevent a complete DE total.

**Target:** Forever 1.60.1 / 70205 / Interface 16001. **Local validation:** 78/78 Lua 5.1 tests pass. The supplied build002 logs/screenshot establish a request reaching PROCESSING, tab installation and the reported failures/old layout. **Build003 native scan/first-hover/UI/persistence retest remains pending.** Forever DE probabilities and special eligibility remain unverified and labeled.

Install the **Clean ZIP**, replacing `MSMarketValue` in the active client's `Interface/AddOns` with WoW closed and preserving WTF/SavedVariables. Restart, select **MS Market Value** at an auctioneer and click **Scan entire AH** once when permitted. Use the Git Repository ZIP, Source ZIP or complete bundle for development/recovery; verify hashes against SHA256.

Version stays **0.1.0-beta** until the first finalized release. Build003 has a new immutable annotated tag; build001/build002 history remains intact. Preparing these assets does not publish a release.

MoobStack is independent and is not affiliated with or endorsed by Blizzard Entertainment. World of Warcraft and related marks belong to their respective owners.
