"""Verify the shipped reference against its immutable export and real Lua reader."""
import gzip
import hashlib
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
try:
    import bundle_everloot as bundler
finally:
    sys.path.pop(0)
PROVENANCE = json.loads((ROOT / "datasets/everloot/provenance.json").read_text())
EXPORT = ROOT / "datasets/everloot" / PROVENANCE["archive"]


def altered(target, change):
    with zipfile.ZipFile(EXPORT) as archive:
        files = {name: archive.read(name) for name in archive.namelist()}
    change(files)
    with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as archive:
        for name, data in files.items():
            archive.writestr(name, data)


class BundledReference(unittest.TestCase):
    def test_rebuild_is_identical_and_the_input_export_keeps_its_provenance(self):
        self.assertEqual(hashlib.sha256(EXPORT.read_bytes()).hexdigest(), PROVENANCE["archiveSHA256"])
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            result = bundler.build(EXPORT, root)
            self.assertEqual((result["rates"], result["sources"], result["encodedBytes"]), (1848, 238, 8251))
            for relative in ("MSMarketValue/Data/Everloot.lua", "MSMarketValue/Data/Everloot-NOTICE.txt",
                             "datasets/everloot/provenance.json", "datasets/everloot/" + EXPORT.name):
                self.assertEqual((root / relative).read_bytes(), (ROOT / relative).read_bytes())
        self.assertIn("CC BY-SA 4.0", (ROOT / "MSMarketValue/Data/Everloot-NOTICE.txt").read_text())

    def test_every_bundled_rate_matches_the_export_in_the_real_lua_reader(self):
        lua = os.environ.get("MSMV_TEST_LUA") or shutil.which("lua5.1")
        if not lua:
            self.skipTest("Supply Lua 5.1 through tools/validate.py")
        with zipfile.ZipFile(EXPORT) as archive:
            records = [json.loads(line) for line in gzip.decompress(archive.read("dataset.jsonl.gz")).splitlines()]
        typed = [r for r in records if r["kind"] in bundler.KINDS]
        expected = {(r["kind"], r["sourceID"], v["id"]): v for r in typed for v in r["rows"]}
        script = ['local A={}',
                  'assert(loadfile("MSMarketValue/Core/Util.lua"))("MSMarketValue",A)',
                  'assert(loadfile("MSMarketValue/Data/LootReference.lua"))("MSMarketValue",A)',
                  'collectgarbage("collect");local before=collectgarbage("count")',
                  'assert(loadfile("MSMarketValue/Data/Everloot.lua"))("MSMarketValue",A)',
                  'collectgarbage("collect");local packed=collectgarbage("count")-before',
                  'assert(A.LootReference.cachedRows==0);local longest=0']
        for source in typed:
            script.append('do local t=os.clock();local rows=A.LootReference.Rows(%d,"%s");longest=math.max(longest,(os.clock()-t)*1000);for _,r in ipairs(rows)do print(string.format("%s,%d,%%d,%%d,%%.12f",r.id,r.samples,r.rate))end;assert(#A.LootReference.order<=8 and A.LootReference.cachedRows<=4096)end' %
                          (source["sourceID"], source["kind"], source["kind"], source["sourceID"]))
        script.append('collectgarbage("collect");print(string.format("BUNDLED_REFERENCE_BENCHMARK sources=238 rows=1848 packed_kib=%.2f with_cache_kib=%.2f cached_sources=%d max_decode_ms=%.3f",packed,collectgarbage("count")-before,#A.LootReference.order,longest))')
        result = subprocess.run([lua, "-e", "\n".join(script)], cwd=ROOT, check=True, capture_output=True, text=True)
        actual = {}
        for line in result.stdout.splitlines():
            if line.startswith("BUNDLED_REFERENCE_BENCHMARK"):
                print(line, flush=True)
                continue
            kind, source, item, samples, percent = line.split(",")
            key = kind, int(source), int(item)
            self.assertNotIn(key, actual)
            actual[key] = int(samples), float(percent)
        self.assertEqual(set(actual), set(expected))
        for key, row in expected.items():
            self.assertEqual(actual[key][0], row["encounters"])
            self.assertAlmostEqual(actual[key][1], row["observed"] / row["encounters"] * 100, places=9)

    def test_a_bad_checksum_cannot_replace_the_installed_module(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory);module = root / "MSMarketValue/Data/Everloot.lua"
            module.parent.mkdir(parents=True);module.write_text("previous dataset")
            target = root / "bad.zip"
            altered(target, lambda files: files.__setitem__("dataset.csv", files["dataset.csv"] + b"tampered"))
            with self.assertRaisesRegex(ValueError, "checksum"):
                bundler.build(target, root)
            self.assertEqual(module.read_text(), "previous dataset")

    def test_incomplete_or_unresolved_exports_are_never_bundled(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for key in ("complete", "referencePackIncluded"):
                def change(files):
                    manifest = json.loads(files["manifest.json"])
                    (manifest["coverage"] if key == "complete" else manifest)[key] = False
                    files["manifest.json"] = json.dumps(manifest).encode()
                target = root / "bad.zip";altered(target, change)
                with self.assertRaises(ValueError):
                    bundler.build(target, root)
                self.assertFalse((root / "MSMarketValue").exists())

    def test_source_modes_are_checked_even_when_all_file_hashes_are_valid(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            def change(files):
                records = [json.loads(line) for line in gzip.decompress(files["dataset.jsonl.gz"]).splitlines()]
                next(r for r in records if r["kind"] == "herbalism")["sourceType"] = "npc"
                normalized = ("\n".join(json.dumps(r) for r in records) + "\n").encode()
                files["dataset.jsonl.gz"] = gzip.compress(normalized)
                manifest = json.loads(files["manifest.json"])
                manifest["datasetSHA256"] = hashlib.sha256(normalized).hexdigest()
                entry = next(e for e in manifest["files"] if e["name"] == "dataset.jsonl.gz")
                entry["bytes"] = len(files["dataset.jsonl.gz"])
                entry["sha256"] = hashlib.sha256(files["dataset.jsonl.gz"]).hexdigest()
                files["manifest.json"] = json.dumps(manifest).encode()
            target = root / "bad.zip";altered(target, change)
            with self.assertRaisesRegex(ValueError, "source ID/type"):
                bundler.build(target, root)
            self.assertFalse((root / "MSMarketValue").exists())
