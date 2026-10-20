# Validation

**1.2.0-beta / 2026-10-20-beta001** · Test revision **7** · Tag `v1.2.0-beta-test7`

| Check | Result |
|---|---|
| Lua 5.1 behavior | **504/504 passed** |
| Runtime syntax | All 21 Lua files passed |
| Identity | Fixed beta version/build; three identical TOCs; test revision 7 |
| Dependencies | Pinned LibStub/LibAHTab bytes and notices retained |
| Actions | No automated auction, crafting, merchant, mail or trade actions |
| History | Stable 1.1.0 and all fifteen prior tag objects retained |
| Native revision 7 | Trade event ordering, local dates and dropdown/click behavior need live checks |

The 39 new cases cover completed/cancelled/changed trades, both gold directions, unavailable/restricted offers, native close clearing, duplicate events, player scope, queue/reload behavior, instant filters, native dropdown selection and local calendar boundaries. All 465 previous cases remain.

A focused regression runs the same refresh check against revision 6 and this revision: the old UI hides the active transaction panel 30 times; the new UI never hides it during refresh. The menu stays open without repeated regeneration. Local-time cases run under UTC and America/New_York, including 23-hour spring and 25-hour fall days.

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
TZ=America/New_York python3 tools/validate.py --lua lua5.1 --luac luac5.1
MSMV_BENCHMARK=1 python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

## Performance

Synthetic Lua CPU measurements from this revision, not client FPS or server results:

| Workload | Result |
|---|---|
| 5,000 items / 15 history days | 206 steps; 366.70 ms total; 4.43 ms maximum step |
| 200 watches / 15 history days | 11 steps; 5.74 ms total; 0.55 ms maximum step |
| 2,000 ledger rows, first view + 100 cached refreshes | 9.15 ms total |
| 500 completed invoices | 100 read/commit steps; 61.30 ms total; 1.60 ms maximum step |
| 10,000 ledger rows, first filtered view + 100 cached refreshes | 14.15 ms total; 5,250 matching sales |

All workloads made zero auction requests. Full 10,000-row CSV, including local and UTC times, was 1,135,421 bytes. Report refreshes reuse cached summaries. Trade money reads are event-driven; idle tracking reads no offers, bags or item metadata. Mail batches handle at most 10 entries, with an approximate four-millisecond target; fast collection may inspect up to 100 visible messages. Single operations and garbage collection can exceed a target budget.

## Native evidence and limits

Revision-6 screenshots show the filters/editor and five ledger rows, including AH mail purchases, vendor trades and a commission. Diagnostics show Forever 70450, 26,777 auction rows, 2,385 priced items and nine vendor observations. These support the current baseline, not acceptance of the new trade observer.

Trade completion requires readable captured offers and a native success message. Closure/cancellation alone does not count. A short closed-trade context handles message ordering; unsupported, restricted or late context may need manual entry. Gold purpose is unavailable, so transfers start as tips. Costs stay unknown until entered; a pure tip can use 0. Trade payments do not automatically match existing manual commissions.

AH backfills remain dated when first recorded; invoices have no original transaction date or durable identity. Identical replacements can remain ambiguous. Vendor trades require matching item/money changes. Purchase costs are not automatically allocated to sales. Incoming trade gold, estimates and unknown costs remain explicit.

Run the [live checklist](LIVE-TEST-CHECKLIST.md), especially trade confirmation/cancellation, both directions, the Type menu, local periods and outstanding AH/mail/vendor/reload checks. Fixture frames do not prove native fonts, layering, taint or disk persistence. Forever DE outcomes remain unverified.

The delivery report checks exact commit/tag identity, source/repository/bundle restores, retained refs, byte parity and archive hashes. Packages exclude player SavedVariables.
