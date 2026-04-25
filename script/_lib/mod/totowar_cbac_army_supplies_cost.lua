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
    TotoWarCbac.loggers.armySuppliesCost:logDebug("TotoWarCbacArmySuppliesCost.new(): STARTED")

    local instance = setmetatable({}, TotoWarCbacArmySuppliesCost)

    instance.availableSupplies = availableArmySupplies
    instance.inRecruitmentMercenaryUnits = {}
    instance.unitArmySuppliesCosts = {}
    instance.totalCost = 0

    TotoWarCbac.loggers.armySuppliesCost:logDebug("TotoWarCbacArmySuppliesCost.new(): COMPLETED")

    return instance
end

---Initializes a new instance of TotoWarCbacArmySuppliesCost from an army.
---@param availableArmySupplies number Total available army supplies in the army.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@return TotoWarCbacArmySuppliesCost
function TotoWarCbacArmySuppliesCost.newFromArmy(availableArmySupplies, army)
    local instance = TotoWarCbacArmySuppliesCost.new(availableArmySupplies)

    TotoWarCbac.loggers.armySuppliesCost:logDebug(
        "TotoWarCbacArmySuppliesCost:newFromArmy(%s, %s): STARTED",
        function() return availableArmySupplies end,
        function() return army:unit_list():num_items() end)

    local characters = army:character_list()
    local units = army:unit_list()

    for i = 0, characters:num_items() - 1, 1 do
        local character = characters:item_at(i)
        instance:addCharacter(character:cqi())
    end

    for i = 0, units:num_items() - 1, 1 do
        local unit = units:item_at(i)

        if not TotoWar.utils:isCharacterUnit(unit:command_queue_index()) then
            instance:addUnit(unit:unit_key(), unit:command_queue_index())
        end
    end

    TotoWarCbac.loggers.armySuppliesCost:logDebug(
        "TotoWarCbacArmySuppliesCost:newFromArmy(%s, %s): COMPLETED => %s | %s",
        function() return availableArmySupplies end,
        function() return army:unit_list():num_items() end,
        function() return instance.totalCost end,
        function() return instance.availableSupplies end)

    return instance
end

---Adds a unit to the army supplies cost.
---@param cqi integer Command queue index of the character.
function TotoWarCbacArmySuppliesCost:addCharacter(cqi)
    TotoWarCbac.loggers.armySuppliesCost:logDebug(
        "TotoWarCbacArmySuppliesCost:addCharacter(%s): STARTED",
        function() return TotoWar.utils:getCharacterCaption(cm:get_character_by_cqi(cqi)) end)

    ---@type TotoWarCbacUnitArmySuppliesCost
    local unitArmySuppliesCost = TotoWarCbacUnitArmySuppliesCost.newCharacter(cqi)
    table.insert(self.unitArmySuppliesCosts, unitArmySuppliesCost)

    self.totalCost = self.totalCost + unitArmySuppliesCost.armySuppliesCost
    self.availableSupplies = TotoWarCbac.options.playerArmySuppliesAmount - self.totalCost

    TotoWarCbac.loggers.armySuppliesCost:logDebug(
        "TotoWarCbacArmySuppliesCost:addCharacter(%s): COMPLETED => %s",
        function() return TotoWar.utils:getCharacterCaption(cm:get_character_by_cqi(cqi)) end,
        function() return self.totalCost end)
end

---Adds a unit to the army supplies cost.
---@param unitKey string Unit key.
---@param cqi integer | nil Unit command queue index if we are able to get one.
---@param isInRecruitmentMercenary boolean | nil Indicates whether the unit added is a mercenary unit (regiment of renown, Grudge settles, Waaagh mobs, ...) in the recruitment pool.
function TotoWarCbacArmySuppliesCost:addUnit(unitKey, cqi, isInRecruitmentMercenary)
    if isInRecruitmentMercenary == nil then
        isInRecruitmentMercenary = false
    end

    TotoWarCbac.loggers.armySuppliesCost:logDebug(
        "TotoWarCbacArmySuppliesCost:addUnit(%s, %s): STARTED",
        function() return TotoWar.utils:getUnitCaption(unitKey) end,
        function() return isInRecruitmentMercenary end)

    ---@type TotoWarCbacUnitArmySuppliesCost
    local unitArmySuppliesCost

    if isInRecruitmentMercenary then
        unitArmySuppliesCost = TotoWarCbacUnitArmySuppliesCost.newUnit(unitKey, cqi)
        table.insert(self.inRecruitmentMercenaryUnits, unitArmySuppliesCost)
    else
        unitArmySuppliesCost = TotoWarCbacUnitArmySuppliesCost.newUnit(unitKey, cqi)
        table.insert(self.unitArmySuppliesCosts, unitArmySuppliesCost)
    end

    self.totalCost = self.totalCost + unitArmySuppliesCost.armySuppliesCost
    self.availableSupplies = TotoWarCbac.options.playerArmySuppliesAmount - self.totalCost

    TotoWarCbac.loggers.armySuppliesCost:logDebug(
        "TotoWarCbacArmySuppliesCost:addUnit(%s, %s): COMPLETED => %s",
        function() return TotoWar.utils:getUnitCaption(unitKey) end,
        function() return isInRecruitmentMercenary end,
        function() return self.totalCost end)
end

---Clears the list of in-recruitment mercenary units supply costs.
function TotoWarCbacArmySuppliesCost:clearMercenaryRecruitment()
    TotoWarCbac.loggers.armySuppliesCost:logDebug("TotoWarCbacArmySuppliesCost:clearMercenaryRecruitment(): STARTED")

    for i = 1, #self.inRecruitmentMercenaryUnits, 1 do
        self:removeUnit(TotoWar.enums.uiPatterns.inRecruitmentMercenaryUnitCard:sub(2) .. "0")
    end

    TotoWarCbac.loggers.armySuppliesCost:logDebug("TotoWarCbacArmySuppliesCost:clearMercenaryRecruitment(): COMPLETED")
end

---Gets the number of units for each unit category composing army supplies costs that exceed the configured maximum proportion.
---
---General and agents are not taken into account.
---@return { [string]: number }
function TotoWarCbacArmySuppliesCost:getUnitCategoryExcessCounts()
    TotoWarCbac.loggers.armySuppliesCost:logDebug("TotoWarCbacArmySuppliesCost:getUnitCategoryExcessCounts(): STARTED")

    local totalUnitCount = 0

    ---@type { [string]: integer }
    local categoryUnitCounts = {}

    ---@type { [string]: integer }
    local categoryUnitExcessCounts = {}

    for key, armyCompositionUnitType in pairs(TotoWarCbac.enums.armyCompositionUnitTypes) do
        if armyCompositionUnitType ~= TotoWarCbac.enums.armyCompositionUnitTypes.general
            and armyCompositionUnitType ~= TotoWarCbac.enums.armyCompositionUnitTypes.agent
        then
            -- The general and agents are not taken into consideration in the proportion
            categoryUnitCounts[armyCompositionUnitType] = 0
        end
    end

    for index, unit in ipairs(self.unitArmySuppliesCosts) do
        if unit.unitCategory ~= TotoWarCbac.enums.armyCompositionUnitTypes.general
            and unit.unitCategory ~= TotoWarCbac.enums.armyCompositionUnitTypes.agent
        then
            -- The general and agents are not taken into consideration in the proportion.
            -- In recruitment mercenary units are ignored since they can only exist when the
            -- player is in a mercenary recruitment panel
            categoryUnitCounts[unit.unitCategory] = categoryUnitCounts[unit.unitCategory] + 1
            totalUnitCount = totalUnitCount + 1
        end
    end

    for key, value in pairs(categoryUnitCounts) do
        local proportion = value / totalUnitCount

        if proportion > TotoWarCbac.options.aiArmyUnitCategoryMaximumPercentages[key] then
            categoryUnitExcessCounts[key] = TotoWar.utils:roundToNearestInteger(
                totalUnitCount * (proportion - TotoWarCbac.options.aiArmyUnitCategoryMaximumPercentages[key]))
        end
    end

    TotoWarCbac.loggers.armySuppliesCost:logDebug(
        "TotoWarCbacArmySuppliesCost:getUnitCategoryExcessCounts(): COMPLETED => %s",
        function()
            local message = ''

            for key, value in pairs(categoryUnitExcessCounts) do
                message = string.format("%s| %s: %s ", message, key, value)
            end

            if message == '' then
                message = 'No excess'
            end

            return message
        end)

    return categoryUnitExcessCounts
end

---Removes the character corresponding to a command queue index.
---@param cqi integer Character command queue index.
function TotoWarCbacArmySuppliesCost:removeCharacter(cqi)
    TotoWarCbac.loggers.armySuppliesCost:logDebug(
        "TotoWarCbacArmySuppliesCost:removeCharacter(%s): STARTED",
        function() return cqi end)

    for i = 1, #self.unitArmySuppliesCosts, -1 do
        local unit = self.unitArmySuppliesCosts[i]

        if unit.cqi == cqi then
            self.totalCost = self.totalCost - unit.armySuppliesCost
            self.availableSupplies = TotoWarCbac.options.playerArmySuppliesAmount - self.totalCost
            table.remove(self.unitArmySuppliesCosts, i)

            TotoWarCbac.loggers.armySuppliesCost:logDebug(
                "TotoWarCbacArmySuppliesCost:removeCharacter(%s): COMPLETED => %s",
                function() return cqi end,
                function() return TotoWar.utils:getUnitCaption(unit.unitKey) end)
        end
    end

    TotoWarCbac.loggers.armySuppliesCost:logError("TotoWarCbacArmySuppliesCost:removeCharacter(%s): NOT FOUND", cqi)
end

---Removes a unit from the army supplies cost.
---
---When removing a mercenary unit, returns the key of the removed unit.
---This is useful to know which unit was removed because we only know the position
---position of the unit in the recruitment queue before calling `removeUnit`.
---@param unitKey string Unit key.
---@return string | nil
function TotoWarCbacArmySuppliesCost:removeUnit(unitKey)
    TotoWarCbac.loggers.armySuppliesCost:logDebug(
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

        TotoWarCbac.loggers.armySuppliesCost:logDebug(
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

                TotoWarCbac.loggers.armySuppliesCost:logDebug(
                    "TotoWarCbacArmySuppliesCost:removeUnit(%s): COMPLETED => %s",
                    function() return TotoWar.utils:getUnitCaption(unitKey) end,
                    function() return self.totalCost end)

                return unitKey;
            end
        end
    end

    TotoWarCbac.loggers.armySuppliesCost:logError(
        "TotoWarCbacArmySuppliesCost:removeUnit(%s): NOT FOUND",
        TotoWar.utils:getUnitCaption(unitKey))
end

---Sorts army supplies costs by unit category, army supplies cost and name.
---
---Unit category order : General, Agent, Melee Infantry, Ranged Infantry, Cavalry & Monsters, Artillery
function TotoWarCbacArmySuppliesCost:sortUnitArmySuppliesCost()
    table.sort(
        self.unitArmySuppliesCosts,
        function(item1, item2)
            if item1.unitCategory == TotoWarCbac.enums.armyCompositionUnitTypes.general then
                return true
            end

            if item2.unitCategory == TotoWarCbac.enums.armyCompositionUnitTypes.general then
                return false
            end

            if item1.unitCategory == TotoWarCbac.enums.armyCompositionUnitTypes.agent
                and item2.unitCategory ~= TotoWarCbac.enums.armyCompositionUnitTypes.agent
            then
                return true
            end

            if item2.unitCategory == TotoWarCbac.enums.armyCompositionUnitTypes.agent
                and item1.unitCategory ~= TotoWarCbac.enums.armyCompositionUnitTypes.agent
            then
                return false
            end

            if item1.unitCategory == TotoWarCbac.enums.armyCompositionUnitTypes.meleeInfantry
                and item2.unitCategory ~= TotoWarCbac.enums.armyCompositionUnitTypes.meleeInfantry
            then
                return true
            end

            if item2.unitCategory == TotoWarCbac.enums.armyCompositionUnitTypes.meleeInfantry
                and item1.unitCategory ~= TotoWarCbac.enums.armyCompositionUnitTypes.meleeInfantry
            then
                return false
            end

            if item1.unitCategory == TotoWarCbac.enums.armyCompositionUnitTypes.rangedInfantry
                and item2.unitCategory ~= TotoWarCbac.enums.armyCompositionUnitTypes.rangedInfantry
            then
                return true
            end

            if item2.unitCategory == TotoWarCbac.enums.armyCompositionUnitTypes.rangedInfantry
                and item1.unitCategory ~= TotoWarCbac.enums.armyCompositionUnitTypes.rangedInfantry
            then
                return false
            end

            if item1.unitCategory == TotoWarCbac.enums.armyCompositionUnitTypes.cavalryAndMonsters
                and item2.unitCategory ~= TotoWarCbac.enums.armyCompositionUnitTypes.cavalryAndMonsters
            then
                return true
            end

            if item2.unitCategory == TotoWarCbac.enums.armyCompositionUnitTypes.cavalryAndMonsters
                and item1.unitCategory ~= TotoWarCbac.enums.armyCompositionUnitTypes.cavalryAndMonsters
            then
                return false
            end

            if item1.unitCategory == TotoWarCbac.enums.armyCompositionUnitTypes.artillery
                and item2.unitCategory ~= TotoWarCbac.enums.armyCompositionUnitTypes.artillery
            then
                return true
            end

            if item2.unitCategory == TotoWarCbac.enums.armyCompositionUnitTypes.artillery
                and item1.unitCategory ~= TotoWarCbac.enums.armyCompositionUnitTypes.artillery
            then
                return false
            end

            if item1.armySuppliesCost < item2.armySuppliesCost then
                return true
            end

            if item2.armySuppliesCost < item1.armySuppliesCost then
                return false
            end

            local item1Caption = TotoWar.utils:getUnitCaption(item1.unitKey)
            local item2Caption = TotoWar.utils:getUnitCaption(item2.unitKey)

            return item1Caption < item2Caption
        end)
end

---Gets the list of unit army supplies costs as a tooltip string.
---@return string
function TotoWarCbacArmySuppliesCost:toArmySuppliesCostTooltipText()
    TotoWarCbac.loggers.armySuppliesCost:logDebug("TotoWarCbacArmySuppliesCost:toTooltipText(): STARTED")

    local unitsArmySuppliesCostTooltipText = ""

    -- Sorting groups by category, price and and caption
    self:sortUnitArmySuppliesCost()

    for index, unitArmySuppliesCost in ipairs(self.unitArmySuppliesCosts) do
        unitsArmySuppliesCostTooltipText =
            unitsArmySuppliesCostTooltipText
            .. "\n"
            .. self:toUnitArmySuppliesCostTooltipText(unitArmySuppliesCost)
    end

    for index, mercenaryUnitArmySuppliesCost in ipairs(self.inRecruitmentMercenaryUnits) do
        unitsArmySuppliesCostTooltipText =
            unitsArmySuppliesCostTooltipText
            .. "\n"
            .. self:toUnitArmySuppliesCostTooltipText(mercenaryUnitArmySuppliesCost)
    end

    local availableArmySuppliesString = string.format("[[col:white]]%s[[/col]]", self.availableSupplies)
    local depletedArmySuppliesWarning = ""

    if self.availableSupplies < 0 then
        availableArmySuppliesString = string.format("[[col:red]]%s[[/col]]", self.availableSupplies)
        depletedArmySuppliesWarning = string.format(
            "\n\n[[col:%s]]%s[[/col]]",
            "red",
            common.get_localised_string("totowar_cbac_tooltip_unit_armySuppliesCostDepleted"))
    end

    local tooltipText = string.format(
        common.get_localised_string("totowar_cbac_tooltip_armySuppliesCost"),
        TotoWarCbac.options.playerArmySuppliesAmount,
        self.totalCost,
        availableArmySuppliesString,
        depletedArmySuppliesWarning,
        unitsArmySuppliesCostTooltipText)

    TotoWarCbac.loggers.armySuppliesCost:logDebug("TotoWarCbacArmySuppliesCost:toTooltipText(): COMPLETED")

    return tooltipText
end

---Gets the unit army supplies cost for a unit as a tooltip string.
---@param unitArmySuppliesCost TotoWarCbacUnitArmySuppliesCost Army supplies cost of the unit.
---@return string
function TotoWarCbacArmySuppliesCost:toUnitArmySuppliesCostTooltipText(unitArmySuppliesCost)
    TotoWarCbac.loggers.armySuppliesCost:logDebug(
    "TotoWarCbacArmySuppliesCost:toUnitArmySuppliesCostTooltipText: STARTED")

    ---@type string
    local tooltipText

    if unitArmySuppliesCost.unitCategory == TotoWarCbac.enums.armyCompositionUnitTypes.general
        or unitArmySuppliesCost.unitCategory == TotoWarCbac.enums.armyCompositionUnitTypes.agent
    then
        local character = cm:get_character_by_cqi(unitArmySuppliesCost.cqi)

        if character:has_military_force() then
            tooltipText = string.format(
                common.get_localised_string("totowar_cbac_tooltip_unit_armySuppliesCostOfGeneral"),
                TotoWar.utils:getCharacterCaption(character),
                TotoWar.utils:getUnitCaption(unitArmySuppliesCost.unitKey),
                unitArmySuppliesCost.armySuppliesCost)
        else
            tooltipText = string.format(
                common.get_localised_string("totowar_cbac_tooltip_unit_armySuppliesCostOfAgent"),
                TotoWar.utils:getCharacterCaption(character),
                TotoWar.utils:getUnitCaption(unitArmySuppliesCost.unitKey),
                unitArmySuppliesCost.armySuppliesCost)
        end
    else
        tooltipText = string.format(
            common.get_localised_string("totowar_cbac_tooltip_unit_armySuppliesCostOfUnit"),
            'totowar_cbac_unit_category_' .. unitArmySuppliesCost.unitCategory,
            TotoWar.utils:getUnitCaption(unitArmySuppliesCost.unitKey),
            unitArmySuppliesCost.armySuppliesCost)
    end

    TotoWarCbac.loggers.armySuppliesCost:logDebug(
    "TotoWarCbacArmySuppliesCost:toUnitArmySuppliesCostTooltipText: COMPLETED")

    return tooltipText
end
