# Release validation

<<<<<<< HEAD
MS Market Value **1.3.1 / 2026-11-17-release001** passed 943 Lua cases and 23 Python checks. All 33 runtime Lua files passed syntax, load order and release identity checks.

The suite covers saved data, auction scans, crafting, ledger records, farming, watchlists, price arrows and interface tooltips. Larger workloads include 16,000 market items, 200 watches and 50 saved sessions.

In-game testing on Forever client 1.60.1 build 70959 recorded a completed scan of 200,368 auction rows and 6,505 priced items.

See [release results](evidence/RELEASE-1.3.1.json) for the checks and runtime hashes.
=======
MS Market Value **1.3.1 / 2026-11-17-release001** passed **943 Lua cases and 23 Python checks/workloads** using Lua 5.1 API/frame fixtures. All 33 runtime Lua files pass syntax, load-order, identity and operation checks.

Coverage includes saved-data upgrades, scans and exact modifiers, crafting, ledger records, farming receipts/rates, empty-corpse samples, scrolling, watchlist alerts, price arrows and interface help. The final-version upgrade check preserves saved records, farming totals and user preferences. Runtime behavior matches the accepted candidate; only the release identity changed.

Larger workloads cover 16,000 market items, 200 watches, 50 saved sessions, 12,000 farming receipts and 10,000 ledger entries. Scrolling reuses frames and cached results without new price-analysis publications or background auction requests. Fixture timings do not establish native FPS or total addon memory use.

The user accepted 1.3.1 for distribution after in-game testing on client 1.60.1 / 70959 / Interface 16001. The supplied report shows a complete 200,368-row scan, 6,505 priced items and ready market analysis with 141 results. This does not claim automated coverage of every native event sequence.

Results, runtime hashes and documentation checks are in `evidence/RELEASE-1.3.1.json`; the log is `evidence/RELEASE-1.3.1-validation.txt`.
>>>>>>> parent of 4393f67 (v1.3.1)
