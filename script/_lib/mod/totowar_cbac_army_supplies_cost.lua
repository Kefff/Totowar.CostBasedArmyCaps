---@class TotoWarArmySuppliesCost
TotoWarArmySuppliesCost = {
    ---Total army supplies cost detailed by unit type.
    ---@type TotoWarUnitArmySuppliesCost[]
    details = nil,

    ---Total army supplies cost
    ---@type number
    totalCost = 0,
}
TotoWarArmySuppliesCost.__index = TotoWarArmySuppliesCost

---Initializes a new instance of TotoWarArmySuppliesCost.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE
---@return TotoWarArmySuppliesCost
function TotoWarArmySuppliesCost.new(army)
    local instance = setmetatable({}, TotoWarArmySuppliesCost)

    local units = army:unit_list()
    local details = {}

    for i = 0, units:num_items() - 1, 1 do
        local unit = units:item_at(i)
        local unitCost = unit:get_unit_custom_battle_cost()

        ---@type TotoWarUnitArmySuppliesCost
        local unitArmySuppliesCost = nil

        for index, detail in ipairs(details) do
            if detail.unitKey == unit:unit_key() then
                unitArmySuppliesCost = detail
                break
            end
        end

        if not unitArmySuppliesCost then
            unitArmySuppliesCost = TotoWarUnitArmySuppliesCost.new(unit:unit_key(), unitCost)
            table.insert(details, unitArmySuppliesCost)
        else
            unitArmySuppliesCost:addUnit()
        end

        instance.totalCost = instance.totalCost + unitCost
    end

    instance.details = details

    return instance
end

---Gets the list of unit army costs as a tooltip string.
---@param armySupplies number Army supplies.
---@return string
function TotoWarArmySuppliesCost:toTooltipText(armySupplies)
    local unitsArmySuppliesCostTooltipText = ""

    for index, unitArmySuppliesCost in ipairs(self.details) do
        if index > 0 then
            unitsArmySuppliesCostTooltipText = unitsArmySuppliesCostTooltipText .. "\n"
        end

        unitsArmySuppliesCostTooltipText = unitsArmySuppliesCostTooltipText .. unitArmySuppliesCost:toTooltipText()
    end

    local availableArmySupplies = armySupplies - self.totalCost
    local availableArmySuppliesString = tostring(availableArmySupplies)
    local depletedArmySuppliesWarning = ""

    if availableArmySupplies < 0 then
        availableArmySuppliesString = string.format(
            "[[col:%s]]%s[[/col]]",
            TotoWarUtils.Enums.Color.red,
            availableArmySupplies)
        depletedArmySuppliesWarning = string.format(
            "\n\n[[col:%s]]%s[[/col]]",
            TotoWarUtils.Enums.Color.red,
            common.get_localised_string("totowar_cbac_unit_army_supply_cost_tooltip_depleted"))
    end

    local tooltipText = string.format(
        common.get_localised_string("totowar_cbac_army_supply_cost_tooltip"),
        armySupplies,
        self.totalCost,
        availableArmySuppliesString,
        depletedArmySuppliesWarning,
        unitsArmySuppliesCostTooltipText)

    return tooltipText
end

---@class TotoWarUnitArmySuppliesCost
TotoWarUnitArmySuppliesCost = {
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
TotoWarUnitArmySuppliesCost.__index = TotoWarUnitArmySuppliesCost

---Initializes a new instance of TotoWarUnitArmySuppliesCost.
---@param unitKey string Unit key.
---@param unitCost number Unit cost.
---@return TotoWarUnitArmySuppliesCost
function TotoWarUnitArmySuppliesCost.new(unitKey, unitCost)
    local instance = setmetatable({}, TotoWarUnitArmySuppliesCost)

    instance.unitCaption = TotoWarUtils:getUnitCaption(unitKey)
    instance.unitCost = unitCost
    instance.unitKey = unitKey
    instance:addUnit()

    return instance
end

---Adds one unit.
function TotoWarUnitArmySuppliesCost:addUnit()
    self.totalCost = self.totalCost + self.unitCost
    self.unitCount = self.unitCount + 1

    TotoWarUtils.logger:logDebug("TEST: %s, %s", tostring(self.totalCost), tostring(self.unitCount))
end

---Gets a unit army cost as a tooltip string.
---@return string
function TotoWarUnitArmySuppliesCost:toTooltipText()
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
