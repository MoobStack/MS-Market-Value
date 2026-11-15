#!/usr/bin/env python3
"""Build a small optional reference addon from saved Wowhead Forever pages.

No JavaScript is executed and no requests are made. Input is a JSON manifest:
[{"id":258573,"kind":"loot","file":"mudfin.html",
  "url":"https://www.wowhead.com/forever/npc=258573/mudfin-oracle"}]
"""
from __future__ import annotations
import argparse
from datetime import date
import html
import hashlib
import json
from pathlib import Path
import re
from urllib.parse import urlsplit

MAX_SOURCES, MAX_ROWS, MAX_TOTAL = 256, 200, 20000
TABLES = {"loot": "drops", "skinning": "skinning", "herbalism": "contains", "mining": "contains"}


def integer(value, low=1, high=2147483647):
    return type(value) is int and low <= value <= high


def source_identity(url):
    parsed = urlsplit(url)
    if parsed.scheme != "https" or parsed.netloc != "www.wowhead.com":
        raise ValueError("Use the canonical https://www.wowhead.com/forever/ URL")
    match = re.fullmatch(r"/forever/(npc|object)=(\d+)(?:/[\w-]+)?", parsed.path)
    if not match or parsed.query or parsed.fragment:
        raise ValueError("Only Forever NPC/object pages are supported")
    return match[1], int(match[2])


def read_rows(page, source, minimum):
    entity, identifier = source_identity(source["url"])
    kind = source["kind"]
    if kind not in TABLES or not integer(source["id"]) or source["id"] != identifier:
        raise ValueError("Invalid source ID or harvesting kind")
    if entity != ("object" if kind in ("herbalism", "mining") else "npc"):
        raise ValueError("Herbs/ore require an object page; drops/skinning require an NPC")
    if len(page.encode("utf-8")) > 8 * 1024 * 1024:
        raise ValueError("Page exceeds the 8 MiB input limit")
    canonical = re.search(r'<link\b[^>]*rel=[\'"]canonical[\'"][^>]*href=[\'"]([^\'"]+)', page)
    if not canonical or source_identity(html.unescape(canonical[1])) != (entity, identifier):
        raise ValueError("Saved page canonical URL does not match its source")
    rows = None
    for match in re.finditer(r"new\s+Listview\s*\(", page):
        start = match.end()
        following = re.search(r"new\s+Listview\s*\(", page[start:])
        block = page[start:start + following.start()] if following else page[start:]
        table_id = re.search(r"\bid\s*:\s*['\"]([^'\"]+)['\"]", block[:1000])
        if not table_id or table_id[1] != TABLES[kind]:
            continue
        data = re.search(r"\bdata\s*:\s*(\[)", block)
        if not data:
            raise ValueError("The requested loot table has no embedded data")
        rows, _ = json.JSONDecoder().raw_decode(block[data.start(1):])
        break
    if not isinstance(rows, list) or len(rows) > 10000:
        raise ValueError("Requested loot table not found or oversized; no fallback table was used")
    result, seen = [], set()
    for row in rows:
        if not isinstance(row, dict):
            continue
        item, count, samples = row.get("id"), row.get("count"), row.get("outof")
        if not integer(item) or not integer(samples, minimum, 1000000000) or not integer(count, 1, samples):
            continue
        if item in seen:
            raise ValueError("Duplicate item rows need review before combining modes or phases")
        seen.add(item)
        name = html.unescape(str(row.get("displayName") or row.get("name") or f"Item {item}"))
        name = re.sub(r"[\x00-\x1f\x7f]", "", name).replace("|", "")[:180]
        result.append({"id": item, "name": name, "rate": round(count / samples * 100, 6), "samples": samples})
    result.sort(key=lambda r: (-r["rate"], r["id"]))
    return result[:MAX_ROWS], len(rows) - min(len(result), MAX_ROWS)


def lua_string(value):
    # JSON quotes are Lua-compatible for these UTF-8 strings; escape remaining
    # controls explicitly and never execute content copied from the source page.
    return json.dumps(value, ensure_ascii=False)


def build(manifest, output, minimum=50, stamp=None):
    sources = json.loads(manifest.read_text(encoding="utf-8"))
    if not isinstance(sources, list) or not 1 <= len(sources) <= MAX_SOURCES:
        raise ValueError("Choose 1-256 sources")
    if not integer(minimum, 1, 1000000000):
        raise ValueError("Minimum samples must be a positive whole number")
    data, provenance, count = {}, [], 0
    stamp = stamp or date.today().isoformat()
    for source in sources:
        if not isinstance(source, dict):
            raise ValueError("Each source must be an object")
        file = (manifest.parent / source["file"]).resolve()
        if file.stat().st_size > 8 * 1024 * 1024:
            raise ValueError("Page exceeds 8 MiB")
        rows, omitted = read_rows(file.read_text(encoding="utf-8"), source, minimum)
        key = f'{source["kind"]}:{source["id"]}'
        if key in data:
            raise ValueError("Duplicate source/kind")
        data[key] = rows
        count += len(rows)
        if count > MAX_TOTAL:
            raise ValueError("Reference pack exceeds 20,000 item rows; choose fewer sources")
        provenance.append({"id": source["id"], "kind": source["kind"], "url": source["url"],
                           "imported": stamp, "pageSHA256": hashlib.sha256(file.read_bytes()).hexdigest(),
                           "minimumSamples": minimum, "rows": len(rows), "omitted": omitted})
    if count == 0:
        raise ValueError("No rows meet the sample threshold")
    label = f"Wowhead Forever ({len(data)} sources; sampled)"
    lines = ["-- Sampled observations, not verified server settings.", "local rows={"]
    for key, values in sorted(data.items()):
        lines.append("[" + lua_string(key) + "]={")
        for row in values:
            lines.append("{id=%d,rate=%.6f,samples=%d,name=%s}," %
                         (row["id"], row["rate"], row["samples"], lua_string(row["name"])))
        lines.append("},")
    lines.extend(["}", "local A=_G.MSMarketValue", "if A and A.LootReference then",
                  " A.LootReference.Register(" + lua_string(label) + ",function(id,kind)",
                  '  return rows[(kind or "loot") .. ":" .. id]', " end,false)", "end", ""])
    output.mkdir(parents=True, exist_ok=True)
    (output / "Reference.lua").write_text("\n".join(lines), encoding="utf-8")
    toc = ("## Interface: 16001\n## Title: MS Market Value - Reference observations\n"
           "## Notes: Optional Wowhead Forever observations; not server drop settings.\n"
           "## Version: " + stamp + "\n## Dependencies: MSMarketValue\nReference.lua\n")
    for name in ("MSMarketValueReference", "MSMarketValueReference_Forever", "MSMarketValueReference_Camelot"):
        (output / (name + ".toc")).write_text(toc, encoding="utf-8")
    (output / "SOURCES.json").write_text(json.dumps(provenance, indent=2) + "\n", encoding="utf-8")
    (output / "README.txt").write_text(
        "Optional reference observations\n\n"
        "Install this folder alongside MSMarketValue, reload WoW, then choose Reference observations in /msmv drops.\n"
        "Only the sources in SOURCES.json are covered. Counts come from saved Wowhead Forever pages; they may include\n"
        "carried-over Classic observations. They are not verified Forever server chances. An absent item is unknown, not 0%.\n"
        f"Imported {stamp}; minimum {minimum} samples per item; {count} rows. Very small samples are omitted.\n"
        "All files are local. The addon does not connect to Wowhead, upload data or change personal observations.\n"
        "To update, rebuild one combined pack from the desired source pages. Use only one reference pack at a time.\n",
        encoding="utf-8")
    return {"sources": len(data), "rows": count, "minimumSamples": minimum}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=Path)
    parser.add_argument("--output", type=Path, required=True, help="Folder named MSMarketValueReference")
    parser.add_argument("--min-samples", type=int, default=50)
    args = parser.parse_args()
    if args.output.name != "MSMarketValueReference":
        parser.error("Output folder must be named MSMarketValueReference")
    try:
        print(json.dumps(build(args.manifest, args.output, args.min_samples)))
    except (ValueError, KeyError, OSError) as error:
        parser.exit(1, f"Import stopped: {error}\n")
