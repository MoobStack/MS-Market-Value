# Test revision 4: live checks

Test `1.1.0-beta / 2026-10-11-beta001`, **Test revision 4**, in Forever. Revision 2 resume tests were reported successful under multiple conditions. Local fixtures do not establish native appearance or disk saving.

## Install and controls

- [ ] Close WoW, replace the addon with the Clean ZIP, preserve WTF, and restart. Confirm Test revision: 4, Interface 16001 and the expected market in `/msmv diagnostics`.
- [ ] Verify existing completed prices, markup, tooltip preferences and DE exclusions.
- [ ] Open a profession. The profit window starts closed; **Show profits** is visible beside the native close button, clear of the title and equipment. Test Tailoring first with auto-open disabled, then another profession. Click it to open, then **Hide profits** to close. Recipe changes must not reopen it.
- [ ] In **/msmv → Crafting & history**, enable Auto-open crafting profits. Close/reopen the profession: the window opens. Close it manually; it stays closed until requested or the next profession session. Disable the setting and repeat.
- [ ] With auto-open off, try `/msmv craft` before choosing a recipe. Close it, then reopen it with Show profits. Switch to the profession overview: both the toggle and profit window hide. Return to a profession and repeat.
- [ ] Check the settings category buttons, long labels, title-bar button, dragging, Escape and UI scales. If the toggle is missing, capture `/msmv diagnostics` while Tailoring remains open, including Crafting toggle and Profession header levels.

## History and retention

- [ ] Confirm history length defaults to 30 and accepts 1–30 days; 0 and values above 30 are rejected. Apply/Enter saves the input; Escape restores it.
- [ ] Check imported history against the last saved complete scan, if it falls within retention. Diagnostics shows UTC dates and retained daily scan count. A one-day average is valid.
- [ ] Complete a scan and hover a priced item. The order is Vendor sell, Historic avg (N days), AH low, then applicable DE expected. Each/Stack totals must match real quantities.
- [ ] Complete another permitted scan on the same UTC day. The daily scan count stays unchanged and that day's prices are replaced. An item missing from the final scan loses that day's sample.
- [ ] After the next UTC day, complete a scan at another price. Check `(daily price 1 + daily price 2) / 2` and the displayed two-day count. Days without a buyout must not add zero samples.
- [ ] With at least two stored UTC days, set retention to 1. Older history disappears immediately; current prices remain. Return to 30: deleted days do not return.
- [ ] Verify automatic pruning when a stored day expires, without needing a new scan.
- [ ] Disable the average under Tooltips: it disappears but collection continues. Re-enable it.
- [ ] Check a matching random suffix and an item-wide fallback. Different variants/markets must not blend into one average.
- [ ] Pause or fail an unfinished scan: current prices and history remain unchanged. Only a completed response enters history.
- [ ] Save normally, then reload/relog/restart. Daily history, retention and both crafting preferences survive. Allow WoW to save before replacing files.

## Recipe list, arithmetic and quotes

- [ ] Open each available profession, select a learned recipe and compare raw quantities/unit prices with material cost, sale and `profit = sale - materials`; return is profit divided by material cost, before fees.
- [ ] In Recipe list, Show all recipes includes positive, negative, break-even and unpriced learned entries. Losses appear red; unknown values say Unavailable and sort last. Profitable only hides those entries. The filter survives a normal save.
- [ ] Switch Profit / craft and Return %, page through results and select a row. Selection changes the native recipe and never crafts it. Service/unsupported entries explain unavailable profit on the selected page.
- [ ] Check fixed multi-item output, variable yield, zero material cost, optional/alternative selection and missing prices. The catalog uses minimum yield and fixed required materials.
- [ ] Leave the list open while item data loads. Catalog build/publication counts stabilize. A new completed price scan replaces the results once after the refresh completes.
- [ ] Check Cooking and a direct Enchanting service. A service keeps a material quote without an invented auction profit.
- [ ] Apply 0%, then 25% quote markup. Fixed outputs and services end in ea; variable/unknown output says per craft. The native recipe link matches profession-book shift-click. Insert in chat opens a draft without sending it.
- [ ] Change recipe/markup while the quote is focused. The old quote must update; missing material prices disable chat insertion.

## Combat and scan regression

- [ ] Hover the same public item outside/during combat: vendor, historic, recent AH and applicable DE values remain, with correct stack totals and no duplicate block.
- [ ] Check bag items, equipment, chat links and comparison tooltips. Unavailable quantity contexts show Each without errors.
- [ ] Open the AH: Buy remains selected, one MS tab appears, and controls fit.
- [ ] Start, pause and resume during cooldown. Once Local copy is complete, close/reopen and resume; request count remains unchanged. Repeat after combat.
- [ ] If the buffer is lost before copying finishes, work remains paused. Fresh Restart waits for the cooldown and adds one request; prior completed prices/history remain until the new scan completes.
- [ ] Reload/logout ends unfinished work without discarding completed prices or history.

## Report

Send `/msmv diagnostics`, the failed check, profession/recipe name or ID, exact Lua error and a screenshot for layout issues. For history, include scan request times in UTC, retained/sample day counts and retention. For resume, include before/after request counts, copy progress and staged rows.
