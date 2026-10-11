# Git, recovery and publication

Release **1.1.0 / 2026-10-11-release001** is prepared on local `main`, with annotated tag `v1.1.0`. `release/1.1.0` points to the same commit; `develop/1.1.0` retains the final beta. Earlier commits and tags remain intact, including `v1.0.0` and all four 1.1.0 test revisions.

Origin is `https://github.com/MoobStack/MS-Market-Value.git`. Before publication, the public remote was still at the 1.0.0 baseline. A configured origin or local tag does not mean the release has been published.

## Packages and recovery

| File | Contents |
|---|---|
| Clean ZIP | Installable `MSMarketValue/` only |
| Source ZIP | All tracked code, tests and documentation |
| Git Repository ZIP | Source plus complete `.git`, branches and tags |
| Bundle | Portable Git history and refs |
| Documentation ZIP | All Markdown docs, release notes and metadata |
| SHA256 / Validation JSON | Package hashes and exact-commit checks |
| Complete Package ZIP | All of the above |

The Repository ZIP already includes `.git`; extract outside AddOns and do not initialize over it. Or restore the bundle:

```bash
git clone MoobStack-MSMarketValue-v1.1.0.bundle MS-Market-Value-restored
cd MS-Market-Value-restored
git switch main
git remote set-url origin https://github.com/MoobStack/MS-Market-Value.git
git fsck --full
python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

`git switch --detach v1.0.0` inspects the previous release; return with `git switch main`. The game needs no development tools. Keep player SavedVariables separately; code packages exclude them.

## Publish

Use a GitHub connection or authenticated Git/GitHub CLI with write access to **MoobStack/MS-Market-Value**. Verify the repository, remote ancestry and new tag before writing. If the remote has diverged or `v1.1.0` already points elsewhere, resolve that explicitly; do not force-push or move tags.

From the verified release checkout, with the eight supplied assets placed in `dist/`:

```bash
(
  set -e
  git fetch origin --no-tags
  git merge-base --is-ancestor origin/main main
  git push --atomic origin main refs/tags/v1.1.0
  gh release create v1.1.0 \
    dist/MoobStack-MSMarketValue-v1.1.0-* dist/MoobStack-MSMarketValue-v1.1.0.bundle \
    --repo MoobStack/MS-Market-Value --verify-tag --latest \
    --title "MS Market Value 1.1.0" --notes-file GITHUB-RELEASE.md
  gh release view v1.1.0 --repo MoobStack/MS-Market-Value \
    --json url,tagName,isDraft,isPrerelease,assets
)
```

Run each step only after the preceding one succeeds. Push the explicit new tag, not all local tags: existing remote tag objects may differ while retaining the same release commit. Keep the release stable, with draft/prerelease disabled. Check the published commit, assets, notes and CI result. Do not overwrite an existing release or asset to hide a mismatch. The [GitHub CLI manual](https://cli.github.com/manual/gh_release_create) describes these flags.

The normal packager creates Clean/Source/Repository ZIPs, the bundle and a manifest. The supplied delivery adds documentation, exact-commit restore results and the Complete Package. Keep those supplied assets together when publishing.

## Further development

Start a new branch from `main` and choose the next version for its scope. Update Bootstrap, all TOCs, build.json, the changelog, docs and validator together. Stable packages have no test-revision field; testing uses a new beta version/build and immutable test tags. Never reuse `v1.1.0` or any earlier tag.

Existing commits use the local `MoobStack <development@moobstack.invalid>` placeholder. Configure a verified identity for new work. CI validates pushes/PRs; it does not publish releases. Keep source, tests and docs in Git; exclude dist, credentials and player data. Preserve [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md) and bundled licenses.
