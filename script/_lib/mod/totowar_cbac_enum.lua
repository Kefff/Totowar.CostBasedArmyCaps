---Unit categories composing an army.
---@class TotoWar_Cbac_Enum_ArmyCompositionUnitCategories
TotoWar_Cbac_Enum_ArmyCompositionUnitCategories = {
    cavalryAndMonsters = "cavalryAndMonsters",
    hero = "hero",
    lord = "lord",
    meleeInfantry = "meleeInfantry",
    rangedInfantry = "rangedInfantry",
    warMachines = "warMachines"
}

---Events triggered by the mod.
---@class TotoWar_Cbac_Enum_ModEvents
TotoWar_Cbac_Enum_ModEvents = {
    ---Event triggered when options are updated.
    ---This differs from `mctOptionsUpdated` as it is used to signal that TotoWar option values
    ---have been updated by reading values from the Mod Configuration Tool.
    optionsUpdated = "TotoWar_Cab_OptionsUpdated",

    ---Event triggered when the army supplies cost of the selected army changes.
    selectedLordArmySuppliesCostChanged = "TotoWar_Cbac_SelectedLordArmySuppliesCostChanged",

    ---Event triggered when the army supplies cost of army exchanging units changes.
    unitExchangeArmySuppliesCostChanged = "TotoWar_Cbac_UnitExchangeArmySuppliesCostChanged",

    ---Event triggered when the army supplies cost changes due to units being selected for upgrade in the warband upgrade screen.
    warbandUpgradeArmySuppliesCostChanged = "TotoWar_Cbac_WarbandUpgradeArmySuppliesCostChanged"
}

---Recruitment pool.
---@class TotoWar_Cbac_Enum_UiRecruitmentPools
TotoWar_Cbac_Enum_UiRecruitmentPools = {
    allied = "allied",
    global = "global",
    local1 = "local1",
    local2 = "local2",
    mercenary = "mercenary"
}
