# Validation

`1.1.0-beta / 2026-10-11-beta001` · Test revision 1 · Tag `v1.1.0-beta-test1`

| Check | Result |
|---|---|
| Lua 5.1 behavior | **135/135 passed** |
| Runtime syntax | All 13 Lua files passed |
| Metadata/load order | Version/build/revision and three identical TOCs passed |
| Bundled libraries | Pinned hashes and notices retained |
| Runtime operations | No dynamic evaluation, auction transaction, automatic craft or chat send |
| Native test revision 1 | Pending |
| Remote CI/publication | Not run or claimed |

## Behavioral coverage

The earlier 90 cases retain the price, suffix, DE, schema, market isolation, native-tab, budget, saved-data and stack-display checks. Interruption and combat expectations now match pause/resume and combat price decoration.

Forty-five added cases cover paused WAITING/PROCESSING/RESOLVING phases, late and empty responses, partial retry passes, data timeouts, AH/combat gates, changed buffers/markets, competing paused requests, commands and controls, unchanged request counts/cooldown, and combat prices with restricted quantity fallback.

Crafting cases cover costs, losses, return denominator, multiple/variable outputs, markup and fractional inputs, missing prices, non-item services, alternatives and optional allocations, incomplete ownership, restricted/malformed data, currencies, variable quantities, quality-dependent output, unsupported recipe types, zero cost, overflow, batching/sorting, catalog invalidation, full/filtered APIs, selection/window lifecycle, and 1.0.0 migration.

Fixtures load the real runtime under Lua 5.1 with native API/frame doubles. They do not render Blizzard textures or prove live UI fit, server buffer retention, native taint, profession coverage or WoW disk saving. Use [LIVE-TEST-CHECKLIST.md](LIVE-TEST-CHECKLIST.md) for those checks.

## Existing native evidence

The user reported a successful earlier build003 PvP/Horde scan: 104,763 rows, 2,856 priced items, one full-scan request, and normal tab behavior. It is preserved in [docs/RELEASE-1.0.0.md](docs/RELEASE-1.0.0.md). That report remains baseline evidence and does not validate the new crafting/resume features or all market/loot rules.

## Packaging and reproduction

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
git diff --check
python3 tools/package.py
```

The package tool requires a clean checkout at the annotated build tag and checks Git objects, ZIP CRC, bundle validity and tagged runtime byte parity. The companion Validation JSON records actual archive/bundle restores, their tests, retained tags, package hashes and deterministic Clean/Source output checks for the delivered commit.

Price history is not implemented or tested in this revision. Its retention, daily replacement and average calculations will be tested in the next revision of the same beta.
