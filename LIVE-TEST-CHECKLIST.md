# 1.2.0 beta checks

Build `2026-10-20-beta001`, Test revision **2**. Keep SavedVariables when replacing the addon folder. Record `/msmv diagnostics` with any error or unexpected result.

## Vendor costs

- Open a normal reagent supplier. Note a thread, dye, vial or flux price and bundle size.
- Select a recipe consuming it. Confirm quantity × purchase unit cost and the **vendor** label. AH markups should not affect it.
- Check the recipe list and quote. Another character should learn its own discount.
- Reload, reopen the profession and confirm the observation remains. Revisit after a discount change; unknown/expired supplies should say **visit supplier**.

## Opportunities

- Open the AH: **MS Opportunities** should precede **MS Market Value**, with the native Buy pane still selected initially.
- Switch among native, opportunities and settings tabs; check for overlap/clipped text. Test at your usual UI scale.
- Use a fresh scan and at least three earlier priced days for one item, or choose a two-day minimum if that is all you have. Today's repeat scans do not add days.
- Check Resale/Rising/Falling/All, sorting, pagination, selection details and saved filters. Compare one displayed price with its scan/history data.
- In Resale, set **Price move %** above an item's displayed drop and Apply: it should disappear. Lower it to the drop or below and recheck; other profit targets must still pass. A 500% drop should show no resale items. Set 0 to turn this check off.
- Set **Min profit (g)** to `0.25`: it means 25s. Move focus to another box and confirm the edit stays; Apply and reopen to check saving. Existing 500s targets should display as 5g.
- Adjust AH cut, minimum profit and return. Verify the per-item target buy price; deposits and unsold stock are excluded.
- Left-click a normal item, equipment variant and commodity. Confirm the native Buy listings match, then return to Opportunities. Right-click/hover should show details without switching tabs. Native filters still apply.
- Try a click while the AH is busy: it should ask for another click later. It must not queue a lookup or interfere with a full scan before its local copy completes.
- Reopen the unchanged page and inspect build/publication counts. It should reuse completed results. Close the AH and enter combat to confirm the pane hides.

## Existing behavior

- Confirm normal scanning, pause/resume after a complete local copy, combat tooltips and profession Show profits/Hide profits.
- Keep a history day across normal logout/relog/restart. Check UTC rollover when available.

For a layout issue, include a screenshot. For vendor math, include item/recipe, required quantity and vendor price/bundle size. For a market signal, include the item, filters and diagnostics. No need to reset saved prices or settings.
