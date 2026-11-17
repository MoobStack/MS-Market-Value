# Test build workflow

The active build is **1.3.1-beta, test revision 7**, tag `v1.3.1-beta-test7`, on `develop/1.3.1`. Version 1.3.0 remains the published release. Do not publish this test build as the final 1.3.1 release.

Keep `build.json`, Bootstrap and all three TOCs consistent. Advance the test revision for each distributed build and use an annotated, immutable test tag. Do not overwrite published history.

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
python3 tools/package.py --output dist
```

Package only a clean tagged checkout. The command creates install, source, repository, documentation and recovery archives with checksums. Only the Clean ZIP belongs in AddOns; keep repository files elsewhere.

After the test cycle is accepted, prepare a separate stable identity, update the release notes, validate again and publish a new stable tag. Fetch the existing origin before any push and preserve remote changes.
