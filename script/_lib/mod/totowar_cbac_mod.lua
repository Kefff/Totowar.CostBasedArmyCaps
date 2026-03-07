---@type TotoWarCbac
local _instance = nil

---TotoWar mod form managing cost-Based army caps.
---@class TotoWarCbac
TotoWarCbac = {
    ---Total army supplies available in an army for the AI.
    ---@type number
    aiArmyArmySupplies = nil,

    ---Maximum number of units that can be discarded in order to make the recruitment of a new unit AI possible
    ---@type number
    aiUnitsToDiscardMaximumNumber = nil,

    ---Total army supplies available in an army for the player.
    ---@type number
    playerArmySupplies = nil,

    ---Manager for AI army supplies.
    ---@type TotoWarCbacAiManager
    aiManager = nil,

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
TotoWarCbac.__index = TotoWarCbac

---Gets the TotoWarCbac mod instance.
---@return TotoWarCbac
function TotoWar_Cbac()
    return _instance
end

---Initializes a new instance.
---@return TotoWarCbac
function TotoWarCbac.new()
    _instance = setmetatable({}, TotoWarCbac)

    _instance.logger = TotoWarLogger.new("TotoWar_Cbac")

    _instance.aiArmyArmySupplies = TotoWarCbacDefaultAiArmySupplies
    _instance.aiUnitsToDiscardMaximumNumber = TotoWarCbacDefaultAiUnitsToDiscardMaximumNumber
    _instance.playerArmySupplies = TotoWarCbacDefaultPlayerArmySupplies
    _instance:loadMctOptions()

    _instance.aiManager = TotoWarCbacAiManager:new()
    _instance.playerManager = TotoWarCbacPlayerManager:new()
    _instance.uiManager = TotoWarCbacUIManager:new()

    _instance:addListeners()

    _instance.logger:logDebug("new(): COMPLETED")

    return _instance
end

---Adds event listeners.
function TotoWarCbac:addListeners()
    self.logger:logDebug("addListeners(): STARTED")

    _instance.aiManager:addListeners()
    _instance.playerManager:addListeners()
    _instance.uiManager:addListeners()

    self.logger:logDebug("addListeners(): COMPLETED")
end

---Loads option values stored by the Mod Configuration Tool if it is installed.
function TotoWarCbac:loadMctOptions()
    local mct = TotoWar().utils:getMct()

    if not mct then
        return
    end

    self.logger:logDebug("addMctOptions(): STARTED")

    local options = mct:get_mod_by_key(TotoWarModName)
    self.aiArmyArmySupplies = options:get_option_by_key(TotoWarCbacAiArmySuppliesOptionName):get_finalized_setting()
    self.aiUnitsToDiscardMaximumNumber = options
        :get_option_by_key(TotoWarCbacAiUnitsToDiscardMaximumNumberOptionName)
        :get_finalized_setting()
    self.playerArmySupplies = options:get_option_by_key(TotoWarCbacPlayerArmySuppliesOptionName):get_finalized_setting()

    self.logger:logDebug("addMctOptions(): COMPLETED")
end
