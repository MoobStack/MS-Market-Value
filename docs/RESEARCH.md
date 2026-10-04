# Research and source review

Reviewed on **2026-10-04 UTC** for the initial beta candidate. No game-client session was available during development.

## Primary references

| Source | Use in this project |
|---|---|
| [Blizzard UI Add-On Development Policy](https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534/1) | Free/visible-source distribution and responsible addon behavior |
| [Blizzard UI mirror: Forever commit e3ecc27](https://github.com/Gethe/wow-ui-source/commit/e3ecc27b64d30fdc735a3f6579b866858f9f9df1) | Current reviewed client source, version 1.60.1 build 70205 |
| [AuctionHouseDocumentation.lua at that commit](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_APIDocumentationGenerated/AuctionHouseDocumentation.lua) | Replication API, event, return fields and full-house scanning direction |
| [ItemDocumentation.lua at that commit](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua) | Native item metadata and item-data loading boundaries |
| [TooltipDataHandler.lua at that commit](https://github.com/Gethe/wow-ui-source/blob/e3ecc27b64d30fdc735a3f6579b866858f9f9df1/Interface/AddOns/Blizzard_SharedXMLGame/Tooltip/TooltipDataHandler.lua) | Modern tooltip postprocessing and primary-data rebuild mechanisms |
| [Questie's own Forever TOC](https://github.com/Questie/Questie/blob/master/Questie_Camelot.toc) | Independently maintained current Interface 16001, Camelot naming and LoadSavedVariablesFirst conventions |
| [CMaNGOS Classic reference database](https://github.com/cmangos/classic-db/blob/ec4f596146be6467ea93c57397858e329e2db852/Full_DB/ClassicDB_1_12_1_z2815.sql.gz) | Reference material IDs, conditional quantities and Classic probability records only |
| [Lua 5.1.5 source distribution](https://www.lua.org/ftp/lua-5.1.5.tar.gz) | Local independent syntax/fixture execution environment |
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

## Evidence boundaries

The local source/API review supports the implementation choice. It does not prove that a particular Forever beta realm returns all intended auctions, that the client writes SavedVariables successfully, that the native UI lays out correctly, or that the DE model matches actual loot.

No Auctionator code, libraries, art or proprietary database was copied. Its general full-scan-and-tooltip product behavior was the user's feature reference. Runtime files are original code; game artwork/fonts are referenced from the installed client's standard resources.

MoobStack identity and packaging conventions were taken from the user's existing addon-development handoff, including prefix/naming, documentation, clean/source/Git ZIPs, bundles and checksum manifests. The earlier OctoWoW target was intentionally not carried over to this new Forever project.
