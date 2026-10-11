# MS Market Value

Auction prices, crafting costs and profit, vendor values, and disenchant estimates for WoW Forever. Item tooltips show each-item and actual stack prices, including during combat.

| Detail | Current test package |
|---|---|
| Publisher | MoobStack |
| Version | `1.1.0-beta` |
| Build | `2026-10-11-beta001` |
| Test revision | **1** |
| Annotated tag | `v1.1.0-beta-test1` |
| Target | WoW Forever 1.60.1 / Interface 16001 |
| Saved data | Schema 1; existing completed scans and settings retained |

## What is ready to test

- **Crafting analysis:** select a learned recipe in an open profession to see material cost, sale value, gross profit or loss, and percentage return on material cost.
- **Profitable recipes:** sort the open profession's fully priced recipes by profit per craft or return percentage. Variable yields use their minimum output for ranking.
- **Craft quotes:** set a markup percentage and copy a quote based on market material costs. Direct enchants and other services can receive material quotes even without an auctionable output.
- **Combat tooltips:** saved prices remain visible. Public stack quantities still supply stack totals; unavailable quantities show each-item prices.
- **Pause and resume:** incomplete scans retain their progress in the current game session. Resume reads the existing auction buffer without another full-scan request.

**Price history comes next**, in another test revision of this same beta. The planned 1.1.0 release will also include configurable retention up to 30 days, the latest completed scan per day, and a historic average in the tooltip. Test revision 1 does not yet collect history.

## Install

Close WoW and replace `Interface/AddOns/MSMarketValue` with the **Clean ZIP**'s addon folder. Keep WTF/SavedVariables. Use the AddOns directory belonging to the Forever client you launch, then restart the game.

Existing 1.0.0 prices are immediately usable. To refresh them, open an auctioneer, choose **MS Market Value**, and start one full scan. Only a completed scan replaces saved prices.

Open a profession and select a learned recipe. The crafting window uses the same native frames, fonts, and controls as the rest of the addon. Close it and reopen it with the **MS Market Value** button or `/msmv craft`.

| Command | Action |
|---|---|
| `/msmv` | Auction tab or settings window |
| `/msmv scan` | Start a scan, or resume a paused scan |
| `/msmv pause` or `/msmv stop` | Keep the incomplete scan and pause |
| `/msmv resume` | Resume at an open auctioneer, outside combat |
| `/msmv discard` | Discard incomplete work; keep completed prices |
| `/msmv craft` | Open crafting analysis for the open profession |
| `/msmv status` | Scan state and saved-price age |
| `/msmv diagnostics` | Copyable client, scan, and crafting details |

## Price meaning

Crafting uses the lowest unit buyouts in the latest completed scan. Owned materials retain their market cost. Profit is **before auction fees**, and return is `(sale value - material cost) / material cost × 100`. A market asking price does not guarantee a sale.

Missing material prices prevent a full cost, profit, or quote. Missing output prices still allow a material quote. The selected recipe includes readable selected optional reagents; unresolved variants, currencies, salvage, and recrafting do not receive invented profit estimates. Ranking covers fixed-reagent recipes in the open profession. If only the filtered native catalog is available, the window says that current profession filters apply.

Resume requires the original auction buffer to remain available. Reloading or quitting ends that session's incomplete work. The persistent 15-minute full-scan interval and the server's own limits still apply.

Disenchant outcomes remain a labeled Classic reference; Forever-specific loot rules are unverified.

## Documentation

- [DOCUMENTATION.md](DOCUMENTATION.md): controls, calculations, scanning, and saved data.
- [CHANGELOG.md](CHANGELOG.md): current and previous changes.
- [LIVE-TEST-CHECKLIST.md](LIVE-TEST-CHECKLIST.md): checks for this exact test revision.
- [VALIDATION.md](VALIDATION.md): local results and remaining native checks.
- [UPGRADE.md](UPGRADE.md): installation, backup, and rollback.
- [GIT-WORKFLOW.md](GIT-WORKFLOW.md): versioning, packaging, and recovery.
- [ARCHITECTURE.md](ARCHITECTURE.md), [COMPATIBILITY.md](COMPATIBILITY.md), and [docs/RESEARCH.md](docs/RESEARCH.md): implementation and source contracts.

Local Lua 5.1 checks pass; the new profession UI and resume behavior still need live testing. The earlier successful PvP scan is preserved in [docs/RELEASE-1.0.0.md](docs/RELEASE-1.0.0.md). This test package has not been published to GitHub.

MoobStack is an independent community addon publisher, unaffiliated with Blizzard Entertainment or any server project. World of Warcraft and related marks belong to their owners.
