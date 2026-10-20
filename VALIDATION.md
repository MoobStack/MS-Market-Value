# Validation

**1.2.0-beta / 2026-10-20-beta001** · Test revision **6** · Tag `v1.2.0-beta-test6`

| Check | Result |
|---|---|
| Lua 5.1 behavior | **465/465 passed** |
| Runtime syntax | All 21 Lua files passed |
| Identity | Fixed beta version/build; three identical TOCs; test revision 6 |
| Dependencies | Pinned LibStub/LibAHTab bytes and notices retained |
| Actions | Transaction observers unchanged; no automated buys, sells, crafts or mail collection |
| History | Stable 1.1.0 and all fourteen prior tag objects retained |
| Native revision 6 | Portable navigation, reports, filters and editor need an in-game layout check |

The 19 new cases cover opening Ledger outside the AH, return navigation, all source totals, six direct filters, report drill-downs, dates and CSV scope, losses, cost coverage, editor validation, settings and cached refreshes. The supplied commission/manual-sale example is a regression case. All 446 previous cases remain, including automatic transactions, scanning, tooltips, crafting, history, pricing and movement filters.

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
MSMV_BENCHMARK=1 python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

## Performance

These are synthetic Lua CPU measurements from this revision, not client FPS or server results:

| Workload | Result |
|---|---|
| 5,000 items / 15 history days | 201 steps; 342.23 ms total; 4.49 ms maximum step |
| 200 watches / 15 history days | 11 steps; 6.16 ms total; 0.78 ms maximum step |
| 2,000 ledger rows, first view + 100 cached refreshes | 8.98 ms total |
| 500 completed invoices | 101 read/commit steps; 83.08 ms total; 4.38 ms maximum step |
| 10,000 ledger rows, first filtered view + 100 cached refreshes | 14.06 ms total; 5,250 matching sales |

All workloads made zero auction requests. Full 10,000-row CSV was 915,411 bytes. Repeated report refreshes reuse cached summaries and make no item-data reads. Mail reads/commits handle at most 10 entries per step, with an approximate four-millisecond target; fast collection may inspect up to 100 visible headers/invoices. Vendor reads occur only for merchant events/pending actions. Single operations and garbage collection can exceed a target budget.

## Native evidence and limits

The supplied revision-5 screenshots show an editable watch and a ledger with a commission and manual AH sale. They support the layout changes and accounting example, but do not establish automatic tracking reliability. Earlier revision-2 diagnostics establish the Forever 70450 scan/crafting/history baseline. Fixtures check panel bounds and visibility; they do not render Blizzard fonts/artwork or establish native layering, taint or disk persistence.

Automatic tracking retains revision 5's behavior. AH sale/backfill dates are first-recorded times because invoices supply no original transaction date. Mail identity is signature/expiry based; identical replacements between observations cannot always be distinguished. Vendor writes require matching item/money changes. Purchase lots are not automatically assigned to sales; craft estimates and unknown costs remain explicit.

Run the [live checklist](LIVE-TEST-CHECKLIST.md) for the new navigation/report/editor and the outstanding commodity, mailbox, vendor and reload checks. Supplier observations and Forever DE outcomes still need qualification.

The delivery report verifies commit/tag identity, source/repository/bundle restores, retained refs, byte parity and archive hashes. Packages exclude player SavedVariables.
