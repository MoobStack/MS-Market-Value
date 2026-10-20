# MS Market Value 1.2.0 beta

Build `2026-10-20-beta001` · Test revision **7**

- Track completed player-trade gold as **Tips received** and **Tips given**, with separate filters and report totals. Cancelled/incomplete trades do not count. Tracking can be disabled in Ledger settings.
- Fix missed filter clicks by keeping the active panel visible during refresh. Filters apply immediately.
- Replace the transaction editor’s cycling Type button with a native dropdown.
- Use local time for ledger rows, dates and retention, including daylight-saving changes. Keep saved timestamps and UTC market history intact; CSV includes both local and UTC time.

Trade gold starts as a tip because the game does not identify its purpose. Reclassify craft payments as Commission rather than recording them twice. Incoming cost stays unknown until entered; use 0 for a pure tip.

**504/504 local Lua 5.1 tests pass**, including DST checks and a regression that reproduces the old panel-hiding problem. Trade event ordering and menu behavior still need a live Forever check.

Close WoW, replace the addon folder using the Clean ZIP and keep SavedVariables. The full repository includes all documentation and earlier tags.
