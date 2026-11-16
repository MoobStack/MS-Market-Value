#!/usr/bin/env python3
"""Bundle a checked Dataset Builder export. Offline; no source code is executed."""
from __future__ import annotations
import argparse
import gzip
import hashlib
import io
import json
from pathlib import Path
import zipfile

from import_reference import integer, lua_string, pack_rows

KINDS = ("loot", "skinning", "herbalism", "mining")
LIMIT = 64 * 1024 * 1024


def read_export(path):
    raw = path.read_bytes()
    if len(raw) > LIMIT:
        raise ValueError("Export exceeds 64 MiB; review before bundling")
    with zipfile.ZipFile(io.BytesIO(raw)) as archive:
        names = archive.namelist()
        if len(names) != len(set(names)) or sum(x.file_size for x in archive.infolist()) > LIMIT:
            raise ValueError("Duplicate files or oversized export")
        manifest = json.loads(archive.read("manifest.json"))
        if manifest.get("source") != "https://everloot.app" or manifest.get("format") != "packed-v1":
            raise ValueError("Use a packed Everloot export")
        coverage = manifest["coverage"]
        if not coverage.get("complete") or not manifest.get("referencePackIncluded"):
            raise ValueError("Complete the typed download before bundling")
        for entry in manifest["files"]:
            data = archive.read(entry["name"])
            if len(data) != entry["bytes"] or hashlib.sha256(data).hexdigest() != entry["sha256"]:
                raise ValueError("Export checksum mismatch")
        with gzip.GzipFile(fileobj=io.BytesIO(archive.read("dataset.jsonl.gz"))) as stream:
            normalized = stream.read(LIMIT + 1)
        if len(normalized) > LIMIT or hashlib.sha256(normalized).hexdigest() != manifest["datasetSHA256"]:
            raise ValueError("Normalized dataset checksum/size mismatch")
        records = [json.loads(line) for line in normalized.splitlines()]
        if sum(len(r["rows"]) for r in records) != coverage["availableRows"]:
            raise ValueError("Dataset row counts do not match the report")
        notice = archive.read("NOTICE.txt").decode("utf-8")
    data, sources, total = {}, [], 0
    for record in records:
        kind = record["kind"]
        if kind not in KINDS:
            if kind not in ("npc", "object"):
                raise ValueError("Unknown loot mode")
            continue
        identifier = record["sourceID"]
        if not integer(identifier, 1, 2147483647) or record["sourceType"] != ("object" if kind in ("herbalism", "mining") else "npc"):
            raise ValueError("Invalid source ID/type")
        key = kind, identifier
        if key in data:
            raise ValueError("Duplicate source/mode")
        rows = []
        for row in record["rows"]:
            if row["evidence"] != "player-counted":
                raise ValueError("Keep curated data in a separate reference pack")
            value = {"id": row["id"], "hits": row["observed"], "samples": row["encounters"]}
            if row.get("questItem") is True:
                value["questItem"] = True
            if "questID" in row:
                if not integer(row["questID"], 1, 2147483647):
                    raise ValueError("Invalid quest ID")
                value["questID"] = row["questID"]
            rows.append(value)
        data[key] = pack_rows(rows)
        total += len(rows)
        sources.append({k: record[k] for k in ("kind", "sourceID", "sourceType", "name", "url", "updatedAt")})
    if total != coverage["addonCompatibleRows"] or len(data) != coverage["sourceModes"]:
        raise ValueError("Typed coverage does not match the report")
    return raw, manifest, data, sources, notice


def build(path, root):
    raw, manifest, data, sources, notice = read_export(path)
    coverage = manifest["coverage"]
    meta = {"version": manifest["datasetVersion"], "rates": coverage["addonCompatibleRows"],
            "sources": len(data), "updatedAt": coverage["typedCorpus"]["data_as_of"]}
    lines = ["-- Everloot community samples; CC BY-SA 4.0. See Everloot-NOTICE.txt.",
             "local _, A = ...", "local sources={"]
    for kind in KINDS:
        lines.append("[" + lua_string(kind) + "]={")
        for (mode, identifier), code in sorted(data.items(), key=lambda pair: pair[0][1]):
            if mode == kind:
                lines.append(f"[{identifier}]={lua_string(code)},")
        lines.append("},")
    lines.extend(["}", 'if A.LootReference.RegisterPacked("Everloot reference",sources,"everloot") then',
                  " A.LootReference.bundled={" + ",".join(k + "=" + (lua_string(v) if isinstance(v, str) else str(v)) for k, v in meta.items()) + "}",
                  "end", ""])
    module = "\n".join(lines).encode("utf-8")
    receipt = {"schema": 1, "archive": path.name, "archiveSHA256": hashlib.sha256(raw).hexdigest(),
               "manifest": manifest, "runtimeSHA256": hashlib.sha256(module).hexdigest(), "sources": sources}
    target = root / "MSMarketValue/Data"
    provenance = root / "datasets/everloot"
    target.mkdir(parents=True, exist_ok=True)
    provenance.mkdir(parents=True, exist_ok=True)
    (target / "Everloot.lua").write_bytes(module)
    (target / "Everloot-NOTICE.txt").write_text(notice + f"\nBundled {meta['version']}: {meta['rates']} rates in {meta['sources']} sources/modes.\nTyped snapshot UTC: {meta['updatedAt']}\nOnly mode-resolved counts are loaded. Personal samples remain separate.\n", encoding="utf-8")
    (provenance / path.name).write_bytes(raw)
    (provenance / "provenance.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    return {**meta, "runtimeBytes": len(module), "encodedBytes": sum(map(len, data.values()))}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    try:
        print(json.dumps(build(args.archive, args.root), indent=2))
    except (ValueError, KeyError, OSError, zipfile.BadZipFile) as exc:
        parser.exit(1, f"Bundle stopped: {exc}\n")
