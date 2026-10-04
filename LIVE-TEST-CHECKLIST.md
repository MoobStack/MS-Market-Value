# Live-client checklist

Test exact release `1.0.0 / 2026-10-04-release001`. The user reported build003 COMPLETE on PvP/Horde: 104,763 rows, 2,856 priced items, one request, 6,329 events and 6,328 same-count updates; the tab installed and behavior appeared normal. This is successful baseline evidence. The boxes below track the exact 1.0.0 release or dedicated scenarios not established by that report; local checks are separate.

## Startup and window

- [ ] Install the Clean ZIP into the active Forever beta AddOns folder and restart the client.
- [ ] Enable script errors using `/console scriptErrors 1`.
- [ ] Confirm the addon list and `/msmv diagnostics` identify version 1.0.0, build 2026-10-04-release001 and Interface 16001.
- [ ] Open `/msmv`; check readable labels, no overlap, usable buttons and proper fonts.
- [ ] Drag the window; close it with Escape; reopen it and confirm the position.
- [ ] Toggle each tooltip setting and apply stale hours. Verify the control changes the corresponding behavior.
- [ ] Open diagnostics, copy with Ctrl+C, and close the dialog.

## Native full scan

- [ ] Open an auctioneer; confirm Buy stays selected, the **MS Market Value** tab appears once, and no standalone settings popup opens.
- [ ] Select the MS tab; check native textured inset borders, stock controls, readable labels and no overlap. Confirm scan controls and both settings columns fit without a settings scrollbar at your UI scale.
- [ ] Switch through Buy, Sell, Auctions, MS and Auctionator tabs if installed; confirm the panels do not overlap or produce blocked-action errors.
- [ ] Close/reopen the auctioneer and confirm one MS tab is reused. Check `/msmv` selects/leaves it and opens a manual window away from the AH.
- [ ] Copy diagnostics before scanning; confirm the market key is available and record ruleset/source, faction, reporting aliases, region/portal and lookup sources. On the supplied PvP host expect ruleset pvp and native region 90. Record the actual Normal alias when available.
- [ ] Click Scan entire AH exactly once. Observe WAITING, PROCESSING and COMPLETE without a Lua error.
- [ ] Confirm the session full-scan request count increases after one permitted attempt. If it remains zero/IDLE, record the explicit market/readiness gate reason.
- [ ] Save diagnostics showing row count, priced-item count, replication-event count and same-count data updates. Additional stable-count updates must not cause the old buffer-refreshed failure.
- [ ] Compare several native AH listings with tooltip prices: a normal item, a stack/commodity, low-level equipment and listed enchanting materials.
- [ ] Include an uncommon weapon with a signed random suffix and check a known matching suffix separately from item-wide fallback.
- [ ] Where bid-only listings are available, verify they do not become a buyout price.
- [ ] Check that listed enchanting materials are covered by the native replication response. Report missing materials even if the scanner says COMPLETE.
- [ ] Confirm the persistent minimum cooldown disables another immediate full scan.

Use `GetReplicateItemInfo`/`GetNumReplicateItems` only through the loaded addon for further diagnostics; do not paste an AH API call into `/run` or use a dynamic Lua editor to bypass the addon's boundaries.

## Tooltip values

- [ ] Hover a known bag stack: verify **Each / Stack (N)** uses its actual count and vendor/AH totals equal the unrounded unit value times N.
- [ ] Hover two different stacks of the same item and split/merge a stack; rehover and confirm the totals change without duplicate sections.
- [ ] Hover a single item, an equipped item and a generic chat link; verify each-only prices when no reliable stack context is available.
- [ ] On eligible gear, confirm **DE expected** is in the price block, with each/stack totals where applicable, followed by one blank line before the material section.
- [ ] Confirm material ranges/chances/averages remain per item. Toggle material display and verify the DE price remains available.
- [ ] Upgrade from build003 with an existing snapshot; confirm prices/settings/exclusions/cooldown remain without a forced scan.

- [ ] Hover a vendor-sellable item outside combat and compare the native sell value for one item.
- [ ] Hover an item with zero vendor sale value and verify it is distinguished from unavailable data.
- [ ] Check native bag/equipment tooltips, chat item-reference tooltips and comparison tooltips.
- [ ] Hover a previously uncached item with comparisons shown, including item 270018 if available. Allow native item data to load; confirm no TooltipDataHandler insert/infoList error, intact comparison headers/deltas and one MS section. Rehover to check deferred comparison values.
- [ ] Hover the same item repeatedly and verify there is only one MS Market Value section per tooltip.
- [ ] Verify missing AH prices read Scan required/Not listed/No buyout appropriately.
- [ ] On eligible green gear, verify material names, quantities, probabilities and expected value lines appear.
- [ ] When a possible material is unpriced, verify the complete DE total is unavailable and any known portion is labeled as partial.
- [ ] Set a short stale threshold on an old snapshot and verify the stale marker.
- [ ] Enter combat with an item tooltip/scan window present; confirm no addon calculation/error runs and local scanning stops safely.

## Persistence and replacement

- [ ] After a successful scan, use `/reload`, then verify prices/settings/window position remain.
- [ ] Log out normally and log back in; verify the same complete snapshot and cooldown state remain.
- [ ] Exit WoW normally and restart it; verify the same values load from disk.
- [ ] Change characters in the same detected region/ruleset/faction; verify account-wide prices remain. If the reporting-host suffix changes, confirm the market key stays the same.
- [ ] Test Normal and PvP separately when available; confirm each keeps its own snapshot. Record the Normal reporting alias and detection source.
- [ ] Confirm another region or unqualified faction cache never substitutes the first market's prices.
- [ ] Verify old realm-keyed records survive the upgrade but do not appear in the new ruleset cache before its first complete scan.
- [ ] After a permitted later scan, confirm its timestamp replaces the old snapshot and missing listings do not retain old prices.

Keep a copy of the SavedVariables backup while the client is closed. A save/reload failure must be recorded as a client-persistence issue; do not claim completion from an in-memory price alone.

## Interrupted scans and coexistence

- [ ] During a later permitted scan, press Stop; verify the prior complete timestamp/prices remain.
- [ ] Close the auctioneer during local processing; verify the prior snapshot remains.
- [ ] If a scan naturally times out or has delayed data, capture diagnostics and verify it does not clear prior prices.
- [ ] After switching tabs and leaving the AH, exercise normal bag use in and out of combat; record any native taint/blocked-action error.
- [ ] With another AH addon installed, run one full scanner at a time. Verify normal tooltip coexistence without duplicated MS sections.
- [ ] If concurrent replication is intentionally tested, expect refusal/preservation and capture both addon versions.

## Forever disenchant evidence

- [ ] While normally disenchanting spare low-level items, record item link/ID, native iLvl, quality, actual material and quantity, client build and sample count.
- [ ] Verify special non-disenchantable items can be excluded and their estimates restored through the UI.
- [ ] Treat an unexpected material or quantity as a model mismatch requiring a model update.
- [ ] Leave unobserved high-level/rare/epic brackets marked unverified. A low-level test cannot qualify them.

Native auction/API/UI/persistence checks and loot-model checks are separate. Submit `/msmv diagnostics`, any exact Lua error and the relevant checklist results for the next build. The three prerelease revisions remain in the 0.1.0-beta history; subsequent stable releases use new semantic version tags.
