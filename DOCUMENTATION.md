# MS Market Value documentation

Version `0.1.0-beta`, build `2026-10-04-beta003`.

## Installation

Use the Clean ZIP for the game. Its top-level folder is `MSMarketValue`; copying that folder into the active Forever client's `Interface/AddOns` directory produces `AddOns/MSMarketValue/MSMarketValue.toc`. Do not install the outer `MS-Market-Value` repository directory as an addon.

The package includes identical fallback, `_Camelot`, and `_Forever` TOCs. The client selects the applicable TOC; these are alternative manifests for one addon, not three addons. The current verified metadata target is Interface 16001. Beta's usual game folder is `_classic_beta_`. Use the folder belonging to the client you actually start.

A newly added addon folder requires a client restart. Subsequent replacements of already known files can usually be followed by `/reload`.

## Full scans

Open an auctioneer, select the **MS Market Value** tab, and choose **Scan entire AH**. The addon sends one replication request, waits for `REPLICATE_ITEM_LIST_UPDATE`, and processes the entire returned zero-based row range. It does not loop through per-item search queries to enumerate the marketplace.

| State | Meaning |
|---|---|
| IDLE | No local scan is running |
| WAITING | One full-snapshot request was sent; awaiting the native response |
| PROCESSING | Reading the returned auction rows in bounded batches |
| RESOLVING | Waiting for incomplete item information and rechecking only those rows |
| COMPLETE | All rows were accounted for and the saved snapshot was replaced |
| CANCELLED | Local work stopped; prior complete prices remain |
| FAILED | Data, server response, context, or ownership checks failed; prior prices remain |

The previous snapshot stays authoritative while a scan is running. Commit occurs only after every returned row was processed. Prices absent from a complete new scan are removed from that market's snapshot. An explicit completed zero-row response saves an empty snapshot; a missing response cannot clear data.

The addon maintains a persistent **15-minute minimum interval** between replication requests. Cancelling, logging out, or reloading does not bypass this interval. Blizzard can impose additional cooldowns. A dropped or refused response can produce a timeout; open diagnostics and retain the previous prices until another permitted attempt.

Closing the auction house or entering combat cancels a scan. Additional replication events with the same readable row count preserve the scan's cursor and accepted rows, and can immediately wake pending item-data retries. They do not issue another request or restart accumulation. A changed/unreadable count, changed market, or another addon's replication request fails the staged scan and retains prior prices. The API exposes no scan generation token; stable-count handling plus request observation is the tested boundary. Only one full-scanning addon should run at a time.

## Prices

All tooltip monetary values are **per individual item**, in copper internally. For a listing of 10 items with a total buyout of 1 gold, the recorded unit price is 10 silver. Fractional unit copper values are retained during calculations, then rounded for display; positive values below one copper show `<1c`.

The AH value is the lowest buyout per unit in the latest completed replication snapshot. Bid-only auctions do not supply a buyout price. Sold rows do not contribute. This is a snapshot of asking prices, not a confirmed sale value, historical average, liquidity measurement, or guaranteed profit.

Signed random suffixes are indexed separately using `itemID:suffix`. Enchantments, gems, unique instance IDs and the viewer's level are not pricing keys. Where no matching suffix is available, the base item ID minimum is labeled **item-wide**. Retail bonus-list/upgrade-level valuation and battle-pet cage valuation are outside this Forever beta's scope.

| Tooltip result | Interpretation |
|---|---|
| Scan required | No complete local market snapshot is available |
| Not listed in scan | This item has no recorded buyout in the new snapshot |
| No buyout in scan | Only bid-only active listings were observed for this item |
| Item data loading | Native cached information needed for vendor/DE details is not ready |
| No vendor sale | Native sell price is zero |
| Stale | Snapshot exceeds the configured age threshold |

Stale data remains available and visibly dated by default. Age is based on the scan's request/start time rather than the later processing completion time.

## Disenchant estimates

The model uses native item level, quality, equipment class and subclass. Required character level is not substituted for item level. Uncommon armor and ordinary weapons have different reference outcome probabilities; wands use the dust-heavy reference treatment.

For each possible material, the tooltip shows a quantity range, outcome probability and expected quantity. For example, `1-2 (80%; avg 1.20)` means that outcome occurs with 80% probability in the reference model and supplies an expected 1.20 units per disenchant. You do not receive all listed alternative outcomes together.

The expected value is the sum of probability-weighted quantities times per-unit material buyout prices from the same snapshot. Each possible material needs a price. If one is missing, the total is **Unavailable** and any known subtotal is labeled **Priced portion only**. Prices are gross, before AH fees and listing costs.

The beta's loot model is a **Classic reference estimate**. It is not a verified Forever loot dataset. Standard gear eligibility is inferred from quality/class/equipment slot, not confirmed by a native disenchantability API. Item exceptions, new Forever materials, changed probabilities, and profession/skill requirements can invalidate an estimate. The addon does not claim your character can currently disenchant the item. Check the native profession behavior and use item exclusions for exceptions.

See [docs/DISENCHANT-MODEL.md](docs/DISENCHANT-MODEL.md) for complete bracket details. Items outside those brackets are labeled as having no profile rather than extrapolated.

## Auction House tab and manual settings window

| Setting/control | Default | Effect |
|---|---|---|
| Vendor sell price | On | Show native vendor sell value |
| Lowest AH buyout | On | Show current saved minimum buyout |
| Estimated disenchant value | On | Show eligible reference outcomes/value |
| Material ranges and chances | On | Show possible materials, ranges, probabilities, averages |
| Snapshot age and stale flag | On | Display snapshot age and stale marker |
| Mark prices stale after | 24 hours | Configurable integer, 1–168 hours |
| Exclude item | None | Suppress DE estimates for the entered numeric item ID |
| Restore estimate | — | Remove that item ID's exclusion |
| Stop scan | — | Stop local work and retain the complete snapshot |
| Copy diagnostics | — | Select diagnostic text for Ctrl+C |

Opening an auctioneer leaves the native Buy tab selected and adds an **MS Market Value** tab. Click it for scan controls above two settings columns. Native Blizzard inset textures/borders, fonts, buttons, checkboxes and inputs match the surrounding game frame. All settings fit without a settings scrollbar. Native tabs and other shared-library addon tabs hide the MS panel when selected. The AH tab is reused on subsequent openings.

`/msmv` selects the MS tab at an auctioneer; running it again returns to Buy. Away from an auctioneer, it opens a native portrait window whose position is saved account-wide. Diagnostics use a separate native portrait dialog with a scrolling copy field. Escape closes that window. No standalone settings window opens automatically. The former `openAtAH` preference remains stored for rollback but is ignored. Item exclusions can be reversed without changing the snapshot.

## Persistence and backup

`MSMarketValueDB` is an account-wide SavedVariable holding settings, exclusions, cooldown state and one replacement snapshot per market key. Forever is realmless: its reporting aliases are not treated as independent market realms when a ruleset can be detected.

| Identity | Cache behavior |
|---|---|
| Detected ruleset | `forever|<region>|<ruleset>|<faction>`; reporting-host number does not split the cache |
| PvP vs Normal/PvE | Separate `pvp` and `normal` snapshots |
| Hardcore | Native `C_GameRules.IsHardcoreActive` takes precedence |
| Normal/PvP/RP alias detection | Bounded `ClassicBeta`, `Forever` or `WoWForever` prefix plus recognized ruleset token and optional numeric host suffix; diagnostics label the alias-derived source |
| Unrecognized alias | Isolated `<region>|<alias>` fallback; diagnostics say ruleset undetected |
| Faction | Conservatively separate Horde/Alliance/Neutral caches until native cross-faction AH sharing is qualified |
| Old realm-keyed snapshot | Retained untouched; never automatically merged/promoted into the new ruleset cache |

For the reported `ClassicBetaPvP2`, native region `90` and Horde, the key is `forever|90|pvp|Horde`. A character reporting `ClassicBetaPvP1` in the same region/faction reads that cache. A Normal character does not read the PvP cache. Only the supplied PvP alias is live evidence; Normal/RP and other host aliases still need native confirmation. Unrecognized aliases remain safely isolated and can be reported for a later mapping update.

A positive native region identifier, including beta `90`, is preferred. An unavailable/zero region falls back to accessible modern/legacy login-portal values; us/kr/eu/tw/cn map to numeric regions and other named portals remain separate. Missing/empty normalized aliases fall back to the public name. Locale, PvP flags and Classic/Modern UI presets never select a ruleset. A missing usable identity blocks the request before consuming cooldown. See [UPGRADE.md](UPGRADE.md) for the fresh scan required when moving an old cache to this new namespace.

WoW writes SavedVariables on a successful UI reload or normal logout/exit. The addon cannot force an immediate disk write. A crash, interrupted shutdown, or client-side SavedVariables regression can lose changes made since the last successful write. `LoadSavedVariablesFirst: 1` is included, and initialization waits for the addon's `ADDON_LOADED` event.

Back up `WTF/Account/<account>/SavedVariables/MSMarketValueDB.lua` and its `.bak` if present while the client is closed. Back up your full WTF folder when moving installations. Do not place player data or account identifiers in the Git repository.

## Troubleshooting and reporting

Enable native script errors with `/console scriptErrors 1`, then reproduce the issue once. Copy `/msmv diagnostics`, the exact error text, client version/build, and addon build. For a material mismatch include item ID/link, item level, quality and actual loot. Diagnostics omit auction seller names and stored account credentials.

Install build003 for the build001 identity failure or build002 “replication buffer was refreshed” failure and `ShoppingTooltip1` first-hover error. IDLE with zero session requests means a request was not sent. Report the market key, ruleset/source, faction, reporting aliases, region/portal, event counts and exact failure. These are public market identifiers, not credentials.

Comparison tooltips still receive values through the native postprocessing callback. MSMV only requests refresh of readable getter-backed primary item tooltips; Blizzard owns comparison layout and rebuilding. A comparison may update with the next native comparison refresh/rehover.

If scan state remains WAITING, preserve the old snapshot and wait for the cooldown. If RESOLVING fails, report the state and exact client build. If saved prices disappear after reload, stop overwriting the backup and report the client-side persistence behavior. Do not install an external executable or SavedVariables workaround as part of this addon without a separate review.

An Interface number change or unavailable/restricted API requires a new compatibility review. Enabling “Load out of date AddOns” only changes loading metadata; it does not qualify runtime compatibility.
