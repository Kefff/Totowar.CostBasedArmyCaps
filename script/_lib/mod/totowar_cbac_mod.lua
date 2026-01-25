---Name of the TotoWar Cost-Based Army Caps mod.
---@type string
TotoWarCbacModName = "totowar_cost_based_army_caps"

---Default amount of army supplies per army.
---Sadly, it cannot be read from DB table (mp_budgets_table) because LUA scripts do not not have access to them.
---@type number
local _defaultArmySupplies = 12400

---@type TotoWarCbac
local _instance = nil

---TotoWar mod form managing cost-Based army caps.
---@class TotoWarCbac
TotoWarCbac = {
    ---Total army supplies in an army.
    ---@type number
    armyTotalArmySupplies = nil,

    ---Logger.
    ---@type TotoWarLogger
    logger = nil,

    ---@type TotoWarCbacPlayerManager
    playerManager = nil,

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

    _instance.armyTotalArmySupplies = _defaultArmySupplies

    _instance.playerManager = TotoWarCbacPlayerManager:new()
    _instance.uiManager = TotoWarCbacUIManager:new()

    _instance:addListeners()

    _instance.logger:logDebug("new(): COMPLETED")

    return _instance
end

---Adds event listeners.
function TotoWarCbac:addListeners()
    self.logger:logDebug("addListeners(): STARTED")

    _instance.playerManager:addListeners()
    _instance.uiManager:addListeners()

    self.logger:logDebug("addListeners(): COMPLETED")
end
