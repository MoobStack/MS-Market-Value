# MS Market Value 1.2.0 beta

Build `2026-10-20-beta001` · Test revision **2**

- Fix **Price move %** in Resale: the price drop must meet the threshold as well as both profit targets. Set it to 0 to disable that check.
- **Min profit (g)** now accepts decimal gold, including `0.25` for 25s. Existing saved targets keep their value.
- Left-click an item to open its live listings in the native Buy UI. Right-click for target-price details; hover for its tooltip.
- Tidy the filter groups, table, row highlights and details. Input edits survive focus changes, and unchanged Apply reuses the result.

Close WoW, replace the addon folder from the Clean ZIP and keep SavedVariables. The version and build are unchanged; diagnostics identify **Test revision: 2**.

**318/318 local Lua 5.1 tests pass.** Check the revised filters, item/commodity navigation and layout in Forever. All docs, tests and prior tags are included in the full Git repository. This remains a test build for 1.2.0.
