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
    unitArmySuppliesCosts = nil,
}
TotoWarCbacArmySuppliesCost.__index = TotoWarCbacArmySuppliesCost

---Initializes a new instance of TotoWarCbacArmySuppliesCost.
---@param availableArmySupplies number Total available army supplies in the army.
---@return TotoWarCbacArmySuppliesCost
function TotoWarCbacArmySuppliesCost.new(availableArmySupplies)
    local instance = setmetatable({}, TotoWarCbacArmySuppliesCost)

    instance.availableSupplies = availableArmySupplies
    instance.inRecruitmentMercenaryUnits = {}
    instance.unitArmySuppliesCosts = {}
    instance.totalCost = 0

    TotoWar.genericLogger:logDebug("TotoWarCbacArmySuppliesCost.new(): COMPLETED")

    return instance
end

---Initializes a new instance of TotoWarCbacArmySuppliesCost from an army.
---@param availableArmySupplies number Total available army supplies in the army.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@return TotoWarCbacArmySuppliesCost
function TotoWarCbacArmySuppliesCost.newFromArmy(availableArmySupplies, army)
    local instance = TotoWarCbacArmySuppliesCost.new(availableArmySupplies)
    local characters = army:character_list()
    local units = army:unit_list()

    for i = 0, characters:num_items() - 1, 1 do
        local character = characters:item_at(i)
        instance:addCharacter(character:cqi())
    end

    for i = 0, units:num_items() - 1, 1 do
        local armyUnit = units:item_at(i)

        if not TotoWar.utils:isCharacterUnit(armyUnit:unit_key()) then
            instance:addUnit(armyUnit:unit_key())
        end
    end

    return instance
end

---Adds a unit to the army supplies cost.
---@param cqi integer Command queue index of the character.
function TotoWarCbacArmySuppliesCost:addCharacter(cqi)
    TotoWar.genericLogger:logDebug(
        "TotoWarCbacArmySuppliesCost:addCharacter(%s): STARTED",
        function() return TotoWar.utils:getCharacterCaption(cm:get_character_by_cqi(cqi)) end)

    ---@type TotoWarCbacUnitArmySuppliesCost
    local unitArmySuppliesCost = TotoWarCbacUnitArmySuppliesCost.newCharacter(cqi)
    table.insert(self.unitArmySuppliesCosts, unitArmySuppliesCost)

    self.totalCost = self.totalCost + unitArmySuppliesCost.armySuppliesCost
    self.availableSupplies = TotoWarCbac.options.playerArmySuppliesAmount - self.totalCost

    TotoWar.genericLogger:logDebug(
        "TotoWarCbacArmySuppliesCost:addCharacter(%s): COMPLETED => %s",
        function() return TotoWar.utils:getCharacterCaption(cm:get_character_by_cqi(cqi)) end,
        function() return self.totalCost end)
end

---Adds a unit to the army supplies cost.
---@param unitKey string Unit key.
---@param isInRecruitmentMercenary boolean | nil Indicates whether the unit added is a mercenary unit (regiment of renown, Grudge settles, Waaagh mobs, ...) in the recruitment pool.
function TotoWarCbacArmySuppliesCost:addUnit(unitKey, isInRecruitmentMercenary)
    if isInRecruitmentMercenary == nil then
        isInRecruitmentMercenary = false
    end

    TotoWar.genericLogger:logDebug(
        "TotoWarCbacArmySuppliesCost:addUnit(%s, %s): STARTED",
        function() return TotoWar.utils:getUnitCaption(unitKey) end,
        function() return isInRecruitmentMercenary end)

    ---@type TotoWarCbacUnitArmySuppliesCost
    local unitArmySuppliesCost

    if isInRecruitmentMercenary then
        unitArmySuppliesCost = TotoWarCbacUnitArmySuppliesCost.newUnit(unitKey)
        table.insert(self.inRecruitmentMercenaryUnits, unitArmySuppliesCost)
    else
        unitArmySuppliesCost = TotoWarCbacUnitArmySuppliesCost.newUnit(unitKey)
        table.insert(self.unitArmySuppliesCosts, unitArmySuppliesCost)
    end

    self.totalCost = self.totalCost + unitArmySuppliesCost.armySuppliesCost
    self.availableSupplies = TotoWarCbac.options.playerArmySuppliesAmount - self.totalCost

    TotoWar.genericLogger:logDebug(
        "TotoWarCbacArmySuppliesCost:addUnit(%s, %s): COMPLETED => %s",
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

    local unitGroup = common.get_context_value(
        TotoWar.enums.ccoContextTypeIds.mainUnitRecord,
        unitKey,
        "UiUnitGroupContext.ParentGroup.Key")
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

    for index, unitArmySuppliesCost in ipairs(self.unitArmySuppliesCosts) do
        local armyCompositionUnitType = self:getUnitArmyCompositionUnitType(unitArmySuppliesCost.unitKey)

        if armyCompositionUnitType ~= TotoWarCbac.enums.armyCompositionUnitTypes.general
            and armyCompositionUnitType ~= TotoWarCbac.enums.armyCompositionUnitTypes.agent
        then
            -- The general and agents are not taken into consideration in the proportion
            unitCountPerCategory[armyCompositionUnitType] = unitCountPerCategory[armyCompositionUnitType] + 1
            totalUnitCount = totalUnitCount + 1
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

---Removes the character corresponding to a command queue index.
---@param cqi integer Character command queue index.
function TotoWarCbacArmySuppliesCost:removeCharacter(cqi)
    TotoWar.genericLogger:logDebug(
        "TotoWarCbacArmySuppliesCost:removeCharacter(%s): STARTED",
        function() return cqi end)

    for i = 1, #self.unitArmySuppliesCosts, -1 do
        local unit = self.unitArmySuppliesCosts[i]

        if unit.cqi == cqi then
            self.totalCost = self.totalCost - unit.armySuppliesCost
            self.availableSupplies = TotoWarCbac.options.playerArmySuppliesAmount - self.totalCost
            table.remove(self.unitArmySuppliesCosts, i)

            TotoWar.genericLogger:logDebug(
                "TotoWarCbacArmySuppliesCost:removeCharacter(%s): COMPLETED => %s",
                function() return cqi end,
                function() return TotoWar.utils:getUnitCaption(unit.unitKey) end)
        end
    end

    TotoWar.genericLogger:logError("TotoWarCbacArmySuppliesCost:removeCharacter(%s): NOT FOUND", cqi)
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
        local positionInRecruitmentQueuePattern = TotoWar.enums.uiPatterns.inRecruitmentMercenaryUnitCard .. "(%d+)$"
        -- Position starts at 0 in the recruitment queue, but LUA table indexes start at 1
        local index = tonumber(unitKey:match(positionInRecruitmentQueuePattern)) + 1
        local unit = self.inRecruitmentMercenaryUnits[index]

        self.totalCost = self.totalCost - unit.armySuppliesCost
        self.availableSupplies = TotoWarCbac.options.playerArmySuppliesAmount - self.totalCost
        table.remove(self.inRecruitmentMercenaryUnits, index)

        TotoWar.genericLogger:logDebug(
            "TotoWarCbacArmySuppliesCost:removeUnit(%s): COMPLETED => %s",
            function() return TotoWar.utils:getUnitCaption(unitKey) end,
            function() return self.totalCost end)

        return unit.unitKey;
    else
        -- Prioritizing removing the last unit added which in theory should be the least experienced
        for i = #self.unitArmySuppliesCosts, 1, -1 do
            local unit = self.unitArmySuppliesCosts[i]

            if unit.unitKey == unitKey then
                self.totalCost = self.totalCost - unit.armySuppliesCost
                self.availableSupplies = TotoWarCbac.options.playerArmySuppliesAmount - self.totalCost
                table.remove(self.unitArmySuppliesCosts, i)

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

    for i, unitArmySuppliesCost in ipairs(self.unitArmySuppliesCosts) do
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
