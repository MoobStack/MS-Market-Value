# Reference drop data

Wowhead’s Forever pages contain collected counts and can include **Classic Era fallback rates**. These are reference samples, not verified server settings. Keep their origin, date and sample size with every import.

Test revision 6 bundles **1,848 Everloot rates in 238 sources/modes**. Reference data is the default and personal collection remains on. No extra addon is needed; disable any older `MSMarketValueReference` pilot so it does not replace the bundled data. Missing items use personal rates with separate sample counts.

The [Everloot guide](EVERLOOT-DATASET.md) lists coverage and the release-update process. Only mode-resolved samples are loaded; unclassified rows stay in the source archive. External packs can still replace the reference provider, without changing personal samples.

For exact download, save and build steps, use [Get a Wowhead reference dataset](WOWHEAD-DATASET.md). The starter ZIP includes a ready manifest and Windows build button; the full repository has the same files.

## Building broader coverage

1. Obtain a reusable Forever export/feed, or curate saved Forever NPC/object pages. Check IDs against the client. A complete collection has not been acquired for this beta.
2. Keep Forever samples, Classic fallback and unknown origins distinct. Prefer a matching Forever sample when available; do not average the two sources together. The importer defaults to mixed/unspecified because a URL alone cannot prove the origin.
3. Compile offline using item IDs, hits and sample totals. Keep all valid rare rows; use `--min-samples 1` when retaining every available sample. Missing data remains unknown.
4. Bundle a versioned snapshot. Keep source links and hashes outside the runtime, use the game’s item names/icons, and update the pack with addon releases.

The current compiler packs numeric records and shares repeated sample totals. Only the hovered source is decoded. The cache holds at most eight sources and 4,096 rows, and the data is not copied into SavedVariables. This avoids a large Lua table for every item across the whole world.

## Build from saved pages

Use Python 3 and the full source repository. Save the desired **Forever** pages as HTML and create a manifest beside them:

```json
[
  {
    "id": 258573,
    "kind": "loot",
    "file": "mudfin.html",
    "url": "https://www.wowhead.com/forever/npc=258573/mudfin-oracle",
    "origin": "mixed-or-unspecified"
  }
]
```

```bash
python3 tools/import_reference.py manifest.json --output export/MSMarketValueReference --min-samples 1
```

Kinds are `loot`, `skinning`, `herbalism` and `mining`; herbs/ore use object pages. Reviewed origins can be `forever` or `classic`. Use one pack at a time. Existing readable packs still work.

The default threshold is 50 samples; lowering it retains smaller samples, whose percentages need caution. Input checks allow up to 65,536 sources, 4,096 rows per source and 2,000,000 rows overall. Oversized sources, duplicate modes and mismatched IDs require review rather than silent truncation. The importer reads embedded tables without running page scripts or making network requests.
