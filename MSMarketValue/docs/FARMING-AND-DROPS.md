# Farming and drops

## Farming sessions

Open `/msmv farm` for the report and display settings.

| Figure | Meaning |
|---|---|
| Session value | Acquired gold and current estimated item value |
| Active time | Time after a start trigger, excluding idle, pauses and loading |
| Hourly average | Eligible farming value divided by active time; quest rewards are optional |
| Recent 60m | Receipt value over the latest 60 active minutes, or available coverage |
| Peak farming | Best completed five-minute window, expressed per hour, with quests excluded |

The peak saves its zone, available coordinates and time. The report separates loot, quests and harvesting, with item/source filters and recent pickups. Use the session menu to choose saved sessions by date, duration and value. Current session returns to the live report. Scroll Items or Recent pickups with the mouse wheel or scrollbar. Columns show quantity, unit value and total; hover a row for item or receipt details.

**Manage** controls the saved-session limit for this character and market: five by default, adjustable from 0–50. Reset saves the finished session and starts a new one, replacing the oldest save when the limit is reached. A limit of 0 stops saving. Delete selected removes one saved session; reducing the limit removes the oldest saves. Both removals require confirmation and leave the current session intact.

New saves retain all tracked item rows, up to the existing 500-item limit, and the last 20 receipts. Earlier saves contain only their original top ten items; those missing details cannot be restored. Their totals and rates remain available.

In Farming settings, Quest rewards defaults to **Session total only**. Choose **Session total and hourly rates** to include rewards in the display average and recent rate, or **Do not record new quest rewards** to stop adding them. Peaks always exclude quest gold and items. These choices do not erase previously recorded rewards.

The display can be resized, locked, shown only on hover or reduced to the hourly average. Drag it when unlocked; left-click opens the report and right-click pauses or resumes.

The calculator starts idle after login. Click Resume, enter combat or receive loot to start timing. **Pause on death** is on by default and can be switched off in Farming settings. With it on, death and ghost time are excluded; resurrection alone leaves the calculator idle until the next trigger or Resume.

Inactivity pause defaults to five minutes. Choose 5–60 minutes or Off. Combat keeps time active. A manual pause stays paused through combat, loot and death until you resume it. Quest rewards can still add to an idle session total, but do not start its timer. Offline and loading time are excluded.

Quest rewards, bound items and poor items use vendor value. Other items can use a fresh AH estimate after the AH cut when it beats vendor value by your threshold, 10% by default. Unpriced items are counted separately. Purchases, mail, trades and sale proceeds are excluded; later sales do not add the item again. Native window closure and world transitions recover stale transaction state. Quest classification ends after turn-in, combat or real world loot, so a missing quest-close event cannot classify an entire login as quest rewards.

## Drop display

Open `/msmv drops`. Sort by rate high to low, rate low to high, or expected item value. Expected value ranks drop chance times one item's saved AH low, or vendor value when no AH price is available; it does not include stack size.

Choose any of six colored rarities. Needed quest drops stay visible and first even when their rarity is unchecked. With no rarities selected, only needed quest drops remain. Filtering happens before the 1–10-item limit. Unknown rarity stays visible with All selected. Sort and rarity changes apply immediately; press Apply after editing Max items.

Reference mode uses bundled entries and automatically fills missing items or sources from your personal observations. Each keeps its own rate and sample count. Choose Personal drops to see only your own records, including your rate for an already referenced item. Collection can remain enabled in either mode.

Personal rates count inspected corpses, skins or nodes. An item on three of ten corpses shows 30% (3/10); a stack counts as one successful drop. Visible items count even when left behind. Reliably identified empty corpses also count as inspections, lowering the rate when no item dropped. Reopening the same body does not count twice. Hovering, unseen kills and ambiguous sources do not count. Current-area records and harvesting types stay separate. Custom drop sections are hidden while loot is open, then restored on the next tooltip refresh. Quest-only drops are hidden when their quest is absent.

Reset by creature/node, zone, dungeon or all this character's observations. This does not erase reference rates, prices, ledger entries or farming sessions. Reference chances can differ from Forever and are not guaranteed outcomes.

## Upgrading from 1.3.0

Session totals, time and personal observations are kept. Upgrading from 1.3.0 starts recent-rate and peak coverage fresh because older receipts may include misclassified quest rewards. Moving between 1.3.1 test builds keeps the newer rate history. Older saved summaries keep totals and averages, but unverifiable recent rates and peaks show Not recorded. Start a new session for a clean whole-session comparison. Previously missed empty bodies cannot be reconstructed; only new inspections adjust personal rates.
