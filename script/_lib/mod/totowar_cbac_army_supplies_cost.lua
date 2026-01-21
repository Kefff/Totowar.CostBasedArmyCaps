---Army supplies cost of the units in an army.
---@class TotoWarCbacArmySuppliesCost
TotoWarCbacArmySuppliesCost = {
    ---Army supplies cost of each unit type present in the army.
    ---@type TotoWarCbacUnitArmySuppliesCost[]
    unitGroups = {},

    ---Total army supplies cost
    ---@type number
    totalCost = 0,
}
TotoWarCbacArmySuppliesCost.__index = TotoWarCbacArmySuppliesCost

---comment
---@return TotoWarCbacArmySuppliesCost
function TotoWarCbacArmySuppliesCost.new()
    local instance = setmetatable({}, TotoWarCbacArmySuppliesCost)

    TotoWar().genericLogger:logDebug("TotoWarCbacArmySuppliesCost.new(): COMPLETED")

    return instance
end

---Adds a unit to the army supplies cost.
---@param unitKey string Unit key.
function TotoWarCbacArmySuppliesCost:addUnit(unitKey)
    TotoWar().genericLogger:logDebug("TotoWarCbacArmySuppliesCost:addUnit(%s): STARTED", unitKey)

    for index, unitGroup in ipairs(self.unitGroups) do
        if unitGroup.unitKey == unitKey then
            unitGroup:addUnit()
            self.totalCost = self.totalCost + unitGroup.unitCost

            TotoWar().genericLogger:logDebug("TotoWarCbacArmySuppliesCost:addUnit(%s): COMPLETED", unitKey)

            return;
        end
    end

    local unitArmySuppliesCost = common.get_context_value("CcoMainUnitRecord", unitKey, "BaseCost")
    local unitGroup = TotoWarCbacUnitArmySuppliesCost.new(unitKey, unitArmySuppliesCost)
    table.insert(self.unitGroups, unitGroup)
    self.totalCost = self.totalCost + unitArmySuppliesCost

    TotoWar().genericLogger:logDebug("TotoWarCbacArmySuppliesCost:addUnit(%s): COMPLETED", unitKey)
end

---Removes a unit from the army supplies cost.
---@param unitKey string Unit key.
function TotoWarCbacArmySuppliesCost:removeUnit(unitKey)
    TotoWar().genericLogger:logDebug("TotoWarCbacArmySuppliesCost:removeUnit(%s): STARTED", unitKey)

    for index, unitGroup in ipairs(self.unitGroups) do
        if unitGroup.unitKey == unitKey then
            self.totalCost = self.totalCost - unitGroup.unitCost

            if (unitGroup.unitCount == 1) then
                table.remove(self.unitGroups, index)
            else
                unitGroup:removeUnit()
            end

            TotoWar().genericLogger:logDebug("TotoWarCbacArmySuppliesCost:removeUnit(%s): COMPLETED", unitKey)

            return;
        end
    end

    TotoWar().genericLogger:logError("TotoWarCbacArmySuppliesCost:removeUnit(%s): NOT FOUND")
end

---Gets the list of unit army supplies costs as a tooltip string.
---@return string
function TotoWarCbacArmySuppliesCost:toArmySuppliesCostTooltipText(armyTotalArmySupplies)
    TotoWar().genericLogger:logDebug("TotoWarCbacArmySuppliesCost:toTooltipText(%s): STARTED", armyTotalArmySupplies)

    local unitsArmySuppliesCostTooltipText = ""

    for i, unitArmySuppliesCost in ipairs(self.unitGroups) do
        if i > 0 then
            unitsArmySuppliesCostTooltipText = unitsArmySuppliesCostTooltipText .. "\n"
        end

        unitsArmySuppliesCostTooltipText = unitsArmySuppliesCostTooltipText ..
            unitArmySuppliesCost:toArmySuppliesCostTooltipText()
    end

    local availableArmySupplies = armyTotalArmySupplies - self.totalCost
    local availableArmySuppliesString = tostring(availableArmySupplies)
    local depletedArmySuppliesWarning = ""

    if availableArmySupplies < 0 then
        availableArmySuppliesString = string.format(
            "[[col:%s]]%s[[/col]]",
            TotoWar().utils.enums.color.red,
            availableArmySupplies)
        depletedArmySuppliesWarning = string.format(
            "\n\n[[col:%s]]%s[[/col]]",
            TotoWar().utils.enums.color.red,
            common.get_localised_string("totowar_cbac_unit_army_supply_cost_tooltip_depleted"))
    end

    local tooltipText = string.format(
        common.get_localised_string("totowar_cbac_army_supply_cost_tooltip"),
        armyTotalArmySupplies,
        self.totalCost,
        availableArmySuppliesString,
        depletedArmySuppliesWarning,
        unitsArmySuppliesCostTooltipText)

    TotoWar().genericLogger:logDebug("TotoWarCbacArmySuppliesCost:toTooltipText(%s): COMPLETED", armyTotalArmySupplies)

    return tooltipText
end
