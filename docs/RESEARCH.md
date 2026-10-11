# Research and source review

Reviewed on **2026-10-04 UTC** for beta builds001–003 and stable 1.0.0. No game-client session was operated during development. The user supplied earlier startup/errors/screenshot evidence and then a successful build003 native PvP scan report. The new quantity API review uses the same pinned Forever client source.

## Primary references

| Source | Use in this project |
|---|---|
| [Blizzard UI Add-On Development Policy](https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534/1) | Free/visible-source distribution and responsible addon behavior |
| [Blizzard UI mirror: Forever commit e3ecc27](https://github.com/Gethe/wow-ui-source/commit/e3ecc27b64d30fdc735a3f6579b866858f9f9df1) | Current reviewed client source, version 1.60.1 build 70205 |
| [AuctionHouseDocumentation.lua at that commit](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_APIDocumentationGenerated/AuctionHouseDocumentation.lua) | Replication API, event, return fields and full-house scanning direction |
| [ItemDocumentation.lua at that commit](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua) | Native item metadata and item-data loading boundaries |
| [Native tooltip info documentation](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_APIDocumentationGenerated/TooltipInfoDocumentation.lua) | Bag/equipment getter argument contracts; generic links provide no verified stack count |
| [Native container documentation](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_APIDocumentationGenerated/ContainerDocumentation.lua) | ContainerItemInfo itemID and stackCount for the hovered bag slot |
| [Native ItemLocation implementation](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_ObjectAPI/Mainline/ItemLocation.lua) | Equipment-slot location constructor; paired with C_Item.GetItemLocation/GetItemID/GetStackCount |
| [TooltipDataHandler.lua at that commit](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_SharedXMLGame/Tooltip/TooltipDataHandler.lua) | Modern tooltip postprocessing and primary-data rebuild mechanisms |
| [Questie's own Forever TOC](https://github.com/Questie/Questie/blob/master/Questie_Camelot.toc) | Independently maintained current Interface 16001, Camelot naming and LoadSavedVariablesFirst conventions |
| [CMaNGOS Classic reference database](https://github.com/cmangos/classic-db/blob/ec4f596146be6467ea93c57397858e329e2db852/Full_DB/ClassicDB_1_12_1_z2815.sql.gz) | Reference material IDs, conditional quantities and Classic probability records only |
| [Lua 5.1.5 source distribution](https://www.lua.org/ftp/lua-5.1.5.tar.gz) | Local independent syntax/fixture execution environment |
| [Native AH frame at reviewed Forever commit](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_AuctionHouseUI/Shared/Blizzard_AuctionHouseFrame.lua) | Display-mode tables, native tab indexing and selection/hide behavior |
| [Native AH layout XML](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_AuctionHouseUI/Shared/Blizzard_AuctionHouseFrame.xml) | Reviewed 800×538 frame and tab template/layout |
| [Native CVar documentation](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_APIDocumentationGenerated/CVarDocumentation.lua) | Ordinary C_CVar.GetCVar access for portal fallback |
| [LibAHTab/LibStub pinned source](https://github.com/TheMouseNest/LibAHTab/tree/2ddbec58c8be37b2cd911bee7512d597e7dfdfe1) | Bundled shared tab implementation, Camelot handling, original MIT/public-domain terms |
| [Official Forever ruleset explanation](https://worldofwarcraft.blizzard.com/en-us/news/24302070) | Realmless Normal/PvP/Roleplaying/Hardcore ecosystem separation; not evidence of AH cross-faction pooling |
| [Native TooltipComparisonManager at reviewed commit](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_SharedXMLGame/Tooltip/TooltipComparisonManager.lua) | Comparison header/append-mode ownership and generic rebuild boundary |
| [Native GameRules documentation](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_APIDocumentationGenerated/GameRulesDocumentation.lua) | Hardcore API and Classic/Modern experience-preset distinction |
| [Native shared panel templates XML](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml) | InsetFrame/PortraitFrame native textures, borders, title/portrait and close controls |
| [Official GitHub CLI release create](https://cli.github.com/manual/gh_release_create), [view](https://cli.github.com/manual/gh_release_view) and [edit](https://cli.github.com/manual/gh_release_edit) | Stable release flags, exact remote tag verification, asset upload and publication checks |
| [Official checkout action v7.0.1](https://github.com/actions/checkout/releases/tag/v7.0.1) | Current reviewed, commit-pinned CI checkout dependency |

The WoW UI mirror contains extracted Blizzard client UI/API definitions. It is useful primary implementation evidence, but it cannot establish live server behavior or automatic compatibility with later builds.

The CMaNGOS reference is a community server implementation of Classic data, not authoritative Blizzard Forever loot data. This distinction is retained in the runtime model, tooltips, README and release notes. Generic bracket estimates can differ from item-specific reference records.

## Findings applied

- The reviewed Forever source reports version 1.60.1 build 70205, requiring a modern API implementation rather than Interface 11200 code.
- Auction replication is the documented full-house enumeration path. The return tuple includes quantity, total buyout, sale status, item ID and completeness.
- `REPLICATE_ITEM_LIST_UPDATE` is the native response event. Index processing starts at zero and ends at count minus one.
- Native item information provides sell price, item level, quality, equipment slot and numeric class/subclass IDs.
- Modern tooltip data callbacks replace the old item-set script hook.
- TOC support for `LoadSavedVariablesFirst` does not remove the need for live save/reload qualification.
- No complete Forever disenchant loot probability dataset was established from the reviewed sources.

## Build002 findings

The native AH uses display-mode tables and a separate tab-index array. LibAHTab minor 5 supports Camelot and coordinates addon panes through a shared registry without extending that native array. Both the main library and its public-domain LibStub copy were fetched from pinned commit `2ddbec58c8be37b2cd911bee7512d597e7dfdfe1`; only line endings/trailing whitespace were normalized.

The user's supplied market error matches build001's pre-request identity gate. It proves a failed gate, not which native lookup returned nil/empty/zero. The fix covers those cases and exposes the public lookup values for native retesting. Recognized portal mappings retain native numeric keys; other portals are isolated. See [BUILD002-INVESTIGATION.md](BUILD002-INVESTIGATION.md).

## Build003 findings

The user's build002 diagnostics show native region 90, an internal PvP alias, one request reaching PROCESSING, and the second-event refusal. Native comparison creation uses append-mode precomputed data while the generic rebuild forces non-append mode; this matches the reported ShoppingTooltip1 infoList insertion failure. The revised code refreshes only getter-backed primary item tooltips and preserves scan staging across stable-count updates. See [BUILD003-INVESTIGATION.md](BUILD003-INVESTIGATION.md).

Official Forever documentation describes realmless, distinct ruleset ecosystems. That supports separating PvP and Normal instead of treating reporting-host suffixes as independent realms. No verified native Normal/PvP getter or cross-faction AH pooling behavior was established in the reviewed source. Alias-derived detection is bounded and labeled, unknown aliases stay isolated, and factions remain separate pending qualification. The Classic/Modern experience preset is a UI preset, not the Normal/PvP ruleset.

The screenshot establishes the old narrow panel. Native InsetFrameTemplate and PortraitFrameTemplate definitions support the revised texture/border/control choices; source review and widget doubles cannot render or qualify the resulting native screen.

## 1.0.0 findings

The user's build003 report establishes COMPLETE on `forever|90|pvp|Horde`: 104,763 rows, 2,856 priced items, 6,329 replication events, 6,328 same-count updates and one request. This updates the earlier pending scan status; dedicated disk, market-coverage and loot checks remain separate. See [RELEASE-1.0.0.md](RELEASE-1.0.0.md).

The pinned native `C_Item.GetItemLocation`, `GetItemID` and `GetStackCount` definitions support resolving one readable owned item GUID. Native tooltip primary getter information carries bag/inventory coordinates; `C_Container.GetContainerItemInfo` supplies a matching bag item's stack count. Equipment fallback is limited to the player's matching item location. `GetItemCount` is aggregate ownership, and item stack size is capacity; neither answers the hovered-quantity question. Generic links and child-item getters lack verified parent stack identity and retain each-only display. Calls are guarded and run outside combat.

## 1.1.0 beta: profession and interruption contracts

The profession adapter was reviewed against the same build70205 source commit used by 1.0.0, `e3ecc27b64d30fdc735a3f6579b866858f9f9df1`. These five files were also compared with the later reviewed mirror commit `15666a6e67938a1ab5caf041406464251db111ca`; their bytes are identical. No new third-party runtime code was imported.

| Primary client source | Contract used |
|---|---|
| [TradeSkillUI documentation](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_APIDocumentationGenerated/TradeSkillUIDocumentation.lua) | Recipe info, schematic, output item data, OpenRecipe and profession events |
| [TradeSkillUI types](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_APIDocumentationGenerated/TradeSkillUITypesDocumentation.lua) | Required slot quantities, item/currency reagents, output ranges and learned flags |
| [Native recipe form](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_ProfessionsTemplates/Blizzard_ProfessionsRecipeSchematicForm.lua) | GetRecipeInfo/GetTransaction, current level, selected output and native output calls |
| [Native transaction](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_ProfessionsTemplates/Blizzard_ProfessionsTransaction.lua) | Regular versus modified allocations and copied reagent/slot/quantity information |
| [Native profession catalog](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_ProfessionsTemplates/Blizzard_Professions.lua) | GetFilteredRecipeIDs as the native recipe-list source |

The adapter probes GetAllRecipeIDs for a full catalog; where unavailable, it uses the reviewed filtered source and labels that scope without changing native filters. Generic native schematics avoid a hardcoded profession whitelist. This supports shared calculations, not a claim that every live recipe shape has been tested.

Combat tooltip decoration reads only accessible saved/native item values. The old blanket combat return was removed; protected primary-tooltip rebuilds remain deferred. Pause/resume keeps session staging, accepted rows and retry cursors, and observes competing requests while paused. The native replication API still has no buffer generation token or persistent incomplete-buffer contract. No new request or cooldown override is used to resume.

## Evidence boundaries

The local source/API review supports the implementation choice. The successful user scan report establishes completion for the supplied PvP replication buffer. Neither that report nor source review proves that every ruleset returns all intended auctions, that the client writes SavedVariables successfully, that the native UI lays out correctly, or that the DE model matches actual loot.

No Auctionator scanner, art or proprietary database was copied. Its general full-scan-and-tooltip behavior was the user's feature reference. Build002 bundles the independently published LibAHTab and LibStub shared libraries from the pinned primary source above, preserving their terms. The rest of the runtime is original project code; game artwork/fonts are referenced from client resources. `tools/vendor.json` records original and normalized bundled hashes.

MoobStack identity and packaging conventions were taken from the user's existing addon-development handoff, including prefix/naming, documentation, clean/source/Git ZIPs, bundles and checksum manifests. The earlier OctoWoW target was intentionally not carried over to this new Forever project.
