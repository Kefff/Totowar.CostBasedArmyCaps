---Army supplies cost of the units in an army.
---@class TotoWarCbacArmySuppliesCost
TotoWarCbacArmySuppliesCost = {
    ---Army supplies cost of each mercenary unit in the recruitment pool.
    ---Mercenary units are identified by their index in this table.
    ---@type TotoWarCbacUnitArmySuppliesCost[]
    inRecruitmentMercenaries = {},

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
---@param isInRecruitmentMercenary boolean Indicates whether the unit added is a mercenary unit (regiment of renown, Grudge settles, Waaagh mobs, ...) in the recruitment pool.
function TotoWarCbacArmySuppliesCost:addUnit(unitKey, isInRecruitmentMercenary)
    TotoWar().genericLogger:logDebug(
        "TotoWarCbacArmySuppliesCost:addUnit(%s, %s): STARTED",
        unitKey,
        isInRecruitmentMercenary)

    local unitArmySuppliesCost = 0

    if isInRecruitmentMercenary then
        unitArmySuppliesCost = common.get_context_value("CcoMainUnitRecord", unitKey, "BaseCost")
        local unitGroup = TotoWarCbacUnitArmySuppliesCost.new(unitKey, unitArmySuppliesCost)
        table.insert(self.inRecruitmentMercenaries, unitGroup)
    else
        local found = false

        for index, unitGroup in ipairs(self.unitGroups) do
            found = unitGroup.unitKey == unitKey

            if found then
                unitArmySuppliesCost = unitGroup.unitCost
                unitGroup:addUnit()

                break;
            end
        end

        if not found then
            unitArmySuppliesCost = common.get_context_value("CcoMainUnitRecord", unitKey, "BaseCost")
            local unitGroup = TotoWarCbacUnitArmySuppliesCost.new(unitKey, unitArmySuppliesCost)
            table.insert(self.unitGroups, unitGroup)
        end
    end

    self.totalCost = self.totalCost + unitArmySuppliesCost

    TotoWar().genericLogger:logDebug(
        "TotoWarCbacArmySuppliesCost:addUnit(%s; %s): COMPLETED => %s",
        unitKey,
        isInRecruitmentMercenary,
        self.totalCost)
end

---Removes a unit from the army supplies cost.
---@param unitKey string Unit key.
function TotoWarCbacArmySuppliesCost:removeUnit(unitKey)
    TotoWar().genericLogger:logDebug("TotoWarCbacArmySuppliesCost:removeUnit(%s): STARTED", unitKey)

    local isInRecruitmentMercenaryUnit = string.match(
        unitKey,
        TotoWar().ui.enums.patterns.inRecruitmentMercenaryUnitCard)

    if isInRecruitmentMercenaryUnit then
        local positionInRecruitmentQueuePattern =
            TotoWar().ui.enums.patterns.inRecruitmentMercenaryUnitCard .. "(%d+)$"

        -- Position starts at 0 in the recruitment queue, but LUA table indexes start at 1
        local index = tonumber(unitKey:match(positionInRecruitmentQueuePattern)) + 1

        local unitGroup = self.inRecruitmentMercenaries[index]
        self.totalCost = self.totalCost - unitGroup.unitCost
        table.remove(self.inRecruitmentMercenaries, index)

        TotoWar().genericLogger:logDebug(
            "TotoWarCbacArmySuppliesCost:removeUnit(%s): COMPLETED => %s",
            unitKey,
            self.totalCost)

        return;
    else
        for index, unitGroup in ipairs(self.unitGroups) do
            if unitGroup.unitKey == unitKey then
                self.totalCost = self.totalCost - unitGroup.unitCost

                if (unitGroup.unitCount == 1) then
                    table.remove(self.unitGroups, index)
                else
                    unitGroup:removeUnit()
                end

                TotoWar().genericLogger:logDebug(
                    "TotoWarCbacArmySuppliesCost:removeUnit(%s): COMPLETED => %s",
                    unitKey,
                    self.totalCost)

                return;
            end
        end
    end

    TotoWar().genericLogger:logError("TotoWarCbacArmySuppliesCost:removeUnit(%s): NOT FOUND", unitKey)
end

---Gets the list of unit army supplies costs as a tooltip string.
---@return string
function TotoWarCbacArmySuppliesCost:toArmySuppliesCostTooltipText()
    TotoWar().genericLogger:logDebug("TotoWarCbacArmySuppliesCost:toTooltipText(): STARTED")

    local unitsArmySuppliesCostTooltipText = ""

    for i, unitArmySuppliesCost in ipairs(self.unitGroups) do
        if #unitsArmySuppliesCostTooltipText > 0 then
            unitsArmySuppliesCostTooltipText = unitsArmySuppliesCostTooltipText .. "\n"
        end

        unitsArmySuppliesCostTooltipText =
            unitsArmySuppliesCostTooltipText .. unitArmySuppliesCost:toArmySuppliesCostTooltipText()
    end

    for i, unitArmySuppliesCost in ipairs(self.inRecruitmentMercenaries) do
        if #unitsArmySuppliesCostTooltipText > 0 then
            unitsArmySuppliesCostTooltipText = unitsArmySuppliesCostTooltipText .. "\n"
        end

        unitsArmySuppliesCostTooltipText =
            unitsArmySuppliesCostTooltipText .. unitArmySuppliesCost:toArmySuppliesCostTooltipText()
    end

    local availableArmySupplies = TotoWar_Cbac().armyTotalArmySupplies - self.totalCost
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
        TotoWar_Cbac().armyTotalArmySupplies,
        self.totalCost,
        availableArmySuppliesString,
        depletedArmySuppliesWarning,
        unitsArmySuppliesCostTooltipText)

    TotoWar().genericLogger:logDebug("TotoWarCbacArmySuppliesCost:toTooltipText(): COMPLETED")

    return tooltipText
end
