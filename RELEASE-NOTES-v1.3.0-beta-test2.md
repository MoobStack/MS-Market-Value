# MS Market Value 1.3.0 beta — Test revision 2

Same version and build: `1.3.0-beta / 2026-11-15-beta001`.

- Track each item modifier separately, including bonus-based variants. Old item-wide prices stay labeled; they cannot supply a modifier’s price movement.
- Browse 12 Opportunities rows with scrolling, collapsible filters and All items for prices that still need history.
- Fix personal drop collection and creature tooltip identification. Add separate herb, ore and skinning observations.
- Separate Loot, Quests and Harvesting in the farming report. Exclude mail/trade receipts and keep overlapping windows together.
- Add a small optional Wowhead reference pack and an offline importer. These are sampled observations, not verified server rates.

Close WoW, back up SavedVariables and replace the addon folder using the Clean ZIP. Keep your saved data. Complete a new AH scan, then check specific modifiers under All items.

Test a creature, herb/ore node and skinned corpse; compare farming totals before and after mail/trade gold. Include `/msmv diagnostics` with any problem. Reference mode needs the optional pack; the supplied example covers Mudfin Oracle only.
