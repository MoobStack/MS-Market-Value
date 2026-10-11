# Behavioral fixtures

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

Version 1.1.0 has **239 behavioral cases**. They load the real runtime and bundled libraries under Lua 5.1 with controlled native API/frame doubles. A restricted-value sentinel catches inspection, formatting, comparison and arithmetic.

Coverage includes atomic scans, recovery/cooldowns, a 98,455-row copied-buffer fixture, markets/suffixes, stacks/combat tooltips, crafting arithmetic/quotes, stable recipe lists, daily history/retention, saved-table round trips, manual controls and native header layering. The release adds retention of beta prices, history, preferences and cooldown without rescanning.

Fixtures do not contact the auction server, render client artwork, establish taint behavior or prove WoW disk saving. Native functions are replaced only in this test file, never in the addon. See [VALIDATION.md](../VALIDATION.md) for supplied live evidence and [LIVE-TEST-CHECKLIST.md](../LIVE-TEST-CHECKLIST.md) for further coverage.
