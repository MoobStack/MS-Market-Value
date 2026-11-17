# MS Market Value 1.3.1-beta — Test revision 4

Build `2026-11-16-beta001`. This remains a test build.

## Sell-page arrows

Two small arrows sit beside the native copper field, up over down. Each click adjusts the unit price by one copper. They use the game's button textures and work on both commodity and individual-item Sell pages, adjusting the primary unit/buyout price. The separate bid field is unchanged.

Silver and gold roll over automatically. The controls stop at zero and at the gold input's limit. Native totals and price validation update through the existing price handler. Quantity, duration and keyboard editing work as before. Choose Create Auction as usual.

## Latest test results

The supplied test revision 3 AH report confirms two earlier exact-format dates, November 15 and 16. Among the matching modified items, 1,470 have no earlier priced date, 1,498 have one and 1,927 have two; none yet meet the default three-day requirement. That accounts for the missing resale baselines in this report. Keep collecting scans; each exact variant needs its own priced dates.

The combat report now shows ordinary loot, harvesting, recent rates and a farming peak, with no ignored money messages. This is useful native evidence that receipts are counting again. It does not by itself verify every quest, death or transaction event order. The earlier fixes remain included.

## Install and check

Close WoW, back up SavedVariables and replace the MSMarketValue folder using the Clean ZIP. Keep SavedVariables. Diagnostics should show test revision 4.

1. Place an item on the Sell page. Confirm the vertical arrows fit beside copper without covering the field, warning or other controls.
2. Starting at 6s 19c with quantity 5, click up once: the unit price should be 6s 20c and the total 31s. Click down to return to 6s 19c and a 30s 95c total.
3. Check both directions across 99c/1s and 99s 99c/1g. Down at zero must stay at zero. Type a price manually and check another click.
4. Try a commodity and an individual equipment item. On equipment, check the separate bid field remains unchanged. Switch tabs, close/reopen the AH and select a different item; there should still be one arrow pair per price field.

Native appearance and the new client build's event behavior still need in-game confirmation. Include the Sell-page price arrows diagnostic line if the controls are missing or unresponsive.
