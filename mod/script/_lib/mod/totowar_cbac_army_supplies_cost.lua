require("script._lib.mod.totowar_cbac_enum")

local logger = TotoWar__Logger.get(TotoWar_Cbac_Enum_LogCategories.armySuppliesCost)

---Gets the unit army supplies cost for a unit as a tooltip string.
---@param unitArmySuppliesCost TotoWar_Cbac_UnitArmySuppliesCost Army supplies cost of the unit.
---@return string
local function toUnitArmySuppliesCostTooltipText(unitArmySuppliesCost)
    logger:logDebug(
        "toUnitArmySuppliesCostTooltipText(unitArmySuppliesCost): STARTED => Unit: %s",
        unitArmySuppliesCost.unitKey)

    ---@type string
    local tooltipText

    if unitArmySuppliesCost.unitCategory == TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.lord
        or unitArmySuppliesCost.unitCategory == TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.hero
    then
        local character = TotoWar__Gameplay:getCharacter(unitArmySuppliesCost.characterCqi)

        if character == nil then
            -- This can happen sometimes. The may have been killed during the time elapsed the recruitment of a unit and the execution of the callback.
            logger:logDebug(
                "toUnitArmySuppliesCostTooltipText(unitArmySuppliesCost): COMPLETED => Unit: %s | Character not found",
                unitArmySuppliesCost.unitKey)

            return ''
        end

        if character:has_military_force() then
            tooltipText = string.format(
                common.get_localised_string("totowar_cbac_tooltip_unit_armySuppliesCostOfLord"),
                TotoWar__Gameplay:getCharacterCaption(character),
                TotoWar__Gameplay:getUnitCaption(unitArmySuppliesCost.unitKey),
                unitArmySuppliesCost.armySuppliesCost)
        else
            tooltipText = string.format(
                common.get_localised_string("totowar_cbac_tooltip_unit_armySuppliesCostOfHero"),
                TotoWar__Gameplay:getCharacterCaption(character),
                TotoWar__Gameplay:getUnitCaption(unitArmySuppliesCost.unitKey),
                unitArmySuppliesCost.armySuppliesCost)
        end
    else
        tooltipText = string.format(
            common.get_localised_string("totowar_cbac_tooltip_unit_armySuppliesCostOfUnit"),
            'totowar_cbac_unit_category_' .. unitArmySuppliesCost.unitCategory,
            TotoWar__Gameplay:getUnitCaption(unitArmySuppliesCost.unitKey),
            unitArmySuppliesCost.armySuppliesCost)
    end

    logger:logDebug(
        "toUnitArmySuppliesCostTooltipText(unitArmySuppliesCost): COMPLETED => Unit: %s",
        unitArmySuppliesCost.unitKey)

    return tooltipText
end

---Army supplies cost of the units in an army.
---@class TotoWar_Cbac_ArmySuppliesCost
TotoWar_Cbac_ArmySuppliesCost = {
    ---Army supplies available to recruit additional units.
    ---@type integer
    availableSupplies = nil,

    ---Level of the lord.
    ---@type integer
    lordLevel = nil,

    ---Army supplies cost of each mercenary unit in the recruitment pool.
    ---Mercenary units are identified by their index in this table.
    ---@type TotoWar_Cbac_UnitArmySuppliesCost[]
    inRecruitmentMercenaryUnits = nil,

    ---Total army supplies available for all units.
    ---@type integer
    totalArmySupplies = nil,

    ---Total army supplies cost
    ---@type integer
    totalCost = nil,

    ---Army supplies cost of each unit type present in the army.
    ---@type TotoWar_Cbac_UnitArmySuppliesCost[]
    unitArmySuppliesCosts = nil,
}
TotoWar_Cbac_ArmySuppliesCost.__index = TotoWar_Cbac_ArmySuppliesCost

---Initializes a new instance of TotoWar_Cbac_ArmySuppliesCost.
---@param isAi boolean Indicates whether the army belongs to AI.
---@param lordLevel integer Level of the lord leading the army.
---@return TotoWar_Cbac_ArmySuppliesCost
function TotoWar_Cbac_ArmySuppliesCost.new(isAi, lordLevel)
    logger:logDebug(
        "new(%s, %s): STARTED",
        isAi,
        lordLevel)

    local instance = setmetatable({}, TotoWar_Cbac_ArmySuppliesCost)

    local baseArmySupplies = 0
    local levelBonus = 0

    if isAi then
        baseArmySupplies = TotoWar_Cbac_Mod.options.aiArmySuppliesAmount
        levelBonus = (lordLevel - 1) * TotoWar_Cbac_Mod.options.aiArmySuppliesBonusAmountPerLevel
    else
        baseArmySupplies = TotoWar_Cbac_Mod.options.playerArmySuppliesAmount
        levelBonus = (lordLevel - 1) * TotoWar_Cbac_Mod.options.playerArmySuppliesBonusAmountPerLevel
    end

    instance.lordLevel = lordLevel
    instance.inRecruitmentMercenaryUnits = {}
    instance.totalArmySupplies = baseArmySupplies + levelBonus
    instance.availableSupplies = instance.totalArmySupplies
    instance.totalCost = 0
    instance.unitArmySuppliesCosts = {}

    logger:logDebug(
        "new(%s, %s): COMPLETED => Base army supplies: %s | Bonus army supplies: %s | Total army supplies: %s",
        isAi,
        lordLevel,
        baseArmySupplies,
        levelBonus,
        instance.totalArmySupplies)

    return instance
end

---Initializes a new instance of TotoWar_Cbac_ArmySuppliesCost from an army.
---@param isAi boolean Indicates whether the army belongs to AI.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@return TotoWar_Cbac_ArmySuppliesCost
function TotoWar_Cbac_ArmySuppliesCost.newFromArmy(isAi, army)
    local rank = 1

    if army:has_general() then
        rank = army:general_character():rank()
    end

    local instance = TotoWar_Cbac_ArmySuppliesCost.new(isAi, rank)

    logger:logDebug(
        "newFromArmy(%s, %s): STARTED => %s",
        isAi,
        function() return army:command_queue_index() end,
        function() return TotoWar__Gameplay:getArmyCaption(army) end)

    local characters = army:character_list()

    for i = 0, characters:num_items() - 1, 1 do
        local character = characters:item_at(i)
        instance:addCharacter(character:cqi())
    end

    local units = army:unit_list()

    for i = 0, units:num_items() - 1, 1 do
        local unit = units:item_at(i)
        local unitCqi = unit:command_queue_index()

        local isAlreadyAddedCharacter = TotoWar__Linq:any(
            instance.unitArmySuppliesCosts,
            function(uasc)
                -- We avoid adding the lord and heroes twice
                return uasc.unitCqi == unitCqi
                    and (uasc.unitCategory == TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.lord
                        or uasc.unitCategory == TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.hero)
            end)

        if not isAlreadyAddedCharacter then
            instance:addUnit(unit:unit_key(), unit:command_queue_index(), false, unit)
        end
    end

    logger:logDebug(
        "newFromArmy(%s, %s): COMPLETED => %s | Units: %s | Total cost: %s | Available supplies: %s",
        isAi,
        function() return army:command_queue_index() end,
        function() return TotoWar__Gameplay:getArmyCaption(army) end,
        #instance.unitArmySuppliesCosts,
        instance.totalCost,
        instance.availableSupplies)

    return instance
end

---Adds a unit to the army supplies cost.
---@param characterCqi integer Command queue index of the character.
function TotoWar_Cbac_ArmySuppliesCost:addCharacter(characterCqi)
    logger:logDebug(
        "addCharacter(%s): STARTED => %s",
        characterCqi,
        function()
            local character = TotoWar__Gameplay:getCharacter(characterCqi)

            return character ~= nil and TotoWar__Gameplay:getCharacterFullCaption(character) or "Character not found"
        end)

    local unitArmySuppliesCost = TotoWar_Cbac_UnitArmySuppliesCost.newCharacter(characterCqi)

    if unitArmySuppliesCost ~= nil then
        table.insert(self.unitArmySuppliesCosts, unitArmySuppliesCost)

        self.totalCost = self.totalCost + unitArmySuppliesCost.armySuppliesCost
        self.availableSupplies = self.totalArmySupplies - self.totalCost
    end

    logger:logDebug(
        "addCharacter(%s): COMPLETED => %s | Total cost: %s | Available supplies: %s",
        characterCqi,
        function()
            local character = TotoWar__Gameplay:getCharacter(characterCqi)

            return character ~= nil and TotoWar__Gameplay:getCharacterFullCaption(character) or "Character not found"
        end,
        self.totalCost,
        self.availableSupplies)
end

---Adds a unit to the army supplies cost.
---@param unitKey string Unit key.
---@param unitCqi integer? Unit command queue index if we are able to get one.
---@param isInRecruitmentMercenary boolean? Indicates whether the unit added is a mercenary unit (regiment of renown, Grudge settles, Waaagh mobs, ...) in the recruitment pool.
---@param unit UNIT_SCRIPT_INTERFACE? Unit (if we are able to get one), used when its recruitment cost is negative.
function TotoWar_Cbac_ArmySuppliesCost:addUnit(unitKey, unitCqi, isInRecruitmentMercenary, unit)
    logger:logDebug(
        "addUnit(%s, %s, %s, unit): STARTED => %s",
        unitKey,
        unitCqi,
        isInRecruitmentMercenary,
        function() return unit ~= nil and TotoWar__Gameplay:getArmyCaption(unit:military_force()) or "No army" end)

    if isInRecruitmentMercenary == nil then
        isInRecruitmentMercenary = false
    end

    ---@type TotoWar_Cbac_UnitArmySuppliesCost
    local unitArmySuppliesCost

    if isInRecruitmentMercenary then
        unitArmySuppliesCost = TotoWar_Cbac_UnitArmySuppliesCost.newUnit(unitKey, unitCqi, unit)
        table.insert(self.inRecruitmentMercenaryUnits, unitArmySuppliesCost)
    else
        unitArmySuppliesCost = TotoWar_Cbac_UnitArmySuppliesCost.newUnit(unitKey, unitCqi, unit)
        table.insert(self.unitArmySuppliesCosts, unitArmySuppliesCost)
    end

    self.totalCost = self.totalCost + unitArmySuppliesCost.armySuppliesCost
    self.availableSupplies = self.totalArmySupplies - self.totalCost

    logger:logDebug(
        "addUnit(%s, %s, %s, unit): COMPLETED => %s | Total cost: %s | Available supplies: %s",
        unitKey,
        unitCqi,
        isInRecruitmentMercenary,
        function() return unit ~= nil and TotoWar__Gameplay:getArmyCaption(unit:military_force()) or "No army" end,
        self.totalCost,
        self.availableSupplies)
end

---Clears the list of in-recruitment mercenary units supply costs.
function TotoWar_Cbac_ArmySuppliesCost:clearMercenaryRecruitment()
    logger:logDebug("clearMercenaryRecruitment(): STARTED")

    for i = 1, #self.inRecruitmentMercenaryUnits, 1 do
        self:removeUnit(TotoWar__Enum_Patterns.inRecruitmentMercenaryUnitCard:sub(2) .. "0")
    end

    logger:logDebug("clearMercenaryRecruitment(): COMPLETED")
end

---Removes the character corresponding to a command queue index.
---@param characterCqi integer Character command queue index.
function TotoWar_Cbac_ArmySuppliesCost:removeCharacter(characterCqi)
    logger:logDebug(
        "removeCharacter(%s): STARTED => %s",
        characterCqi,
        function()
            local character = TotoWar__Gameplay:getCharacter(characterCqi)

            return character ~= nil and TotoWar__Gameplay:getCharacterFullCaption(character) or "Character not found"
        end)

    local characterIndex = TotoWar__Linq:findIndex(
        self.unitArmySuppliesCosts,
        function(uasc) return uasc.characterCqi == characterCqi end)

    if characterIndex == -1 then
        local characterCaption = tostring(characterCqi)
        local character = TotoWar__Gameplay:getCharacter(characterCqi)

        if character ~= nil then
            characterCaption = TotoWar__Gameplay:getCharacterFullCaption(character)
        end

        logger:logError(
            "%s: character not counted in army supplies, not removed",
            characterCaption)
        logger:logDebug(
            "removeCharacter(%s): COMPLETED => %s | Not counted, not removed",
            characterCqi,
            characterCaption)

        return
    end

    local character = self.unitArmySuppliesCosts[characterIndex]
    self.totalCost = self.totalCost - character.armySuppliesCost
    self.availableSupplies = self.totalArmySupplies - self.totalCost
    table.remove(self.unitArmySuppliesCosts, characterIndex)

    logger:logDebug(
        "removeCharacter(%s): COMPLETED => %s | Removed character: %s | Total cost: %s | Available supplies: %s",
        characterCqi,
        function()
            local character = TotoWar__Gameplay:getCharacter(characterCqi)

            return character ~= nil and TotoWar__Gameplay:getCharacterFullCaption(character) or "Character not found"
        end,
        function() return TotoWar__Gameplay:getUnitCaption(character.unitKey) end,
        self.totalCost,
        self.availableSupplies)
end

---Removes a unit from the army supplies cost.
---
---When removing a mercenary unit, returns the key of the removed unit.
---This is useful to know which unit was removed because we only know the position
---position of the unit in the recruitment queue before calling `removeUnit`.
---@param unitKey string Unit key.
---@return string | nil
function TotoWar_Cbac_ArmySuppliesCost:removeUnit(unitKey)
    logger:logDebug("removeUnit(%s): STARTED", unitKey)

    local isInRecruitmentMercenaryUnit = string.match(
        unitKey,
        TotoWar__Enum_Patterns.inRecruitmentMercenaryUnitCard)

    if isInRecruitmentMercenaryUnit then
        local positionInRecruitmentQueuePattern = TotoWar__Enum_Patterns.inRecruitmentMercenaryUnitCard .. "(%d+)$"
        -- Position starts at 0 in the recruitment queue, but LUA table indexes start at 1
        local index = tonumber(unitKey:match(positionInRecruitmentQueuePattern)) + 1
        local unit = self.inRecruitmentMercenaryUnits[index]

        if unit == nil then
            logger:logWarning(
                "Mercenary recruitment: unit at position %s not counted, not removed (%s mercenaries counted)",
                index,
                #self.inRecruitmentMercenaryUnits)
            logger:logDebug(
                "removeUnit(%s): COMPLETED => Mercenary not counted, not removed",
                unitKey)

            return nil
        end

        self.totalCost = self.totalCost - unit.armySuppliesCost
        self.availableSupplies = self.totalArmySupplies - self.totalCost
        table.remove(self.inRecruitmentMercenaryUnits, index)

        logger:logDebug(
            "removeUnit(%s): COMPLETED => Removed unit: %s | Total cost: %s | Available supplies: %s",
            unitKey,
            function() return TotoWar__Gameplay:getUnitCaption(unit.unitKey) end,
            self.totalCost,
            self.availableSupplies)

        return unit.unitKey;
    else
        -- Prioritizing removing the last unit added which in theory should be the least experienced
        for i = #self.unitArmySuppliesCosts, 1, -1 do
            local unit = self.unitArmySuppliesCosts[i]

            if unit.unitKey == unitKey then
                self.totalCost = self.totalCost - unit.armySuppliesCost
                self.availableSupplies = self.totalArmySupplies - self.totalCost
                table.remove(self.unitArmySuppliesCosts, i)

                logger:logDebug(
                    "removeUnit(%s): COMPLETED => Removed unit: %s | Total cost: %s | Available supplies: %s",
                    unitKey,
                    function() return TotoWar__Gameplay:getUnitCaption(unitKey) end,
                    self.totalCost,
                    self.availableSupplies)

                return unitKey;
            end
        end
    end

    logger:logError(
        "%s: unit not counted in army supplies, not removed",
        TotoWar__Gameplay:getUnitCaption(unitKey))
end

---Sorts army supplies costs by unit category, army supplies cost and name.
---
---Unit category order : Lord, Hero, Melee Infantry, Ranged Infantry, Cavalry & Monsters, War machines
function TotoWar_Cbac_ArmySuppliesCost:sortUnitArmySuppliesCost()
    logger:logDebug(
        "sortUnitArmySuppliesCost(): STARTED => Units: %s",
        #self.unitArmySuppliesCosts)

    local categoryPriority = {
        [TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.lord] = 1,
        [TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.hero] = 2,
        [TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.meleeInfantry] = 3,
        [TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.rangedInfantry] = 4,
        [TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.cavalryAndMonsters] = 5,
        [TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.warMachines] = 6
    }

    ---@type table<string, string>
    local captions = {}

    for index, unitArmySuppliesCost in ipairs(self.unitArmySuppliesCosts) do
        if captions[unitArmySuppliesCost.unitKey] == nil then
            captions[unitArmySuppliesCost.unitKey] = TotoWar__Gameplay:getUnitCaption(unitArmySuppliesCost.unitKey)
        end
    end

    table.sort(
        self.unitArmySuppliesCosts,
        function(item1, item2)
            local priority1 = categoryPriority[item1.unitCategory] or math.huge
            local priority2 = categoryPriority[item2.unitCategory] or math.huge

            -- Category sort
            if priority1 ~= priority2 then
                return priority1 < priority2
            end

            -- Cost sort
            if item1.armySuppliesCost ~= item2.armySuppliesCost then
                return item1.armySuppliesCost < item2.armySuppliesCost
            end

            -- Name sort
            local caption1 = captions[item1.unitKey]
            local caption2 = captions[item2.unitKey]

            if caption1 ~= caption2 then
                return caption1 < caption2
            end

            -- In case of full equality, the method must return false to be considered a valid sort funtionc
            return tostring(item1.unitKey) < tostring(item2.unitKey)
        end
    )

    logger:logDebug(
        "sortUnitArmySuppliesCost(): COMPLETED => Units: %s",
        #self.unitArmySuppliesCosts)
end

---Gets the list of unit army supplies costs as a tooltip string.
---@return string
function TotoWar_Cbac_ArmySuppliesCost:toArmySuppliesCostTooltipText()
    logger:logDebug(
        "toArmySuppliesCostTooltipText(): STARTED => Units: %s | Mercenaries being recruited: %s",
        #self.unitArmySuppliesCosts,
        #self.inRecruitmentMercenaryUnits)

    local unitsArmySuppliesCostTooltipText = ""

    self:sortUnitArmySuppliesCost() -- Sorting groups by category, price and and caption

    for index, unitArmySuppliesCost in ipairs(self.unitArmySuppliesCosts) do
        unitsArmySuppliesCostTooltipText =
            unitsArmySuppliesCostTooltipText
            .. "\n"
            .. toUnitArmySuppliesCostTooltipText(unitArmySuppliesCost)
    end

    for index, mercenaryUnitArmySuppliesCost in ipairs(self.inRecruitmentMercenaryUnits) do
        unitsArmySuppliesCostTooltipText =
            unitsArmySuppliesCostTooltipText
            .. "\n"
            .. toUnitArmySuppliesCostTooltipText(mercenaryUnitArmySuppliesCost)
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

    logger:logDebug(
        "toArmySuppliesCostTooltipText(): COMPLETED => Units: %s | Mercenaries being recruited: %s",
        #self.unitArmySuppliesCosts,
        #self.inRecruitmentMercenaryUnits)

    return tooltipText
end
