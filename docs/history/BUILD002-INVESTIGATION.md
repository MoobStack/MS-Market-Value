# Build002 investigation

User report: **MS Market Value 0.1.0-beta / 2026-10-04-beta001**, on **Forever 1.60.1 / 70205 / Interface 16001**.

## Observed evidence

The supplied diagnostics reported `API available: true`, `Tooltip callback installed: true`, `Addon disabled: no`, `Tooltip status: ready`, scan state `IDLE`, cooldown `0`, and no saved snapshot. Recent messages repeatedly said `Realm/region information is not available yet.` The user also reported that Auctionator could scan this client.

Build001 resolves a market before setting its cooldown or calling `C_AuctionHouse.ReplicateItems`. It accepts only a nonempty normalized realm and numeric region 1–10. The reported message comes from that gate. A missing/empty normalized realm or unusable region prevents a request even when every required auction function exists. Build001's diagnostic text did not reveal which lookup failed; the exact live return value remains unknown.

## Fix and requested UI change

Build002 checks accessible public values with guarded calls. A usable native normalized name and numeric region remain primary. A missing/empty normalized name falls back to the public realm name with spaces/hyphens removed. A missing/zero region falls back to the login portal. Recognized us/kr/eu/tw/cn portals use the existing numeric region keys. Other named portals retain separate keys. It never guesses from locale or merges another portal's prices.

If all usable identifiers are missing, scanning fails before the request/cooldown write with a specific reason. New diagnostics report each public lookup value, the selected market key/sources, session request count and tab status. A continued IDLE gate failure can be distinguished from a WAITING server-response failure.

The requested **MS Market Value** AH tab contains scan controls and scrolling settings. Opening the auctioneer leaves Buy selected and hides any manual MS window. `/msmv` selects/leaves the tab at an auctioneer and opens a manual window elsewhere. The automatic-popup preference is retired while its saved value is preserved for rollback.

LibAHTab minor 5 and LibStub minor 2 are bundled from pinned upstream sources. Their shared registry coordinates addon tabs without changing Blizzard's native tab indices. Original license/credit notices are included. A compatible library already loaded by another addon is reused.

## Verification and limits

All **63/63** local Lua 5.1 behavioral tests pass. Added cases prove the tested fallback scan sends one request and commits prices, preserve matching old keys, isolate named portals, retain old data on a market change and consume no request/cooldown when identity is unavailable. The actual bundled library is exercised against native-frame doubles and another addon-tab fixture.

No Forever client was operated during this fix. The supplied startup report is live user evidence for build001; it is not a build002 scan, visual layout, native taint, Auctionator coexistence or SavedVariables disk pass. Use [LIVE-TEST-CHECKLIST.md](../../LIVE-TEST-CHECKLIST.md) for retests. DE material probabilities and special eligibility remain Classic reference estimates unverified for Forever.

Primary review is recorded in [RESEARCH.md](../RESEARCH.md); provenance is in [THIRD-PARTY-NOTICES.md](../../THIRD-PARTY-NOTICES.md). Both builds retain **0.1.0-beta**, immutable build tags and schema 1.

## Later evidence

The subsequent build002 report establishes native region 90, one scan request reaching PROCESSING, AH tab installation and the next failures. Build003 revises region bounds, ruleset identity, comparison refresh and repeated-event handling. See [BUILD003-INVESTIGATION.md](BUILD003-INVESTIGATION.md). The statements above describe the evidence available when build002 was prepared.
