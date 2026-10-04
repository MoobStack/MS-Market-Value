# Upgrades, backup and rollback

The installed folder and SavedVariable names remain `MSMarketValue` and `MSMarketValueDB`. The first stable version is **1.0.0**, build `2026-10-04-release001`; database schema remains 1. All earlier revisions remain in the 0.1.0-beta history.

## Update

1. Finish or stop any running scan and close WoW normally.
2. Back up `WTF/Account/<account>/SavedVariables/MSMarketValueDB.lua` and its `.bak` if present. Keep a copy of the current Clean ZIP.
3. Replace the existing `Interface/AddOns/MSMarketValue` folder with the new Clean ZIP's `MSMarketValue` folder. Preserve your WTF folder.
4. Start WoW; open diagnostics and verify **version 1.0.0** and **build 2026-10-04-release001**.
5. Check saved prices/settings and rerun the live checks relevant to the revision.

Do not mix Lua files from two builds. Do not install the source/Git repository directory inside AddOns. No legacy migration bridge or separate Update ZIP is required for this new addon.

## Upgrade from build003 to 1.0.0

No fresh scan, database reset or SavedVariables deletion is required. Version 1.0.0 keeps build003's market namespace, schema, completed prices, settings, exclusions, saved window position and cooldown. Replace only the addon folder and preserve WTF. Hover a known stack to verify **Each / Stack (N)**, the grouped vendor/AH/DE prices and the blank line before per-item DE materials. Quantity is read from the current hover context and is not saved.

If upgrading directly from build001/build002, the older namespace transition below still applies; a successful scan under the detected ruleset key is required. A build003 snapshot already under that key is immediately usable.

## Historical upgrade to build003

Schema remains 1. Settings, exclusions, window position, cooldown and old completed records are preserved. Detected Forever markets now use `forever|region|ruleset|faction`. The prior `portal:test|ClassicBetaPvP2` key is not copied or merged into the new cache; native region 90 is now accepted directly. **One fresh successful scan is required for the new ruleset key.** The old records remain stored for rollback and are never substituted for another ruleset's prices.

On the reported PvP alias, diagnostics should show ruleset `pvp`, its alias-derived source, native region `90` and your faction. A host-number change within that region/ruleset/faction keeps the same cache. Normal/PvE stays separate. An unrecognized alias remains isolated and should be reported rather than manually merged. Faction caches stay separate until AH pooling is verified.

Select **MS Market Value** at an auctioneer. Scan controls and the two settings columns now use native Blizzard inset frames, and all options fit without a settings scrollbar. The manual window and diagnostics have native portrait frames. Keep the existing cooldown, scan once when permitted, and retest first-hover comparison tooltips with script errors enabled.

## Earlier build001 to build002 change

Schema remains 1. Existing completed market snapshots, settings, item exclusions and cooldown timestamps are retained. No fresh database or rescan is required solely for the code upgrade. Numeric native/recognized-portal keys reuse the existing market; a distinct named test portal intentionally has its own snapshot.

After installing build002, open an auctioneer and click the new **MS Market Value** tab. The old automatic-popup setting is retained for rollback but no longer acts. `/msmv` opens a manual window away from the AH. Use the vertical scrollbar to reach the lower settings. Diagnostics include the public realm/region lookup fields needed for the scan retest.

## Roll back

With WoW closed, replace the addon folder using the previous Clean ZIP. If the new revision changed the saved schema, restore the matching SavedVariables backup too. Never restore a saved-data file while WoW is open; the client's subsequent save can overwrite it.

These releases refuse future schema numbers and preserve the loaded variable. They do not silently downgrade a future database or delete it. The documented schema is version 1; any future migration must be reviewed and tested separately.

## Move installations

Copy the addon folder into the new client's AddOns directory and transfer the matching account SavedVariables/WTF backup while both clients are closed. Character/account naming and current beta client persistence behavior must be tested on the new installation. Code backups alone do not contain personal price snapshots.

The Git Repository ZIP and bundle restore source/history. The Clean ZIP restores the installed addon. The account SavedVariables backup restores scanned data/settings. Keep these distinct backups together with their build/checksum identities.
