# Contributing

Use Lua 5.1 and the reviewed Forever APIs. Keep native game actions under player control, guard restricted values, and preserve existing saved data. Prefer bounded processing and cached views over repeated full rebuilds.

Run from the repository root:

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
TZ=America/New_York python3 tools/validate.py --lua lua5.1 --luac luac5.1
git diff --check
```

Add focused regression cases for behavior changes. Check native UI/event behavior in Forever when it matters; fixture frames cannot establish visual fit, taint or disk saving. Update the user guide and changelog when behavior changes.

Release tags are immutable. A future testing cycle gets its own beta version/build and numbered test revisions; a stable release has no test-revision field. Keep the three TOCs, Bootstrap and build.json consistent. See [Git workflow](GIT-WORKFLOW.md).

Do not commit credentials, player SavedVariables or generated packages. Preserve bundled library licenses and hashes. Original project code currently has no additional license grant; see [notices](THIRD-PARTY-NOTICES.md).
