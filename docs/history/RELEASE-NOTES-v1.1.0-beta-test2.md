# MS Market Value 1.1.0 beta — Test revision 2

`1.1.0-beta / 2026-10-11-beta001` · `v1.1.0-beta-test2`

This revision fixes the reported AH reopen/resume failure, changing recipe list and long quote wording. The version and build stay the same; diagnostics identify **Test revision: 2**.

Auction rows are copied locally. Keep the AH open until **Local copy** is complete; then close/reopen and resume without another server request. Pause stops pricing while unread rows continue copying. If the buffer is lost too early, progress stays paused and a fresh restart waits for the original cooldown. Only a completed scan replaces prices.

Quotes read `Recipe - price ea`, with the native recipe link when available. **Insert in chat** opens a draft for the player to send. Fixed multi-item outputs quote per item; variable/unknown yields stay per craft. Profitable recipes now remain visible until a complete refresh is ready, without restarting on unrelated item data.

Crafting costs, gross profit/loss, return percentage, combat tooltip prices and existing saved settings remain available. **169/169 local Lua 5.1 checks pass**; native UI, link rendering and scan recovery still need testing. DE loot remains an unverified Classic reference.

Install the Clean ZIP with WoW closed and keep WTF/SavedVariables. Follow [LIVE-TEST-CHECKLIST.md](../../LIVE-TEST-CHECKLIST.md). The Documentation ZIP contains the updated guide and changelog; Source/Repository ZIPs and the bundle retain code and history.

Price history comes next. This is a testing prerelease, not the official 1.1.0 release. No remote publication is claimed.
