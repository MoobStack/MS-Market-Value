# Contributing

Maintain the player-visible contract: a user starts one native full-house scan, only a complete snapshot replaces the current market data, and tooltips explain the values and uncertainty clearly.

## Development setup

Install Git, Python 3.10+ and Lua/luac 5.1. Work from the repository root. Runtime code must stay compatible with the reviewed Forever API and Lua 5.1 syntax. Runtime bundles pinned LibStub and LibAHTab; it includes no executables or separate dependency-install requirement. Preserve their attribution/licenses, verify vendor hashes, and explicitly review any future library update.

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
git diff --check
```

Use focused behavioral fixtures for changed price, persistence, scanner or restriction behavior. UI and native server behavior also require live evidence; headless widgets are limited test doubles.

## Release identity

Version **1.0.0** is the first finalized release. Keep all three historical **0.1.0-beta** build tags immutable. Stable changes use a new semantic version, unique build identifier and annotated `v<version>` tag; update Bootstrap, all TOCs, build.json, changelog and release notes together. Never overwrite a released version or rewrite public history. Full instructions are in [GIT-WORKFLOW.md](GIT-WORKFLOW.md).

## Review expectations

- Describe the concrete trigger and resulting behavior.
- Preserve snapshot replacement and missing-price semantics.
- Check restricted values before using them; never attempt to make them readable.
- Keep auction/server requests bounded and user-started.
- Keep features and settings available through the UI.
- Distinguish exact observed prices from estimated disenchant outcomes.
- Attribute new data sources and record their coverage limits.
- Update the live-check status when new evidence is collected.

## Reports

Include the addon build, client version/build, exact reproduction steps, copied diagnostics and complete Lua error text. For a DE mismatch include item ID/link, item level, quality, material ID/name, quantity and observation count. A single sample does not determine a probability.

Do not submit player WTF folders, account identifiers, credentials, seller lists or other private data. Use the supplied GitHub issue template after the repository exists.
