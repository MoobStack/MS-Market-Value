# Architecture

MS Market Value 1.3.2 uses Lua 5.1, Interface 16001 and SavedVariables schema 1.

| Area | Responsibility |
|---|---|
| Core | Safe public-value access, settings, prices, history and player records |
| Auction / Market | Full-scan copying, exact modifier identity and bounded opportunity ranking |
| Crafting | Learned-recipe costs, profit estimates and quotes |
| Farming / Drops | Acquired-value sessions, sampled loot and filtered tooltips |
| UI / Integrations | Native frames, tooltip hooks and event handling |

Only a completed scan replaces current prices. Full requests are user-started and cooldown-limited. Market analysis reuses verified item metadata, retains at most 500 results and spreads work across frames. Reference rows and personal counts remain separate; display filtering never rewrites observations.

Persistent records include prices, preferences, cooldowns, history, watchlists, ledger entries, farming summaries and personal drop samples. Runtime caches remain outside SavedVariables. Unsupported saved formats are preserved. Native actions remain under player control.

Markets use region, ruleset and faction. Ruleset confirmation is saved per character. Character activity can record while market identity is pending. Today's scan prices roll into one daily average per item and exact modifier at the UTC date change.

The three TOCs load the same 34 Lua files. `tools/validate.py` checks the load order, bundled-library hashes and addon behavior.

Farming rate history uses its own schema 2. Upgrades preserve session totals/time and observations while starting new recent/peak coverage. Quest and world-loot receipts are reconciled separately; only non-quest minute values can set a peak. Empty inspections require a recent, identified dead-unit interaction. Tooltip sections are owned and rebuilt as a unit rather than appended repeatedly.

Saved-session retention is per character/market, 0–50 with a default of five. New archives copy up to 500 item rows and 20 recent receipts; older top-item summaries remain readable. Both scrolling lists reuse fixed row pools and cached results. Login/death waiting is separate from the saved manual pause and the inactivity timer.

UI/Help owns interface tooltip binding and the saved display preference. It hooks existing hover handlers once and checks the preference at display time. Only its own tooltip owner is hidden; item-price and world-drop integrations keep separate settings.
