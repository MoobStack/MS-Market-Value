# Publish MS Market Value 1.3.2

Use tag `v1.3.2` and [RELEASE-NOTES-v1.3.2.md](RELEASE-NOTES-v1.3.2.md) for the release description. Attach the Clean ZIP for players to install.

Once the tag is on GitHub, publish from the repository root with GitHub CLI:

```bash
gh release create v1.3.2 dist/MoobStack-MSMarketValue-v1.3.2-Clean.zip \
  --verify-tag --title 'MS Market Value v1.3.2' \
  --notes-file RELEASE-NOTES-v1.3.2.md --latest
```

The release also includes documentation inside the addon folder. See [Release workflow](GIT-WORKFLOW.md) for packaging.
