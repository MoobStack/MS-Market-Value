# Validation

Release **1.2.0 / 2026-10-20-release001** · Tag `v1.2.0`

| Check | Result |
|---|---|
| Lua 5.1 behavior | **584/584 passed** |
| Runtime syntax/load order | All 22 Lua files; three identical TOCs |
| Stable identity | No beta/test-revision label; version/build/tag agree |
| Upgrade | 1.1.0 and beta saved data, preferences, history, ledger and pending records retained |
| Dependencies/actions | Pinned library bytes retained; no automated transaction/crafting/mail actions |
| Archives | Source/repository/bundle restore checks, byte parity, hashes and Git integrity |
| History | All 17 earlier annotated tag objects retained |

The release keeps revision 8’s runtime behavior. Two added checks cover beta-to-stable saved-data and pending-transaction retention. Existing cases cover scans, tooltip quantities/combat, crafting, history, vendor pricing, resale math, watchlists, ledger accounting, trade confirmation, loot/expenses, local/DST dates and UI filter regressions.

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
TZ=America/New_York python3 tools/validate.py --lua lua5.1 --luac luac5.1
MSMV_BENCHMARK=1 python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

Optional workloads exercise 5,000 items over 15 history days, 200 watches, 500 invoices and 10,000 ledger rows, with zero auction requests. Processing is bounded and reports reuse cached views. CPU measurements vary by host; approximate frame budgets are not guaranteed FPS limits.

## Native evidence

Earlier diagnostics show successful full scans, retained history, recipe valuations and vendor observations on Forever 1.60.1 / 70450 / Interface 16001. The user reports correct trade tips and improved filter response. The latest screenshots show a 15c daily loot row, a 14s 54c repair expense, all ten filters and a readable report: 1g 47s 06c income minus 1g 16s 38c spending equals +30s 68c cash flow.

This supports those observed paths and layout. It does not establish every recipe, guild repair, training/respec/flight/mail sequence, locale, ruleset, addon combination or disk-save round trip. Unavailable or ambiguous transaction data can still need manual review; see [Compatibility](COMPATIBILITY.md) and the [live checklist](LIVE-TEST-CHECKLIST.md). Forever DE outcomes remain unverified.

The supplied Validation JSON records the exact commit/tag, retained refs, independent archive checks and package hashes. Player SavedVariables and screenshots are excluded from code packages. Remote CI/publication was not run.
