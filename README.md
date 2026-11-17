# MS Market Value

**Version 1.3.1 · WoW Forever · By MoobStack**

Auction prices, crafting profits, farming estimates, drop rates and a personal gold ledger in one addon.

## Install

Close WoW and extract the Clean ZIP into `Interface/AddOns`. The addon folder should be `Interface/AddOns/MSMarketValue`. Enable it on the character-selection screen. When updating, keep your SavedVariables; they hold prices, settings and personal records.

## What it does

- **Prices and crafting:** save AH prices, build daily history and add vendor, auction and disenchant values to item tooltips. Compare learned recipes or prepare a crafting quote.
- **Opportunities:** find resale candidates and price movements, with separate item modifiers and rarity/supply filters. Sell-page arrows adjust unit price by one copper.
- **Watchlists:** save buying targets, search and sort your watches, then click an item for its Buy page. Quiet alerts highlight new or improved matches.
- **Farming:** track acquired value, hourly rates and a located farming peak. Scroll item details, manage saved sessions and resize or lock the small display.
- **Drop rates:** view reference rates or personal observations for creatures and harvesting. Needed quest drops come first; choose sorting, rarity and item limits.
- **Ledger:** review purchases, sales, commissions, tips, loot and expenses by local date. Edit entries and export CSV.

## First steps

1. At an auctioneer, open **MS Market Value → Scan entire AH**. Keep the AH open until **Local copy** is complete. Full scans have a 15-minute minimum interval.
2. Open a profession and click **Show profits**. Visit a supplies vendor to learn your discounted material costs.
3. Use **MS Opportunities → All items** for current prices. Resale needs three earlier priced UTC days for each exact modifier by default.
4. Open Farming to review your session. Timing starts idle at login; Resume, combat or received loot starts it. Quest rewards default to session totals only, and death pause is on by default.

Hover unfamiliar controls for help. Turn this off under **Tooltips → Addon interface tooltips**. Display preferences are saved automatically.

## Commands

| Command | Opens |
|---|---|
| `/msmv` | Main settings |
| `/msmv craft` | Crafting profits and quotes |
| `/msmv market` | Opportunities, at an auctioneer |
| `/msmv watch` | Watchlists |
| `/msmv ledger` | Personal ledger |
| `/msmv farm` | Farming report and display settings |
| `/msmv drops` | Drop-rate display and observation settings |
| `/msmv diagnostics` | A copyable support report |

AH prices are asking prices, and farming value is an estimate rather than realized profit. Classic drop and disenchant references may differ in Forever. Buying, selling and crafting remain under your control.

[User guide](DOCUMENTATION.md) · [What's new in 1.3.1](RELEASE-NOTES-v1.3.1.md) · [Changelog](CHANGELOG.md) · [Updating](UPGRADE.md) · [Compatibility](COMPATIBILITY.md)
