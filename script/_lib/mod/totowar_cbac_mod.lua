---TotoWar mod form managing cost-Based army caps.
---@class TotoWarCbacMod
TotoWarCbacMod = {
    ---Manager for AI army supplies.
    ---@type TotoWarCbacAiManager
    aiManager = nil,

    ---Enums
    ---@class TotoWarCbac_Enums
    enums = {
        ---Unit categories composing an army.
        ---@class TotoWarCbac_Enums_ArmyCompositionUnitCategories
        armyCompositionUnitTypes = {
            hero = "hero",
            artillery = "artillery",
            cavalryAndMonsters = "cavalryAndMonsters",
            lord = "lord",
            meleeInfantry = "meleeInfantry",
            rangedInfantry = "rangedInfantry",
        },

        ---Events triggered by the mod.
        ---@class TotoWarCbac_Enums_ModEvents
        modEvents = {
            ---Event triggered when options are updated.
            ---This differs from `mctOptionsUpdated` as it is used to signal that TotoWar option values
            ---have been updated by reading values from the Mod Configuration Tool.
            optionsUpdated = "TotoWarCab_OptionsUpdated",

            ---Event triggered when the army supplies cost of the selected army changes.
            selectedLordArmySuppliesCostChanged = "TotoWarCbac_SelectedLordArmySuppliesCostChanged",

            ---Event triggered when the army supplies cost of army exchanging units changes.
            unitExchangeArmySuppliesCostChanged = "TotoWarCbac_UnitExchangeArmySuppliesCostChanged",
        },

        ---Recruitment pool names.
        ---@class TotoWarCbac_Enums_UiRecruitmentPoolNames
        uiRecruitmentPoolNames = {
            allied = "allied",
            global = "global",
            local_ = "local", -- `local` is a reserved word
            mercenary = "mercenary"
        }
    },

    ---Loggers.
    ---@class TotoWarCbac_Loggers
    loggers = {
        ---@type TotoWarLogger
        aiManager = nil,

        ---@type TotoWarLogger
        armySuppliesCost = nil,

        ---@type TotoWarLogger
        generic = nil,

        ---@type TotoWarLogger
        playerManager = nil,

        ---@type TotoWarLogger
        uiManager = nil,
    },

    ---Options
    ---@class TotoWarCbac_Options
    options = {
        ---Maximum percentage of heroes in AI armies.
        aiArmyHeroMaximumPercentage = TotoWar_Cbac_OptionDefaultValue_AiArmyHeroMaximumPercentage,

        ---Total army supplies available in an army for the AI.
        aiArmySuppliesAmount = TotoWar_Cbac_OptionDefaultValue_AiArmySuppliesAmount,

        ---Bonus army supplies per level of the lord in AI armies.
        aiArmySuppliesBonusAmountPerLevel = TotoWar_Cbac_OptionDefaultValue_AiArmySuppliesBonusAmountPerLevel,

        ---Indicates whether army supplies restrictions are enabled for AI armies.
        aiArmySuppliesEnabled = TotoWar_Cbac_OptionDefaultValue_AiArmySuppliesEnabled,

        ---Maximum percentage of each unit category to target in AI armies.
        ---@type TotoWarDictionary<string, number>
        aiArmyUnitCategoryMaximumPercentages = TotoWarDictionary.new(),

        ---Total army supplies available in an army for the player.
        playerArmySuppliesAmount = TotoWar_Cbac_OptionDefaultValue_PlayerArmySuppliesAmount,

        ---Bonus army supplies per level of the lord in player armies.
        playerArmySuppliesBonusAmountPerLevel = TotoWar_Cbac_OptionDefaultValue_PlayerArmySuppliesBonusAmountPerLevel,

        ---Indicates whether army supplies restrictions are enabled for player armies.
        playerArmySuppliesEnabled = TotoWar_Cbac_OptionDefaultValue_PlayerArmySuppliesEnabled
    },

    ---Manager for player army supplies.
    ---@type TotoWarCbacPlayerManager
    playerManager = nil,

    ---Manager for displaying army supplies in the UI.
    ---@type TotoWarCbacUIManager
    uiManager = nil

}
TotoWarCbacMod.__index = TotoWarCbacMod

---TotoWar Cost-Based Army Cost mod instance.
---@type TotoWarCbacMod
TotoWarCbac = nil

---Initializes a new instance.
---@return TotoWarCbacMod
function TotoWarCbacMod.new()
    TotoWarCbac = setmetatable({}, TotoWarCbacMod)

    TotoWarCbac:initializeLoggers()

    -- Initialize the dictionary with default values
    TotoWarCbac.options.aiArmyUnitCategoryMaximumPercentages:set("artillery",
        TotoWar_Cbac_OptionDefaultValue_AiArmyArtilleryMaximumPercentage)
    TotoWarCbac.options.aiArmyUnitCategoryMaximumPercentages:set("cavalryAndMonsters",
        TotoWar_Cbac_OptionDefaultValue_AiArmyCavalryAndMonstersMaximumPercentage)
    TotoWarCbac.options.aiArmyUnitCategoryMaximumPercentages:set("meleeInfantry",
        TotoWar_Cbac_OptionDefaultValue_AiArmyMeleeInfantryMaximumPercentage)
    TotoWarCbac.options.aiArmyUnitCategoryMaximumPercentages:set("rangedInfantry",
        TotoWar_Cbac_OptionDefaultValue_AiArmyMeleeInfantryMaximumPercentage)

    TotoWarCbac.aiManager = TotoWarCbacAiManager:new()
    TotoWarCbac.playerManager = TotoWarCbacPlayerManager:new()
    TotoWarCbac.uiManager = TotoWarCbacUIManager:new()

    TotoWarCbac:addListeners()
    TotoWarCbac:loadMctOptions()

    TotoWarCbac.loggers.generic:logInfo("TotoWar - Cost-Based Army Caps | Mod initialized")
    TotoWarCbac.loggers.generic:logDebug("TotoWarCbacMod.new(): COMPLETED")

    return TotoWarCbac
end

---Adds event listeners.
function TotoWarCbacMod:addListeners()
    TotoWarCbac.loggers.generic:logDebug("addListeners(): STARTED")

    TotoWar.utils:addListener(
        "TotoWarCbac",
        TotoWar.enums.modEvents.mctOptionsUpdated,
        true,
        function()
            TotoWarCbac:onMctOptionsUpdated()
        end)

    TotoWar.utils:addListener(
        "TotoWar",
        TotoWarCbac.enums.modEvents.optionsUpdated,
        true,
        function()
            TotoWarCbac:onOptionsUpdated()
        end)

    -- Manager listeners
    TotoWarCbac.aiManager:addListeners()
    TotoWarCbac.playerManager:addListeners()
    TotoWarCbac.uiManager:addListeners()

    TotoWarCbac.loggers.generic:logDebug("addListeners(): COMPLETED")
end

---Initializes loggers.
function TotoWarCbacMod:initializeLoggers()
    TotoWarCbac.loggers.aiManager = TotoWarLogger.new("TotoWarCbac_AiManager")
    TotoWarCbac.loggers.armySuppliesCost = TotoWarLogger.new("TotoWarCbac_ArmySuppliesCost")
    TotoWarCbac.loggers.generic = TotoWarLogger.new("TotoWarCbac_Generic")
    TotoWarCbac.loggers.playerManager = TotoWarLogger.new("TotoWarCbac_PlayerManager")
    TotoWarCbac.loggers.uiManager = TotoWarLogger.new("TotoWarCbac_UIManager")

    TotoWarCbac.loggers.generic:logDebug("initializeLoggers(): COMPLETED")
end

---Loads option values stored by the Mod Configuration Tool if it is installed.
function TotoWarCbacMod:loadMctOptions()
    local mct = TotoWar.utils:getMct()

    if not mct then
        return
    end

    TotoWarCbac.loggers.generic:logInfo("TotoWar - Cost-Based Army Caps | Loading options")

    local options = mct:get_mod_by_key(TotoWar_ModName)

    TotoWarCbac.options.aiArmyHeroMaximumPercentage = options
        :get_option_by_key(TotoWar_Cbac_OptionName_AiArmyHeroMaximumPercentage)
        :get_finalized_setting()
    TotoWarCbac.options.aiArmySuppliesBonusAmountPerLevel = options
        :get_option_by_key(TotoWar_Cbac_OptionName_AiArmySuppliesBonusAmountPerLevel)
        :get_finalized_setting()
    TotoWarCbac.options.aiArmySuppliesAmount = options
        :get_option_by_key(TotoWar_Cbac_OptionName_AiArmySuppliesAmount)
        :get_finalized_setting()
    TotoWarCbac.options.aiArmySuppliesEnabled = options
        :get_option_by_key(TotoWar_Cbac_OptionName_AiArmySuppliesEnabled)
        :get_finalized_setting()
    TotoWarCbac.options.aiArmyUnitCategoryMaximumPercentages:set(TotoWarCbac.enums.armyCompositionUnitTypes.artillery,
        options
        :get_option_by_key(TotoWar_Cbac_OptionName_AiArmyArtilleryMaximumPercentage)
        :get_finalized_setting() / 100)
    TotoWarCbac.options.aiArmyUnitCategoryMaximumPercentages:set(
        TotoWarCbac.enums.armyCompositionUnitTypes.cavalryAndMonsters,
        options
        :get_option_by_key(TotoWar_Cbac_OptionName_AiArmyCavalryAndMonstersMaximumPercentage)
        :get_finalized_setting() / 100)
    TotoWarCbac.options.aiArmyUnitCategoryMaximumPercentages:set(
        TotoWarCbac.enums.armyCompositionUnitTypes.meleeInfantry,
        options
        :get_option_by_key(TotoWar_Cbac_OptionName_AiArmyMeleeInfantryMaximumPercentage)
        :get_finalized_setting() / 100)
    TotoWarCbac.options.aiArmyUnitCategoryMaximumPercentages:set(
        TotoWarCbac.enums.armyCompositionUnitTypes.rangedInfantry,
        options
        :get_option_by_key(TotoWar_Cbac_OptionName_AiArmyRangedInfantryMaximumPercentage)
        :get_finalized_setting() / 100)

    TotoWarCbac.options.playerArmySuppliesAmount = options
        :get_option_by_key(TotoWar_Cbac_OptionName_PlayerArmySuppliesAmount)
        :get_finalized_setting()
    TotoWarCbac.options.playerArmySuppliesBonusAmountPerLevel = options
        :get_option_by_key(TotoWar_Cbac_OptionName_PlayerArmySuppliesBonusAmountPerLevel)
        :get_finalized_setting()
    TotoWarCbac.options.playerArmySuppliesEnabled = options
        :get_option_by_key(TotoWar_Cbac_OptionName_PlayerArmySuppliesEnabled)
        :get_finalized_setting()

    -- Signaling option changes
    core:trigger_event(TotoWarCbac.enums.modEvents.optionsUpdated)

    TotoWarCbac.loggers.generic:logInfo("TotoWar - Cost-Based Army Caps | Options loaded")
end

---Reacts to MCT options being updated.
function TotoWarCbacMod:onMctOptionsUpdated()
    TotoWarCbac.loggers.generic:logDebug("onMctOptionsUpdated(): STARTED")

    TotoWarCbac:loadMctOptions()

    TotoWarCbac.loggers.generic:logDebug("onMctOptionsUpdated(): COMPLETED")
end

---Reacts to TotoWar options being updated.
function TotoWarCbacMod:onOptionsUpdated()
    TotoWarCbac.loggers.generic:logDebug("onOptionsUpdated(): STARTED")

    -- Overriding options after they are loaded
    -- Must be executed first in this function
    TotoWarCbac:overwriteOptionsForDebug()

    TotoWarCbac.loggers.generic:logDebug("onOptionsUpdated(): COMPLETED")
end

---Allows to programatically overwrite option values for local debug purpose.
function TotoWarCbacMod:overwriteOptionsForDebug()
    TotoWarCbac.loggers.generic:logDebug("overwriteOptionsForDebug(): STARTED")

    -- Set override values here
    -- TotoWarCbac.loggers.aiManager.logLevel = TotoWar.enums.logSeverity.warning
    -- TotoWarCbac.loggers.armySuppliesCost.logLevel = TotoWar.enums.logSeverity.warning
    -- TotoWarCbac.loggers.generic.logLevel = TotoWar.enums.logSeverity.warning
    -- TotoWarCbac.loggers.playerManager.logLevel = TotoWar.enums.logSeverity.warning
    -- TotoWarCbac.loggers.uiManager.logLevel = TotoWar.enums.logSeverity.warning

    TotoWarCbac.loggers.generic:logDebug("overwriteOptionsForDebug(): COMPLETED")
end
