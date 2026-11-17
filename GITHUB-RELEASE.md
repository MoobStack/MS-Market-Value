# Publish MS Market Value 1.3.1

Use tag `v1.3.1` and [RELEASE-NOTES-v1.3.1.md](RELEASE-NOTES-v1.3.1.md) for the release description. Attach the Clean ZIP from `dist` for players to install.

Once the tag is on GitHub, publish from the repository root with GitHub CLI:

```bash
gh release create v1.3.1 dist/MoobStack-MSMarketValue-v1.3.1-Clean.zip \
  --verify-tag --title 'MS Market Value v1.3.1' \
  --notes-file RELEASE-NOTES-v1.3.1.md --latest
```

The release also includes documentation inside the addon folder. See [Release workflow](GIT-WORKFLOW.md) for packaging.
