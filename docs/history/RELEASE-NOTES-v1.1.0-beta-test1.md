# MS Market Value 1.1.0 beta — Test revision 1

Version `1.1.0-beta` · Build `2026-10-11-beta001` · Tag `v1.1.0-beta-test1`

- Added material costs, sale value, gross profit or loss, and return percentage for selected learned recipes.
- Added a profitable-recipe view for the open profession, sortable by profit per craft or return percentage.
- Added copyable craft quotes with saved markup. Service recipes can show material quotes without an auctionable output.
- Restored public tooltip prices during combat, including actual stack totals where quantity is available.
- Added pause/resume for incomplete scans. Resume uses the existing request and retains accepted rows, missing-data retries and the server cooldown.
- Updated the user guide, changelog, upgrade notes and live checklist.

Missing material prices prevent full estimates. Profit is before fees; variable output uses its minimum yield for ranking. Unresolved reagent variants and unsupported recipe shapes stay unavailable.

Paused work lasts for the current game session while the native buffer remains available. Reloading or quitting ends that unfinished scan. Completed prices and settings remain saved.

This is the first test package for the crafting feature and fixes. **Price history follows in another test revision of the same version and build.** The official 1.1.0 release is not yet published.

Install the Clean ZIP with WoW closed and preserve WTF/SavedVariables. Confirm **Test revision: 1** in diagnostics, then test an item recipe, a service recipe, combat hovers, and pause/resume. Local Lua 5.1 checks pass; native verification is pending.
