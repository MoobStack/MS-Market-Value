# Everloot baseline

The Windows download succeeded. The supplied November 15 export passed its ZIP, row-count and checksum checks.

| Included | Count |
|---|---|
| Source/item rates | 2,027 |
| Creature sources | 230 |
| Object sources | 38 |
| Distinct items | 906 |
| ZIP size | 40,944 bytes, about 40 KiB |

The same normalized records occupy 386,063 bytes before compression. Numeric IDs and repeated fields compress well; no icons, artwork or individual player logs are included. The small archive is valid, but it is **not a complete world loot database**.

## What is still missing

The published feed identifies NPCs and objects but does not separate kills, skinning, herbs, ore and other loot types. Its 2,027 rates therefore have **zero resolved loot modes**. The builder correctly saved the baseline without creating runtime Lua. Assigning those rates to a kill or mining table would mix different sample types.

The original export is included separately in the Complete Package for review. It is not loaded into the addon or copied into SavedVariables. Its `NOTICE.txt` contains Everloot's attribution and CC BY-SA 4.0 data terms. These are community samples, not verified server settings.

## Next collection step

In the separate **Dataset Builder 0.1.1** folder, run **RESOLVE-LOOT-MODES.cmd**. It requests the public records needed to distinguish loot types. Keep `work` to resume an interrupted or rate-limited download.

Check `STATUS.cmd` and `output/last-check.json`. A compatible **Reference.zip** is produced only when the data supports typed rates. If the source refuses the public-records endpoint, keep the existing baseline and share the displayed error or connection report; the aggregate feed alone cannot supply the missing classifications.

## Personal gap filling

From addon test revision 5, **Reference data** keeps each available shared rate and fills missing items or whole sources from this character's personal history. Fallback rows say **personal** and retain their own hits/sample counts. Known personal quest/rarity information can also fill missing item details.

Kill, skinning, herbalism and mining samples stay separate. Quest eligibility and the display limit still apply. Personal mode shows only personal rates. Resetting personal history removes its fallback rows without modifying the reference pack; nothing is uploaded.
