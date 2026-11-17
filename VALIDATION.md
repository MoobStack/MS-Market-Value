# Validation

MS Market Value **1.3.1-beta, test revision 4** passed **890 Lua cases and 23 Python checks/workloads** with Lua 5.1 API/frame fixtures. Thirteen new cases cover the Sell-page arrow controls.

The checks cover one-copper changes in both sell modes, silver/gold carry and borrow, zero and gold-field limits, quantity preservation, updated totals, keyboard edits, lazy frame creation and AH reopening without duplicate controls. Hidden, disabled, forbidden or unreadable fields remain unchanged. The runtime operation check confirms no auction-posting calls were added.

A separate replay used the actual shared price/money setter functions from the native UI source. It passed denomination rollover, clearing zero and callback-driven total updates. That replay adds one integration check; its other thirteen cases repeat the new regressions. It does not render the game or establish compatibility with every native UI build.

All 31 runtime Lua files pass syntax, load-order and identity checks. Larger market, session-storage, farming, crafting and ledger workloads passed. Earlier price-history and farming fixes remain covered. Results, source URLs and runtime hashes are in `evidence/TEST-1.3.1-4.json`; logs are alongside it.

The supplied test revision 3 diagnostics report two earlier exact-variant dates and no modified matches with three earlier dates. The combat report shows recent/peak rates and zero ignored money messages. These are reported in-game observations, separate from the local test results.

Native arrow appearance, warning placement and behavior on client 1.60.1 / 70959 still need confirmation. Follow the [test notes](RELEASE-NOTES-v1.3.1-beta-test4.md).
