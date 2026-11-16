# Architecture

MS Market Value 1.3.0 uses Lua 5.1, Interface 16001 and SavedVariables schema 1.

| Area | Responsibility |
|---|---|
| Core | Safe public-value access, settings, prices, history and player records |
| Auction / Market | Full-scan copying, exact modifier identity and bounded opportunity ranking |
| Crafting | Learned-recipe costs, profit estimates and quotes |
| Farming / Drops | Acquired-value sessions, sampled loot and filtered tooltips |
| UI / Integrations | Native frames, tooltip hooks and event handling |

Only a completed scan replaces current prices. Full requests are user-started and cooldown-limited. Market analysis reuses verified item metadata, retains at most 500 results and spreads work across frames. Reference rows and personal counts remain separate; display filtering never rewrites observations.

Persistent records include prices, preferences, cooldowns, history, watchlists, ledger entries, farming summaries and personal drop samples. Runtime caches remain outside SavedVariables. Unsupported saved formats are preserved. Native actions remain under player control.

The three TOCs load the same 30 Lua files. Bundled-library hashes and focused behavioral checks are enforced by `tools/validate.py`.
