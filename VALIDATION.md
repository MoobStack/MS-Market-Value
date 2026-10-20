# Validation

**1.2.0-beta / 2026-10-20-beta001** · Test revision **4** · Tag `v1.2.0-beta-test4`

| Check | Result |
|---|---|
| Lua 5.1 behavior | **388/388 passed** |
| Runtime syntax | All 20 Lua files passed |
| Identity | Fixed beta version/build; three identical TOCs; test revision 4 |
| Dependencies | Pinned LibStub/LibAHTab bytes and notices retained |
| Requests/actions | Watch checks use saved data; no automatic auction, crafting or mailbox action |
| Prior history | Stable 1.1.0 and all twelve prior tag objects retained |
| Native revision 4 | Pricing, watchlist UI and invoice import await in-game checks |

The 55 added cases cover net/break-even math, fee-aware ranking caches, service labor/minimum/customer materials, numeric row quotes, watch target combinations/history/suffixes/scopes, alerts and throttled native listings. Ledger checks cover unknown versus zero cost, fees/refunds/flow, edits/undo/retention, schema isolation, limits, reviewed invoices, duplicate identities across reload/deletion/pruning, CSV and restricted values. Existing scan/tooltip/crafting/history behavior and the 500% movement regression remain covered.

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
MSMV_BENCHMARK=1 python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

## Performance

The synthetic 5,000-item / 15-day market analysis completed in 215 steps, using 478.15 ms total CPU and a 5.63 ms maximum step. The approximate four-millisecond per-job target can be exceeded by a completed operation or garbage collection.

For 200 watches over 15 days, checking completed in **11 steps / 5.60 ms total**, with a **0.62 ms** maximum step. A first view plus 100 cached record/summary refreshes for 2,000 ledger entries took **9.02 ms total**. CSV output was 162,107 bytes. Both workloads made **zero auction requests**. These are local Lua measurements, not native FPS or server tests.

Pricing changes recompute net values/quotes from published material/sale values rather than rebuilding native schematics. Rank/search/summary caches have bounded identities. Watch jobs cancel on data/target/fee changes and pause in combat. Ledger UI reuses sorted records and totals until its revision/profile changes; invoice reads occur only on explicit import.

## Native evidence and limits

The latest supplied screenshot is revision 3's crafting list on Forever build 70450. It shows working service rows and identifies the need for numeric quotes. Prior revision 2 diagnostics show 26,852 rows / 2,483 priced items, four history days, service recipe 13529 and zero vendor observations. They do not verify revision 4's new features.

The matching build-70450 mail source establishes the buyer/seller invoice fields used for preview/import. It supplies no durable mail ID; conservative signature/expiry matching can flag separate identical invoices. Imported records use recording time. Purchase-success notifications lack the complete transaction totals needed to infer a cost, so this build uses manual entries and reviewed invoices. No counterparty, subject or body is retained.

Check the [live checklist](LIVE-TEST-CHECKLIST.md), including native quantities/fees/refunds, customer-material quotes, watch notices, listing links and save/reload behavior. Actual vendor prices still need a supplier visit. DE outcomes remain an unverified Classic reference. Frame fixtures do not establish native font fit, taint behavior or disk persistence.

The delivery report records exact commit/tag identity, independent source/repository/bundle restores, retained tags, byte parity and package hashes. Packages exclude player SavedVariables.
