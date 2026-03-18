---Army supplies cost of the units in an army.
---@class TotoWarCbacArmySuppliesCost
TotoWarCbacArmySuppliesCost = {
    ---Army supplies available to recruit additional units.
    availableSupplies = nil,

    ---Army supplies cost of each mercenary unit in the recruitment pool.
    ---Mercenary units are identified by their index in this table.
    ---@type TotoWarCbacUnitArmySuppliesCost[]
    inRecruitmentMercenaryUnits = nil,

    ---Army supplies cost of each unit type present in the army.
    ---@type TotoWarCbacUnitArmySuppliesCost[]
    unitGroups = nil,

    ---Total army supplies cost
    ---@type integer
    totalCost = nil,
}
TotoWarCbacArmySuppliesCost.__index = TotoWarCbacArmySuppliesCost

---Initializes a new instance of TotoWarCbacArmySuppliesCost.
---@param availableArmySupplies number Total available army supplies in the army.
---@return TotoWarCbacArmySuppliesCost
function TotoWarCbacArmySuppliesCost.new(availableArmySupplies)
    local instance = setmetatable({}, TotoWarCbacArmySuppliesCost)

    instance.availableSupplies = availableArmySupplies
    instance.inRecruitmentMercenaryUnits = {}
    instance.unitGroups = {}
    instance.totalCost = 0

    TotoWar.genericLogger:logDebug("TotoWarCbacArmySuppliesCost.new(): COMPLETED")

    return instance
end

---Adds a unit to the army supplies cost.
---@param unitKey string Unit key.
---@param isInRecruitmentMercenary boolean Indicates whether the unit added is a mercenary unit (regiment of renown, Grudge settles, Waaagh mobs, ...) in the recruitment pool.
function TotoWarCbacArmySuppliesCost:addUnit(unitKey, isInRecruitmentMercenary)
    TotoWar.genericLogger:logDebug(
        "TotoWarCbacArmySuppliesCost:addUnit(%s, %s): STARTED",
        function() return TotoWar.utils:getUnitCaption(unitKey) end,
        function() return isInRecruitmentMercenary end)

    local unitArmySuppliesCost = 0

    if isInRecruitmentMercenary then
        unitArmySuppliesCost = common.get_context_value("CcoMainUnitRecord", unitKey, "BaseCost")
        local unitGroup = TotoWarCbacUnitArmySuppliesCost.new(unitKey, unitArmySuppliesCost)
        table.insert(self.inRecruitmentMercenaryUnits, unitGroup)
    else
        local unitGroup = TotoWar.utils:tableFirstOrDefault(
            self.unitGroups,
            function(ug) return ug.unitKey == unitKey end)

        if unitGroup then
            unitArmySuppliesCost = unitGroup.unitArmySuppliesCost
            unitGroup:addUnit()
        else
            unitArmySuppliesCost = common.get_context_value("CcoMainUnitRecord", unitKey, "BaseCost")
            local unitGroup = TotoWarCbacUnitArmySuppliesCost.new(unitKey, unitArmySuppliesCost)
            table.insert(self.unitGroups, unitGroup)
        end
    end

    self.totalCost = self.totalCost + unitArmySuppliesCost
    self.availableSupplies = TotoWarCbac.playerArmySuppliesAmount - self.totalCost

    TotoWar.genericLogger:logDebug(
        "TotoWarCbacArmySuppliesCost:addUnit(%s; %s): COMPLETED => %s",
        function() return TotoWar.utils:getUnitCaption(unitKey) end,
        function() return isInRecruitmentMercenary end,
        function() return self.totalCost end)
end

---Clears the list of in-recruitment mercenary units supply costs.
function TotoWarCbacArmySuppliesCost:clearMercenaryRecruitment()
    TotoWar.genericLogger:logDebug("TotoWarCbacArmySuppliesCost:clearMercenaryRecruitment(): STARTED")

    for i = 1, #self.inRecruitmentMercenaryUnits, 1 do
        self:removeUnit(TotoWar.enums.uiPatterns.inRecruitmentMercenaryUnitCard:sub(2) .. "0")
    end

    TotoWar.genericLogger:logDebug("TotoWarCbacArmySuppliesCost:clearMercenaryRecruitment(): COMPLETED")
end

---Removes a unit from the army supplies cost.
---
---When removing a mercenary unit, returns the key of the removed unit.
---This is useful to know which unit was removed because we only know the position
---position of the unit in the recruitment queue before calling `removeUnit`.
---@param unitKey string Unit key.
---@return string | nil
function TotoWarCbacArmySuppliesCost:removeUnit(unitKey)
    TotoWar.genericLogger:logDebug(
        "TotoWarCbacArmySuppliesCost:removeUnit(%s): STARTED",
        function() return TotoWar.utils:getUnitCaption(unitKey) end)

    local isInRecruitmentMercenaryUnit = string.match(
        unitKey,
        TotoWar.enums.uiPatterns.inRecruitmentMercenaryUnitCard)

    if isInRecruitmentMercenaryUnit then
        local positionInRecruitmentQueuePattern =
            TotoWar.enums.uiPatterns.inRecruitmentMercenaryUnitCard .. "(%d+)$"

        -- Position starts at 0 in the recruitment queue, but LUA table indexes start at 1
        local index = tonumber(unitKey:match(positionInRecruitmentQueuePattern)) + 1

        local unitGroup = self.inRecruitmentMercenaryUnits[index]
        self.totalCost = self.totalCost - unitGroup.unitArmySuppliesCost
        self.availableSupplies = TotoWarCbac.playerArmySuppliesAmount - self.totalCost
        table.remove(self.inRecruitmentMercenaryUnits, index)

        TotoWar.genericLogger:logDebug(
            "TotoWarCbacArmySuppliesCost:removeUnit(%s): COMPLETED => %s",
            function() return TotoWar.utils:getUnitCaption(unitKey) end,
            function() return self.totalCost end)

        return unitGroup.unitKey;
    else
        for index, unitGroup in ipairs(self.unitGroups) do
            if unitGroup.unitKey == unitKey then
                self.totalCost = self.totalCost - unitGroup.unitArmySuppliesCost
                self.availableSupplies = TotoWarCbac.playerArmySuppliesAmount - self.totalCost

                if (unitGroup.unitCount == 1) then
                    table.remove(self.unitGroups, index)
                else
                    unitGroup:removeUnit()
                end

                TotoWar.genericLogger:logDebug(
                    "TotoWarCbacArmySuppliesCost:removeUnit(%s): COMPLETED => %s",
                    function() return TotoWar.utils:getUnitCaption(unitKey) end,
                    function() return self.totalCost end)

                return unitKey;
            end
        end
    end

    TotoWar.genericLogger:logError(
        "TotoWarCbacArmySuppliesCost:removeUnit(%s): NOT FOUND",
        TotoWar.utils:getUnitCaption(unitKey))
end

---Gets the list of unit army supplies costs as a tooltip string.
---@return string
function TotoWarCbacArmySuppliesCost:toArmySuppliesCostTooltipText()
    TotoWar.genericLogger:logDebug("TotoWarCbacArmySuppliesCost:toTooltipText(): STARTED")

    local unitsArmySuppliesCostTooltipText = ""

    for i, unitArmySuppliesCost in ipairs(self.unitGroups) do
        unitsArmySuppliesCostTooltipText =
            unitsArmySuppliesCostTooltipText .. "\n" .. unitArmySuppliesCost:toArmySuppliesCostTooltipText()
    end

    for i, mercenaryUnitArmySuppliesCost in ipairs(self.inRecruitmentMercenaryUnits) do
        unitsArmySuppliesCostTooltipText =
            unitsArmySuppliesCostTooltipText .. "\n" .. mercenaryUnitArmySuppliesCost:toArmySuppliesCostTooltipText()
    end

    local availableArmySuppliesString = tostring(self.availableSupplies)
    local depletedArmySuppliesWarning = ""

    if self.availableSupplies < 0 then
        availableArmySuppliesString = string.format(
            "[[col:%s]]%s[[/col]]",
            TotoWar.enums.colors.red,
            availableArmySuppliesString)
        depletedArmySuppliesWarning = string.format(
            "\n\n[[col:%s]]%s[[/col]]",
            TotoWar.enums.colors.red,
            common.get_localised_string("totowar_cbac_tooltip_unit_armySuppliesCostDepleted"))
    end

    local tooltipText = string.format(
        common.get_localised_string("totowar_cbac_tooltip_armySuppliesCost"),
        TotoWarCbac.playerArmySuppliesAmount,
        self.totalCost,
        availableArmySuppliesString,
        depletedArmySuppliesWarning,
        unitsArmySuppliesCostTooltipText)

    TotoWar.genericLogger:logDebug("TotoWarCbacArmySuppliesCost:toTooltipText(): COMPLETED")

    return tooltipText
end
