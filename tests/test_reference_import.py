"""Offline importer checks; run with python3 -m unittest discover -s tests -p 'test_*.py'."""
import importlib.util
import json
import os
from pathlib import Path
import tempfile
import subprocess
import shutil
import sys
import unittest

spec = importlib.util.spec_from_file_location("reference_import", Path(__file__).resolve().parents[1] / "tools/import_reference.py")
importer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(importer)


def source(identifier=1000, kind="loot"):
    entity = "object" if kind in ("herbalism", "mining") else "npc"
    return {"id": identifier, "kind": kind, "file": "page.html",
            "url": f"https://www.wowhead.com/forever/{entity}={identifier}/test"}


def page(rows, origin=None, table="drops"):
    origin = origin or source()
    return f'<link rel="canonical" href="{origin["url"]}">\nnew Listview({{id: \'{table}\', data:{json.dumps(rows)}}});'


class ImportChecks(unittest.TestCase):
    def test_starter_manifest_builds_with_the_documented_cli(self):
        repo=Path(__file__).resolve().parents[1]
        manifest=repo/"examples/reference-input/manifest.json"
        sources=json.loads(manifest.read_text())
        self.assertEqual(sources[0]["id"],258573)
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder);target=root/"manifest.json";target.write_bytes(manifest.read_bytes())
            (root/sources[0]["file"]).write_text(page([{"id":100,"count":1,"outof":1}],sources[0]))
            result=subprocess.run([sys.executable,str(repo/"tools/import_reference.py"),str(target),
                "--output",str(root/"MSMarketValueReference"),"--min-samples","1"],check=True,capture_output=True,text=True)
            self.assertEqual(json.loads(result.stdout)["rows"],1)
            self.assertEqual(json.loads((root/"MSMarketValueReference/SOURCES.json").read_text())[0]["origin"],"mixed-or-unspecified")

    def test_rates_keep_sample_denominators_and_omit_tiny_samples(self):
        rows, omitted = importer.read_rows(page([
            {"id": 100, "count": 10, "outof": 400, "name": "Material"},
            {"id": 101, "count": 1, "outof": 1, "name": "Tiny sample"},
        ]), source(), 50)
        self.assertEqual(rows, [{"id": 100, "name": "Material", "hits":10,"rate": 2.5, "samples": 400}])
        self.assertEqual(omitted, 1)

    def test_wrong_branch_or_source_is_rejected(self):
        for url in ("https://www.wowhead.com/classic/npc=1000/test", "https://example.com/forever/npc=1000/test"):
            src = source(); src["url"] = url
            with self.assertRaises(ValueError): importer.read_rows(page([], src), src, 50)
        with self.assertRaises(ValueError): importer.read_rows(page([], source(1001)), source(), 50)

    def test_no_fallback_to_a_different_loot_table(self):
        with self.assertRaises(ValueError): importer.read_rows(page([], table="pickpocketing"), source(), 50)

    def test_node_and_skinning_tables_stay_separate(self):
        row = {"id": 100, "count": 30, "outof": 100}
        for kind, table in (("herbalism", "contains"), ("mining", "contains"), ("skinning", "skinning")):
            src = source(kind=kind)
            self.assertEqual(importer.read_rows(page([row], src, table), src, 50)[0][0]["rate"], 30)

    def test_invalid_counts_and_duplicate_modes_do_not_inflate_rates(self):
        rows = [{"id": 100, "count": 101, "outof": 100}, {"id": True, "count": 1, "outof": 100}]
        self.assertEqual(importer.read_rows(page(rows), source(), 50)[0], [])
        rows = [{"id": 100, "count": 1, "outof": 100}] * 2
        with self.assertRaises(ValueError): importer.read_rows(page(rows), source(), 50)

    def test_all_valid_rows_are_kept_and_oversized_sources_require_review(self):
        rows = [{"id": n, "count": 1, "outof": 100} for n in range(1, 301)]
        values, omitted = importer.read_rows(page(rows), source(), 50)
        self.assertEqual(len(values), 300); self.assertEqual(omitted, 0)
        too_many=[{"id":n,"count":1,"outof":100} for n in range(1,4098)]
        with self.assertRaises(ValueError): importer.read_rows(page(too_many),source(),50)

    def test_page_scripts_are_not_evaluated_and_item_names_are_escaped(self):
        rows = [{"id": 100, "count": 1, "outof": 100, "name": 'A "quote" |cffff0000\n'}]
        values, _ = importer.read_rows(page(rows) + '\nos.execute("bad")', source(), 50)
        self.assertEqual(values[0]["name"], 'A "quote" cffff0000')
        self.assertEqual(importer.lua_string(values[0]["name"]), '"A \\"quote\\" cffff0000"'.replace('\\\\', '\\'))

    def test_pack_contains_provenance_and_no_saved_variables(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / "page.html").write_text(page([{"id": 100, "count": 25, "outof": 100}]))
            manifest = root / "manifest.json"; manifest.write_text(json.dumps([source()]))
            output = root / "MSMarketValueReference"
            self.assertEqual(importer.build(manifest, output, stamp="2026-11-15")["rows"], 1)
            toc = (output / "MSMarketValueReference.toc").read_text()
            self.assertIn("Dependencies: MSMarketValue", toc); self.assertNotIn("SavedVariables", toc)
            provenance = json.loads((output / "SOURCES.json").read_text())[0]
            self.assertEqual(provenance["url"], source()["url"])
            self.assertEqual(provenance["minimumSamples"], 50)
            code=(output / "Reference.lua").read_text()
            self.assertIn("RegisterPacked",code);self.assertNotIn("samples=",code)
            self.assertEqual(provenance["origin"],"mixed-or-unspecified")

    def test_compact_counts_keep_tiny_rates_and_quest_metadata(self):
        rows=[{"id":100,"hits":1,"samples":1000000,"questItem":True,"questID":42}]
        self.assertEqual(importer.pack_rows(rows),"BgywekDBDqB")
        self.assertEqual(importer.encode_uint(0),"A");self.assertEqual(importer.encode_uint(31),"f")
        self.assertEqual(importer.encode_uint(32),"gB")
        with self.assertRaises(ValueError):importer.pack_rows([])
        with self.assertRaises(ValueError):importer.encode_uint(-1)

    def test_source_origin_is_explicit_instead_of_inferred_from_url(self):
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder);(root/"page.html").write_text(page([{"id":100,"count":1,"outof":100}]))
            manifest=root/"manifest.json";src=source();src["origin"]="classic"
            manifest.write_text(json.dumps([src]));output=root/"pack"
            importer.build(manifest,output)
            self.assertIn("Wowhead Classic reference",(output/"Reference.lua").read_text())
            src["origin"]="guess";manifest.write_text(json.dumps([src]))
            with self.assertRaises(ValueError):importer.build(manifest,output)

    def test_python_output_decodes_in_the_real_lua_reader(self):
        lua=os.environ.get("MSMV_TEST_LUA") or shutil.which("lua5.1")
        if not lua:self.skipTest("Lua 5.1 is supplied by tools/validate.py")
        rows=[{"id":100,"hits":1,"samples":1000000,"questItem":True,"questID":42},
              {"id":102,"hits":25,"samples":400},{"id":1000000,"hits":2,"samples":1000000}]
        code=importer.pack_rows(rows)
        script='''local A={}
assert(loadfile("MSMarketValue/Core/Util.lua"))("MSMarketValue",A)
assert(loadfile("MSMarketValue/Data/LootReference.lua"))("MSMarketValue",A)
local rows=A.LootReference.Decode('''+json.dumps(code)+''')
assert(#rows==3 and rows[1].id==100 and rows[1].questID==42 and rows[1].questItem)
assert(math.abs(rows[1].rate-.0001)<.0000000001 and rows[1].samples==1000000)
assert(rows[2].id==102 and rows[2].samples==400 and rows[2].rate==6.25)
assert(rows[3].id==1000000 and rows[3].samples==1000000)
'''
        subprocess.run([lua,"-e",script],cwd=Path(__file__).resolve().parents[1],check=True,capture_output=True,text=True)

    @unittest.skipUnless(os.environ.get("MSMV_BENCHMARK")=="1","optional reference workload")
    def test_generate_large_reference_workload(self):
        target=Path(__file__).resolve().parent/"tmp/reference-workload.lua";target.parent.mkdir(exist_ok=True)
        lines=["local sources={loot={"]
        encoded=0
        for source_id in range(1,1001):
            rows=[{"id":10000+item,"hits":1+(item+source_id)%99,"samples":10000+source_id} for item in range(1,501)]
            code=importer.pack_rows(rows);encoded+=len(code)
            lines.append(f'[{source_id}]="{code}",')
        lines.extend(["}}",'_G.MSMarketValue.LootReference.RegisterPacked("Synthetic workload",sources)'])
        target.write_text("\n".join(lines)+"\n")
        self.assertLess(encoded,2500000)


if __name__ == "__main__": unittest.main()
