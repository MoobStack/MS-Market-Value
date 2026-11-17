# Validation

Run from the repository root with Lua 5.1:

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
TZ=America/New_York python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

The suite loads the actual addon modules against native API/frame fixtures and checks saved-data upgrades, scans, crafting, market filters, ledger, farming and drop display. Python checks verify supporting data and import integrity. The 1.3.1 regressions exercise empty-loot event sequences, quest/native receipt order, integrated vendor sales, session selection and tooltip hide/rebuild behavior. Later coverage checks session retention/deletion, full archive detail, scrolling selection and login/death/ghost timing.

Set `MSMV_BENCHMARK=1` to include larger synthetic workloads. Their CPU/memory figures describe fixture components, not native FPS or total addon memory. See [Validation](../VALIDATION.md) for release evidence.

Variant coverage checks use explicit November UTC dates and saved-data reloads. Farming replays cover missing close events, native visibility recovery, exclusions and the 19-award pattern from the supplied report.

Sell-page coverage checks both price fields, one-copper steps, silver/gold rollover, native callback preservation, limits, manual edits, lazy installation and AH reopening.

Watchlist regressions cover virtual scrolling, cached search/sort views, native Buy navigation, hidden item IDs, target editing, settings, grouped alerts, unchanged-scan/reload deduplication, rearming and deferred delivery. The optional 200-watch UI workload checks frame reuse and avoids metadata or pricing rebuilds while scrolling.

Sell styling coverage checks the larger panel-button hit area, native AH arrow orientation and warning placement. Watchlist search remains scoped to saved watches.

Interface-help checks cover default and saved preferences, immediate hiding, native tooltip ownership, preserved handlers, concise control/input explanations and list hover opt-out across the addon. Sell help follows the same switch; its 26×22 buttons retain native price callbacks.
