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
            agent = "agent",
            artillery = "artillery",
            cavalryAndMonsters = "cavalryAndMonsters",
            general = "general",
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
            selectedGeneralArmySuppliesCostChanged = "TotoWarCbac_SelectedGeneralArmySuppliesCostChanged",

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

    ---Options
    ---@class TotoWarCbac_Options
    options = {
        ---Maximum amount of agents in AI armies.
        aiArmyAgentMaximumAmount =
            TotoWar_Cbac_OptionDefaultValue_AiArmyAgentMaximumAmount,

        ---Maximum number of units that can be discarded in order to make the recruitment of a new unit AI possible AI armies.
        aiArmyDisposableUnitsMaximumAmount = TotoWar_Cbac_OptionDefaultValue_AiArmyDisposableUnitsMaximumAmount,

        ---Total army supplies available in an army for the AI.
        aiArmySuppliesAmount = TotoWar_Cbac_OptionDefaultValue_AiArmySuppliesAmount,

        ---Indicates whether army supplies restrictions are enabled for AI armies.
        aiArmySuppliesEnabled = TotoWar_Cbac_OptionDefaultValue_AiArmySuppliesEnabled,

        ---Maximum percentage of each unit category to target in AI armies.
        aiArmyUnitCategoryMaximumPercentages = {
            ["artillery"] = TotoWar_Cbac_OptionDefaultValue_AiArmyArtilleryMaximumPercentage,
            ["cavalryAndMonsters"] = TotoWar_Cbac_OptionDefaultValue_AiArmyCavalryAndMonstersMaximumPercentage,
            ["meleeInfantry"] = TotoWar_Cbac_OptionDefaultValue_AiArmyDisposableUnitsMaximumAmount,
            ["rangedInfantry"] = TotoWar_Cbac_OptionDefaultValue_AiArmyMeleeInfantryMaximumPercentage,
        },

        ---Total army supplies available in an army for the player.
        playerArmySuppliesAmount = TotoWar_Cbac_OptionDefaultValue_PlayerArmySuppliesAmount,

        ---Indicates whether army supplies restrictions are enabled for player armies.
        playerArmySuppliesEnabled = TotoWar_Cbac_OptionDefaultValue_PlayerArmySuppliesEnabled,
    },

    ---Logger.
    ---@type TotoWarLogger
    logger = nil,

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

    TotoWarCbac.logger = TotoWarLogger.new("TotoWar_Cbac")

    TotoWarCbac.aiManager = TotoWarCbacAiManager:new()
    TotoWarCbac.playerManager = TotoWarCbacPlayerManager:new()
    TotoWarCbac.uiManager = TotoWarCbacUIManager:new()

    TotoWarCbac:loadMctOptions()
    TotoWarCbac:addListeners()

    TotoWarCbac.logger:logDebug("new(): COMPLETED")

    return TotoWarCbac
end

---Adds event listeners.
function TotoWarCbacMod:addListeners()
    self.logger:logDebug("addListeners(): STARTED")

    TotoWar.utils:addListener(
        "TotoWarCbac",
        TotoWar.enums.modEvents.mctOptionsUpdated,
        true,
        function()
            self:onOptionsUpdated()
        end)

    -- Manager listeners
    TotoWarCbac.aiManager:addListeners()
    TotoWarCbac.playerManager:addListeners()
    TotoWarCbac.uiManager:addListeners()

    self.logger:logDebug("addListeners(): COMPLETED")
end

---Loads option values stored by the Mod Configuration Tool if it is installed.
function TotoWarCbacMod:loadMctOptions()
    local mct = TotoWar.utils:getMct()

    if not mct then
        return
    end

    self.logger:logDebug("loadMctOptions(): STARTED")

    local options = mct:get_mod_by_key(TotoWar_ModName)

    self.options.aiArmyAgentMaximumAmount = options
        :get_option_by_key(TotoWar_Cbac_OptionName_AiArmyAgentMaximumAmount)
        :get_finalized_setting()
    self.options.aiArmyDisposableUnitsMaximumAmount = options
        :get_option_by_key(TotoWar_Cbac_OptionName_AiDisposableUnitsMaximumAmount)
        :get_finalized_setting()
    self.options.aiArmySuppliesAmount = options
        :get_option_by_key(TotoWar_Cbac_OptionName_AiArmySuppliesAmount)
        :get_finalized_setting()
    self.options.aiArmySuppliesEnabled = options
        :get_option_by_key(TotoWar_Cbac_OptionName_AiArmySuppliesEnabled)
        :get_finalized_setting()
    self.options.aiArmyUnitCategoryMaximumPercentages[self.enums.armyCompositionUnitTypes.artillery] = options
        :get_option_by_key(TotoWar_Cbac_OptionName_AiArmyArtilleryMaximumPercentage)
        :get_finalized_setting() / 100
    self.options.aiArmyUnitCategoryMaximumPercentages[self.enums.armyCompositionUnitTypes.cavalryAndMonsters] = options
        :get_option_by_key(TotoWar_Cbac_OptionName_AiArmyCavalryAndMonstersMaximumPercentage)
        :get_finalized_setting() / 100
    self.options.aiArmyUnitCategoryMaximumPercentages[self.enums.armyCompositionUnitTypes.meleeInfantry] = options
        :get_option_by_key(TotoWar_Cbac_OptionName_AiArmyMeleeInfantryMaximumPercentage)
        :get_finalized_setting() / 100
    self.options.aiArmyUnitCategoryMaximumPercentages[self.enums.armyCompositionUnitTypes.rangedInfantry] = options
        :get_option_by_key(TotoWar_Cbac_OptionName_AiArmyRangedInfantryMaximumPercentage)
        :get_finalized_setting() / 100

    self.options.playerArmySuppliesAmount = options
        :get_option_by_key(TotoWar_Cbac_OptionName_PlayerArmySuppliesAmount)
        :get_finalized_setting()
    self.options.playerArmySuppliesEnabled = options
        :get_option_by_key(TotoWar_Cbac_OptionName_PlayerArmySuppliesEnabled)
        :get_finalized_setting()

    self.aiManager.logger.isEnabled = options
        :get_option_by_key(TotoWar_Cbac_OptionName_AiManagerLoggerEnabled)
        :get_finalized_setting()
    self.playerManager.logger.isEnabled = options
        :get_option_by_key(TotoWar_Cbac_OptionName_PlayerManagerLoggerEnabled)
        :get_finalized_setting()
    self.uiManager.logger.isEnabled = options
        :get_option_by_key(TotoWar_Cbac_OptionName_UiManagerLoggerEnabled)
        :get_finalized_setting()

    self.logger:logDebug("loadMctOptions(): COMPLETED")
end

---Reacts to options being updated.
function TotoWarCbacMod:onOptionsUpdated()
    self.logger:logDebug("[EVENT] onOptionsUpdated(): STARTED")

    self:loadMctOptions()

    -- Signaling option changes
    core:trigger_event(self.enums.modEvents.optionsUpdated)

    self.logger:logDebug("[EVENT] onOptionsUpdated(): COMPLETED")
end
