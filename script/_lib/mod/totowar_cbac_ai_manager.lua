---Manager in charge of managing the army supplies for the AI armies.
---@class TotoWar_Cbac_AiManager
TotoWar_Cbac_AiManager = {
    ---List of command queue interfaces of the lords for which we need to check and adjust the composition in order to comply with army supply restrictions.
    ---@type integer[]
    armyAdjustmentQueue = {},

    ---List of command queue interfaces of the lords for which we need to check whether disbanded units should be reinstated.
    ---@type TotoWar__Dictionary<integer, TotoWar_Cbac_UnitArmySuppliesCost[]>
    disbandQueue = TotoWar__Dictionary.new()
}
TotoWar_Cbac_AiManager.__index = TotoWar_Cbac_AiManager

---Initializes a new instance.
---@return TotoWar_Cbac_AiManager
function TotoWar_Cbac_AiManager.new()
    TotoWar_Cbac.loggers.aiManager:logDebug("TotoWar_Cbac_AiManager.new(): STARTED")

    local instance = setmetatable({}, TotoWar_Cbac_AiManager)

    TotoWar_Cbac.loggers.aiManager:logDebug("TotoWar_Cbac_AiManager.new(): COMPLETED")

    return instance
end

---Adds an army to the adjustment queue.
---@param lordCqi integer Command queue index of the lord whose army will be adjusted.
function TotoWar_Cbac_AiManager:addArmyToAdjustmentQueue(lordCqi)
    TotoWar_Cbac.loggers.aiManager:logDebug(
        "addArmyToAdjustmentQueue(%s from %s): STARTED",
        function() return TotoWar__Gameplay:getCharacterCaption(cm:get_character_by_cqi(lordCqi)) end,
        function() return TotoWar__Gameplay:getFactionCaption(cm:get_character_by_cqi(lordCqi):faction():name()) end)

    if not TotoWar__Linq:any(self.armyAdjustmentQueue, function(cqi) return cqi == lordCqi end)
    then
        table.insert(self.armyAdjustmentQueue, lordCqi)

        -- Forced to use a callback here to defer the adjustment until all units are recruited.
        -- Disbanding units each time the unit recruitment unit was received could lead to crashes so
        -- we switched to a defered global adjustment to fix that.
        cm:callback(
            function()
                self:adjustAiArmy(lordCqi)
                TotoWar__Linq:remove(self.armyAdjustmentQueue, function(cqi) return cqi == lordCqi end)
            end,
            0.001)
    end

    TotoWar_Cbac.loggers.aiManager:logDebug(
        "addArmyToAdjustmentQueue(%s from %s): COMPLETED",
        function() return TotoWar__Gameplay:getCharacterCaption(cm:get_character_by_cqi(lordCqi)) end,
        function() return TotoWar__Gameplay:getFactionCaption(cm:get_character_by_cqi(lordCqi):faction():name()) end)
end

---Adds an army to the disband queue to check whether the unit should be reinstated if disbanded after the army has already been adjusted.
---@param disbandedUnit UNIT_SCRIPT_INTERFACE Disbanded unit.
function TotoWar_Cbac_AiManager:addUnitToDisbandQueue(disbandedUnit)
    local lordCqi = disbandedUnit:military_force():general_character():cqi()

    TotoWar_Cbac.loggers.aiManager:logDebug(
        "addUnitToDisbandQueue(%s from %s, %s): STARTED",
        function() return TotoWar__Gameplay:getCharacterCaption(disbandedUnit:military_force():general_character()) end,
        function() return TotoWar__Gameplay:getFactionCaption(disbandedUnit:military_force():faction():name()) end,
        function() return TotoWar__Gameplay:getUnitCaption(disbandedUnit:unit_key()) end)

    ---@type integer | nil
    local lastAdjustmentTurn = TotoWar__Gameplay:getSavedValue(
        TotoWar_Cbac_Constant.modName,
        string.format(TotoWar_Cbac_Constant.storageKeyFormatArmyLastAdjustmentTurn, lordCqi))

    if lastAdjustmentTurn ~= cm:turn_number() then
        TotoWar_Cbac.loggers.aiManager:logDebug(
            "addUnitToDisbandQueue(%s from %s, %s): DISBAND CONFIRMED => Current turn: %s | Last adjustment turn: %s",
            function() return TotoWar__Gameplay:getCharacterCaption(disbandedUnit:military_force():general_character()) end,
            function() return TotoWar__Gameplay:getFactionCaption(disbandedUnit:military_force():faction():name()) end,
            function() return TotoWar__Gameplay:getUnitCaption(disbandedUnit:unit_key()) end,
            function() return cm:turn_number() end,
            function() return lastAdjustmentTurn end)

        return
    end

    local unitArmySuppliesCost = TotoWar_Cbac_UnitArmySuppliesCost.newUnit(disbandedUnit:unit_key())

    if self.disbandQueue:exists(lordCqi) then
        local units = self.disbandQueue:get(lordCqi)
        table.insert(units, unitArmySuppliesCost)
        self.disbandQueue:set(lordCqi, units)
    else
        self.disbandQueue:set(lordCqi, { unitArmySuppliesCost })

        -- Callback to wait for other disband events to be executed before checking whether we should reinstate the unit.
        -- Not sure it is required like for the adjustment queue but added it to be consistent.
        cm:callback(
            function()
                self:cancelDisbandIfAlreadyAdjusted(lordCqi)
                self.disbandQueue:remove(lordCqi)
            end,
            0.001)
    end

    TotoWar_Cbac.loggers.aiManager:logDebug(
        "addUnitToDisbandQueue(%s from %s, %s): COMPLETED",
        function() return TotoWar__Gameplay:getCharacterCaption(disbandedUnit:military_force():general_character()) end,
        function() return TotoWar__Gameplay:getFactionCaption(disbandedUnit:military_force():faction():name()) end,
        function() return TotoWar__Gameplay:getUnitCaption(disbandedUnit:unit_key()) end)
end

---Adds listeners for events.
function TotoWar_Cbac_AiManager:addListeners()
    TotoWar_Cbac.loggers.aiManager:logDebug("addListeners(): STARTED")

    TotoWar__Gameplay:addListener(
        "TotoWar_Cbac_AiManager",
        TotoWar__Enum_GameEvent.characterTurnEnd,
        ---@param context CharacterTurnEnd
        function(context)
            return
                TotoWar_Cbac.options.aiArmySuppliesEnabled
                and TotoWar__Gameplay:isLordCharacter(context:character())
                and not cm:is_local_players_turn()
        end,
        ---@param context CharacterTurnEnd
        function(context)
            self:onAiCharacterTurnEnd(context:character())
        end)

    TotoWar__Gameplay:addListener(
        "TotoWar_Cbac_AiManager",
        TotoWar__Enum_GameEvent.militaryForceCreated,
        function()
            return
                TotoWar_Cbac.options.aiArmySuppliesEnabled
                and not cm:is_local_players_turn()
        end,
        ---@param context TotoWar__GameEventContext_MilitaryForceCreated
        function(context)
            self:onAiArmyCreated(context:military_force_created())
        end)

    TotoWar__Gameplay:addListener(
        "TotoWar_Cbac_AiManager",
        TotoWar__Enum_GameEvent.unitConverted,
        function()
            return
                TotoWar_Cbac.options.aiArmySuppliesEnabled
                and not cm:is_local_players_turn()
        end,
        ---@param context TotoWar__GameEventContext_UnitConverted
        function(context)
            self:onAiUnitConverted(context:unit(), context:converted_unit())
        end)

    TotoWar__Gameplay:addListener(
        "TotoWar_Cbac_AiManager",
        TotoWar__Enum_GameEvent.unitDisbanded,
        function()
            return
                TotoWar_Cbac.options.aiArmySuppliesEnabled
                and not cm:is_local_players_turn()
        end,
        ---@param context TotoWar__GameEventContext_UnitDisbanded
        function(context)
            self:onAiUnitDisbanded(context:unit())
        end)

    TotoWar__Gameplay:addListener(
        "TotoWar_Cbac_AiManager",
        TotoWar__Enum_GameEvent.unitTrained,
        ---@param context TotoWar__GameEventContext_UnitTrained
        function(context)
            return
                TotoWar_Cbac.options.aiArmySuppliesEnabled
                and not cm:is_local_players_turn()
                and context:unit():military_force()
                and TotoWar__Gameplay:canRecruitUnits(context:unit():military_force())
        end,
        ---@param context TotoWar__GameEventContext_UnitTrained
        function(context)
            self:onAiUnitRecruited(context:unit())
        end)

    TotoWar__Gameplay:addListener(
        "TotoWar_Cbac_AiManager",
        TotoWar__Enum_GameEvent.unitUpgraded,
        function()
            return
                TotoWar_Cbac.options.aiArmySuppliesEnabled
                and not cm:is_local_players_turn()
        end,
        ---@param context TotoWar__GameEventContext_UnitUpgraded
        function(context)
            self:onAiUnitUpgraded(context:unit())
        end)

    TotoWar_Cbac.loggers.aiManager:logDebug("addListeners(): COMPLETED")
end

---Adjusts an AI army by removing excess heroes and units when its cost exceeds army supplies.
---@param lordCqi integer Command queue index of the lord whose army will be adjusted.
function TotoWar_Cbac_AiManager:adjustAiArmy(lordCqi)
    local lord = cm:get_character_by_cqi(lordCqi)

    if not lord then
        -- This can happen sometimes for some reason
        TotoWar_Cbac.loggers.aiManager:logError("Lord with CQI \"%s\" not found", lordCqi)

        return
    end

    local army = lord:military_force()
    local armySuppliesCost = TotoWar_Cbac_ArmySuppliesCost.newFromArmy(true, army)

    if armySuppliesCost.availableSupplies >= 0 then
        return
    end

    TotoWar_Cbac.loggers.aiManager:logDebug(
        "adjustAiArmy(%s from %s): STARTED => Total army supplies cost: %s | Available army supplies: %s",
        function() return TotoWar__Gameplay:getCharacterCaption(lord) end,
        function() return TotoWar__Gameplay:getFactionCaption(army:faction():name()) end,
        function() return armySuppliesCost.totalCost end,
        function() return armySuppliesCost.availableSupplies end)

    -- Sorting units from the cheapest to the priciest
    table.sort(
        armySuppliesCost.unitArmySuppliesCosts,
        function(a, b)
            return a.armySuppliesCost < b.armySuppliesCost
        end)

    -- Getting the target army composition and the unit categories that have excess units
    local targetArmyComposition = self:getTargetArmyComposition(army)
    local targetArmySize = TotoWar__Linq:sum(targetArmyComposition:getValues(), function(v) return v end)
    local unitCategoryExcessCounts = self:getUnitCategoryExcessCounts(armySuppliesCost, targetArmyComposition)

    if unitCategoryExcessCounts:exists(TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.hero) then
        -- Removing excess of heroes
        self:adjustAiArmyHeroes(
            army,
            armySuppliesCost,
            unitCategoryExcessCounts:get(TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.hero))
    end

    ---@type TotoWar_Cbac_UnitArmySuppliesCost[]
    local unitsToDiscard = {}

    -- Adjust composition and units simultaneously
    self:adjustAiArmyCompositionAndUnits(army, armySuppliesCost, targetArmySize, unitCategoryExcessCounts, unitsToDiscard)

    -- Removing units flagged as discardable to stay within the army supplies limit
    for index, unitToDiscard in ipairs(unitsToDiscard) do
        self:removeUnitFromAiArmy(army, unitToDiscard.unitKey, unitToDiscard.unitCqi)
    end

    TotoWar_Cbac.loggers.aiManager:logDebug(
        "adjustAiArmy(%s from %s): COMPLETED => Total army supplies cost: %s | Available army supplies: %s",
        function() return TotoWar__Gameplay:getCharacterCaption(lord) end,
        function() return TotoWar__Gameplay:getFactionCaption(army:faction():name()) end,
        function() return armySuppliesCost.totalCost end,
        function() return armySuppliesCost.availableSupplies end)
end

---Adjusts the units in an army to stay within maximum number of units allowed in each unit category and within army supplies cost and target army size.
---
---Uses a dynamic programming knapsack algorithm to find the best subset of removable units that covers the cost deficit while respecting the ideal size reduction when possible.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@param armySuppliesCost TotoWar_Cbac_ArmySuppliesCost Army supplies cost of the army. Updated if units are flagged as to removed.
---@param targetArmySize integer Target army size.
---@param unitCategoryExcessCounts TotoWar__Dictionary<string, integer> Excess count by unit category.
---@param unitsToDiscard TotoWar_Cbac_UnitArmySuppliesCost[] List in which units to discard are stored. Updated if units are flagged as to be removed.
function TotoWar_Cbac_AiManager:adjustAiArmyCompositionAndUnits(
    army,
    armySuppliesCost,
    targetArmySize,
    unitCategoryExcessCounts,
    unitsToDiscard
)
    if armySuppliesCost.availableSupplies >= 0 then
        return
    end

    local lord = army:general_character()

    TotoWar_Cbac.loggers.aiManager:logDebug(
        "adjustAiArmyCompositionAndUnits(%s from %s): STARTED => Total army supplies cost: %s | Available army supplies: %s",
        function() return TotoWar__Gameplay:getCharacterCaption(lord) end,
        function() return TotoWar__Gameplay:getFactionCaption(army:faction():name()) end,
        function() return armySuppliesCost.totalCost end,
        function() return armySuppliesCost.availableSupplies end)

    local removableUnits = TotoWar__Linq:where(
        armySuppliesCost.unitArmySuppliesCosts,
        function(uasc)
            return
                uasc.unitCategory ~= TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.lord
                and uasc.unitCategory ~= TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.hero
        end)

    if #removableUnits == 0 then
        return
    end

    local currentArmySize = #armySuppliesCost.unitArmySuppliesCosts
    local requiredRemovalsForSize = math.max(0, currentArmySize - targetArmySize)
    local deficit = -armySuppliesCost.availableSupplies

    TotoWar_Cbac.loggers.aiManager:logDebug(
        "adjustAiArmyCompositionAndUnits(%s from %s): Army size: %s | Removable units: %s | Target army size: %s | Required removals for size: %s | Deficit: %s",
        function() return TotoWar__Gameplay:getCharacterCaption(lord) end,
        function() return TotoWar__Gameplay:getFactionCaption(army:faction():name()) end,
        function() return currentArmySize end,
        function() return #removableUnits end,
        function() return targetArmySize end,
        function() return requiredRemovalsForSize end,
        function() return deficit end)

    -------------------------------------------------------------------------
    -- Build max removable per category (how many are in excess)
    -------------------------------------------------------------------------
    ---@type table<string, integer>
    local maxPerCategory = {}

    ---@type string[]
    local categories = {}

    for _, category in ipairs(unitCategoryExcessCounts:getKeys()) do
        local count = unitCategoryExcessCounts:get(category)

        if count > 0 then
            maxPerCategory[category] = count
            table.insert(categories, category)
        end
    end

    TotoWar_Cbac.loggers.aiManager:logDebug(
        "adjustAiArmyCompositionAndUnits(%s from %s): Categories in excess: %s",
        function() return TotoWar__Gameplay:getCharacterCaption(lord) end,
        function() return TotoWar__Gameplay:getFactionCaption(army:faction():name()) end,
        function()
            if #categories == 0 then
                return "none"
            end

            return table.concat(
                TotoWar__Linq:select(
                    unitCategoryExcessCounts.entries,
                    function(c) return string.format("%s (%s)", c.key, c.value) end),
                " | ")
        end)

    -------------------------------------------------------------------------
    -- Split removable units into:
    -- - excessUnits (categories in excess)
    -- - otherUnits (everything else)
    -------------------------------------------------------------------------
    ---@type TotoWar_Cbac_UnitArmySuppliesCost[]
    local excessUnits = {}

    ---@type TotoWar_Cbac_UnitArmySuppliesCost[]
    local otherUnits = {}

    for _, u in ipairs(removableUnits) do
        if maxPerCategory[u.unitCategory] ~= nil then
            table.insert(excessUnits, u)
        else
            table.insert(otherUnits, u)
        end
    end

    -------------------------------------------------------------------------
    -- Determine maxRemovals for the main DP (only using excessUnits)
    -------------------------------------------------------------------------
    local maxRemovals = #excessUnits

    if maxRemovals <= 0 then
        maxRemovals = 0
    end

    -------------------------------------------------------------------------
    -- Bound DP cost space:
    -------------------------------------------------------------------------
    local biggestCosts = {}

    for _, u in ipairs(excessUnits) do
        table.insert(biggestCosts, u.armySuppliesCost)
    end

    table.sort(biggestCosts, function(a, b) return a > b end)

    local margin = 0
    for i = 1, math.min(maxRemovals, #biggestCosts) do
        margin = margin + biggestCosts[i]
    end

    local maxCost = deficit + margin

    -------------------------------------------------------------------------
    -- MAIN DP over excessUnits only
    -- DP[count][stateKey][removedCost] = pickedUnits
    -------------------------------------------------------------------------
    ---@type table<integer, table<string, table<integer, TotoWar_Cbac_UnitArmySuppliesCost[]>>>
    local DP = {}
    DP[0] = {}

    local startState = TotoWar_Cbac_AiManagerAdjustmentState.new(categories, maxPerCategory)
    local startKey = startState:getKey()

    DP[0][startKey] = {}
    DP[0][startKey][0] = {}

    table.sort(excessUnits, function(a, b)
        return a.armySuppliesCost < b.armySuppliesCost
    end)

    for _, unit in ipairs(excessUnits) do
        for removedCount = maxRemovals - 1, 0, -1 do
            if DP[removedCount] then
                DP[removedCount + 1] = DP[removedCount + 1] or {}

                for stateKey, costTable in pairs(DP[removedCount]) do
                    local baseState = TotoWar_Cbac_AiManagerAdjustmentState.newFromKey(stateKey, categories,
                        maxPerCategory)

                    ---@diagnostic disable-next-line: param-type-mismatch
                    if baseState:canAdd(unit.unitCategory) then
                        for removedCost, picked in pairs(costTable) do
                            local newCost = removedCost + unit.armySuppliesCost

                            if newCost <= maxCost then
                                local newState = baseState:clone()
                                ---@diagnostic disable-next-line: param-type-mismatch
                                newState:add(unit.unitCategory)

                                local newKey = newState:getKey()

                                DP[removedCount + 1][newKey] = DP[removedCount + 1][newKey] or {}

                                if DP[removedCount + 1][newKey][newCost] == nil then
                                    local newPicked = { unpack(picked) }
                                    table.insert(newPicked, unit)
                                    DP[removedCount + 1][newKey][newCost] = newPicked
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -------------------------------------------------------------------------
    -- Best selection among excess units:
    --
    -- FULL solutions (cost >= deficit):
    -- 1) closest to requiredRemovalsForSize (if requiredRemovalsForSize > 0)
    -- 2) fewer removals (tie breaker)
    -- 3) minimal cost above deficit
    -- 4) maximal satisfiedScore
    --
    -- PARTIAL solutions (cost < deficit):
    -- 1) maximal cost (closest below deficit)
    -- 2) closest to requiredRemovalsForSize (if requiredRemovalsForSize > 0)
    -- 3) fewer removals
    -- 4) maximal satisfiedScore
    -------------------------------------------------------------------------
    local idealRemovalCount = nil
    if requiredRemovalsForSize > 0 then
        idealRemovalCount = requiredRemovalsForSize
    end

    local bestPicked = nil
    local bestCost = nil
    ---@type integer
    local bestRemovalCount = nil
    local bestSatisfiedScore = nil

    local partialPicked = nil
    local partialCost = nil
    ---@type integer
    local partialRemovalCount = nil
    local partialSatisfiedScore = nil

    ---@param k integer
    ---@return integer
    local function getDistanceToIdeal(k)
        if idealRemovalCount == nil then
            return 0
        end

        return math.abs(k - idealRemovalCount)
    end

    ---@param k integer
    local function considerSolutions(k)
        if not DP[k] then
            return
        end

        for stateKey, costTable in pairs(DP[k]) do
            local state = TotoWar_Cbac_AiManagerAdjustmentState.newFromKey(stateKey, categories, maxPerCategory)
            local satisfiedScore = state:getSatisfiedScore()

            for cost, picked in pairs(costTable) do
                if cost >= deficit then
                    if bestPicked == nil then
                        bestPicked = picked
                        bestCost = cost
                        bestRemovalCount = k
                        bestSatisfiedScore = satisfiedScore
                    else
                        local bestDist = getDistanceToIdeal(bestRemovalCount)
                        local newDist = getDistanceToIdeal(k)

                        local bestExcess = bestCost - deficit
                        local newExcess = cost - deficit

                        if newDist < bestDist
                            or (newDist == bestDist and k < bestRemovalCount)
                            or (newDist == bestDist and k == bestRemovalCount and newExcess < bestExcess)
                            or (newDist == bestDist and k == bestRemovalCount and newExcess == bestExcess and satisfiedScore > bestSatisfiedScore)
                        then
                            bestPicked = picked
                            bestCost = cost
                            bestRemovalCount = k
                            bestSatisfiedScore = satisfiedScore
                        end
                    end
                else
                    if partialPicked == nil then
                        partialPicked = picked
                        partialCost = cost
                        partialRemovalCount = k
                        partialSatisfiedScore = satisfiedScore
                    else
                        local partialDist = getDistanceToIdeal(partialRemovalCount)
                        local newDist = getDistanceToIdeal(k)

                        if cost > partialCost
                            or (cost == partialCost and newDist < partialDist)
                            or (cost == partialCost and newDist == partialDist and k < partialRemovalCount)
                            or (cost == partialCost and newDist == partialDist and k == partialRemovalCount and satisfiedScore > partialSatisfiedScore)
                        then
                            partialPicked = picked
                            partialCost = cost
                            partialRemovalCount = k
                            partialSatisfiedScore = satisfiedScore
                        end
                    end
                end
            end
        end
    end

    for k = 1, maxRemovals do
        considerSolutions(k)
    end

    if not bestPicked then
        bestPicked = partialPicked
        bestCost = partialCost
        bestRemovalCount = partialRemovalCount
    end

    if not bestPicked then
        bestPicked = {}
        bestCost = 0
        bestRemovalCount = 0
    end

    for _, unitArmySuppliesCost in ipairs(bestPicked) do
        TotoWar_Cbac.loggers.aiManager:logDebug(
            "adjustAiArmyCompositionAndUnits(%s from %s): UNIT TO DISCARD (CATEGORY EXCESS) => %s | Category: %s | Cost: %s",
            function() return TotoWar__Gameplay:getCharacterCaption(lord) end,
            function() return TotoWar__Gameplay:getFactionCaption(army:faction():name()) end,
            function() return TotoWar__Gameplay:getUnitCaption(unitArmySuppliesCost.unitKey) end,
            function() return unitArmySuppliesCost.unitCategory end,
            function() return unitArmySuppliesCost.armySuppliesCost end)
    end

    -------------------------------------------------------------------------
    -- COMPLETE WITH otherUnits if deficit not covered
    -------------------------------------------------------------------------
    local pickedSet = {}
    for _, u in ipairs(bestPicked) do
        pickedSet[u.unitCqi] = true
    end

    ---@type TotoWar_Cbac_UnitArmySuppliesCost[]
    local remaining = {}

    for _, u in ipairs(otherUnits) do
        if not pickedSet[u.unitCqi] then
            table.insert(remaining, u)
        end
    end

    local remainingDeficit = deficit - bestCost

    if remainingDeficit > 0 and #remaining > 0 then
        local sumAll = 0
        for _, u in ipairs(remaining) do
            sumAll = sumAll + u.armySuppliesCost
        end

        ---@type table<integer, { count: integer, picked: TotoWar_Cbac_UnitArmySuppliesCost[] }>
        local DP2 = {}
        DP2[0] = { count = 0, picked = {} }

        for _, unit in ipairs(remaining) do
            for cost = sumAll - unit.armySuppliesCost, 0, -1 do
                local entry = DP2[cost]
                if entry then
                    local newCost = cost + unit.armySuppliesCost
                    local newCount = entry.count + 1

                    local existing = DP2[newCost]

                    if existing == nil or newCount < existing.count then
                        local newPicked = { unpack(entry.picked) }
                        table.insert(newPicked, unit)

                        DP2[newCost] = {
                            count = newCount,
                            picked = newPicked
                        }
                    end
                end
            end
        end

        local bestExtraPicked = nil
        local bestExtraCost = nil
        local bestExtraCount = nil

        local targetExtraCount = nil
        if idealRemovalCount ~= nil then
            targetExtraCount = math.max(0, idealRemovalCount - bestRemovalCount)
        end

        for cost, entry in pairs(DP2) do
            if cost >= remainingDeficit then
                if bestExtraPicked == nil then
                    bestExtraPicked = entry.picked
                    bestExtraCost = cost
                    bestExtraCount = entry.count
                else
                    if targetExtraCount ~= nil then
                        local distA = math.abs(entry.count - targetExtraCount)
                        local distB = math.abs(bestExtraCount - targetExtraCount)

                        if distA < distB
                            or (distA == distB and entry.count < bestExtraCount)
                            or (distA == distB and entry.count == bestExtraCount and cost < bestExtraCost)
                        then
                            bestExtraPicked = entry.picked
                            bestExtraCost = cost
                            bestExtraCount = entry.count
                        end
                    else
                        if entry.count < bestExtraCount
                            or (entry.count == bestExtraCount and cost < bestExtraCost)
                        then
                            bestExtraPicked = entry.picked
                            bestExtraCost = cost
                            bestExtraCount = entry.count
                        end
                    end
                end
            end
        end

        if bestExtraPicked then
            for _, u in ipairs(bestExtraPicked) do
                table.insert(bestPicked, u)
            end
            bestCost = bestCost + bestExtraCost
            bestRemovalCount = bestRemovalCount + bestExtraCount

            for _, unitArmySuppliesCost in ipairs(bestExtraPicked) do
                TotoWar_Cbac.loggers.aiManager:logDebug(
                    "adjustAiArmyCompositionAndUnits(%s from %s): UNIT TO DISCARD (EXTRA PICK) => %s | Category: %s | Cost: %s",
                    function() return TotoWar__Gameplay:getCharacterCaption(lord) end,
                    function() return TotoWar__Gameplay:getFactionCaption(army:faction():name()) end,
                    function() return TotoWar__Gameplay:getUnitCaption(unitArmySuppliesCost.unitKey) end,
                    ---@diagnostic disable-next-line: return-type-mismatch
                    function() return unitArmySuppliesCost.unitCategory end,
                    function() return unitArmySuppliesCost.armySuppliesCost end)
            end
        end
    end

    -------------------------------------------------------------------------
    -- Final safety: ensure deficit is covered
    -------------------------------------------------------------------------
    if bestCost < deficit then
        TotoWar_Cbac.loggers.aiManager:logWarning(
            "Army composition of %s from %s cannot be adjusted (Deficit: %s | Removed cost: %s)",
            TotoWar__Gameplay:getCharacterCaption(lord),
            TotoWar__Gameplay:getFactionCaption(army:faction():name()),
            deficit,
            bestCost)
    end

    -------------------------------------------------------------------------
    -- Apply removals
    -------------------------------------------------------------------------
    for _, unitArmySuppliesCost in ipairs(bestPicked) do
        table.insert(unitsToDiscard, unitArmySuppliesCost)
        armySuppliesCost:removeUnit(unitArmySuppliesCost.unitKey)
    end

    -- Storing the current turn as the last adjustment turn for that lord to be able to cancel the disbands that may happen just after the adjustment
    -- to avoid removing too many units from the army
    TotoWar__Gameplay:saveValue(
        TotoWar_Cbac_Constant.modName,
        string.format(TotoWar_Cbac_Constant.storageKeyFormatArmyLastAdjustmentTurn, lord:cqi()),
        cm:turn_number())

    TotoWar_Cbac.loggers.aiManager:logDebug(
        "adjustAiArmyCompositionAndUnits(%s from %s): COMPLETED => Total army supplies cost: %s | Available army supplies: %s | Army size: %s",
        function() return TotoWar__Gameplay:getCharacterCaption(lord) end,
        function() return TotoWar__Gameplay:getFactionCaption(army:faction():name()) end,
        function() return armySuppliesCost.totalCost end,
        function() return armySuppliesCost.availableSupplies end,
        function() return #armySuppliesCost.unitArmySuppliesCosts end)
end

---Adjusts the amount of heroes in an army if it exceeds the limit.
---
---Duplicate hero types are removed first.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@param armySuppliesCost TotoWar_Cbac_ArmySuppliesCost Army supplies cost of the army. Updated if heroes are removed.
---@param herosInExcess integer Amount of heroes that exceed the limit.
function TotoWar_Cbac_AiManager:adjustAiArmyHeroes(army, armySuppliesCost, herosInExcess)
    local heroes = TotoWar__Linq:where(
        armySuppliesCost.unitArmySuppliesCosts,
        function(uasc) return uasc.unitCategory == TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.hero end)

    if herosInExcess == 0 then
        return 0
    end

    local lord = army:general_character()

    TotoWar_Cbac.loggers.aiManager:logDebug(
        "adjustAiArmyHeroes(%s from %s, %s): STARTED => Total army supplies cost: %s | Available army supplies: %s | Army size: %s",
        function() return TotoWar__Gameplay:getCharacterCaption(lord) end,
        function() return TotoWar__Gameplay:getFactionCaption(army:faction():name()) end,
        function() return herosInExcess end,
        function() return armySuppliesCost.totalCost end,
        function() return armySuppliesCost.availableSupplies end,
        function() return #armySuppliesCost.unitArmySuppliesCosts end)

    while herosInExcess > 0 do
        -- Finding the group of heroes with the most heroes (or the last hero group when they all have the same amount of heroes)
        ---@type TotoWar__KeyValue<string, TotoWar_Cbac_UnitArmySuppliesCost[]>
        local heroUnitGroupWithMostHeroes = nil

        -- Grouping heroes by their base type to ignore their mount
        local heroUnitGroups = TotoWar__Linq:groupBy(heroes, function(a) return a.baseUnitKey end)

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
        table.remove(
            heroes,
            TotoWar__Linq:findIndex(heroes, function(h) return h.characterCqi == heroToRemove.characterCqi end))
        herosInExcess = herosInExcess - 1

        TotoWar_Cbac.loggers.aiManager:logDebug(
            "adjustAiArmyHeroes(%s from %s, %s): REMOVED => %s (%s)",
            function() return TotoWar__Gameplay:getCharacterCaption(lord) end,
            function() return TotoWar__Gameplay:getFactionCaption(army:faction():name()) end,
            function() return herosInExcess end,
            function() return TotoWar__Gameplay:getCharacterCaption(cm:get_character_by_cqi(heroToRemove.characterCqi)) end,
            function() return TotoWar__Gameplay:getUnitCaption(heroToRemove.unitKey) end)
    end

    TotoWar_Cbac.loggers.aiManager:logDebug(
        "adjustAiArmyHeroes(%s from %s, %s): COMPLETED => Total army supplies cost: %s | Available army supplies: %s | Army size: %s",
        function() return TotoWar__Gameplay:getCharacterCaption(lord) end,
        function() return TotoWar__Gameplay:getFactionCaption(army:faction():name()) end,
        function() return herosInExcess end,
        function() return armySuppliesCost.totalCost end,
        function() return armySuppliesCost.availableSupplies end,
        function() return #armySuppliesCost.unitArmySuppliesCosts end)
end

---Cancels the disband of a unit if the army it was in was already adjusted in order to comply with army supplies restrictions.
---@param lordCqi integer Command queue index of the lord whose army may have been adjusted.
function TotoWar_Cbac_AiManager:cancelDisbandIfAlreadyAdjusted(lordCqi)
    local lord = cm:get_character_by_cqi(lordCqi)

    TotoWar_Cbac.loggers.aiManager:logDebug(
        "cancelDisbandIfAlreadyAdjusted(%s from %s): STARTED",
        function() return TotoWar__Gameplay:getCharacterCaption(lord) end,
        function() return TotoWar__Gameplay:getFactionCaption(lord:military_force():faction():name()) end)

    local armySuppliesCost = TotoWar_Cbac_ArmySuppliesCost.newFromArmy(true, lord:military_force())
    local disbandedUnits = self.disbandQueue:get(lordCqi)

    for index, disbandedUnit in ipairs(disbandedUnits) do
        if armySuppliesCost.availableSupplies >= disbandedUnit.armySuppliesCost then
            cm:grant_unit_to_character(
                cm:char_lookup_str(lord:cqi()),
                disbandedUnit.unitKey)
            armySuppliesCost:addUnit(disbandedUnit.unitKey)

            TotoWar_Cbac.loggers.aiManager:logDebug(
                "cancelDisbandIfAlreadyAdjusted(%s from %s): DISBAND CANCELLED => %s | Unit cost: %s | Available supplies: %s",
                function() return TotoWar__Gameplay:getCharacterCaption(lord) end,
                function() return TotoWar__Gameplay:getFactionCaption(lord:military_force():faction():name()) end,
                function() return TotoWar__Gameplay:getUnitCaption(disbandedUnit.unitKey) end,
                function() return disbandedUnit.armySuppliesCost end,
                function() return armySuppliesCost.availableSupplies end)
        else
            -- In theory, we should never be in this case because the army adjustment should have removed enough units to prevent it
            TotoWar_Cbac.loggers.aiManager:logDebug(
                "cancelDisbandIfAlreadyAdjusted(%s from %s): DISBAND CONFIRMED => Unit: %s | Unit cost: %s | Available supplies : %s",
                function() return TotoWar__Gameplay:getCharacterCaption(lord) end,
                function() return TotoWar__Gameplay:getFactionCaption(lord:military_force():faction():name()) end,
                function() return TotoWar__Gameplay:getUnitCaption(disbandedUnit.unitKey) end,
                function() return disbandedUnit.armySuppliesCost end,
                function() return armySuppliesCost.availableSupplies end)
        end
    end

    TotoWar_Cbac.loggers.aiManager:logDebug(
        "cancelDisbandIfAlreadyAdjusted(%s from %s): COMPLETED",
        function() return TotoWar__Gameplay:getCharacterCaption(lord) end,
        function() return TotoWar__Gameplay:getFactionCaption(lord:military_force():faction():name()) end)
end

---Gets the maximum percentage a unit category can represent in a target army composition.
---@param faction FACTION_SCRIPT_INTERFACE Faction.
---@return TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategory, integer>
function TotoWar_Cbac_AiManager:getTargetArmyCompositionUnitCategoryMaximumPercentages(faction)
    TotoWar_Cbac.loggers.aiManager:logDebug(
        "getTargetArmyCompositionUnitCategoryMaximumPercentage(%s of %s): STARTED",
        function() return TotoWar__Gameplay:getFactionCaption(faction:name()) end,
        function() return TotoWar__Gameplay:getCultureCaption(faction:culture()) end)

    ---@type TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategory, integer>
    local result = TotoWar__Dictionary.new()

    ---@type TotoWar_Cbac_Enum_ArmyCompositionUnitCategory[]
    local overrides = {}

    local defaultTargetComposition = TotoWar_Cbac_ArmyCompositionTarget:get("default")
    local defaultTotal = 0
    local realTotal = 0

    for index, unitCategory in ipairs(defaultTargetComposition:getKeys()) do
        local defaultPercentage = TotoWar_Cbac_ArmyCompositionTarget:get("default"):get(unitCategory)

        local realPercentage = defaultPercentage

        if TotoWar_Cbac_ArmyCompositionTarget:exists(faction:name()) then
            local factionOverride = TotoWar_Cbac_ArmyCompositionTarget:get(faction:name())

            if factionOverride:exists(unitCategory) then
                realPercentage = factionOverride:get(unitCategory)
                table.insert(overrides, unitCategory)
            end
        elseif TotoWar_Cbac_ArmyCompositionTarget:exists(faction:culture()) then
            local cultureOverride = TotoWar_Cbac_ArmyCompositionTarget:get(faction:culture())

            if cultureOverride:exists(unitCategory) then
                realPercentage = cultureOverride:get(unitCategory)
                table.insert(overrides, unitCategory)
            end
        end

        defaultTotal = defaultTotal + defaultPercentage
        realTotal = realTotal + realPercentage
        result:set(unitCategory, realPercentage)
    end

    local difference = defaultTotal - realTotal

    if difference ~= 0 then
        -- Distributing the difference in percentages to other unit categories (up to a maximum of 75%)
        local unitCategoriesToUpdate = TotoWar__Linq:where(
            defaultTargetComposition:getKeys(),
            function(k)
                return k ~= TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.lord  -- We do not want to allow more lords
                    and k ~= TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.hero -- We do not want to allow more heroes
                    and not TotoWar__Linq:any(overrides, function(o) return o == k end)
            end)
        local percentageToAddPerUnitCategory =
            math.floor(difference / #unitCategoriesToUpdate / 5 + 0.5) * 5 -- Multiple of 5

        for index, unitCategory in ipairs(unitCategoriesToUpdate) do
            local updatedPercentage = result:get(unitCategory) + percentageToAddPerUnitCategory
            result:set(
                unitCategory,
                math.min(updatedPercentage, TotoWar_Cbac_Constant.maximumUnitCategoryTargetPercentage))
        end
    end

    TotoWar_Cbac.loggers.aiManager:logDebug(
        "getTargetArmyCompositionUnitCategoryMaximumPercentage(%s of %s): COMPLETED => %s",
        function() return TotoWar__Gameplay:getFactionCaption(faction:name()) end,
        function() return TotoWar__Gameplay:getCultureCaption(faction:culture()) end,
        function()
            return table.concat(
                TotoWar__Linq:select(
                    result.entries,
                    function(e) return string.format("%s: %s%%", e.key, e.value) end),
                " | ")
        end)

    return result
end

---Gets a target army composition by providing unit counts by category.
---
---If a target army composition has already been affected to an army, it is read from the game state.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@return TotoWar__Dictionary<string, integer>
function TotoWar_Cbac_AiManager:getTargetArmyComposition(army)
    local lord = army:general_character()

    TotoWar_Cbac.loggers.aiManager:logDebug(
        "getTargetArmyComposition(%s from %s): STARTED",
        function() return TotoWar__Gameplay:getCharacterCaption(lord) end,
        function() return TotoWar__Gameplay:getFactionCaption(army:faction():name()) end)

    ---@type TotoWar__Dictionary<string, integer>
    local categoryUnitCounts = TotoWar__Dictionary.new()

    local lordUnitAmount = TotoWar__Gameplay:getSavedValue(
        TotoWar_Cbac_Constant.modName,
        string.format(
            TotoWar_Cbac_Constant.storageKeyFormatArmyUnitCategoryAmount,
            lord:cqi(),
            TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.lord))

    ---@type integer
    local armySize

    if lordUnitAmount ~= nil then
        TotoWar_Cbac.loggers.aiManager:logDebug(
            "getTargetArmyComposition(%s from %s): READING EXISTING COMPOSITION",
            function() return TotoWar__Gameplay:getCharacterCaption(lord) end,
            function() return TotoWar__Gameplay:getFactionCaption(army:faction():name()) end)

        -- Reading existing values from the game state
        categoryUnitCounts:set(
            TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.hero,
            TotoWar__Gameplay:getSavedValue(
                TotoWar_Cbac_Constant.modName,
                string.format(
                    TotoWar_Cbac_Constant.storageKeyFormatArmyUnitCategoryAmount,
                    lord:cqi(),
                    TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.hero)))
        categoryUnitCounts:set(
            TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.warMachines,
            TotoWar__Gameplay:getSavedValue(
                TotoWar_Cbac_Constant.modName,
                string.format(
                    TotoWar_Cbac_Constant.storageKeyFormatArmyUnitCategoryAmount,
                    lord:cqi(),
                    TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.warMachines)))
        categoryUnitCounts:set(
            TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.cavalryAndMonsters,
            TotoWar__Gameplay:getSavedValue(
                TotoWar_Cbac_Constant.modName,
                string.format(
                    TotoWar_Cbac_Constant.storageKeyFormatArmyUnitCategoryAmount,
                    lord:cqi(),
                    TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.cavalryAndMonsters)))
        categoryUnitCounts:set(
            TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.lord,
            lordUnitAmount)
        categoryUnitCounts:set(
            TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.meleeInfantry,
            TotoWar__Gameplay:getSavedValue(
                TotoWar_Cbac_Constant.modName,
                string.format(
                    TotoWar_Cbac_Constant.storageKeyFormatArmyUnitCategoryAmount,
                    lord:cqi(),
                    TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.meleeInfantry)))
        categoryUnitCounts:set(
            TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.rangedInfantry,
            TotoWar__Gameplay:getSavedValue(
                TotoWar_Cbac_Constant.modName,
                string.format(
                    TotoWar_Cbac_Constant.storageKeyFormatArmyUnitCategoryAmount,
                    lord:cqi(),
                    TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.rangedInfantry)))

        armySize = TotoWar__Linq:sum(categoryUnitCounts:getValues(), function(v) return v end)
    else
        TotoWar_Cbac.loggers.aiManager:logDebug(
            "getTargetArmyComposition(%s from %s): GENERATING NEW COMPOSITION",
            function() return TotoWar__Gameplay:getCharacterCaption(lord) end,
            function() return TotoWar__Gameplay:getFactionCaption(army:faction():name()) end)

        -- Generating an army target composition
        local maximumPercentages = self:getTargetArmyCompositionUnitCategoryMaximumPercentages(army:faction())

        local cavalryAndMonstersMaximumPercentage = maximumPercentages:get(
            TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.cavalryAndMonsters)
        local heroMaximumPercentage = maximumPercentages:get(TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.hero)
        local meleeInfantryMaximumPercentage = maximumPercentages:get(
            TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.meleeInfantry)
        local rangedInfantryMaximumPercentage = maximumPercentages:get(
            TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.rangedInfantry)
        local warMachinesMaximumPercentage = maximumPercentages:get(
            TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.warMachines)

        armySize = math.random(TotoWar_Cbac_Constant.minimumTargetArmySize, TotoWar_Cbac_Constant.maximumTargetArmySize)

        lordUnitAmount = 1
        local nonLordUnitCount = armySize - lordUnitAmount

        local cavalryAndMonstersPercentage = math.random(
            cavalryAndMonstersMaximumPercentage * TotoWar_Cbac_Constant.minimumUnitCategoryPercentageRatio,
            cavalryAndMonstersMaximumPercentage)
        cavalryAndMonstersPercentage = math.floor(cavalryAndMonstersPercentage / 5 + 0.5) * 5 -- Multiple of 5

        local heroPercentage = math.random(
            heroMaximumPercentage * TotoWar_Cbac_Constant.minimumUnitCategoryPercentageRatio,
            heroMaximumPercentage)
        heroPercentage = math.floor(heroPercentage / 5 + 0.5) * 5 -- Multiple of 5

        local meleeInfantryPercentage = math.random(
            meleeInfantryMaximumPercentage * TotoWar_Cbac_Constant.minimumUnitCategoryPercentageRatio,
            meleeInfantryMaximumPercentage)
        meleeInfantryPercentage = math.floor(meleeInfantryPercentage / 5 + 0.5) * 5 -- Multiple of 5

        local rangedInfantryPercentage = math.random(
            rangedInfantryMaximumPercentage * TotoWar_Cbac_Constant.minimumUnitCategoryPercentageRatio,
            rangedInfantryMaximumPercentage)
        rangedInfantryPercentage = math.floor(rangedInfantryPercentage / 5 + 0.5) * 5 -- Multiple of 5

        local warMachinesPercentage = math.random(
            warMachinesMaximumPercentage * TotoWar_Cbac_Constant.minimumUnitCategoryPercentageRatio,
            warMachinesMaximumPercentage)
        warMachinesPercentage = math.floor(warMachinesPercentage / 5 + 0.5) * 5 -- Multiple of 5

        local percentagesTotal =
            cavalryAndMonstersPercentage
            + heroPercentage
            + meleeInfantryPercentage
            + rangedInfantryPercentage
            + warMachinesPercentage

        if percentagesTotal > 100 then
            -- Adjusting percentages with a ratio to be based on 100
            local ratio = 100 / percentagesTotal
            cavalryAndMonstersPercentage = math.floor(cavalryAndMonstersPercentage * ratio / 5 + 0.5) * 5
            heroPercentage = math.floor(heroPercentage * ratio / 5 + 0.5) * 5
            meleeInfantryPercentage = math.floor(meleeInfantryPercentage * ratio / 5 + 0.5) * 5
            rangedInfantryPercentage = math.floor(rangedInfantryPercentage * ratio / 5 + 0.5) * 5
            warMachinesPercentage = math.floor(warMachinesPercentage * ratio / 5 + 0.5) * 5

            percentagesTotal =
                cavalryAndMonstersPercentage
                + heroPercentage
                + meleeInfantryPercentage
                + rangedInfantryPercentage
                + warMachinesPercentage
        end

        -- Filling the remaining percentage with melee infantry
        meleeInfantryPercentage = meleeInfantryPercentage + 100 - percentagesTotal

        -- Making sure the melee percentage is the highest
        ---@type TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategory, integer>
        local percentages = TotoWar__Dictionary.new()
        percentages:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.cavalryAndMonsters, cavalryAndMonstersPercentage)
        percentages:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.hero, heroPercentage)
        percentages:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.meleeInfantry, meleeInfantryPercentage)
        percentages:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.rangedInfantry, rangedInfantryPercentage)
        percentages:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.warMachines, warMachinesPercentage)

        table.sort(
            percentages.entries,
            function(a, b) return a.value > b.value end)
        local highestPercentageEntry = percentages.entries[1]

        if highestPercentageEntry.key ~= TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.meleeInfantry then
            local highestPercentage = highestPercentageEntry.value
            local meleeInfantryPercentage = percentages:get(TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.meleeInfantry)

            percentages:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.meleeInfantry, highestPercentage)
            percentages:set(highestPercentageEntry.key, meleeInfantryPercentage)
        end

        cavalryAndMonstersPercentage = percentages:get(TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.cavalryAndMonsters)
        heroPercentage = percentages:get(TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.hero)
        meleeInfantryPercentage = percentages:get(TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.meleeInfantry)
        rangedInfantryPercentage = percentages:get(TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.rangedInfantry)
        warMachinesPercentage = percentages:get(TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.warMachines)

        TotoWar_Cbac.loggers.aiManager:logDebug(
            "getTargetArmyComposition(%s from %s): TARGET PERCENTAGES => %s",
            function() return TotoWar__Gameplay:getCharacterCaption(lord) end,
            function() return TotoWar__Gameplay:getFactionCaption(army:faction():name()) end,
            function()
                return string.format(
                    "cavalryAndMonsters: %s%% | hero: %s%% | meleeInfantry: %s%% | rangedInfantry: %s%% | warMachines: %s%%",
                    cavalryAndMonstersPercentage,
                    heroPercentage,
                    meleeInfantryPercentage,
                    rangedInfantryPercentage,
                    warMachinesPercentage)
            end)

        local cavalryAndMonstersCount = TotoWar__Number:roundToNearestInteger(
            nonLordUnitCount * cavalryAndMonstersPercentage / 100)
        local heroCount = TotoWar__Number:roundToNearestInteger(nonLordUnitCount * heroPercentage / 100)
        local meleeInfantryCount = TotoWar__Number:roundToNearestInteger(nonLordUnitCount * meleeInfantryPercentage / 100)
        local rangedInfantryCount = TotoWar__Number:roundToNearestInteger(
            nonLordUnitCount * rangedInfantryPercentage / 100)
        local warMachinesCount = TotoWar__Number:roundToNearestInteger(nonLordUnitCount * warMachinesPercentage / 100)

        -- Fix rounding errors
        local assignedUnits =
            warMachinesCount
            + cavalryAndMonstersCount
            + heroCount
            + meleeInfantryCount
            + rangedInfantryCount

        local delta = nonLordUnitCount - assignedUnits

        if delta ~= 0 then
            meleeInfantryCount = meleeInfantryCount + delta
        end

        categoryUnitCounts:set(
            TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.warMachines,
            warMachinesCount)
        TotoWar__Gameplay:saveValue(
            TotoWar_Cbac_Constant.modName,
            string.format(
                TotoWar_Cbac_Constant.storageKeyFormatArmyUnitCategoryAmount,
                lord:cqi(),
                TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.warMachines),
            warMachinesCount)

        categoryUnitCounts:set(
            TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.cavalryAndMonsters,
            cavalryAndMonstersCount)
        TotoWar__Gameplay:saveValue(
            TotoWar_Cbac_Constant.modName,
            string.format(
                TotoWar_Cbac_Constant.storageKeyFormatArmyUnitCategoryAmount,
                lord:cqi(),
                TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.cavalryAndMonsters),
            cavalryAndMonstersCount)

        categoryUnitCounts:set(
            TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.hero,
            heroCount)
        TotoWar__Gameplay:saveValue(
            TotoWar_Cbac_Constant.modName,
            string.format(
                TotoWar_Cbac_Constant.storageKeyFormatArmyUnitCategoryAmount,
                lord:cqi(),
                TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.hero),
            heroCount)

        categoryUnitCounts:set(
            TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.lord,
            lordUnitAmount)
        TotoWar__Gameplay:saveValue(
            TotoWar_Cbac_Constant.modName,
            string.format(
                TotoWar_Cbac_Constant.storageKeyFormatArmyUnitCategoryAmount,
                lord:cqi(),
                TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.lord),
            lordUnitAmount)

        categoryUnitCounts:set(
            TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.meleeInfantry,
            meleeInfantryCount)
        TotoWar__Gameplay:saveValue(
            TotoWar_Cbac_Constant.modName,
            string.format(
                TotoWar_Cbac_Constant.storageKeyFormatArmyUnitCategoryAmount,
                lord:cqi(),
                TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.meleeInfantry),
            meleeInfantryCount)

        categoryUnitCounts:set(
            TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.rangedInfantry,
            rangedInfantryCount)
        TotoWar__Gameplay:saveValue(
            TotoWar_Cbac_Constant.modName,
            string.format(
                TotoWar_Cbac_Constant.storageKeyFormatArmyUnitCategoryAmount,
                lord:cqi(),
                TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.rangedInfantry),
            rangedInfantryCount)
    end

    TotoWar_Cbac.loggers.aiManager:logDebug(
        "getTargetArmyComposition(%s from %s): COMPLETED => Target army size: %s | %s",
        function() return TotoWar__Gameplay:getCharacterCaption(lord) end,
        function() return TotoWar__Gameplay:getFactionCaption(army:faction():name()) end,
        function() return armySize end,
        function()
            local composition = ""

            for _, entry in ipairs(categoryUnitCounts.entries) do
                if composition:len() > 0 then
                    composition = composition .. " | "
                end

                composition = string.format("%s%s: %s", composition, entry.key, entry.value)
            end

            return composition
        end)

    return categoryUnitCounts
end

---Gets the number of units for each unit category composing army supplies costs that exceed the target unit counts.
---
---Lord and heroes are not taken into account.
---@param armySuppliesCost TotoWar_Cbac_ArmySuppliesCost Army supplies cost.
---@param targetCategoryCounts TotoWar__Dictionary<string, integer> Target unit count per category.
---@return TotoWar__Dictionary<string, integer>
function TotoWar_Cbac_AiManager:getUnitCategoryExcessCounts(armySuppliesCost, targetCategoryCounts)
    TotoWar_Cbac.loggers.aiManager:logDebug("getUnitCategoryExcessCounts(): STARTED")

    local totalUnitCount = 0

    ---@type TotoWar__Dictionary<string, integer>
    local categoryCounts = TotoWar__Dictionary.new()

    ---@type TotoWar__Dictionary<string, integer>
    local excessCategoryCounts = TotoWar__Dictionary.new()

    -- Count units per category
    for index, unitArmySuppliesCost in ipairs(armySuppliesCost.unitArmySuppliesCosts) do
        local current = 0

        if categoryCounts:exists(unitArmySuppliesCost.unitCategory) then
            current = categoryCounts:get(unitArmySuppliesCost.unitCategory)
        end

        ---@diagnostic disable-next-line: param-type-mismatch
        categoryCounts:set(unitArmySuppliesCost.unitCategory, current + 1)
        totalUnitCount = totalUnitCount + 1
    end

    if totalUnitCount > 0 then
        for _, entry in ipairs(categoryCounts.entries) do
            if entry.key ~= TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.meleeInfantry then -- Melee infantry cannot be in excess
                local excess = entry.value - targetCategoryCounts:get(entry.key)

                if excess > 0 then
                    excessCategoryCounts:set(entry.key, excess)
                end
            end
        end
    end

    TotoWar_Cbac.loggers.aiManager:logDebug(
        "getUnitCategoryExcessCounts(): COMPLETED => %s",
        function()
            local message = table.concat(
                TotoWar__Linq:select(
                    excessCategoryCounts.entries,
                    function(e) return string.format("%s: %s", e.key, e.value) end),
                " | ")

            if message == '' then
                message = 'No excess'
            end

            return message
        end)

    return excessCategoryCounts
end

---Reacts to an army being created by an AI faction.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
function TotoWar_Cbac_AiManager:onAiArmyCreated(army)
    TotoWar_Cbac.loggers.aiManager:logDebug(
        "onAiArmyCreated(%s from %s): STARTED",
        function() return TotoWar__Gameplay:getCharacterCaption(army:general_character()) end,
        function() return TotoWar__Gameplay:getFactionCaption(army:faction():name()) end)

    -- Adjusting the composition for armies spawned with units already included
    self:adjustAiArmy(army:general_character():cqi())

    TotoWar_Cbac.loggers.aiManager:logDebug(
        "onAiArmyCreated(%s from %s): COMPLETED",
        function() return TotoWar__Gameplay:getCharacterCaption(army:general_character()) end,
        function() return TotoWar__Gameplay:getFactionCaption(army:faction():name()) end)
end

---Reacts to the turn of a character ending.
---@param character CHARACTER_SCRIPT_INTERFACE Character.
function TotoWar_Cbac_AiManager:onAiCharacterTurnEnd(character)
    TotoWar_Cbac.loggers.aiManager:logDebug(
        "onAiCharacterTurnEnd(%s from %s): STARTED",
        function() return TotoWar__Gameplay:getCharacterCaption(character) end,
        function() return TotoWar__Gameplay:getFactionCaption(character:faction():name()) end)

    -- Relaunching the army adjustment to remove heros that may have been (re)added after the army adjustement triggered when units are recruited
    self:adjustAiArmy(character:cqi())

    TotoWar_Cbac.loggers.aiManager:logDebug(
        "onAiCharacterTurnEnd(%s from %s): COMPLETED",
        function() return TotoWar__Gameplay:getCharacterCaption(character) end,
        function() return TotoWar__Gameplay:getFactionCaption(character:faction():name()) end)
end

---Reacts to a unit being converted by an AI army.
---@param originalUnit UNIT_SCRIPT_INTERFACE Unit.
---@param newUnit UNIT_SCRIPT_INTERFACE Unit.
function TotoWar_Cbac_AiManager:onAiUnitConverted(originalUnit, newUnit)
    local lord = newUnit:military_force():general_character()

    TotoWar_Cbac.loggers.aiManager:logDebug(
        "onAiUnitConverted(%s from %s, %s, %s): STARTED",
        function() return TotoWar__Gameplay:getCharacterCaption(lord) end,
        function() return TotoWar__Gameplay:getFactionCaption(newUnit:military_force():faction():name()) end,
        function() return TotoWar__Gameplay:getUnitCaption(originalUnit:unit_key()) end,
        function() return TotoWar__Gameplay:getUnitCaption(newUnit:unit_key()) end)

    -- This is just to log how AI converts units and how it impacts the mod

    TotoWar_Cbac.loggers.aiManager:logDebug(
        "onAiUnitConverted(%s from %s, %s, %s): COMPLETED",
        function() return TotoWar__Gameplay:getCharacterCaption(lord) end,
        function() return TotoWar__Gameplay:getFactionCaption(newUnit:military_force():faction():name()) end,
        function() return TotoWar__Gameplay:getUnitCaption(originalUnit:unit_key()) end,
        function() return TotoWar__Gameplay:getUnitCaption(newUnit:unit_key()) end)
end

---Reacts to a unit being disbanded by an AI army.
---@param unit UNIT_SCRIPT_INTERFACE Unit.
function TotoWar_Cbac_AiManager:onAiUnitDisbanded(unit)
    TotoWar_Cbac.loggers.aiManager:logDebug(
        "onAiUnitDisbanded(%s from %s, %s): STARTED",
        function() return TotoWar__Gameplay:getCharacterCaption(unit:military_force():general_character()) end,
        function() return TotoWar__Gameplay:getFactionCaption(unit:military_force():faction():name()) end,
        function() return TotoWar__Gameplay:getUnitCaption(unit:unit_key()) end)

    self:addUnitToDisbandQueue(unit)

    TotoWar_Cbac.loggers.aiManager:logDebug(
        "onAiUnitDisbanded(%s from %s, %s): COMPLETED",
        function() return TotoWar__Gameplay:getCharacterCaption(unit:military_force():general_character()) end,
        function() return TotoWar__Gameplay:getFactionCaption(unit:military_force():faction():name()) end,
        function() return TotoWar__Gameplay:getUnitCaption(unit:unit_key()) end)
end

---Reacts to a unit being recruited by an AI army.
---@param unit UNIT_SCRIPT_INTERFACE Unit.
function TotoWar_Cbac_AiManager:onAiUnitRecruited(unit)
    local lord = unit:military_force():general_character()

    TotoWar_Cbac.loggers.aiManager:logDebug(
        "onAiUnitRecruited(%s from %s, %s): STARTED",
        function() return TotoWar__Gameplay:getCharacterCaption(lord) end,
        function() return TotoWar__Gameplay:getFactionCaption(unit:military_force():faction():name()) end,
        function() return TotoWar__Gameplay:getUnitCaption(unit:unit_key()) end)

    self:addArmyToAdjustmentQueue(lord:cqi())

    TotoWar_Cbac.loggers.aiManager:logDebug(
        "onAiUnitRecruited(%s from %s, %s): COMPLETED",
        function() return TotoWar__Gameplay:getCharacterCaption(lord) end,
        function() return TotoWar__Gameplay:getFactionCaption(unit:military_force():faction():name()) end,
        function() return TotoWar__Gameplay:getUnitCaption(unit:unit_key()) end)
end

---Reacts to a unit being upgraded by an AI army.
---@param unit UNIT_SCRIPT_INTERFACE Unit.
function TotoWar_Cbac_AiManager:onAiUnitUpgraded(unit)
    local lord = unit:military_force():general_character()

    TotoWar_Cbac.loggers.aiManager:logDebug(
        "onAiUnitUpgraded(%s from %s, %s): STARTED",
        function() return TotoWar__Gameplay:getCharacterCaption(lord) end,
        function() return TotoWar__Gameplay:getFactionCaption(unit:military_force():faction():name()) end,
        function() return TotoWar__Gameplay:getUnitCaption(unit:unit_key()) end)

    self:addArmyToAdjustmentQueue(lord:cqi())

    TotoWar_Cbac.loggers.aiManager:logDebug(
        "onAiUnitUpgraded(%s from %s, %s): COMPLETED",
        function() return TotoWar__Gameplay:getCharacterCaption(lord) end,
        function() return TotoWar__Gameplay:getFactionCaption(unit:military_force():faction():name()) end,
        function() return TotoWar__Gameplay:getUnitCaption(unit:unit_key()) end)
end

---Removes a unit from an AI army and reimburses the AI faction of the cost of the unit.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@param unitKey string Key of the unit to remove.
---@param unitCqi integer Command queue index of the unit to remove.
function TotoWar_Cbac_AiManager:removeUnitFromAiArmy(army, unitKey, unitCqi)
    TotoWar_Cbac.loggers.aiManager:logDebug(
        "removeUnitFromAiArmy(%s from %s, %s, %s): STARTED",
        function() return TotoWar__Gameplay:getCharacterCaption(army:general_character()) end,
        function() return TotoWar__Gameplay:getFactionCaption(army:faction():name()) end,
        function() return TotoWar__Gameplay:getUnitCaption(unitKey) end,
        function() return unitCqi end)

    local unitRealCost = cco("CcoCampaignUnit", unitCqi):Call("Cost")

    if unitRealCost ~= nil and unitRealCost > 0 then
        cm:treasury_mod(army:faction():name(), unitRealCost)

        TotoWar_Cbac.loggers.aiManager:logDebug(
            "removeUnitFromAiArmy(%s from %s, %s, %s): REIMBURSE => %s | New treasury: %s",
            function() return TotoWar__Gameplay:getCharacterCaption(army:general_character()) end,
            function() return TotoWar__Gameplay:getFactionCaption(army:faction():name()) end,
            function() return TotoWar__Gameplay:getUnitCaption(unitKey) end,
            function() return unitCqi end,
            function() return unitRealCost end,
            function() return army:faction():treasury() end)
    end

    cm:remove_unit_from_character(cm:char_lookup_str(army:general_character()), unitKey)

    TotoWar_Cbac.loggers.aiManager:logDebug(
        "removeUnitFromAiArmy(%s from %s, %s, %s): COMPLETED",
        function() return TotoWar__Gameplay:getCharacterCaption(army:general_character()) end,
        function() return TotoWar__Gameplay:getFactionCaption(army:faction():name()) end,
        function() return TotoWar__Gameplay:getUnitCaption(unitKey) end,
        function() return unitCqi end)
end
