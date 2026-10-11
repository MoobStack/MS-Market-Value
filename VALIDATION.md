# Validation

`1.1.0-beta / 2026-10-11-beta001` · Test revision 3 · Tag `v1.1.0-beta-test3`

| Check | Result |
|---|---|
| Lua 5.1 behavior | **227/227 passed** |
| Runtime syntax | All 14 Lua files passed |
| Metadata/load order | Fixed beta version/build, revision 3 and three identical TOCs passed |
| Bundled libraries | Pinned hashes and notices retained |
| Runtime operations | No dynamic evaluation, auction transaction, automatic craft or chat send |
| Native revision 2 | User reports improved behavior and successful resumes under multiple conditions |
| Native revision 3 | New history, controls and persistence checks pending |
| Remote CI/publication | Not run or claimed |

## Local coverage

The 169 prior cases retain scan/price arithmetic, atomic snapshots, suffixes, market isolation, DE, schema/settings migration, stack quantities, native tab coordination, combat decoration, and scan/copy/retry budgets. Recovery includes the reported 98,455-row size, copied buffers surviving AH closure, early buffer loss, cooldown-gated restart and request identity checks. Crafting covers quantities, losses, quotes, native selection, service/unsupported shapes and stable catalog publication.

Fifty-eight new cases cover daily replacement, request-day boundaries, missing listings/days, empty scans, exclusion of partial/bid-only/sold data, 1–30 day pruning, immediate retention changes, rollover, market/suffix isolation, fractions and large prices, existing-snapshot import, saved-table serialization, invalid history preservation, numeric-record validation and bounded caching.

They also check tooltip ordering, sample counts, historical stack totals and combat decoration; settings categories, retention inputs, auto-open/manual-close behavior, the profession button above a raised crafting page, all-recipes sorting and colors, undefined returns, services, saved filters and atomic list refreshes.

Fixtures load the actual runtime under Lua 5.1 with native API/frame doubles. They do not render client art, establish taint behavior, contact auction servers or prove WoW disk saving. Serialization is a saved-table round trip, not a game save. Every profession's native recipe shapes still need checking.

## Native evidence

The earlier successful build003 PvP/Horde scan had 104,763 rows, 2,856 priced items and one full-scan request; see [docs/RELEASE-1.0.0.md](docs/RELEASE-1.0.0.md).

The revision 1 report came from Forever 1.60.1 / 70338 / Interface 16001, region 110. It retained 98,455 rows and exposed reopen/resume failure and recipe-list churn. After revision 2, the user reports that scanning resumed correctly under multiple test conditions and the addon is working better. No new row counts, exact timings or exhaustive native coverage were supplied. Revision 3 requires its own history and UI checks.

The pinned native layout shows Forever's CraftingPage at frame level 100. The toggle now follows that page's level and uses the title bar, above its background and away from equipment slots. This source check explains the placement; native appearance still needs verification.

## Reproduction and packages

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
git diff --check
python3 tools/package.py
```

Packaging requires a clean checkout at the annotated build tag. The delivered Validation JSON records actual Source/Git ZIP and bundle restores, tests, retained tags, byte parity, package hashes and deterministic Clean/Source checks for the exact commit. Personal SavedVariables are not included. Use [LIVE-TEST-CHECKLIST.md](LIVE-TEST-CHECKLIST.md) for native checks.
