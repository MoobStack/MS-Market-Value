local _, A = ...

-- Original table representation of reference probabilities, not game loot data.
-- Forever's revised loot probabilities are NOT verified by this profile.
-- See docs/DISENCHANT-MODEL.md and docs/RESEARCH.md for provenance and limits.
A.DEProfile = {
    id = "classic-reference-1",
    label = "Classic reference estimate",
    verifiedForever = false,
    materials = {
        [10940] = "Strange Dust", [11083] = "Soul Dust",
        [11137] = "Vision Dust", [11176] = "Dream Dust", [16204] = "Illusion Dust",
        [10938] = "Lesser Magic Essence", [10939] = "Greater Magic Essence",
        [10998] = "Lesser Astral Essence", [11082] = "Greater Astral Essence",
        [11134] = "Lesser Mystic Essence", [11135] = "Greater Mystic Essence",
        [11174] = "Lesser Nether Essence", [11175] = "Greater Nether Essence",
        [16202] = "Lesser Eternal Essence", [16203] = "Greater Eternal Essence",
        [10978] = "Small Glimmering Shard", [11084] = "Large Glimmering Shard",
        [11138] = "Small Glowing Shard", [11139] = "Large Glowing Shard",
        [11177] = "Small Radiant Shard", [11178] = "Large Radiant Shard",
        [14343] = "Small Brilliant Shard", [14344] = "Large Brilliant Shard",
        [20725] = "Nexus Crystal",
    },
    -- min/max iLvl, dust ID/quantity, essence ID/quantity, shard ID,
    -- armor dust/essence chance, weapon dust/essence chance (percent).
    green = {
        { 5, 15, 10940, 1, 2, 10938, 1, 2, nil,   80, 20, 20, 80 },
        {16, 20, 10940, 2, 3, 10939, 1, 2, 10978, 75, 20, 20, 75 },
        {21, 25, 10940, 4, 6, 10998, 1, 2, 10978, 75, 15, 15, 75 },
        {26, 30, 11083, 1, 2, 11082, 1, 2, 11084, 75, 20, 20, 75 },
        {31, 35, 11083, 2, 5, 11134, 1, 2, 11138, 75, 20, 20, 75 },
        {36, 40, 11137, 1, 2, 11135, 1, 2, 11139, 75, 20, 20, 75 },
        {41, 45, 11137, 2, 5, 11174, 1, 2, 11177, 75, 20, 20, 75 },
        {46, 50, 11176, 1, 2, 11175, 1, 2, 11178, 75, 20, 20, 75 },
        {51, 55, 11176, 2, 5, 16202, 1, 2, 14343, 75, 20, 22, 75 },
        {56, 60, 16204, 1, 2, 16203, 1, 2, 14344, 75, 20, 22, 75 },
        {61, 65, 16204, 2, 5, 16203, 2, 2, 14344, 75, 20, 22, 75 },
    },
    -- min/max iLvl, material, min/max quantity, chance.
    rare = {
        {11, 25, 10978, 1, 1, 100}, {26, 30, 11084, 1, 1, 100},
        {31, 35, 11138, 1, 1, 100}, {36, 40, 11139, 1, 1, 100},
        {41, 45, 11177, 1, 1, 100}, {46, 50, 11178, 1, 1, 100},
        {51, 55, 14343, 1, 1, 100}, {56, 65, 14344, 1, 1, 99.5},
    },
    epic = {
        {40, 45, 11177, 2, 4, 100}, {46, 50, 11178, 2, 4, 100},
        {51, 55, 14343, 2, 4, 100}, {56, 60, 20725, 1, 1, 100},
        {61, 92, 20725, 1, 2, 100},
    },
}
