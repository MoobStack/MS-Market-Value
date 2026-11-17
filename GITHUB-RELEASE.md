# Publish MS Market Value 1.3.1

Use release **1.3.1**, build `2026-11-17-release001`, and [RELEASE-NOTES-v1.3.1.md](RELEASE-NOTES-v1.3.1.md) for the description.

Installers should use the Clean ZIP. The Complete Package includes current documentation, source and Git backups. Place the supplied release files in `dist` before uploading.

With GitHub CLI authenticated, push the corrected documentation and release tag:

```bash
git fetch --no-tags origin main
git push origin main
git push origin refs/tags/v1.3.1
```

For a new release:

```bash
gh release create v1.3.1 dist/MoobStack-MSMarketValue-v1.3.1-* \
  --verify-tag --title 'MS Market Value 1.3.1' \
  --notes-file RELEASE-NOTES-v1.3.1.md --latest
```

For an existing release, update its description and replace its release files:

```bash
gh release edit v1.3.1 --notes-file RELEASE-NOTES-v1.3.1.md
gh release upload v1.3.1 dist/MoobStack-MSMarketValue-v1.3.1-* --clobber
```

The code tag stays unchanged during a documentation correction; source and install packages contain the corrected guides.
