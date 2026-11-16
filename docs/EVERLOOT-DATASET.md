# Everloot baseline

Test revision 7 includes the checked export from Dataset Builder **0.1.4**, with typed snapshot **2026-11-16 02:40 UTC** (November 15 in Eastern time). These are Forever community samples, not verified server probabilities.

| Loaded data | Rates | Sources/modes |
|---|---:|---:|
| Creature loot | 1,850 | 235 |
| Skinning | 9 | 3 |
| Herbalism | 7 | 3 |
| Mining | 10 | 2 |
| **Total** | **1,876** | **243** |

Skinning creatures overlap the 235 creature IDs. Gathering covers five nodes. The complete normalized export contains 3,940 rows; its 2,064 unclassified rows stay in the review archive. Modes and denominators are not guessed or combined. Coverage depends on available reports and the source's thresholds.

The runtime module is about **11 KiB**, including **8,381 bytes** of packed counts. Only viewed sources decode, sharing an eight-source / 4,096-row cache with Classic fallback. Nothing is copied into SavedVariables or downloaded in game.

The immutable export and provenance are in `datasets/everloot`. The install includes source credit and the **CC BY-SA 4.0** data notice in `Data/Everloot-NOTICE.txt`; these terms are separate from addon code.

## Update the bundled data

1. In Dataset Builder, run **RESOLVE-LOOT-MODES-WITH-KEY.cmd**. Keep its work folder for resuming; keep API keys outside addon packages.
2. Use the completed normalized **Dataset ZIP**, not the separate reference-addon ZIP. Review its coverage report.
3. From the full addon repository, run `python3 tools/bundle_everloot.py PATH-TO-DATASET.zip`, then the normal validation and packaging checks. The bundler checks hashes, counts and source modes before replacing runtime data.

This updates the primary layer and retains Classic fallback and personal records. Switch to Personal drops to use your records alone. Resetting personal history never changes either bundled layer.
