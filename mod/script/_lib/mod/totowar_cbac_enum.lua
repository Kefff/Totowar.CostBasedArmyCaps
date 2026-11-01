---Unit categories composing an army.
---@enum TotoWar_Cbac_Enum_ArmyCompositionUnitCategories
TotoWar_Cbac_Enum_ArmyCompositionUnitCategories = {
    cavalryAndMonsters = "cavalryAndMonsters",
    hero = "hero",
    lord = "lord",
    meleeInfantry = "meleeInfantry",
    rangedInfantry = "rangedInfantry",
    warMachines = "warMachines"
}

---Log categories of the mod.
---@enum TotoWar_Cbac_Enum_LogCategories
TotoWar_Cbac_Enum_LogCategories = {
    aiManager = "TotoWar_Cbac_AiManager",
    armySuppliesCost = "TotoWar_Cbac_ArmySuppliesCost",
    playerManager = "TotoWar_Cbac_PlayerManager",
    uiManager = "TotoWar_Cbac_UIManager"
}

---Events triggered by the mod.
---@enum TotoWar_Cbac_Enum_ModEvents
TotoWar_Cbac_Enum_ModEvents = {
    ---Event triggered when the army supplies cost of the selected army changes.
    selectedLordArmySuppliesCostChanged = "TotoWar_Cbac_SelectedLordArmySuppliesCostChanged",

    ---Event triggered when the army supplies cost of army exchanging units changes.
    unitExchangeArmySuppliesCostChanged = "TotoWar_Cbac_UnitExchangeArmySuppliesCostChanged",

    ---Event triggered when the army supplies cost changes due to units being selected for upgrade in the warband upgrade screen.
    warbandUpgradeArmySuppliesCostChanged = "TotoWar_Cbac_WarbandUpgradeArmySuppliesCostChanged"
}

---Recruitment pool.
---@enum TotoWar_Cbac_Enum_UiRecruitmentPools
TotoWar_Cbac_Enum_UiRecruitmentPools = {
    allied = "allied",
    mercenary = "mercenary",
    standard = "standard"
}
