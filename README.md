# MS Market Value

**Version 1.3.0 · WoW Forever · By MoobStack**

Auction prices, crafting profits, farming estimates, drop rates and a personal gold ledger in one addon.

## Install

Close WoW and extract the Clean ZIP into `Interface/AddOns`. The folder should be `Interface/AddOns/MSMarketValue`. Enable it on the character-selection screen. When updating, keep your `WTF/SavedVariables` files; they hold your prices, settings and records.

## What it does

- **Prices and crafting:** save AH prices, build daily history and see vendor, auction and disenchant values in tooltips. Compare learned recipes by material cost, net profit and return, or prepare a crafting quote.
- **Market opportunities:** search resale candidates and price movements, filter by rarity and supply, and keep item modifiers separate. Save watchlist targets from Opportunities or the Buy page.
- **Farming:** track acquired value, session average, recent rate and a located farming peak. Resize or lock the gold display and let idle pause handle breaks.
- **Drop rates:** view reference rates and personal observations for creatures and harvesting. Personal drops fill missing entries; needed quest items stay first. Choose sorting, rarity and item limits.
- **Ledger:** review purchases, sales, commissions, tips, loot and expenses by local date. Edit entries, separate known costs from estimates and export CSV.

## First steps

1. At an auctioneer, open **MS Market Value → Scan entire AH**. Keep the AH open until **Local copy** is complete. New full scans have a 15-minute minimum interval.
2. Open a profession and click **Show profits**. Visit a supplies vendor so crafting calculations can learn your purchase costs.
3. Use **MS Opportunities → All items** for current prices. Resale signals need three earlier priced UTC days for each exact modifier by default; the market's total saved days may be higher.
4. Open the farming, drop or ledger tools with the commands below. Settings and display choices are saved automatically.

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

AH prices are asking prices, and farming value is an estimate rather than realized profit. Some drop and disenchant references come from Classic and may differ in Forever. Buying, selling, crafting and other game actions remain under your control.

[User guide](DOCUMENTATION.md) · [What's new](CHANGELOG.md) · [Updating](UPGRADE.md) · [Compatibility](COMPATIBILITY.md)
