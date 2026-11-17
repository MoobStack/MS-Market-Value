# Validation

MS Market Value **1.3.1-beta, test revision 1** passed **813 Lua cases and 23 Python checks/workloads** with Lua 5.1 API/frame fixtures. The suite includes 33 new regressions for empty corpses, quest receipt order, vendor sales, rate settings, saved sessions and tooltip ownership.

Replays against 1.3.0 reproduced skipped empty samples, duplicated quest receipts and two tooltip sections extending beyond the fitted border. The updated files pass those cases. All 30 runtime Lua files pass syntax, load-order, identity and operation checks; current guide links were also checked.

The larger workloads cover 12,000 farming receipts over 600 active minutes and repeated searches over 16,000 market entries. Farming rate data remains bounded; four market searches still produce four completed builds.

Results and runtime hashes are in `evidence/TEST-1.3.1-1.json`; the full local log is `evidence/TEST-1.3.1-1-validation.txt`. Local checks do not verify native event delivery, fonts, frame sizing or FPS. Follow the [in-game checks](RELEASE-NOTES-v1.3.1-beta-test1.md) before accepting a final release.
