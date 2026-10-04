# MS Market Value

MS Market Value saves a complete auction-house price snapshot and adds vendor, auction and estimated disenchant values to item tooltips. Stacked items show the value of each item and the whole hovered stack in one price block.

| Project detail | Value |
|---|---|
| Publisher | MoobStack |
| Addon folder | `MSMarketValue` |
| Version | `1.0.0` |
| Build | `2026-10-04-release001` |
| Annotated tag | `v1.0.0` |
| Target | WoW Forever 1.60.1 / 70205 / Interface 16001 |
| Dependencies | Bundled LibStub and LibAHTab; no separate addon installation |
| Validation | 90/90 local checks; build003 native PvP scan completed 104,763 rows |

## Changes in 1.0.0

- Vendor, AH and applicable **DE expected** prices share a compact block headed **Each / Stack (quantity)** when the hovered quantity is available and greater than one.
- Stack totals use that item's actual quantity and multiply the unrounded unit value before display rounding.
- A blank line separates prices from the disenchant material ranges, chances and expected quantities. Those material estimates remain per item.
- Existing build003 snapshots, settings, exclusions and cooldowns carry forward. No fresh scan is required solely for this update.
- The first stable release uses **1.0.0**. All three **0.1.0-beta** builds and their immutable tags remain in Git history.

See [CHANGELOG.md](CHANGELOG.md) for the complete history and [RELEASE-NOTES-v1.0.0.md](RELEASE-NOTES-v1.0.0.md) for this release.

## Install and use

1. With WoW closed, replace `Interface/AddOns/MSMarketValue` using the **Clean ZIP**. Use the AddOns folder of the Forever client you actually launch; the current beta client normally uses `_classic_beta_`.
2. Confirm `Interface/AddOns/MSMarketValue/MSMarketValue.toc` exists directly inside the addon folder. Preserve your WTF/SavedVariables files.
3. Restart WoW and enable **MS Market Value**.
4. Existing build003 prices are immediately usable. For a first scan or later refresh, open an auctioneer, select **MS Market Value**, and click **Scan entire AH** once when permitted.
5. Wait for **COMPLETE**. Use `/reload` or a normal logout/exit to let WoW save prices and settings.

| Command | Action |
|---|---|
| `/msmv` or `/msmarketvalue` | Select/leave the MS tab at an auctioneer; open/close settings elsewhere |
| `/msmv scan` | Request one complete scan at an open auctioneer |
| `/msmv stop` | Stop local processing and keep the last complete snapshot |
| `/msmv status` | Show scan state and snapshot age |
| `/msmv diagnostics` | Open copyable client, market and scan details |

The AH tab uses native Blizzard inset textures, fonts and controls. Opening an auctioneer keeps Buy selected without a settings popup. Scanning and tooltip calculations run outside combat.

## Read the tooltip

**Each / Stack (N)** identifies the two monetary values on each price row. Single items and contexts without a reliable quantity show **Each** only. An item link in chat does not acquire the count of an unrelated stack you own.

- **Vendor sell:** native sell price.
- **AH low:** lowest observed unit buyout in the latest complete snapshot; asking prices before fees.
- **AH low (item-wide):** labeled fallback across variants when the signed suffix has no exact price.
- **DE expected:** probability-weighted material value. Missing material prices make the full estimate unavailable; any priced portion is labeled separately.
- **Disenchant estimate:** per-item material quantity ranges, chances and expected quantities, separated from prices by a blank line. Outcomes are alternatives.

The DE model remains a **Classic reference estimate**. Forever-specific loot, exceptional eligibility and profession requirements are unverified and labeled. No item is automatically disenchanted. The user's successful build003 report supports the existing PvP scan behavior; the new 1.0.0 stack display still needs a native hover check.

## Documentation

| File | Purpose |
|---|---|
| [DOCUMENTATION.md](DOCUMENTATION.md) | Settings, prices, persistence and troubleshooting |
| [COMPATIBILITY.md](COMPATIBILITY.md) | Supported client/API target, restrictions and coverage limits |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Modules, scan lifecycle, quantity resolution and saved schema |
| [docs/DISENCHANT-MODEL.md](docs/DISENCHANT-MODEL.md) | Reference tables, assumptions and eligibility |
| [docs/RELEASE-1.0.0.md](docs/RELEASE-1.0.0.md) | Native baseline evidence and tooltip implementation |
| [docs/BUILD003-INVESTIGATION.md](docs/BUILD003-INVESTIGATION.md) | Earlier tooltip/scan fixes, ruleset caches and native styling |
| [docs/BUILD002-INVESTIGATION.md](docs/BUILD002-INVESTIGATION.md) | Earlier market lookup failure and first AH tab |
| [docs/RESEARCH.md](docs/RESEARCH.md) | Primary source links and provenance |
| [GIT-WORKFLOW.md](GIT-WORKFLOW.md) | Complete Git, GitHub, stable release, packaging and recovery workflow |
| [VALIDATION.md](VALIDATION.md) | Completed checks, native evidence and remaining coverage |
| [LIVE-TEST-CHECKLIST.md](LIVE-TEST-CHECKLIST.md) | Native checks for the exact release |
| [UPGRADE.md](UPGRADE.md) | Upgrade, backup and rollback |
| [ROADMAP.md](ROADMAP.md) | Follow-up client and loot-model work |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Development and reporting expectations |
| [GITHUB-RELEASE.md](GITHUB-RELEASE.md) | GitHub release description |

The intended repository is `MoobStack/MS-Market-Value`. A configured origin and local tag do not establish that GitHub publication has occurred.

MoobStack is an independent community addon publisher, unaffiliated with Blizzard Entertainment or any community server project. World of Warcraft and related marks belong to their owners.
