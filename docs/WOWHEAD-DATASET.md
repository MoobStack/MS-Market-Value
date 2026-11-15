# Get a Wowhead reference dataset

The supplied pilot covers **Mudfin Oracle only: 132 item rows**. A full-world dataset has not been built. The starter package and the full repository contain the same offline importer; no scraping service or in-game downloader is required.

## First import on Windows

1. Install Python 3 if needed. In PowerShell, run `py -3 --version` to check it is available. Extract the starter ZIP, or use the full repository folder.
2. Open [Mudfin Oracle on Wowhead Forever](https://www.wowhead.com/forever/npc=258573/mudfin-oracle). Check its Drops tab. In Chrome/Edge, press **Ctrl+U** to view the page source, then **Ctrl+S**. Save it as `examples/reference-input/mudfin-oracle.html` inside the extracted folder. Keep the HTML source, not a screenshot or the table copied into a spreadsheet.
3. Double-click **BUILD-REFERENCE.cmd**. It uses the supplied manifest and keeps every valid row with at least one sample. The printed result gives source and item-row counts.
4. Close WoW. Copy the generated `output/MSMarketValueReference` folder into `Interface/AddOns`, beside `MSMarketValue`. Enable both addons, then choose **Reference data** under `/msmv drops`.

Or open PowerShell in the extracted folder and run:

```powershell
py -3 .\tools\import_reference.py .\examples\reference-input\manifest.json --output .\output\MSMarketValueReference --min-samples 1
```

On macOS/Linux, use `python3` with the same arguments and forward slashes.

## Add more creatures and gathering nodes

Find sources in [Forever NPCs](https://www.wowhead.com/forever/npcs) and [Forever Objects](https://www.wowhead.com/forever/objects). Save each individual source page beside the first HTML file. Add one entry to `examples/reference-input/manifest.json` for each source and loot type, separated by commas. Its numeric ID must match the number after `npc=` or `object=` in the URL.

```json
[
  {
    "id": 258573,
    "kind": "loot",
    "file": "mudfin-oracle.html",
    "url": "https://www.wowhead.com/forever/npc=258573/mudfin-oracle",
    "origin": "mixed-or-unspecified"
  }
]
```

| What to collect | Page | `kind` | Required table |
|---|---|---|---|
| Creature drops | NPC | `loot` | Drops |
| Skinning | NPC | `skinning` | Skinning |
| Herbs | Object | `herbalism` | Contains |
| Ore | Object | `mining` | Contains |

Rebuild **one combined pack** after adding sources. Rebuilding replaces the generated files; keep the manifest and saved pages to reproduce it. Put collection files outside AddOns. The generated folder contains source URLs, import dates and input hashes in `SOURCES.json`, which is not loaded in game.

Start with the zones and dungeons players use, then add coverage. For a world-wide collection, seek a reusable export from Wowhead or another documented source instead of relying on manual saves for every creature. The current tool compiles saved pages; it does not acquire a complete database automatically. No bulk export has been verified for this beta.

## What the rates mean

Wowhead [documents Classic Era fallback on Forever pages](https://www.wowhead.com/latest-dev-updates): entries marked **Classic Era** use Classic samples until Forever samples replace them. These percentages are collected observations, not the server's configured chances.

Keep `origin` as `mixed-or-unspecified` for mixed or unreviewed pages. Use `forever` or `classic` only when the entire imported source has that reviewed origin. Do not label a whole page Forever just because of its URL. Personal observations remain separate from the reference pack.

The importer preserves hits and sample totals, including rare rates, rather than rounding to whole percentages. `--min-samples 1` retains small samples too; raise it when you want stronger evidence. An absent item or source means unknown, not a zero drop chance.

## If an import stops

- **File missing:** check the HTML filename and folder against `file` in the manifest. Windows may have added `.txt` or `.html` twice.
- **Canonical URL mismatch:** save the individual Forever page, not Classic, a search result or an error page.
- **Loot table not found:** check that the required table exists. In the saved source, search for `new Listview` and `drops`, `skinning` or `contains`. A login/challenge page or a changed page format cannot supply the data.
- **No qualifying rows:** check the printed error and sample threshold. Do not invent rates for missing samples.

Only packed numeric records load in game. Names and colors come from the client; the bounded decoder cache holds at most eight sources and 4,096 rows. See [reference format and limits](REFERENCE-PACKS.md).
