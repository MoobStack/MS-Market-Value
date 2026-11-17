# Release workflow

The release is **1.3.1**, build `2026-11-17-release001`, tagged `v1.3.1`. The release commit belongs on `main`; keep previous tags unchanged.

Update `build.json`, Bootstrap, all three TOCs and the user guides together. Validate before creating an annotated release tag:

```bash
TZ=America/New_York MSMV_BENCHMARK=1 MSMV_REPLAY=1 python3 tools/validate.py --lua lua5.1 --luac luac5.1
git diff --check
python3 tools/package.py --output dist
```

Packaging requires a clean checkout at the exact release tag. It creates the install, source, Git repository, documentation and recovery files with checksums. Fetch `main` without replacing existing tags before publishing, and preserve remote changes. Push only the intended branch and new release tag.

See [GitHub release](GITHUB-RELEASE.md) for distribution.
