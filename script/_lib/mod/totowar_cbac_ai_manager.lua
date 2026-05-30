---Manager in charge of managing the army supplies for the AI armies.
---@class TotoWarCbacAiManager
TotoWarCbacAiManager = {
    ---List of command queue interfaces of the lords for which we need to check and adjust the composition in order to comply with army supply restrictions.
    ---@type integer[]
    armyAdjustmentQueue = {},

    ---List of command queue interfaces of the lords for which we need to check whether disbanded units should be reinstated.
    ---@type TotoWarDictionary<integer, TotoWarCbacUnitArmySuppliesCost[]>
    disbandQueue = TotoWarDictionary.new()
}
TotoWarCbacAiManager.__index = TotoWarCbacAiManager

---Initializes a new instance.
---@return TotoWarCbacAiManager
function TotoWarCbacAiManager.new()
    TotoWarCbac.loggers.aiManager:logDebug("TotoWarCbacAiManager.new(): STARTED")

    local instance = setmetatable({}, TotoWarCbacAiManager)

    TotoWarCbac.loggers.aiManager:logDebug("TotoWarCbacAiManager.new(): COMPLETED")

    return instance
end

---Adds an army to the adjustment queue.
---@param lordCqi integer Command queue index of the lord whose army will be adjusted.
function TotoWarCbacAiManager:addArmyToAdjustmentQueue(lordCqi)
    TotoWarCbac.loggers.aiManager:logDebug(
        "addArmyToAdjustmentQueue(%s from %s): STARTED",
        function() return TotoWar.utils:getCharacterCaption(cm:get_character_by_cqi(lordCqi)) end,
        function() return TotoWar.utils:getFactionCaption(cm:get_character_by_cqi(lordCqi):faction():name()) end)

    if not TotoWarLinq:any(self.armyAdjustmentQueue, function(cqi) return cqi == lordCqi end)
    then
        table.insert(self.armyAdjustmentQueue, lordCqi)

        -- Forced to use a callback here to defer the adjustment until all units are recruited.
        -- Disbanding units each time the unit recruitment unit was received could lead to crashes so
        -- we switched to a defered global adjustment to fix that.
        cm:callback(
            function()
                self:adjustAiArmy(lordCqi)
                TotoWarLinq:remove(self.armyAdjustmentQueue, function(cqi) return cqi == lordCqi end)
            end,
            0.001)
    end

    TotoWarCbac.loggers.aiManager:logDebug(
        "addArmyToAdjustmentQueue(%s from %s): COMPLETED",
        function() return TotoWar.utils:getCharacterCaption(cm:get_character_by_cqi(lordCqi)) end,
        function() return TotoWar.utils:getFactionCaption(cm:get_character_by_cqi(lordCqi):faction():name()) end)
end

---Adds an army to the disband queue to check whether the unit should be reinstated if disbanded after the army has already been adjusted.
---@param disbandedUnit UNIT_SCRIPT_INTERFACE Disbanded unit.
function TotoWarCbacAiManager:addUnitToDisbandQueue(disbandedUnit)
    local lordCqi = disbandedUnit:military_force():general_character():cqi()

    TotoWarCbac.loggers.aiManager:logDebug(
        "addUnitToDisbandQueue(%s from %s, %s): STARTED",
        function() return TotoWar.utils:getCharacterCaption(disbandedUnit:military_force():general_character()) end,
        function() return TotoWar.utils:getFactionCaption(disbandedUnit:military_force():faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(disbandedUnit:unit_key()) end)

    ---@type integer | nil
    local lastAdjustmentTurn = TotoWar.utils:getSavedValue(
        TotoWar_Cbac_ModName,
        string.format(TotoWarCbac.constants.storageKeyFormatArmyLastAdjustmentTurn, lordCqi))

    if lastAdjustmentTurn ~= cm:turn_number() then
        TotoWarCbac.loggers.aiManager:logDebug(
            "addUnitToDisbandQueue(%s from %s, %s): DISBAND CONFIRMED => Current turn: %s | Last adjustment turn: %s",
            function() return TotoWar.utils:getCharacterCaption(disbandedUnit:military_force():general_character()) end,
            function() return TotoWar.utils:getFactionCaption(disbandedUnit:military_force():faction():name()) end,
            function() return TotoWar.utils:getUnitCaption(disbandedUnit:unit_key()) end,
            function() return cm:turn_number() end,
            function() return lastAdjustmentTurn end)

        return
    end

    local unitArmySuppliesCost = TotoWarCbacUnitArmySuppliesCost.newUnit(disbandedUnit:unit_key())

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

    TotoWarCbac.loggers.aiManager:logDebug(
        "addUnitToDisbandQueue(%s from %s, %s): COMPLETED",
        function() return TotoWar.utils:getCharacterCaption(disbandedUnit:military_force():general_character()) end,
        function() return TotoWar.utils:getFactionCaption(disbandedUnit:military_force():faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(disbandedUnit:unit_key()) end)
end

---Adds listeners for events.
function TotoWarCbacAiManager:addListeners()
    TotoWarCbac.loggers.aiManager:logDebug("addListeners(): STARTED")

    TotoWar.utils:addListener(
        "TotoWarCbacAiManager",
        TotoWar.enums.gameEvents.characterTurnEnd,
        ---@param context CharacterTurnEnd
        function(context)
            return
                TotoWarCbac.options.aiArmySuppliesEnabled
                and TotoWar.utils:isLordCharacter(context:character())
                and not cm:is_local_players_turn()
        end,
        ---@param context CharacterTurnEnd
        function(context)
            self:onAiCharacterTurnEnd(context:character())
        end)

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
        TotoWarCbac.loggers.aiManager:logError("Lord with CQI \"%s\" not found", lordCqi)

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

---Adjusts the units in an army to stay within maximum number of units allowed in each unit category and within army supplies cost and target army size.
---
---Uses a dynamic programming knapsack algorithm to find the best subset of removable units that covers the cost deficit while respecting the ideal size reduction when possible.
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
    local deficit = -armySuppliesCost.availableSupplies

    TotoWarCbac.loggers.aiManager:logDebug(
        "adjustAiArmyCompositionAndUnits(%s from %s): Army size: %s | Removable units: %s | Target army size: %s | Required removals for size: %s | Deficit: %s",
        function() return TotoWar.utils:getCharacterCaption(lord) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
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

    TotoWarCbac.loggers.aiManager:logDebug(
        "adjustAiArmyCompositionAndUnits(%s from %s): Categories in excess: %s",
        function() return TotoWar.utils:getCharacterCaption(lord) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function()
            if #categories == 0 then
                return "none"
            end

            return table.concat(
                TotoWarLinq:select(
                    unitCategoryExcessCounts.entries,
                    function(c) return string.format("%s (%s)", c.key, c.value) end),
                " | ")
        end)

    -------------------------------------------------------------------------
    -- Split removable units into:
    -- - excessUnits (categories in excess)
    -- - otherUnits (everything else)
    -------------------------------------------------------------------------
    ---@type TotoWarCbacUnitArmySuppliesCost[]
    local excessUnits = {}

    ---@type TotoWarCbacUnitArmySuppliesCost[]
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
    ---@type table<integer, table<string, table<integer, TotoWarCbacUnitArmySuppliesCost[]>>>
    local DP = {}
    DP[0] = {}

    local startState = TotoWarCbacAiManagerAdjustmentState.new(categories, maxPerCategory)
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
                    local baseState = TotoWarCbacAiManagerAdjustmentState.newFromKey(stateKey, categories, maxPerCategory)

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
            local state = TotoWarCbacAiManagerAdjustmentState.newFromKey(stateKey, categories, maxPerCategory)
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
        TotoWarCbac.loggers.aiManager:logDebug(
            "adjustAiArmyCompositionAndUnits(%s from %s): UNIT TO DISCARD (CATEGORY EXCESS) => %s | Category: %s | Cost: %s",
            function() return TotoWar.utils:getCharacterCaption(lord) end,
            function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
            function() return TotoWar.utils:getUnitCaption(unitArmySuppliesCost.unitKey) end,
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

    ---@type TotoWarCbacUnitArmySuppliesCost[]
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

        ---@type table<integer, { count: integer, picked: TotoWarCbacUnitArmySuppliesCost[] }>
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
                TotoWarCbac.loggers.aiManager:logDebug(
                    "adjustAiArmyCompositionAndUnits(%s from %s): UNIT TO DISCARD (EXTRA PICK) => %s | Category: %s | Cost: %s",
                    function() return TotoWar.utils:getCharacterCaption(lord) end,
                    function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
                    function() return TotoWar.utils:getUnitCaption(unitArmySuppliesCost.unitKey) end,
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
        TotoWarCbac.loggers.aiManager:logWarning(
            "Army composition of %s from %s cannot be adjusted (Deficit: %s | Removed cost: %s)",
            TotoWar.utils:getCharacterCaption(lord),
            TotoWar.utils:getFactionCaption(army:faction():name()),
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
    TotoWar.utils:saveValue(
        TotoWar_Cbac_ModName,
        string.format(TotoWarCbac.constants.storageKeyFormatArmyLastAdjustmentTurn, lord:cqi()),
        cm:turn_number())

    TotoWarCbac.loggers.aiManager:logDebug(
        "adjustAiArmyCompositionAndUnits(%s from %s): COMPLETED => Total army supplies cost: %s | Available army supplies: %s | Army size: %s",
        function() return TotoWar.utils:getCharacterCaption(lord) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return armySuppliesCost.totalCost end,
        function() return armySuppliesCost.availableSupplies end,
        function() return #armySuppliesCost.unitArmySuppliesCosts end)
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
    local heroesToRemoveAmount = #heroes -
        math.floor(#armySuppliesCost.unitArmySuppliesCosts * TotoWarCbac.options.aiArmyHeroMaximumPercentage / 100)

    if heroesToRemoveAmount == 0 then
        return 0
    end

    local lord = army:general_character()

    TotoWarCbac.loggers.aiManager:logDebug(
        "adjustAiArmyHeroes(%s from %s): STARTED => Total army supplies cost: %s | Available army supplies: %s | Army size: %s | Heroes to remove: %s",
        function() return TotoWar.utils:getCharacterCaption(lord) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return armySuppliesCost.totalCost end,
        function() return armySuppliesCost.availableSupplies end,
        function() return #armySuppliesCost.unitArmySuppliesCosts end,
        function() return heroesToRemoveAmount end)

    while heroesToRemoveAmount > 0 do
        -- Finding the group of heroes with the most heroes (or the last hero group when they all have the same amount of heroes)
        ---@type TotoWarKeyValue<string, TotoWarCbacUnitArmySuppliesCost[]>
        local heroUnitGroupWithMostHeroes = nil

        -- Grouping heroes by their base type to ignore their mount
        local heroUnitGroups = TotoWarLinq:groupBy(heroes, function(a) return a.baseUnitKey end)

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
            TotoWarLinq:findIndex(heroes, function(h) return h.characterCqi == heroToRemove.characterCqi end))
        heroesToRemoveAmount = heroesToRemoveAmount - 1

        TotoWarCbac.loggers.aiManager:logDebug(
            "adjustAiArmyHeroes(%s from %s): REMOVED => %s (%s)",
            function() return TotoWar.utils:getCharacterCaption(lord) end,
            function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
            function() return TotoWar.utils:getCharacterCaption(cm:get_character_by_cqi(heroToRemove.characterCqi)) end,
            function() return TotoWar.utils:getUnitCaption(heroToRemove.unitKey) end)
    end

    TotoWarCbac.loggers.aiManager:logDebug(
        "adjustAiArmyHeroes(%s from %s): COMPLETED => Total army supplies cost: %s | Available army supplies: %s | Army size: %s",
        function() return TotoWar.utils:getCharacterCaption(lord) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return armySuppliesCost.totalCost end,
        function() return armySuppliesCost.availableSupplies end,
        function() return #armySuppliesCost.unitArmySuppliesCosts end)
end

---Cancels the disband of a unit if the army it was in was already adjusted in order to comply with army supplies restrictions.
---@param lordCqi integer Command queue index of the lord whose army may have been adjusted.
function TotoWarCbacAiManager:cancelDisbandIfAlreadyAdjusted(lordCqi)
    local lord = cm:get_character_by_cqi(lordCqi)

    TotoWarCbac.loggers.aiManager:logDebug(
        "cancelDisbandIfAlreadyAdjusted(%s from %s): STARTED",
        function() return TotoWar.utils:getCharacterCaption(lord) end,
        function() return TotoWar.utils:getFactionCaption(lord:military_force():faction():name()) end)

    local armySuppliesCost = TotoWarCbacArmySuppliesCost.newFromArmy(true, lord:military_force())
    local disbandedUnits = self.disbandQueue:get(lordCqi)

    for index, disbandedUnit in ipairs(disbandedUnits) do
        if armySuppliesCost.availableSupplies >= disbandedUnit.armySuppliesCost then
            cm:grant_unit_to_character(
                cm:char_lookup_str(lord:cqi()),
                disbandedUnit.unitKey)
            armySuppliesCost:addUnit(disbandedUnit.unitKey)

            TotoWarCbac.loggers.aiManager:logDebug(
                "cancelDisbandIfAlreadyAdjusted(%s from %s): DISBAND CANCELLED => %s | Unit cost: %s | Available supplies: %s",
                function() return TotoWar.utils:getCharacterCaption(lord) end,
                function() return TotoWar.utils:getFactionCaption(lord:military_force():faction():name()) end,
                function() return TotoWar.utils:getUnitCaption(disbandedUnit.unitKey) end,
                function() return disbandedUnit.armySuppliesCost end,
                function() return armySuppliesCost.availableSupplies end)
        else
            -- In theory, we should never be in this case because the army adjustment should have removed enough units to prevent it
            TotoWarCbac.loggers.aiManager:logDebug(
                "cancelDisbandIfAlreadyAdjusted(%s from %s): DISBAND CONFIRMED => Unit: %s | Unit cost: %s | Available supplies : %s",
                function() return TotoWar.utils:getCharacterCaption(lord) end,
                function() return TotoWar.utils:getFactionCaption(lord:military_force():faction():name()) end,
                function() return TotoWar.utils:getUnitCaption(disbandedUnit.unitKey) end,
                function() return disbandedUnit.armySuppliesCost end,
                function() return armySuppliesCost.availableSupplies end)
        end
    end

    TotoWarCbac.loggers.aiManager:logDebug(
        "cancelDisbandIfAlreadyAdjusted(%s from %s): COMPLETED",
        function() return TotoWar.utils:getCharacterCaption(lord) end,
        function() return TotoWar.utils:getFactionCaption(lord:military_force():faction():name()) end)
end

---Gets the target army size for a lord.
---
---If it is not set yet, it is randomly generated and stored in the game state.
---@param lordCqi integer Command queue index of the lord.
---@return integer
function TotoWarCbacAiManager:getLordTargetArmySize(lordCqi)
    ---@type integer | nil
    local targetArmySize = TotoWar.utils:getSavedValue(
        TotoWar_Cbac_ModName,
        string.format(TotoWarCbac.constants.storageKeyFormatArmyTargetSize, lordCqi))

    if targetArmySize == nil then
        targetArmySize = math.random(13, 20)
        TotoWar.utils:saveValue(
            TotoWar_Cbac_ModName,
            string.format(TotoWarCbac.constants.storageKeyFormatArmyTargetSize, lordCqi),
            targetArmySize)
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

---Reacts to the turn of a character ending.
---@param character CHARACTER_SCRIPT_INTERFACE Character.
function TotoWarCbacAiManager:onAiCharacterTurnEnd(character)
    TotoWarCbac.loggers.aiManager:logDebug(
        "onAiCharacterTurnEnd(%s from %s): STARTED",
        function() return TotoWar.utils:getCharacterCaption(character) end,
        function() return TotoWar.utils:getFactionCaption(character:faction():name()) end)

    -- Relaunching the army adjustment to remove heros that may have been (re)added after the army adjustement triggered when units are recruited
    self:adjustAiArmy(character:cqi())

    TotoWarCbac.loggers.aiManager:logDebug(
        "onAiCharacterTurnEnd(%s from %s): COMPLETED",
        function() return TotoWar.utils:getCharacterCaption(character) end,
        function() return TotoWar.utils:getFactionCaption(character:faction():name()) end)
end

---Reacts to a unit being converted by an AI army.
---@param originalUnit UNIT_SCRIPT_INTERFACE Unit.
---@param newUnit UNIT_SCRIPT_INTERFACE Unit.
function TotoWarCbacAiManager:onAiUnitConverted(originalUnit, newUnit)
    local lord = newUnit:military_force():general_character()

    TotoWarCbac.loggers.aiManager:logDebug(
        "onAiUnitConverted(%s from %s, %s, %s): STARTED",
        function() return TotoWar.utils:getCharacterCaption(lord) end,
        function() return TotoWar.utils:getFactionCaption(newUnit:military_force():faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(originalUnit:unit_key()) end,
        function() return TotoWar.utils:getUnitCaption(newUnit:unit_key()) end)

    -- This is just to log how AI converts units and how it impacts the mod

    TotoWarCbac.loggers.aiManager:logDebug(
        "onAiUnitConverted(%s from %s, %s, %s): COMPLETED",
        function() return TotoWar.utils:getCharacterCaption(lord) end,
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

    self:addUnitToDisbandQueue(unit)

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

    self:addArmyToAdjustmentQueue(lord:cqi())

    TotoWarCbac.loggers.aiManager:logDebug(
        "onAiUnitRecruited(%s from %s, %s): COMPLETED",
        function() return TotoWar.utils:getCharacterCaption(lord) end,
        function() return TotoWar.utils:getFactionCaption(unit:military_force():faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(unit:unit_key()) end)
end

---Reacts to a unit being upgraded by an AI army.
---@param unit UNIT_SCRIPT_INTERFACE Unit.
function TotoWarCbacAiManager:onAiUnitUpgraded(unit)
    local lord = unit:military_force():general_character()

    TotoWarCbac.loggers.aiManager:logDebug(
        "onAiUnitUpgraded(%s from %s, %s): STARTED",
        function() return TotoWar.utils:getCharacterCaption(lord) end,
        function() return TotoWar.utils:getFactionCaption(unit:military_force():faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(unit:unit_key()) end)

    self:addArmyToAdjustmentQueue(lord:cqi())

    TotoWarCbac.loggers.aiManager:logDebug(
        "onAiUnitUpgraded(%s from %s, %s): COMPLETED",
        function() return TotoWar.utils:getCharacterCaption(lord) end,
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

    cm:remove_unit_from_character(cm:char_lookup_str(army:general_character()), unitKey)

    TotoWarCbac.loggers.aiManager:logDebug(
        "removeUnitFromAiArmy(%s from %s, %s, %s): COMPLETED",
        function() return TotoWar.utils:getCharacterCaption(army:general_character()) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(unitKey) end,
        function() return unitCqi end)
end
