#!/usr/bin/env python3
"""Compile the pinned ClassicDB snapshot into a pooled, offline reference layer."""
from __future__ import annotations

import argparse
import csv
import gzip
import hashlib
import json
import math
from pathlib import Path
import re
import shutil
from collections import Counter, defaultdict

ROOT = Path(__file__).resolve().parents[1]
SNAPSHOT = "ClassicDB_1_12_1_z2815.sql.gz"
SHA256 = "4f92db520868ab4e566726f68b5b2e380ae781209beaf22237b4f7f04600d0c0"
COMMIT = "e4825cf48176edff313d78de66b0beb14371c8eb"
ENGINE = "b2bf92e57c97162d59048b030fb8cb1646bc4913"
URL = f"https://raw.githubusercontent.com/cmangos/classic-db/{COMMIT}/Full_DB/{SNAPSHOT}"
ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
SCALE = 100000000  # probability, not a sample count; 0.000001 percentage point
TABLES = {"creature_template", "item_template", "creature_loot_template",
          "reference_loot_template", "skinning_loot_template"}


def tuples(text):
    """Parse SQL VALUES as literals only. Never connect to or execute SQL."""
    start = None
    quoted = escaped = False
    for index, char in enumerate(text):
        if escaped:
            escaped = False
            continue
        if quoted and char == "\\":
            escaped = True
        elif char == "'":
            quoted = not quoted
        elif not quoted and char == "(":
            if start is not None:
                raise ValueError("Nested SQL value")
            start = index + 1
        elif not quoted and char == ")":
            if start is None:
                raise ValueError("Unbalanced SQL value")
            yield next(csv.reader([text[start:index]], delimiter=",", quotechar="'", escapechar="\\"))
            start = None
    if quoted or start is not None:
        raise ValueError("Incomplete SQL literal")


def read_snapshot(path):
    if hashlib.sha256(path.read_bytes()).hexdigest() != SHA256:
        raise ValueError("Use the pinned, checksum-verified ClassicDB full snapshot")
    schemas, data, current = {}, defaultdict(list), None
    with gzip.open(path, "rt", encoding="utf-8") as stream:
        for line in stream:
            create = re.match(r"CREATE TABLE `([^`]+)`", line)
            if create:
                current = create[1]
                schemas[current] = []
            elif current and line.startswith("  `"):
                schemas[current].append(line.split("`", 2)[1])
            elif current and line.startswith(")"):
                current = None
            insert = re.match(r"INSERT INTO `([^`]+)` VALUES (.*);\s*$", line)
            if not insert or insert[1] not in TABLES:
                continue
            columns = schemas[insert[1]]
            for values in tuples(insert[2]):
                if len(values) != len(columns):
                    raise ValueError(f"Column mismatch: {insert[1]}")
                if insert[1] == "creature_template":
                    row = dict(zip(columns, values))
                    data[insert[1]].append(tuple(int(row[k]) for k in ("Entry", "LootId", "SkinningLootId")))
                elif insert[1] == "item_template":
                    row = dict(zip(columns, values))
                    if row["class"] == "12" or row["bonding"] == "4":
                        data[insert[1]].append(int(row["entry"]))
                else:
                    data[insert[1]].append((int(values[0]), int(values[1]), float(values[2]),
                                            int(values[3]), int(values[4]), int(values[5]), int(values[6])))
    if not all(data[t] for t in TABLES):
        raise ValueError("Missing source tables")
    return data


class Compiler:
    def __init__(self, references, quest_items=()):
        self.references = references
        self.quest_items = set(quest_items)
        self.cache = {}
        self.skipped = Counter()

    def branch(self, row, stack):
        _, item, _, _, minimum, maximum, _ = row
        if minimum >= 0:
            return {item: 1.0}
        target = -minimum
        if target in stack or target not in self.references:
            self.skipped["missingOrCyclicReferences"] += 1
            return {}
        if target not in self.cache:
            self.cache[target] = self.compile(self.references[target], stack + (target,))
        return {item: -math.expm1(maximum * math.log1p(-p)) if p < 1 else 1.0
                for item, p in self.cache[target].items()}

    def compile(self, rows, stack=()):
        groups, independent = defaultdict(list), []
        for row in rows:
            if row[3]:
                groups[row[3]].append(row)
            elif row[6]:
                self.skipped["conditionalRows"] += 1
            else:
                chance = min(1, abs(row[2]) / 100)
                if chance:
                    independent.append({item: p * chance for item, p in self.branch(row, stack).items()})
        for entries in groups.values():
            # Eligibility can change group probabilities. Leave these to the
            # Forever/personal layers rather than inventing an unconditional rate.
            if any(row[6] for row in entries):
                self.skipped["conditionalGroupRows"] += len(entries)
                continue
            total = sum(abs(row[2]) for row in entries)
            equal = sum(row[2] == 0 for row in entries)
            if total > 100.0001:
                self.skipped["overfullGroupRows"] += len(entries)
                continue
            group = defaultdict(float)
            for row in entries:
                weight = abs(row[2]) / 100 if row[2] else max(0, 1 - total / 100) / equal
                for item, p in self.branch(row, stack).items():
                    group[item] += weight * p
            independent.append(group)
        result = {}
        for component in independent:
            for item, p in component.items():
                result[item] = 1 - (1 - result.get(item, 0)) * (1 - min(1, p))
        return {item: p for item, p in result.items() if p > 0}


def varint(number):
    out = ""
    while number >= 32:
        out += ALPHABET[number % 32 + 32]
        number //= 32
    return out + ALPHABET[number]


def pack(rows, quest_items, lists=None, list_ids=None):
    if not 0 < len(rows) <= 4096:
        raise ValueError("Source exceeds the runtime decode limit")
    previous, parts = 0, [varint(len(rows))]
    grouped = defaultdict(list)
    for item, probability in sorted(rows.items()):
        scaled = max(1, min(SCALE, round(probability * SCALE)))
        value = scaled * 2 + (item in quest_items)
        if lists is not None:
            grouped[value].append(item)
        else:
            parts += [varint(item - previous), varint(value)]
        previous = item
    for value, items in sorted(grouped.items()):
        previous, code = 0, ""
        for item in items:
            code += varint(item - previous)
            previous = item
        if code not in list_ids:
            lists.append(code)
            list_ids[code] = len(lists)
        parts += [varint(list_ids[code]), varint(value)]
    return "".join(parts)


def build(path, license_path, root=ROOT):
    license_bytes = license_path.read_bytes()
    if b"GNU GENERAL PUBLIC LICENSE" not in license_bytes or b"Version 3, 29 June 2007" not in license_bytes:
        raise ValueError("Include the upstream GPL-3.0 license unchanged")
    data = read_snapshot(path)
    tables = {}
    for name in ("creature_loot_template", "reference_loot_template", "skinning_loot_template"):
        table = defaultdict(list)
        for row in data[name]:
            table[row[0]].append(row)
        tables[name] = table
    compiler = Compiler(tables["reference_loot_template"], data["item_template"])
    quest_items = set(data["item_template"])
    # Negative chances also mark quest-only drops, including non-quest-class items.
    for table in tables.values():
        quest_items.update(row[1] for rows in table.values() for row in rows if row[2] < 0 and row[4] > 0)
    pool, pool_ids, maps, rates, npc_ids = [], {}, {"loot": {}, "skinning": {}}, 0, set()
    item_lists, list_ids = [], {}
    compiled = {}
    for npc, loot, skin in sorted(data["creature_template"]):
        for kind, entry, table_name in (("loot", loot, "creature_loot_template"), ("skinning", skin, "skinning_loot_template")):
            if not entry or entry not in tables[table_name]:
                continue
            key = kind, entry
            if key not in compiled:
                rows = compiler.compile(tables[table_name][entry])
                compiled[key] = (pack(rows, quest_items, item_lists, list_ids), len(rows)) if rows else None
            value = compiled[key]
            if not value:
                continue
            code, count = value
            if code not in pool_ids:
                pool.append(code)
                pool_ids[code] = len(pool)
            maps[kind][npc] = pool_ids[code]
            npc_ids.add(npc)
            rates += count
    meta = {"label": "Classic 1.12 reference", "npcs": len(npc_ids), "lootNPCs": len(maps["loot"]),
            "skinningNPCs": len(maps["skinning"]), "sources": sum(map(len, maps.values())), "rates": rates,
            "tables": len(pool), "itemLists": len(item_lists), "scale": SCALE, "snapshot": SNAPSHOT, "verified": False}
    lines = ["-- ClassicDB nominal base chances; unverified for Forever. GPL-3.0.",
             "-- See Classic-NOTICE.txt. Rebuild with tools/bundle_classic.py.", "local _, A = ...", "local pool={"]
    lines.extend('"' + code + '",' for code in pool)
    lines += ["}", "local items={"]
    lines.extend('"' + code + '",' for code in item_lists)
    lines += ["}", "local sources={"]
    for kind, mapping in maps.items():
        lines.append(kind + "={")
        lines.extend(f"[{npc}]={index}," for npc, index in sorted(mapping.items()))
        lines.append("},")
    lines += ["}", "A.LootReference.RegisterClassicPacked({" + ",".join(
        k + "=" + (json.dumps(v) if isinstance(v, str) else str(v).lower()) for k, v in meta.items()) + "},sources,pool,items)", ""]
    module = "\n".join(lines).encode()
    target, source = root / "MSMarketValue/Data", root / "datasets/classic"
    source.mkdir(parents=True, exist_ok=True)
    target.mkdir(parents=True, exist_ok=True)
    (target / "Classic.lua").write_bytes(module)
    for original, destination in ((path, source / SNAPSHOT), (license_path, source / "COPYING")):
        if original.resolve() != destination.resolve():
            shutil.copyfile(original, destination)
    (target / "Classic-COPYING.txt").write_bytes(license_bytes)
    notice = ("Classic fallback data\n\nDerived from CMaNGOS ClassicDB, Classic 1.12; GPL-3.0.\n"
              f"Source: {URL}\nSource SHA256: {SHA256}\n\n"
              "These are historical nominal Classic chances, not verified Forever rates.\n"
              "No claim is made that this snapshot includes all later ClassicDB updates.\n"
              "Forever samples override matching items; personal data fills remaining gaps.\n"
              "Conditional/overfull groups are omitted. Shared tables are expanded offline;\n"
              "base rates exclude server multipliers, eligibility and duplicate-prevention effects.\n"
              "The full repository includes the source snapshot, license and rebuild utility.\n")
    (target / "Classic-NOTICE.txt").write_text(notice)
    provenance = {**meta, "sourceURL": URL, "sourceCommit": COMMIT, "sourceSHA256": SHA256,
                  "reviewedLootEngine": f"https://github.com/cmangos/mangos-classic/blob/{ENGINE}/src/game/Loot/LootMgr.cpp",
                  "runtimeSHA256": hashlib.sha256(module).hexdigest(), "runtimeBytes": len(module),
                  "encodedBytes": sum(map(len, pool)) + sum(map(len, item_lists)), "omissions": dict(sorted(compiler.skipped.items()))}
    (source / "provenance.json").write_text(json.dumps(provenance, indent=2) + "\n")
    return provenance


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("snapshot", type=Path)
    parser.add_argument("license", type=Path)
    parser.add_argument("--root", type=Path, default=ROOT)
    args = parser.parse_args()
    print(json.dumps(build(args.snapshot, args.license, args.root), indent=2))
