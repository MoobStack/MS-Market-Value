# Reference drop data

The beta includes two reference layers. No extra addon is required; disable older `MSMarketValueReference` pilots.

| Priority | Source | Coverage |
|---|---|---|
| 1 | Forever community samples from Everloot | 1,876 mode-resolved rates; 235 creatures and five gathering nodes. |
| 2 | ClassicDB nominal base chances | 4,395 creatures, with corpse loot and/or skinning. Unverified for Forever. |
| 3 | This character's personal drops | Missing items and sources you have inspected locally. |

Matching items use the highest available layer. Counts stay separate, and Classic rates never receive invented sample sizes. Personal-only mode ignores the reference layers while collection continues by default. Missing data remains unknown.

The [Everloot guide](EVERLOOT-DATASET.md) explains updates from Dataset Builder. The [Classic guide](CLASSIC-DATASET.md) explains coverage, source hashes and offline rebuilding. Full exports, provenance and licenses stay in the repository; only packed runtime data and required notices enter the Clean ZIP.

## Other packs

The [Wowhead guide](WOWHEAD-DATASET.md) covers saved Forever pages and the offline importer. Keep each source's origin, date and sample size. Wowhead Forever pages may include Classic Era fallback data, so a page URL alone does not establish Forever-specific rates.

External packs can replace the primary provider. The bundled Classic layer remains available for gaps, followed by personal samples. Use one external provider at a time and review its source/coverage before bundling.

All reference data stays out of SavedVariables. Only queried sources are decoded; the shared cache caps at eight packed sources and 4,096 rows. Names and icons come from the client. No data is downloaded in game.
