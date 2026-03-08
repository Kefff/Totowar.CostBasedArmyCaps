---TotoWar mod form managing cost-Based army caps.
---@class TotoWarCbacMod
TotoWarCbacMod = {
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
TotoWarCbacMod.__index = TotoWarCbacMod

---TotoWar Cost-Based Army Cost mod instance.
---@type TotoWarCbacMod
TotoWarCbac = nil

---Initializes a new instance.
---@return TotoWarCbacMod
function TotoWarCbacMod.new()
    TotoWarCbac = setmetatable({}, TotoWarCbacMod)

    TotoWarCbac.logger = TotoWarLogger.new("TotoWar_Cbac")

    TotoWarCbac.aiArmyArmySupplies = TotoWarCbacDefaultAiArmySupplies
    TotoWarCbac.aiUnitsToDiscardMaximumNumber = TotoWarCbacDefaultAiUnitsToDiscardMaximumNumber
    TotoWarCbac.playerArmySupplies = TotoWarCbacDefaultPlayerArmySupplies
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

    local options = mct:get_mod_by_key(TotoWarModName)
    self.aiArmyArmySupplies = options:get_option_by_key(TotoWarCbacAiArmySuppliesOptionName):get_finalized_setting()
    self.aiUnitsToDiscardMaximumNumber = options
        :get_option_by_key(TotoWarCbacAiUnitsToDiscardMaximumNumberOptionName)
        :get_finalized_setting()
    self.playerArmySupplies = options:get_option_by_key(TotoWarCbacPlayerArmySuppliesOptionName):get_finalized_setting()

    self.logger:logDebug("addMctOptions(): COMPLETED")
end
