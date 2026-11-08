require("script._lib.mod.totowar_cbac_enum")

local logger = TotoWar__Logger.get(TotoWar_Cbac_Enum_LogCategories.aiManager)

---Gets the data stored for an AI army (target composition and last adjustment turn).
---@param armyCqi integer Army command queue index.
---@return { composition: table<TotoWar_Cbac_Enum_ArmyCompositionUnitCategories, integer> | nil, lastAdjustmentTurn: integer | nil } | nil
local function getAiArmyData(armyCqi)
    logger:logDebug(
        "getAiArmyData(%s): STARTED => %s",
        armyCqi,
        function()
            local army = TotoWar__Gameplay:getArmy(armyCqi)

            return army ~= nil and TotoWar__Gameplay:getArmyCaption(army) or "Army not found"
        end)

    local aiArmyData = TotoWar__Gameplay:getSavedValue(
        TotoWar_Cbac_Constant.modName,
        string.format(TotoWar_Cbac_Constant.storageKeyFormatAiArmy, armyCqi))

    logger:logDebug(
        "getAiArmyData(%s): COMPLETED => %s | Found: %s",
        armyCqi,
        function()
            local army = TotoWar__Gameplay:getArmy(armyCqi)

            return army ~= nil and TotoWar__Gameplay:getArmyCaption(army) or "Army not found"
        end,
        aiArmyData ~= nil)

    ---@diagnostic disable-next-line: return-type-mismatch
    return aiArmyData
end

---Stores the data of an AI army (target composition and last adjustment turn).
---@param armyCqi integer Army command queue index.
---@param aiArmyData table | nil Data of the army, or nil to remove it.
local function setAiArmyData(armyCqi, aiArmyData)
    logger:logDebug(
        "setAiArmyData(%s, aiArmyData): STARTED => %s | Cleared: %s",
        armyCqi,
        function()
            local army = TotoWar__Gameplay:getArmy(armyCqi)

            return army ~= nil and TotoWar__Gameplay:getArmyCaption(army) or "Army not found"
        end,
        aiArmyData == nil)

    local key = string.format(TotoWar_Cbac_Constant.storageKeyFormatAiArmy, armyCqi)

    if aiArmyData == nil then
        TotoWar__Gameplay:clearSavedValue(TotoWar_Cbac_Constant.modName, key)
    else
        TotoWar__Gameplay:saveValue(TotoWar_Cbac_Constant.modName, key, aiArmyData)
    end

    logger:logDebug(
        "setAiArmyData(%s, aiArmyData): COMPLETED => %s | Cleared: %s",
        armyCqi,
        function()
            local army = TotoWar__Gameplay:getArmy(armyCqi)

            return army ~= nil and TotoWar__Gameplay:getArmyCaption(army) or "Army not found"
        end,
        aiArmyData == nil)
end

---Sort function ordering unit army supplies costs from the cheapest to the priciest.
---Units with the same cost are ordered by unit key, then by unit CQI, so that the units chosen by the adjustment
---do not depend on the order in which the game lists the units of the army.
---@param a TotoWar_Cbac_UnitArmySuppliesCost
---@param b TotoWar_Cbac_UnitArmySuppliesCost
---@return boolean
local function compareUnitArmySuppliesCosts(a, b)
    if a.armySuppliesCost ~= b.armySuppliesCost then
        return a.armySuppliesCost < b.armySuppliesCost
    end

    if a.unitKey ~= b.unitKey then
        return a.unitKey < b.unitKey
    end

    -- The unit CQI is nil for a unit being recruited, which does not occur in an AI army
    return (a.unitCqi or 0) < (b.unitCqi or 0)
end

---Gets the total experience level of units.
---Used to remove the least experienced units first when several combinations of units are equivalent.
---@param units TotoWar_Cbac_UnitArmySuppliesCost[]
---@return integer
local function getTotalExperienceLevel(units)
    local totalExperienceLevel = 0

    for _, unit in ipairs(units) do
        totalExperienceLevel = totalExperienceLevel + unit.experienceLevel
    end

    return totalExperienceLevel
end

---Indicates whether a combination of units comes before another one, to choose between two equivalent combinations
---without depending on the iteration order of `pairs`, which depends on how the game lists the units of the army.
---The units of each combination must be sorted with `compareUnitArmySuppliesCosts`.
---@param units1 TotoWar_Cbac_UnitArmySuppliesCost[]
---@param units2 TotoWar_Cbac_UnitArmySuppliesCost[]
---@return boolean
local function isCombinationBefore(units1, units2)
    for i = 1, math.min(#units1, #units2) do
        if compareUnitArmySuppliesCosts(units1[i], units2[i]) then
            return true
        end

        if compareUnitArmySuppliesCosts(units2[i], units1[i]) then
            return false
        end
    end

    return #units1 < #units2
end

---Adjusts the units in an army to stay within maximum number of units allowed in each unit category and within army supplies cost and target army size.
---
---Uses a dynamic programming knapsack algorithm to find the best subset of removable units that covers the cost deficit while respecting the ideal size reduction when possible.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@param armySuppliesCost TotoWar_Cbac_ArmySuppliesCost Army supplies cost of the army. Updated if units are flagged as to removed.
---@param targetArmySize integer Target army size.
---@param unitCategoryExcessCounts TotoWar__Dictionary<string, integer> Excess count by unit category.
---@param unitsToDiscard TotoWar_Cbac_UnitArmySuppliesCost[] List in which units to discard are stored. Updated if units are flagged as to be removed.
local function adjustAiArmyCompositionAndUnits(
    army,
    armySuppliesCost,
    targetArmySize,
    unitCategoryExcessCounts,
    unitsToDiscard
)
    logger:logDebug(
        "adjustAiArmyCompositionAndUnits(%s, armySuppliesCost, %s, unitCategoryExcessCounts, unitsToDiscard): STARTED => %s | Total cost: %s | Available supplies: %s",
        function() return army:command_queue_index() end,
        targetArmySize,
        function() return TotoWar__Gameplay:getArmyCaption(army) end,
        armySuppliesCost.totalCost,
        armySuppliesCost.availableSupplies)

    if armySuppliesCost.availableSupplies >= 0 then
        logger:logDebug(
            "adjustAiArmyCompositionAndUnits(%s, armySuppliesCost, %s, unitCategoryExcessCounts, unitsToDiscard): COMPLETED => %s | Total cost: %s | Available supplies: %s | Army supplies not exceeded",
            function() return army:command_queue_index() end,
            targetArmySize,
            function() return TotoWar__Gameplay:getArmyCaption(army) end,
            armySuppliesCost.totalCost,
            armySuppliesCost.availableSupplies)

        return
    end

    local removableUnits = TotoWar__Linq:where(
        armySuppliesCost.unitArmySuppliesCosts,
        function(uasc)
            return
                uasc.unitCategory ~= TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.lord
                and uasc.unitCategory ~= TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.hero
        end)

    if #removableUnits == 0 then
        logger:logDebug(
            "adjustAiArmyCompositionAndUnits(%s, armySuppliesCost, %s, unitCategoryExcessCounts, unitsToDiscard): COMPLETED => %s | Total cost: %s | Available supplies: %s | No removable unit",
            function() return army:command_queue_index() end,
            targetArmySize,
            function() return TotoWar__Gameplay:getArmyCaption(army) end,
            armySuppliesCost.totalCost,
            armySuppliesCost.availableSupplies)

        return
    end

    local currentArmySize = #armySuppliesCost.unitArmySuppliesCosts
    local requiredRemovalsForSize = math.max(0, currentArmySize - targetArmySize)
    local deficit = -armySuppliesCost.availableSupplies

    logger:logDebug(
        "adjustAiArmyCompositionAndUnits(%s, armySuppliesCost, %s, unitCategoryExcessCounts, unitsToDiscard): ARMY => %s | Size: %s | Removable units: %s | Target size: %s | Required removals for size: %s | Deficit: %s",
        function() return army:command_queue_index() end,
        targetArmySize,
        function() return TotoWar__Gameplay:getArmyCaption(army) end,
        currentArmySize,
        #removableUnits,
        targetArmySize,
        requiredRemovalsForSize,
        deficit)

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

    logger:logDebug(
        "adjustAiArmyCompositionAndUnits(%s, armySuppliesCost, %s, unitCategoryExcessCounts, unitsToDiscard): CATEGORIES IN EXCESS => %s | %s",
        function() return army:command_queue_index() end,
        targetArmySize,
        function() return TotoWar__Gameplay:getArmyCaption(army) end,
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

    table.sort(excessUnits, compareUnitArmySuppliesCosts)

    for _, unit in ipairs(excessUnits) do
        for removedCount = maxRemovals - 1, 0, -1 do
            if DP[removedCount] then
                DP[removedCount + 1] = DP[removedCount + 1] or {}

                for stateKey, costTable in pairs(DP[removedCount]) do
                    local baseState = TotoWar_Cbac_AiManagerAdjustmentState.newFromKey(stateKey, categories,
                        maxPerCategory)

                    if baseState:canAdd(unit.unitCategory) then
                        for removedCost, picked in pairs(costTable) do
                            local newCost = removedCost + unit.armySuppliesCost

                            if newCost <= maxCost then
                                local newState = baseState:clone()
                                newState:add(unit.unitCategory)

                                local newKey = newState:getKey()

                                DP[removedCount + 1][newKey] = DP[removedCount + 1][newKey] or {}

                                local existingPicked = DP[removedCount + 1][newKey][newCost]
                                local newPicked = nil

                                if existingPicked == nil then
                                    newPicked = { unpack(picked) }
                                    table.insert(newPicked, unit)
                                else
                                    -- For the same removal count, category state and cost, the combination with
                                    -- the least experienced units is kept, so that they are removed first
                                    local newExperienceLevel = getTotalExperienceLevel(picked) + unit.experienceLevel
                                    local existingExperienceLevel = getTotalExperienceLevel(existingPicked)

                                    if newExperienceLevel <= existingExperienceLevel then
                                        newPicked = { unpack(picked) }
                                        table.insert(newPicked, unit)

                                        if newExperienceLevel == existingExperienceLevel
                                            and not isCombinationBefore(newPicked, existingPicked)
                                        then
                                            newPicked = nil
                                        end
                                    end
                                end

                                if newPicked ~= nil then
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
    -- 4) minimal total experience level
    -- 5) first combination when sorting units with compareUnitArmySuppliesCosts (isCombinationBefore)
    --
    -- PARTIAL solutions (cost < deficit):
    -- 1) maximal cost (closest below deficit)
    -- 2) closest to requiredRemovalsForSize (if requiredRemovalsForSize > 0)
    -- 3) fewer removals
    -- 4) minimal total experience level
    -- 5) first combination when sorting units with compareUnitArmySuppliesCosts (isCombinationBefore)
    --
    -- The last criterion makes the choice independent of the iteration order of `pairs`.
    -------------------------------------------------------------------------
    local idealRemovalCount = nil
    if requiredRemovalsForSize > 0 then
        idealRemovalCount = requiredRemovalsForSize
    end

    local bestPicked = nil
    local bestCost = nil
    ---@type integer
    local bestRemovalCount = nil
    local bestExperienceLevel = nil

    local partialPicked = nil
    local partialCost = nil
    ---@type integer
    local partialRemovalCount = nil
    local partialExperienceLevel = nil

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

        for _, costTable in pairs(DP[k]) do
            for cost, picked in pairs(costTable) do
                local experienceLevel = getTotalExperienceLevel(picked)

                if cost >= deficit then
                    if bestPicked == nil then
                        bestPicked = picked
                        bestCost = cost
                        bestRemovalCount = k
                        bestExperienceLevel = experienceLevel
                    else
                        local bestDist = getDistanceToIdeal(bestRemovalCount)
                        local newDist = getDistanceToIdeal(k)

                        local bestExcess = bestCost - deficit
                        local newExcess = cost - deficit

                        if newDist < bestDist
                            or (newDist == bestDist and k < bestRemovalCount)
                            or (newDist == bestDist and k == bestRemovalCount and newExcess < bestExcess)
                            or (newDist == bestDist and k == bestRemovalCount and newExcess == bestExcess and experienceLevel < bestExperienceLevel)
                            or (newDist == bestDist and k == bestRemovalCount and newExcess == bestExcess and experienceLevel == bestExperienceLevel and isCombinationBefore(picked, bestPicked))
                        then
                            bestPicked = picked
                            bestCost = cost
                            bestRemovalCount = k
                            bestExperienceLevel = experienceLevel
                        end
                    end
                else
                    if partialPicked == nil then
                        partialPicked = picked
                        partialCost = cost
                        partialRemovalCount = k
                        partialExperienceLevel = experienceLevel
                    else
                        local partialDist = getDistanceToIdeal(partialRemovalCount)
                        local newDist = getDistanceToIdeal(k)

                        if cost > partialCost
                            or (cost == partialCost and newDist < partialDist)
                            or (cost == partialCost and newDist == partialDist and k < partialRemovalCount)
                            or (cost == partialCost and newDist == partialDist and k == partialRemovalCount and experienceLevel < partialExperienceLevel)
                            or (cost == partialCost and newDist == partialDist and k == partialRemovalCount and experienceLevel == partialExperienceLevel and isCombinationBefore(picked, partialPicked))
                        then
                            partialPicked = picked
                            partialCost = cost
                            partialRemovalCount = k
                            partialExperienceLevel = experienceLevel
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
        logger:logDebug(
            "adjustAiArmyCompositionAndUnits(%s, armySuppliesCost, %s, unitCategoryExcessCounts, unitsToDiscard): UNIT TO DISCARD (CATEGORY EXCESS) => %s | Unit: %s | Unit CQI: %s | Category: %s | Cost: %s | Experience: %s",
            function() return army:command_queue_index() end,
            targetArmySize,
            function() return TotoWar__Gameplay:getArmyCaption(army) end,
            function() return TotoWar__Gameplay:getUnitCaption(unitArmySuppliesCost.unitKey) end,
            unitArmySuppliesCost.unitCqi,
            unitArmySuppliesCost.unitCategory,
            unitArmySuppliesCost.armySuppliesCost,
            unitArmySuppliesCost.experienceLevel)
    end

    -------------------------------------------------------------------------
    -- COMPLETE WITH otherUnits if deficit not covered
    -------------------------------------------------------------------------
    -- No unit of otherUnits has been picked: the units picked above all come from excessUnits.
    -- otherUnits keeps the order of the army units sorted with compareUnitArmySuppliesCosts, which DP2 relies on
    -- to keep the same combination whatever the order in which the game lists the units of the army.
    local remaining = otherUnits

    local remainingDeficit = deficit - bestCost

    if remainingDeficit > 0 and #remaining > 0 then
        ---@type table<integer, { count: integer, experienceLevel: integer, picked: TotoWar_Cbac_UnitArmySuppliesCost[] }>
        local DP2 = {}
        DP2[0] = { count = 0, experienceLevel = 0, picked = {} }

        for _, unit in ipairs(remaining) do
            -- Only iterating over the costs already reached instead of every cost up to the total cost of the units.
            -- They are processed from the highest to the lowest so that each unit is added at most once to a combination:
            -- the costs updated for this unit are higher than the cost being processed, so they have already been processed.
            local reachedCosts = {}

            for cost, _ in pairs(DP2) do
                table.insert(reachedCosts, cost)
            end

            table.sort(reachedCosts, function(a, b) return a > b end)

            for _, cost in ipairs(reachedCosts) do
                local entry = DP2[cost]
                if entry then
                    local newCost = cost + unit.armySuppliesCost
                    local newCount = entry.count + 1
                    local newExperienceLevel = entry.experienceLevel + unit.experienceLevel

                    local existing = DP2[newCost]

                    -- For the same cost and removal count, the combination with the least experienced units is kept,
                    -- so that they are removed first
                    if existing == nil
                        or newCount < existing.count
                        or (newCount == existing.count and newExperienceLevel < existing.experienceLevel)
                    then
                        local newPicked = { unpack(entry.picked) }
                        table.insert(newPicked, unit)

                        DP2[newCost] = {
                            count = newCount,
                            experienceLevel = newExperienceLevel,
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
                logger:logDebug(
                    "adjustAiArmyCompositionAndUnits(%s, armySuppliesCost, %s, unitCategoryExcessCounts, unitsToDiscard): UNIT TO DISCARD (EXTRA PICK) => %s | Unit: %s | Unit CQI: %s | Category: %s | Cost: %s | Experience: %s",
                    function() return army:command_queue_index() end,
                    targetArmySize,
                    function() return TotoWar__Gameplay:getArmyCaption(army) end,
                    function() return TotoWar__Gameplay:getUnitCaption(unitArmySuppliesCost.unitKey) end,
                    unitArmySuppliesCost.unitCqi,
                    unitArmySuppliesCost.unitCategory,
                    unitArmySuppliesCost.armySuppliesCost,
                    unitArmySuppliesCost.experienceLevel)
            end
        end
    end

    -------------------------------------------------------------------------
    -- Final safety: ensure deficit is covered
    -------------------------------------------------------------------------
    if bestCost < deficit then
        logger:logWarning(
            "%s: army adjusted, army supplies still exceeded by %s (disbandable units only cover %s)",
            function() return TotoWar__Gameplay:getArmyCaption(army) end,
            deficit,
            bestCost)
    end

    -------------------------------------------------------------------------
    -- Apply removals
    -------------------------------------------------------------------------
    for _, unitArmySuppliesCost in ipairs(bestPicked) do
        table.insert(unitsToDiscard, unitArmySuppliesCost)
        armySuppliesCost:removeUnit(unitArmySuppliesCost.unitKey, unitArmySuppliesCost.unitCqi)
    end

    -- Storing the current turn as the last adjustment turn for that army to be able to cancel the disbands that may happen just after the adjustment
    -- to avoid removing too many units from the army
    local aiArmyData = getAiArmyData(army:command_queue_index()) or {}
    aiArmyData.lastAdjustmentTurn = cm:turn_number()
    setAiArmyData(army:command_queue_index(), aiArmyData)

    logger:logDebug(
        "adjustAiArmyCompositionAndUnits(%s, armySuppliesCost, %s, unitCategoryExcessCounts, unitsToDiscard): COMPLETED => %s | Total cost: %s | Available supplies: %s | Army size: %s",
        function() return army:command_queue_index() end,
        targetArmySize,
        function() return TotoWar__Gameplay:getArmyCaption(army) end,
        armySuppliesCost.totalCost,
        armySuppliesCost.availableSupplies,
        #armySuppliesCost.unitArmySuppliesCosts)
end

---Adjusts the amount of heroes in an army if it exceeds the limit.
---
---Duplicate hero types are removed first.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@param armySuppliesCost TotoWar_Cbac_ArmySuppliesCost Army supplies cost of the army. Updated if heroes are removed.
---@param herosInExcess integer Amount of heroes that exceed the limit.
local function adjustAiArmyHeroes(army, armySuppliesCost, herosInExcess)
    logger:logDebug(
        "adjustAiArmyHeroes(%s, armySuppliesCost, %s): STARTED => %s | Total cost: %s | Available supplies: %s | Army size: %s",
        function() return army:command_queue_index() end,
        herosInExcess,
        function() return TotoWar__Gameplay:getArmyCaption(army) end,
        armySuppliesCost.totalCost,
        armySuppliesCost.availableSupplies,
        #armySuppliesCost.unitArmySuppliesCosts)

    local heroes = TotoWar__Linq:where(
        armySuppliesCost.unitArmySuppliesCosts,
        function(uasc) return uasc.unitCategory == TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.hero end)

    if herosInExcess == 0 then
        logger:logDebug(
            "adjustAiArmyHeroes(%s, armySuppliesCost, %s): COMPLETED => %s | Total cost: %s | Available supplies: %s | Army size: %s | No hero in excess",
            function() return army:command_queue_index() end,
            herosInExcess,
            function() return TotoWar__Gameplay:getArmyCaption(army) end,
            armySuppliesCost.totalCost,
            armySuppliesCost.availableSupplies,
            #armySuppliesCost.unitArmySuppliesCosts)

        return
    end

    local lord = army:general_character()

    while herosInExcess > 0 do
        -- Grouping heroes by their base type to ignore their mount
        local heroUnitGroups = TotoWar__Linq:groupBy(heroes, function(a) return a.baseUnitKey end)

        -- Finding the size of the groups of heroes with the most heroes
        local largestHeroUnitGroupSize = 0

        for index, entry in ipairs(heroUnitGroups.entries) do
            largestHeroUnitGroupSize = math.max(largestHeroUnitGroupSize, #entry.value)
        end

        -- Removing the least experienced hero among these groups, so that AI armies keep their veteran heroes
        -- (or the last hero of the last group when several heroes have the same rank)
        ---@type TotoWar_Cbac_UnitArmySuppliesCost
        local heroToRemove = nil

        for index, entry in ipairs(heroUnitGroups.entries) do
            if #entry.value == largestHeroUnitGroupSize then
                for _, hero in ipairs(entry.value) do
                    if heroToRemove == nil or hero.experienceLevel <= heroToRemove.experienceLevel then
                        heroToRemove = hero
                    end
                end
            end
        end

        -- Getting the location where the hero will be teleported
        local heroTargetPositionX, heroTargetPositionY = cm:find_valid_spawn_location_for_character_from_position(
            lord:faction():name(),
            lord:logical_position_x(),
            lord:logical_position_y(),
            true);

        if heroTargetPositionX == -1 then
            -- No valid position around the army (at sea, in the Underway, etc.), other heroes would fail the same way
            logger:logWarning(
                "%s: army adjusted, %s hero(es) stay in the army (no free position to leave)",
                function() return TotoWar__Gameplay:getArmyCaption(army) end,
                herosInExcess)

            break
        end

        -- Teleporting the hero out of the lord army.
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

        logger:logInfo(
            "%s: army adjusted, hero %s (%s, rank %s) left the army",
            function() return TotoWar__Gameplay:getArmyCaption(army) end,
            function()
                local hero = TotoWar__Gameplay:getCharacter(heroToRemove.characterCqi)

                return hero ~= nil and TotoWar__Gameplay:getCharacterCaption(hero) or heroToRemove.characterCqi
            end,
            function() return TotoWar__Gameplay:getUnitCaption(heroToRemove.unitKey) end,
            heroToRemove.experienceLevel)
    end

    logger:logDebug(
        "adjustAiArmyHeroes(%s, armySuppliesCost, %s): COMPLETED => %s | Total cost: %s | Available supplies: %s | Army size: %s",
        function() return army:command_queue_index() end,
        herosInExcess,
        function() return TotoWar__Gameplay:getArmyCaption(army) end,
        armySuppliesCost.totalCost,
        armySuppliesCost.availableSupplies,
        #armySuppliesCost.unitArmySuppliesCosts)
end

---Gets the maximum percentage of a unit category for a culture.
---@param culture string Culture key.
---@param unitCategory TotoWar_Cbac_Enum_ArmyCompositionUnitCategories Unit category.
---@return integer | nil
local function getUnitCategoryMaximumPercentage(culture, unitCategory)
    logger:logDebug(
        "getUnitCategoryMaximumPercentage(%s, %s): STARTED => Culture: %s",
        culture,
        unitCategory,
        function() return TotoWar__Gameplay:getCultureCaption(culture) end)

    ---@type integer | nil
    local maximumPercentage = nil

    if TotoWar_Cbac_ArmyCompositionTarget:exists(culture)
        and TotoWar_Cbac_ArmyCompositionTarget:get(culture):exists(unitCategory)
    then
        maximumPercentage = TotoWar_Cbac_ArmyCompositionTarget:get(culture):get(unitCategory)
    end

    logger:logDebug(
        "getUnitCategoryMaximumPercentage(%s, %s): COMPLETED => Culture: %s | %s",
        culture,
        unitCategory,
        function() return TotoWar__Gameplay:getCultureCaption(culture) end,
        maximumPercentage)

    return maximumPercentage
end

---Gets the maximum percentage a unit category can represent in a target army composition.
---@param faction FACTION_SCRIPT_INTERFACE Faction.
---@return TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategories, integer>
local function getTargetArmyCompositionUnitCategoryMaximumPercentages(faction)
    logger:logDebug(
        "getTargetArmyCompositionUnitCategoryMaximumPercentages(%s): STARTED => %s",
        function() return faction:name() end,
        function() return TotoWar__Gameplay:getFactionFullCaption(faction) end)

    ---@type TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategories, integer>
    local result = TotoWar__Dictionary.new()

    ---Unit categories having a maximum percentage for the culture of the faction, whether it lowered the MCT value or not.
    ---@type TotoWar_Cbac_Enum_ArmyCompositionUnitCategories[]
    local cappedUnitCategories = {}

    ---@diagnostic disable-next-line: param-type-mismatch
    local defaultTargetComposition = TotoWar_Cbac_ArmyCompositionTarget:get("default")
    local defaultTotal = 0
    local realTotal = 0

    for index, unitCategory in ipairs(defaultTargetComposition:getKeys()) do
        local defaultPercentage = defaultTargetComposition:get(unitCategory)
        local realPercentage = defaultPercentage
        local maximumPercentage = getUnitCategoryMaximumPercentage(faction:culture(), unitCategory)

        if maximumPercentage ~= nil then
            table.insert(cappedUnitCategories, unitCategory)

            if maximumPercentage < realPercentage then
                realPercentage = maximumPercentage
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
                return k ~= TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.lord  -- We do not want to allow more lords
                    and k ~= TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.hero -- We do not want to allow more heroes
                    and not TotoWar__Linq:any(cappedUnitCategories, function(c) return c == k end)
            end)

        if #unitCategoriesToUpdate > 0 then
            local percentageToAddPerUnitCategory = TotoWar__Number:roundToMultipleOf(
                difference / #unitCategoriesToUpdate,
                5)

            for index, unitCategory in ipairs(unitCategoriesToUpdate) do
                local updatedPercentage = result:get(unitCategory) + percentageToAddPerUnitCategory
                result:set(
                    unitCategory,
                    math.min(updatedPercentage, TotoWar_Cbac_Constant.maximumUnitCategoryTargetPercentage))
            end
        end
    end

    logger:logDebug(
        "getTargetArmyCompositionUnitCategoryMaximumPercentages(%s): COMPLETED => %s | %s",
        function() return faction:name() end,
        function() return TotoWar__Gameplay:getFactionFullCaption(faction) end,
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
local function getTargetArmyComposition(army)
    logger:logDebug(
        "getTargetArmyComposition(%s): STARTED => %s",
        function() return army:command_queue_index() end,
        function() return TotoWar__Gameplay:getArmyCaption(army) end)

    ---@type TotoWar__Dictionary<string, integer>
    local categoryUnitCounts = TotoWar__Dictionary.new()

    local aiArmyData = getAiArmyData(army:command_queue_index())

    ---@type integer
    local armySize

    if aiArmyData ~= nil and aiArmyData.composition ~= nil then
        logger:logDebug(
            "getTargetArmyComposition(%s): READING EXISTING COMPOSITION => %s",
            function() return army:command_queue_index() end,
            function() return TotoWar__Gameplay:getArmyCaption(army) end)

        -- Reading existing values from the game state
        local unitCategories = {
            TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.lord,
            unpack(TotoWar_Cbac_Constant.randomUnitCategories)
        }

        for index, unitCategory in ipairs(unitCategories) do
            if aiArmyData.composition[unitCategory] ~= nil then
                categoryUnitCounts:set(unitCategory, aiArmyData.composition[unitCategory])
            end
        end

        armySize = TotoWar__Linq:sum(categoryUnitCounts:getValues(), function(v) return v end)
    else
        logger:logDebug(
            "getTargetArmyComposition(%s): GENERATING NEW COMPOSITION => %s",
            function() return army:command_queue_index() end,
            function() return TotoWar__Gameplay:getArmyCaption(army) end)

        -- Generating an army target composition
        local maximumPercentages = getTargetArmyCompositionUnitCategoryMaximumPercentages(army:faction())

        armySize = cm:random_number(
            TotoWar_Cbac_Constant.maximumTargetArmySize,
            TotoWar_Cbac_Constant.minimumTargetArmySize)

        local lordUnitAmount = 1
        local nonLordUnitCount = armySize - lordUnitAmount

        ---@type TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategories, integer>
        local percentages = TotoWar__Dictionary.new()
        local percentagesTotal = 0

        for index, unitCategory in ipairs(TotoWar_Cbac_Constant.randomUnitCategories) do
            local maximumPercentage = maximumPercentages:get(unitCategory)
            local percentage = cm:random_number(
                maximumPercentage,
                math.ceil(maximumPercentage * TotoWar_Cbac_Constant.minimumUnitCategoryPercentageRatio))
            percentage = TotoWar__Number:roundToMultipleOf(percentage, 5)

            percentages:set(unitCategory, percentage)
            percentagesTotal = percentagesTotal + percentage
        end

        if percentagesTotal > 100 then
            -- Adjusting percentages with a ratio to be based on 100
            local ratio = 100 / percentagesTotal
            percentagesTotal = 0

            for index, unitCategory in ipairs(TotoWar_Cbac_Constant.randomUnitCategories) do
                local percentage = TotoWar__Number:roundToMultipleOf(percentages:get(unitCategory) * ratio, 5)

                percentages:set(unitCategory, percentage)
                percentagesTotal = percentagesTotal + percentage
            end
        end

        -- Filling the remaining percentage with melee infantry
        percentages:set(
            TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.meleeInfantry,
            percentages:get(TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.meleeInfantry) + 100 - percentagesTotal)

        -- Making sure the melee percentage is the highest
        table.sort(
            percentages.entries,
            function(a, b) return a.value > b.value end)
        local highestPercentageEntry = percentages.entries[1]

        if highestPercentageEntry.key ~= TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.meleeInfantry then
            local highestPercentage = highestPercentageEntry.value
            local meleeInfantryPercentage = percentages:get(TotoWar_Cbac_Enum_ArmyCompositionUnitCategories
                .meleeInfantry)

            percentages:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.meleeInfantry, highestPercentage)
            percentages:set(highestPercentageEntry.key, meleeInfantryPercentage)
        end

        logger:logDebug(
            "getTargetArmyComposition(%s): TARGET PERCENTAGES => %s | %s",
            function() return army:command_queue_index() end,
            function() return TotoWar__Gameplay:getArmyCaption(army) end,
            function()
                return table.concat(
                    TotoWar__Linq:select(
                        TotoWar_Cbac_Constant.randomUnitCategories,
                        function(c) return string.format("%s: %s%%", c, percentages:get(c)) end),
                    " | ")
            end)

        local assignedUnits = 0

        for index, unitCategory in ipairs(TotoWar_Cbac_Constant.randomUnitCategories) do
            local unitCount = TotoWar__Number:roundToNearestInteger(
                nonLordUnitCount * percentages:get(unitCategory) / 100)

            categoryUnitCounts:set(unitCategory, unitCount)
            assignedUnits = assignedUnits + unitCount
        end

        -- Fix rounding errors
        local delta = nonLordUnitCount - assignedUnits

        if delta ~= 0 then
            categoryUnitCounts:set(
                TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.meleeInfantry,
                categoryUnitCounts:get(TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.meleeInfantry) + delta)
        end

        categoryUnitCounts:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.lord, lordUnitAmount)

        local composition = {}

        for index, entry in ipairs(categoryUnitCounts.entries) do
            composition[entry.key] = entry.value
        end

        aiArmyData = aiArmyData or {}
        aiArmyData.composition = composition
        setAiArmyData(army:command_queue_index(), aiArmyData)

        logger:logInfo(
            "%s: army composition chosen (Size: %s | Heroes: %s | Melee infantry: %s | Ranged infantry: %s | Cavalry & monsters: %s | War machines: %s)",
            function() return TotoWar__Gameplay:getArmyCaption(army) end,
            armySize,
            categoryUnitCounts:get(TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.hero),
            categoryUnitCounts:get(TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.meleeInfantry),
            categoryUnitCounts:get(TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.rangedInfantry),
            categoryUnitCounts:get(TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.cavalryAndMonsters),
            categoryUnitCounts:get(TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.warMachines))
    end

    logger:logDebug(
        "getTargetArmyComposition(%s): COMPLETED => %s | Target army size: %s | %s",
        function() return army:command_queue_index() end,
        function() return TotoWar__Gameplay:getArmyCaption(army) end,
        armySize,
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
local function getUnitCategoryExcessCounts(armySuppliesCost, targetCategoryCounts)
    logger:logDebug("getUnitCategoryExcessCounts(armySuppliesCost, targetCategoryCounts): STARTED")

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

        categoryCounts:set(unitArmySuppliesCost.unitCategory, current + 1)
        totalUnitCount = totalUnitCount + 1
    end

    if totalUnitCount > 0 then
        for _, entry in ipairs(categoryCounts.entries) do
            if entry.key ~= TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.meleeInfantry then -- Melee infantry cannot be in excess
                local targetCount = targetCategoryCounts:get(entry.key)

                if targetCount == nil then
                    logger:logWarning(
                        "Target army composition: no value for %s (0 used)",
                        entry.key)

                    targetCount = 0
                end

                local excess = entry.value - targetCount

                if excess > 0 then
                    excessCategoryCounts:set(entry.key, excess)
                end
            end
        end
    end

    logger:logDebug(
        "getUnitCategoryExcessCounts(armySuppliesCost, targetCategoryCounts): COMPLETED => %s",
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

---Removes a unit from an AI army and reimburses the AI faction of the cost of the unit.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@param unitKey string Key of the unit to remove.
---@param unitCqi integer Command queue index of the unit to remove.
local function removeUnitFromAiArmy(army, unitKey, unitCqi)
    logger:logDebug(
        "removeUnitFromAiArmy(%s, %s, %s): STARTED => %s | Unit: %s",
        function() return army:command_queue_index() end,
        unitKey,
        unitCqi,
        function() return TotoWar__Gameplay:getArmyCaption(army) end,
        function() return TotoWar__Gameplay:getUnitCaption(unitKey) end)

    local unitRealCost = cco("CcoCampaignUnit", unitCqi):Call("Cost")
    local reimbursedCost = 0

    if unitRealCost == nil then
        logger:logWarning(
            "%s: army adjusted, cost of %s not found (nothing reimbursed)",
            function() return TotoWar__Gameplay:getArmyCaption(army) end,
            function() return TotoWar__Gameplay:getUnitCaption(unitKey) end)
    elseif unitRealCost > 0 then
        cm:treasury_mod(army:faction():name(), unitRealCost)
        reimbursedCost = unitRealCost
    end

    -- cm:remove_unit_by_cqi is defined by the game (used in wh3_campaign_slaanesh_seductive_influence.lua) but missing from its documentation and from the type definitions.
    -- It does not trigger the UnitDisbanded event (verified in game). Otherwise, as the last adjustment turn of the army
    -- is already stored, the units removed here would be added to the disband queue and could then be reinstated.
    cm:remove_unit_by_cqi(unitCqi)

    logger:logInfo(
        "%s: army adjusted, disbanded %s (%s reimbursed)",
        function() return TotoWar__Gameplay:getArmyCaption(army) end,
        function() return TotoWar__Gameplay:getUnitCaption(unitKey) end,
        reimbursedCost)

    logger:logDebug(
        "removeUnitFromAiArmy(%s, %s, %s): COMPLETED => %s | Unit: %s",
        function() return army:command_queue_index() end,
        unitKey,
        unitCqi,
        function() return TotoWar__Gameplay:getArmyCaption(army) end,
        function() return TotoWar__Gameplay:getUnitCaption(unitKey) end)
end

---Adjusts an AI army by removing excess heroes and units when its cost exceeds army supplies.
---@param armyCqi integer Command queue index of the army to adjust.
local function adjustAiArmy(armyCqi)
    local army = TotoWar__Gameplay:getArmy(armyCqi)

    logger:logDebug(
        "adjustAiArmy(%s): STARTED => %s",
        armyCqi,
        function() return army ~= nil and TotoWar__Gameplay:getArmyCaption(army) or "Army not found" end)

    if army == nil or not army:has_general() then
        -- The army may have been destroyed between the recruitment of a unit and the execution of the callback
        logger:logDebug(
            "adjustAiArmy(%s): COMPLETED => %s | Army destroyed or without lord",
            armyCqi,
            function() return army ~= nil and TotoWar__Gameplay:getArmyCaption(army) or "Army not found" end)

        return
    end

    local armySuppliesCost = TotoWar_Cbac_ArmySuppliesCost.newFromArmy(true, army)

    if armySuppliesCost.availableSupplies >= 0 then
        logger:logDebug(
            "adjustAiArmy(%s): COMPLETED => %s | Total cost: %s | Available supplies: %s | Army supplies not exceeded",
            armyCqi,
            function() return TotoWar__Gameplay:getArmyCaption(army) end,
            armySuppliesCost.totalCost,
            armySuppliesCost.availableSupplies)

        return
    end

    logger:logDebug(
        "adjustAiArmy(%s): ARMY SUPPLIES EXCEEDED => %s | Total cost: %s | Available supplies: %s",
        armyCqi,
        function() return TotoWar__Gameplay:getArmyCaption(army) end,
        armySuppliesCost.totalCost,
        armySuppliesCost.availableSupplies)

    -- Sorting units from the cheapest to the priciest
    table.sort(armySuppliesCost.unitArmySuppliesCosts, compareUnitArmySuppliesCosts)

    -- Getting the target army composition and the unit categories that have excess units
    local targetArmyComposition = getTargetArmyComposition(army)
    local targetArmySize = TotoWar__Linq:sum(targetArmyComposition:getValues(), function(v) return v end)
    local unitCategoryExcessCounts = getUnitCategoryExcessCounts(armySuppliesCost, targetArmyComposition)

    if unitCategoryExcessCounts:exists(TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.hero) then
        -- Removing excess of heroes
        adjustAiArmyHeroes(
            army,
            armySuppliesCost,
            unitCategoryExcessCounts:get(TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.hero))
    end

    ---@type TotoWar_Cbac_UnitArmySuppliesCost[]
    local unitsToDiscard = {}

    -- Adjust composition and units simultaneously
    adjustAiArmyCompositionAndUnits(army, armySuppliesCost, targetArmySize, unitCategoryExcessCounts, unitsToDiscard)

    -- Removing units flagged as discardable to stay within the army supplies limit
    for index, unitToDiscard in ipairs(unitsToDiscard) do
        removeUnitFromAiArmy(army, unitToDiscard.unitKey, unitToDiscard.unitCqi)
    end

    logger:logDebug(
        "adjustAiArmy(%s): COMPLETED => %s | Total cost: %s | Available supplies: %s",
        armyCqi,
        function() return TotoWar__Gameplay:getArmyCaption(army) end,
        armySuppliesCost.totalCost,
        armySuppliesCost.availableSupplies)
end

---Indicates whether an army is an AI army whose composition is managed by the mod.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@return boolean
local function isManagedAiArmy(army)
    logger:logDebug(
        "isManagedAiArmy(army): STARTED => %s",
        function() return army ~= nil and not army:is_null_interface() and TotoWar__Gameplay:getArmyCaption(army) or "No army" end)

    local isManaged =
        army ~= nil
        and not army:is_null_interface()
        and not army:faction():is_human()
        and TotoWar__Gameplay:canRecruitUnits(army)

    logger:logDebug(
        "isManagedAiArmy(army): COMPLETED => %s | Managed: %s",
        function() return army ~= nil and not army:is_null_interface() and TotoWar__Gameplay:getArmyCaption(army) or "No army" end,
        isManaged)

    return isManaged
end

---Reacts to an army being created by an AI faction.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
local function onAiArmyCreated(army)
    logger:logDebug(
        "onAiArmyCreated(%s): STARTED => %s",
        function() return army:command_queue_index() end,
        function() return TotoWar__Gameplay:getArmyCaption(army) end)

    -- Adjusting the composition for armies spawned with units already included
    adjustAiArmy(army:command_queue_index())

    logger:logDebug(
        "onAiArmyCreated(%s): COMPLETED => %s",
        function() return army:command_queue_index() end,
        function() return TotoWar__Gameplay:getArmyCaption(army) end)
end

---Reacts to an army being destroyed.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
local function onAiArmyDestroyed(army)
    logger:logDebug(
        "onAiArmyDestroyed(%s): STARTED => %s",
        function() return army:command_queue_index() end,
        function() return TotoWar__Gameplay:getArmyCaption(army) end)

    setAiArmyData(army:command_queue_index(), nil)

    logger:logDebug(
        "onAiArmyDestroyed(%s): COMPLETED => %s",
        function() return army:command_queue_index() end,
        function() return TotoWar__Gameplay:getArmyCaption(army) end)
end

---Reacts to the turn of a character ending.
---@param character CHARACTER_SCRIPT_INTERFACE Character.
local function onAiCharacterTurnEnd(character)
    logger:logDebug(
        "onAiCharacterTurnEnd(%s): STARTED => %s | Army: %s",
        function() return character:cqi() end,
        function() return TotoWar__Gameplay:getArmyCaption(character:military_force()) end,
        function() return character:military_force():command_queue_index() end)

    -- Relaunching the army adjustment to remove heros that may have been (re)added after the army adjustement triggered when units are recruited
    adjustAiArmy(character:military_force():command_queue_index())

    logger:logDebug(
        "onAiCharacterTurnEnd(%s): COMPLETED => %s | Army: %s",
        function() return character:cqi() end,
        function() return TotoWar__Gameplay:getArmyCaption(character:military_force()) end,
        function() return character:military_force():command_queue_index() end)
end

---Reacts to a unit being converted by an AI army.
---@param originalUnit UNIT_SCRIPT_INTERFACE Unit.
---@param newUnit UNIT_SCRIPT_INTERFACE Unit.
local function onAiUnitConverted(originalUnit, newUnit)
    logger:logDebug(
        "onAiUnitConverted(%s, %s): STARTED => %s | Original unit: %s | New unit: %s | Army: %s",
        function() return originalUnit:command_queue_index() end,
        function() return newUnit:command_queue_index() end,
        function() return TotoWar__Gameplay:getArmyCaption(newUnit:military_force()) end,
        function() return TotoWar__Gameplay:getUnitCaption(originalUnit:unit_key()) end,
        function() return TotoWar__Gameplay:getUnitCaption(newUnit:unit_key()) end,
        function() return newUnit:military_force():command_queue_index() end)

    -- This is just to log how AI converts units and how it impacts the mod

    logger:logDebug(
        "onAiUnitConverted(%s, %s): COMPLETED => %s | Original unit: %s | New unit: %s | Army: %s",
        function() return originalUnit:command_queue_index() end,
        function() return newUnit:command_queue_index() end,
        function() return TotoWar__Gameplay:getArmyCaption(newUnit:military_force()) end,
        function() return TotoWar__Gameplay:getUnitCaption(originalUnit:unit_key()) end,
        function() return TotoWar__Gameplay:getUnitCaption(newUnit:unit_key()) end,
        function() return newUnit:military_force():command_queue_index() end)
end

---Manager in charge of managing the army supplies for the AI armies.
---@class TotoWar_Cbac_AiManager
TotoWar_Cbac_AiManager = {
    ---Command queue indexes of the armies for which we need to check and adjust the composition in order to comply with army supply restrictions.
    ---@type integer[]
    armyAdjustmentQueue = nil,

    ---Disbanded units, by command queue index of their army, for which we need to check whether they should be reinstated.
    ---@type TotoWar__Dictionary<integer, TotoWar_Cbac_UnitArmySuppliesCost[]>
    disbandQueue = nil
}

---Adds an army to the adjustment queue.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army to adjust.
function TotoWar_Cbac_AiManager:addArmyToAdjustmentQueue(army)
    local armyCqi = army:command_queue_index()

    logger:logDebug(
        "addArmyToAdjustmentQueue(%s): STARTED => %s",
        armyCqi,
        function() return TotoWar__Gameplay:getArmyCaption(army) end)

    if not TotoWar__Linq:any(self.armyAdjustmentQueue, function(cqi) return cqi == armyCqi end)
    then
        table.insert(self.armyAdjustmentQueue, armyCqi)

        -- Forced to delay the adjustment until all units are recruited.
        -- Disbanding units each time the unit recruitment unit was received could lead to crashes so
        -- we switched to a deferred global adjustment to fix that.
        TotoWar__Utils:delay(
            function()
                adjustAiArmy(armyCqi)
                TotoWar__Linq:remove(self.armyAdjustmentQueue, function(cqi) return cqi == armyCqi end)
            end,
            0.001)
    end

    logger:logDebug(
        "addArmyToAdjustmentQueue(%s): COMPLETED => %s",
        armyCqi,
        function() return TotoWar__Gameplay:getArmyCaption(army) end)
end

---Adds a disbanded unit to the disband queue, to reinstate it if the army has already been adjusted this turn (see `cancelDisbandIfAlreadyAdjusted`).
---@param disbandedUnit UNIT_SCRIPT_INTERFACE Disbanded unit.
function TotoWar_Cbac_AiManager:addUnitToDisbandQueue(disbandedUnit)
    local armyCqi = disbandedUnit:military_force():command_queue_index()

    logger:logDebug(
        "addUnitToDisbandQueue(%s): STARTED => %s | Unit: %s | Army: %s",
        function() return disbandedUnit:command_queue_index() end,
        function() return TotoWar__Gameplay:getArmyCaption(disbandedUnit:military_force()) end,
        function() return TotoWar__Gameplay:getUnitCaption(disbandedUnit:unit_key()) end,
        armyCqi)

    local aiArmyData = getAiArmyData(armyCqi)

    ---@type integer | nil
    local lastAdjustmentTurn = nil

    if aiArmyData ~= nil then
        lastAdjustmentTurn = aiArmyData.lastAdjustmentTurn
    end

    if lastAdjustmentTurn ~= cm:turn_number() then
        logger:logDebug(
            "addUnitToDisbandQueue(%s): COMPLETED => %s | Unit: %s | Army: %s | Disband confirmed, army not adjusted this turn (Current turn: %s | Last adjustment turn: %s)",
            function() return disbandedUnit:command_queue_index() end,
            function() return TotoWar__Gameplay:getArmyCaption(disbandedUnit:military_force()) end,
            function() return TotoWar__Gameplay:getUnitCaption(disbandedUnit:unit_key()) end,
            armyCqi,
            function() return cm:turn_number() end,
            lastAdjustmentTurn)

        return
    end

    local unitArmySuppliesCost = TotoWar_Cbac_UnitArmySuppliesCost.newUnit(disbandedUnit:unit_key())

    if self.disbandQueue:exists(armyCqi) then
        local units = self.disbandQueue:get(armyCqi)
        table.insert(units, unitArmySuppliesCost)
        self.disbandQueue:set(armyCqi, units)
    else
        self.disbandQueue:set(armyCqi, { unitArmySuppliesCost })

        -- Callback to wait for other disband events to be executed before checking whether we should reinstate the unit.
        -- Not sure it is required like for the adjustment queue but added it to be consistent.
        TotoWar__Utils:delay(
            function()
                self:cancelDisbandIfAlreadyAdjusted(armyCqi)
                self.disbandQueue:remove(armyCqi)
            end,
            0.001)
    end

    logger:logDebug(
        "addUnitToDisbandQueue(%s): COMPLETED => %s | Unit: %s | Army: %s",
        function() return disbandedUnit:command_queue_index() end,
        function() return TotoWar__Gameplay:getArmyCaption(disbandedUnit:military_force()) end,
        function() return TotoWar__Gameplay:getUnitCaption(disbandedUnit:unit_key()) end,
        armyCqi)
end

---Cancels the disband of a unit if the army it was in was already adjusted in order to comply with army supplies restrictions.
---
---Once the mod has adjusted an army during a turn, the AI may disband some of its remaining units in the same turn,
---which would undo the composition and size chosen by the mod. Units disbanded after the adjustment are therefore
---reinstated, as long as the army supplies allow it.
---@param armyCqi integer Command queue index of the army that may have been adjusted.
function TotoWar_Cbac_AiManager:cancelDisbandIfAlreadyAdjusted(armyCqi)
    local army = TotoWar__Gameplay:getArmy(armyCqi)

    logger:logDebug(
        "cancelDisbandIfAlreadyAdjusted(%s): STARTED => %s",
        armyCqi,
        function() return army ~= nil and TotoWar__Gameplay:getArmyCaption(army) or "Army not found" end)

    if army == nil or not army:has_general() then
        -- The army may have been destroyed between the disband of a unit and the execution of the callback
        logger:logDebug(
            "cancelDisbandIfAlreadyAdjusted(%s): COMPLETED => %s | Army destroyed or without lord",
            armyCqi,
            function() return army ~= nil and TotoWar__Gameplay:getArmyCaption(army) or "Army not found" end)

        return
    end

    local lord = army:general_character()

    local armySuppliesCost = TotoWar_Cbac_ArmySuppliesCost.newFromArmy(true, army)
    local disbandedUnits = self.disbandQueue:get(armyCqi)

    for index, disbandedUnit in ipairs(disbandedUnits) do
        if armySuppliesCost.availableSupplies >= disbandedUnit.armySuppliesCost then
            cm:grant_unit_to_character(
                cm:char_lookup_str(lord:cqi()),
                disbandedUnit.unitKey)
            armySuppliesCost:addUnit(disbandedUnit.unitKey)

            logger:logInfo(
                "%s: unit reinstated, %s (disbanded by the AI after the army adjustment)",
                function() return TotoWar__Gameplay:getArmyCaption(army) end,
                function() return TotoWar__Gameplay:getUnitCaption(disbandedUnit.unitKey) end)
        else
            -- In theory, we should never be in this case because the army adjustment should have removed enough units to prevent it
            logger:logInfo(
                "%s: unit not reinstated, %s (cost %s, available army supplies %s)",
                function() return TotoWar__Gameplay:getArmyCaption(army) end,
                function() return TotoWar__Gameplay:getUnitCaption(disbandedUnit.unitKey) end,
                disbandedUnit.armySuppliesCost,
                armySuppliesCost.availableSupplies)
        end
    end

    logger:logDebug(
        "cancelDisbandIfAlreadyAdjusted(%s): COMPLETED => %s",
        armyCqi,
        function() return TotoWar__Gameplay:getArmyCaption(army) end)
end

---Initializes the AI manager.
function TotoWar_Cbac_AiManager:initialize()
    logger:logDebug("initialize(): STARTED")

    self.armyAdjustmentQueue = {}
    self.disbandQueue = TotoWar__Dictionary.new()

    self:subscribeToEvents()

    logger:logDebug("initialize(): COMPLETED")
end

---Reacts to a unit being disbanded by an AI army.
---@param unit UNIT_SCRIPT_INTERFACE Unit.
function TotoWar_Cbac_AiManager:onAiUnitDisbanded(unit)
    logger:logDebug(
        "onAiUnitDisbanded(%s): STARTED => %s | Unit: %s | Army: %s",
        function() return unit:command_queue_index() end,
        function() return TotoWar__Gameplay:getArmyCaption(unit:military_force()) end,
        function() return TotoWar__Gameplay:getUnitCaption(unit:unit_key()) end,
        function() return unit:military_force():command_queue_index() end)

    self:addUnitToDisbandQueue(unit)

    logger:logDebug(
        "onAiUnitDisbanded(%s): COMPLETED => %s | Unit: %s | Army: %s",
        function() return unit:command_queue_index() end,
        function() return TotoWar__Gameplay:getArmyCaption(unit:military_force()) end,
        function() return TotoWar__Gameplay:getUnitCaption(unit:unit_key()) end,
        function() return unit:military_force():command_queue_index() end)
end

---Reacts to a unit being recruited by an AI army.
---@param unit UNIT_SCRIPT_INTERFACE Unit.
function TotoWar_Cbac_AiManager:onAiUnitRecruited(unit)
    logger:logDebug(
        "onAiUnitRecruited(%s): STARTED => %s | Unit: %s | Army: %s",
        function() return unit:command_queue_index() end,
        function() return TotoWar__Gameplay:getArmyCaption(unit:military_force()) end,
        function() return TotoWar__Gameplay:getUnitCaption(unit:unit_key()) end,
        function() return unit:military_force():command_queue_index() end)

    self:addArmyToAdjustmentQueue(unit:military_force())

    logger:logDebug(
        "onAiUnitRecruited(%s): COMPLETED => %s | Unit: %s | Army: %s",
        function() return unit:command_queue_index() end,
        function() return TotoWar__Gameplay:getArmyCaption(unit:military_force()) end,
        function() return TotoWar__Gameplay:getUnitCaption(unit:unit_key()) end,
        function() return unit:military_force():command_queue_index() end)
end

---Reacts to a unit being upgraded by an AI army.
---@param unit UNIT_SCRIPT_INTERFACE Unit.
function TotoWar_Cbac_AiManager:onAiUnitUpgraded(unit)
    logger:logDebug(
        "onAiUnitUpgraded(%s): STARTED => %s | Unit: %s | Army: %s",
        function() return unit:command_queue_index() end,
        function() return TotoWar__Gameplay:getArmyCaption(unit:military_force()) end,
        function() return TotoWar__Gameplay:getUnitCaption(unit:unit_key()) end,
        function() return unit:military_force():command_queue_index() end)

    self:addArmyToAdjustmentQueue(unit:military_force())

    logger:logDebug(
        "onAiUnitUpgraded(%s): COMPLETED => %s | Unit: %s | Army: %s",
        function() return unit:command_queue_index() end,
        function() return TotoWar__Gameplay:getArmyCaption(unit:military_force()) end,
        function() return TotoWar__Gameplay:getUnitCaption(unit:unit_key()) end,
        function() return unit:military_force():command_queue_index() end)
end

---Subscribes to events.
function TotoWar_Cbac_AiManager:subscribeToEvents()
    logger:logDebug("subscribeToEvents(): STARTED")

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_GameEvents.characterTurnEnd,
        ---@param context CharacterTurnEnd
        function(context) onAiCharacterTurnEnd(context:character()) end,
        ---@param context CharacterTurnEnd
        function(context)
            return
                TotoWar_Cbac_Mod.options.aiArmySuppliesEnabled
                and TotoWar__Gameplay:isLordCharacter(context:character())
                and context:character():has_military_force()
                and isManagedAiArmy(context:character():military_force())
        end)

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_GameEvents.militaryForceCreated,
        ---@param context TotoWar__GameEventContext_MilitaryForceCreated
        function(context) onAiArmyCreated(context:military_force_created()) end,
        ---@param context TotoWar__GameEventContext_MilitaryForceCreated
        function(context)
            return
                TotoWar_Cbac_Mod.options.aiArmySuppliesEnabled
                and isManagedAiArmy(context:military_force_created())
        end)

    -- Not depending on the option: stored data must be removed even if AI restrictions are disabled
    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_GameEvents.militaryForceDestroyed,
        ---@param context TotoWar__GameEventContext_MilitaryForceDestroyed
        function(context) onAiArmyDestroyed(context:military_force()) end,
        ---@param context TotoWar__GameEventContext_MilitaryForceDestroyed
        function(context)
            return getAiArmyData(context:military_force():command_queue_index()) ~= nil
        end)

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_GameEvents.unitConverted,
        ---@param context TotoWar__GameEventContext_UnitConverted
        function(context) onAiUnitConverted(context:unit(), context:converted_unit()) end,
        ---@param context TotoWar__GameEventContext_UnitConverted
        function(context)
            return
                TotoWar_Cbac_Mod.options.aiArmySuppliesEnabled
                and isManagedAiArmy(context:converted_unit():military_force())
        end)

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_GameEvents.unitDisbanded,
        ---@param context TotoWar__GameEventContext_UnitDisbanded
        function(context) self:onAiUnitDisbanded(context:unit()) end,
        ---@param context TotoWar__GameEventContext_UnitDisbanded
        function(context)
            return
                TotoWar_Cbac_Mod.options.aiArmySuppliesEnabled
                and isManagedAiArmy(context:unit():military_force())
        end)

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_GameEvents.unitTrained,
        ---@param context TotoWar__GameEventContext_UnitTrained
        function(context) self:onAiUnitRecruited(context:unit()) end,
        ---@param context TotoWar__GameEventContext_UnitTrained
        function(context)
            return
                TotoWar_Cbac_Mod.options.aiArmySuppliesEnabled
                and isManagedAiArmy(context:unit():military_force())
        end)

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_GameEvents.unitUpgraded,
        ---@param context TotoWar__GameEventContext_UnitUpgraded
        function(context) self:onAiUnitUpgraded(context:unit()) end,
        ---@param context TotoWar__GameEventContext_UnitUpgraded
        function(context)
            return
                TotoWar_Cbac_Mod.options.aiArmySuppliesEnabled
                and isManagedAiArmy(context:unit():military_force())
        end)

    logger:logDebug("subscribeToEvents(): COMPLETED")
end
