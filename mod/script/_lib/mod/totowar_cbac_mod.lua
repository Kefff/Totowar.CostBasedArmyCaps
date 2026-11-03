local logger = TotoWar__Logger.get(TotoWar_Cbac_Enum_LogCategories.mod)

---Allows to programatically overwrite option values for local debug purpose.
local function overwriteOptionsForDebug()
    -- Set override values here, for example to show or hide the messages of a log category:
    -- TotoWar__Logger.levelOverrides[TotoWar_Cbac_Enum_LogCategories.aiManager] = TotoWar__Enum_LogSeverities.debug
    -- TotoWar__Logger.levelOverrides[TotoWar_Cbac_Enum_LogCategories.uiManager] = TotoWar__Enum_LogSeverities.error
end

---TotoWar mod for managing army caps.
---@class TotoWar_Cbac_Mod
TotoWar_Cbac_Mod = {
    ---Options.
    options = {
        ---Total army supplies available in an army for the AI.
        aiArmySuppliesAmount = TotoWar_Cbac_Constant.optionDefaultValue_aiArmySuppliesAmount,

        ---Bonus army supplies per level of the lord in AI armies.
        aiArmySuppliesBonusAmountPerLevel = TotoWar_Cbac_Constant.optionDefaultValue_aiArmySuppliesBonusAmountPerLevel,

        ---Indicates whether army supplies restrictions are enabled for AI armies.
        aiArmySuppliesEnabled = TotoWar_Cbac_Constant.optionDefaultValue_aiArmySuppliesEnabled,

        ---Total army supplies available in an army for the player.
        playerArmySuppliesAmount = TotoWar_Cbac_Constant.optionDefaultValue_playerArmySuppliesAmount,

        ---Bonus army supplies per level of the lord in player armies.
        playerArmySuppliesBonusAmountPerLevel =
            TotoWar_Cbac_Constant.optionDefaultValue_playerArmySuppliesBonusAmountPerLevel,

        ---Indicates whether army supplies restrictions are enabled for player armies.
        playerArmySuppliesEnabled = TotoWar_Cbac_Constant.optionDefaultValue_playerArmySuppliesEnabled
    }
}

---Initializes the mod and its services.
function TotoWar_Cbac_Mod:initialize()
    logger:logDebug("TotoWar_Cbac_Mod:initialize(): STARTED")

    self:subscribeToEvents()
    self:loadMctOptions()

    TotoWar_Cbac_AiManager:initialize()
    TotoWar_Cbac_PlayerManager:initialize()
    TotoWar_Cbac_UIManager:initialize()

    logger:logInfo("Mod \"%s\" initialized", TotoWar_Cbac_Constant.modCaption)
    logger:logDebug("TotoWar_Cbac_Mod:initialize(): COMPLETED")
end

---Loads option values stored by the Mod Configuration Tool if it is installed.
function TotoWar_Cbac_Mod:loadMctOptions()
    logger:logDebug("TotoWar_Cbac_Mod:loadMctOptions(): STARTED")

    local mct = TotoWar__Gameplay:getMct()

    if mct == nil then
        logger:logInfo(
            "Mod Configuration Tool not installed: \"%s\" uses its default options",
            TotoWar_Cbac_Constant.modCaption)
        logger:logDebug("TotoWar_Cbac_Mod:loadMctOptions(): COMPLETED => Mod Configuration Tool not installed")

        return
    end

    local options = mct:get_mod_by_key(TotoWar__Constant.modName)

    self.options.aiArmySuppliesAmount = options
        :get_option_by_key(TotoWar_Cbac_Constant.optionName_aiArmySuppliesAmount)
        :get_finalized_setting()
    self.options.aiArmySuppliesBonusAmountPerLevel = options
        :get_option_by_key(TotoWar_Cbac_Constant.optionName_aiArmySuppliesBonusAmountPerLevel)
        :get_finalized_setting()
    self.options.aiArmySuppliesEnabled = options
        :get_option_by_key(TotoWar_Cbac_Constant.optionName_aiArmySuppliesEnabled)
        :get_finalized_setting()

    local compositionOptionNames = {
        [TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.cavalryAndMonsters] =
            TotoWar_Cbac_Constant.optionName_aiArmyCavalryAndMonstersMaximumPercentage,
        [TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.hero] =
            TotoWar_Cbac_Constant.optionName_aiArmyHeroMaximumPercentage,
        [TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.meleeInfantry] =
            TotoWar_Cbac_Constant.optionName_aiArmyMeleeInfantryMaximumPercentage,
        [TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.rangedInfantry] =
            TotoWar_Cbac_Constant.optionName_aiArmyRangedInfantryMaximumPercentage,
        [TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.warMachines] =
            TotoWar_Cbac_Constant.optionName_aiArmyWarMachinesMaximumPercentage
    }
    ---@diagnostic disable-next-line: param-type-mismatch
    local defaultComposition = TotoWar_Cbac_ArmyCompositionTarget:get("default")

    for unitCategory, optionName in pairs(compositionOptionNames) do
        defaultComposition:set(unitCategory, options:get_option_by_key(optionName):get_finalized_setting())
    end

    self.options.playerArmySuppliesAmount = options
        :get_option_by_key(TotoWar_Cbac_Constant.optionName_playerArmySuppliesAmount)
        :get_finalized_setting()
    self.options.playerArmySuppliesBonusAmountPerLevel = options
        :get_option_by_key(TotoWar_Cbac_Constant.optionName_playerArmySuppliesBonusAmountPerLevel)
        :get_finalized_setting()
    self.options.playerArmySuppliesEnabled = options
        :get_option_by_key(TotoWar_Cbac_Constant.optionName_playerArmySuppliesEnabled)
        :get_finalized_setting()

    -- Signaling option changes
    TotoWar__EventsManager:trigger(TotoWar__Enum_ModEvents.optionsUpdated)

    logger:logInfo(
        "\"%s\" options loaded from the Mod Configuration Tool (Player armies restricted: %s | AI armies restricted: %s)",
        TotoWar_Cbac_Constant.modCaption,
        self.options.playerArmySuppliesEnabled,
        self.options.aiArmySuppliesEnabled)
    logger:logDebug("TotoWar_Cbac_Mod:loadMctOptions(): COMPLETED")
end

---Reacts to MCT options being updated.
function TotoWar_Cbac_Mod:onMctOptionsUpdated()
    logger:logDebug("TotoWar_Cbac_Mod:onMctOptionsUpdated(): STARTED")

    self:loadMctOptions()

    logger:logDebug("TotoWar_Cbac_Mod:onMctOptionsUpdated(): COMPLETED")
end

---Subscribes to events.
function TotoWar_Cbac_Mod:subscribeToEvents()
    logger:logDebug("TotoWar_Cbac_Mod:subscribeToEvents(): STARTED")

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_ModEvents.mctOptionsUpdated,
        function() self:onMctOptionsUpdated() end)

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_ModEvents.optionsUpdated,
        function() overwriteOptionsForDebug() end,
        nil,
        nil,
        9999) -- To force overwriteOptionsForDebug to be executed after other methods reacting to the optionsUpdated event

    logger:logDebug("TotoWar_Cbac_Mod:subscribeToEvents(): COMPLETED")
end
