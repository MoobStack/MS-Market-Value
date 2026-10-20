# Validation

**1.2.0-beta / 2026-10-20-beta001** · Test revision **8** · Tag `v1.2.0-beta-test8`

| Check | Result |
|---|---|
| Lua 5.1 behavior | **582/582 passed** |
| Runtime syntax | All 22 Lua files passed |
| Identity | Fixed beta version/build; three identical TOCs; test revision 8 |
| Dependencies | Pinned LibStub/LibAHTab bytes and notices retained |
| Actions | No automated auction, crafting, merchant, mail, repair, training, flight or trade actions |
| History | Stable 1.1.0 and all sixteen prior tag objects retained |
| Native revision 8 | Loot/spending event ordering, category menus and layout need live checks |

The 78 new cases cover daily loot and local midnight, reloads, character/market scope, retention, queue merging, localized/guild loot formats, restricted values, repair funding, vendor/repair overlaps, failed services, mail totals, expense categories, filtered CSV and independent settings. All 504 previous cases remain. Local calendar fixtures include 23-hour spring and 25-hour fall DST days.

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
TZ=America/New_York python3 tools/validate.py --lua lua5.1 --luac luac5.1
MSMV_BENCHMARK=1 python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

## Performance

Synthetic Lua CPU measurements from this revision, not client FPS or server results:

| Workload | Result |
|---|---|
| 5,000 items / 15 history days | 206 steps; 399.67 ms total; 6.87 ms maximum step |
| 200 watches / 15 history days | 11 steps; 7.78 ms total; 0.74 ms maximum step |
| 2,000 ledger rows, first view + 100 cached refreshes | 13.42 ms total |
| 500 completed invoices | 100 read/commit steps; 79.79 ms total; 3.68 ms maximum step |
| 10,000 ledger rows, first filtered view + 100 cached refreshes | 17.39 ms total; 5,250 matching sales |

All workloads made zero auction requests. The 10,000-row CSV, including local/UTC times and category, was 1,165,430 bytes. These measurements vary with the host. Single operations and garbage collection can exceed the approximate four-millisecond processing target.

Loot updates one indexed daily row without per-award receipt growth. Expense capture is event-driven; matching uses bounded pending lists. Idle tracking reads no bags, item metadata, trainer catalog or taxi map. Filtered row views and summaries remain cached.

## Native evidence and limits

The user reports that revision 7 logs trade tips correctly and filter buttons respond better. That supports those changes; it does not qualify this revision’s new loot and spending observer. Earlier diagnostics identify Forever 1.60.1 / 70450 / Interface 16001, successful scans and saved vendor observations.

Expense classification requires readable action context and a matching wallet deduction, or matching vendor item values plus a native repair-cost decrease. Unrecognized outgoing wallet changes use Unclassified. Generic handling excludes auction escrow and player trades to avoid duplicates; expired deposits are not inferred. Failed actions with no deduction create no expense. Delayed, combined or unavailable native values may require manual review. Loot uses dedicated native messages, not wallet-income guesses.

AH backfills remain dated when first recorded; invoices have no original transaction date or durable identity. Identical replacements can remain ambiguous. Vendor trades require matching item/money changes. Purchase costs are not automatically allocated to sales. Incoming trade cost remains unknown; a pure tip can use 0. Bank deposits and mailed gold are wallet outflows, not necessarily business losses. Profit cards remain limited to costed income entries; cash flow includes all recorded spending.

Follow the [live checklist](LIVE-TEST-CHECKLIST.md), especially loot shares/reload, personal/guild repairs, training, respecs, flights, mail success/failure, Other category selection and layout. Fixture frames do not prove native fonts, layering, taint or disk persistence. Forever DE outcomes remain unverified.

The delivery report checks commit/tag identity, independent source/repository/bundle restores, retained refs, byte parity and archive hashes. Packages exclude player SavedVariables.
