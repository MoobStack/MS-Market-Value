# In-game checks for 1.3.3

- Complete a faction scan, then log in to a character at a neutral auctioneer. The same countdown should carry over. When it expires, scan the neutral house and verify that only the neutral snapshot updates.
- On the first neutral visit to Opportunities after login, check that Arbitrage opens. Switch **Basis** and verify the **Faction avg**, spread and profit update where the averages differ. Click rows marked **Neutral** and **Faction** and verify both open the exact item’s neutral listings. Return to a faction auctioneer and check that the regular view is restored.
- Close a faction house before a scan receives its first response. Reopen it and click a saved Opportunities result while the scan is paused. Buy should open when the game is ready for a search.
- Hover over gear with and without a price for its exact stat roll. Only prices using any variant should show an asterisk.
- Confirm the market and saved prices with realm names hidden. If prompted, choose the ruleset before scanning. Verify activity from before the choice is still recorded.
- Complete two AH scans in the same UTC day. Check that Intraday uses both in item tooltips and that Opportunities compares with earlier scans. After midnight UTC, confirm the daily average remains and today's scan count starts over.
- Check that the scan bar fills Price snapshot when complete and that the version sits above it. Try Return, Profit and Movement in both Rising and Falling.
- Click and drag the minimap button, then hide it under Tooltips. Check exact-modifier history progress and live Buy navigation.
- Scroll crafting recipes and watchlists; check search, sorting, target editing and quiet alerts. Verify Sell-page arrows change unit price by one copper and update totals.
- Check login/death idle, manual pause, quest-only session totals and normal loot. Sell a collected item and confirm farming value is not added again.
- Select, scroll and manage saved sessions. Check an empty corpse, then skin and loot a creature without overlapping drop sections.
- Switch Addon interface tooltips off and on. Help and list details should follow the option while clicks and editing continue to work.

Include `/msmv diagnostics`, the client build and the steps that reproduce a problem.
