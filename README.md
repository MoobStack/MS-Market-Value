# MS Market Value

Auction prices, crafting costs and profit, price history, vendor values, and disenchant estimates for WoW Forever. Item tooltips show each-item and actual stack prices, including during combat.

| Detail | Current test package |
|---|---|
| Publisher | MoobStack |
| Version | `1.1.0-beta` |
| Build | `2026-10-11-beta001` |
| Test revision | **4** |
| Annotated tag | `v1.1.0-beta-test4` |
| Target | WoW Forever 1.60.1 / Interface 16001 |
| Saved data | Schema 1; existing completed scans and settings retained |

## What is ready to test

- **Crafting analysis:** material cost, sale value, gross profit or loss, and percentage return on material cost for a selected learned recipe.
- **Recipe list:** sort by profit or return. Show profitable recipes, or include losses, break-even recipes and unavailable estimates. A complete refresh replaces the list once.
- **Craft quotes:** `Recipe - price ea`, with the native recipe link when available. Copy the quote or insert a chat draft. Services receive material quotes without an auction sale estimate.
- **Price history:** keep 1–30 UTC calendar days, using each day's latest completed scan. Tooltips show the average and the number of days with a price.
- **Crafting controls:** a Show profits / Hide profits button beside the profession close button and an optional automatic opening setting. Auto-open defaults to off.
- **Combat tooltips and scan recovery:** saved public prices stay visible in combat. Completed local auction copies resume after closing/reopening without another server request.

## Install and use

Close WoW and replace `Interface/AddOns/MSMarketValue` with the **Clean ZIP**'s addon folder. Keep WTF/SavedVariables, then restart the Forever client. Diagnostics should identify **Test revision: 4**.

At an auctioneer, select **MS Market Value** and start one full scan. Only a completed scan replaces saved prices. Keep the AH open until **Local copy** is complete; incomplete work ends on reload/logout. The 15-minute request interval still applies.

Open a profession, select a learned recipe, and click **Show profits** beside its close button. `/msmv craft` also opens the window with auto-open disabled. **Recipe list → Show all recipes** includes unprofitable and unpriced entries. Use **Profitable only** to switch back. In `/msmv`, choose **Crafting & history** to set auto-open and days retained; the default history length is 30 days.

| Command | Action |
|---|---|
| `/msmv` | Auction tab or settings window |
| `/msmv scan` | Start a scan, or resume paused work |
| `/msmv pause` or `/msmv stop` | Pause and retain incomplete work |
| `/msmv resume` | Resume at an open auctioneer, outside combat |
| `/msmv restart` | Request a fresh scan when the cooldown allows |
| `/msmv discard` | Discard incomplete work; keep completed prices |
| `/msmv craft` | Open crafting analysis for the open profession |
| `/msmv status` | Scan state and saved-price age |
| `/msmv diagnostics` | Copyable client, scan, history and crafting details |

## Price meaning

Crafting uses the latest scan's lowest unit buyouts, including the market cost of owned materials. Profit is **before auction fees**. Missing prices and unsupported recipe shapes remain unavailable; select a row for details. Asking prices do not guarantee sales.

History averages the available daily unit lows equally. One day is enough; missing days or listings are skipped. Upgrade imports the last existing complete scan if it is within retention. Earlier scans cannot be reconstructed. Shortening retention deletes older history, without removing current prices.

Disenchant outcomes remain a labeled Classic reference; Forever-specific loot rules are unverified.

## Documentation

- [DOCUMENTATION.md](DOCUMENTATION.md): controls, calculations, history and scanning.
- [CHANGELOG.md](CHANGELOG.md): current and earlier changes.
- [LIVE-TEST-CHECKLIST.md](LIVE-TEST-CHECKLIST.md), [VALIDATION.md](VALIDATION.md): local evidence and native checks.
- [UPGRADE.md](UPGRADE.md), [GIT-WORKFLOW.md](GIT-WORKFLOW.md): installation, backup and recovery.
- [ARCHITECTURE.md](ARCHITECTURE.md), [COMPATIBILITY.md](COMPATIBILITY.md), [docs/RESEARCH.md](docs/RESEARCH.md): implementation and source contracts.

**238/238 local Lua 5.1 tests pass.** Revision 4 fixes the missing native toggle reported in revision 3. The user reports successful revision 2 resumes. Button visibility, daily history and native saving still need live checks. This package has not been published to GitHub.

MoobStack is an independent community addon publisher, unaffiliated with Blizzard Entertainment or any server project. World of Warcraft and related marks belong to their owners.
