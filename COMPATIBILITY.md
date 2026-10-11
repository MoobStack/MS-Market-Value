# Compatibility

## Target

This test targets **WoW Forever 1.60.1, Interface 16001**, using modern auction, profession, item and tooltip APIs. The earlier completed scan report was from build 70205 on PvP/Horde. The Test revision 1 report came from build 70338, exposed buffer loss on reopen and recipe-list churn, and retained 98,455 saved rows. Test revision 2 needs its own native checks.

All three TOCs—standard, `_Camelot` and `_Forever`—describe the same addon and load order. Initialization checks the Interface number, saved schema, restricted-value API and auction functions. Different clients or Interface versions need an API review.

The pinned Blizzard UI/API mirror and source references are listed in [docs/RESEARCH.md](docs/RESEARCH.md). A source contract supports implementation; it does not establish live server behavior.

## Auction and market data

Full enumeration uses one user-started `C_AuctionHouse.ReplicateItems` request. Reading and retries are batched. Only a completed response replaces prices. The persistent 15-minute minimum request interval and server limits remain intact.

Pause/resume uses a session-local auction copy once all price rows have been copied. Keep the AH open until Local copy is complete. An early buffer loss retains paused work; recovery can retry the original buffer or start fresh after the request cooldown. The API has no generation token. Count/anchor checks and observed competing requests protect incomplete copying; complete copies no longer depend on native retention. Reload/logout does not preserve unfinished work. Use one full scanner at a time.

Detected market keys combine region, Forever ruleset and faction. Native positive region IDs include the reported beta regions 90 and 110. Hardcore uses the native API; Normal/PvP/RP detection uses bounded public reporting aliases with the source shown in diagnostics. Host numbers share a detected ruleset cache. Unrecognized aliases remain isolated. Cross-faction AH pooling is not yet qualified, and older cache keys are not merged automatically.

## Crafting coverage

The generic adapter reads native learned recipes and consumed material schematics rather than maintaining a profession whitelist. It follows the visible native crafting form and includes validated selected optional reagents. A full recipe catalog is preferred; a filtered fallback is explicitly labeled and leaves native filters alone.

Fixed item-reagent crafts support cost, output quantity, sale value, gross profit and return. Non-auctionable services support material quotes. Unknown material prices, incomplete variant choices, currency costs, variable reagent quantities, salvage and recrafting cannot supply a full estimate in this revision. Quality-dependent output requires selection.

The native GetRecipeLink is used where available, matching profession-book shift-clicks. ChatFrameUtil.OpenChat opens a draft; a legacy opener is supported if present. A missing link keeps the plain recipe name. Every profession's live recipe shapes and hyperlink rendering remain part of testing.

## Tooltips and frames

Public item tooltips receive saved prices during combat. Restricted IDs are not read; unavailable stack context shows each-item values. GUID/location and bag/equipment quantity reads are guarded. Native primary-tooltip rebuilds remain outside combat; comparison rebuilds remain under Blizzard ownership.

AH and crafting controls use Blizzard templates. LibAHTab coordinates addon tabs through the shared LibStub registry without extending Blizzard's tab arrays. Frame doubles check lifecycle behavior, not visual fit, native taint or running-addon coexistence.

## Prices and DE estimates

AH lows are asking prices before fees. Missing buyouts are not zero values or guaranteed sale prices. Suffix-specific prices retain a labeled item-wide fallback. Recipe ranking uses minimum output yield; quotes use full market material cost, including owned materials.

DE values use the named Classic reference model. Forever loot probabilities, new materials, exceptional eligibility and skill requirements remain unverified. The addon does not perform auction transactions, crafting or disenchanting actions.

## Persistence

Schema-1 completed prices and preferences carry forward from 1.0.0. WoW writes account SavedVariables on its normal save lifecycle; verify reload/relog/restart behavior in the actual client. Future schemas and invalid roots are preserved and refused. The next test revision will introduce documented history retention; this revision keeps only the latest completed snapshot per market.
