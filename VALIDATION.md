# Validation

**1.3.0-beta / 2026-11-15-beta001 · Test revision 1**

- **619/619 Lua 5.1 cases passed**, including the existing scan, crafting, history and ledger checks.
- New cases cover modifier names, lowest-price quantities, scarcity filters, reopened/area/group loot, quest priority, reset scopes, confirmed receipts and session accounting.
- The tracking workload retained under **4.8 MiB of additional Lua state** with 12,800 drop item counters, a full 2,048-source deduplication ring and 500 session item types.
- The existing 5,000-item / 15-day analysis remained bounded at 200 results. Its longest measured processing step was about **5.8 ms** on the test host. These are synthetic measurements, not a guarantee for every player's system.
- Bundled library bytes, all three TOCs and runtime load order passed validation. No automatic purchases, loot actions or chat sending were added.

Live testing is still required for the new layouts and loot/reward event timing. No verified Forever fixed-rate dataset is included. See the [live checklist](LIVE-TEST-CHECKLIST.md) and [farming guide](docs/FARMING-AND-DROPS.md).

The last live result for 1.2.1 was a complete 140,222-row scan with November 5 recovered and November 6 added. That check does not qualify the new beta features.
