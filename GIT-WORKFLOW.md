# Git, recovery and testing

The current work is on **develop/1.2.0**, tagged `v1.2.0-beta-test4`. Local `main` and `v1.1.0` retain release commit `d959424db004e24542322bd9bd7278a290f9df77`. Earlier branches, commits and all twelve prior tag objects, including test1 through test3, remain intact.

Hold **1.2.0-beta / 2026-10-20-beta001** throughout testing. Increment `testRevision` and create a new annotated `v1.2.0-beta-testN` tag for each delivery. Do not move old tags. Final publication will use stable version 1.2.0 and a new release build/tag.

## Packages

| File | Contents |
|---|---|
| Clean ZIP | Installable `MSMarketValue/` only |
| Source ZIP | All tracked code, tests and documentation |
| Git Repository ZIP | Source plus complete `.git`, branches and tags |
| Bundle | Portable Git history and refs |
| Documentation ZIP | All Markdown docs, release notes and metadata |
| SHA256 / Validation JSON | Package hashes and exact-commit checks |
| Complete Package ZIP | All of the above |

All documentation is also tracked inside the full repository. Extract that package outside AddOns; do not initialize over its existing `.git`. To restore a bundle:

```bash
git clone MoobStack-MSMarketValue-v1.2.0-beta-test4.bundle MS-Market-Value-restored
cd MS-Market-Value-restored
git switch develop/1.2.0
git remote set-url origin https://github.com/MoobStack/MS-Market-Value.git
git fsck --full
python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

Inspect the previous release with `git switch --detach v1.1.0`, then return to `develop/1.2.0`. Player SavedVariables are separate and excluded from code archives.

## Build and publish later

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
git diff --check
python3 tools/package.py
```

Packaging requires a clean checkout at the annotated tag in build.json. The normal packager creates Clean/Source/Repository ZIPs, the bundle and a manifest. The supplied Complete Package adds documentation and independent restore results.

Origin remains `https://github.com/MoobStack/MS-Market-Value.git`. No remote was changed or publication performed for this test. The recovered archive's `origin/main` is historical metadata, not current remote evidence. Fetch and verify remote ancestry/tag identity before any future push. Push only the intended branch/new tag; never force-push or bulk-push old tags. CI validates pushes/PRs and does not publish releases.

Existing commits use `MoobStack <development@moobstack.invalid>` as a local placeholder. Configure a verified identity for new work. Keep generated packages, credentials and player data out of Git. Retain bundled licenses and [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).
