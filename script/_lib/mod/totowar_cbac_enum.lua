---Unit categories composing an army.
---@class TotoWar_Cbac_Enum_ArmyCompositionUnitCategory
TotoWar_Cbac_Enum_ArmyCompositionUnitCategory = {
    cavalryAndMonsters = "cavalryAndMonsters",
    hero = "hero",
    lord = "lord",
    meleeInfantry = "meleeInfantry",
    rangedInfantry = "rangedInfantry",
    warMachines = "warMachines"
}

---Events triggered by the mod.
---@class TotoWar_Cbac_Enum_ModEvent
TotoWar_Cbac_Enum_ModEvent = {
    ---Event triggered when options are updated.
    ---This differs from `mctOptionsUpdated` as it is used to signal that TotoWar option values
    ---have been updated by reading values from the Mod Configuration Tool.
    optionsUpdated = "TotoWar_Cab_OptionsUpdated",

    ---Event triggered when the army supplies cost of the selected army changes.
    selectedLordArmySuppliesCostChanged = "TotoWar_Cbac_SelectedLordArmySuppliesCostChanged",

    ---Event triggered when the army supplies cost of army exchanging units changes.
    unitExchangeArmySuppliesCostChanged = "TotoWar_Cbac_UnitExchangeArmySuppliesCostChanged",
}

---Recruitment pool names.
---@class TotoWar_Cbac_Enum_UiRecruitmentPoolName
TotoWar_Cbac_Enum_UiRecruitmentPoolName = {
    allied = "allied",
    global = "global",
    local_ = "local", -- `local` is a reserved word
    mercenary = "mercenary"
}
