# MS Market Value 1.3.1-beta — Test revision 2

Build `2026-11-16-beta001`. This remains a test build for 1.3.1.

## Changes

- Add session management: keep 0–50 saves per character and market, five by default. Delete one selected save or confirm a lower limit to remove the oldest. The current session is kept.
- Save the full tracked item breakdown and the last 20 receipts in new sessions. Older summaries retain their existing top ten items.
- Give the session report more list space, twelve visible rows, aligned quantity/unit/total columns, item hover details and native scrolling. All totals, rates, source filters and recent pickups remain.
- Replace crafting recipe pagination with mouse-wheel and scrollbar navigation. Show eleven rows, retain search/sorting/filtering and select the recipe actually under the cursor.
- Start the calculator idle at login until Resume, combat or received loot. Quest rewards alone do not start timing.
- Add Pause on death, on by default. Death and ghost time are excluded; resurrection leaves it idle until a trigger. Manual pauses stay manual.

The fixes from test revision 1 remain included: empty-corpse samples, quest reward reconciliation and hourly choices, vendor receipt exclusion and clean skinning tooltips.

## Install and check

Close WoW, back up SavedVariables and replace the MSMarketValue folder using the Clean ZIP. Keep SavedVariables. Diagnostics should show test revision 2. Updating from test revision 1 keeps rates, records and observations; no sessions are removed by the update.

1. Log in and wait without combat or loot: active time must stay fixed. Resume manually, then repeat after relogging with combat and with received loot.
2. Die and release: time must stay fixed while dead, as a ghost and after resurrection. Combat, received loot or Resume should restart it. Try disabling Pause on death, and verify that a manual pause never resumes itself.
3. Open Session → Manage. Try a higher limit, a lower limit and 0. Removals must ask for confirmation. Delete a selected save and check that other saves and the current session remain.
4. Reset a session with more than ten item types, select the saved session, and scroll to its final item. Check source filtering, quantity/value columns, Recent pickups and Current session.
5. In a profession with more than eleven recipes, scroll to the end, search, sort and change the profitable/all filter. Click a recipe after scrolling; the matching native recipe should open.

Older summaries cannot recover item rows they never stored. New saves keep up to 500 item rows and 20 recent receipts. In-game event timing, mouse behavior and frame appearance still need confirmation; include diagnostics and reproduction steps for any failure.
