# Compatibility

## Target

Version 1.2.0-beta targets **WoW Forever 1.60.1, Interface 16001**, using modern auction, profession, item and tooltip APIs. The preceding 1.1.0 release was accepted on build 70338, PvP/Horde. Test revision 2 diagnostics from build 70450 show a complete 26,852-row scan, four history days, an installed opportunities tab and a selected service recipe with a native recipe link. Vendor observations remain zero. The revised crafting layout and live item navigation still need native verification; see [VALIDATION.md](VALIDATION.md).

All three TOCs—standard, `_Camelot` and `_Forever`—describe the same addon and load order. Initialization checks the Interface number, saved schema, restricted-value API and auction functions. Different clients or Interface versions need an API review.

The pinned Blizzard UI/API mirror and source references are listed in [docs/RESEARCH.md](docs/RESEARCH.md). A source contract supports implementation; it does not establish live server behavior.

## Auction and market data

Full enumeration uses one user-started `C_AuctionHouse.ReplicateItems` request. Reading and retries are batched. Only a completed response replaces prices. The persistent 15-minute minimum request interval and server limits remain intact.

Pause/resume uses a session-local auction copy once all price rows have been copied. Keep the AH open until Local copy is complete. An early buffer loss retains paused work; recovery can retry the original buffer or start fresh after the request cooldown. The API has no generation token. Count/anchor checks and observed competing requests protect incomplete copying; complete copies no longer depend on native retention. Reload/logout does not preserve unfinished work. Use one full scanner at a time.

Detected market keys combine region, Forever ruleset and faction. Native positive region IDs include the reported beta regions 90 and 110. Hardcore uses the native API; Normal/PvP/RP detection uses bounded public reporting aliases with the source shown in diagnostics. Host numbers share a detected ruleset cache. Unrecognized aliases remain isolated. Cross-faction AH pooling is not yet qualified, and older cache keys are not merged automatically.

## Crafting coverage

The generic adapter reads native learned recipes and consumed material schematics rather than maintaining a profession whitelist. It follows the visible native crafting form and includes validated selected optional reagents. A full recipe catalog is preferred; a filtered fallback is explicitly labeled and leaves native filters alone.

Fixed item-reagent crafts support cost, output quantity, sale value, gross and fee-adjusted net profit/return, and break-even prices. Non-auctionable services support material quotes. Unknown material prices, incomplete variant choices, currency costs, variable reagent quantities, salvage and recrafting cannot supply a full estimate in this version. Quality-dependent output requires selection.

The native GetRecipeLink is used where available, matching profession-book shift-clicks. ChatFrameUtil.OpenChat opens a draft; a legacy opener is supported if present. A missing link keeps the plain recipe name. Every profession's live recipe shapes and hyperlink rendering remain part of testing.

## Tooltips and frames

Public item tooltips receive saved prices during combat. Restricted IDs are not read; unavailable stack context shows each-item values. GUID/location and bag/equipment quantity reads are guarded. Native primary-tooltip rebuilds remain outside combat; comparison rebuilds remain under Blizzard ownership.

AH and crafting controls use Blizzard templates. LibAHTab coordinates addon tabs through the shared LibStub registry without extending Blizzard's tab arrays. The profession toggle sits beside the close button, above the actual native border/title levels, and hides with CraftingPage. Auto-open is not required; `/msmv craft` is also available. Frame doubles check lifecycle behavior, not visual fit, native taint or running-addon coexistence.

## Prices and DE estimates

AH lows are asking prices before fees. Missing buyouts are not zero values or guaranteed sale prices. Suffix-specific prices retain a labeled item-wide fallback. Recipe ranking uses minimum output yield; quotes use vendor purchase observations for known vendor materials and market replacement cost for other materials, including owned materials. The optional all-recipes view retains unavailable learned entries, without assigning zero prices.

DE values use the named Classic reference model. Forever loot probabilities, new materials, exceptional eligibility and skill requirements remain unverified. The addon does not perform auction transactions, crafting, disenchanting or mailbox collection actions.

## Persistence

Schema-1 completed prices and preferences carry forward from 1.0.0. WoW writes account SavedVariables on its normal save lifecycle; verify reload/relog/restart behavior in the actual client. Future schemas and invalid roots are preserved and refused. Daily history retains 1–30 UTC calendar days, using the latest completed scan per request day. The existing current snapshot stays separate. Upgrade can import its latest valid snapshot once, but cannot reconstruct earlier days. Matching suffix series and market keys stay isolated; missing listings are skipped in averages. Unknown history sub-schemas remain untouched while current prices continue.

## Version 1.2.0 additions

Merchant pricing probes `C_MerchantFrame.GetItemInfo`, with the legacy `GetMerchantItemInfo` tuple as a fallback. Item ID/link and merchant count are read only; stackCount is the purchase bundle quantity. Only purchasable, unlimited, gold-only items qualify. No fixed Classic buy prices or guessed buy/sell multiplier is used. Costs require a readable player GUID and remain scoped to that character, faction and market. Missing/expired vendor prices require a supplier visit. Reputation-tier changes use readable `C_Reputation` data; revisit the supplier after any other discount change.

The second AH pane uses the same unchanged LibAHTab registry and is registered before settings. Its computations need no new auction API, but do require earlier saved days for matching items. Stale/current/future dates and random suffixes are checked independently. The AH cut is a configurable estimate, default 5%; it is not a detected server rate. Deposits, demand, sale completion and available quantity at the displayed low are not inferred. Native frame fit and API behavior remain testing items. Revision 2 checks native MakeItemKey/GetItemKeyInfo and uses the frame's SelectBrowseResult/QueryItem for a player-clicked lookup. If exact-key support is unavailable, it can run the native Buy name search with readable item data. Existing native filters can narrow those results. These lookups are separate from full replication scans and do not bypass their cooldown.


## Money tools and tracking

The same build-70450 sources define native Buy headers, item completion IDs, commodity server quotes/confirmation and buyer/seller invoices. Secure post-observers record confirmed requests; mailbox invoices backfill missing observations. Source review does not establish native event ordering, other-addon coexistence or successful live reconciliation. Test normal buys, commodities, offline sales, fast collection and reloads before release.

AH sales are discovered at the mailbox, not immediately when a listing vanishes. Invoices expose neither a durable identity nor the original transaction time. Signature/expiry matching retains simultaneous duplicates but cannot resolve every identical invoice removed/replaced between observations. Backfills use first-recorded dates. Unknown costs stay unknown; purchase lots are not automatically assigned to sales.

Vendor accounting requires gold-only item/bag/wallet changes that reconcile exactly. Currency items, equipped sales, refunds and concurrent unrelated changes can need manual recording. The addon never calls purchasing, posting, selling, crafting or mail-collection functions.

Watchlists and ledger use separate optional schema-1 roots. Numeric watches are item-wide; item links are exact-suffix watches. Commission estimates use selected recipe data and the service customer-material setting. Keep SavedVariables backups when rolling back: an older beta may not understand the new commission/vendor kinds. The UI and all new automatic paths still need live Forever checks.
