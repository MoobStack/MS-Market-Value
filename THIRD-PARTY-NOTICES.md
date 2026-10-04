# Source and license status

Original addon code, tests, tooling and documentation were prepared for MoobStack. **No software license has been selected for that original code.** The bundled libraries below have their own existing terms; those terms do not license the rest of this repository. Free distribution and visible source alone do not establish an open-source grant.

## Bundled libraries

| Component | Version | Terms | Location |
|---|---|---|---|
| LibAHTab | `LibAHTab-1-0`, minor 5 | MIT, Copyright (c) 2022 plusmouse | `MSMarketValue/Libs/LibAHTab/LibAHTab.lua`; full terms in `LICENSE.txt` beside it |
| LibStub | Minor 2 | Public-domain dedication and original author credits in source | `MSMarketValue/Libs/LibStub/LibStub.lua` |

Both are taken from [TheMouseNest/LibAHTab commit 2ddbec58](https://github.com/TheMouseNest/LibAHTab/tree/2ddbec58c8be37b2cd911bee7512d597e7dfdfe1). Only LF line endings and trailing whitespace were normalized. `tools/vendor.json` records the source and bundled SHA-256 hashes; validation checks the bundled bytes. The Clean ZIP includes library source, MIT terms and `Libs/NOTICE.txt`.

LibAHTab provides common modern AH tab coordination and explicitly handles Camelot. LibStub provides versioned shared-library registration. MS's scanner, pricing, loot model and settings logic are original code; no Auctionator scanner, art or price database is bundled.

## Inspected references

Blizzard UI/API definitions were inspected for compatibility. No extracted Blizzard Lua source, fonts, music or game binaries are bundled. Runtime icon, font and texture paths refer to client-supplied assets.

CMaNGOS Classic data was consulted for material IDs, probabilities and quantity facts. The package uses an original compact representation of those observations, labeled as unverified Classic estimates for Forever. It does not redistribute the SQL database, its executable code or its license as the addon's license.

The separately compiled development Lua interpreter and research downloads are not release assets. The addon requires no external executable or separately installed dependency addon.

If a license is selected for original MoobStack code or additional third-party assets are added, update notices and release documentation together. World of Warcraft and related marks belong to their respective owners; MoobStack has no Blizzard endorsement.
