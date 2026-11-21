# MS Market Value user guide

Start with the [README](README.md) for installation, commands and a quick setup.

## Prices and crafting

At an auctioneer, choose **Scan entire AH** on the MS Market Value tab and keep the AH open until **Local copy** is complete. The addon detects your ruleset when possible. Confirm it if asked, or use **Change ruleset** in Price snapshot to set it later. The choice is saved for that character.

A completed scan replaces the current snapshot. You can pause and resume during the same login. Unfinished scans expire when you reload or log out.

The **Prices** switch in **Price settings** selects the estimates used across the addon. **Daily** gives each saved UTC date equal weight, including today so far. **Intraday** averages today's completed scans. Each scan contributes its lowest unit price for each item or exact modifier with a buyout. At the UTC date change, the addon keeps the day's averages and drops the individual price samples. History keeps 1–30 UTC days.

Open a profession and click **Show profits**, or use `/msmv craft`. Scroll, search and sort learned recipes, then select one for materials, net profit and break-even price. Visit supplies vendors to learn discounted costs. Other materials use market replacement value, including items you own; missing prices stay unknown.

**Pricing** sets the AH cut, markup, service labor and minimum charge. Quotes can be copied or placed in a chat draft. **Record sale** adds a commission to the ledger; leave price blank to use the quote, and enter quantity plus any total tip. Saved material costs remain estimates until you enter actual cost.

## Opportunities and watchlists

At the AH, **MS Opportunities → All items** shows the latest asking prices and stock. **Basis** changes the reference for that page. Daily uses earlier UTC dates, with three priced dates per variant by default. Intraday uses earlier scans today, with at least one priced scan per variant. Right-click **Basis** to follow the addon setting again.

Apply keywords, rarity and supply filters. Use **Sort** to order Rising or Falling by movement, return or net profit per item. Left-click a result for live listings, or use **Watch selected** to save targets. On the Sell page, the red arrows beside copper adjust unit price by one copper and update the total.

Add watches from the Buy page, Opportunities or an item link. Search filters items already watched. Scroll the list, click headings to sort, or enable **Targets met only**. Left-click opens Buy; right-click or Edit changes targets. Money inputs are gold per item, zero disables a target, and all enabled targets must pass.

**Watch settings** controls quiet reviews after scans or AH visits and an optional chat summary. New matches or lower matched prices can trigger one grouped review; unchanged prices stay quiet. Alerts wait while you sell or edit.

[Opportunity details](docs/MARKET-OPPORTUNITIES.md) · [Watchlists and ledger](docs/ECONOMY-TOOLS.md)

## Farming and drops

Use `/msmv farm` for session value, hourly rates, a located five-minute peak and scrolling item details. Select past sessions from the menu; **Current session** returns to the live report. **Manage** sets a 0–50-save limit, five by default, or deletes one save after confirmation.

Timing starts idle at login. Resume, combat or received loot starts it. Death pause is on by default; resurrection alone leaves it idle. Inactivity pause defaults to five minutes. A manual pause stays paused until you resume it.

Quest rewards default to session totals only, with optional hourly inclusion; peaks always exclude quests. Farming estimates acquired value, and later sales do not count it again. Resize or lock the small display in Farming settings.

Use `/msmv drops` to choose reference or personal rates, sorting, rarity and item limits. Personal observations fill missing reference entries. Needed quest drops stay visible and first; inspected empty corpses count toward personal samples.

[Farming and drop details](docs/FARMING-AND-DROPS.md)

## Ledger and help

Use `/msmv ledger` for income, spending, cash flow and profit by local date. Filter Transactions and click a row to edit it outside combat. Blank cost means unknown; zero means no cost. CSV follows your selected dates and filters.

Hover unfamiliar controls for short help. **Tooltips → Addon interface tooltips** hides control help and list hover details when switched off. Item-value and world-drop tooltips have separate settings.

AH prices are asking prices. Net estimates use the configured AH cut but exclude deposits and unsold listings. For support, include `/msmv diagnostics`, the client build and what happened. Keep SavedVariables when updating; see [Updating](UPGRADE.md).
