# Git and GitHub workflow

| Git detail | Value |
|---|---|
| Project | MS Market Value |
| Intended repository | `MoobStack/MS-Market-Value` |
| Main branch | `main` |
| Public beta version | `0.1.0-beta` |
| Current build | `2026-10-04-beta003` |
| Current annotated tag | `v0.1.0-beta-build003` |

## What the supplied artifacts contain

| Artifact | Contents/use |
|---|---|
| `*-Clean.zip` | Only `MSMarketValue/`; install in the game |
| `*-Source.zip` | Complete repository files excluding `.git`; readable source and documentation |
| `*-Git-Repository.zip` | Repository files and complete `.git`; `main`, commit, annotated build tag, configured origin |
| `*.bundle` | Portable complete Git history and refs, including the build tag |
| `*-SHA256.txt` | Checksums of binary/archive artifacts and any separately supplied companion docs/receipt |

No Update ZIP or migration bridge is needed. Build003 preserves schema 1, settings/exclusions/cooldowns and old completed records. Detected Forever markets use new ruleset/faction keys and require one fresh successful scan; old realm-keyed records are never automatically merged. The build001/build002 commits and annotated tags remain intact. The SavedVariable remains `MSMarketValueDB`.

The initialized repository uses a local publisher identity `MoobStack <development@moobstack.invalid>`. The `.invalid` address cannot receive mail and is not a claim about the user's GitHub identity. Set your preferred name and email for future commits. The origin URL is a destination only; packaging does not create a remote repository, push commits, or publish a release.

## Open and inspect the prepared repository

Extract the Git Repository ZIP to a development folder outside the game. Open a terminal in the resulting `MS-Market-Value` directory:

```bash
git status --short
git branch --show-current
git log --oneline --decorate -5
git remote -v
git show --stat v0.1.0-beta-build003
git fsck --full
```

The branch should be `main`, the worktree should be clean, and the build tag should point at the supplied commit. Never initialize a new repository over the included `.git` directory.

## Configure your identity

```bash
git config user.name "YOUR PREFERRED COMMIT NAME"
git config user.email "YOUR VERIFIED OR GITHUB NOREPLY EMAIL"
```

These are literal placeholders to replace; neither command sends email. They affect future commits in this repository. The publisher commits can remain as delivered. All three annotated build001/build002/build003 tags and their commits are retained.

## Create the remote repository when ready

On GitHub, create an empty repository named **MS-Market-Value** under **MoobStack**, without adding a generated README, license, or gitignore. Alternatively, with an authenticated GitHub CLI and permission to create repositories in the organization:

```bash
gh repo create MoobStack/MS-Market-Value --public --description "WoW Forever auction snapshots and item value tooltips"
```

Skip creation if that repository already exists. Inspect its history before combining it with this checkout. Do not replace an existing remote history blindly.

The prepared checkout already has this HTTPS destination:

```bash
git remote -v
# If changing an existing origin URL:
git remote set-url origin https://github.com/MoobStack/MS-Market-Value.git
# If origin is absent instead:
git remote add origin https://github.com/MoobStack/MS-Market-Value.git
```

Use only the command appropriate to whether `origin` exists. Authentication belongs to your Git/GitHub installation; never place tokens in source files or remote URLs.

## Push the reviewed beta revision

Run these commands after deciding to upload the prepared project:

```bash
git push -u origin main
git push origin refs/tags/v0.1.0-beta-build001 refs/tags/v0.1.0-beta-build002 refs/tags/v0.1.0-beta-build003
```

GitHub Actions runs read-only validation of source contracts and Lua 5.1 fixtures. It does not upload artifacts or publish a release. Runtime validation in WoW remains separate from CI.

## Develop the next revision under the SAME primary beta version

For build004:

1. Start from this full Git repository, or clone the remote after it exists.
2. Reproduce the reported behavior with a focused fixture and preserve the previous complete-snapshot contract.
3. Keep `A.VERSION`, all TOC `## Version` values, and `build.json.version` at **0.1.0-beta**.
4. Set a new build ID such as `2026-10-05-beta004` in `Bootstrap.lua`, all three TOCs and `build.json`. Set `buildNumber` to `004`, `gitTag` to `v0.1.0-beta-build004`, and `archiveDate` to the new UTC build date.
5. Add the new entry under the existing `0.1.0-beta` section in CHANGELOG.md. Update README's latest-build excerpt, release notes, validation status and any affected documentation.
6. Run source and behavioral validation; run the applicable native-client checks.
7. Commit on `main` and create a **new annotated build tag**. Preserve the earlier build tags.

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
git diff --check
git add .
git commit -m "Beta build004: describe the concrete behavior change"
git tag -a v0.1.0-beta-build004 -m "MS Market Value 0.1.0-beta build004"
git status --short
git fsck --full
python3 tools/package.py
git push origin main
git push origin refs/tags/v0.1.0-beta-build004
```

The example date is illustrative, not a required date for the next revision. Version remains fixed; build identifiers advance. No force-push or moving published beta tag is needed.

## Run validation locally

Development dependencies are Python 3.10+ and Lua/luac 5.1. LibStub and LibAHTab are bundled runtime libraries; no separately installed dependency addon is required. On Linux with these commands available:

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

On Windows, use `py -3` for Python and supply absolute paths to your Lua 5.1 executables if they are not on PATH:

```powershell
py -3 tools/validate.py --lua "C:\Tools\Lua51\lua.exe" --luac "C:\Tools\Lua51\luac.exe"
```

These Windows paths are examples of development-tool locations, not files included in this package. Use your actual installation paths. Do not validate the addon only with Lua 5.4.

## Produce release assets from the exact tagged source

The package tool refuses a dirty checkout or a HEAD that differs from `build.json.gitTag`. It includes all tracked source/docs, excludes development files from the Clean ZIP, verifies ZIP CRC and source/runtime/tag byte parity, and verifies the bundle:

```bash
python3 tools/package.py
git status --short
```

Outputs are under ignored `dist/`. To check downloaded checksums on Linux:

```bash
cd dist
sha256sum -c MoobStack-MSMarketValue-v0.1.0-beta-build003-SHA256.txt
```

On Windows, compute an individual artifact's hash and compare it with the matching manifest line:

```powershell
Get-FileHash .\dist\MoobStack-MSMarketValue-v0.1.0-beta-build003-Clean.zip -Algorithm SHA256
```

Archive filenames and the immutable build tag identify a candidate even while its TOC version stays unchanged. Runtime/source ZIPs use fixed timestamps and sorted entries for reproducibility. Repository ZIP metadata includes Git's local history/configuration and may differ after additional local Git operations.

## Prepare a GitHub release

Use the text in `GITHUB-RELEASE.md` and attach the four artifacts and checksum manifest. Mark a beta as **Pre-release**. A draft can be created after the tag has been pushed, using Bash:

```bash
gh release create v0.1.0-beta-build003 \
  dist/MoobStack-MSMarketValue-v0.1.0-beta-build003-Clean.zip \
  dist/MoobStack-MSMarketValue-v0.1.0-beta-build003-Source.zip \
  dist/MoobStack-MSMarketValue-v0.1.0-beta-build003-Git-Repository.zip \
  dist/MoobStack-MSMarketValue-v0.1.0-beta-build003.bundle \
  dist/MoobStack-MSMarketValue-v0.1.0-beta-build003-SHA256.txt \
  --repo MoobStack/MS-Market-Value \
  --title "MS Market Value 0.1.0-beta — build003" \
  --notes-file GITHUB-RELEASE.md \
  --prerelease --draft
```

That command is documentation for your later publication decision; it was not executed while preparing these files. Keep live-validation status accurate and do not describe the Classic DE model as verified Forever loot data. A final stable version/tag is selected only when the first release is ready to be finalized.

## Restore from the bundle

Verify and clone the bundle in a new development directory:

```bash
git clone MoobStack-MSMarketValue-v0.1.0-beta-build003.bundle MS-Market-Value-restored
cd MS-Market-Value-restored
git fsck --full
git checkout main
git show --stat v0.1.0-beta-build003
git remote set-url origin https://github.com/MoobStack/MS-Market-Value.git
python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

A bundle clone's initial origin points to the local bundle; the `set-url` step restores the intended GitHub destination. A bundle preserves code/history, not the player's SavedVariables. Restore those separately with WoW closed.

## Change record for this candidate

Build003 fixes first-hover comparison refresh and repeated replication-event handling, adds ruleset-aware caches with native beta region support, and rebuilds settings with native Blizzard frame templates. Public version remains `0.1.0-beta`. See [CHANGELOG.md](CHANGELOG.md), [docs/BUILD003-INVESTIGATION.md](docs/BUILD003-INVESTIGATION.md) and [VALIDATION.md](VALIDATION.md) for behavior, cache-upgrade implications and native evidence limits. The delivered repository is local; no GitHub push or publication is claimed.

## Repository hygiene

Commit source, tests, build metadata and documentation. Keep `dist/`, WTF/SavedVariables, credentials, temporary fixtures and private diagnostics out of Git. The existing gitignore handles these local outputs; check `git status` and `git diff --cached` before each commit. A visible-source/free addon is not automatically MIT-licensed: see `THIRD-PARTY-NOTICES.md` for the current license decision status.
