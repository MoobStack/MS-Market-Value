# Farming and creature drops

Open `/msmv farm` for the session report and display settings, or `/msmv drops` for creature tooltips and reset options.

## Creature tooltips

The tooltip shows four items by default, adjustable from 1–10. Active quest items come first, then items with the highest expected value. Percentages include a sample count: an item seen on 3 of 10 inspected corpses shows **30% (3/10)**. A stack counts as one successful drop.

Solo, party and raid samples are stored separately and combined for the tooltip. Only loot exposed by the client is counted. Unlooted kills, hidden group loot, quest eligibility and gathering can affect the sample; these numbers are observations, not the server’s configured drop chance.

**Personal observations** works without a database. **Fixed reference data** accepts an optional reference pack, kept separate from your samples. This beta does not bundle a verified Forever drop-rate database. It shows unavailable reference data honestly rather than borrowing Classic rates.

Reset options affect this character’s observations:

- **Creature:** enter the exact name, ignoring case, or its NPC ID.
- **Zone:** clears the current map area.
- **Dungeon:** clears the current dungeon’s recorded floors and difficulties.
- **All:** clears your drop observations.

Resetting requires a second click. It does not clear prices, farming sessions or ledger entries.

## Farming value

The session counts your received loot, looted gold, quest gold and received quest reward items. Visible drops won by somebody else do not become your income. Purchases, mail, crafting and trade transfers stay outside this calculation.

Quest rewards and bound items use vendor value. Other items can use the current saved AH low after the configured AH cut. By default, that net value must beat vendor value by at least **10%**; otherwise vendor value is used. Stale or missing AH data falls back to vendor value. Unpriced items stay visible and are excluded until their data loads.

The estimate values items once when acquired; selling them does not add the proceeds again. Item totals use the current valuation, while Recent pickups keeps the value when received. This is an estimate of acquired value, not realized profit. It excludes deposits, unsold stock and expenses.

The timer includes travel and combat, but excludes offline time, loading screens and manual pauses. The hourly estimate starts after a minute. The small display eases toward changes; report totals remain exact.

Drag the display to move it. Left-click opens the report; right-click pauses or resumes. Farming settings can hide it completely or reveal it only on hover. **Reset session** saves a short summary before starting again.

## Storage and processing

The addon keeps counters, not kill-by-kill logs. A short, capped receipt index prevents recent corpses being counted again after a reload. Drop history stops growing at 3,000 creature/area records or 20,000 item counters, with at most 128 areas and 200 items per creature/cohort. A session keeps at most 500 item types, 20 recent pickups and five earlier summaries. Reset older data when a limit is reached.

Tooltip results and farming totals are cached. Only the latest pair of auction scans is needed for stock movement; no extra daily volume database is created. No data is uploaded.
