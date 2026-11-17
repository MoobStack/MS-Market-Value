# MS Market Value 1.1.0 beta — Test revision 4

`1.1.0-beta / 2026-10-11-beta001` · `v1.1.0-beta-test4`

Fix the missing **Show profits / Hide profits** button reported in Tailoring. Forever draws the native title and border above the recipe page; the previous button remained underneath them. The button now follows the actual header level, sits beside the profession close button and hides with the crafting page. It works with **Auto-open crafting profits** disabled. `/msmv craft` also opens the window for the open profession.

Diagnostics now include toggle visibility, its level/strata, native header levels and the crafting-window state. If the button remains missing, copy `/msmv diagnostics` while Tailoring is open.

**238/238 local Lua 5.1 tests pass**, including the header regression that fails against revision 3. The button still needs a native visual check. Daily history, retention, both recipe filters, linked quotes and the scanner are retained; the user reports successful revision 2 resumes. Native history rollover/saving and Forever DE outcomes remain unverified.

Close WoW, replace the addon folder using the Clean ZIP and keep WTF/SavedVariables. Confirm **Test revision: 4**. Use [LIVE-TEST-CHECKLIST.md](../../LIVE-TEST-CHECKLIST.md) for the live checks. The Documentation ZIP contains the updated guide and changelog; the Complete Package also includes source and Git recovery files.

The beta version/build are unchanged. This is a testing package, not the official 1.1.0 release; it has not been pushed or published to GitHub.
