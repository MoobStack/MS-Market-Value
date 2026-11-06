# Source and releases

The **Git Repository ZIP** contains the source, guides, tests and Git history. Extract it into a new folder and open the `MS-Market-Value` directory there. The **Clean ZIP** is the one to install in WoW.

## Publish 1.2.1

The packaged `main` builds on GitHub’s 1.2.0 release. From the extracted repository, using an account with write access:

```bash
git fetch origin
git push --atomic origin main v1.2.1
```

Create the GitHub release from the existing `v1.2.1` tag. Use [GITHUB-RELEASE.md](GITHUB-RELEASE.md) for the notes and attach the Clean ZIP. If Git reports that GitHub has newer commits, integrate those first.

## Build and recover

Run `python3 tools/validate.py --lua lua5.1 --luac luac5.1` to test. Run `python3 tools/package.py` from the clean checkout at the annotated tag in `build.json`.

The full archive preserves the original development branches and earlier annotated tags under `refs/archive/1.2.0/tags/`, alongside GitHub’s published tags. Earlier notes are in [docs/history](docs/history/README.md).
