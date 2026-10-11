# Behavioral fixtures

Run from the repository root with Lua/luac 5.1:

```bash
python3 tools/validate.py --lua lua5.1 --luac luac5.1
```

Test revision 2 has **169 behavioral cases**. They load the actual runtime and bundled libraries against controlled native API/frame doubles. A hostile restricted-value sentinel detects accidental inspection, formatting, comparison and arithmetic.

Coverage includes atomic prices, suffixes, market isolation, DE estimates, schema/settings migration, saved-table round trips, real stack quantities, native AH tab coordination, combat decoration, copying/retry budgets, pause/resume and cooldown recovery, recipe arithmetic/selection, stable catalog publication and native-linked chat drafts. The new resume fixture includes 98,455 synthetic rows and a cleared native buffer.

Truly missing price fields remain pending. A separate fixture checks valid public price fields while cosmetic item data is unavailable; the native allInfo flag alone does not decide price readiness.

Fixtures do not contact auctions or a game client. Native APIs are replaced only in this test file, never in the shipped addon. Serialization checks do not prove WoW disk saving. Frame doubles do not render native art, establish taint behavior or prove recipe/market coverage. Use [LIVE-TEST-CHECKLIST.md](../LIVE-TEST-CHECKLIST.md) for those checks.
