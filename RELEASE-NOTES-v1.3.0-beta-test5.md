# MS Market Value 1.3.0 beta — Test revision 5

Same version and build: `1.3.0-beta / 2026-11-15-beta001`.

- Limit Rarity to Poor, Common, Uncommon, Rare, Epic and Legendary, with matching text colors. Existing supported selections carry forward.
- Reuse the current variant index when filters change. Check keywords and supply limits before historical pricing, keep only the best 500 results, and finish searches before processing queued item-data refreshes.
- Keep modifier names accurate when the client initially supplies a generic name. Missing names load without requiring a hover.
- Fill reference gaps with this character's personal drop rates, including group and harvesting samples. Mark them personal; keep shared rates and sample counts separate.
- Document the checked Everloot export: 2,027 rates, 268 sources and about 40 KiB compressed. Loot modes remain unresolved, so it is a review dataset rather than an installable reference pack.

Close WoW and replace the addon folder using the Clean ZIP. Keep SavedVariables. Check `/msmv diagnostics` says **Test revision: 5**.

Test repeated keyword/rarity changes on the same scan, including `of the`, and compare exact modifiers with the Buy page. In Reference mode, check a source/item absent from the pack and confirm personal counts appear. This remains a beta; no official 1.3 release was published.
