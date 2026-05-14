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

local _storageKeyTargetArmySizePrefix = "totowar_cbac_target_army_size_"

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

    if not lord then
        -- This can happen sometimes for some reason
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

    -- Adjust composition and units simultaneously
    self:adjustAiArmyCompositionAndUnits(army, armySuppliesCost, unitsToDiscard)

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
    local heroes = TotoWarLinq:where(
        armySuppliesCost.unitArmySuppliesCosts,
        function(uasc) return uasc.unitCategory == TotoWarCbac.enums.armyCompositionUnitTypes.hero end)
    local heroesToRemoveAmount = #heroes - TotoWarCbac.options.aiArmyHeroMaximumAmount

    if heroesToRemoveAmount <= 0 then
        return 0
    end

    local lord = army:general_character()

    TotoWarCbac.loggers.aiManager:logDebug(
        "adjustAiArmyHeroes(%s from %s): STARTED => Total army supplies cost: %s | Available army supplies: %s",
        function() return TotoWar.utils:getCharacterCaption(lord) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return armySuppliesCost.totalCost end,
        function() return armySuppliesCost.availableSupplies end)

    -- Grouping heroes by their base type to ignore their mount
    local heroUnitGroups = TotoWarLinq:groupBy(heroes, function(a) return a.baseUnitKey end)

    while heroesToRemoveAmount > 0 do
        -- Finding the group of heroes with the most heroes (or the last hero group when they all have the same amount of heroes)
        ---@type TotoWarKeyValue<string, TotoWarCbacUnitArmySuppliesCost[]>
        local heroUnitGroupWithMostHeroes = nil

        for index, entry in ipairs(heroUnitGroups.entries) do
            if heroUnitGroupWithMostHeroes == nil or #entry.value >= #heroUnitGroupWithMostHeroes.value then
                heroUnitGroupWithMostHeroes = entry
            end
        end

        local heroToRemoveIndex = #heroUnitGroupWithMostHeroes.value
        local heroToRemove = heroUnitGroupWithMostHeroes.value[heroToRemoveIndex]

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

---Adjusts the units in an army to stay within maximum number of units allowed in each unit category and within army supplies cost and target army size.
---
---Uses a dynamic programming knapsack algorithm to find the best subset of removable units that covers the cost deficit while respecting the exact size reduction when required.
---Totally vibe-coded, I'm too dumb to implement this.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@param armySuppliesCost TotoWarCbacArmySuppliesCost Army supplies cost of the army. Updated if units are flagged as to removed.
---@param unitsToDiscard TotoWarCbacUnitArmySuppliesCost[] List in which units to discard are stored. Updated if units are flagged as to be removed.
function TotoWarCbacAiManager:adjustAiArmyCompositionAndUnits(army, armySuppliesCost, unitsToDiscard)
    if armySuppliesCost.availableSupplies >= 0 then
        return
    end

    local lord = army:general_character()

    TotoWarCbac.loggers.aiManager:logDebug(
        "adjustAiArmyCompositionAndUnits(%s from %s): STARTED => Total army supplies cost: %s | Available army supplies: %s",
        function() return TotoWar.utils:getCharacterCaption(lord) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return armySuppliesCost.totalCost end,
        function() return armySuppliesCost.availableSupplies end)

    local removableUnits = TotoWarLinq:where(
        armySuppliesCost.unitArmySuppliesCosts,
        function(uasc)
            return
                uasc.unitCategory ~= TotoWarCbac.enums.armyCompositionUnitTypes.lord
                and uasc.unitCategory ~= TotoWarCbac.enums.armyCompositionUnitTypes.hero
        end)

    if #removableUnits == 0 then
        return
    end

    local unitCategoryExcessCounts = armySuppliesCost:getUnitCategoryExcessCounts()
    local targetArmySize = self:getLordTargetArmySize(lord:cqi())
    local currentArmySize = #armySuppliesCost.unitArmySuppliesCosts
    local requiredRemovalsForSize = math.max(0, currentArmySize - targetArmySize)
    local excessArmySuppliesCost = -armySuppliesCost.availableSupplies

    TotoWarCbac.loggers.aiManager:logDebug(
        "adjustAiArmyCompositionAndUnits(%s from %s): Target army size: %s | Army size: %s",
        function() return TotoWar.utils:getCharacterCaption(lord) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return targetArmySize end,
        function() return currentArmySize end)

    -- Convert the candidate units into a DP-friendly table. Each unit gets a value: excessScore * 1,000,000 + armySuppliesCost.
    -- This biases the DP to prefer excess-category units first, then higher cost.
    local candidateUnitList = {}
    local maxCandidateCost = 0

    for unitIndex, unit in ipairs(removableUnits) do
        local excessCategoryScore = 0

        if unitCategoryExcessCounts[unit.unitCategory] and unitCategoryExcessCounts[unit.unitCategory] > 0 then
            excessCategoryScore = 1
        end

        local unitScore = excessCategoryScore * 1000000 + unit.armySuppliesCost
        table.insert(
            candidateUnitList,
            {
                unit = unit,
                cost = unit.armySuppliesCost,
                excessScore = excessCategoryScore,
                value = unitScore,
                index = unitIndex
            })
        maxCandidateCost = maxCandidateCost + unit.armySuppliesCost
    end

    -- DP table dimensions: count of removed units × total cost covered.
    local candidateCount = #candidateUnitList
    local maxRemovableUnits = candidateCount
    local MINIMUM_SCORE = -1e18

    local bestScoreForCountAndCost = {}
    local parentPointer = {}

    for removedUnitCount = 0, maxRemovableUnits do
        bestScoreForCountAndCost[removedUnitCount] = {}
        parentPointer[removedUnitCount] = {}
        for accumulatedCost = 0, maxCandidateCost do
            bestScoreForCountAndCost[removedUnitCount][accumulatedCost] = MINIMUM_SCORE
        end
    end
    bestScoreForCountAndCost[0][0] = 0

    -- Fill the DP table.
    -- bestScoreForCountAndCost[count][cost] = best total score achievable by removing exactly `count` units with summed cost `cost`.
    for candidateIndex = 1, candidateCount do
        local candidateUnit = candidateUnitList[candidateIndex]

        for removedUnitCount = maxRemovableUnits, 1, -1 do
            for accumulatedCost = maxCandidateCost, candidateUnit.cost, -1 do
                local previousScore =
                    bestScoreForCountAndCost[removedUnitCount - 1][accumulatedCost - candidateUnit.cost]
                if previousScore > MINIMUM_SCORE then
                    local candidateScore = previousScore + candidateUnit.value
                    if candidateScore > bestScoreForCountAndCost[removedUnitCount][accumulatedCost] then
                        bestScoreForCountAndCost[removedUnitCount][accumulatedCost] = candidateScore
                        parentPointer[removedUnitCount][accumulatedCost] = {
                            prevCost = accumulatedCost -
                                candidateUnit.cost,
                            candidateIndex = candidateIndex
                        }
                    end
                end
            end
        end
    end

    -- Reconstruct selected units from parent pointers.
    local function reconstructSolution(removeCount, totalCost)
        local selectedUnits = {}
        local usedUnitIndexes = {}
        while removeCount > 0 and totalCost >= 0 do
            local step = parentPointer[removeCount][totalCost]

            if not step then
                break
            end

            local entry = candidateUnitList[step.candidateIndex]
            table.insert(selectedUnits, entry)
            usedUnitIndexes[step.candidateIndex] = true
            totalCost = step.prevCost
            removeCount = removeCount - 1
        end

        return selectedUnits, usedUnitIndexes
    end

    local chosenRemovalCount = nil
    local chosenRemovalCost = nil
    local chosenRemovalScore = MINIMUM_SCORE

    if requiredRemovalsForSize > 0 then
        -- We must remove exactly requiredRemovalsForSize units.
        local requiredRemovalCount = requiredRemovalsForSize

        if requiredRemovalCount > maxRemovableUnits then
            requiredRemovalCount = maxRemovableUnits
        end

        -- Choose the best cost >= costDeficit for that exact removal count.
        for accumulatedCost = excessArmySuppliesCost, maxCandidateCost do
            local score = bestScoreForCountAndCost[requiredRemovalCount][accumulatedCost]

            if score > chosenRemovalScore or (score == chosenRemovalScore and (chosenRemovalCost == nil or accumulatedCost > chosenRemovalCost)) then
                chosenRemovalScore = score
                chosenRemovalCost = accumulatedCost
                chosenRemovalCount = requiredRemovalCount
            end
        end

        -- If no feasible cost covers the deficit, pick the best available exact-count solution.
        if chosenRemovalScore == MINIMUM_SCORE then
            for accumulatedCost = 0, maxCandidateCost do
                local score = bestScoreForCountAndCost[requiredRemovalCount][accumulatedCost]

                if score > chosenRemovalScore or (score == chosenRemovalScore and (chosenRemovalCost == nil or accumulatedCost > chosenRemovalCost)) then
                    chosenRemovalScore = score
                    chosenRemovalCost = accumulatedCost
                    chosenRemovalCount = requiredRemovalCount
                end
            end
        end
    else
        -- We can remove any number of units; choose the smallest count that covers the deficit.
        for removedUnitCount = 1, maxRemovableUnits do
            local bestScoreForThisCount = MINIMUM_SCORE
            local bestCostForThisCount = nil

            for accumulatedCost = excessArmySuppliesCost, maxCandidateCost do
                local score = bestScoreForCountAndCost[removedUnitCount][accumulatedCost]
                if score > bestScoreForThisCount or (score == bestScoreForThisCount and (bestCostForThisCount == nil or accumulatedCost < bestCostForThisCount)) then
                    bestScoreForThisCount = score
                    bestCostForThisCount = accumulatedCost
                end
            end

            if bestScoreForThisCount > MINIMUM_SCORE then
                if not chosenRemovalCount or removedUnitCount < chosenRemovalCount or (removedUnitCount == chosenRemovalCount and bestScoreForThisCount > chosenRemovalScore) then
                    chosenRemovalCount = removedUnitCount
                    chosenRemovalCost = bestCostForThisCount
                    chosenRemovalScore = bestScoreForThisCount
                end
            end

            if chosenRemovalCount and chosenRemovalCount < removedUnitCount then
                break
            end
        end
    end

    if not chosenRemovalCount or not chosenRemovalCost then
        return
    end

    local selectedUnits, usedUnitIndexes = reconstructSolution(chosenRemovalCount, chosenRemovalCost)
    local selectedTotalCost = 0

    for _, entry in ipairs(selectedUnits) do
        selectedTotalCost = selectedTotalCost + entry.cost
    end

    -- Fallback: if exact-count solution doesn't cover the deficit, add extra units by priority.
    if requiredRemovalsForSize > 0 and selectedTotalCost < excessArmySuppliesCost then
        local remainingCandidates = {}

        for candidateIndex, entry in ipairs(candidateUnitList) do
            if not usedUnitIndexes[candidateIndex] then
                table.insert(remainingCandidates, entry)
            end
        end

        table.sort(remainingCandidates, function(a, b)
            if a.excessScore ~= b.excessScore then
                return a.excessScore > b.excessScore
            end

            return a.cost > b.cost
        end)

        for _, entry in ipairs(remainingCandidates) do
            if selectedTotalCost >= excessArmySuppliesCost then
                break
            end

            table.insert(selectedUnits, entry)
            selectedTotalCost = selectedTotalCost + entry.cost
        end
    end

    -- Apply the final solution to unitsToDiscard and update the cost object.
    for _, entry in ipairs(selectedUnits) do
        table.insert(unitsToDiscard, entry.unit)
        armySuppliesCost:removeUnit(entry.unit.unitKey)

        if unitCategoryExcessCounts[entry.unit.unitCategory] then
            unitCategoryExcessCounts[entry.unit.unitCategory] = unitCategoryExcessCounts[entry.unit.unitCategory] - 1
        end
    end

    TotoWarCbac.loggers.aiManager:logDebug(
        "adjustAiArmyCompositionAndUnits(%s from %s): COMPLETED => Total army supplies cost: %s | Available army supplies: %s | Army size: %s",
        function() return TotoWar.utils:getCharacterCaption(lord) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return armySuppliesCost.totalCost end,
        function() return armySuppliesCost.availableSupplies end,
        function() return #armySuppliesCost.unitArmySuppliesCosts end)
end

---Gets the target army size for a lord.
---
---If it is not set yet, it is randomly generated and stored in the game state.
---@param lordCqi integer Command queue index of the lord.
---@return integer
function TotoWarCbacAiManager:getLordTargetArmySize(lordCqi)
    local targetArmySize = cm:get_saved_value(_storageKeyTargetArmySizePrefix .. lordCqi)

    if targetArmySize == nil then
        targetArmySize = math.random(12, 20)
        cm:set_saved_value(_storageKeyTargetArmySizePrefix .. lordCqi, targetArmySize)
    end

    return targetArmySize
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
            0.1)
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
