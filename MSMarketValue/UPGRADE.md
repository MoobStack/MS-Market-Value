# Updating to 1.3.0

1. Close WoW and back up `WTF/Account/<account>/SavedVariables/MSMarketValueDB.lua` and its `.bak` file.
2. Replace `Interface/AddOns/MSMarketValue` with the Clean ZIP's folder. Keep WTF/SavedVariables.
3. Start the game and check that `/msmv diagnostics` shows version 1.3.0.

Your prices, history, preferences, watchlists, ledger and personal records are kept. A fresh scan adds full modifier and supply details; older item-wide history remains saved but cannot identify a specific modifier's movement. Unfinished scans cannot survive a reload or logout.

Drop sorting defaults to highest rate first with all rarities. Needed quest drops remain visible and first. Choose Expected item value to use value-based ordering. Farming idle pause defaults to five minutes unless you have already changed it.

Disable an older separate reference addon if it overrides the bundled display. Install only the Clean ZIP in AddOns; keep source archives elsewhere.

For rollback, close WoW and restore both an older addon and its matching SavedVariables backup. Shortening price-history or ledger retention removes older records, so export or back up anything you want to keep first.
