---Name of the TotoWar Cost-Based Army Caps mod.
---@type string
TotoWarCbacModName = "totowar_cost_based_army_caps"

---Default amount of army supplies per army for the AI.
---Sadly, it cannot be read from DB table (mp_budgets_table) because LUA scripts do not not have access to them.
---@type number
local _defaultAiArmySupplies = 12400

---Default amount of army supplies per army for the player.
---Sadly, it cannot be read from DB table (mp_budgets_table) because LUA scripts do not not have access to them.
---@type number
local _defaultPlayerArmySupplies = 12400

---@type TotoWarCbac
local _instance = nil

---TotoWar mod form managing cost-Based army caps.
---@class TotoWarCbac
TotoWarCbac = {
    ---Total army supplies available in an army for the AI.
    ---@type number
    armySuppliesPerAiArmy = nil,

    ---Total army supplies available in an army for the player.
    ---@type number
    armySuppliesPerPlayerArmy = nil,

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

    _instance.armySuppliesPerAiArmy = _defaultAiArmySupplies
    _instance.armySuppliesPerPlayerArmy = _defaultPlayerArmySupplies

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
