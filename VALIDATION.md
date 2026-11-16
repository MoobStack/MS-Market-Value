# Validation

MS Market Value 1.3.0 is promoted from the user-accepted functionality for release. The gameplay modules are retained; this release updates identity, documentation and packaging.

Release checks cover Lua 5.1 behavior, all 30 runtime files, matching TOCs, bundled-library integrity, saved-data upgrades, prices, filters, personal observations, farming, ledger and package contents. **780 Lua cases and 23 Python checks/workloads passed** against the release files. Results are recorded in `evidence/RELEASE-1.3.0.json`.

Local API/frame fixtures do not measure native FPS, fonts or total addon memory. Use the [release checklist](LIVE-TEST-CHECKLIST.md) when testing on another client build.
