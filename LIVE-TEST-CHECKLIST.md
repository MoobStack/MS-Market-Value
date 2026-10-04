# Live-client beta checklist

Test the exact build `2026-10-04-beta001`. Record the client version/build and addon diagnostics before changing the environment. All boxes below are initially uncompleted; the headless test result is not a live pass.

## Startup and window

- [ ] Install the Clean ZIP into the active Forever beta AddOns folder and restart the client.
- [ ] Enable script errors using `/console scriptErrors 1`.
- [ ] Confirm the addon list and `/msmv diagnostics` identify version 0.1.0-beta, build001 and Interface 16001.
- [ ] Open `/msmv`; check readable labels, no overlap, usable buttons and proper fonts.
- [ ] Drag the window; close it with Escape; reopen it and confirm the position.
- [ ] Toggle each tooltip setting and apply stale hours. Verify the control changes the corresponding behavior.
- [ ] Open diagnostics, copy with Ctrl+C, and close the dialog.

## Native full scan

- [ ] Open an auctioneer; verify the window opens when that preference is enabled.
- [ ] Click Scan entire AH exactly once. Observe WAITING, PROCESSING and COMPLETE without a Lua error.
- [ ] Save diagnostics showing row count and priced-item count.
- [ ] Compare several native AH listings with tooltip prices: a normal item, a stack/commodity, low-level equipment and listed enchanting materials.
- [ ] Include an uncommon weapon with a signed random suffix and check a known matching suffix separately from item-wide fallback.
- [ ] Where bid-only listings are available, verify they do not become a buyout price.
- [ ] Check that listed enchanting materials are covered by the native replication response. Report missing materials even if the scanner says COMPLETE.
- [ ] Confirm the persistent minimum cooldown disables another immediate full scan.

Use `GetReplicateItemInfo`/`GetNumReplicateItems` only through the loaded addon for further diagnostics; do not paste an AH API call into `/run` or use a dynamic Lua editor to bypass the addon's boundaries.

## Tooltip values

- [ ] Hover a vendor-sellable item outside combat and compare the native sell value for one item.
- [ ] Hover an item with zero vendor sale value and verify it is distinguished from unavailable data.
- [ ] Check native bag/equipment tooltips, chat item-reference tooltips and comparison tooltips.
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
- [ ] Change characters on the same realm; verify account-wide prices remain.
- [ ] If testing another realm/region, verify the first realm's prices are not substituted for an unscanned market.
- [ ] After a permitted later scan, confirm its timestamp replaces the old snapshot and missing listings do not retain old prices.

Keep a copy of the SavedVariables backup while the client is closed. A save/reload failure must be recorded as a client-persistence issue; do not claim completion from an in-memory price alone.

## Interrupted scans and coexistence

- [ ] During a later permitted scan, press Stop; verify the prior complete timestamp/prices remain.
- [ ] Close the auctioneer during local processing; verify the prior snapshot remains.
- [ ] If a scan naturally times out or has delayed data, capture diagnostics and verify it does not clear prior prices.
- [ ] With another AH addon installed, run one full scanner at a time. Verify normal tooltip coexistence without duplicated MS sections.
- [ ] If concurrent replication is intentionally tested, expect refusal/preservation and capture both addon versions.

## Forever disenchant evidence

- [ ] While normally disenchanting spare low-level items, record item link/ID, native iLvl, quality, actual material and quantity, client build and sample count.
- [ ] Verify special non-disenchantable items can be excluded and their estimates restored through the UI.
- [ ] Treat an unexpected material or quantity as a model mismatch requiring a beta update.
- [ ] Leave unobserved high-level/rare/epic brackets marked unverified. A low-level test cannot qualify them.

Native auction/API/UI/persistence checks and loot-model checks are separate. Submit `/msmv diagnostics`, any exact Lua error and the relevant checklist results for the next build. All revisions stay under the same primary beta version.
