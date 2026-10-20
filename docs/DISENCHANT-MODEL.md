# Disenchant estimates

Profile **classic-reference-1** is a **Classic reference, unverified for Forever**. Its material IDs, item-level brackets and probabilities were compared with the [CMaNGOS Classic reference database](https://github.com/cmangos/classic-db/blob/ec4f596146be6467ea93c57397858e329e2db852/Full_DB/ClassicDB_1_12_1_z2815.sql.gz), not a Forever server loot table.

## What is modeled

The estimate uses native item level, quality, class and equipment slot. It covers modeled uncommon, rare and epic weapons/armor. Wands use the dust-heavy reference treatment. Shirts, tabards, bags, fishing poles, cosmetic armor and unsupported equipment are excluded. Required character level is not substituted for item level.

The full bracket tables are in [Disenchant.lua](../MSMarketValue/Data/Disenchant.lua). Items outside those ranges are not extrapolated. Item-specific exceptions, new Forever materials, skill requirements and actual eligibility may differ. Use item exclusions for known exceptions.

## Reading the value

For each possible material:

```text
expected quantity = probability × midpoint of its quantity range
expected value = sum(expected quantity × latest AH material unit low)
```

The midpoint assumes a uniform quantity range. Tooltip material `avg` is the expected amount per disenchant, including outcomes where that material is absent. It is not a guaranteed yield.

When a hovered stack quantity is known, its total is calculated before rounding. Material details remain per item. If any possible material lacks a price, the addon does not present an incomplete estimate as a full total. Vendor sell value remains independent.

Material prices are asking prices. Fees, deposits, market depth and sale probability are excluded. The addon never performs Disenchant.

## Improving the model

Record item ID/link, client build, native item level/quality, actual materials and quantities. A single result shows a possible outcome, not its probability. Change distributions only with representative observations or an authoritative source, then update the profile, focused fixtures and documentation together.
