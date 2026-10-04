# Compatibility and policy design

## Reviewed target

| Attribute | Build001 target |
|---|---|
| Game | World of Warcraft: Forever beta |
| Client version | 1.60.1 |
| Interface | 16001 |
| Reviewed UI source | Blizzard UI mirror `forever`, 1.60.1 build 70205 |
| Reviewed source commit | `e3ecc27b64d30fdc735a3f6579b866858f9f9df1` |
| Lua validation | Lua 5.1.5 |
| Live-client qualification | Pending |

Forever uses a modern client API despite level-60 content. This addon targets that environment; the old MoobStack Interface 11200 client target does not apply to this project. Modern Retail, Classic Era, older private-server clients and later unreviewed Interface versions are not qualified targets for build001.

All three TOCs advertise Interface 16001. The `_Camelot` suffix corresponds to current Forever package conventions; the `_Forever` and unsuffixed copies provide equivalent naming alternatives. Including those manifests does not qualify a different API version. Runtime checks require the reviewed Interface number, restricted-value detection and the required modern auction functions.

## Full-house scan API

The reviewed Blizzard-generated `AuctionHouseDocumentation.lua` directs full-house enumeration to `C_AuctionHouse.ReplicateItems`. Its `SendSearchQuery` documentation explicitly discourages using repeated item searches to enumerate the entire AH. Build001 follows the replication path and completion event.

No legacy `QueryAuctionItems` scanner, fabricated browse completion, repeated full-scan retry loop or cooldown override is included. Reading is batched; a persistent minimum request interval controls load. Completion means all rows exposed in the native replication response were accounted for. Actual Forever coverage, including listed enchanting materials, must be checked in the client.

## Tooltip/restricted data handling

- Item decoration uses `TooltipDataProcessor.AddTooltipPostCall` for the native item type.
- Only registered accessible public tooltips are decorated; forbidden tooltips are skipped.
- `issecretvalue`, and `canaccessvalue` where available, are checked before using input values.
- Secret inputs are not converted, inspected, compared, formatted, stored or calculated with.
- Scanning and tooltip calculations stop/suppress their work in combat.
- Native item and auction data is accessed using ordinary validated inputs.
- No combat analytics, aura reads, combat-log computation, protected interaction or automatic chat communication is used.

These are conservative design choices, not a Blizzard approval or a guarantee that all future client updates permit the same APIs. An unavailable/changed/restricted function is a compatibility issue to report, not a reason to bypass its restriction.

## Blizzard addon policy alignment

The implementation is designed around Blizzard's published UI Add-On Development Policy: free distribution and visible source, reasonable client/server load, no advertisements or in-game donation solicitation, appropriate content and normal game API boundaries. The project does not include premium features, an executable companion, external networking or hidden code.

Blizzard retains control over available addon functionality. The reviewed policy is linked in [docs/RESEARCH.md](docs/RESEARCH.md). No claim of legal certification or official endorsement is made.

## Persistence

TOCs declare account-wide `MSMarketValueDB` and `LoadSavedVariablesFirst: 1`. Initialization additionally waits for the matching ADDON_LOADED event. Disk writes use the client's standard SavedVariables lifecycle. The addon has no filesystem-writing API and cannot repair a client loader or persistence regression.

Native reload, relog, character switch and full-exit/restart checks remain mandatory live tests. In particular, a passing mocked serialization test is not evidence that the current beta client successfully saves addon data on a specific operating system/account.

## Disenchant model qualification

The default model is explicitly a Classic reference. No reviewed native API exposes a complete Forever-specific disenchant loot probability table to this addon. Class/quality/equipment slot only estimate standard eligibility. Player profession capability and individual exceptions are not guaranteed.

New Forever items/materials or changed drop rates must be modeled from new evidence before they can be represented as verified. Keep the label and exclusions until that evidence exists. [docs/DISENCHANT-MODEL.md](docs/DISENCHANT-MODEL.md) explains the bounds.

## Update response

For a new client build with unchanged Interface, rerun affected live checks and compare the API surface if behavior changes. For a new Interface number, review the actual UI/API definitions before updating metadata and the runtime gate together. Maintain the primary public beta version while advancing the build ID. Do not mark a client qualified based solely on a TOC edit.
