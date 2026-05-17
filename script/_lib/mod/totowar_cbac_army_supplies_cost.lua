---Army supplies cost of the units in an army.
---@class TotoWarCbacArmySuppliesCost
TotoWarCbacArmySuppliesCost = {
    ---Army supplies available to recruit additional units.
    ---@type integer
    availableSupplies = nil,

    ---Level of the lord.
    ---@type integer
    lordLevel = nil,

    ---Army supplies cost of each mercenary unit in the recruitment pool.
    ---Mercenary units are identified by their index in this table.
    ---@type TotoWarCbacUnitArmySuppliesCost[]
    inRecruitmentMercenaryUnits = nil,

    ---Total army supplies available for all units.
    ---@type integer
    totalArmySupplies = nil,

    ---Total army supplies cost
    ---@type integer
    totalCost = nil,

    ---Army supplies cost of each unit type present in the army.
    ---@type TotoWarCbacUnitArmySuppliesCost[]
    unitArmySuppliesCosts = nil,
}
TotoWarCbacArmySuppliesCost.__index = TotoWarCbacArmySuppliesCost

---Initializes a new instance of TotoWarCbacArmySuppliesCost.
---@param isAi boolean Indicates whether the army belongs to AI.
---@param lordLevel integer Level of the lord leading the army.
---@return TotoWarCbacArmySuppliesCost
function TotoWarCbacArmySuppliesCost.new(isAi, lordLevel)
    TotoWarCbac.loggers.armySuppliesCost:logDebug("TotoWarCbacArmySuppliesCost.new(): STARTED")

    local instance = setmetatable({}, TotoWarCbacArmySuppliesCost)

    local levelBonus = 0

    if isAi then
        levelBonus = (lordLevel - 1) * TotoWarCbac.options.aiArmySuppliesBonusAmountPerLevel
        instance.totalArmySupplies = TotoWarCbac.options.aiArmySuppliesAmount + levelBonus
    else
        levelBonus = (lordLevel - 1) * TotoWarCbac.options.playerArmySuppliesBonusAmountPerLevel
        instance.totalArmySupplies = TotoWarCbac.options.playerArmySuppliesAmount + levelBonus
    end

    instance.availableSupplies = instance.totalArmySupplies
    instance.lordLevel = lordLevel
    instance.inRecruitmentMercenaryUnits = {}
    instance.totalCost = 0
    instance.unitArmySuppliesCosts = {}

    TotoWarCbac.loggers.armySuppliesCost:logDebug(
        "TotoWarCbacArmySuppliesCost.new(): COMPLETED => Lord level: %s | Bonus army supplies: %s | Total army supplies: %s",
        function() return instance.lordLevel end,
        function() return levelBonus end,
        function() return instance.totalArmySupplies end)

    return instance
end

---Initializes a new instance of TotoWarCbacArmySuppliesCost from an army.
---@param isAi boolean Indicates whether the army belongs to AI.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@return TotoWarCbacArmySuppliesCost
function TotoWarCbacArmySuppliesCost.newFromArmy(isAi, army)
    local instance = TotoWarCbacArmySuppliesCost.new(isAi, army:general_character():rank())

    TotoWarCbac.loggers.armySuppliesCost:logDebug(
        "TotoWarCbacArmySuppliesCost:newFromArmy(%s, %s): STARTED",
        function() return isAi end,
        function() return army:unit_list():num_items() end)

    local characters = army:character_list()

    for i = 0, characters:num_items() - 1, 1 do
        local character = characters:item_at(i)
        instance:addCharacter(character:cqi())
    end

    local units = army:unit_list()

    for i = 0, units:num_items() - 1, 1 do
        local unit = units:item_at(i)
        local unitCqi = unit:command_queue_index()

        local isAlreadyAddedCharacter = TotoWarLinq:any(
            instance.unitArmySuppliesCosts,
            function(uasc)
                -- We avoid adding the lord and heroes twice
                return uasc.unitCqi == unitCqi
                    and (uasc.unitCategory == TotoWarCbac.enums.armyCompositionUnitTypes.lord
                        or uasc.unitCategory == TotoWarCbac.enums.armyCompositionUnitTypes.hero)
            end)

        if not isAlreadyAddedCharacter then
            instance:addUnit(unit:unit_key(), unit:command_queue_index())
        end
    end

    TotoWarCbac.loggers.armySuppliesCost:logDebug(
        "TotoWarCbacArmySuppliesCost:newFromArmy(%s, %s): COMPLETED => %s | %s",
        function() return isAi end,
        function() return army:unit_list():num_items() end,
        function() return instance.totalCost end,
        function() return instance.availableSupplies end)

    return instance
end

---Adds a unit to the army supplies cost.
---@param characterCqi integer Command queue index of the character.
function TotoWarCbacArmySuppliesCost:addCharacter(characterCqi)
    TotoWarCbac.loggers.armySuppliesCost:logDebug(
        "TotoWarCbacArmySuppliesCost:addCharacter(%s): STARTED",
        function() return TotoWar.utils:getCharacterCaption(cm:get_character_by_cqi(characterCqi)) end)

    ---@type TotoWarCbacUnitArmySuppliesCost
    local unitArmySuppliesCost = TotoWarCbacUnitArmySuppliesCost.newCharacter(characterCqi)
    table.insert(self.unitArmySuppliesCosts, unitArmySuppliesCost)

    self.totalCost = self.totalCost + unitArmySuppliesCost.armySuppliesCost
    self.availableSupplies = self.totalArmySupplies - self.totalCost

    TotoWarCbac.loggers.armySuppliesCost:logDebug(
        "TotoWarCbacArmySuppliesCost:addCharacter(%s): COMPLETED => %s",
        function() return TotoWar.utils:getCharacterCaption(cm:get_character_by_cqi(characterCqi)) end,
        function() return self.totalCost end)
end

---Adds a unit to the army supplies cost.
---@param unitKey string Unit key.
---@param unitCqi integer | nil Unit command queue index if we are able to get one.
---@param isInRecruitmentMercenary boolean | nil Indicates whether the unit added is a mercenary unit (regiment of renown, Grudge settles, Waaagh mobs, ...) in the recruitment pool.
function TotoWarCbacArmySuppliesCost:addUnit(unitKey, unitCqi, isInRecruitmentMercenary)
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
        unitArmySuppliesCost = TotoWarCbacUnitArmySuppliesCost.newUnit(unitKey, unitCqi)
        table.insert(self.inRecruitmentMercenaryUnits, unitArmySuppliesCost)
    else
        unitArmySuppliesCost = TotoWarCbacUnitArmySuppliesCost.newUnit(unitKey, unitCqi)
        table.insert(self.unitArmySuppliesCosts, unitArmySuppliesCost)
    end

    self.totalCost = self.totalCost + unitArmySuppliesCost.armySuppliesCost
    self.availableSupplies = self.totalArmySupplies - self.totalCost

    TotoWarCbac.loggers.armySuppliesCost:logDebug(
        "TotoWarCbacArmySuppliesCost:addUnit(%s, %s): COMPLETED => %s",
        function() return TotoWar.utils:getUnitCaption(unitKey) end,
        function() return isInRecruitmentMercenary end,
        function() return self.totalCost end)
end

---Checks whether a unit category has a number of units that exceed its maximum allowed proportion in the army composition.
---@param category TotoWarCbac_Enums_ArmyCompositionUnitCategories Unit category.
---@param categoryUnitCounts TotoWarDictionary<string, integer> Unit counts per category.
---@param totalUnitCount integer Total number of units in the army.
---@return boolean
function TotoWarCbacArmySuppliesCost:checkUnitCategoryExcess(category, categoryUnitCounts, totalUnitCount)
    TotoWarCbac.loggers.armySuppliesCost:logDebug(
        "checkUnitCategoryExcess(%s, %s, %s): STARTED",
        ---@diagnostic disable-next-line: return-type-mismatch
        function() return category end,
        ---@diagnostic disable-next-line: param-type-mismatch
        function() return categoryUnitCounts:get(category) end,
        function() return totalUnitCount end)

    if totalUnitCount <= 0 then
        return false
    end

    ---@diagnostic disable-next-line: param-type-mismatch
    local currentCount = categoryUnitCounts:get(category)

    if currentCount <= 0 then
        return false
    end

    local proportion = currentCount / totalUnitCount
    ---@diagnostic disable-next-line: param-type-mismatch
    local maxProp = TotoWarCbac.options.aiArmyUnitCategoryMaximumPercentages:get(category)
    local isExcess = proportion > maxProp

    TotoWarCbac.loggers.armySuppliesCost:logDebug(
        "checkUnitCategoryExcess(%s, %s, %s): COMPLETED => Is excess: %s | Proportion: %s | Max proportion: %s",
        ---@diagnostic disable-next-line: return-type-mismatch
        function() return category end,
        ---@diagnostic disable-next-line: param-type-mismatch
        function() return categoryUnitCounts:get(category) end,
        function() return totalUnitCount end,
        function() return isExcess end,
        function() return proportion end,
        function() return maxProp end)

    return proportion > maxProp
end

---Clears the list of in-recruitment mercenary units supply costs.
function TotoWarCbacArmySuppliesCost:clearMercenaryRecruitment()
    TotoWarCbac.loggers.armySuppliesCost:logDebug("clearMercenaryRecruitment(): STARTED")

    for i = 1, #self.inRecruitmentMercenaryUnits, 1 do
        self:removeUnit(TotoWar.enums.uiPatterns.inRecruitmentMercenaryUnitCard:sub(2) .. "0")
    end

    TotoWarCbac.loggers.armySuppliesCost:logDebug("clearMercenaryRecruitment(): COMPLETED")
end

---Gets the number of units for each unit category composing army supplies costs that exceed the configured maximum proportion.
---
---Lord and heroes are not taken into account.
---@return TotoWarDictionary<string, integer>
function TotoWarCbacArmySuppliesCost:getUnitCategoryExcessCounts()
    TotoWarCbac.loggers.armySuppliesCost:logDebug("getUnitCategoryExcessCounts(): STARTED")

    local totalUnitCount = 0
    local orderedCategories = {
        TotoWarCbac.enums.armyCompositionUnitTypes.artillery,
        TotoWarCbac.enums.armyCompositionUnitTypes.cavalryAndMonsters,
        TotoWarCbac.enums.armyCompositionUnitTypes.rangedInfantry,
        TotoWarCbac.enums.armyCompositionUnitTypes.meleeInfantry
    }

    ---@type TotoWarDictionary<string, integer>
    local categoryUnitCounts = TotoWarDictionary.new()

    ---@type TotoWarDictionary<string, integer>
    local categoryUnitExcessCounts = TotoWarDictionary.new()

    -- Initialize counts for each category (excluding lord and heroes)
    for key, armyCompositionUnitType in pairs(orderedCategories) do
        categoryUnitCounts:set(armyCompositionUnitType, 0)
    end

    -- Count units per category (excluding lord and heroes)
    for index, unit in ipairs(self.unitArmySuppliesCosts) do
        if unit.unitCategory ~= TotoWarCbac.enums.armyCompositionUnitTypes.lord
            and unit.unitCategory ~= TotoWarCbac.enums.armyCompositionUnitTypes.hero
        then
            ---@diagnostic disable-next-line: param-type-mismatch
            categoryUnitCounts:set(unit.unitCategory, categoryUnitCounts:get(unit.unitCategory) + 1)
            totalUnitCount = totalUnitCount + 1
        end
    end

    if totalUnitCount > 0 then
        -- Initialize excess counts
        for _, category in ipairs(orderedCategories) do
            categoryUnitExcessCounts:set(category, 0)
        end

        -- Iterate over each category, selecting at most 1 unit per category over the limit each cycle to remove until no category is above the limit anymore.
        -- Units that are selected as excess are not taken into consideration in the ratio computation for the next iterations.
        while true do
            local hasRemoved = false

            for _, category in ipairs(orderedCategories) do
                ---@diagnostic disable-next-line: param-type-mismatch
                if self:checkUnitCategoryExcess(category, categoryUnitCounts, totalUnitCount) then
                    categoryUnitExcessCounts:set(category, categoryUnitExcessCounts:get(category) + 1)
                    categoryUnitCounts:set(category, categoryUnitCounts:get(category) - 1)
                    totalUnitCount = totalUnitCount - 1

                    hasRemoved = true
                end
            end

            if not hasRemoved then
                break
            end
        end

        -- Removing entries with 0 excess
        for index, category in ipairs(orderedCategories) do
            if categoryUnitExcessCounts:get(category) == 0 then
                categoryUnitExcessCounts:remove(category)
            end
        end
    end

    TotoWarCbac.loggers.armySuppliesCost:logDebug(
        "TotoWarCbacArmySuppliesCost:getUnitCategoryExcessCounts(): COMPLETED => %s",
        function()
            local message = ''

            for index, entry in ipairs(categoryUnitExcessCounts.entries) do
                message = string.format("%s| %s: %s ", message, entry.key, entry.value)
            end

            if message == '' then
                message = 'No excess'
            end

            return message
        end)

    return categoryUnitExcessCounts
end

---Removes the character corresponding to a command queue index.
---@param characterCqi integer Character command queue index.
function TotoWarCbacArmySuppliesCost:removeCharacter(characterCqi)
    TotoWarCbac.loggers.armySuppliesCost:logDebug(
        "TotoWarCbacArmySuppliesCost:removeCharacter(%s): STARTED",
        function() return TotoWar.utils:getCharacterCaption(cm:get_character_by_cqi(characterCqi)) end)

    local characterIndex = TotoWarLinq:findIndex(
        self.unitArmySuppliesCosts,
        function(uasc) return uasc.characterCqi == characterCqi end)

    if characterIndex == -1 then
        TotoWarCbac.loggers.armySuppliesCost:logError(
            "TotoWarCbacArmySuppliesCost:removeCharacter(%s): NOT FOUND",
            TotoWar.utils:getCharacterCaption(cm:get_character_by_cqi(characterCqi)))

        return
    end

    local character = self.unitArmySuppliesCosts[characterIndex]
    self.totalCost = self.totalCost - character.armySuppliesCost
    self.availableSupplies = self.totalArmySupplies - self.totalCost
    table.remove(self.unitArmySuppliesCosts, characterIndex)

    TotoWarCbac.loggers.armySuppliesCost:logDebug(
        "TotoWarCbacArmySuppliesCost:removeCharacter(%s): COMPLETED",
        function() return TotoWar.utils:getCharacterCaption(cm:get_character_by_cqi(characterCqi)) end)
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
        self.availableSupplies = self.totalArmySupplies - self.totalCost
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
                self.availableSupplies = self.totalArmySupplies - self.totalCost
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
---Unit category order : Lord, Hero, Melee Infantry, Ranged Infantry, Cavalry & Monsters, Artillery
function TotoWarCbacArmySuppliesCost:sortUnitArmySuppliesCost()
    table.sort(
        self.unitArmySuppliesCosts,
        function(item1, item2)
            if item1.unitCategory == TotoWarCbac.enums.armyCompositionUnitTypes.lord then
                return true
            end

            if item2.unitCategory == TotoWarCbac.enums.armyCompositionUnitTypes.lord then
                return false
            end

            if item1.unitCategory == TotoWarCbac.enums.armyCompositionUnitTypes.hero
                and item2.unitCategory ~= TotoWarCbac.enums.armyCompositionUnitTypes.hero
            then
                return true
            end

            if item2.unitCategory == TotoWarCbac.enums.armyCompositionUnitTypes.hero
                and item1.unitCategory ~= TotoWarCbac.enums.armyCompositionUnitTypes.hero
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
    TotoWarCbac.loggers.armySuppliesCost:logDebug("toTooltipText(): STARTED")

    local unitsArmySuppliesCostTooltipText = ""

    self:sortUnitArmySuppliesCost() -- Sorting groups by category, price and and caption

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
        self.totalArmySupplies,
        self.totalCost,
        availableArmySuppliesString,
        depletedArmySuppliesWarning,
        unitsArmySuppliesCostTooltipText)

    TotoWarCbac.loggers.armySuppliesCost:logDebug("toTooltipText(): COMPLETED")

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

    if unitArmySuppliesCost.unitCategory == TotoWarCbac.enums.armyCompositionUnitTypes.lord
        or unitArmySuppliesCost.unitCategory == TotoWarCbac.enums.armyCompositionUnitTypes.hero
    then
        local character = cm:get_character_by_cqi(unitArmySuppliesCost.characterCqi)

        if character:has_military_force() then
            tooltipText = string.format(
                common.get_localised_string("totowar_cbac_tooltip_unit_armySuppliesCostOfLord"),
                TotoWar.utils:getCharacterCaption(character),
                TotoWar.utils:getUnitCaption(unitArmySuppliesCost.unitKey),
                unitArmySuppliesCost.armySuppliesCost)
        else
            tooltipText = string.format(
                common.get_localised_string("totowar_cbac_tooltip_unit_armySuppliesCostOfHero"),
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
