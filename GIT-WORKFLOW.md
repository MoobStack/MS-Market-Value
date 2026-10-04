# Git and GitHub workflow

| Git detail | Value |
|---|---|
| Project | MS Market Value |
| Intended repository | `MoobStack/MS-Market-Value` |
| Main branch | `main` |
| Stable version | `1.0.0` |
| Build | `2026-10-04-release001` |
| Annotated tag | `v1.0.0` |
| Historical beta tags | `v0.1.0-beta-build001`, `v0.1.0-beta-build002`, `v0.1.0-beta-build003` |

## Artifacts and prerequisites

| Artifact | Contents and use |
|---|---|
| `*-Clean.zip` | Only `MSMarketValue/`; install this in the game |
| `*-Source.zip` | Complete tracked source/tests/docs, excluding `.git` |
| `*-Git-Repository.zip` | Source and complete `.git`, main branch, commit history, annotated tags and configured origin |
| `*.bundle` | Portable complete Git history and refs |
| `*-SHA256.txt` | SHA-256 hashes of supplied archives/bundle and any companion docs/receipt |
| `*-Git-Workflow.md`, `*-Changelog.md` | Standalone copies of these repository documents |
| `*-Validation.json` | Evidence for the delivered tag, tests, restores, parity and checksums |

Development requires Git, Python 3.10+ and Lua/luac 5.1. GitHub commands below additionally require an authenticated `gh` installation and write permission under MoobStack. The game package bundles LibStub and LibAHTab; it needs no development tools or separate dependency addon.

Version 1.0.0 keeps schema 1 and build003's market namespace, prices, settings, exclusions and cooldown. It does not require a new scan solely for the upgrade. Older realm-keyed caches remain stored and require their first scan under the detected ruleset key. SavedVariables are player data and are not part of source/history archives.

A configured origin, local tag or packaged asset does not establish remote publication. Only a verified push and published GitHub release establish that result.

## Inspect the supplied repository

Extract the Git Repository ZIP outside the game's AddOns folder. Open a terminal in `MS-Market-Value`:

```bash
git status --short
git branch --show-current
git log --oneline --decorate -5
git remote -v
git show --stat v1.0.0
git tag --list
git fsck --full
```

Expect a clean `main` checkout at `v1.0.0`, with all three earlier beta tags. Do not initialize a new repository over its included `.git` directory. The Source ZIP is readable source without Git metadata; use the Repository ZIP or bundle to preserve history.

The original local commits use `MoobStack <development@moobstack.invalid>`. This placeholder cannot receive mail and is not the user's verified GitHub identity. Configure your preferred identity for future commits:

```bash
git config user.name "YOUR PREFERRED COMMIT NAME"
git config user.email "YOUR VERIFIED OR GITHUB NOREPLY EMAIL"
```

Replace the literal placeholders. These settings affect future commits and send no email; existing release commits/tags can remain as delivered.

## Inspect or create the remote

Check the intended repository through GitHub or an authenticated CLI:

```bash
gh repo view MoobStack/MS-Market-Value --json nameWithOwner,url,defaultBranchRef
```

If it exists, inspect its branches/tags before pushing. If it does not exist and you have creation permission, create an empty public repository without a generated README/license/gitignore:

```bash
gh repo create MoobStack/MS-Market-Value --public --description "WoW Forever auction snapshots and item value tooltips"
```

The supplied checkout has this destination. Inspect it; change or add origin only if necessary:

```bash
git remote -v
# Use set-url when origin exists:
git remote set-url origin https://github.com/MoobStack/MS-Market-Value.git
# Use add instead when origin is absent:
git remote add origin https://github.com/MoobStack/MS-Market-Value.git
```

Authentication belongs to Git/GitHub. Never put tokens in files, remote URLs or release assets. For an existing remote, inspect its history:

```bash
git fetch origin
git ls-remote --heads --tags origin
git log --oneline --decorate --all -10
```

An empty remote or an ancestor of local `main` permits a normal fast-forward push. Resolve divergent history explicitly on a review branch before publishing; never force-push over an unrelated project or overwrite existing tags.

## Validate and push 1.0.0

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
git diff --check
git status --short
git fsck --full
git push -u origin main
git push origin refs/tags/v0.1.0-beta-build001 refs/tags/v0.1.0-beta-build002 refs/tags/v0.1.0-beta-build003 refs/tags/v1.0.0
```

The read-only GitHub Actions workflow validates source contracts and Lua 5.1 fixtures on main pushes/pull requests. It does not publish or upload release assets. Native WoW checks remain separate. Wait for the remote checks and inspect any failure before announcing a release:

```bash
gh run list --repo MoobStack/MS-Market-Value --branch main --limit 5
```

## Package the exact tagged source

`tools/package.py` requires a clean checkout, an annotated tag from build.json and HEAD at that tag. It verifies Git objects, ZIP CRCs, bundle validity and runtime/source/tag byte parity:

```bash
python3 tools/package.py
git status --short
```

Its five outputs appear in ignored `dist/`: Clean ZIP, Source ZIP, Git Repository ZIP, complete bundle and a checksum manifest for those four artifacts. The supplied release also contains standalone workflow/changelog copies and a validation receipt; its manifest covers those companions too.

Clean/Source ZIPs use fixed dates and sorted entries for reproducibility. Git Repository ZIP metadata can differ after subsequent Git operations. Keep runtime files from one exact tag together; never mix builds in AddOns.

To verify all files listed in a downloaded manifest on Linux, run from the directory containing them:

```bash
sha256sum -c MoobStack-MSMarketValue-v1.0.0-SHA256.txt
```

On Windows, compare the computed hash with the appropriate manifest line:

```powershell
Get-FileHash .\MoobStack-MSMarketValue-v1.0.0-Clean.zip -Algorithm SHA256
```

Windows validation can use `py -3` and actual executable paths:

```powershell
py -3 tools/validate.py --lua "C:\Tools\Lua51\lua.exe" --luac "C:\Tools\Lua51\luac.exe"
```

These example tools are not included in the addon. Use Lua 5.1 for runtime validation.

## Publish the stable release

After the exact tag is pushed and its assets are checked, publish using `GITHUB-RELEASE.md`. Version 1.0.0 is stable: omit `--prerelease`. The following command publishes immediately; the documented commands are not evidence they have been executed:

```bash
gh release create v1.0.0 \
  dist/MoobStack-MSMarketValue-v1.0.0-Clean.zip \
  dist/MoobStack-MSMarketValue-v1.0.0-Source.zip \
  dist/MoobStack-MSMarketValue-v1.0.0-Git-Repository.zip \
  dist/MoobStack-MSMarketValue-v1.0.0.bundle \
  dist/MoobStack-MSMarketValue-v1.0.0-SHA256.txt \
  --repo MoobStack/MS-Market-Value \
  --verify-tag --latest \
  --title "MS Market Value 1.0.0" \
  --notes-file GITHUB-RELEASE.md
```

Use the supplied files' actual directory if publishing the delivered assets instead of freshly generated `dist/` outputs. Attach the supplied workflow/changelog/validation companions as well when using the extended manifest. Avoid a manifest listing files you have not uploaded. A deliberate review draft can use `--draft`; publishing a draft later requires `gh release edit v1.0.0 --draft=false --latest --repo MoobStack/MS-Market-Value`.

If a release already exists, inspect it before acting; do not duplicate it, replace published assets silently or reuse its tag for different code. Verify the resulting release and assets:

```bash
gh release view v1.0.0 --repo MoobStack/MS-Market-Value --json url,isDraft,isPrerelease,tagName,assets
git ls-remote origin refs/heads/main refs/tags/v1.0.0 'refs/tags/v1.0.0^{}'
```

The release should have `isDraft=false`, `isPrerelease=false`, the correct tag/commit and all files required by its checksum manifest. Keep the Classic DE qualification and precise native evidence in the public notes.

## Develop the next stable version

Use a branch for each change and a new version/tag for each released result. A backward-compatible bug fix can use **1.0.1**; a compatible feature addition can use **1.1.0**. Breaking contracts require a major-version review. Development branches can iterate before their release tag is created; never move an existing released tag.

1. Branch from updated `main`, reproduce the concrete issue and change the relevant source/fixtures.
2. Update `A.VERSION`, all three TOC Version values and build.json.version together.
3. Use a unique UTC build ID such as `2026-10-05-release002`; update Bootstrap, all three TOCs and build.json.build/buildNumber/archiveDate. Keep `releaseChannel` as `stable` and set `gitTag` to `v1.0.1` for a 1.0.1 release.
4. Add a new changelog section and release notes; update supported-client/evidence statements accurately.
5. Run validation and applicable native checks, review the diff, commit and merge the reviewed change.
6. Annotate the new version tag on the exact final commit, package and push without rewriting earlier history.

```bash
git switch -c fix/describe-issue
python3 tools/validate.py --lua lua5.1 --luac luac5.1
git diff --check
git add .
git diff --cached
git commit -m "Describe the concrete fix"
# Merge through the project's normal review workflow before tagging.
git switch main
git tag -a v1.0.1 -m "MS Market Value 1.0.1"
python3 tools/package.py
git push origin main
git push origin refs/tags/v1.0.1
```

The version/date above are examples for a future patch. Earlier prerelease revisions remain under 0.1.0-beta; that historical version freeze ended with 1.0.0. Never force-push main or delete historical release tags as part of ordinary revision work.

## Restore or roll back

Clone the supplied bundle into a fresh development directory:

```bash
git clone MoobStack-MSMarketValue-v1.0.0.bundle MS-Market-Value-restored
cd MS-Market-Value-restored
git checkout main
git fsck --full
git show --stat v1.0.0
git remote set-url origin https://github.com/MoobStack/MS-Market-Value.git
python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

A bundle clone initially has the bundle path as origin; set-url restores the intended destination. To inspect a historical build without changing main, use `git switch --detach v0.1.0-beta-build003`. Return with `git switch main`. Package only the tag named in that checkout's build.json.

For a game rollback, close WoW and replace the addon folder from the matching earlier Clean ZIP. Schema 1 remains compatible with build003; restore a SavedVariables backup only when needed, while WoW is closed. Git archives restore code/history, not player prices. See [UPGRADE.md](UPGRADE.md).

## Repository hygiene and change record

Commit source, fixtures, build metadata and documentation. Keep dist, WTF/SavedVariables, credentials, temporary research and private diagnostics out of Git. Inspect the staged diff before committing. Original project code has no selected permissive license; retain bundled library notices and terms in [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).

Version 1.0.0 adds actual-stack prices, places expected DE in the price block and spaces material estimates below it. The scanner/schema/market keys remain compatible with build003. See [CHANGELOG.md](CHANGELOG.md), [docs/RELEASE-1.0.0.md](docs/RELEASE-1.0.0.md) and [VALIDATION.md](VALIDATION.md) for exact changes and evidence.
