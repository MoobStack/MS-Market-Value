# MS Market Value

MS Market Value saves a complete auction-house price snapshot and adds vendor sell prices, auction buyout prices, and estimated disenchant material values to item tooltips.

| Project detail | Value |
|---|---|
| Publisher | MoobStack |
| Addon folder | `MSMarketValue` |
| Public beta version | `0.1.0-beta` |
| Build | `2026-10-04-beta002` |
| Target | WoW Forever 1.60.1, Interface 16001 |
| Dependencies | Bundled LibStub and LibAHTab; no separate addon installation |
| Status | Revised beta candidate; 63 local tests pass; native scan/tab retest pending |

This is a separate modern-client addon. It does not extend or migrate the older Interface 11200 MS Auction addon.

---

## Changelog

### 0.1.0-beta — build002 — 2026-10-04 UTC

- Fixed the pre-request market lookup failure: missing/empty normalized realm names fall back to the public realm name; unavailable/zero regions fall back to the login portal.
- Added a new **MS Market Value** Auction House tab with scan controls and scrolling settings. Opening an auctioneer keeps the native Buy tab selected and no longer opens the standalone settings window.
- Bundled LibAHTab and LibStub for shared addon-tab coordination; no separate dependency installation is required.
- Added realm/region lookup values, lookup sources, tab status, and session request count to diagnostics.
- Retained the same primary beta version, schema, completed snapshots, and immutable build001 tag. All **63/63** local behavioral tests pass; native scan/tab retest remains pending.

All revisions before the first finalized release remain **0.1.0-beta**. Build identifiers and immutable build tags distinguish revisions. See [CHANGELOG.md](CHANGELOG.md).

---

## Documentation

### Install and use

1. Extract the **Clean ZIP** into the active Forever client's `Interface/AddOns` folder. During beta this is normally `World of Warcraft/_classic_beta_/Interface/AddOns`.
2. Confirm `Interface/AddOns/MSMarketValue/MSMarketValue.toc` exists directly inside the addon folder.
3. Restart WoW and enable **MS Market Value**.
4. Open an auctioneer, select the new **MS Market Value** tab, then click **Scan entire AH**. Opening the auctioneer does not open a settings popup.
5. Wait for **COMPLETE**. Hover items to see prices and eligible reference disenchant estimates.
6. Use `/reload` or log out normally to let WoW write saved data to disk.

| Command | Action |
|---|---|
| `/msmv` or `/msmarketvalue` | Select/leave the MS tab at an auctioneer; open/close a manual window elsewhere |
| `/msmv scan` | Request one full-house scan at an open auctioneer |
| `/msmv stop` | Cancel local processing and keep the last complete snapshot |
| `/msmv status` | Show scan state and saved snapshot age |
| `/msmv diagnostics` | Open text that can be copied into a beta report |

Every normal option is available in the AH tab and the manually opened window. The tab has a vertical scrollbar for its lower settings. Scanning and tooltip calculations run outside combat.

### How to interpret the tooltip

- **Vendor sell:** the native sell price for one item.
- **AH low:** the lowest observed buyout per unit from the last complete scan. These are asking prices, before auction fees.
- **Item-wide:** the fallback minimum across variants sharing the item ID. It is labeled when a matching signed suffix is unavailable.
- **DE material:** a possible outcome with a quantity range, chance, and probability-weighted average quantity. The possible outcomes are alternatives.
- **DE value:** the sum of each material's expected quantity multiplied by its current snapshot price. Missing material prices make the complete value unavailable; a priced subtotal is labeled separately.

**Disenchant data limitation:** This beta uses a **Classic reference estimate**, not a verified Forever loot table. Special item eligibility, revised materials, probabilities, and quantity distributions require live evidence. The tooltip states this limitation. No item is automatically disenchanted.

### Project references

| File | Purpose |
|---|---|
| [DOCUMENTATION.md](DOCUMENTATION.md) | Features, settings, prices, persistence and troubleshooting |
| [COMPATIBILITY.md](COMPATIBILITY.md) | Client/API target, Blizzard policy design, restrictions and limits |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Modules, scan lifecycle and saved-data schema |
| [docs/DISENCHANT-MODEL.md](docs/DISENCHANT-MODEL.md) | Reference tables, formula and eligibility limits |
| [docs/BUILD002-INVESTIGATION.md](docs/BUILD002-INVESTIGATION.md) | Reported failure, fix and evidence limits |
| [docs/RESEARCH.md](docs/RESEARCH.md) | Primary sources and research provenance |
| [GIT-WORKFLOW.md](GIT-WORKFLOW.md) | Full local Git, GitHub, beta revision, packaging and recovery workflow |
| [VALIDATION.md](VALIDATION.md) | Completed checks and pending live checks |
| [LIVE-TEST-CHECKLIST.md](LIVE-TEST-CHECKLIST.md) | First-client qualification steps |
| [UPGRADE.md](UPGRADE.md) | Beta updates, backups and rollback |
| [ROADMAP.md](ROADMAP.md) | Work remaining before a finalized release |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Development and bug-report expectations |
| [GITHUB-RELEASE.md](GITHUB-RELEASE.md) | Prepared beta release description |
| [RELEASE-NOTES-v0.1.0-beta.md](RELEASE-NOTES-v0.1.0-beta.md) | Current beta release notes |

The intended repository is `MoobStack/MS-Market-Value`. An origin URL in the supplied local repository is a configured destination, not evidence that the repository or a release has been created on GitHub.

MoobStack is an independent community addon publisher. These addons are not affiliated with, authorized by, or endorsed by Blizzard Entertainment or any community server project. World of Warcraft and related marks are the property of their respective owners.
