# Validation

MS Market Value **1.3.1-beta, test revision 3** passed **877 Lua cases and 23 Python checks/workloads** with Lua 5.1 API/frame fixtures. The 31 new cases cover exact-date history, intraday modifier retention, persistence, missing close events, transaction exclusions and farming peaks.

A replay against test revision 2 erased an exact modifier price when a later scan omitted it on the same UTC day. The fix retains its last observed price for that day, preserves fresh current listings, never carries samples into another date and keeps incompatible formats separate. Normal item-wide daily behavior remains covered.

The November 15–17 calendar replay has two earlier exact dates; the fourth date permits a qualifying three-day baseline. Reloads and link level/unique-ID changes keep the exact key stable in the fixtures. Different modifiers cannot supply one another's missing samples. The user's actual saved keys/daily prices were not available; the new diagnostic report exposes those values for native confirmation.

A missing quest-close replay ignored 19 subsequent loot-money awards on test revision 2. The fix counted all 19, left quest gold separate and kept it out of the farming peak. Merchant, mail, trade and native-frame recovery checks passed, including cooldowns and manual/death pause.

All 30 runtime Lua files pass syntax, load-order, identity and operation checks. Repeated market searches still settle; the prior session-storage, scrolling, farming, drop, crafting and ledger coverage remains included. Results and hashes are in `evidence/TEST-1.3.1-3.json`; the local log is `evidence/TEST-1.3.1-3-validation.txt`.

Local fixtures do not prove native event timing, total addon memory or FPS. Follow the [test notes](RELEASE-NOTES-v1.3.1-beta-test3.md) and include a representative selected variant in the next diagnostic report.
