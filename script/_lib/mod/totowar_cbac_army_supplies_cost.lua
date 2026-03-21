---Army supplies cost of the units in an army.
---@class TotoWarCbacArmySuppliesCost
TotoWarCbacArmySuppliesCost = {
    ---Army supplies available to recruit additional units.
    availableSupplies = nil,

    ---Army supplies cost of each mercenary unit in the recruitment pool.
    ---Mercenary units are identified by their index in this table.
    ---@type TotoWarCbacUnitArmySuppliesCost[]
    inRecruitmentMercenaryUnits = nil,

    ---Total army supplies cost
    ---@type integer
    totalCost = nil,

    ---Army supplies cost of each unit type present in the army.
    ---@type TotoWarCbacUnitArmySuppliesCost[]
    unitGroups = nil,
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
    self.availableSupplies = TotoWarCbac.options.playerArmySuppliesAmount - self.totalCost

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

---Gets the unit army composition type based on the category of a unit.
---@param unitKey string Unit key.
---@return string
function TotoWarCbacArmySuppliesCost:getUnitArmyCompositionUnitType(unitKey)
    TotoWar.genericLogger:logDebug(
        "TotoWarCbacArmySuppliesCost:getUnitArmyCompositionUnitType(%s): STARTED",
        function() return unitKey end)

    local unitGroup = common.get_context_value("CcoMainUnitRecord", unitKey, "UiUnitGroupContext.ParentGroup.Key")
    local armyCompositionUnitType = TotoWarCbac.enums.armyCompositionUnitTypes.cavalryAndMonsters

    if unitGroup:find('commander') then
        armyCompositionUnitType = TotoWarCbac.enums.armyCompositionUnitTypes.general
    elseif unitGroup:find('agent') then
        armyCompositionUnitType = TotoWarCbac.enums.armyCompositionUnitTypes.agent
    elseif unitGroup:find('artillery') then
        armyCompositionUnitType = TotoWarCbac.enums.armyCompositionUnitTypes.artillery
    elseif unitGroup:find('infantry') then
        if unitGroup:find('missile') then
            armyCompositionUnitType = TotoWarCbac.enums.armyCompositionUnitTypes.rangedInfantry
        else
            armyCompositionUnitType = TotoWarCbac.enums.armyCompositionUnitTypes.meleeInfantry
        end
    end

    TotoWar.genericLogger:logDebug(
        "TotoWarCbacArmySuppliesCost:getUnitArmyCompositionUnitType(%s): COMPLETED => %s",
        function() return unitKey end,
        function() return armyCompositionUnitType end)

    return armyCompositionUnitType
end

---Gets the list of unit army supplies costs as a tooltip string.
---@return { [string]: number }
function TotoWarCbacArmySuppliesCost:getUnitCategoryProportions()
    TotoWar.genericLogger:logDebug("TotoWarCbacArmySuppliesCost:getUnitCategoryProportions(): STARTED")

    local totalUnitCount = 0

    ---@type { [string]: integer }
    local unitCountPerCategory = {}

    ---@type { [string]: number }
    local unitCategoryProportions = {}

    for key, armyCompositionUnitType in pairs(TotoWarCbac.enums.armyCompositionUnitTypes) do
        if armyCompositionUnitType ~= TotoWarCbac.enums.armyCompositionUnitTypes.general
            and armyCompositionUnitType ~= TotoWarCbac.enums.armyCompositionUnitTypes.agent
        then
            -- The general and agents are not taken into consideration in the proportion
            unitCountPerCategory[armyCompositionUnitType] = 0
            unitCategoryProportions[armyCompositionUnitType] = 0
        end
    end

    for index, unitGroup in ipairs(self.unitGroups) do
        local armyCompositionUnitType = self:getUnitArmyCompositionUnitType(unitGroup.unitKey)

        if armyCompositionUnitType ~= TotoWarCbac.enums.armyCompositionUnitTypes.general
            and armyCompositionUnitType ~= TotoWarCbac.enums.armyCompositionUnitTypes.agent
        then
            -- The general and agents are not taken into consideration in the proportion
            unitCountPerCategory[armyCompositionUnitType] =
                unitCountPerCategory[armyCompositionUnitType] + unitGroup.unitCount
            totalUnitCount = totalUnitCount + unitGroup.unitCount
        end
    end

    for index, mercenaryUnit in ipairs(self.inRecruitmentMercenaryUnits) do
        ---@type string
        local armyCompositionUnitType = self:getUnitArmyCompositionUnitType(mercenaryUnit.unitKey)
        unitCountPerCategory[armyCompositionUnitType] = unitCountPerCategory[armyCompositionUnitType] + 1
        totalUnitCount = totalUnitCount + 1
    end

    for key, value in pairs(unitCountPerCategory) do
        unitCategoryProportions[key] = TotoWar.utils:roundToNearestInteger(value / totalUnitCount * 100)
    end

    TotoWar.genericLogger:logDebug(
        "TotoWarCbacArmySuppliesCost:getUnitCategoryProportions(): COMPLETED => %s",
        function()
            local unitCategoryProportionsString = ''

            for key, value in pairs(unitCategoryProportions) do
                unitCategoryProportionsString = string.format("%s| %s: %s%% ", unitCategoryProportionsString, key, value)
            end

            return unitCategoryProportionsString
        end)

    return unitCategoryProportions
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
        self.availableSupplies = TotoWarCbac.options.playerArmySuppliesAmount - self.totalCost
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
                self.availableSupplies = TotoWarCbac.options.playerArmySuppliesAmount - self.totalCost

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
        TotoWarCbac.options.playerArmySuppliesAmount,
        self.totalCost,
        availableArmySuppliesString,
        depletedArmySuppliesWarning,
        unitsArmySuppliesCostTooltipText)

    TotoWar.genericLogger:logDebug("TotoWarCbacArmySuppliesCost:toTooltipText(): COMPLETED")

    return tooltipText
end
