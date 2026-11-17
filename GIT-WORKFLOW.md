# Release workflow

The addon release is **1.3.1**, build `2026-11-17-release001`, tagged `v1.3.1`. Keep existing release tags unchanged.

Validate code changes before tagging a new release:

```bash
TZ=America/New_York MSMV_BENCHMARK=1 MSMV_REPLAY=1 python3 tools/validate.py --lua lua5.1 --luac luac5.1
git diff --check
python3 tools/package.py --output dist
```

Documentation corrections can follow on `main` without changing the addon version. Commit the corrections, then run:

```bash
python3 tools/package.py --documentation-update --output dist
```

This mode verifies every installed code/data file and the release identity against `v1.3.1`, then packages the current committed documentation. Both modes check all documentation, mirrored guides and archive integrity.

Fetch `main` before publishing and preserve remote changes. See [GitHub release](GITHUB-RELEASE.md) for distribution.
