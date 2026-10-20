# 1.2.0 beta checks

Build `2026-10-20-beta001`, Test revision **5**. Keep SavedVariables when replacing the addon folder. Record `/msmv diagnostics` with any error or unexpected result.

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

## Crafting layout

- Open a normal item recipe and a direct enchant. Item recipes should show net profit/return and a break-even price; services should show material cost and a numeric quote, with no auction-only fields.
- Check **Recipe list** at normal UI scale. Search a partial name, change sorting and toggle Show all recipes. Searching should not raise catalog build counts. Switch professions and confirm the search clears.
- Hover a long recipe name for full details, then click it to select the native recipe. Quote-only services should not count as missing price data.
- Check material quantities, AH/vendor sources and line totals. Visit a supplies vendor first if diagnostics still show zero purchase prices.
- Change markup and confirm the linked quote updates. Copying and Insert in chat should retain their existing behavior.

## Existing behavior

- Confirm normal scanning, pause/resume after a complete local copy, combat tooltips and profession Show profits/Hide profits.
- Keep a history day across normal logout/relog/restart. Check UTC rollover when available.

For a layout issue, include a screenshot. For vendor math, include item/recipe, required quantity and vendor price/bundle size. For a market signal, include the item, filters and diagnostics. No need to reset saved prices or settings.


## Pricing, watchlists and commissions

- Check net crafting profit/break-even and labor/minimum/customer-material quotes against Pricing. Numeric service quotes should remain in recipe rows.
- On both a normal item's and a commodity's native Buy page, click **Watch item**. Set/save targets, reopen it and confirm the values remain. Check a random-suffix item too.
- Save a watch away from the AH and test View listings at an auctioneer. Reopening an unchanged scan should not repeat its alert.
- Under Craft quote, leave price blank, quantity 1 and tip 0; Record sale should immediately add one Commission using the quote. Try an explicit 2g price, quantity 3 and 25s total tip: income should be 6g 25s.
- Test fixed multi-item output, a service with your materials and customer-material mode. Estimated costs/profit should say Est.; customer-material own cost should be 0. Enter actual cost to replace an estimate.

## Automatic AH tracking

- Buy a normal item/stack: confirm exactly one AH buy with the actual total and quantity. A cancelled confirmation, unsuccessful buy or ordinary bid must not create a purchase.
- Buy a commodity across multiple price levels. Compare the final server total, not just first unit price. Try a price increase and a failed purchase.
- Collect the purchase mail. The existing purchase should reconcile instead of duplicating. Reload between purchase and mailbox collection and repeat the check.
- Open completed seller mail, including a sale made while logged out. Check gross amount, fee and quantity; returned deposit must not increase income/profit. Pending sale notices must not count.
- Test repeated mailbox opens, reordering, multiple identical invoices and fast Open All/collection. An unread old purchase should backfill once. Note identical invoices removed/replaced close together as an API ambiguity case; compare against native totals.
- Delete/undo a recorded invoice and reopen mail. It should not be imported again. Tracking must not collect, delete or return mail itself.

## Vendor trades and reports

- Buy a reagent bundle, sell a known stack, sell several items quickly, and buy one back. Compare bag quantities and exact wallet changes with individual Vendor buy/sale entries.
- Try a failed purchase, repair, bag move and unrelated wallet change. They must not become vendor trades. Unsupported/currency/refund cases may require manual entry and should not invent values.
- Filter AH sales, AH buys, commissions, vendor sales and vendor buys separately. Test Today, 7 days, 30 days and a one-day custom UTC range. Reports and CSV should use the same rows.
- Compare income, spending and cash flow separately from known P/L and estimated craft P/L. A sale without cost should say Needed, with no assigned profit.
- Check type/date columns and separate commission controls at normal UI scale, including long names and larger gold amounts.
- Disable AH/vendor tracking independently, then re-enable. Reload/relog and check preferences, watches, cost bases, entries and duplicate protection.

Back up SavedVariables before shortening retention. For a tracking problem, include diagnostics, transaction type, quantity/total, native confirmation/mail details, and whether another mailbox/AH addon was active.
