# MS Market Value 1.1.0 beta — Test revision 1

`1.1.0-beta / 2026-10-11-beta001` · `v1.1.0-beta-test1`

This test package adds selected-recipe crafting costs, sale value, gross profit or loss, percentage return, a profitable-recipe list, and copyable markup quotes. The profession window uses native Blizzard frames and controls. Services can receive material quotes without an auctionable output.

Tooltip prices remain visible during combat. Incomplete auction scans can be paused and resumed within the current session without another full-scan request. Completed prices stay usable until the new scan finishes; the existing server cooldown is preserved.

Price history follows in another test revision of the same version and build. This package does not collect history, and the official 1.1.0 release is not yet ready for publication.

Install the Clean ZIP with WoW closed and preserve WTF/SavedVariables. Existing 1.0.0 schema-1 prices/settings carry forward. Confirm **Test revision: 1** in diagnostics and follow the live checklist.

Crafting uses the latest completed scan's asking prices before fees. Missing prices or unresolved reagent choices stay unavailable. Resume requires the current session's original buffer; unfinished work ends on reload/logout. DE loot remains a labeled Classic reference, unverified for Forever.

If distributed on GitHub for testing, mark this as a **prerelease**. The Source ZIP includes all updated documentation; Repository ZIP and bundle preserve the full Git history. No remote publication is claimed by these local packages.
