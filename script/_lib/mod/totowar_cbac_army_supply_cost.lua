---@class TotoWarArmySupplyCost
TotoWarArmySupplyCost = {
    ---Total army supply cost detailed by unit type.
    ---@type TotoWarUnitArmySupplyCost[]
    details = nil,

    ---Total army supply cost
    ---@type number
    totalCost = 0,
}
TotoWarArmySupplyCost.__index = TotoWarArmySupplyCost

---Initializes a new instance of TotoWarArmySupplyCost.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE
---@return TotoWarArmySupplyCost
function TotoWarArmySupplyCost.new(army)
    local instance = setmetatable({}, TotoWarArmySupplyCost)

    local units = army:unit_list()
    local details = {}

    for i = 0, units:num_items() - 1, 1 do
        local unit = units:item_at(i)
        local unitCost = unit:get_unit_custom_battle_cost()

        ---@type TotoWarUnitArmySupplyCost
        local unitArmySupplyCost = nil

        for index, detail in ipairs(details) do
            if detail.unitKey == unit:unit_key() then
                unitArmySupplyCost = detail
                break
            end
        end

        if not unitArmySupplyCost then
            unitArmySupplyCost = TotoWarUnitArmySupplyCost.new(unit:unit_key(), unitCost)
            table.insert(details, unitArmySupplyCost)
        else
            unitArmySupplyCost:addUnit()
        end

        instance.totalCost = instance.totalCost + unitCost
    end

    instance.details = details

    return instance
end

---Gets the list of unit army costs as a tooltip string.
---@param armySupply number Army supply.
---@return string
function TotoWarArmySupplyCost:toTooltipText(armySupply)
    local unitsArmySupplyCostTooltipText = ""

    for index, unitArmySupplyCost in ipairs(self.details) do
        if index > 0 then
            unitsArmySupplyCostTooltipText = unitsArmySupplyCostTooltipText .. "\n"
        end

        unitsArmySupplyCostTooltipText = unitsArmySupplyCostTooltipText .. unitArmySupplyCost:toTooltipText()
    end

    local availableArmySupply = armySupply - self.totalCost
    local tooltipText = string.format(
        common.get_localised_string("totowar_cbac_army_supply_cost_tooltip"),
        armySupply,
        self.totalCost,
        availableArmySupply,
        unitsArmySupplyCostTooltipText)

    return tooltipText
end

---@class TotoWarUnitArmySupplyCost
TotoWarUnitArmySupplyCost = {
    ---Army supply cost of all the units of this type.
    ---@type number
    totalCost = 0,

    ---Army supply cost of one unit of this type.
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
TotoWarUnitArmySupplyCost.__index = TotoWarUnitArmySupplyCost

---Initializes a new instance of TotoWarUnitArmySupplyCost.
---@param unitKey string Unit key.
---@param unitCost number Unit cost.
---@return TotoWarUnitArmySupplyCost
function TotoWarUnitArmySupplyCost.new(unitKey, unitCost)
    local instance = setmetatable({}, TotoWarUnitArmySupplyCost)

    instance.unitCaption = TotoWarUtils:getUnitCaption(unitKey)
    instance.unitCost = unitCost
    instance.unitKey = unitKey
    instance:addUnit()

    return instance
end

---Adds one unit.
function TotoWarUnitArmySupplyCost:addUnit()
    self.totalCost = self.totalCost + self.unitCost
    self.unitCount = self.unitCount + 1

    TotoWarUtils.logger:logDebug("TEST: %s, %s", tostring(self.totalCost), tostring(self.unitCount))
end

---Gets a unit army cost as a tooltip string.
---@return string
function TotoWarUnitArmySupplyCost:toTooltipText()
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

    return tooltipText
end
