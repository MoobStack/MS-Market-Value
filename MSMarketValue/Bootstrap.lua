local addonName, A = ...

A.NAME = addonName or "MSMarketValue"
A.TITLE = "MS Market Value"
A.VERSION = "1.0.0"
A.BUILD = "2026-10-04-release001"
A.SCHEMA = 1
A.INTERFACE = 16001
A.SCAN_COOLDOWN = 900
A.REQUEST_TIMEOUT = 120
A.RESOLVE_TIMEOUT = 45
A.MAX_ROWS = 1000000
A.BATCH_SIZE = 100
A.FRAME_BUDGET_MS = 4
A.log = {}

-- One intentionally named public namespace; no Blizzard globals are replaced.
_G.MSMarketValue = A
