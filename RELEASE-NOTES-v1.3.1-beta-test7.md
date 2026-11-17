# MS Market Value 1.3.1-beta — Test revision 7

Build `2026-11-16-beta001`. This remains a test build.

## Changes

- Short help tooltips explain unfamiliar buttons, filters and settings across the addon. Money inputs clarify units, per-item versus whole-lot amounts, and what zero or a blank field means.
- **Tooltips → Addon interface tooltips** is enabled by default. Turn it off to hide control help and list hover details inside addon windows, including help for the addon buttons on native AH pages. Clicks, selection and row highlights keep working. Item-value and world-drop displays retain their existing settings.
- The red Sell-page arrows are slightly smaller: 26×22 each instead of 28×24. They stay centered beside copper and still change the unit price by one copper, with normal rollover and total updates.

Existing prices, watches, targets, sessions, observations and preferences are kept. Watchlist search continues to filter items already watched.

## Install and check

Close WoW and replace the MSMarketValue folder using the Clean ZIP. Keep SavedVariables; back them up before testing. Diagnostics should show test revision 7.

1. In `/msmv`, check that Addon interface tooltips is checked under Tooltips. Hover Restart scan, a price input and unfamiliar controls in the other addon windows. Descriptions should be short and readable.
2. Disable the option while a help tooltip is visible: it should disappear immediately. Check control and list-row hovers in Crafting, Opportunities, Watchlists, Ledger and Farming. Clicks, search, editing and row highlights should still work.
3. Item-price and creature/harvesting tooltips should follow their own settings. Enable interface help again and confirm list details and control descriptions return. Your choice should survive `/reload`.
4. Check both commodity and equipment Sell pages. The red arrows should fit comfortably beside copper. Verify 99c/1s and 99s 99c/1g rollover; each click changes unit price by 1c and updates the total normally.

The local checks do not render game frames. Confirm tooltip placement, seven-row settings spacing and button size in game; include a screenshot and diagnostics if anything overlaps.
