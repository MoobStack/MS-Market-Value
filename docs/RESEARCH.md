# Source notes

Implementation was reviewed against pinned client UI/API source, then checked with local Lua fixtures and user-supplied Forever results. A source contract does not prove every live event ordering or server behavior.

| Source | Use |
|---|---|
| [Forever 1.60.1 / 70450](https://github.com/Gethe/wow-ui-source/tree/172a387e3ab85b26e6640d3058d5ec1e6ccd4c63) | Current AH, merchant, profession, mail, trade, money and menu contracts |
| [Forever 1.60.1 / 70338](https://github.com/Gethe/wow-ui-source/tree/943764493e6b16d63ded3ab304150d1f05e58b57) | 1.1.0 profession header and scan-resume review |
| [Forever 1.60.1 / 70205](https://github.com/Gethe/wow-ui-source/tree/e3ecc27b64d30fdc735a3f6579b866858f9f9df1) | Original replication, tooltip and stack-quantity implementation |
| [LibAHTab / LibStub](https://github.com/TheMouseNest/LibAHTab/tree/2ddbec58c8be37b2cd911bee7512d597e7dfdfe1) | Bundled tab coordination and dependencies; hashes in tools/vendor.json |
| [CMaNGOS Classic database](https://github.com/cmangos/classic-db/blob/ec4f596146be6467ea93c57397858e329e2db852/Full_DB/ClassicDB_1_12_1_z2815.sql.gz) | Classic DE reference only; not verified Forever probabilities |
| [Blizzard addon policy](https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534/1) | Distribution and addon behavior |

Useful build-70450 files include the generated AuctionHouse/TradeSkillUI API definitions, native AuctionHouse frames, MerchantFrame.lua, MailFrame.lua, GameDialogDefs.lua, Trainer UI, TaxiFrame.lua and MenuTemplates.lua. They establish readable native fields, action callbacks and menu behavior.

Daily grouping, history averages, conservative resale baselines, expense matching windows and invoice deduplication are addon policies. No reviewed API supplies guaranteed sale demand, original invoice dates or a complete durable transaction identity. Generic wallet increases are not called loot, and quotes alone do not create expenses.

Detailed earlier investigations are in [development history](history/README.md) and original Git tags. [Validation](../VALIDATION.md) distinguishes local checks from native observations.
