# MS Market Value 1.1.0 beta — Test revision 3

`1.1.0-beta / 2026-10-11-beta001` · `v1.1.0-beta-test3`

Price history is now collected: keep 1–30 UTC calendar days, with each day's latest completed scan replacing that entry. Tooltips show the average of the days with a price, between vendor and recent AH values. One day is enough. The latest existing saved scan is imported on upgrade when it is within retention; earlier scans cannot be recovered.

The profession title-bar button now toggles Show profits / Hide profits and sits above Forever's crafting page. Auto-open is optional and off by default. Configure it and history length in **/msmv → Crafting & history**.

**Recipe list → Show all recipes** includes losses, break-even recipes and unavailable estimates. **Profitable only** restores the original filter. Unknown values sort last and remain unavailable. Both list modes keep the last complete results during a refresh.

The user reports successful revision 2 scan resumes under multiple conditions. This revision preserves that scanner, linked quotes, combat prices and existing settings. **227/227 local Lua 5.1 tests pass**; new UI fit, daily rollover and native saving still need checks. DE loot remains an unverified Classic reference.

Close WoW, install the Clean ZIP and keep WTF/SavedVariables. Follow [LIVE-TEST-CHECKLIST.md](LIVE-TEST-CHECKLIST.md). The Documentation ZIP has the updated guide and changelog; Source/Repository ZIPs and the bundle retain all code and Git history.

This remains a testing prerelease. The beta version and build are unchanged; official 1.1.0 publication follows live verification. No remote publication is claimed.
