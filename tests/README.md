# Behavioral fixtures

Run from the repository root:

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

The 90 tests exercise price/persistence/scanner/restriction behavior against deliberately controlled native API and widget doubles. They use a hostile restricted-value sentinel to catch accidental inspection, formatting, comparison and arithmetic.

The saved-data round-trip serializes a complete fixture table and initializes a fresh addon namespace. This is a serialization/initialization test, not proof of WoW disk saving. No actual auctions, spellcasts or game clients are contacted.

Build002 adds 18 cases for empty/missing/throwing/restricted market lookups, region/portal compatibility and isolation, build001 cache reuse, pre-request failure behavior, AH-tab scanning, shared-library switching, delayed loading, reopen/reuse, retired auto-popup settings, slash docking and combat gates. Fixtures load the actual bundled libraries and verify native tab arrays are not extended. The other addon tab is a fixture, not a running Auctionator installation.

Build003 replaces the old repeated-event refusal case and adds 15 cases for scan data updates, partial retry passes, cold-cache refresh ownership, primary getter/data access gates, duplicate/reentrant refresh, beta region 90, realmless host sharing, ruleset/faction isolation and persistence, legacy cache retention and bounded alias/hardcore detection.

Version 1.0.0 adds 12 cases for matched native GUID/bag/equipment quantities, generic-link each-only behavior, inaccessible/malformed/count-mismatch fallbacks, API failures and combat/forbidden guards, changing stack sizes without duplicate blocks, fractional stack rounding and suffix prices, grouped DE values and blank spacing, partial-price handling, settings and reuse of the completed beta003 snapshot. Maximum capacity and total ownership are rejected as quantity sources. The user reported successful build003 native PvP scanning; the new stack display is still a native follow-up.

The tests' serialization loader and API replacements are development-only. Neither is included in the Clean ZIP. UI doubles check control construction and behavior but cannot qualify native visual layout or taint. Native requirements are in LIVE-TEST-CHECKLIST.md.
