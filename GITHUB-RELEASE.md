# Publish MS Market Value 1.3.1

<<<<<<< HEAD
Use tag `v1.3.1` and [RELEASE-NOTES-v1.3.1.md](RELEASE-NOTES-v1.3.1.md) for the release description. Attach the Clean ZIP from `dist` for players to install.

Once the tag is on GitHub, publish from the repository root with GitHub CLI:

```bash
gh release create v1.3.1 dist/MoobStack-MSMarketValue-v1.3.1-Clean.zip \
  --verify-tag --title 'MS Market Value v1.3.1' \
  --notes-file RELEASE-NOTES-v1.3.1.md --latest
```

The release also includes documentation inside the addon folder. See [Release workflow](GIT-WORKFLOW.md) for packaging.
=======
Use tag **v1.3.1**, title **MS Market Value 1.3.1**, and [RELEASE-NOTES-v1.3.1.md](RELEASE-NOTES-v1.3.1.md) as the release description. Publish it as a normal release.

The packages are built from the clean, tagged release commit. Installers should use the Clean ZIP; the Complete Package contains source, documentation and Git backups. Keep previous releases and tags intact.

With GitHub CLI authenticated, run from the release checkout:

```bash
git fetch --no-tags origin main
git push --atomic origin main refs/tags/v1.3.1
gh release create v1.3.1 dist/MoobStack-MSMarketValue-v1.3.1-* \
  --verify-tag --title 'MS Market Value 1.3.1' \
  --notes-file RELEASE-NOTES-v1.3.1.md --latest
```

Place the supplied release files in `dist` first. If the release already exists, review its tag and assets before uploading; do not overwrite them blindly.
>>>>>>> parent of 4393f67 (v1.3.1)
