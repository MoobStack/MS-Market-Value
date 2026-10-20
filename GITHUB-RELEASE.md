# MS Market Value 1.2.0 beta

Build `2026-10-20-beta001` · Test revision **8**

- Add one running loot-income total per local day, kept across reloads.
- Track personal repairs, training, respecs, postage, flights, mailed gold and other spending. Unrecognized wallet deductions appear as **Unclassified**.
- Add **Loot** and **Other** filters. Other has category checkboxes; switching filters removes that restriction, and All includes everything.
- Add expense categories to the editor and CSV. Include loot and Other in the period report, with separate tracking options.

Existing data and settings carry forward. Loot and expense history starts after installing this revision. AH deposits remain outside generic expense detection; unusual combined or unavailable native data may need manual review.

**582/582 local Lua 5.1 tests pass.** Live loot, repair/service events and the revised menus still need a Forever check. Close WoW, replace the addon folder using the Clean ZIP and keep SavedVariables. All documentation and earlier tags are included in the full repository.
