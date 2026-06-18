---Constants of the TotoWar: Army Caps mod.
---@class TotoWar_Cbac_Constant
TotoWar_Cbac_Constant = {
    ---Maximum size of an army to target for adjustments.
    maximumTargetArmySize = 20,

    ---Maximum percentage a unite category can occupy in AI armies.
    maximumUnitCategoryTargetPercentage = 75,

    ---Minimum size of an army to target for adjustments.
    minimumTargetArmySize = 13,

    ---Ratio applied to the maximum percentage of a unit category to get the minimum percentage this unit category can occupy in AI armies.
    minimumUnitCategoryPercentageRatio = 0.15,

    ---Name of the TotoWar: Army Caps mod.
    modName = "totowar_cost_based_army_caps",

    ---Default value for the maximum percentage of cavalry and monsters to target in AI armies.
    optionDefaultValue_aiArmyCavalryAndMonstersMaximumPercentage = 50,

    ---Name of the option for the maximum percentage of heroes in AI armies.
    optionDefaultValue_aiArmyHeroMaximumPercentage = 15,

    ---Default value for the maximum percentage of melee infantry to target in AI armies.
    optionDefaultValue_aiArmyMeleeInfantryMaximumPercentage = 75,

    ---Default value for the maximum percentage of ranged infantry to target in AI armies.
    optionDefaultValue_aiArmyRangedInfantryMaximumPercentage = 50,

    ---Default value for the amount of available army supplies in AI armies.
    ---Sadly, it cannot be read from DB table (mp_budgets_table) because LUA scripts do not not have access to them.
    optionDefaultValue_aiArmySuppliesAmount = 12400,

    ---Default value for the amount of bonus army supplies given to an AI army per level of its lord.
    optionDefaultValue_aiArmySuppliesBonusAmountPerLevel = 50,

    ---Default value for the option that enabled AI army supplies restrictions.
    optionDefaultValue_aiArmySuppliesEnabled = true,

    ---Default value for the maximum percentage of war machines to target in AI armies.
    optionDefaultValue_aiArmyWarMachinesMaximumPercentage = 20,

    ---Default value for the amount of available army supplies in player armies.
    ---Sadly, it cannot be read from DB table (mp_budgets_table) because LUA scripts do not not have access to them.
    optionDefaultValue_playerArmySuppliesAmount = 12400,

    ---Default value for the amount of bonus army supplies given to a player army per level of its lord.
    optionDefaultValue_playerArmySuppliesBonusAmountPerLevel = 50,

    ---Default value for the option that enabled AI army supplies restrictions.
    optionDefaultValue_playerArmySuppliesEnabled = true,

    ---Name of the option for the maximum percentage of heroes in AI armies.
    optionName_aiArmyHeroMaximumPercentage = "totowar_cbac_aiArmyHeroMaximumPercentage",

    ---Name of the option for the maximum percentage of cavalry and monsters to target in AI armies.
    optionName_aiArmyCavalryAndMonstersMaximumPercentage =
    "totowar_cbac_aiArmyCavalryAndMonstersMaximumPercentage",

    ---Name of the option for the maximum percentage of melee infantry to target in AI armies.
    optionName_aiArmyMeleeInfantryMaximumPercentage =
    "totowar_cbac_aiArmyMeleeInfantryMaximumPercentage",

    ---Name of the option for the maximum percentage of ranged infantry to target in AI armies.
    optionName_aiArmyRangedInfantryMaximumPercentage =
    "totowar_cbac_aiArmyRangedInfantryMaximumPercentage",

    ---Name of the option for the amount of army supplies in AI armies.
    optionName_aiArmySuppliesAmount = "totowar_cbac_aiArmySuppliesAmount",

    ---Name of the option for the amount of bonus army supplies per level of its lord in AI armies.
    optionName_aiArmySuppliesBonusAmountPerLevel = "totowar_cbac_aiArmySuppliesBonusAmountPerLevel",

    ---Name of option that enables army supplies restriction for AI armies.
    optionName_aiArmySuppliesEnabled = "totowar_cbac_aiArmySuppliesEnabled",

    ---Name of the option for the maximum percentage of war machines to target in AI armies.
    optionName_aiArmyWarMachinesMaximumPercentage =
    "totowar_cbac_aiArmyWarMachinesMaximumPercentage",

    ---Name of the option for the amount of army supplies in player armies.
    optionName_playerArmySuppliesAmount = "totowar_cbac_playerArmySuppliesAmount",

    ---Name of the option for the amount of bonus army supplies per level of its lord in player armies.
    optionName_playerArmySuppliesBonusAmountPerLevel =
    "totowar_cbac_playerArmySuppliesBonusAmountPerLevel",

    ---Name of the option that enables army supplies restriction for player armies.
    optionName_playerArmySuppliesEnabled = "totowar_cbac_playerArmySuppliesEnabled",

    ---Storage key for date associated with the last turn an army was adjusted to meet cost-based caps.
    storageKeyFormatArmyLastAdjustmentTurn = "armyLastAdjustmentTurn_%s",

    ---Storage key for the amount a unit category should represent in an army.
    storageKeyFormatArmyUnitCategoryAmount = "armyUnitCategoryAmount_%s_%s"
}
