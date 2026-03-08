---TotoWar mod form managing cost-Based army caps.
---@class TotoWarCbacMod
TotoWarCbacMod = {
    ---Total army supplies available in an army for the AI.
    ---@type number
    aiArmySuppliesAmount = TotoWar_Cbac_OptionDefaultValue_AiArmySuppliesAmount,

    ---Indicates whether army supplies restrictions are enabled for AI armies.
    ---@type boolean
    aiArmySuppliesEnabled = TotoWar_Cbac_OptionDefaultValue_AiArmySuppliesEnabled,

    ---Maximum number of units that can be discarded in order to make the recruitment of a new unit AI possible
    ---@type number
    aiDisposableUnitsMaximumAmount = TotoWar_Cbac_OptionDefaultValue_AiDisposableUnitsMaximumAmount,

    ---Manager for AI army supplies.
    ---@type TotoWarCbacAiManager
    aiManager = nil,

    ---Logger.
    ---@type TotoWarLogger
    logger = nil,

    ---Total army supplies available in an army for the player.
    ---@type number
    playerArmySuppliesAmount = TotoWar_Cbac_OptionDefaultValue_PlayerArmySuppliesAmount,

    ---Indicates whether army supplies restrictions are enabled for player armies.
    ---@type boolean
    playerArmySuppliesEnabled = TotoWar_Cbac_OptionDefaultValue_PlayerArmySuppliesEnabled,

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

    TotoWarCbac:loadMctOptions()

    TotoWarCbac.aiManager = TotoWarCbacAiManager:new()
    TotoWarCbac.playerManager = TotoWarCbacPlayerManager:new()
    TotoWarCbac.uiManager = TotoWarCbacUIManager:new()

    TotoWarCbac:addListeners()

    TotoWarCbac.logger:logDebug("new(): COMPLETED")

    return TotoWarCbac
end

---Adds event listeners.
function TotoWarCbacMod:addListeners()
    self.logger:logDebug("addListeners(): STARTED")

    -- Listener for option updates
    TotoWar.utils:addListener(
        "TotoWarCbac",
        TotoWar.utils.enums.events.mctOptionsUpdated,
        true,
        function()
            self:loadMctOptions()
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

    self.logger:logDebug("addMctOptions(): STARTED")

    local options = mct:get_mod_by_key(TotoWar_ModName)
    self.aiArmySuppliesAmount = options:get_option_by_key(TotoWar_Cbac_OptionName_AiArmySuppliesAmount)
        :get_finalized_setting()
    self.aiArmySuppliesEnabled = options:get_option_by_key(TotoWar_Cbac_OptionName_AiArmySuppliesEnabled)
        :get_finalized_setting()
    self.aiDisposableUnitsMaximumAmount = options
        :get_option_by_key(TotoWar_Cbac_OptionName_AiDisposableUnitsMaximumAmount)
        :get_finalized_setting()
    self.playerArmySuppliesAmount = options:get_option_by_key(TotoWar_Cbac_OptionName_PlayerArmySuppliesAmount)
        :get_finalized_setting()
    self.playerArmySuppliesEnabled = options:get_option_by_key(TotoWar_Cbac_OptionName_PlayerArmySuppliesEnabled)
        :get_finalized_setting()

    self.logger:logDebug("addMctOptions(): COMPLETED")
end
