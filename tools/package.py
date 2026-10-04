#!/usr/bin/env python3
"""Package a clean tagged checkout; never create or modify a remote release."""
from __future__ import annotations
import argparse
import hashlib
import json
import pathlib
import subprocess
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
META = json.loads((ROOT / "build.json").read_text(encoding="utf-8"))
TAG = META["gitTag"]
PREFIX = "MoobStack-MSMarketValue-" + TAG
ZIP_TIME = tuple(int(part) for part in META["archiveDate"].split("-")) + (0, 0, 0)


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


def build(output: pathlib.Path) -> list[pathlib.Path]:
    if git("status", "--porcelain"):
        raise SystemExit("Refusing to package a dirty checkout; commit all intended changes first.")
    if git("rev-parse", "HEAD") != git("rev-parse", TAG + "^{commit}"):
        raise SystemExit("HEAD must be the exact annotated build tag.")
    if git("cat-file", "-t", TAG) != "tag":
        raise SystemExit("Use an annotated build tag.")
    subprocess.run(["git", "fsck", "--full"], cwd=ROOT, check=True)
    output.mkdir(parents=True, exist_ok=True)
    filenames = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT).decode().split("\0")
    files = [name for name in filenames if name]
    entries = [(name, (ROOT / name).read_bytes()) for name in files]
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
    bundle = output / f"{PREFIX}.bundle"
    subprocess.run(["git", "bundle", "create", str(bundle), "--all"], cwd=ROOT, check=True)
    subprocess.run(["git", "bundle", "verify", str(bundle)], cwd=ROOT, check=True)
    artifacts.append(bundle)
    # Exact tagged runtime bytes must agree between the install and source ZIPs.
    with zipfile.ZipFile(artifacts[0]) as clean, zipfile.ZipFile(artifacts[1]) as source:
        for name in clean.namelist():
            assert clean.read(name) == source.read("MS-Market-Value/" + name)
            assert clean.read(name) == subprocess.check_output(["git", "show", TAG + ":" + name], cwd=ROOT)
    manifest = output / f"{PREFIX}-SHA256.txt"
    manifest.write_text("".join(hashlib.sha256(path.read_bytes()).hexdigest() + "  " + path.name + "\n" for path in artifacts), encoding="utf-8")
    artifacts.append(manifest)
    for path in artifacts:
        print(str(path.resolve()))
    return artifacts


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=pathlib.Path, default=ROOT / "dist")
    args = parser.parse_args()
    build(args.output.resolve())
