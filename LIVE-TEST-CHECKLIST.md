# Test revision 1: live checks

Test `1.1.0-beta / 2026-10-11-beta001`, **Test revision 1**, on the Forever client. Local fixtures do not establish native UI fit or server buffer retention.

## Install and baseline

- [ ] Close WoW, replace the addon with the Clean ZIP, preserve WTF, and restart.
- [ ] Enable script errors with `/console scriptErrors 1`.
- [ ] Verify **Test revision: 1** in `/msmv diagnostics`, with Interface 16001 and the expected market key.
- [ ] Confirm the previous completed prices, tooltip settings and DE exclusions remain.
- [ ] Open an auctioneer: Buy remains selected, one MS tab appears, and the scan/settings controls fit at your UI scale.

## Crafting

- [ ] Open each available profession and select a learned item recipe. The MS crafting window opens and follows recipe changes.
- [ ] Compare every required material quantity and its latest AH unit price with the displayed material list and total cost.
- [ ] Check a profitable recipe and a losing recipe. Confirm `profit = sale - materials` and `% = profit / materials × 100`, before fees.
- [ ] Check a multi-item output. Cost is per craft; sale uses the number produced; cost per item divides by output count.
- [ ] If output quantity varies, check both endpoints. The ranking uses minimum output.
- [ ] Open **Profitable recipes**, switch Profit / craft and Return %, page through results, and select a row. It selects the native recipe and does not craft anything.
- [ ] Confirm missing material prices prevent a full cost, profit and quote. Missing output price still allows a complete material quote.
- [ ] Change optional or alternative reagents where supported. The selected recipe follows public allocations; incomplete choices remain unavailable.
- [ ] Test Cooking and a direct Enchanting service. A service has material cost/quote without a fabricated auction profit.
- [ ] Apply 0%, then 25% markup. Confirm the quote equals material cost × 1.25, can be copied, and the setting persists after a normal save/reload.
- [ ] Close/reopen the crafting window with its MS button and `/msmv craft`; close the profession and confirm the addon window closes.
- [ ] Check long recipe/material names, window dragging, Escape, UI scales and readability. Report overlap with a screenshot.

## Combat tooltips

- [ ] Hover the same priced bag item outside and during combat. Vendor, AH and applicable DE values remain present.
- [ ] Check an actual stack, a single item, equipment, a chat link and comparisons. Stack quantities remain correct where public; unavailable quantity shows Each.
- [ ] Rehover and change stacks. No duplicate price block or comparison header damage occurs.
- [ ] Allow uncached item information to load; no tooltip getter/rebuild or blocked-action error occurs. Deferred native refresh can finish after combat.

## Pause and resume

- [ ] Start one permitted scan and capture diagnostics. Click Pause while it is processing; the previous completed timestamp/prices remain usable.
- [ ] Click Resume during the full-scan cooldown. It continues staged work and does **not** increase the session request count.
- [ ] Pause while waiting for a response if possible. A response received while paused stays staged until Resume.
- [ ] Close/reopen the auctioneer during processing and resume. Record whether Forever retains the buffer; an unavailable buffer must fail clearly and keep previous prices.
- [ ] If combat interrupts a scan, confirm PAUSED, then resume outside combat at an auctioneer.
- [ ] If native item data is delayed, resume after a timeout. Accepted rows must not be counted twice.
- [ ] Confirm COMPLETE accounts for the full response, updates the saved timestamp once, and leaves the original request cooldown intact.
- [ ] Use `/msmv discard` on another incomplete scan. Completed prices remain; the new-request cooldown is not bypassed.
- [ ] Do not expect incomplete work to survive `/reload` or quitting. Verify completed prices and cooldown still do.
- [ ] Check normal AH tab switching and another AH addon with one scanner active at a time; capture any error.

## Save and report

- [ ] Verify completed prices, settings and exclusions after `/reload`, relog and full exit/restart.
- [ ] Compare several current AH listings, including enchanting materials and a signed-suffix item, with saved unit prices.
- [ ] Keep different rulesets/factions isolated and verify a same-market reporting-host change reuses the cache.

Send `/msmv diagnostics`, the profession and recipe name/ID, exact Lua errors, and the failed checklist item. For resume, include before/after request counts and staged-row progress. Price history is not part of this revision's checks.
