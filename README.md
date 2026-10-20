# MS Market Value

Auction prices, market opportunities, crafting costs and profit, price history and disenchant estimates for WoW Forever.

**Version 1.2.0-beta** · Build `2026-10-20-beta001` · Test revision **2**

For Forever 1.60.1 / Interface 16001. By MoobStack. The version and build stay fixed throughout 1.2.0 testing; test revisions identify changes.

## Features

- Full Auction House scans with saved prices, pause/resume and recovery after closing the AH once its rows have been copied.
- Item tooltips show vendor, historic average, recent AH and applicable disenchant values, including during combat. Actual stacks show Each / Stack totals.
- **MS Opportunities**, before the MS Market Value AH tab, finds resale candidates and significant price moves from saved history. Filter by price drop, return and net profit in gold. Click an item to open its native live listings.
- Crafting uses your observed vendor purchase cost for normal vendor materials and AH prices for other materials.
- Crafting shows material cost, sale value, profit or loss and percentage return. Sort recipes by profit or return, with an option to include unprofitable and unpriced recipes.
- Craft quotes use the native recipe link when available. Copy a quote or insert a chat draft; sending stays under your control.
- Keep 1–30 days of daily prices, using each UTC day's latest completed scan. Auto-open for crafting profits is optional and off by default.

## Install and use

Close WoW and replace `Interface/AddOns/MSMarketValue` with the **Clean ZIP**'s addon folder. Keep WTF/SavedVariables to retain prices, history and settings. Existing users do not need a new scan just to upgrade.

At an auctioneer, select **MS Market Value → Scan entire AH**. Keep the AH open until **Local copy** is complete. You can then pause, close/reopen and resume without another request. Incomplete work ends on reload/logout; new full requests have a 15-minute minimum interval.

Open a profession and click **Show profits** beside its close button. **Recipe list → Show all recipes** includes losses and unavailable estimates. In `/msmv → Crafting & history`, set auto-open and history length. History defaults to 30 days.

| Command | Action |
|---|---|
| `/msmv` | Open the AH tab or settings |
| `/msmv scan` | Start a scan or resume paused work |
| `/msmv pause` or `/msmv stop` | Pause incomplete work |
| `/msmv resume` | Resume at an open auctioneer, outside combat |
| `/msmv restart` | Start fresh when the cooldown allows |
| `/msmv discard` | Discard incomplete work; keep saved prices |
| `/msmv craft` | Open analysis for the open profession |
| `/msmv market` | Open market opportunities at an auctioneer |
| `/msmv status` or `/msmv diagnostics` | Show status or copy a problem report |

Visit a supplies vendor to learn your discounted purchase prices. Known vendor materials without a current observation say **visit supplier**; inflated AH listings are not used instead. Other materials use the latest scan's lowest unit buyouts, including owned materials. Profit is **before fees**; asking prices do not guarantee sales. Missing prices or unsupported recipes stay unavailable. History averages the days with a price equally; one day is enough. Disenchant outcomes use an **unverified Classic reference** for Forever.

See [DOCUMENTATION.md](DOCUMENTATION.md) for calculations and controls, [CHANGELOG.md](CHANGELOG.md) for changes, [UPGRADE.md](UPGRADE.md) for backup/rollback, and [GIT-WORKFLOW.md](GIT-WORKFLOW.md) for source recovery and publication. [ARCHITECTURE.md](ARCHITECTURE.md), [COMPATIBILITY.md](COMPATIBILITY.md) and [VALIDATION.md](VALIDATION.md) cover implementation and testing.

**318/318 local Lua 5.1 tests pass.** The revised filters, layout and live item navigation need in-game confirmation. See [docs/MARKET-OPPORTUNITIES.md](docs/MARKET-OPPORTUNITIES.md), [docs/VENDOR-COSTS.md](docs/VENDOR-COSTS.md) and [VALIDATION.md](VALIDATION.md) for controls, calculations and checks.

MoobStack is an independent community publisher, unaffiliated with Blizzard Entertainment or any server project. World of Warcraft and related marks belong to their owners.
