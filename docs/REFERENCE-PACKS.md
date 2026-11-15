# Reference observations

Wowhead has a [Forever database](https://www.wowhead.com/forever/npc=258573/mudfin-oracle) with collected drop counts. Those counts are useful reference samples, not the server’s configured drop chances. Some data may carry over from Classic. Always keep the source and sample size visible.

The optional Mudfin Oracle pack in this test package covers **NPC 258573 only**, with 132 item rows. Extract its `MSMarketValueReference` folder beside `MSMarketValue`, reload, then choose **Reference observations** under `/msmv drops`. Other sources remain unavailable until a pack includes them. Personal observations continue independently.

## Build a pack

Use Python 3 and the full source repository. Save the desired Wowhead **Forever** NPC/object pages as HTML. Create a JSON manifest beside those files:

```json
[
  {
    "id": 258573,
    "kind": "loot",
    "file": "mudfin.html",
    "url": "https://www.wowhead.com/forever/npc=258573/mudfin-oracle"
  }
]
```

```bash
python3 tools/import_reference.py manifest.json --output export/MSMarketValueReference
```

Use `loot` or `skinning` for NPC pages, and `herbalism` or `mining` for object pages. All desired sources go in one manifest. The importer reads embedded table data without running page scripts or making network requests. Missing tables or mismatched IDs stop the import.

By default, item rows need at least 50 recorded samples; change this with `--min-samples`. The pack keeps sample counts, source links, import date and input hashes. It is capped at 256 sources, 200 item rows per source and 20,000 rows overall. Smaller packs use less memory. Missing or omitted entries are unknown, not 0% drops.

Install one reference pack at a time. The base addon does not download, upload or duplicate its database into SavedVariables. Verified server rates remain unavailable unless a trustworthy Forever source publishes them.
