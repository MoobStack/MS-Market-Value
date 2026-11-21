# Farming and drops

## Session figures

Open `/msmv farm` for the report and display settings.

| Figure | Meaning |
|---|---|
| Session value | Acquired gold plus current estimated item value |
| Active time | Time after a start trigger, excluding idle, pauses and loading |
| Hourly average | Eligible value divided by active time; quest rewards are optional |
| Recent 60m | Receipt value over the latest 60 active minutes, or available coverage |
| Peak farming | Best completed five-minute window, expressed per hour, excluding quests |

The peak saves its zone, available coordinates and time. Loot, quests and harvesting have separate totals. Scroll **Items** or **Recent pickups** with the mouse wheel or scrollbar; use the source filter to narrow the list.

Select past sessions from the dated menu. **Current session** returns to the live report. **Manage** keeps 0–50 saves per character and market, five by default, or deletes the selected save. Reset archives the session and starts another, replacing the oldest at the limit. A limit of 0 stops archiving. Deleting saves or reducing their limit requires confirmation.

New saves retain up to 500 tracked item rows and the last 20 receipts. Older summaries keep their original top ten items; missing details cannot be recovered.

## Timing and valuation

Timing starts idle after login. Resume, combat or received loot starts it. **Pause on death** is enabled by default; death/ghost time is excluded and resurrection alone leaves it idle. Inactivity pause defaults to five minutes, adjustable from 5–60 minutes or Off. Combat keeps time active. Manual pauses stay paused until you resume them. Offline and loading time are excluded.

**Quest rewards** defaults to Session total only. You can include new rewards in hourly rates or stop recording them. Peaks always exclude quest gold and items. Quest rewards do not start an idle timer, and changing this option does not erase earlier rewards.

Quest rewards, bound items and poor items use vendor value. Other items can use the average from **Price settings** after the AH cut if the scan is fresh and the estimate beats vendor value by the chosen threshold, 10% by default. Unpriced items are counted separately. Purchases, mail, trades and sale proceeds are excluded. Later sales do not add the item again.

Resize or lock the small display in Farming settings. Drag it when unlocked; left-click opens the report and right-click pauses or resumes. Session total and hover-only display are optional.

## Drop display

Open `/msmv drops`. Sort by chance high to low, chance low to high, or **Expected item value**. Expected value multiplies drop chance by the selected AH average for one item, using vendor value if the average is unavailable.

Choose any of six rarities. Needed quest drops stay visible and first, even when their rarity is unchecked. With no rarities selected, only needed quest drops remain. Filtering happens before the 1–10-item limit; unknown rarity stays visible with All selected. Sort and rarity apply immediately; press Apply after editing Max items.

**Reference data** fills missing items or sources from personal observations, keeping each rate and sample count separate. **Personal drops** shows only your own records. Collection can stay enabled in either mode.

Personal rates count inspected corpses, skins or nodes. An item on three of ten corpses shows 30% (3/10); a stack counts as one successful drop. Visible items count even if left behind. Reliably identified empty corpses count once; reopening does not add a sample. Unseen kills, unopened corpses and ambiguous sources do not count. Harvesting types and current-area records stay separate.

Custom drop sections hide during looting to prevent overlap. Quest-only drops hide when the quest is absent. Reset personal observations by creature/node, current zone, dungeon or character without erasing reference data or other addon records. Reference chances may differ in Forever.

For older session data and rate coverage, see [Updating](../UPGRADE.md).
