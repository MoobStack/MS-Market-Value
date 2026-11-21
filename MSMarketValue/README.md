# MS Market Value

**1.3.3 for WoW Forever**

Auction prices, crafting profits, farming estimates, drop rates and a personal gold ledger in one addon.

## Install

Close WoW and extract the Clean ZIP into `Interface/AddOns`. The addon folder should be `Interface/AddOns/MSMarketValue`. Enable it on the character-selection screen. Keep SavedVariables when updating to retain prices, settings and personal records.

## What it does

- **Prices and crafting** Store Auction House prices, compare learned recipes and prepare crafting quotes. Item tooltips can show vendor, auction and disenchant values.
- **Opportunities** Find resale candidates, price movements, and trades between the faction and neutral houses. Sell-page arrows adjust unit price by one copper.
- **Watchlists** Save buying targets, search and sort your watches, then click an item for its Buy page. Quiet alerts highlight new or improved matches.
- **Farming** Track acquired value, hourly rates and your best five-minute stretch. Scroll item details, manage saved sessions and resize or lock the small display.
- **Drop rates** View reference rates or personal observations for creatures and harvesting. Needed quest drops come first, with sorting, rarity and item limits for the rest.
- **Ledger** Review purchases, sales, commissions, tips, loot and expenses by local date. Edit entries and export CSV.

## First steps

1. At a faction auctioneer, open **MS Market Value → Scan entire AH**. Confirm the ruleset or house if prompted. Keep the AH open until **Local copy** is complete. Both auction houses share the account's 15-minute full-scan cooldown.
2. Under **Price settings**, choose **Daily** for an average across saved UTC dates or **Intraday** for today's scans. Open a profession and click **Show profits** to compare recipes.
3. Use **MS Opportunities → All items** for current faction prices. On your first neutral visit to **MS Opportunities** each login, **Arbitrage** opens automatically. Use **Basis** to compare the latest neutral prices with faction Daily or Intraday averages.
4. Open Farming to review your session. Timing starts idle at login; Resume, combat or received loot starts it. Quest rewards default to session totals only, and death pause is on by default.

Click the gold coin on the minimap to open the addon. Drag it along the rim to move it, or uncheck **Show minimap button** under **Tooltips** to hide it.

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
| `/msmv ruleset` | Ruleset selection for this character |
| `/msmv diagnostics` | A copyable support report |

AH prices reflect asking prices. Farming totals estimate the value of what you collect. Classic drop and disenchant references may differ in Forever.

[User guide](DOCUMENTATION.md) · [What's new in 1.3.3](RELEASE-NOTES-v1.3.3.md) · [Changelog](CHANGELOG.md) · [Updating](UPGRADE.md) · [Compatibility](COMPATIBILITY.md)
