# Vendor material costs

Open a supplies vendor to learn the purchase prices offered to your character. No purchase is needed. The addon records the displayed gold price divided by the bundle quantity, so reputation discounts and stacks are included.

Crafting materials then show **vendor** beside their cost. That cost feeds the selected recipe, profitability list and quote. It stays fixed to the vendor observation even if an AH listing is cheaper or several times more expensive. Other materials continue to use current AH prices.

Only purchasable, unlimited-stock, gold-only items qualify. Limited-stock and barter/currency items do not supply a normal vendor replacement cost. Common threads, dyes, fluxes, vials and other supplies are recognized by item ID; other unlimited items are learned when their merchant is opened. No price is guessed from vendor sell value or copied from a different version of WoW.

For recognized supplies with no usable observation, the material says **visit supplier**. That recipe's full cost, profit and quote remain unavailable until the price is learned. An inflated AH price is not used in its place.

Observations belong to the current character, faction and market and survive normal SavedVariables saves. They expire after seven days. A detected reputation-tier change invalidates prices while retaining known vendor identity. Revisit a supplier after any discount change, particularly where native reputation data is unavailable. The last visited supplier's current price is used; the addon does not search other vendors for a better discount.

Tooltip **Vendor sell** still means the amount a vendor pays you. It is separate from crafting's purchase cost. AH snapshots and daily history are also unchanged by merchant visits.

For a problem report, include the material, required quantity, merchant price/bundle size, crafting result and `/msmv diagnostics`. Vendor observations never need a new AH scan.
