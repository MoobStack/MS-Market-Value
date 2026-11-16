# Contributing

Use Lua 5.1 and the supported Forever APIs. Preserve existing saved data, guard restricted values and keep native game actions under player control. Add focused regression coverage for behavior changes and update the relevant guide and changelog.

Run from the repository root:

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
TZ=America/New_York python3 tools/validate.py --lua lua5.1 --luac luac5.1
git diff --check
```

Native UI changes also need an in-game check. Do not commit credentials, player SavedVariables or generated archives. Preserve bundled notices and immutable release tags. See [Release workflow](GIT-WORKFLOW.md).
