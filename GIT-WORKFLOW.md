# Git workflow and recovery

The development checkout is on `develop/1.1.0`, with testing metadata `1.1.0-beta / 2026-10-11-beta001`, Test revision 2, and annotated tag `v1.1.0-beta-test2`. `main` and `v1.0.0` retain the stable baseline. The configured origin is `https://github.com/MoobStack/MS-Market-Value.git`; a configured URL does not mean these changes were pushed.

## Packages

| File | Use |
|---|---|
| Clean ZIP | Install `MSMarketValue/` in the game |
| Source ZIP | Tracked source, tests and all documentation; no `.git` |
| Git Repository ZIP | Source plus complete `.git`, branches, commits, tags and origin |
| Git bundle | Portable complete history and refs |
| Documentation ZIP | User guide, changelog, test checklist, release and recovery notes |
| SHA256 manifest | Integrity hashes for delivered files |
| Validation JSON | Test and archive-restore results for the exact tagged commit |

Player SavedVariables are not included. Keep a separate account-data backup. Existing release tags remain immutable.

## Inspect and validate

Extract the Repository ZIP outside AddOns and open a terminal in `MS-Market-Value`:

```bash
git status --short
git branch --show-current
git log --oneline --decorate -5
git tag --list
git show --stat v1.1.0-beta-test2
git fsck --full
python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

Development requires Git, Python 3.10+ and Lua/luac 5.1. The game needs none of them. CI checks the source and fixtures on main/development pushes and pull requests; it does not publish releases. Local validation is not a remote CI result or a native WoW check.

Existing commits use the project's local `MoobStack <development@moobstack.invalid>` placeholder. Configure your preferred verified Git identity for future commits; preserve existing history.

## Next test revision

Continue on `develop/1.1.0`. Keep `A.VERSION`, all TOC versions, and build.json.version at `1.1.0-beta`. Keep all build identifiers at `2026-10-11-beta001`.

1. Implement one feature or a concrete fix and update focused behavioral fixtures.
2. Advance `A.TEST_REVISION`, all three `X-Test-Revision` values, and build.json.testRevision together.
3. Set build.json.gitTag to the new immutable `v1.1.0-beta-testN`. Update archiveDate to the package date; buildNumber remains 001.
4. Update the changelog, user docs, release notes and validation/live-check status.
5. Validate, review the staged diff and commit. Create a new annotated tag on that exact commit.

For the next package, use `v1.1.0-beta-test3`; never move test1 or test2 to a different commit. Price history is the next planned implementation.

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
git diff --check
git add .
git diff --cached
git commit -m "Describe the implemented change"
git tag -a v1.1.0-beta-test3 -m "MS Market Value 1.1.0 beta, test revision 3"
python3 tools/package.py
```

The example tag applies only after metadata has advanced to revision 3. Packaging requires a clean checkout at the annotated tag named in build.json. It checks Git objects, ZIP CRC, bundle integrity and runtime/source/tag byte parity, then writes files to ignored `dist/`.

## Recovery

The Repository ZIP already includes `.git`; do not initialize a new repository over it. Alternatively, restore the bundle:

```bash
git clone MoobStack-MSMarketValue-v1.1.0-beta-test2.bundle MS-Market-Value-restored
cd MS-Market-Value-restored
git switch develop/1.1.0
git fsck --full
git show --stat v1.1.0-beta-test2
git remote set-url origin https://github.com/MoobStack/MS-Market-Value.git
python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

The bundle clone initially uses the bundle path as origin. To inspect the stable baseline, use `git switch --detach v1.0.0`; return with `git switch develop/1.1.0`. Earlier beta tags remain available. For a game rollback, use the matching Clean ZIP with WoW closed; see [UPGRADE.md](UPGRADE.md).

## Publication

This package is local testing work, not an official 1.1.0 release. If test packages are shared through GitHub, publish them as **prereleases** using their exact test tags. Verify the intended repository and remote history before pushing; resolve divergence explicitly and do not force-push.

The final release follows implementation and live verification of crafting, history and both fixes. Update Bootstrap, all TOCs and build.json to stable `1.1.0`, use a release build ID and `releaseChannel: stable`, update validator gates and rewrite public notes for the finished release. Merge through the project's normal review workflow, tag the final commit as `v1.1.0`, and package that clean commit. Do not repurpose any existing tag.

Keep source, fixtures and docs in Git; keep dist, WTF, credentials, private diagnostics and temporary research out. Original project code has no selected permissive license; retain [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md) and bundled library terms.
