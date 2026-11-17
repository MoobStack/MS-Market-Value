# Release workflow

MS Market Value **1.3.1** uses build `2026-11-17-release001` and tag `v1.3.1`.

Run the checks from the repository root before packaging:

```bash
TZ=America/New_York MSMV_BENCHMARK=1 MSMV_REPLAY=1 python3 tools/validate.py --lua lua5.1 --luac luac5.1
git diff --check
python3 tools/package.py --output dist
```

The packaging script verifies the release tag, the bundled guides and the archives. See [GitHub release](GITHUB-RELEASE.md) for distribution.
