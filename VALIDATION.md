# Validation

**1.2.0-beta / 2026-10-20-beta001** · Test revision **3** · Tag `v1.2.0-beta-test3`

| Check | Result |
|---|---|
| Lua 5.1 behavior | **333/333 passed** |
| Runtime syntax | All 17 Lua files passed |
| Identity | Fixed beta version/build; three identical TOCs; test revision 3 |
| Dependencies | Pinned LibStub/LibAHTab bytes and notices retained |
| Crafting controls | Search/sort reuse published valuations; no new auction requests |
| Prior history | Stable 1.1.0 and all eleven prior tag objects retained |
| Native revision 3 | Crafting layout and hover behavior await in-game confirmation |

The 15 new cases cover service quotes and item-profit restoration, service versus missing-data counts, literal name search, cached sorting, profession changes, atomic published summaries, material source/quantity/totals, vendor-unseen costs and current markup in service tooltips. Existing scan, combat tooltip, vendor, crafting, history and Opportunities checks remain. The 500% price-move regression from revision 2 is retained.

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

The delivery report records exact commit/tag identity, independent archive restores, retained tags, byte comparisons and hashes. Packaging requires a clean annotated-tag checkout. Code packages exclude player SavedVariables.

## Performance

Search and summary caches are invalidated by published source/query/profession changes. Empty search reuses the existing ranking directly. Repeated search/sort refresh fixtures make zero recipe schematic calls and leave catalog builds unchanged. The selected-recipe adapter still follows native selection/reagents on its existing 0.25-second tick.

Market analysis is unchanged in this revision. Revision 2's synthetic 5,000-item / 15-day test completed in 210 steps, using 450.25 ms total CPU and a 5.18 ms maximum step. It retained 200 results and made zero auction requests. Those are local measurements of that earlier revision, not game-client FPS or a crafting-layout benchmark.

## Native evidence

The supplied revision 2 diagnostics came from **Forever 1.60.1 / 70450 / Interface 16001**, PvP/Horde. They show **26,852 auction rows / 2,483 priced items**, four history days and an installed Opportunities tab with six matches. Selected recipe 13529 is a service with a native recipe link. The screenshots show its material quote and the all-learned recipe list. A hidden crafting frame in diagnostics does not itself indicate a missing toggle.

Vendor observations remain **0**. The supplied report does not qualify vendor costing or confirm a successful item-list lookup. Revision 3's layout, typography, hover behavior and UI-scale fit need a client check. Frame doubles do not render Blizzard artwork, establish taint behavior or prove disk persistence. Follow the [live checklist](LIVE-TEST-CHECKLIST.md). DE outcomes remain an unverified Classic reference.
