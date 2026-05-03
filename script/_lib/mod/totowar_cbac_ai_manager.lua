---Manager in charge of managing the army supplies for the AI armies.
---@class TotoWarCbacAiManager
TotoWarCbacAiManager = {
    ---List of armies to check and adjust in order to comply with army supply restrictions.
    ---Key: Command queue index of the lord.
    ---Value: Number of recruited units.
    ---@type { [string]: integer }
    armyAdjustmentQueue = {}
}
TotoWarCbacAiManager.__index = TotoWarCbacAiManager

local _elitismCoefficients = { 1, 1.1, 1.2, 1.3, 1.4, 1.5 }
local _storageKeyElitismCoefficientPrefix = "totowar_cbac_elitism_coefficient_"

---Initializes a new instance.
---@return TotoWarCbacAiManager
function TotoWarCbacAiManager.new()
    TotoWarCbac.loggers.aiManager:logDebug("TotoWarCbacAiManager.new(): STARTED")

    local instance = setmetatable({}, TotoWarCbacAiManager)

    TotoWarCbac.loggers.aiManager:logDebug("TotoWarCbacAiManager.new(): COMPLETED")

    return instance
end

---Adds listeners for events.
function TotoWarCbacAiManager:addListeners()
    TotoWarCbac.loggers.aiManager:logDebug("addListeners(): STARTED")

    TotoWar.utils:addListener(
        "TotoWarCbacAiManager",
        TotoWar.enums.gameEvents.militaryForceCreated,
        function()
            return
                TotoWarCbac.options.aiArmySuppliesEnabled
                and not cm:is_local_players_turn()
        end,
        ---@param context TotoWarGameEventContext_MilitaryForceCreated
        function(context)
            self:onAiArmyCreated(context:military_force_created())
        end)

    TotoWar.utils:addListener(
        "TotoWarCbacAiManager",
        TotoWar.enums.gameEvents.unitConverted,
        function()
            return
                TotoWarCbac.options.aiArmySuppliesEnabled
                and not cm:is_local_players_turn()
        end,
        ---@param context TotoWarGameEventContext_UnitConverted
        function(context)
            self:onAiUnitConverted(context:unit(), context:converted_unit())
        end)

    TotoWar.utils:addListener(
        "TotoWarCbacAiManager",
        TotoWar.enums.gameEvents.unitDisbanded,
        function()
            return
                TotoWarCbac.options.aiArmySuppliesEnabled
                and not cm:is_local_players_turn()
        end,
        ---@param context TotoWarGameEventContext_UnitDisbanded
        function(context)
            self:onAiUnitDisbanded(context:unit())
        end)

    TotoWar.utils:addListener(
        "TotoWarCbacAiManager",
        TotoWar.enums.gameEvents.unitTrained,
        ---@param context TotoWarGameEventContext_UnitTrained
        function(context)
            return
                TotoWarCbac.options.aiArmySuppliesEnabled
                and not cm:is_local_players_turn()
                and context:unit():military_force()
                and TotoWar.utils:canRecruitUnits(context:unit():military_force())
        end,
        ---@param context TotoWarGameEventContext_UnitTrained
        function(context)
            self:onAiUnitRecruited(context:unit())
        end)

    TotoWar.utils:addListener(
        "TotoWarCbacAiManager",
        TotoWar.enums.gameEvents.unitUpgraded,
        function()
            return
                TotoWarCbac.options.aiArmySuppliesEnabled
                and not cm:is_local_players_turn()
        end,
        ---@param context TotoWarGameEventContext_UnitUpgraded
        function(context)
            self:onAiUnitUpgraded(context:unit())
        end)

    TotoWarCbac.loggers.aiManager:logDebug("addListeners(): COMPLETED")
end

---Adjusts an AI army by removing excess heroes and units when its cost exceeds army supplies.
---@param lordCqi integer Command queue index of the lord whose army will be adjusted.
function TotoWarCbacAiManager:adjustAiArmy(lordCqi)
    local lord = cm:get_character_by_cqi(lordCqi)

    if lord == nil then
        -- This can happen sometimes (5 times in 80 turns) for some reason
        TotoWarCbac.loggers.aiManager:logError("adjustAiArmy(%s): LORD NOT FOUND", lordCqi)

        return
    end

    local army = lord:military_force()
    local armySuppliesCost = TotoWarCbacArmySuppliesCost.newFromArmy(true, army)

    if armySuppliesCost.availableSupplies >= 0 then
        return
    end

    TotoWarCbac.loggers.aiManager:logDebug(
        "adjustAiArmy(%s from %s): STARTED => Total army supplies cost: %s | Available army supplies: %s",
        function() return TotoWar.utils:getCharacterCaption(lord) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return armySuppliesCost.totalCost end,
        function() return armySuppliesCost.availableSupplies end)

    -- Sorting units from the cheapest to the priciest
    table.sort(
        armySuppliesCost.unitArmySuppliesCosts,
        function(a, b)
            return a.armySuppliesCost < b.armySuppliesCost
        end)

    -- Removing excess of heroes
    self:adjustAiArmyHeroes(army, armySuppliesCost)

    ---@type TotoWarCbacUnitArmySuppliesCost[]
    local unitsToDiscard = {}

    -- Adding to the list of units to remove the cheapest units of categories that have too many units
    self:adjustAiArmyComposition(army, armySuppliesCost, unitsToDiscard)

    -- Adding to the list of units to remove the cheapest units to pass under the maximum army supplies cost
    self:adjustAiArmyUnits(army, armySuppliesCost, unitsToDiscard)

    -- Removing units flagged as discardable to stay within the army supplies limit
    for index, unitToDiscard in ipairs(unitsToDiscard) do
        self:removeUnitFromAiArmy(army, unitToDiscard.unitKey, unitToDiscard.unitCqi)
    end

    TotoWarCbac.loggers.aiManager:logDebug(
        "adjustAiArmy(%s from %s): COMPLETED => Total army supplies cost: %s | Available army supplies: %s",
        function() return TotoWar.utils:getCharacterCaption(lord) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return armySuppliesCost.totalCost end,
        function() return armySuppliesCost.availableSupplies end)
end

---Adjusts the amount of heroes in an army if it exceeds the limit.
---
---Duplicate hero types are removed first.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@param armySuppliesCost TotoWarCbacArmySuppliesCost Army supplies cost of the army. Updated if heroes are removed.
function TotoWarCbacAiManager:adjustAiArmyHeroes(army, armySuppliesCost)
    local heroes = totoWar_linqWhere(
        armySuppliesCost.unitArmySuppliesCosts,
        function(uasc) return uasc.unitCategory == TotoWarCbac.enums.armyCompositionUnitTypes.hero end)
    local heroesToRemoveAmount = #heroes - TotoWarCbac.options.aiArmyHeroMaximumAmount

    if heroesToRemoveAmount <= 0 then
        return
    end

    local lord = army:general_character()

    TotoWarCbac.loggers.aiManager:logDebug(
        "adjustAiArmyHeroes(%s from %s): STARTED => Total army supplies cost: %s | Available army supplies: %s",
        function() return TotoWar.utils:getCharacterCaption(lord) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return armySuppliesCost.totalCost end,
        function() return armySuppliesCost.availableSupplies end)

    -- Grouping heroes by their base type to ignore their mount
    local heroUnitGroups = totoWar_linqGroupBy(heroes, function(a) return a.baseUnitKey end)

    while heroesToRemoveAmount > 0 do
        -- Finding the group of heroes with the most heroes (or the last hero group when they all have the same amount of heroes)
        ---@type string
        local heroGroupKey
        local heroGroupUnitCount = 0

        for key, heroUnits in pairs(heroUnitGroups) do
            if #heroUnits >= heroGroupUnitCount then
                heroGroupUnitCount = #heroUnits
                heroGroupKey = key
            end
        end

        local heroToRemoveIndex = #heroUnitGroups[heroGroupKey]
        local heroToRemove = heroUnitGroups[heroGroupKey][heroToRemoveIndex]

        -- Getting the location where the hero will be teleported
        local heroTargetPositionX, heroTargetPositionY = cm:find_valid_spawn_location_for_character_from_position(
            lord:faction():name(),
            lord:logical_position_x(),
            lord:logical_position_y(),
            true);

        -- Teleporting the last hero of the group out of the lord army.
        -- Forced to use the teleport method instead of just moving the hero because teleporting is
        -- done instantly while moving is done after the next `UnitTrained` events are received.
        -- If we do not teleport the hero, it is still in the army when we calculate army
        -- supplies costs during later `UnitTrained` events which we do not want.
        cm:teleport_to(
            cm:char_lookup_str(heroToRemove.characterCqi),
            ---@diagnostic disable-next-line: param-type-mismatch
            heroTargetPositionX,
            ---@diagnostic disable-next-line: param-type-mismatch
            heroTargetPositionY)

        armySuppliesCost:removeCharacter(heroToRemove.characterCqi)
        heroesToRemoveAmount = heroesToRemoveAmount - 1

        TotoWarCbac.loggers.aiManager:logDebug(
            "adjustAiArmyHeroes(%s from %s): REMOVED => %s (%s)",
            function() return TotoWar.utils:getCharacterCaption(lord) end,
            function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
            function() return TotoWar.utils:getCharacterCaption(cm:get_character_by_cqi(heroToRemove.characterCqi)) end,
            function() return TotoWar.utils:getUnitCaption(heroToRemove.unitKey) end)
    end

    TotoWarCbac.loggers.aiManager:logDebug(
        "adjustAiArmyHeroes(%s from %s): COMPLETED => Total army supplies cost: %s | Available army supplies: %s",
        function() return TotoWar.utils:getCharacterCaption(lord) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return armySuppliesCost.totalCost end,
        function() return armySuppliesCost.availableSupplies end)
end

---Adjusts the units in an army to stay within maximum number of units allowed in each unit category.
---
---Cheapest units are removed first.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@param armySuppliesCost TotoWarCbacArmySuppliesCost Army supplies cost of the army. Updated if units are flagged as to removed.
---@param unitsToDiscard TotoWarCbacUnitArmySuppliesCost[] List in which units to discard are stored. Updated if units are flagged as to be removed.
function TotoWarCbacAiManager:adjustAiArmyComposition(army, armySuppliesCost, unitsToDiscard)
    if armySuppliesCost.availableSupplies >= 0 then
        return
    end

    TotoWarCbac.loggers.aiManager:logDebug(
        "adjustAiArmyComposition(%s from %s): STARTED => Total army supplies cost: %s | Available army supplies: %s",
        function() return TotoWar.utils:getCharacterCaption(army:general_character()) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return armySuppliesCost.totalCost end,
        function() return armySuppliesCost.availableSupplies end)

    -- Getting the number of units that exceeds the maximum proportion that is configured
    local unitCategoryExcessCounts = armySuppliesCost:getUnitCategoryExcessCounts()

    -- While the army supplies cost exceeds the maximum allowed, we add the exceeding units to the list of units to remove
    for unitCategory, unitCategoryExcessCount in pairs(unitCategoryExcessCounts) do
        if armySuppliesCost.availableSupplies > 0 or unitCategoryExcessCount == 0 then
            break
        end

        TotoWarCbac.loggers.aiManager:logDebug(
            "adjustAiArmyComposition(%s from %s): Category: %s | Excess: %s | Total army supplies cost: %s | Available army supplies: %s",
            function() return TotoWar.utils:getCharacterCaption(army:general_character()) end,
            function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
            function() return unitCategory end,
            function() return unitCategoryExcessCount end,
            function() return armySuppliesCost.totalCost end,
            function() return armySuppliesCost.availableSupplies end)

        for index, unitArmySuppliesCost in ipairs(armySuppliesCost.unitArmySuppliesCosts) do
            if armySuppliesCost.availableSupplies > 0 or unitCategoryExcessCount == 0 then
                break
            end

            if unitArmySuppliesCost.unitCategory == unitCategory then
                table.insert(unitsToDiscard, unitArmySuppliesCost)
                armySuppliesCost:removeUnit(unitArmySuppliesCost.unitKey)
                unitCategoryExcessCount = unitCategoryExcessCount - 1

                TotoWarCbac.loggers.aiManager:logDebug(
                    "adjustAiArmyComposition(%s from %s): EXCEEDING => %s | Category: %s | Remaining excess: %s | Total army supplies cost: %s | Available army supplies: %s",
                    function() return TotoWar.utils:getCharacterCaption(army:general_character()) end,
                    function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
                    function() return TotoWar.utils:getUnitCaption(unitArmySuppliesCost.unitKey) end,
                    function() return unitCategory end,
                    function() return unitCategoryExcessCount end,
                    function() return armySuppliesCost.totalCost end,
                    function() return armySuppliesCost.availableSupplies end)
            end
        end
    end

    TotoWarCbac.loggers.aiManager:logDebug(
        "adjustAiArmyComposition(%s from %s): COMPLETED => Total army supplies cost: %s | Available army supplies: %s",
        function() return TotoWar.utils:getCharacterCaption(army:general_character()) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return armySuppliesCost.totalCost end,
        function() return armySuppliesCost.availableSupplies end)
end

---Adjusts the units in an army to stay below the army supplies cost limit by removing a combination of the cheapest possible units.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@param armySuppliesCost TotoWarCbacArmySuppliesCost Army supplies cost of the army. Updated if heroes are removed.
---@param unitsToDiscard TotoWarCbacUnitArmySuppliesCost[] List in which units to discard are stored. Updated if units are flagged as to be removed.
function TotoWarCbacAiManager:adjustAiArmyUnits(army, armySuppliesCost, unitsToDiscard)
    if armySuppliesCost.availableSupplies >= 0 then
        return
    end

    local lord = army:general_character()

    TotoWarCbac.loggers.aiManager:logDebug(
        "adjustAiArmyUnits(%s from %s): STARTED => Total army supplies cost: %s | Available army supplies: %s",
        function() return TotoWar.utils:getCharacterCaption(lord) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return armySuppliesCost.totalCost end,
        function() return armySuppliesCost.availableSupplies end)

    local disposableUnits = totoWar_linqWhere(
        armySuppliesCost.unitArmySuppliesCosts,
        function(uasc)
            return
                uasc.unitCategory ~= TotoWarCbac.enums.armyCompositionUnitTypes.lord
                and uasc.unitCategory ~= TotoWarCbac.enums.armyCompositionUnitTypes.hero
        end)

    ---@type number | nil
    local elitismCoefficient = cm:get_saved_value(_storageKeyElitismCoefficientPrefix .. lord:cqi())

    if elitismCoefficient == nil then
        local index = math.random(1, #_elitismCoefficients)
        elitismCoefficient = _elitismCoefficients[index]
        cm:set_saved_value(_storageKeyElitismCoefficientPrefix .. lord:cqi(), elitismCoefficient)
    end

    ---@type TotoWarCbacUnitArmySuppliesCost[]
    local finalSelectedUnits = {}
    local armySuppliesCostToDiscard = -armySuppliesCost.availableSupplies
    local disposableUnitsNumber = math.floor(
        elitismCoefficient * self.armyAdjustmentQueue[lord:cqi()])

    TotoWarCbac.loggers.aiManager:logDebug(
        "adjustAiArmyUnits(%s from %s): DISPOSABLE UNITS => %s | Elitism coefficient: %s",
        function() return TotoWar.utils:getCharacterCaption(lord) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return disposableUnitsNumber end,
        function() return elitismCoefficient end)

    for i = 1, disposableUnitsNumber, 1 do
        -- Iterating to find up to disposableUnitsNumber units that can be discarded to cover armySuppliesCostToDiscard
        local startIndex = 0
        local endIndex = startIndex + disposableUnitsNumber - 1

        if endIndex > #disposableUnits - 1 then
            endIndex = #disposableUnits - 1
        end

        ---@type TotoWarCbacUnitArmySuppliesCost[]
        local selectedUnits = {}
        local selectedUnitsArmySuppliesCost = 0

        while endIndex < #disposableUnits and selectedUnitsArmySuppliesCost < armySuppliesCostToDiscard do
            -- Iterating throught each combination of disposableUnitsNumber units until we find the first
            -- combination that covers the armySuppliesCostToDiscard (or we reach the last unit)
            selectedUnits = {}
            selectedUnitsArmySuppliesCost = 0

            startIndex = startIndex + 1
            endIndex = endIndex + 1

            for j = startIndex, endIndex, 1 do
                table.insert(selectedUnits, disposableUnits[j])
                selectedUnitsArmySuppliesCost = selectedUnitsArmySuppliesCost + disposableUnits[j].armySuppliesCost

                if selectedUnitsArmySuppliesCost >= armySuppliesCostToDiscard then
                    break
                end
            end
        end

        -- Adding the priciest unit of the combination to the list of units that will be discarded.
        -- Since it is this unit that made it possible to reach the armySuppliesCostToDiscard, we know for sure that it must be discarded.
        -- Further iterations are used to optimise the cost of the other units that must also be discarded to the reach remaining armySuppliesCostToDiscard.
        table.insert(finalSelectedUnits, selectedUnits[#selectedUnits])
        armySuppliesCostToDiscard = armySuppliesCostToDiscard - selectedUnits[#selectedUnits].armySuppliesCost

        TotoWarCbac.loggers.aiManager:logDebug(
            "adjustAiArmyUnits(%s from %s): UNIT TO DISCARD: %s (%s)",
            function() return TotoWar.utils:getCharacterCaption(lord) end,
            function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
            function() return TotoWar.utils:getUnitCaption(selectedUnits[#selectedUnits].unitKey) end,
            function() return selectedUnits[#selectedUnits].armySuppliesCost end)

        if armySuppliesCostToDiscard <= 0 then
            -- If armySuppliesCostToDiscard is less than or equal to 0 after adding the priciest unit of the combination to the list of units
            -- that will be discarded, there is no need to find further units to discard as the cost is covered by the last priciest unit.
            break
        end
    end

    for index, selectedUnit in ipairs(finalSelectedUnits) do
        table.insert(unitsToDiscard, selectedUnit)
        armySuppliesCost:removeUnit(selectedUnit.unitKey)
    end

    TotoWarCbac.loggers.aiManager:logDebug(
        "adjustAiArmyUnits(%s from %s): COMPLETED => Total army supplies cost: %s | Available army supplies: %s",
        function() return TotoWar.utils:getCharacterCaption(lord) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return armySuppliesCost.totalCost end,
        function() return armySuppliesCost.availableSupplies end)
end

---Reacts to an army being created by an AI faction.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
function TotoWarCbacAiManager:onAiArmyCreated(army)
    TotoWarCbac.loggers.aiManager:logDebug(
        "onAiArmyCreated(%s from %s): STARTED",
        function() return TotoWar.utils:getCharacterCaption(army:general_character()) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end)

    -- This is just to log how AI creates armies and how it impacts the mod

    TotoWarCbac.loggers.aiManager:logDebug(
        "onAiArmyCreated(%s from %s): COMPLETED",
        function() return TotoWar.utils:getCharacterCaption(army:general_character()) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end)
end

---Reacts to a unit being converted by an AI army.
---@param originalUnit UNIT_SCRIPT_INTERFACE Unit.
---@param newUnit UNIT_SCRIPT_INTERFACE Unit.
function TotoWarCbacAiManager:onAiUnitConverted(originalUnit, newUnit)
    TotoWarCbac.loggers.aiManager:logDebug(
        "onAiUnitConverted(%s from %s, %s, %s): STARTED",
        function() return TotoWar.utils:getCharacterCaption(newUnit:military_force():general_character()) end,
        function() return TotoWar.utils:getFactionCaption(newUnit:military_force():faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(originalUnit:unit_key()) end,
        function() return TotoWar.utils:getUnitCaption(newUnit:unit_key()) end)

    -- This is just to log how AI converts units and how it impacts the mod

    TotoWarCbac.loggers.aiManager:logDebug(
        "onAiUnitConverted(%s from %s, %s, %s): COMPLETED",
        function() return TotoWar.utils:getCharacterCaption(newUnit:military_force():general_character()) end,
        function() return TotoWar.utils:getFactionCaption(newUnit:military_force():faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(originalUnit:unit_key()) end,
        function() return TotoWar.utils:getUnitCaption(newUnit:unit_key()) end)
end

---Reacts to a unit being disbanded by an AI army.
---@param unit UNIT_SCRIPT_INTERFACE Unit.
function TotoWarCbacAiManager:onAiUnitDisbanded(unit)
    TotoWarCbac.loggers.aiManager:logDebug(
        "onAiUnitDisbanded(%s from %s, %s): STARTED",
        function() return TotoWar.utils:getCharacterCaption(unit:military_force():general_character()) end,
        function() return TotoWar.utils:getFactionCaption(unit:military_force():faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(unit:unit_key()) end)

    -- This is just to log how AI disbands units and how it impacts the mod

    TotoWarCbac.loggers.aiManager:logDebug(
        "onAiUnitDisbanded(%s from %s, %s): COMPLETED",
        function() return TotoWar.utils:getCharacterCaption(unit:military_force():general_character()) end,
        function() return TotoWar.utils:getFactionCaption(unit:military_force():faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(unit:unit_key()) end)
end

---Reacts to a unit being recruited by an AI army.
---@param unit UNIT_SCRIPT_INTERFACE Unit.
function TotoWarCbacAiManager:onAiUnitRecruited(unit)
    local lord = unit:military_force():general_character()

    TotoWarCbac.loggers.aiManager:logDebug(
        "onAiUnitRecruited(%s from %s, %s): STARTED",
        function() return TotoWar.utils:getCharacterCaption(lord) end,
        function() return TotoWar.utils:getFactionCaption(unit:military_force():faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(unit:unit_key()) end)

    if self.armyAdjustmentQueue[lord:cqi()] == nil
    then
        self.armyAdjustmentQueue[lord:cqi()] = 1

        -- Forced to use a callback here to defer the adjustment until all units are recruited.
        -- Disbanding units each time the unit recruitment unit was received could lead to crashes so
        -- we switched to a defered global adjustment to fix that.
        cm:callback(
            function()
                self:adjustAiArmy(lord:cqi())
                self.armyAdjustmentQueue[lord:cqi()] = nil
            end,
            0.001)
    else
        self.armyAdjustmentQueue[lord:cqi()] = self.armyAdjustmentQueue[lord:cqi()] + 1
    end

    TotoWarCbac.loggers.aiManager:logDebug(
        "onAiUnitRecruited(%s from %s, %s): COMPLETED",
        function() return TotoWar.utils:getCharacterCaption(lord) end,
        function() return TotoWar.utils:getFactionCaption(unit:military_force():faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(unit:unit_key()) end)
end

---Reacts to a unit being upgraded by an AI army.
---@param unit UNIT_SCRIPT_INTERFACE Unit.
function TotoWarCbacAiManager:onAiUnitUpgraded(unit)
    TotoWarCbac.loggers.aiManager:logDebug(
        "onAiUnitUpgraded(%s from %s, %s): STARTED",
        function() return TotoWar.utils:getCharacterCaption(unit:military_force():general_character()) end,
        function() return TotoWar.utils:getFactionCaption(unit:military_force():faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(unit:unit_key()) end)

    -- This is just to log how AI upgrades units and how it impacts the mod

    TotoWarCbac.loggers.aiManager:logDebug(
        "onAiUnitUpgraded(%s from %s, %s): COMPLETED",
        function() return TotoWar.utils:getCharacterCaption(unit:military_force():general_character()) end,
        function() return TotoWar.utils:getFactionCaption(unit:military_force():faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(unit:unit_key()) end)
end

---Removes a unit from an AI army and reimburses the AI faction of the cost of the unit.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@param unitKey string Key of the unit to remove.
---@param unitCqi integer Command queue index of the unit to remove.
function TotoWarCbacAiManager:removeUnitFromAiArmy(army, unitKey, unitCqi)
    TotoWarCbac.loggers.aiManager:logDebug(
        "removeUnitFromAiArmy(%s from %s, %s, %s): STARTED",
        function() return TotoWar.utils:getCharacterCaption(army:general_character()) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(unitKey) end,
        function() return unitCqi end)

    local unitRealCost = cco("CcoCampaignUnit", unitCqi):Call("Cost")

    if unitRealCost ~= nil and unitRealCost > 0 then
        cm:treasury_mod(army:faction():name(), unitRealCost)

        TotoWarCbac.loggers.aiManager:logDebug(
            "removeUnitFromAiArmy(%s from %s, %s, %s): REIMBURSE => %s | New treasury: %s",
            function() return TotoWar.utils:getCharacterCaption(army:general_character()) end,
            function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
            function() return TotoWar.utils:getUnitCaption(unitKey) end,
            function() return unitCqi end,
            function() return unitRealCost end,
            function() return army:faction():treasury() end)
    end

    -- TODO : THIS LINE MAY CAUSE THE GAME TO CRASH IN SOME CASES
    -- IF WE DELAY IT BY 0.01s WITH A CALLBACK, IT DOES NOT CRASH ANYMORE, BUT OTHER CALLS TO
    -- removeUnitFromAiArmy ARE TRIGGERED BEFORE UNITS ARE REMOVED SO COST CALCULATION ARE WRONG
    cm:remove_unit_from_character(cm:char_lookup_str(army:general_character()), unitKey)

    TotoWarCbac.loggers.aiManager:logDebug(
        "removeUnitFromAiArmy(%s from %s, %s, %s): COMPLETED",
        function() return TotoWar.utils:getCharacterCaption(army:general_character()) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(unitKey) end,
        function() return unitCqi end)
end
