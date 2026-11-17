# Validation

MS Market Value **1.3.1-beta, test revision 5** passed **924 Lua cases and 23 Python checks/workloads** using Lua 5.1 API/frame fixtures. Thirty-four new cases cover the watchlist revision.

Coverage includes search, header sorting, target-only filtering, ten reusable scrolling rows, rarity colors and separate target indicators, native Buy navigation, link-based creation, preserved watch scope, editing/removal and watch-specific settings.

Alert replays cover grouped reviews, optional chat, unchanged scans, repeat AH visits, saved-data reloads, price improvements, out-of-target/unlisted rearming and explicit dismissal. They also cover deferred delivery during combat, selling, purchase confirmation, typing and editing. An open watchlist updates without another foreground open. Alerts make no native auction search requests; explicit row clicks do.

The 200-watch UI workload performed 200 scrolls and 200 searches with no new frames, pricing publications or metadata reads during scrolling. Its largest measured scroll step was 2.23 ms in this run. These are fixture component timings, not native FPS or whole-addon memory measurements.

All 32 runtime Lua files pass syntax, load-order, identity and operation checks. Prior market, farming, session, crafting, ledger and Sell-arrow coverage remains included. Evidence and runtime hashes are in `evidence/TEST-1.3.1-5.json`; the complete local log is `evidence/TEST-1.3.1-5-validation.txt`.

The supplied test revision 4 diagnostics report installed Sell arrows, active farming rates with no ignored money messages, and two earlier exact-variant dates. The new watchlist appearance, direct navigation and alert timing on client 1.60.1 / 70959 still need native confirmation. Follow the [test notes](RELEASE-NOTES-v1.3.1-beta-test5.md).
