# Release validation

MS Market Value **1.3.3 / 2026-11-21-release008** passed 976 Lua tests and 23 Python checks. All 34 runtime Lua files passed syntax, load order and release identity checks.

Local checks cover the shared cooldown, scan retries and switching the Arbitrage price basis. Both Arbitrage trade directions open the neutral Buy page with the exact item and its saved neutral price. A separate check covers resolving a modifier from Browse results.

Live diagnostics confirmed the neutral scan and Basis switch on the preceding build. Final row navigation was verified in local checks.
