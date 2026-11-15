# MS Market Value 1.3.0 beta — Test revision 1

Build `2026-11-15-beta001`. This version and build stay fixed during testing.

- Opportunities keeps full item modifiers and links. Add keyword, quantity and stock-decline filters, plus the cost of buying every unit at the market low.
- Creature tooltips show a short, quest-prioritized list from inspected loot. Personal observations include visible party/raid loot and support creature, zone, dungeon and full resets.
- Farming tracks your loot and quest rewards, with a movable hourly estimate, vendor/AH threshold, session breakdown and pause/reset.
- Storage is capped; no raw kill log or large reference database is bundled. Fixed-reference mode needs a separate data source.

Close WoW, back up SavedVariables and replace only the addon folder with the Clean ZIP. Complete a fresh AH scan for the quantity fields. Use `/msmv farm` and `/msmv drops`.

Test a named green, a normal creature and a party/raid loot session, then send `/msmv diagnostics`. Check that quest rewards count once, and reset only a small sample while testing.
