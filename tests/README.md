# Validation

Run from the repository root with Lua 5.1:

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
TZ=America/New_York python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

The suite loads the actual addon modules against native API/frame fixtures and checks saved-data upgrades, scans, crafting, market filters, ledger, farming and drop display. Python checks verify supporting data and import integrity. The 1.3.1 regressions exercise empty-loot event sequences, quest/native receipt order, integrated vendor sales, session selection and tooltip hide/rebuild behavior.

Set `MSMV_BENCHMARK=1` to include larger synthetic workloads. Their CPU/memory figures describe fixture components, not native FPS or total addon memory. See [Validation](../VALIDATION.md) for release evidence.
