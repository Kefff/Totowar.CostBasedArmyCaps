-- Tests of TotoWar_Cbac_AiManagerUnitSelection (selection of the units to remove from an AI army).
--
-- Runs outside of the game with any Lua interpreter (5.1 to 5.4), from any directory:
--   lua tests/totowar_cbac_ai_manager_unit_selection_tests.lua
-- or with the interpreter of the Lua extension of VS Code:
--   lua-language-server tests/totowar_cbac_ai_manager_unit_selection_tests.lua
--
-- The random tests compare the selection with a brute-force selection that enumerates every subset of units.

local scriptPath = debug.getinfo(1, "S").source:gsub("^@", ""):gsub("\\", "/")
local repositoryPath = scriptPath:match("^(.*)/tests/[^/]*$") or "."

package.path = repositoryPath .. "/mod/?.lua;" .. package.path

-- Stubs of the game and of the TotoWar libraries used by the tested file
local loggerStub = {
    logDebug = function() end,
    logError = function() end,
    logInfo = function() end,
    logWarning = function() end
}
TotoWar__Logger = { get = function() return loggerStub end }

-- `unpack` of Lua 5.1 (used by the game), moved to `table.unpack` from Lua 5.2
---@diagnostic disable-next-line: deprecated
unpack = unpack or table.unpack

dofile(repositoryPath .. "/mod/script/_lib/mod/totowar_cbac_ai_manager_unit_selection.lua")

local compareUnits = TotoWar_Cbac_AiManagerUnitSelection.compareUnitArmySuppliesCosts

-------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------

local nextUnitCqi = 1

---Creates a unit army supplies cost.
local function newUnit(unitKey, armySuppliesCost, unitCategory, experienceLevel)
    nextUnitCqi = nextUnitCqi + 1

    return {
        armySuppliesCost = armySuppliesCost,
        experienceLevel = experienceLevel or 0,
        unitCategory = unitCategory,
        unitCqi = nextUnitCqi,
        unitKey = unitKey
    }
end

---Gets the CQIs of units, sorted, to compare selections whatever the order of their units.
local function getSortedCqis(units)
    local cqis = {}

    for _, unit in ipairs(units) do
        table.insert(cqis, unit.unitCqi)
    end

    table.sort(cqis)

    return table.concat(cqis, ",")
end

local function shuffle(list)
    local shuffledList = {}

    for i, item in ipairs(list) do
        table.insert(shuffledList, math.random(1, i), item)
    end

    return shuffledList
end

local function assertEquals(expected, actual, message)
    if expected ~= actual then
        error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)), 2)
    end
end

local function select(units, categoryExcessCounts, deficit, targetRemovalCount)
    return TotoWar_Cbac_AiManagerUnitSelection:selectUnitsToRemove(
        units,
        categoryExcessCounts,
        deficit,
        targetRemovalCount)
end

-------------------------------------------------------------------------
-- Brute-force selection, written from the documented rules of the selection
-------------------------------------------------------------------------

---Indicates whether a combination comes before another one: units compared in the reverse order in which they are
---added (categories in excess sorted by name, then units sorted in each category), the smaller combination first.
local function isBruteForceCombinationBefore(units1, units2)
    local index1 = #units1
    local index2 = #units2

    while index1 > 0 and index2 > 0 do
        if compareUnits(units1[index1], units2[index2]) then
            return true
        end

        if compareUnits(units2[index2], units1[index1]) then
            return false
        end

        index1 = index1 - 1
        index2 = index2 - 1
    end

    return index1 == 0 and index2 > 0
end

local function isBruteForceSolutionBetter(solution1, solution2, deficit, targetCount)
    local isComplete1 = solution1.cost >= deficit
    local isComplete2 = solution2.cost >= deficit

    if isComplete1 ~= isComplete2 then
        return isComplete1
    end

    local keys1
    local keys2

    if isComplete1 then
        keys1 = { math.abs(#solution1.units - targetCount), #solution1.units, solution1.cost, solution1.experienceLevel }
        keys2 = { math.abs(#solution2.units - targetCount), #solution2.units, solution2.cost, solution2.experienceLevel }
    else
        keys1 = { -solution1.cost, math.abs(#solution1.units - targetCount), #solution1.units, solution1.experienceLevel }
        keys2 = { -solution2.cost, math.abs(#solution2.units - targetCount), #solution2.units, solution2.experienceLevel }
    end

    for i = 1, #keys1 do
        if keys1[i] ~= keys2[i] then
            return keys1[i] < keys2[i]
        end
    end

    return isBruteForceCombinationBefore(solution1.units, solution2.units)
end

---Enumerates the subsets of units (kept in the order of the list) that respect the maximum count of each category,
---and returns the best one.
local function bruteForceChoose(units, maxCountByCategory, deficit, targetCount, isPartialAllowed)
    local bestSolution = nil
    local picked = {}
    local countByCategory = {}

    local function enumerate(index, cost, experienceLevel)
        if index > #units then
            if isPartialAllowed or cost >= deficit then
                local solution = { units = { unpack(picked) }, cost = cost, experienceLevel = experienceLevel }

                if bestSolution == nil or isBruteForceSolutionBetter(solution, bestSolution, deficit, targetCount) then
                    bestSolution = solution
                end
            end

            return
        end

        local unit = units[index]

        enumerate(index + 1, cost, experienceLevel)

        local categoryCount = countByCategory[unit.unitCategory] or 0

        if maxCountByCategory == nil or categoryCount < maxCountByCategory[unit.unitCategory] then
            table.insert(picked, unit)
            countByCategory[unit.unitCategory] = categoryCount + 1
            enumerate(index + 1, cost + unit.armySuppliesCost, experienceLevel + unit.experienceLevel)
            countByCategory[unit.unitCategory] = categoryCount
            table.remove(picked)
        end
    end

    enumerate(1, 0, 0)

    return bestSolution
end

local function bruteForceSelect(units, categoryExcessCounts, deficit, targetRemovalCount)
    local excessUnits = {}
    local otherUnits = {}

    for _, unit in ipairs(units) do
        if (categoryExcessCounts[unit.unitCategory] or 0) > 0 then
            table.insert(excessUnits, unit)
        else
            table.insert(otherUnits, unit)
        end
    end

    -- Order in which the selection adds the units to the combinations
    table.sort(excessUnits, function(a, b)
        if a.unitCategory ~= b.unitCategory then
            return a.unitCategory < b.unitCategory
        end

        return compareUnits(a, b)
    end)
    table.sort(otherUnits, compareUnits)

    -- The empty subset is always available as a partial solution
    local excessSolution = bruteForceChoose(excessUnits, categoryExcessCounts, deficit, targetRemovalCount, true)
    ---@cast excessSolution -nil
    local otherUnitsToRemove = {}
    local removedCost = excessSolution.cost

    if removedCost < deficit and #otherUnits > 0 then
        local otherSolution = bruteForceChoose(
            otherUnits,
            nil,
            deficit - removedCost,
            math.max(0, targetRemovalCount - #excessSolution.units),
            false)

        if otherSolution ~= nil then
            otherUnitsToRemove = otherSolution.units
            removedCost = removedCost + otherSolution.cost
        end
    end

    return excessSolution.units, otherUnitsToRemove, removedCost
end

-------------------------------------------------------------------------
-- Tests
-------------------------------------------------------------------------

local tests = {}

tests["Removes the unit of a category in excess that covers the deficit at the lowest cost"] = function()
    local unit1 = newUnit("cav_1", 300, "cavalryAndMonsters")
    local unit2 = newUnit("cav_2", 500, "cavalryAndMonsters")
    local unit3 = newUnit("cav_3", 900, "cavalryAndMonsters")

    local excessUnits, otherUnits, removedCost = select({ unit1, unit2, unit3 }, { cavalryAndMonsters = 1 }, 400, 0)

    assertEquals(getSortedCqis({ unit2 }), getSortedCqis(excessUnits), "Excess units")
    assertEquals(0, #otherUnits, "Other units")
    assertEquals(500, removedCost, "Removed cost")
end

tests["Removes no more units of a category than its excess, then completes with the other units"] = function()
    local cavalry1 = newUnit("cav", 100, "cavalryAndMonsters")
    local cavalry2 = newUnit("cav", 100, "cavalryAndMonsters")
    local infantry = newUnit("inf", 300, "meleeInfantry")

    local excessUnits, otherUnits, removedCost = select(
        { cavalry1, cavalry2, infantry },
        { cavalryAndMonsters = 1 },
        250,
        0)

    assertEquals(1, #excessUnits, "Excess units")
    assertEquals(getSortedCqis({ infantry }), getSortedCqis(otherUnits), "Other units")
    assertEquals(400, removedCost, "Removed cost")
end

tests["Removes the number of units closest to the number needed to reach the target army size"] = function()
    local unit1 = newUnit("cav_1", 100, "cavalryAndMonsters")
    local unit2 = newUnit("cav_2", 120, "cavalryAndMonsters")
    local unit3 = newUnit("cav_3", 300, "cavalryAndMonsters")
    local units = { unit1, unit2, unit3 }

    local excessUnits = select(units, { cavalryAndMonsters = 3 }, 250, 0)
    assertEquals(getSortedCqis({ unit3 }), getSortedCqis(excessUnits), "Without target army size")

    excessUnits = select(units, { cavalryAndMonsters = 3 }, 250, 2)
    assertEquals(getSortedCqis({ unit1, unit3 }), getSortedCqis(excessUnits), "With 2 units to remove")
end

tests["Removes the least experienced unit between equivalent units"] = function()
    local experiencedUnit = newUnit("cav", 300, "cavalryAndMonsters", 3)
    local inexperiencedUnit = newUnit("cav", 300, "cavalryAndMonsters", 0)

    local excessUnits = select({ experiencedUnit, inexperiencedUnit }, { cavalryAndMonsters = 1 }, 300, 0)

    assertEquals(getSortedCqis({ inexperiencedUnit }), getSortedCqis(excessUnits), "Excess units")
end

tests["Completes with the number of other units closest to the number of units still to remove"] = function()
    -- Two units of 50 cover the deficit exactly with the 2 units to remove: removing the unit of 100 and a unit of
    -- 50 would also remove 2 units, but 150 army supplies
    local unit100 = newUnit("inf_100", 100, "meleeInfantry")
    local unit50a = newUnit("inf_50", 50, "meleeInfantry")
    local unit50b = newUnit("inf_50", 50, "meleeInfantry")

    local excessUnits, otherUnits, removedCost = select({ unit100, unit50a, unit50b }, {}, 100, 2)

    assertEquals(0, #excessUnits, "Excess units")
    assertEquals(getSortedCqis({ unit50a, unit50b }), getSortedCqis(otherUnits), "Other units")
    assertEquals(100, removedCost, "Removed cost")
end

tests["Does not remove other units when they cannot cover the remaining deficit"] = function()
    local cavalry = newUnit("cav", 100, "cavalryAndMonsters")
    local infantry = newUnit("inf", 50, "meleeInfantry")

    local excessUnits, otherUnits, removedCost = select({ cavalry, infantry }, { cavalryAndMonsters = 1 }, 1000, 0)

    assertEquals(getSortedCqis({ cavalry }), getSortedCqis(excessUnits), "Excess units")
    assertEquals(0, #otherUnits, "Other units")
    assertEquals(100, removedCost, "Removed cost")
end

tests["Ignores the categories in excess without removable units"] = function()
    local cavalry = newUnit("cav", 200, "cavalryAndMonsters")

    local excessUnits, otherUnits, removedCost = select({ cavalry }, { cavalryAndMonsters = 1, hero = 2 }, 150, 3)

    assertEquals(getSortedCqis({ cavalry }), getSortedCqis(excessUnits), "Excess units")
    assertEquals(0, #otherUnits, "Other units")
    assertEquals(200, removedCost, "Removed cost")
end

tests["Same selection as the brute-force selection, whatever the order of the units (random armies)"] = function()
    local categories = { "cavalryAndMonsters", "meleeInfantry", "rangedInfantry", "warMachines" }
    local costs = { 100, 150, 200, 250, 300, 450, 600, 900 }

    math.randomseed(20261115)

    for armyIndex = 1, 500 do
        local units = {}

        for _ = 1, math.random(1, 12) do
            local cost = costs[math.random(1, #costs)]
            local category = categories[math.random(1, #categories)]

            -- Few unit keys per cost, so that units only differing by their CQI are frequent
            table.insert(units, newUnit(category .. "_" .. cost .. "_" .. math.random(1, 2), cost, category,
                math.random(0, 2)))
        end

        local categoryExcessCounts = {}

        for _, category in ipairs(categories) do
            if math.random() < 0.5 then
                categoryExcessCounts[category] = math.random(1, 3)
            end
        end

        local deficit = math.random(1, 2500)
        local targetRemovalCount = math.random(0, 5)
        local context = string.format("Army %s (deficit: %s, target removal count: %s)", armyIndex, deficit,
            targetRemovalCount)

        local expectedExcessUnits, expectedOtherUnits, expectedRemovedCost = bruteForceSelect(
            units, categoryExcessCounts, deficit, targetRemovalCount)
        local excessUnits, otherUnits, removedCost = select(
            shuffle(units), categoryExcessCounts, deficit, targetRemovalCount)

        assertEquals(getSortedCqis(expectedExcessUnits), getSortedCqis(excessUnits), context .. ", excess units")
        assertEquals(getSortedCqis(expectedOtherUnits), getSortedCqis(otherUnits), context .. ", other units")
        assertEquals(expectedRemovedCost, removedCost, context .. ", removed cost")
    end
end

-------------------------------------------------------------------------
-- Runner
-------------------------------------------------------------------------

local testNames = {}

for testName, _ in pairs(tests) do
    table.insert(testNames, testName)
end

table.sort(testNames)

local failureCount = 0

for _, testName in ipairs(testNames) do
    local isSuccess, errorMessage = pcall(tests[testName])

    if isSuccess then
        print("[OK]   " .. testName)
    else
        failureCount = failureCount + 1
        print("[FAIL] " .. testName .. "\n       " .. tostring(errorMessage))
    end
end

print(string.format("%s test(s), %s failure(s)", #testNames, failureCount))

if failureCount > 0 then
    error("Tests failed", 0)
end
