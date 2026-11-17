#!/usr/bin/env python3
"""Package a release or verified documentation update without remote writes."""
from __future__ import annotations
import argparse
import hashlib
import json
import pathlib
import re
import subprocess
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
META = json.loads((ROOT / "build.json").read_text(encoding="utf-8"))
TAG = META["gitTag"]
PREFIX = "MoobStack-MSMarketValue-" + TAG
ZIP_TIME = tuple(int(part) for part in META["archiveDate"].split("-")) + (0, 0, 0)
DOC_SUFFIXES = {".md", ".txt", ".rst", ".html", ".htm"}
DOC_TERMS = re.compile(r"\bbeta\b|\bpre-?release\b|\btest[\s_-]*(?:revision|version|build)\b|\bby[\s*]+moobstack\b", re.I)


def git(*arguments: str) -> str:
    return subprocess.check_output(["git", *arguments], cwd=ROOT, text=True).strip()


def make_zip(path: pathlib.Path, entries: list[tuple[str, bytes]]) -> None:
    with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, content in sorted(entries):
            info = zipfile.ZipInfo(name, ZIP_TIME)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, content)
    with zipfile.ZipFile(path) as archive:
        assert archive.testzip() is None


def documentation(name: str) -> bool:
    path = pathlib.PurePosixPath(name)
    return path.suffix.lower() in DOC_SUFFIXES or path.name.lower() in {"readme", "license", "copying", "notice"}


def check_documentation(entries: list[tuple[str, bytes]]) -> None:
    for name, content in entries:
        if documentation(name):
            if DOC_TERMS.search(name) or DOC_TERMS.search(content.decode("utf-8")):
                raise SystemExit(f"Release documentation needs cleanup: {name}")


def check_installed_release(files: list[str]) -> None:
    """A documentation update must retain every installed code/data byte."""
    previous = set(git("ls-tree", "-r", "--name-only", TAG, "--", "MSMarketValue").splitlines())
    current = {name for name in files if name.startswith("MSMarketValue/")}
    for name in sorted(previous | current):
        if documentation(name):
            continue
        if name not in previous or name not in current:
            raise SystemExit(f"Installed files changed in a documentation update: {name}")
        original = subprocess.check_output(["git", "show", TAG + ":" + name], cwd=ROOT)
        if (ROOT / name).read_bytes() != original:
            raise SystemExit(f"Installed code/data changed in a documentation update: {name}")
    if (ROOT / "build.json").read_bytes() != subprocess.check_output(["git", "show", TAG + ":build.json"], cwd=ROOT):
        raise SystemExit("A documentation update must keep the release identity unchanged.")


def build(output: pathlib.Path, documentation_update: bool = False) -> list[pathlib.Path]:
    if git("status", "--porcelain"):
        raise SystemExit("Refusing to package a dirty checkout; commit all intended changes first.")
    if git("cat-file", "-t", TAG) != "tag":
        raise SystemExit("Use an annotated build tag.")
    if git("rev-parse", "HEAD") != git("rev-parse", TAG + "^{commit}"):
        if not documentation_update or META.get("releaseChannel") != "stable":
            raise SystemExit("HEAD must be the release tag, or use --documentation-update with unchanged installed code/data.")
        subprocess.run(["git", "merge-base", "--is-ancestor", TAG, "HEAD"], cwd=ROOT, check=True)
    subprocess.run(["git", "fsck", "--full"], cwd=ROOT, check=True)
    output.mkdir(parents=True, exist_ok=True)
    filenames = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT).decode().split("\0")
    files = [name for name in filenames if name]
    entries = [(name, (ROOT / name).read_bytes()) for name in files]
    if documentation_update:
        check_installed_release(files)
    if META.get("releaseChannel") == "stable":
        check_documentation(entries)
    # The install includes the same user guides as the repository.
    user_docs = {"README.md", "DOCUMENTATION.md", "CHANGELOG.md",
        "UPGRADE.md", "COMPATIBILITY.md", "THIRD-PARTY-NOTICES.md", META["releaseNotes"],
        "docs/FARMING-AND-DROPS.md", "docs/MARKET-OPPORTUNITIES.md", "docs/ECONOMY-TOOLS.md",
        "docs/VENDOR-COSTS.md", "docs/DISENCHANT-MODEL.md"}
    for name, data in entries:
        if name in user_docs:
            installed = data.replace(b"(MSMarketValue/Libs/)", b"(Libs/)").replace(b"(MSMarketValue/Data/)", b"(Data/)")
            assert (ROOT / "MSMarketValue" / name).read_bytes() == installed, f"Update the installed guide: {name}"
    clean_entries = [(name, content) for name, content in entries if name.startswith("MSMarketValue/")]
    assert clean_entries and all("/.git/" not in name for name, _ in clean_entries)
    source_entries = [("MS-Market-Value/" + name, data) for name, data in entries]
    git_entries = list(source_entries)
    for file in sorted((ROOT / ".git").rglob("*")):
        if file.is_file():
            git_entries.append(("MS-Market-Value/" + file.relative_to(ROOT).as_posix(), file.read_bytes()))
    artifacts = []
    for suffix, content in (("Clean.zip", clean_entries), ("Source.zip", source_entries), ("Git-Repository.zip", git_entries)):
        path = output / f"{PREFIX}-{suffix}"
        make_zip(path, content)
        artifacts.append(path)
    documentation = [(name, data) for name, data in entries if name in user_docs or
        (name.startswith("MSMarketValue/") and name.endswith(".txt"))]
    documentation_zip = output / f"{PREFIX}-Documentation.zip"
    make_zip(documentation_zip, documentation)
    artifacts.append(documentation_zip)
    bundle = output / f"{PREFIX}.bundle"
    subprocess.run(["git", "bundle", "create", str(bundle), "--all"], cwd=ROOT, check=True)
    subprocess.run(["git", "bundle", "verify", str(bundle)], cwd=ROOT, check=True)
    artifacts.append(bundle)
    # Install and source bytes must match this exact committed documentation tree.
    with zipfile.ZipFile(artifacts[0]) as clean, zipfile.ZipFile(artifacts[1]) as source:
        for name in clean.namelist():
            assert clean.read(name) == source.read("MS-Market-Value/" + name)
            assert clean.read(name) == subprocess.check_output(["git", "show", "HEAD:" + name], cwd=ROOT)
    manifest = output / f"{PREFIX}-SHA256.txt"
    manifest.write_text("".join(hashlib.sha256(path.read_bytes()).hexdigest() + "  " + path.name + "\n" for path in artifacts), encoding="utf-8")
    artifacts.append(manifest)
    for path in artifacts:
        print(str(path.resolve()))
    return artifacts


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=pathlib.Path, default=ROOT / "dist")
    parser.add_argument("--documentation-update", action="store_true", help="Package corrected stable documentation while verifying installed code/data against the release tag")
    args = parser.parse_args()
    build(args.output.resolve(), documentation_update=args.documentation_update)
