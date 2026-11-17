# User guide

MS Market Value 1.3.1-beta for WoW Forever. The [README](README.md) covers installation, commands and first steps.

## Prices and history

Start a full scan at an auctioneer from the MS Market Value tab. A completed scan replaces current prices; a partial or failed scan keeps the previous snapshot. Pause and resume within the same login session. After Local copy is complete, processing can resume without the original server buffer. Reloading or logging out ends unfinished work.

Tooltips can show vendor sell value, historic average, current AH low and disenchant estimates. Known stack quantities show each-item and stack totals. Stale or missing prices are labeled. History keeps 1–30 UTC days; ordinary item prices use the latest completed scan for each day. Exact modifiers retain their latest priced observation within that UTC day, even when a later scan no longer lists them. The average's day count is the number of days priced for that item, not every day saved for the market.

On the AH Sell page, the red arrow buttons beside the copper field increase or decrease the unit price by one copper. Silver and gold roll over automatically, and the total updates as usual. Prices stop at zero.

Hover unfamiliar buttons, filters and settings for short explanations. **Tooltips → Addon interface tooltips** is on by default; turn it off to hide control help and list hover details inside addon windows. Item-value and world-drop tooltips have their own display settings.

## Crafting and quotes

Open a profession and click Show profits, or use `/msmv craft`. Select a learned recipe to inspect its materials, cost, net profit, return and break-even price. Search or sort recipes and choose profitable recipes or all recipes. Scroll with the mouse wheel or native scrollbar; click any visible recipe for details. Automatic opening is optional.

Visit a supplies vendor to learn your discounted material costs. Other materials use market replacement value, including items you already own. Missing prices stay unknown rather than becoming zero. The AH cut defaults to 5%; deposits and unsold stock are excluded.

Pricing settings control markup, labor, minimum charge and customer-supplied materials. Quotes can be copied or placed in a chat draft. Record sale adds a commission to the ledger; leave its price blank to use the quote, and enter quantity and any total tip. Material costs saved from a quote remain estimates until you enter actual cost.

## Opportunities and watchlists

At the AH, open MS Opportunities. All items shows current prices; Resale, Rising and Falling need earlier history for the exact modifier. Apply keywords, rarity and supply filters to narrow the list. Missing baselines show a priced-day count such as 2/3 days; hover or right-click to see the UTC dates. Left-click a result for live Buy listings, right-click for details, or use Watch selected to save targets.

Use Watch item on the Buy page or Watch selected on Opportunities to save targets. The watchlist scrolls, supports search and target-only filtering, and sorts by clickable headers. Search filters items already on the watchlist; use the AH Buy page to find other items. Target status is separate from item-name rarity. Left-click an item for its Buy page; right-click or Edit changes its targets. Zero disables a target; all enabled targets must pass. Watch settings controls quiet reviews after scans or AH visits and an optional chat summary. Unchanged prices stay quiet, and reviews wait while you sell or edit. See [Money tools](docs/ECONOMY-TOOLS.md) for watchlist details and [Opportunities](docs/MARKET-OPPORTUNITIES.md) for history rules.

## Farming, drops and the ledger

Use `/msmv farm` for session totals, rates and display options. Select a saved session from the menu; Current session returns to the live report. Manage sets a 0–50-session limit or deletes the selected saved session after confirmation. Both item views scroll. Quest rewards default to the session total only, with an option to include them in hourly rates; peaks always exclude quests. Timing starts idle after login. Resume, combat or received loot starts it. Pause on death is on by default; resurrection alone leaves it idle. Inactivity pause also defaults to five minutes, and a manual pause stays paused. `/msmv drops` controls collection, reference/personal display, sorting, rarity and resets. See [Farming and drops](docs/FARMING-AND-DROPS.md).

Use `/msmv ledger` for income, spending, cash flow and profit reports. Choose local dates, filter Transactions and click a row to edit it outside combat. Other expenses have category checkboxes; CSV follows the active filters. See [Money tools](docs/ECONOMY-TOOLS.md) for tracking and cost rules.

## Updating and support

Close WoW before replacing the addon or backing up `WTF/Account/<account>/SavedVariables/MSMarketValueDB.lua`. Keep SavedVariables during updates. If something looks wrong, include `/msmv diagnostics`, your client build and a short description of what happened.
