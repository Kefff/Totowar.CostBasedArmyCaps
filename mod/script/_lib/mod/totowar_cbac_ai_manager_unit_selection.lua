require("script._lib.mod.totowar_cbac_enum")

local logger = TotoWar__Logger.get(TotoWar_Cbac_Enum_LogCategories.aiManagerUnitSelection)

---Combination of units, stored as a linked list from the last unit added to the first one, so that adding a unit to a
---combination does not copy its units.
---@class TotoWar_Cbac_AiManagerUnitCombination
---@field experienceLevel integer Total experience level of the units of the combination.
---@field previous TotoWar_Cbac_AiManagerUnitCombination | nil Combination without its last unit (`nil` for the empty combination).
---@field unit TotoWar_Cbac_UnitArmySuppliesCost | nil Last unit added to the combination (`nil` for the empty combination).

---Group of units from which a combination can pick a limited number of units.
---@class TotoWar_Cbac_AiManagerUnitGroup
---@field maxCount integer Maximum number of units of the group in a combination.
---@field units TotoWar_Cbac_UnitArmySuppliesCost[] Units of the group.

---Combination chosen among the combinations of units, with its cost and its number of units.
---@class TotoWar_Cbac_AiManagerUnitSolution
---@field combination TotoWar_Cbac_AiManagerUnitCombination Combination.
---@field cost integer Total army supplies cost of the units of the combination.
---@field count integer Number of units of the combination.

---Selection of the units to remove from an AI army that exceeds its army supplies.
---Does not use the game: it only works on army supplies costs, so that it can be tested outside of the game.
---@class TotoWar_Cbac_AiManagerUnitSelection
TotoWar_Cbac_AiManagerUnitSelection = {}
TotoWar_Cbac_AiManagerUnitSelection.__index = TotoWar_Cbac_AiManagerUnitSelection

---Sort function ordering unit army supplies costs from the cheapest to the priciest.
---Units with the same cost are ordered by unit key, then by unit CQI, so that the units chosen by the adjustment
---do not depend on the order in which the game lists the units of the army.
---@param a TotoWar_Cbac_UnitArmySuppliesCost
---@param b TotoWar_Cbac_UnitArmySuppliesCost
---@return boolean
function TotoWar_Cbac_AiManagerUnitSelection.compareUnitArmySuppliesCosts(a, b)
    if a.armySuppliesCost ~= b.armySuppliesCost then
        return a.armySuppliesCost < b.armySuppliesCost
    end

    if a.unitKey ~= b.unitKey then
        return a.unitKey < b.unitKey
    end

    -- The unit CQI is nil for a unit being recruited, which does not occur in an AI army
    return (a.unitCqi or 0) < (b.unitCqi or 0)
end

---Indicates whether a combination of units comes before another one, to choose between two equivalent combinations
---without depending on the iteration order of `pairs`, which depends on how the game lists the units of the army.
---The units are compared from the last one added, which keeps the order of two combinations when the same unit is
---added to both of them.
---@param combination1 TotoWar_Cbac_AiManagerUnitCombination
---@param combination2 TotoWar_Cbac_AiManagerUnitCombination
---@return boolean
local function isCombinationBefore(combination1, combination2)
    while combination1.unit ~= nil and combination2.unit ~= nil do
        -- Same remaining units
        if combination1 == combination2 then
            return false
        end

        if TotoWar_Cbac_AiManagerUnitSelection.compareUnitArmySuppliesCosts(combination1.unit, combination2.unit) then
            return true
        end

        if TotoWar_Cbac_AiManagerUnitSelection.compareUnitArmySuppliesCosts(combination2.unit, combination1.unit) then
            return false
        end

        -- Never nil: only the empty combination has no previous combination, and it has no unit
        combination1 = combination1.previous --[[@as TotoWar_Cbac_AiManagerUnitCombination]]
        combination2 = combination2.previous --[[@as TotoWar_Cbac_AiManagerUnitCombination]]
    end

    return combination1.unit == nil and combination2.unit ~= nil
end

---Stores a combination of units if it is better than the combination already stored for the same number of units
---and the same cost: the combination with the least experienced units is kept, so that they are removed first.
---@param combinations table<integer, table<integer, TotoWar_Cbac_AiManagerUnitCombination>> Combinations by number of units, then by cost.
---@param count integer Number of units of the combination.
---@param cost integer Total army supplies cost of the units of the combination.
---@param combination TotoWar_Cbac_AiManagerUnitCombination Combination.
local function keepBestCombination(combinations, count, cost, combination)
    combinations[count] = combinations[count] or {}

    local existingCombination = combinations[count][cost]

    if existingCombination == nil
        or combination.experienceLevel < existingCombination.experienceLevel
        or (combination.experienceLevel == existingCombination.experienceLevel
            and isCombinationBefore(combination, existingCombination))
    then
        combinations[count][cost] = combination
    end
end

---Builds the best combinations of units that can be removed, by number of units and by cost (dynamic programming
---knapsack algorithm).
---The groups are processed one after the other: picking at most the maximum number of units of a group while
---processing it is enough to respect this maximum, without storing the number of units picked in each group.
---@param unitGroups TotoWar_Cbac_AiManagerUnitGroup[] Groups of units.
---@return table<integer, table<integer, TotoWar_Cbac_AiManagerUnitCombination>> # Best combination by number of units, then by cost.
local function buildCombinations(unitGroups)
    logger:logDebug("buildCombinations(unitGroups): STARTED => Groups: %s", #unitGroups)

    ---@type table<integer, table<integer, TotoWar_Cbac_AiManagerUnitCombination>>
    local combinations = { [0] = { [0] = { experienceLevel = 0 } } }

    for _, unitGroup in ipairs(unitGroups) do
        -- Combinations by number of units picked in the group, the combinations of the previous groups having none
        ---@type table<integer, table<integer, table<integer, TotoWar_Cbac_AiManagerUnitCombination>>>
        local combinationsByGroupCount = { [0] = combinations }
        local maxGroupCount = math.min(unitGroup.maxCount, #unitGroup.units)

        for unitIndex, unit in ipairs(unitGroup.units) do
            -- From the highest number of units picked in the group to the lowest, so that each unit is added at most
            -- once to a combination: the combinations updated for this unit have already been processed
            for groupCount = math.min(unitIndex, maxGroupCount) - 1, 0, -1 do
                combinationsByGroupCount[groupCount + 1] = combinationsByGroupCount[groupCount + 1] or {}

                for count, combinationsByCost in pairs(combinationsByGroupCount[groupCount]) do
                    for cost, combination in pairs(combinationsByCost) do
                        keepBestCombination(
                            combinationsByGroupCount[groupCount + 1],
                            count + 1,
                            cost + unit.armySuppliesCost,
                            {
                                experienceLevel = combination.experienceLevel + unit.experienceLevel,
                                previous = combination,
                                unit = unit
                            })
                    end
                end
            end
        end

        combinations = {}

        for groupCount = 0, maxGroupCount, 1 do
            for count, combinationsByCost in pairs(combinationsByGroupCount[groupCount] or {}) do
                for cost, combination in pairs(combinationsByCost) do
                    keepBestCombination(combinations, count, cost, combination)
                end
            end
        end
    end

    logger:logDebug(
        "buildCombinations(unitGroups): COMPLETED => Groups: %s | Combinations: %s",
        #unitGroups,
        function()
            local combinationCount = 0

            for _, combinationsByCost in pairs(combinations) do
                for _ in pairs(combinationsByCost) do
                    combinationCount = combinationCount + 1
                end
            end

            return combinationCount
        end)

    return combinations
end

---Gets the units of a combination, in the order in which they were added.
---@param combination TotoWar_Cbac_AiManagerUnitCombination Combination.
---@return TotoWar_Cbac_UnitArmySuppliesCost[]
local function getCombinationUnits(combination)
    ---@type TotoWar_Cbac_UnitArmySuppliesCost[]
    local units = {}

    while combination.unit ~= nil do
        table.insert(units, 1, combination.unit)

        -- Never nil: only the empty combination has no previous combination, and it has no unit
        combination = combination.previous --[[@as TotoWar_Cbac_AiManagerUnitCombination]]
    end

    return units
end

---Indicates whether a solution is better than another one:
---
---COMPLETE solutions (cost >= deficit), always better than partial solutions:
---1) closest to the target number of units
---2) fewer units
---3) minimal cost above deficit
---4) minimal total experience level
---5) first combination (isCombinationBefore)
---
---PARTIAL solutions (cost < deficit):
---1) maximal cost (closest below deficit)
---2) closest to the target number of units
---3) fewer units
---4) minimal total experience level
---5) first combination (isCombinationBefore)
---
---The last criterion makes the choice independent of the iteration order of `pairs`.
---@param solution1 TotoWar_Cbac_AiManagerUnitSolution
---@param solution2 TotoWar_Cbac_AiManagerUnitSolution
---@param deficit integer Army supplies to recover.
---@param targetCount integer Target number of units.
---@return boolean
local function isSolutionBetter(solution1, solution2, deficit, targetCount)
    local isComplete1 = solution1.cost >= deficit
    local isComplete2 = solution2.cost >= deficit

    if isComplete1 ~= isComplete2 then
        return isComplete1
    end

    if not isComplete1 and solution1.cost ~= solution2.cost then
        return solution1.cost > solution2.cost
    end

    local distance1 = math.abs(solution1.count - targetCount)
    local distance2 = math.abs(solution2.count - targetCount)

    if distance1 ~= distance2 then
        return distance1 < distance2
    end

    if solution1.count ~= solution2.count then
        return solution1.count < solution2.count
    end

    if isComplete1 and solution1.cost ~= solution2.cost then
        return solution1.cost < solution2.cost
    end

    if solution1.combination.experienceLevel ~= solution2.combination.experienceLevel then
        return solution1.combination.experienceLevel < solution2.combination.experienceLevel
    end

    return isCombinationBefore(solution1.combination, solution2.combination)
end

---Chooses the best solution among combinations of units (see `isSolutionBetter`).
---@param combinations table<integer, table<integer, TotoWar_Cbac_AiManagerUnitCombination>> Combinations by number of units, then by cost.
---@param deficit integer Army supplies to recover.
---@param targetCount integer Target number of units.
---@param isPartialAllowed boolean Indicates whether a solution that does not cover the deficit can be chosen.
---@return TotoWar_Cbac_AiManagerUnitSolution | nil # `nil` when no solution can be chosen.
local function chooseSolution(combinations, deficit, targetCount, isPartialAllowed)
    ---@type TotoWar_Cbac_AiManagerUnitSolution | nil
    local bestSolution = nil

    for count, combinationsByCost in pairs(combinations) do
        for cost, combination in pairs(combinationsByCost) do
            if isPartialAllowed or cost >= deficit then
                ---@type TotoWar_Cbac_AiManagerUnitSolution
                local solution = { combination = combination, cost = cost, count = count }

                if bestSolution == nil or isSolutionBetter(solution, bestSolution, deficit, targetCount) then
                    bestSolution = solution
                end
            end
        end
    end

    return bestSolution
end

---Selects the units to remove from an army to cover an army supplies deficit.
---
---The units of the categories in excess are chosen first, no more than the excess of their category, as close as
---possible to the number of units to remove to reach the target army size. If they do not cover the deficit, the
---other units complete them, only if they can cover the remaining deficit.
---@param removableUnits TotoWar_Cbac_UnitArmySuppliesCost[] Units that can be removed (neither lords nor heroes).
---@param categoryExcessCounts table<string, integer> Number of units in excess by unit category.
---@param deficit integer Army supplies to recover.
---@param targetRemovalCount integer Number of units to remove to reach the target army size.
---@return TotoWar_Cbac_UnitArmySuppliesCost[] excessUnitsToRemove Units of the categories in excess to remove.
---@return TotoWar_Cbac_UnitArmySuppliesCost[] otherUnitsToRemove Other units to remove.
---@return integer removedCost Total army supplies cost of the units to remove.
function TotoWar_Cbac_AiManagerUnitSelection:selectUnitsToRemove(
    removableUnits,
    categoryExcessCounts,
    deficit,
    targetRemovalCount
)
    logger:logDebug(
        "selectUnitsToRemove(removableUnits, categoryExcessCounts, %s, %s): STARTED => Removable units: %s",
        deficit,
        targetRemovalCount,
        #removableUnits)

    -- Grouping the units of the categories in excess by category, the other units in a group without maximum
    ---@type table<string, TotoWar_Cbac_UnitArmySuppliesCost[]>
    local excessUnitsByCategory = {}

    ---@type TotoWar_Cbac_UnitArmySuppliesCost[]
    local otherUnits = {}

    for _, unit in ipairs(removableUnits) do
        if (categoryExcessCounts[unit.unitCategory] or 0) > 0 then
            excessUnitsByCategory[unit.unitCategory] = excessUnitsByCategory[unit.unitCategory] or {}
            table.insert(excessUnitsByCategory[unit.unitCategory], unit)
        else
            table.insert(otherUnits, unit)
        end
    end

    -- Categories in excess without removable units (heroes) are ignored. The categories and the units are sorted,
    -- so that the combinations built do not depend on the order in which the game lists the units of the army.
    ---@type string[]
    local excessCategories = {}

    for category, _ in pairs(excessUnitsByCategory) do
        table.insert(excessCategories, category)
    end

    table.sort(excessCategories)

    ---@type TotoWar_Cbac_AiManagerUnitGroup[]
    local excessUnitGroups = {}

    for _, category in ipairs(excessCategories) do
        table.sort(excessUnitsByCategory[category], TotoWar_Cbac_AiManagerUnitSelection.compareUnitArmySuppliesCosts)
        table.insert(excessUnitGroups, {
            maxCount = categoryExcessCounts[category],
            units = excessUnitsByCategory[category]
        })
    end

    table.sort(otherUnits, TotoWar_Cbac_AiManagerUnitSelection.compareUnitArmySuppliesCosts)

    -- Choosing the units of the categories in excess. The empty combination is always available as a partial solution.
    local excessSolution = chooseSolution(buildCombinations(excessUnitGroups), deficit, targetRemovalCount, true)
    ---@cast excessSolution TotoWar_Cbac_AiManagerUnitSolution

    local excessUnitsToRemove = getCombinationUnits(excessSolution.combination)
    local removedCost = excessSolution.cost

    ---@type TotoWar_Cbac_UnitArmySuppliesCost[]
    local otherUnitsToRemove = {}

    -- Completing with the other units if the deficit is not covered
    if removedCost < deficit and #otherUnits > 0 then
        local otherSolution = chooseSolution(
            buildCombinations({ { maxCount = #otherUnits, units = otherUnits } }),
            deficit - removedCost,
            math.max(0, targetRemovalCount - excessSolution.count),
            false)

        if otherSolution ~= nil then
            otherUnitsToRemove = getCombinationUnits(otherSolution.combination)
            removedCost = removedCost + otherSolution.cost
        end
    end

    logger:logDebug(
        "selectUnitsToRemove(removableUnits, categoryExcessCounts, %s, %s): COMPLETED => Excess units to remove: %s | Other units to remove: %s | Removed cost: %s",
        deficit,
        targetRemovalCount,
        #excessUnitsToRemove,
        #otherUnitsToRemove,
        removedCost)

    return excessUnitsToRemove, otherUnitsToRemove, removedCost
end
