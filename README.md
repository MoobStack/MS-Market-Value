# MS Market Value

Auction prices, crafting costs and profit, vendor values, and disenchant estimates for WoW Forever. Item tooltips show each-item and actual stack prices, including during combat.

| Detail | Current test package |
|---|---|
| Publisher | MoobStack |
| Version | `1.1.0-beta` |
| Build | `2026-10-11-beta001` |
| Test revision | **2** |
| Annotated tag | `v1.1.0-beta-test2` |
| Target | WoW Forever 1.60.1 / Interface 16001 |
| Saved data | Schema 1; existing completed scans and settings retained |

## What is ready to test

- **Crafting analysis:** select a learned recipe in an open profession to see material cost, sale value, gross profit or loss, and percentage return on material cost.
- **Profitable recipes:** a stable list of fully priced recipes, sorted by profit per craft or return percentage. Updates replace the list only when all recipes have been checked.
- **Craft quotes:** concise `Recipe - price ea` quotes, with the native recipe link when available. Copy them or insert a chat draft. Direct enchants receive material quotes without an auctionable output.
- **Combat tooltips:** saved prices remain visible. Public stack quantities still supply stack totals; unavailable quantities show each-item prices.
- **Pause and resume:** auction rows are copied locally before pricing finishes. Once the copy is complete, closing the AH cannot erase it; Resume continues without another server request.

**Price history comes next**, in another test revision of this same beta. The planned 1.1.0 release will also include configurable retention up to 30 days, the latest completed scan per day, and a historic average in the tooltip. Test revision 2 does not yet collect history.

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
| `/msmv restart` | Start a fresh scan when the cooldown allows; keep completed prices |
| `/msmv discard` | Discard incomplete work; keep completed prices |
| `/msmv craft` | Open crafting analysis for the open profession |
| `/msmv status` | Scan state and saved-price age |
| `/msmv diagnostics` | Copyable client, scan, and crafting details |

## Price meaning

Crafting uses the lowest unit buyouts in the latest completed scan. Owned materials retain their market cost. Profit is **before auction fees**, and return is `(sale value - material cost) / material cost × 100`. A market asking price does not guarantee a sale.

Missing material prices prevent a full cost, profit, or quote. Missing output prices still allow a material quote. The selected recipe includes readable selected optional reagents; unresolved variants, currencies, salvage, and recrafting do not receive invented profit estimates. Ranking covers fixed-reagent recipes in the open profession. If only the filtered native catalog is available, the window says that current profession filters apply.

Keep the AH open until **Local copy** shows **complete**. Pause stops pricing while unread rows continue copying with the AH open. If the client clears rows before copying finishes, progress stays paused; retry if the buffer returns, or restart after the cooldown. Reloading or quitting ends incomplete work. The 15-minute request interval still applies.

Disenchant outcomes remain a labeled Classic reference; Forever-specific loot rules are unverified.

## Documentation

- [DOCUMENTATION.md](DOCUMENTATION.md): controls, calculations, scanning, and saved data.
- [CHANGELOG.md](CHANGELOG.md): current and previous changes.
- [LIVE-TEST-CHECKLIST.md](LIVE-TEST-CHECKLIST.md): checks for this exact test revision.
- [VALIDATION.md](VALIDATION.md): local results and remaining native checks.
- [UPGRADE.md](UPGRADE.md): installation, backup, and rollback.
- [GIT-WORKFLOW.md](GIT-WORKFLOW.md): versioning, packaging, and recovery.
- [ARCHITECTURE.md](ARCHITECTURE.md), [COMPATIBILITY.md](COMPATIBILITY.md), and [docs/RESEARCH.md](docs/RESEARCH.md): implementation and source contracts.

Local Lua 5.1 checks pass; Test revision 2 still needs native UI and resume checks. The earlier successful PvP scan is preserved in [docs/RELEASE-1.0.0.md](docs/RELEASE-1.0.0.md). This test package has not been published to GitHub.

MoobStack is an independent community addon publisher, unaffiliated with Blizzard Entertainment or any server project. World of Warcraft and related marks belong to their owners.
