# MS Market Value 1.2.0 beta

Build `2026-10-20-beta001` · Test revision **4**

- Service rows now show numeric quotes. Pricing adds labor, a minimum charge and customer-supplied materials.
- Crafting shows net profit/return after the configured AH cut and a break-even price. Deposits and expired listings remain separate.
- Watchlists save buy/return/profit targets, check stored scans/history and provide local alerts plus live-listing links.
- The personal ledger records manual transactions or a reviewed open AH invoice. It distinguishes unknown costs from zero, tracks costed sale profit, and supports edits, undo, retention and CSV copying.

Open **Pricing** in crafting, or use `/msmv watch` and `/msmv ledger`. The two money tools also open from Opportunities. Invoice import is a preview: open completed AH mail, review it and click Record entry. It never collects mail; similar invoices may require manual review.

**388/388 local Lua 5.1 tests pass.** Check pricing, watch targets and invoice amounts in Forever. Close WoW, replace the addon folder using the Clean ZIP and keep SavedVariables. All docs, tests and prior tags are included in the full Git repository.
