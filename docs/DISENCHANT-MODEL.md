# Disenchant reference model

Profile `classic-reference-1`; `verifiedForever = false`.

## Scope and provenance

This is an item-level **estimate** based on Classic reference distributions, represented in original addon tables. Material IDs, ranges and probabilities were checked against the public CMaNGOS Classic database's disenchant reference records. It is not a Blizzard Forever server loot table, and exceptional Classic records and Forever changes can differ from the generic brackets.

The model uses `C_Item.GetItemInfo` item level, quality, class/subclass and equipment slot. It does not substitute required character level. Only modeled quality 2–4 weapons/armor in supported equipment slots are considered. Shirts, tabards, bags, fishing poles, cosmetic armor and non-equipment are excluded. Wands follow the dust-heavy reference treatment. Eligible does not mean verified disenchantable or currently usable by the player's Enchanting skill.

User item exclusions suppress the estimate for known exceptions. The model does not execute Disenchant, check a protected action by trying it, or encourage choosing a destruction action automatically.

## Uncommon equipment

Material quantities are conditional on that material being selected. Outcomes are mutually exclusive in this reference model. Percentages are **dust / essence / shard**.

| iLvl | Dust quantity | Essence quantity | Shard quantity | Armor % | Ordinary weapon % |
|---|---|---|---|---|---|
| 5–15 | Strange Dust 1–2 | Lesser Magic Essence 1–2 | None | 80 / 20 / 0 | 20 / 80 / 0 |
| 16–20 | Strange Dust 2–3 | Greater Magic Essence 1–2 | Small Glimmering Shard 1 | 75 / 20 / 5 | 20 / 75 / 5 |
| 21–25 | Strange Dust 4–6 | Lesser Astral Essence 1–2 | Small Glimmering Shard 1 | 75 / 15 / 10 | 15 / 75 / 10 |
| 26–30 | Soul Dust 1–2 | Greater Astral Essence 1–2 | Large Glimmering Shard 1 | 75 / 20 / 5 | 20 / 75 / 5 |
| 31–35 | Soul Dust 2–5 | Lesser Mystic Essence 1–2 | Small Glowing Shard 1 | 75 / 20 / 5 | 20 / 75 / 5 |
| 36–40 | Vision Dust 1–2 | Greater Mystic Essence 1–2 | Large Glowing Shard 1 | 75 / 20 / 5 | 20 / 75 / 5 |
| 41–45 | Vision Dust 2–5 | Lesser Nether Essence 1–2 | Small Radiant Shard 1 | 75 / 20 / 5 | 20 / 75 / 5 |
| 46–50 | Dream Dust 1–2 | Greater Nether Essence 1–2 | Large Radiant Shard 1 | 75 / 20 / 5 | 20 / 75 / 5 |
| 51–55 | Dream Dust 2–5 | Lesser Eternal Essence 1–2 | Small Brilliant Shard 1 | 75 / 20 / 5 | 22 / 75 / 3 |
| 56–60 | Illusion Dust 1–2 | Greater Eternal Essence 1–2 | Large Brilliant Shard 1 | 75 / 20 / 5 | 22 / 75 / 3 |
| 61–65 | Illusion Dust 2–5 | Greater Eternal Essence 2 | Large Brilliant Shard 1 | 75 / 20 / 5 | 22 / 75 / 3 |

## Rare equipment

| iLvl | Reference outcome |
|---|---|
| 11–25 | Small Glimmering Shard ×1, 100% |
| 26–30 | Large Glimmering Shard ×1, 100% |
| 31–35 | Small Glowing Shard ×1, 100% |
| 36–40 | Large Glowing Shard ×1, 100% |
| 41–45 | Small Radiant Shard ×1, 100% |
| 46–50 | Large Radiant Shard ×1, 100% |
| 51–55 | Small Brilliant Shard ×1, 100% |
| 56–65 | Large Brilliant Shard ×1, 99.5%; or Nexus Crystal ×1, 0.5% |

Some exceptional reference item records use different loot selections, including a guaranteed Large Brilliant Shard. The generic estimate is not a substitute for a per-item loot dataset.

## Epic equipment

| iLvl | Reference outcome |
|---|---|
| 40–45 | Small Radiant Shard ×2–4 |
| 46–50 | Large Radiant Shard ×2–4 |
| 51–55 | Small Brilliant Shard ×2–4 |
| 56–60 | Nexus Crystal ×1 |
| 61–92 | Nexus Crystal ×1–2 |

These single-material outcomes have reference probability 100%. Items outside the modeled level/quality ranges receive no extrapolated estimate.

## Formula and assumptions

For outcome probability `p` and quantity range `min..max`:

```text
expected quantity = p × (min + max) / 2
expected DE value = sum(expected quantity × material minimum unit buyout)
```

The midpoint assumes an approximately uniform quantity distribution within the bracket. The probability and quantity assumptions remain provisional for Forever. The tooltip's `avg` is expected quantity per disenchant, not average quantity conditional on receiving that outcome.

Worked synthetic example: an iLvl 17 green armor item, with dust at 100c, essence at 200c and shard at 1000c:

| Material | Expected quantity | Contribution |
|---|---:|---:|
| Strange Dust | 0.75 × 2.5 = 1.875 | 187.5c |
| Greater Magic Essence | 0.20 × 1.5 = 0.30 | 60c |
| Small Glimmering Shard | 0.05 × 1 = 0.05 | 50c |
| Total | | 297.5c, displayed as 2s 98c |

This example is a calculation fixture, not a report of current market prices. In the price block, **DE expected** for a verified hovered stack of three is 892.5c, displayed as 8s 93c; the per-item estimate displays as 2s 98c. Stack multiplication happens before rounding. The material block remains per item and follows a blank line. Vendor value is independent of the model. AH material values are gross asking-price estimates; fees, deposits, market depth and sale probability are not modeled.

If any possible material has no snapshot buyout, no complete expected value is shown. A known subtotal is separately labeled and never called the total. A missing price, a zero native vendor value, a bid-only auction and an unlisted item are different states.

## Updating the model

Release model changes under a new version/profile, preserving existing release tags. Record item ID/link, native item level, quality, class/subclass, actual materials and quantities, number of observations, and client build. A single observation proves that outcome occurred, not its probability. Use sufficiently representative observations or an authoritative new data source before changing probability claims.

Update the profile, research notes, model tables, focused fixtures and changelog together. Add exact item exceptions only with evidence. Continue to label any unverified bracket or changed Forever material behavior until independently qualified.
