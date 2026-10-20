# Validation

**1.2.0-beta / 2026-10-20-beta001** · Test revision **5** · Tag `v1.2.0-beta-test5`

| Check | Result |
|---|---|
| Lua 5.1 behavior | **446/446 passed** |
| Runtime syntax | All 21 Lua files passed |
| Identity | Fixed beta version/build; three identical TOCs; test revision 5 |
| Dependencies | Pinned LibStub/LibAHTab bytes and notices retained |
| Actions | Native transaction functions are observed, never invoked/replaced; no automated buys, sells, crafts or mail collection |
| History | Stable 1.1.0 and all thirteen prior tag objects retained |
| Native revision 5 | Buy buttons, commissions, transaction ordering/reconciliation and reports need live checks |

The 58 new cases cover item/commodity success versus failed requests, exact captured totals, receipt reconciliation, offline-mail backfills, repeated/identical/reordered invoices, fast collection, reloads, capacity retry, vendor quantities/money, buyback prices, commissions/tips/cost bases, date/type reporting, filtered CSV, watch-header controls, idle work and restricted fields. Earlier scanning, tooltips, crafting, history, net-profit/quote/watchlist behavior and the movement-filter regression remain covered.

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
MSMV_BENCHMARK=1 python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

## Performance

These are synthetic Lua CPU measurements, not client FPS or server results:

| Workload | Result |
|---|---|
| 5,000 items / 15 history days | 197 steps; 326.46 ms total; 9.13 ms maximum step |
| 200 watches / 15 history days | 11 steps; 6.05 ms total; 0.57 ms maximum step |
| 2,000 ledger rows, first view + 100 cached refreshes | 7.86 ms total |
| 500 completed invoices | 101 read/commit steps; 77.77 ms total; 4.17 ms maximum step |
| 10,000 ledger rows, first filtered view + 100 cached refreshes | 14.36 ms total; 5,250 matching sales |

All workloads made zero auction requests. Full 10,000-row CSV was 915,411 bytes. Mail reads/commits handle at most 10 entries per step, with an approximate four-millisecond target. An explicit fast-collection hook may inspect up to 100 visible headers/invoices to preserve duplicate multiplicity. Vendor reads occur only for merchant events/pending actions. Idle transaction checks read no bags or item metadata. Single operations and garbage collection can exceed a target budget.

## Native evidence and limits

The supplied screenshots show revision 4's quote and ledger draft; revision 2 diagnostics establish the earlier Forever 70450 scan/crafting/history baseline. They do not qualify revision 5. Matching client sources establish fields and handlers, not live ordering or native UI fit.

The ledger does not infer completed sales from scan changes. AH sale/backfill dates are first-recorded times because the API supplies no original transaction date. Mail identity is signature/expiry based; identical replacements between observations cannot always be distinguished. Vendor writes require matching item/money changes and reject unsupported cases. Automatic known-cost allocation to sold stock is not implemented. Craft estimates and unknown costs remain explicit.

Run the [live checklist](LIVE-TEST-CHECKLIST.md), especially commodity price changes, fast collection, other mailbox addons, repeated invoices, vendor buybacks and reloads. Supplier observations and Forever DE outcomes still need native qualification.

The delivery report verifies commit/tag identity, source/repository/bundle restores, retained refs, byte parity and archive hashes. Packages exclude player SavedVariables; local tests do not prove native persistence or taint behavior.
