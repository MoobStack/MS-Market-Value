# Beta upgrades, backup and rollback

The installed folder and SavedVariable names remain `MSMarketValue` and `MSMarketValueDB` throughout this beta. Public version remains 0.1.0-beta; build IDs identify individual revisions.

## Update

1. Finish or stop any running scan and close WoW normally.
2. Back up `WTF/Account/<account>/SavedVariables/MSMarketValueDB.lua` and its `.bak` if present. Keep a copy of the current Clean ZIP.
3. Replace the existing `Interface/AddOns/MSMarketValue` folder with the new Clean ZIP's `MSMarketValue` folder. Preserve your WTF folder.
4. Start WoW; open diagnostics and verify the new **build ID**, not only the unchanged beta version.
5. Check saved prices/settings and rerun the live checks relevant to the revision.

Do not mix Lua files from two builds. Do not install the source/Git repository directory inside AddOns. No legacy migration bridge or separate Update ZIP is required for this new addon.

## Build001 to build002

Schema remains 1. Existing completed market snapshots, settings, item exclusions and cooldown timestamps are retained. No fresh database or rescan is required solely for the code upgrade. Numeric native/recognized-portal keys reuse the existing market; a distinct named test portal intentionally has its own snapshot.

After installing build002, open an auctioneer and click the new **MS Market Value** tab. The old automatic-popup setting is retained for rollback but no longer acts. `/msmv` opens a manual window away from the AH. Use the vertical scrollbar to reach the lower settings. Diagnostics include the public realm/region lookup fields needed for the scan retest.

## Roll back

With WoW closed, replace the addon folder using the previous Clean ZIP. If the new revision changed the saved schema, restore the matching SavedVariables backup too. Never restore a saved-data file while WoW is open; the client's subsequent save can overwrite it.

Both builds refuse future schema numbers and preserves the loaded variable. It does not silently downgrade a future database or delete it. The documented schema is version 1; any future migration must be reviewed and tested separately.

## Move installations

Copy the addon folder into the new client's AddOns directory and transfer the matching account SavedVariables/WTF backup while both clients are closed. Character/account naming and current beta client persistence behavior must be tested on the new installation. Code backups alone do not contain personal price snapshots.

The Git Repository ZIP and bundle restore source/history. The Clean ZIP restores the installed addon. The account SavedVariables backup restores scanned data/settings. Keep these distinct backups together with their build/checksum identities.
