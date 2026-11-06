# Source, recovery and release

The **1.2.1** update builds on `v1.2.0` without changing that tag. The original 1.2.0 recovery package retains the earlier release and testing history.

## Package contents

| File | Purpose |
|---|---|
| Clean ZIP | Installable addon only |
| Source ZIP | All tracked code, tests and documentation |
| Git Repository ZIP | Source plus complete `.git`, branches and tags |
| Bundle | Portable Git history and refs |
| Documentation ZIP | Guides, release notes and build metadata |
| Validation / SHA256 | Exact-release checks and package hashes |

All documentation is included in the full repository. Earlier notes are under `docs/history`; original versions also remain at their tags. Keep recovery files outside AddOns.

Restore a bundle:

```bash
git clone MoobStack-MSMarketValue-v1.2.0.bundle MS-Market-Value
cd MS-Market-Value
git switch main
git remote set-url origin https://github.com/MoobStack/MS-Market-Value.git
git fsck --full
python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

## Packaging and publication

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
git diff --check
python3 tools/package.py
```

Packaging requires a clean checkout at the exact annotated tag in build.json. Runtime/source/tag bytes must match. The complete delivery adds documentation and independent archive-restore checks. CI validates main, development and release branches; it does not publish releases.

This package is prepared locally. No remote push or GitHub release was performed. Before publishing, fetch and verify remote ancestry/tag identity, use a verified commit identity, then push only the intended branch/new tag. Never move old tags or bulk-push recovered refs. Existing local commits use the placeholder `MoobStack <development@moobstack.invalid>`.
