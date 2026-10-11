# Validation

**1.1.0 / 2026-10-11-release001** · Annotated tag `v1.1.0`

| Check | Result |
|---|---|
| Lua 5.1 behavior | **239/239 passed** |
| Runtime syntax | All 14 Lua files passed |
| Release identity | Stable version/build; three identical TOCs; no test-revision metadata |
| Bundled libraries | Pinned bytes and notices retained |
| Runtime operations | No dynamic evaluation, auction transactions, automatic crafts or chat sends |
| Live feedback | User reports revision 4 functioning properly and approves 1.1.0 |
| Supplied diagnostics | Complete 96,590-row snapshot; 3,179 priced items; recipe 2964 valued; one history day |
| Remote publication | Requires a verified GitHub write connection; local tests do not establish remote CI |

## Coverage

Fixtures cover scan arithmetic, atomic snapshots, copied-buffer recovery, interruptions/cooldowns, restricted data, market/suffix isolation, stack prices, combat tooltips and native tab coordination. Crafting includes quantities, profits/losses, services, quotes, stable catalog publication, manual opening and both list filters. History covers daily replacement, UTC boundaries, retention, missing listings, migration, saved-table round trips, variants and bounded averages.

The release adds a beta-to-stable upgrade check: completed prices, daily history, preferences, exclusions and cooldown survive without a new scan. The header regression also remains: it failed against revision 3's button under the native border/title and passes with the revision 4 fix.

The user previously reported successful revision 2 resumes under multiple conditions. Revision 4 diagnostics come from Forever 1.60.1 / 70338 / Interface 16001 on PvP/Horde, region 110. They show a ready tooltip callback, one catalog build/publication, a native recipe link and one retained UTC day. The user reports proper operation. The toggle and crafting window were hidden at capture, so the text does not independently demonstrate their appearance.

This evidence does not cover every profession, ruleset, daily rollover, long retention or a dedicated reload/restart history test. Frame doubles do not render client art or establish taint behavior. The DE model remains a Classic reference. Details are in [docs/RELEASE-1.1.0.md](docs/RELEASE-1.1.0.md); ongoing checks are in [LIVE-TEST-CHECKLIST.md](LIVE-TEST-CHECKLIST.md).

## Reproduce

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
git diff --check
python3 tools/package.py
```

Packaging requires a clean checkout at the annotated build tag. The delivered Validation JSON records exact commit/tag identities, restored Source/Git ZIP and bundle checks, runtime/documentation parity, retained tags and package hashes. Personal SavedVariables are excluded. Publication steps are in [GIT-WORKFLOW.md](GIT-WORKFLOW.md).
