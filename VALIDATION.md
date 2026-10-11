# Validation

`1.1.0-beta / 2026-10-11-beta001` · Test revision 2 · Tag `v1.1.0-beta-test2`

| Check | Result |
|---|---|
| Lua 5.1 behavior | **169/169 passed** |
| Runtime syntax | All 13 Lua files passed |
| Metadata/load order | Version/build/revision and three identical TOCs passed |
| Bundled libraries | Pinned hashes and notices retained |
| Runtime operations | No dynamic evaluation, auction transaction, automatic craft or chat send |
| Native test revision 1 | Reported reopen failure and recipe-list churn on build 70338 |
| Native test revision 2 | Retest pending |
| Remote CI/publication | Not run or claimed |

## Behavioral coverage

The earlier 90 cases retain the price, suffix, DE, schema, market isolation, native-tab, budget, saved-data and stack-display checks. Interruption and combat expectations now match pause/resume and combat price decoration.

Forty-five added cases cover paused WAITING/PROCESSING/RESOLVING phases, late and empty responses, partial retry passes, data timeouts, AH/combat gates, changed buffers/markets, competing paused requests, commands and controls, unchanged request counts/cooldown, and combat prices with restricted quantity fallback.

Crafting cases cover costs, losses, return denominator, multiple/variable outputs, markup and fractional inputs, missing prices, non-item services, alternatives and optional allocations, incomplete ownership, restricted/malformed data, currencies, variable quantities, quality-dependent output, unsupported recipe types, zero cost, overflow, batching/sorting, catalog invalidation, full/filtered APIs, selection/window lifecycle, and 1.0.0 migration.

Thirty-four Test revision 2 cases cover public price fields before cosmetic readiness, native buffer loss after complete copying, paused background copying, unavailable native getters, early buffer loss without discarded progress, cooldown-gated fresh restart, count/row/suffix identity checks, resolved local retries, copy budgets, and the reported 98,455-row size.

They also cover item-event floods, atomic catalog publication, unchanged native list events, learned/new recipes, loaded names, snapshot timestamps and profession/market isolation; concise/native-linked quotes, unavailable link fallbacks, fixed-output unit quotes, variable-yield wording, native chat drafts, focused stale text and missing-price controls. Synchronous item events and competing requests during item loading also have regressions.

Fixtures load the real runtime under Lua 5.1 with native API/frame doubles. They do not render Blizzard textures or prove live UI fit, server buffer retention, native taint, profession coverage or WoW disk saving. Use [LIVE-TEST-CHECKLIST.md](LIVE-TEST-CHECKLIST.md) for those checks.

## Existing native evidence

The user reported a successful earlier build003 PvP/Horde scan: 104,763 rows, 2,856 priced items, one full-scan request, and normal tab behavior. It is preserved in [docs/RELEASE-1.0.0.md](docs/RELEASE-1.0.0.md). That report remains baseline evidence and does not validate all market/loot rules.

The Test revision 1 report shows client 1.60.1 / 70338 / Interface 16001, region 110, a retained completed snapshot of 98,455 rows/3,179 priced items, and a failed resume after AH closure. The user also reported a repeatedly changing recipe list and requested shorter linked quotes. This is evidence of those problems, not proof of the Test revision 2 fixes.

## Packaging and reproduction

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
git diff --check
python3 tools/package.py
```

The package tool requires a clean checkout at the annotated build tag and checks Git objects, ZIP CRC, bundle validity and tagged runtime byte parity. The companion Validation JSON records actual archive/bundle restores, their tests, retained tags, package hashes and deterministic Clean/Source output checks for the delivered commit.

Price history is not implemented or tested in this revision. Its retention, daily replacement and average calculations will be tested in the next revision of the same beta.
