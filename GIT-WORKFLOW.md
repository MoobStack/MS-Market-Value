# Release workflow

The official release is **1.3.0**, build `2026-11-16-release001`, tag `v1.3.0`. The Git Repository ZIP includes source and history; extract it outside AddOns. Only the Clean ZIP belongs in the game.

## Validate and package

From a clean checkout at the annotated release tag:

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
python3 tools/package.py --output dist
```

Keep the TOCs, Bootstrap and build.json consistent. The packaging command produces install, source, repository, documentation and recovery archives with checksums. Earlier history remains in Git.

## Publish

Use the existing origin for `MoobStack/MS-Market-Value`. Fetch before pushing and resolve any remote changes without rewriting published history. Push main and the annotated v1.3.0 tag, then create a GitHub release titled MS Market Value 1.3.0 using `RELEASE-NOTES-v1.3.0.md`.

Attach the Clean ZIP, Source ZIP, Documentation ZIP and matching checksums. GitHub authentication is required. Never overwrite an existing release tag; correct a published release with a new version.
