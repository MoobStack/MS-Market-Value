# Classic fallback

The bundled ClassicDB snapshot covers **4,395 creatures**: 4,289 with corpse loot and 924 with skinning; some have both. It includes Elder Mottled Boar. There are **1,284,783 creature/item/mode chances**, including shared world-drop tables. This is not a count of unique items.

These are historical **Classic 1.12 nominal base chances**, unverified for Forever. Forever-specific IDs, changed loot and newer creatures may differ or be absent. Herb and mining reference data still comes from Everloot.

For each item, the addon prefers Forever community counts, then Classic, then your personal samples. Classic rows say **Classic** and have no invented sample count. Personal-only mode ignores both reference layers.

## Size and rules

The runtime module is about **821 KiB**. Shared item lists and chances stay packed; only a viewed source is decoded. The shared cache holds at most eight sources and 4,096 rows. Nothing is copied into SavedVariables.

The offline compiler expands shared tables, exclusive groups and repeated rolls. It omits conditions and overfull groups it cannot safely interpret. Rates are rounded to 0.000001 percentage point; eligibility, duplicate prevention and server multipliers can change actual outcomes. The source counts and omissions are recorded in `datasets/classic/provenance.json`.

## Rebuild

From the full repository, with Python 3:

```bash
python3 tools/bundle_classic.py datasets/classic/ClassicDB_1_12_1_z2815.sql.gz datasets/classic/COPYING
python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

The compiler accepts the pinned snapshot's SHA-256 only and makes no network requests. Updating to another snapshot requires reviewing its schema and loot rules, then changing the pin and tests. This full snapshot does not include every later ClassicDB update.

Derived from [CMaNGOS ClassicDB](https://github.com/cmangos/classic-db/tree/e4825cf48176edff313d78de66b0beb14371c8eb), under GPL-3.0. The full source snapshot, license and rebuild utility are included in the repository. The install includes the data notice and full license under `Data/Classic-*`.
