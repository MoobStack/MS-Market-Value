# Validation

**1.2.0-beta / 2026-10-20-beta001** · Test revision **2** · Tag `v1.2.0-beta-test2`

| Check | Result |
|---|---|
| Lua 5.1 behavior | **318/318 passed** |
| Runtime syntax | All 17 Lua files passed |
| Identity | Fixed beta version/build; three identical TOCs; test revision 2 |
| Dependencies | Pinned LibStub/LibAHTab bytes and notices retained |
| Requests | Analysis and refreshes make none; live item lookup requires a row left-click |
| Prior history | Stable 1.1.0 and all ten prior tag objects retained |
| Native revision 2 | Filters, layout and live navigation await in-game confirmation |

The 27 new cases cover the reported 500% resale regression, exact movement boundaries, disabled movement checks, decimal gold/copper conversion, saved target values, input focus/refresh behavior, cached Apply, item/commodity/suffix navigation and fallback searches. They also check combat, closed frames, stale or changed data, pending analysis, throttling, duplicate clicks and incomplete scan copies. The 500% case also fails against revision 1's analysis, confirming it catches the reported bug. Existing scanning, vendor, crafting, history and tooltip checks remain.

## Performance

A synthetic Lua 5.1 workload with **5,000 items across 15 days** completed in **210 update steps**, using **450.25 ms** total CPU with a **5.18 ms** maximum step here. It retained the best 200 results and made zero auction requests. The frame budget is approximately four milliseconds; a completed operation or garbage collection can exceed that target. This is not a game-client FPS measurement.

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
MSMV_BENCHMARK=1 python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

The delivery report records the exact commit/tag, independent archive restores, retained tags, byte comparisons and hashes. Packaging requires a clean checkout at the annotated test tag. Packages exclude player SavedVariables.

## Native evidence

The supplied revision 1 diagnostics came from **Forever 1.60.1 / 70450 / Interface 16001**, PvP/Horde. They show a complete local scan with **26,669 rows / 2,451 priced items**, four saved UTC days and an installed opportunities tab. The screenshots expose Resale listing items despite a 500% movement threshold. They do not establish vendor costing: zero purchase prices were recorded and no profession was open.

Revision 2's native lookup contracts were reviewed against the matching build-70450 source. Local frame doubles do not render Blizzard artwork or establish server timing, taint behavior or disk persistence. Use the [live checklist](LIVE-TEST-CHECKLIST.md) to confirm movement filtering, decimal input, item and commodity listings, and layout at normal UI scale. Vendor prices still need a supplier/recipe check. Asking prices do not establish demand or completed sales; DE outcomes remain an unverified Classic reference.
