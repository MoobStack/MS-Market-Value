# Source and testing

The Git Repository ZIP includes the source, tests, documentation and Git history. Extract it into a new folder and open `MS-Market-Value`. Install only the Clean ZIP's addon folder in WoW.

Development is on `develop/1.3.0`, tagged `v1.3.0-beta-test5`. The official release remains 1.2.1. Keep `1.3.0-beta / 2026-11-15-beta001` throughout testing and advance only the test revision.

Run `python3 tools/validate.py --lua lua5.1 --luac luac5.1` for checks, then `python3 tools/package.py` from the clean checkout at the annotated tag in build.json.

This beta is prepared locally. No changes were pushed and no official 1.3 release was created.
