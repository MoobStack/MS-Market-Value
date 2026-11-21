# Release validation

MS Market Value **1.3.2 / 2026-11-21-release001** passed 964 Lua cases and 23 Python checks. All 34 runtime Lua files passed syntax, load order and release identity checks.

The suite covers saved-data upgrades, hidden realm names, per-character rulesets, intraday rollover, minimap controls and sorting in Rising and Falling. Larger workloads include 16,000 market items, 200 watches and 50 saved sessions.

In-game diagnostics on Forever 1.60.1 build 71037 recorded a completed scan of 231,576 rows and six scans in the same UTC day. UTC rollover was verified with simulated time. The final progress-bar layout and sort controls were checked against frame fixtures.
