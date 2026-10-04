#!/usr/bin/env python3
"""Repository contract checks plus Lua 5.1 behavioral tests. No third-party Python deps."""
from __future__ import annotations
import argparse
import hashlib
import json
import pathlib
import re
import subprocess

ROOT = pathlib.Path(__file__).resolve().parents[1]
RUNTIME = ROOT / "MSMarketValue"


def run(lua: str, luac: str | None = None) -> None:
    toc = RUNTIME / "MSMarketValue.toc"
    text = toc.read_text(encoding="utf-8")
    meta = json.loads((ROOT / "build.json").read_text(encoding="utf-8"))
    assert meta["version"] == "0.1.0-beta", "Hold the primary beta version until the finalized release"
    assert f'## Interface: {meta["interface"]}\n' in text
    assert f'## Version: {meta["version"]}\n' in text
    assert f'## X-Build: {meta["build"]}\n' in text
    bootstrap = (RUNTIME / "Bootstrap.lua").read_text(encoding="utf-8")
    assert f'A.VERSION = "{meta["version"]}"' in bootstrap
    assert f'A.BUILD = "{meta["build"]}"' in bootstrap
    assert f'A.INTERFACE = {meta["interface"]}' in bootstrap
    assert meta["gitTag"] == f'v{meta["version"]}-build{meta["buildNumber"]}'
    assert "## SavedVariables: MSMarketValueDB\n" in text
    assert "## LoadSavedVariablesFirst: 1\n" in text
    for suffix in ("Camelot", "Forever"):
        assert (RUNTIME / f"MSMarketValue_{suffix}.toc").read_bytes() == toc.read_bytes()
    paths = [line.replace("\\", "/") for line in text.splitlines() if line and not line.startswith("#")]
    assert len(paths) == len(set(paths)) == 11
    assert paths[0] == "Bootstrap.lua" and paths[-1] == "Core/Events.lua"
    assert paths[1:3] == ["Libs/LibStub/LibStub.lua", "Libs/LibAHTab/LibAHTab.lua"]
    assert set(paths) == {p.relative_to(RUNTIME).as_posix() for p in RUNTIME.rglob("*.lua")}
    vendor = json.loads((ROOT / "tools/vendor.json").read_text(encoding="utf-8"))
    for relative, checksums in vendor["files"].items():
        assert hashlib.sha256((RUNTIME / relative).read_bytes()).hexdigest() == checksums["bundled_sha256"], relative
    forbidden = re.compile(r"\b(?:RunScript|loadstring|loadfile|QueryAuctionItems|SendSearchQuery|PlaceAuctionBid|PostItem|PostCommodity|ConfirmCommoditiesPurchase|CastSpellByName|SendChatMessage)\s*\(")
    for relative in paths:
        path = (RUNTIME / relative).resolve()
        assert path.is_relative_to(RUNTIME.resolve()) and path.is_file()
        code = path.read_text(encoding="utf-8")
        assert not forbidden.search(code), f"Forbidden runtime operation: {relative}"
        if luac:
            subprocess.run([luac, "-p", str(path)], check=True)
    result = subprocess.run([lua, "-e", 'assert(_VERSION == "Lua 5.1", "Use Lua 5.1 to validate this addon")'], check=True)
    assert result.returncode == 0
    subprocess.run([lua, "tests/run.lua"], cwd=ROOT, check=True)
    print("PASS TOC/load order, beta identity, Lua 5.1, and runtime operation checks.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--lua", default="lua5.1")
    parser.add_argument("--luac", default=None)
    args = parser.parse_args()
    run(args.lua, args.luac)
