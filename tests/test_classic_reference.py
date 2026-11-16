"""Probability fixtures, reproducible source checks and the real Lua decoder."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from collections import defaultdict

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import bundle_classic as classic
sys.path.pop(0)
PROVENANCE = json.loads((ROOT / "datasets/classic/provenance.json").read_text())


def entry(item, chance, group=0, reference=None, rolls=1, condition=0):
    return (1, item, chance, group, -reference if reference else 1, rolls, condition)


class ClassicReference(unittest.TestCase):
    def test_literal_parser_handles_escaped_comments_and_rejects_incomplete_values(self):
        self.assertEqual(list(classic.tuples("(1,'a\\'b,c'),(2,'(safe)');")), [["1", "a'b,c"], ["2", "(safe)"]])
        for text in ("(1,'unfinished", "((1))", "(1"):
            with self.assertRaises(ValueError):
                list(classic.tuples(text))

    def test_independent_references_groups_and_repeat_rolls_keep_their_denominators(self):
        compiler = classic.Compiler({10: [entry(100, 25), entry(101, 50)]})
        rows = compiler.compile([entry(100, 20), entry(0, 50, reference=10, rolls=2)])
        self.assertAlmostEqual(rows[100], 1 - .8 * (1 - .5 * (1 - .75**2)))
        self.assertAlmostEqual(rows[101], .5 * (1 - .5**2))
        rows = compiler.compile([entry(100, 40, group=1), entry(101, 0, group=1), entry(102, 0, group=1)])
        self.assertAlmostEqual(rows[100], .4)
        self.assertAlmostEqual(rows[101], .3)
        self.assertAlmostEqual(rows[102], .3)

    def test_unknown_eligibility_overfull_groups_and_cycles_are_not_fabricated(self):
        compiler = classic.Compiler({10: [entry(0, 100, reference=10)]})
        rows = compiler.compile([entry(100, 50, group=1, condition=42), entry(101, 0, group=1),
                                 entry(102, 75, group=2), entry(103, 75, group=2),
                                 entry(104, 100, condition=2), entry(0, 100, reference=10), entry(105, -25)])
        self.assertEqual(rows, {105: .25})
        self.assertEqual(compiler.skipped["conditionalGroupRows"], 2)
        self.assertEqual(compiler.skipped["overfullGroupRows"], 2)
        self.assertEqual(compiler.skipped["conditionalRows"], 1)
        self.assertEqual(compiler.skipped["missingOrCyclicReferences"], 1)

    def test_rebuild_is_identical_and_original_source_and_license_are_included(self):
        source = ROOT / "datasets/classic" / classic.SNAPSHOT
        self.assertEqual(hashlib.sha256(source.read_bytes()).hexdigest(), classic.SHA256)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            classic.build(source, ROOT / "datasets/classic/COPYING", root)
            for relative in ("MSMarketValue/Data/Classic.lua", "MSMarketValue/Data/Classic-NOTICE.txt",
                             "MSMarketValue/Data/Classic-COPYING.txt", "MSMarketValue/Data/Classic-COPYRIGHT.txt",
                             "datasets/classic/COPYRIGHT.md", "datasets/classic/provenance.json"):
                self.assertEqual((root / relative).read_bytes(), (ROOT / relative).read_bytes())
        self.assertLess(PROVENANCE["runtimeBytes"], 900000)

    def test_every_compiled_source_matches_the_real_lua_decoder_with_bounded_memory(self):
        lua = os.environ.get("MSMV_TEST_LUA") or shutil.which("lua5.1")
        if not lua:
            self.skipTest("Supply Lua 5.1 through tools/validate.py")
        data = classic.read_snapshot(ROOT / "datasets/classic" / classic.SNAPSHOT)
        tables = {}
        for name in ("creature_loot_template", "reference_loot_template", "skinning_loot_template"):
            tables[name] = defaultdict(list)
            for row in data[name]:
                tables[name][row[0]].append(row)
        compiler = classic.Compiler(tables["reference_loot_template"], data["item_template"])
        quests = set(data["item_template"])
        for table in tables.values():
            quests.update(r[1] for rows in table.values() for r in rows if r[2] < 0 and r[4] > 0)
        expected = {}
        for npc, loot, skin in data["creature_template"]:
            for kind, identifier, name in (("loot", loot, "creature_loot_template"), ("skinning", skin, "skinning_loot_template")):
                if identifier not in tables[name]:
                    continue
                rows = compiler.compile(tables[name][identifier])
                if not rows:
                    continue
                fingerprint = 0
                for item, probability in sorted(rows.items()):
                    value = max(1, min(classic.SCALE, round(probability * classic.SCALE)))
                    fingerprint = (fingerprint * 131 + item * 17 + value * 2 + (item in quests)) % 2147483647
                expected[kind, npc] = len(rows), fingerprint
        script = ['local A={}',
                  'assert(loadfile("MSMarketValue/Core/Util.lua"))("MSMarketValue",A)',
                  'assert(loadfile("MSMarketValue/Data/LootReference.lua"))("MSMarketValue",A)',
                  'collectgarbage("collect");local before=collectgarbage("count")',
                  'assert(loadfile("MSMarketValue/Data/Classic.lua"))("MSMarketValue",A)',
                  'collectgarbage("collect");local packed=collectgarbage("count")-before;assert(A.LootReference.cachedRows==0)',
                  'local total,longest,maxrows=0,0,0;local R=A.LootReference',
                  'local function Check(id,kind,count,expected) local at=os.clock();local rows=R.Rows(id,kind);longest=math.max(longest,(os.clock()-at)*1000);assert(#rows==count);maxrows=math.max(maxrows,#rows);table.sort(rows,function(a,b)return a.id<b.id end);local h=0;for _,r in ipairs(rows)do assert(not r.samples and r.origin=="classic");h=(h*131+r.id*17+math.floor(r.rate*1000000+.5)*2+(r.questItem and 1 or 0))%2147483647 end;assert(h==expected,id..":"..kind);assert(R.cachedRows<=4096 and #R.order<=8);total=total+#rows end']
        script.extend(f'Check({npc},"{kind}",{count},{fingerprint})' for (kind, npc), (count, fingerprint) in sorted(expected.items()))
        script += [f'assert(total=={PROVENANCE["rates"]})',
                   'collectgarbage("collect");print(string.format("CLASSIC_REFERENCE_BENCHMARK rows=%d packed_kib=%.2f with_cache_kib=%.2f max_source_rows=%d max_decode_ms=%.3f",total,packed,collectgarbage("count")-before,maxrows,longest))',
                   'assert(packed<3000,"Packed baseline exceeded 3 MiB")']
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "classic-test.lua"
            path.write_text("\n".join(script))
            result = subprocess.run([lua, str(path)], cwd=ROOT, check=True, capture_output=True, text=True)
        print(result.stdout.strip(), flush=True)


if __name__ == "__main__":
    unittest.main()
