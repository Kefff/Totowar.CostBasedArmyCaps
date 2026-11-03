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

---Log categories of the mod: one per file, named after the class of the file.
---@enum TotoWar_Cbac_Enum_LogCategories
TotoWar_Cbac_Enum_LogCategories = {
    aiManager = "TotoWar_Cbac_AiManager",
    armySuppliesCost = "TotoWar_Cbac_ArmySuppliesCost",
    mod = "TotoWar_Cbac_Mod",
    playerManager = "TotoWar_Cbac_PlayerManager",
    uiManager = "TotoWar_Cbac_UIManager",
    unitArmySuppliesCost = "TotoWar_Cbac_UnitArmySuppliesCost"
}

---Events triggered by the mod.
---@enum TotoWar_Cbac_Enum_ModEvents
TotoWar_Cbac_Enum_ModEvents = {
    ---Multiplayer event, sent with `TotoWar__EventsManager:triggerMultiplayer` and received by all the players of the game,
    ---when an army of a player must be blocked or allowed to move again, depending on its army supplies.
    ---The decision is made on the machine of the player, from the army supplies displayed in the interface, and
    ---the event makes all the machines apply it, so that the game stays synchronized.
    ---Data: `<army command queue index>|<1 to block the army, 0 to allow it to move>`.
    mpArmyMovementUpdateRequested = "TotoWar_Cbac_ArmyMovementUpdateRequested",

    ---Event triggered when the army supplies cost of the selected hero changes.
    selectedHeroArmySuppliesCostChanged = "TotoWar_Cbac_SelectedHeroArmySuppliesCostChanged",

    ---Event triggered when the army supplies cost of the selected army changes.
    selectedLordArmySuppliesCostChanged = "TotoWar_Cbac_SelectedLordArmySuppliesCostChanged",

    ---Event triggered when the army supplies cost of army exchanging units changes.
    unitExchangeArmySuppliesCostChanged = "TotoWar_Cbac_UnitExchangeArmySuppliesCostChanged",

    ---Event triggered when the army supplies cost changes due to units being selected for upgrade in the warband upgrade screen.
    warbandUpgradeArmySuppliesCostChanged = "TotoWar_Cbac_WarbandUpgradeArmySuppliesCostChanged"
}
