# 1.1.0 release evidence

The user reports Test revision 4 functioning properly and requests the official 1.1.0 release. The stable package uses that runtime with release metadata and no beta test-revision label.

| Supplied diagnostic | Value |
|---|---|
| Tested addon | `1.1.0-beta / 2026-10-11-beta001`, revision 4 |
| Client | `1.60.1 / 70338 / Interface 16001` |
| Market | `forever|110|pvp|Horde` |
| Saved prices | Complete; 96,590 rows; 3,179 priced items; no bid-only or sold rows |
| Snapshot request UTC | `2026-10-11T18:53:05Z` |
| Scan at capture | IDLE; no full-scan requests in this session |
| Tooltip | Callback installed; ready; addon enabled |
| Crafting | Catalog ready; recipe 2964 valuation complete; native link available |
| Catalog builds / publications | 1 / 1 |
| History | One UTC day, 2026-10-11; retention 30 days |
| Auto-open / list filter | Off / profitable only |
| Toggle / crafting window | Hidden at capture; text alone does not prove visual fit |

Earlier feedback reports successful revision 2 resumes under multiple conditions. Local release validation passes **239/239 Lua 5.1 cases**, including beta-to-stable data retention, daily history and native header layering.

The report confirms saved prices, a craft valuation and a retained daily entry in this session. It does not establish every recipe/ruleset, multi-day rollover, 30-day retention in the game, a dedicated history disk round-trip or verified Forever disenchant loot. Those remain in [LIVE-TEST-CHECKLIST.md](../LIVE-TEST-CHECKLIST.md).

Release identity is **1.1.0 / 2026-10-11-release001**, tag `v1.1.0`, schema 1. Existing prices, history and settings are retained. Packaging and remote-publication checks are separate; see [VALIDATION.md](../VALIDATION.md) and [GIT-WORKFLOW.md](../GIT-WORKFLOW.md).
