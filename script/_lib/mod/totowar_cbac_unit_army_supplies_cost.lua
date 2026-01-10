---@class TotoWarCbacUnitArmySuppliesCost
TotoWarCbacUnitArmySuppliesCost = {
    ---Army supplies cost of all the units of this type.
    ---@type number
    totalCost = 0,

    ---Army supplies cost of one unit of this type.
    ---@type number
    unitCost = 0,

    ---Caption of the unit.
    ---@type string
    unitCaption = nil,

    ---Number of units of this type.
    ---@type number
    unitCount = 0,

    ---Key of the unit.
    ---@type string
    unitKey = nil,
}
TotoWarCbacUnitArmySuppliesCost.__index = TotoWarCbacUnitArmySuppliesCost

---Initializes a new instance.
---@param unitKey string Unit key.
---@param unitCost number Unit cost.
---@return TotoWarCbacUnitArmySuppliesCost
function TotoWarCbacUnitArmySuppliesCost.new(unitKey, unitCost)
    TotoWar().genericLogger:logDebug("TotoWarCbacUnitArmySuppliesCost.new(%s, %s): STARTED", unitKey, unitCost)

    local instance = setmetatable({}, TotoWarCbacUnitArmySuppliesCost)

    instance.unitCaption = TotoWar().utils:getUnitCaption(unitKey)
    instance.unitCost = unitCost
    instance.unitKey = unitKey
    instance:addUnit()

    TotoWar().genericLogger:logDebug("TotoWarCbacUnitArmySuppliesCost.new(%s, %s): COMPLETED", unitKey, unitCost)

    return instance
end

---Adds one unit.
function TotoWarCbacUnitArmySuppliesCost:addUnit()
    TotoWar().genericLogger:logDebug("TotoWarCbacUnitArmySuppliesCost.addUnit(): STARTED")

    self.totalCost = self.totalCost + self.unitCost
    self.unitCount = self.unitCount + 1

    TotoWar().genericLogger:logDebug("TotoWarCbacUnitArmySuppliesCost.addUnit(): COMPLETED")
end

---Gets a unit army supplies cost as a tooltip string.
---@return string
function TotoWarCbacUnitArmySuppliesCost:toTooltipText()
    TotoWar().genericLogger:logDebug("TotoWarCbacUnitArmySuppliesCost:toTooltipText: STARTED")

    local tooltipText = ""

    if self.unitCount > 1 then
        tooltipText = tooltipText .. string.format(
            common.get_localised_string("totowar_cbac_army_supply_cost_tooltip_detail_multiple"),
            self.unitCaption,
            self.totalCost,
            self.unitCount,
            self.unitCost)
    else
        tooltipText = tooltipText .. string.format(
            common.get_localised_string("totowar_cbac_army_supply_cost_tooltip_detail"),
            self.unitCaption,
            self.unitCost)
    end

    TotoWar().genericLogger:logDebug("TotoWarCbacUnitArmySuppliesCost:toTooltipText: COMPLETED")

    return tooltipText
end
