# Farming and drops

Open `/msmv farm` for the report and display settings, or `/msmv drops` for tooltip options and personal-data resets.

## Drop tooltips

The list shows four items by default, adjustable from 1–10. Needed quest items come first, then expected item value. Quest-only drops are hidden when their quest is absent; normal trade materials remain visible. Item names use their rarity colors.

**Reference data** is the default. Each item uses Forever community counts first, Classic fallback second, and your personal samples last. Classic rows are marked and are unverified for Forever. Counts from different sources are never combined. **Personal drops** shows only your records. Personal collection is on by default in either mode; explicit choices are remembered.

The bundle includes [1,876 Everloot rates](EVERLOOT-DATASET.md) and [Classic coverage for 4,395 creatures](CLASSIC-DATASET.md). It is broader than the earlier pilot but does not cover every Forever creature or change. No separate reference addon is needed; disable older `MSMarketValueReference` pilots.

Personal rates count **corpses checked**, skins or nodes. An item appearing on 3 of 10 corpses shows **30% (3/10)**; a stack is one successful drop. Visible items count when loot opens, even when left behind. A short receipt index prevents normal reopen/partial-loot duplicates, including after reload. Unopened or unreadable loot cannot be counted.

Solo, party and raid samples stay separate in storage and combine for display. Only loot the client exposes can count; hidden group loot and quest eligibility affect these samples. Herbalism, mining and skinning have separate records. Name-only nodes may need one successful harvest before they can be identified.

Reset a creature/node by name or ID, the current zone, current dungeon or all this character's observations. A second click confirms it. Prices, reference data, ledger entries and farming sessions stay intact.

## Session report

| Figure | Meaning |
|---|---|
| Session value | Your acquired gold and current estimated item value. |
| Active time | Online session time, including travel and combat; pauses/loading are excluded. |
| Session average | Session value divided by all active time. Starts after one minute. |
| Recent · 60m | Receipt value over the latest 60 active minutes, or available history. Starts after one minute. |
| Peak farming | Best completed five-minute window, expressed per hour. Quest gold and rewards are excluded. |

The peak saves the zone, available map coordinates and local time of the last farming receipt in that window. The report separates Loot, Quests and Harvesting, with item/source filters, recent pickups and five saved summaries. Reset starts a new session and saves the previous summary.

Recent/peak history uses one-minute buckets and prices known when receipts settle. The oldest partial bucket is prorated. Later AH price changes can revalue the session without creating a historical peak. Unpriced pickups are counted separately and omitted from recent/peak rates; their session item totals can update when data loads. Older sessions keep their totals, with new rate history starting at this update.

## What counts

Your received loot, looted gold, included quest rewards and harvested materials count. Drops won by someone else, purchases, crafted items, mail, trade gold and sale proceeds do not. Wallet increases alone are never farming income. Receipts during mail/trade, or just after closing either, are ignored.

Quest rewards, bound items and poor items use vendor value. Other items can use a fresh saved AH low after the configured AH cut. It must beat vendor value by at least **10%** by default; otherwise vendor value is used. Missing/stale AH data falls back to vendor value. Unpriced items remain visible until their data loads.

Items contribute once; later sales do not add proceeds again. The estimate measures acquired value, not realized profit, and excludes expenses, deposits and unsold stock.

## Display and idle pause

The centered display labels the whole-session rate **Average** and the optional total **Session**. Active figures ease toward changes. Set its width from **240–520 pixels**, lock its position, hide the total or show only on hover. Drag when unlocked; left-click opens the report and right-click pauses/resumes.

Automatic idle pause is on by default at **five minutes**, adjustable from **5–60** or Off. Combat keeps timing active; the inactivity countdown starts when combat ends or from your latest loot. The full grace period counts. At the limit, **Idle** appears and the timer stops. Combat entry, your loot, harvesting or an included quest reward resumes it without adding the idle gap. A manual pause says **Paused** and stays paused until you resume it.

## Storage

Drop counters cap at 3,000 source/area records, 20,000 item counters, 128 areas and 200 items per source/cohort. Recent-corpse protection is bounded. Sessions keep at most 500 item types, 20 recent pickups and five saved summaries. Rate history adds at most **61 minute buckets** per current session.

Reference strings stay packed, with at most eight viewed sources and 4,096 decoded rows shared across both layers. No reference data enters SavedVariables. Results are cached; no uploads or in-game web requests are made.
