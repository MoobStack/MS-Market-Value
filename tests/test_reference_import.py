"""Offline importer checks; run with python3 -m unittest discover -s tests -p 'test_*.py'."""
import importlib.util
import json
from pathlib import Path
import tempfile
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
    def test_rates_keep_sample_denominators_and_omit_tiny_samples(self):
        rows, omitted = importer.read_rows(page([
            {"id": 100, "count": 10, "outof": 400, "name": "Material"},
            {"id": 101, "count": 1, "outof": 1, "name": "Tiny sample"},
        ]), source(), 50)
        self.assertEqual(rows, [{"id": 100, "name": "Material", "rate": 2.5, "samples": 400}])
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

    def test_large_tables_are_capped_before_lua_output(self):
        rows = [{"id": n, "count": 1, "outof": 100} for n in range(1, 301)]
        values, omitted = importer.read_rows(page(rows), source(), 50)
        self.assertEqual(len(values), 200); self.assertEqual(omitted, 100)

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
            self.assertIn("end,false)", (output / "Reference.lua").read_text())


if __name__ == "__main__": unittest.main()
