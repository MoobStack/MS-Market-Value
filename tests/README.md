# Behavioral fixtures

Run from the repository root:

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

The 45 tests exercise price/persistence/scanner/restriction behavior against deliberately controlled native API and widget doubles. They use a hostile restricted-value sentinel to catch accidental inspection, formatting, comparison and arithmetic.

The saved-data round-trip serializes a complete fixture table and initializes a fresh addon namespace. This is a serialization/initialization test, not proof of WoW disk saving. No actual auctions, spellcasts or game clients are contacted.

The tests' serialization loader and API replacements are development-only. Neither is included in the Clean ZIP. UI doubles check control construction and behavior but cannot qualify native visual layout or taint. Native requirements are in LIVE-TEST-CHECKLIST.md.
