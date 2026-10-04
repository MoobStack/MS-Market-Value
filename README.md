# MS Market Value

MS Market Value saves a complete auction-house price snapshot and adds vendor sell prices, auction buyout prices, and estimated disenchant material values to item tooltips.

| Project detail | Value |
|---|---|
| Publisher | MoobStack |
| Addon folder | `MSMarketValue` |
| Public beta version | `0.1.0-beta` |
| Build | `2026-10-04-beta001` |
| Target | WoW Forever 1.60.1, Interface 16001 |
| Dependencies | None |
| Status | Initial beta candidate; headless tests pass; live-client testing pending |

This is a separate modern-client addon. It does not extend or migrate the older Interface 11200 MS Auction addon.

---

## Changelog

### 0.1.0-beta — build001 — 2026-10-04 UTC

- Added user-started, full-house scans through `C_AuctionHouse.ReplicateItems()`.
- Added account-wide saved data with separate realm/region snapshots.
- Complete scans replace the previous snapshot; incomplete scans preserve it.
- Added per-item vendor sell and lowest auction buyout prices, stack normalization, signed-suffix lookup, and scan age/stale indicators.
- Added reference disenchant outcomes by item level, quality, and equipment class, with material quantity ranges, probabilities, expected quantities, and expected auction value.
- Added settings, item exclusions, scan progress, cancellation, and copyable diagnostics.
- Added modern tooltip callbacks, restricted-value guards, combat gating, Git documentation, behavioral tests, and reproducible runtime/source archives.

All revisions before the first finalized release remain **0.1.0-beta**. Build identifiers and immutable build tags distinguish revisions. See [CHANGELOG.md](CHANGELOG.md).

---

## Documentation

### Install and use

1. Extract the **Clean ZIP** into the active Forever client's `Interface/AddOns` folder. During beta this is normally `World of Warcraft/_classic_beta_/Interface/AddOns`.
2. Confirm `Interface/AddOns/MSMarketValue/MSMarketValue.toc` exists directly inside the addon folder.
3. Restart WoW and enable **MS Market Value**.
4. Open an auctioneer, then click **Scan entire AH** in the addon window. `/msmv` also opens the window.
5. Wait for **COMPLETE**. Hover items to see prices and eligible reference disenchant estimates.
6. Use `/reload` or log out normally to let WoW write saved data to disk.

| Command | Action |
|---|---|
| `/msmv` or `/msmarketvalue` | Open/close the settings and scan window |
| `/msmv scan` | Request one full-house scan at an open auctioneer |
| `/msmv stop` | Cancel local processing and keep the last complete snapshot |
| `/msmv status` | Show scan state and saved snapshot age |
| `/msmv diagnostics` | Open text that can be copied into a beta report |

Every normal option is also available in the window. Scanning and tooltip calculations run outside combat.

### How to interpret the tooltip

- **Vendor sell:** the native sell price for one item.
- **AH low:** the lowest observed buyout per unit from the last complete scan. These are asking prices, before auction fees.
- **Item-wide:** the fallback minimum across variants sharing the item ID. It is labeled when a matching signed suffix is unavailable.
- **DE material:** a possible outcome with a quantity range, chance, and probability-weighted average quantity. The possible outcomes are alternatives.
- **DE value:** the sum of each material's expected quantity multiplied by its current snapshot price. Missing material prices make the complete value unavailable; a priced subtotal is labeled separately.

**Disenchant data limitation:** build001 uses a **Classic reference estimate**, not a verified Forever loot table. Special item eligibility, revised materials, probabilities, and quantity distributions require live evidence. The tooltip states this limitation. No item is automatically disenchanted.

### Project references

| File | Purpose |
|---|---|
| [DOCUMENTATION.md](DOCUMENTATION.md) | Features, settings, prices, persistence and troubleshooting |
| [COMPATIBILITY.md](COMPATIBILITY.md) | Client/API target, Blizzard policy design, restrictions and limits |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Modules, scan lifecycle and saved-data schema |
| [docs/DISENCHANT-MODEL.md](docs/DISENCHANT-MODEL.md) | Reference tables, formula and eligibility limits |
| [docs/RESEARCH.md](docs/RESEARCH.md) | Primary sources and research provenance |
| [GIT-WORKFLOW.md](GIT-WORKFLOW.md) | Full local Git, GitHub, beta revision, packaging and recovery workflow |
| [VALIDATION.md](VALIDATION.md) | Completed checks and pending live checks |
| [LIVE-TEST-CHECKLIST.md](LIVE-TEST-CHECKLIST.md) | First-client qualification steps |
| [UPGRADE.md](UPGRADE.md) | Beta updates, backups and rollback |
| [ROADMAP.md](ROADMAP.md) | Work remaining before a finalized release |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Development and bug-report expectations |
| [GITHUB-RELEASE.md](GITHUB-RELEASE.md) | Prepared beta release description |
| [RELEASE-NOTES-v0.1.0-beta.md](RELEASE-NOTES-v0.1.0-beta.md) | Build001 release notes |

The intended repository is `MoobStack/MS-Market-Value`. An origin URL in the supplied local repository is a configured destination, not evidence that the repository or a release has been created on GitHub.

MoobStack is an independent community addon publisher. These addons are not affiliated with, authorized by, or endorsed by Blizzard Entertainment or any community server project. World of Warcraft and related marks are the property of their respective owners.
