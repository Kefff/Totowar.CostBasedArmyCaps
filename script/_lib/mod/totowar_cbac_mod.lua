---TotoWar mod for managing cost-Based army caps.
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
        aiArmySuppliesAmount = TotoWar_Cbac_OptionDefaultValue_AiArmySuppliesAmount,

        ---Bonus army supplies per level of the lord in AI armies.
        aiArmySuppliesBonusAmountPerLevel = TotoWar_Cbac_OptionDefaultValue_AiArmySuppliesBonusAmountPerLevel,

        ---Indicates whether army supplies restrictions are enabled for AI armies.
        aiArmySuppliesEnabled = TotoWar_Cbac_OptionDefaultValue_AiArmySuppliesEnabled,

        ---Percentage of each unit category to target in AI armies.
        ---@type TotoWar__Dictionary<string, number>
        aiArmyUnitCategoryPercentages = TotoWar__Dictionary.new(),

        ---Total army supplies available in an army for the player.
        playerArmySuppliesAmount = TotoWar_Cbac_OptionDefaultValue_PlayerArmySuppliesAmount,

        ---Bonus army supplies per level of the lord in player armies.
        playerArmySuppliesBonusAmountPerLevel = TotoWar_Cbac_OptionDefaultValue_PlayerArmySuppliesBonusAmountPerLevel,

        ---Indicates whether army supplies restrictions are enabled for player armies.
        playerArmySuppliesEnabled = TotoWar_Cbac_OptionDefaultValue_PlayerArmySuppliesEnabled
    },

    ---Manager for player army supplies.
    ---@type TotoWar_Cbac_PlayerManager
    playerManager = nil,

    ---Manager for displaying army supplies in the UI.
    ---@type TotoWar_Cbac_UIManager
    uiManager = nil

}
TotoWar_Cbac_Mod.__index = TotoWar_Cbac_Mod

---TotoWar Cost-Based Army Cost mod instance.
---@type TotoWar_Cbac_Mod
TotoWar_Cbac = nil

---Initializes a new instance.
---@return TotoWar_Cbac_Mod
function TotoWar_Cbac_Mod.new()
    TotoWar_Cbac = setmetatable({}, TotoWar_Cbac_Mod)

    TotoWar_Cbac:initializeLoggers()

    -- Initialize the dictionary with default values
    TotoWar_Cbac.options.aiArmyUnitCategoryPercentages:set(
        "cavalryAndMonsters",
        TotoWar_Cbac_OptionDefaultValue_AiArmyCavalryAndMonstersMaximumPercentage)
    TotoWar_Cbac.options.aiArmyUnitCategoryPercentages:set(
        "cavalryAndMonsters",
        TotoWar_Cbac_OptionDefaultValue_AiArmyCavalryAndMonstersMaximumPercentage)
    TotoWar_Cbac.options.aiArmyUnitCategoryPercentages:set(
        "meleeInfantry",
        TotoWar_Cbac_OptionDefaultValue_AiArmyMeleeInfantryMinimumPercentage)
    TotoWar_Cbac.options.aiArmyUnitCategoryPercentages:set(
        "rangedInfantry",
        TotoWar_Cbac_OptionDefaultValue_AiArmyRangedInfantryMaximumPercentage)
    TotoWar_Cbac.options.aiArmyUnitCategoryPercentages:set(
        "warMachines",
        TotoWar_Cbac_OptionDefaultValue_AiArmyWarMachinesMaximumPercentage)

    TotoWar_Cbac.aiManager = TotoWar_Cbac_AiManager.new()
    TotoWar_Cbac.playerManager = TotoWar_Cbac_PlayerManager.new()
    TotoWar_Cbac.uiManager = TotoWar_Cbac_UIManager.new()

    TotoWar_Cbac:addListeners()
    TotoWar_Cbac:loadMctOptions()

    TotoWar_Cbac.loggers.generic:logInfo("TotoWar - Cost-Based Army Caps | Mod initialized")
    TotoWar_Cbac.loggers.generic:logDebug("TotoWar_Cbac_Mod.new(): COMPLETED")

    return TotoWar_Cbac
end

---Adds event listeners.
function TotoWar_Cbac_Mod:addListeners()
    TotoWar_Cbac.loggers.generic:logDebug("addListeners(): STARTED")

    TotoWar__Gameplay:addListener(
        "TotoWarCbac",
        TotoWar__Enum_ModEvents.mctOptionsUpdated,
        true,
        function()
            TotoWar_Cbac:onMctOptionsUpdated()
        end)

    TotoWar__Gameplay:addListener(
        "TotoWar",
        TotoWar_Cbac_Enum_ModEvent.optionsUpdated,
        true,
        function()
            TotoWar_Cbac:onOptionsUpdated()
        end)

    -- Manager listeners
    TotoWar_Cbac.aiManager:addListeners()
    TotoWar_Cbac.playerManager:addListeners()
    TotoWar_Cbac.uiManager:addListeners()

    TotoWar_Cbac.loggers.generic:logDebug("addListeners(): COMPLETED")
end

---Initializes loggers.
function TotoWar_Cbac_Mod:initializeLoggers()
    TotoWar_Cbac.loggers.aiManager = TotoWar__Logger.new("TotoWarCbac_AiManager")
    TotoWar_Cbac.loggers.armySuppliesCost = TotoWar__Logger.new("TotoWarCbac_ArmySuppliesCost")
    TotoWar_Cbac.loggers.generic = TotoWar__Logger.new("TotoWarCbac_Generic")
    TotoWar_Cbac.loggers.playerManager = TotoWar__Logger.new("TotoWarCbac_PlayerManager")
    TotoWar_Cbac.loggers.uiManager = TotoWar__Logger.new("TotoWarCbac_UIManager")

    TotoWar_Cbac.loggers.generic:logDebug("initializeLoggers(): COMPLETED")
end

---Loads option values stored by the Mod Configuration Tool if it is installed.
function TotoWar_Cbac_Mod:loadMctOptions()
    local mct = TotoWar__Gameplay:getMct()

    if not mct then
        return
    end

    TotoWar_Cbac.loggers.generic:logInfo("TotoWar - Cost-Based Army Caps | Loading options")

    local options = mct:get_mod_by_key(TotoWar__ModName)

    TotoWar_Cbac.options.aiArmySuppliesBonusAmountPerLevel = options
        :get_option_by_key(TotoWar_Cbac_OptionName_AiArmySuppliesBonusAmountPerLevel)
        :get_finalized_setting()
    TotoWar_Cbac.options.aiArmySuppliesAmount = options
        :get_option_by_key(TotoWar_Cbac_OptionName_AiArmySuppliesAmount)
        :get_finalized_setting()
    TotoWar_Cbac.options.aiArmySuppliesEnabled = options
        :get_option_by_key(TotoWar_Cbac_OptionName_AiArmySuppliesEnabled)
        :get_finalized_setting()
    TotoWar_Cbac.options.aiArmyUnitCategoryPercentages:set(
        TotoWar_Cbac_Enum_ArmyCompositionUnitCategorie.cavalryAndMonsters,
        options:get_option_by_key(TotoWar_Cbac_OptionName_AiArmyCavalryAndMonstersMaximumPercentage)
        :get_finalized_setting())
    TotoWar_Cbac.options.aiArmyUnitCategoryPercentages:set(
        TotoWar_Cbac_Enum_ArmyCompositionUnitCategorie.hero,
        options:get_option_by_key(TotoWar_Cbac_OptionName_AiArmyHeroMaximumPercentage):get_finalized_setting())
    TotoWar_Cbac.options.aiArmyUnitCategoryPercentages:set(
        TotoWar_Cbac_Enum_ArmyCompositionUnitCategorie.meleeInfantry,
        options:get_option_by_key(TotoWar_Cbac_OptionName_AiArmyMeleeInfantryMinimumPercentage):get_finalized_setting())
    TotoWar_Cbac.options.aiArmyUnitCategoryPercentages:set(
        TotoWar_Cbac_Enum_ArmyCompositionUnitCategorie.rangedInfantry,
        options:get_option_by_key(TotoWar_Cbac_OptionName_AiArmyRangedInfantryMaximumPercentage):get_finalized_setting())
    TotoWar_Cbac.options.aiArmyUnitCategoryPercentages:set(
        TotoWar_Cbac_Enum_ArmyCompositionUnitCategorie.warMachines,
        options:get_option_by_key(TotoWar_Cbac_OptionName_AiArmyWarMachinesMaximumPercentage):get_finalized_setting())

    TotoWar_Cbac.options.playerArmySuppliesAmount = options
        :get_option_by_key(TotoWar_Cbac_OptionName_PlayerArmySuppliesAmount)
        :get_finalized_setting()
    TotoWar_Cbac.options.playerArmySuppliesBonusAmountPerLevel = options
        :get_option_by_key(TotoWar_Cbac_OptionName_PlayerArmySuppliesBonusAmountPerLevel)
        :get_finalized_setting()
    TotoWar_Cbac.options.playerArmySuppliesEnabled = options
        :get_option_by_key(TotoWar_Cbac_OptionName_PlayerArmySuppliesEnabled)
        :get_finalized_setting()

    -- Signaling option changes
    core:trigger_event(TotoWar_Cbac_Enum_ModEvent.optionsUpdated)

    TotoWar_Cbac.loggers.generic:logInfo("TotoWar - Cost-Based Army Caps | Options loaded")
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
    TotoWar_Cbac.loggers.generic:logDebug("overwriteOptionsForDebug(): STARTED")

    -- Set override values here
    -- TotoWarCbac.loggers.aiManager.logLevel = TotoWar__Enum_LogSeverity.warning
    -- TotoWar_Cbac.loggers.armySuppliesCost.logLevel = TotoWar__Enum_LogSeverity.warning
    -- TotoWar_Cbac.loggers.generic.logLevel = TotoWar__Enum_LogSeverity.warning
    -- TotoWar_Cbac.loggers.playerManager.logLevel = TotoWar__Enum_LogSeverity.warning
    -- TotoWar_Cbac.loggers.uiManager.logLevel = TotoWar__Enum_LogSeverity.warning

    TotoWar_Cbac.loggers.generic:logDebug("overwriteOptionsForDebug(): COMPLETED")
end
