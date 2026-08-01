---TotoWar mod for managing army caps.
---@class TotoWar_Cbac_Mod
TotoWar_Cbac_Mod = {
    ---Manager for AI army supplies.
    ---@type TotoWar_Cbac_AiManager
    aiManager = nil,

    ---Loggers.
    loggers = {
        ---@type TotoWar__Logger
        aiManager = nil,

        ---@type TotoWar__Logger
        armySuppliesCost = nil,

        ---@type TotoWar__Logger
        generic = nil,

        ---@type TotoWar__Logger
        playerManager = nil,

        ---@type TotoWar__Logger
        uiManager = nil,
    },

    ---Options
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
    },

    ---Manager for player army supplies.
    ---@type TotoWar_Cbac_PlayerManager
    playerManager = nil,

    ---Manager for displaying army supplies in the UI.
    ---@type TotoWar_Cbac_UIManager
    uiManager = nil

}
TotoWar_Cbac_Mod.__index = TotoWar_Cbac_Mod

---TotoWar: Army Cost mod instance.
---@type TotoWar_Cbac_Mod
TotoWar_Cbac = nil

---Initializes a new instance.
---@return TotoWar_Cbac_Mod
function TotoWar_Cbac_Mod.new()
    TotoWar_Cbac = setmetatable({}, TotoWar_Cbac_Mod)

    TotoWar_Cbac:overwriteOptionsForDebug()
    TotoWar_Cbac:initializeLoggers()
    TotoWar_Cbac:subscribeToEvents()

    TotoWar_Cbac.aiManager = TotoWar_Cbac_AiManager.new()
    TotoWar_Cbac.playerManager = TotoWar_Cbac_PlayerManager.new()
    TotoWar_Cbac.uiManager = TotoWar_Cbac_UIManager.new()

    TotoWar_Cbac:loadMctOptions()

    TotoWar_Cbac.loggers.generic:logInfo("TotoWar: Army Caps | Mod initialized")
    TotoWar_Cbac.loggers.generic:logDebug("TotoWar_Cbac_Mod.new(): COMPLETED")

    return TotoWar_Cbac
end

---Initializes loggers.
function TotoWar_Cbac_Mod:initializeLoggers()
    TotoWar_Cbac.loggers.aiManager = TotoWar__Logger.new("TotoWar_Cbac_AiManager")
    TotoWar_Cbac.loggers.armySuppliesCost = TotoWar__Logger.new("TotoWar_Cbac_ArmySuppliesCost")
    TotoWar_Cbac.loggers.generic = TotoWar__Logger.new("TotoWar_Cbac_Generic")
    TotoWar_Cbac.loggers.playerManager = TotoWar__Logger.new("TotoWar_Cbac_PlayerManager")
    TotoWar_Cbac.loggers.uiManager = TotoWar__Logger.new("TotoWar_Cbac_UIManager")

    TotoWar_Cbac.loggers.generic:logDebug("initializeLoggers(): COMPLETED")
end

---Loads option values stored by the Mod Configuration Tool if it is installed.
function TotoWar_Cbac_Mod:loadMctOptions()
    local mct = TotoWar__Gameplay:getMct()

    if not mct then
        return
    end

    TotoWar_Cbac.loggers.generic:logInfo("TotoWar: Army Caps | Loading options")

    local options = mct:get_mod_by_key(TotoWar__Constant.modName)

    TotoWar_Cbac.options.aiArmySuppliesAmount = options
        :get_option_by_key(TotoWar_Cbac_Constant.optionName_aiArmySuppliesAmount)
        :get_finalized_setting()
    TotoWar_Cbac.options.aiArmySuppliesBonusAmountPerLevel = options
        :get_option_by_key(TotoWar_Cbac_Constant.optionName_aiArmySuppliesBonusAmountPerLevel)
        :get_finalized_setting()
    TotoWar_Cbac.options.aiArmySuppliesEnabled = options
        :get_option_by_key(TotoWar_Cbac_Constant.optionName_aiArmySuppliesEnabled)
        :get_finalized_setting()

    TotoWar_Cbac_ArmyCompositionTarget:set(
        TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.cavalryAndMonsters,
        options:get_option_by_key(TotoWar_Cbac_Constant.optionName_aiArmyCavalryAndMonstersMaximumPercentage)
        :get_finalized_setting())
    TotoWar_Cbac_ArmyCompositionTarget:set(
        TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.hero,
        options:get_option_by_key(TotoWar_Cbac_Constant.optionName_aiArmyHeroMaximumPercentage):get_finalized_setting())
    TotoWar_Cbac_ArmyCompositionTarget:set(
        TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.meleeInfantry,
        options:get_option_by_key(TotoWar_Cbac_Constant.optionName_aiArmyMeleeInfantryMaximumPercentage)
        :get_finalized_setting())
    TotoWar_Cbac_ArmyCompositionTarget:set(
        TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.rangedInfantry,
        options:get_option_by_key(TotoWar_Cbac_Constant.optionName_aiArmyRangedInfantryMaximumPercentage)
        :get_finalized_setting())
    TotoWar_Cbac_ArmyCompositionTarget:set(
        TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.warMachines,
        options:get_option_by_key(TotoWar_Cbac_Constant.optionName_aiArmyWarMachinesMaximumPercentage)
        :get_finalized_setting())

    TotoWar_Cbac.options.playerArmySuppliesAmount = options
        :get_option_by_key(TotoWar_Cbac_Constant.optionName_playerArmySuppliesAmount)
        :get_finalized_setting()
    TotoWar_Cbac.options.playerArmySuppliesBonusAmountPerLevel = options
        :get_option_by_key(TotoWar_Cbac_Constant.optionName_playerArmySuppliesBonusAmountPerLevel)
        :get_finalized_setting()
    TotoWar_Cbac.options.playerArmySuppliesEnabled = options
        :get_option_by_key(TotoWar_Cbac_Constant.optionName_playerArmySuppliesEnabled)
        :get_finalized_setting()

    -- Signaling option changes
    TotoWar.eventsManager:trigger(TotoWar__Enum_ModEvents.optionsUpdated)

    TotoWar_Cbac.loggers.generic:logInfo("TotoWar: Army Caps | Options loaded")
end

---Reacts to MCT options being updated.
function TotoWar_Cbac_Mod:onMctOptionsUpdated()
    TotoWar_Cbac.loggers.generic:logDebug("onMctOptionsUpdated(): STARTED")

    TotoWar_Cbac:loadMctOptions()

    TotoWar_Cbac.loggers.generic:logDebug("onMctOptionsUpdated(): COMPLETED")
end

---Reacts to TotoWar options being updated.
function TotoWar_Cbac_Mod:onOptionsUpdated()
    TotoWar_Cbac.loggers.generic:logDebug("onOptionsUpdated(): STARTED")

    -- Overriding options after they are loaded
    -- Must be executed first in this function
    TotoWar_Cbac:overwriteOptionsForDebug()

    TotoWar_Cbac.loggers.generic:logDebug("onOptionsUpdated(): COMPLETED")
end

---Allows to programatically overwrite option values for local debug purpose.
function TotoWar_Cbac_Mod:overwriteOptionsForDebug()
    -- Set override values here

    -- TotoWar_Cbac.loggers.aiManager.logLevel = TotoWar__Enum_LogSeverity.warning
    -- TotoWar_Cbac.loggers.armySuppliesCost.logLevel = TotoWar__Enum_LogSeverity.warning
    -- TotoWar_Cbac.loggers.generic.logLevel = TotoWar__Enum_LogSeverity.warning
    -- TotoWar_Cbac.loggers.playerManager.logLevel = TotoWar__Enum_LogSeverity.warning
    -- TotoWar_Cbac.loggers.uiManager.logLevel = TotoWar__Enum_LogSeverity.warning
end

---Subscribes to events.
function TotoWar_Cbac_Mod:subscribeToEvents()
    TotoWar_Cbac.loggers.generic:logDebug("subscribeToEvents(): STARTED")

    TotoWar.eventsManager:subscribe(
        TotoWar__Enum_ModEvents.mctOptionsUpdated,
        function() TotoWar_Cbac:onMctOptionsUpdated() end)

    TotoWar.eventsManager:subscribe(
        TotoWar__Enum_ModEvents.optionsUpdated,
        function() TotoWar_Cbac:onOptionsUpdated() end)

    TotoWar_Cbac.loggers.generic:logDebug("subscribeToEvents(): COMPLETED")
end
