# Everloot baseline

Test revision 6 includes the checked Everloot export from Dataset Builder 0.1.3. No separate reference addon is needed. **Reference data** is the default; personal collection stays on and fills missing items with separately labeled rates.

| Loaded into the addon | Rates | Sources/modes |
|---|---:|---:|
| Creature loot | 1,822 | 230 |
| Skinning | 9 | 3 |
| Herbalism | 7 | 3 |
| Mining | 10 | 2 |
| **Total** | **1,848** | **238** |

The typed snapshot is **2026-11-16 00:20 UTC** (November 15 in Eastern time). These are community loot-window samples, not verified server probabilities. Coverage depends on the source catalog and reporting thresholds; an absent drop is unknown, not 0%.

The complete export has 3,875 rows. Its other 2,027 rows lack a loot mode and remain in the review archive; they are never assigned to creature or harvesting tables. The published aggregate feed has its own earlier snapshot date. Those denominators are not combined.

## Size and storage

The runtime adds about **11 KiB of Lua**, including **8,251 bytes of packed counts**. Only viewed sources are decoded; the cache holds at most eight sources and 4,096 rows. No reference data is copied into SavedVariables, and no API requests or uploads happen in game.

The full export and per-source provenance are under `datasets/everloot` in the repository, outside the Clean ZIP. The addon includes its source credit and **CC BY-SA 4.0** data notice in `Data/Everloot-NOTICE.txt`; code licensing is separate.

## Refreshing for a release

1. In Dataset Builder, run **RESOLVE-LOOT-MODES-WITH-KEY.cmd** and keep its `work` folder for resuming. Never include the key or cache with the addon.
2. Check the finished export and coverage report. Keep one immutable dataset ZIP for the release.
3. From the addon repository, run `python3 tools/bundle_everloot.py PATH-TO-DATASET.zip`, then run the normal validation and packaging checks. The bundler verifies hashes, counts and source modes before replacing runtime data.

Personal rates and reset scopes remain independent. Reference rates win when available; missing items or sources use this character's rates and sample counts. Personal mode shows only personal records. Resetting personal history does not change the base dataset.
