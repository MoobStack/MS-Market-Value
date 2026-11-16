# MS Market Value 1.3.0 beta — Test revision 7

Same testing version and build: `1.3.0-beta / 2026-11-15-beta001`.

- Add Classic fallback coverage for 4,395 creatures. Forever community rates take priority; personal drops fill remaining gaps. Classic rows are marked as unverified for Forever.
- Center the farming display, add space between labels and amounts, and add width and position-lock settings.
- Reorganize the session report around session value, active time, session average, recent rate and a located five-minute farming peak. Quest rewards cannot set the peak.
- Resume idle sessions on combat entry or your own loot. Keep time active during combat and restart the idle countdown afterward. Manual pauses stay paused.
- Keep reference data packed and recent rate history bounded. Existing saved data carries forward.

Close WoW, replace the addon folder using the Clean ZIP and keep SavedVariables. Disable older reference pilots. `/msmv diagnostics` should show **Test revision: 7**.

Check the display at your normal UI scale, change its width/lock, let it idle, then resume by combat and by looting. Compare session/recent rates after a longer session and confirm a large quest reward leaves the farming peak unchanged. Hover Elder Mottled Boar to check the new Classic fallback.

This is a test build; no official 1.3 release has been published.
