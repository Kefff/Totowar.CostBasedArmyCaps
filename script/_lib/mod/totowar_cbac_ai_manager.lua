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
    local deficit = -armySuppliesCost.availableSupplies

    TotoWarCbac.loggers.aiManager:logDebug(
        "adjustAiArmyCompositionAndUnits(%s from %s): Removable units: %s | Target army size: %s | Current army size: %s | Required removals for size: %s | Deficit: %s",
        function() return TotoWar.utils:getCharacterCaption(lord) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return #removableUnits end,
        function() return targetArmySize end,
        function() return currentArmySize end,
        function() return requiredRemovalsForSize end,
        function() return deficit end)

    -- Dynamic programming knapsack:
    -- We select a subset of removable units to remove such that:
    -- - removedCost >= deficit
    -- - removedCount == requiredRemovalsForSize (if requiredRemovalsForSize > 0)
    -- - removedCategoryCount[cat] >= unitCategoryExcessCounts[cat]
    -- and removedCost is minimal above deficit.

    -- Build minimum removal requirements per category (only those > 0)
    ---@type table<string, integer>
    local minReq = {}

    for cat, count in pairs(unitCategoryExcessCounts) do
        if count ~= nil and count > 0 then
            minReq[cat] = count
        end
    end

    -- If no size constraint is required, we still want to remove as few units as possible.
    -- We'll solve it by allowing up to maxRemovals = #removableUnits, but we will pick the
    -- best solution with the smallest number of removals.
    local exactRemovalCount = requiredRemovalsForSize > 0
    local maxRemovals = requiredRemovalsForSize

    if not exactRemovalCount then
        maxRemovals = #removableUnits
    end

    -- Clamp maxRemovals to available units
    maxRemovals = math.min(maxRemovals, #removableUnits)

    if maxRemovals <= 0 then
        return
    end

    -- Sort removable units by increasing cost (helps with pruning + debugging)
    table.sort(removableUnits, function(a, b)
        return a.armySuppliesCost < b.armySuppliesCost
    end)

    ---@type string[]
    local categories = {}

    for cat, _ in pairs(minReq) do
        table.insert(categories, cat)
    end

    table.sort(categories)

    local finalKey = TotoWarCbacAiManagerAdjustmentSelection.getFinalKey(categories, minReq)

    TotoWarCbac.loggers.aiManager:logDebug(
        "adjustAiArmyCompositionAndUnits(%s from %s): Categories: %s | Min required count: %s | Final key: %s",
        function() return TotoWar.utils:getCharacterCaption(lord) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function()
            if #categories == 0 then
                return "none"
            end

            return table.concat(categories, ",")
        end,
        function()
            local total = 0
            for _, count in pairs(minReq) do
                total = total + count
            end

            return total
        end,
        function() return finalKey end)

    -- Bound the DP cost space to avoid explosion:
    -- We only care about reaching deficit, so we cap costs at deficit + margin.
    -- Margin = sum of the biggest unit costs we might remove.
    local biggestCosts = {}

    for _, u in ipairs(removableUnits) do
        table.insert(biggestCosts, u.armySuppliesCost)
    end

    table.sort(biggestCosts, function(a, b) return a > b end)

    local margin = 0

    for i = 1, math.min(maxRemovals, #biggestCosts) do
        margin = margin + biggestCosts[i]
    end

    local maxCost = deficit + margin

    -- DP[removedCount][stateKey][removedCost] = pickedUnits
    ---@type table<integer, table<string, table<integer, TotoWarCbacUnitArmySuppliesCost[]>>>
    local DP = {}
    DP[0] = {}

    local startState = TotoWarCbacAiManagerAdjustmentSelection.new(categories, minReq)
    local startKey = startState:getKey()

    DP[0][startKey] = {}
    DP[0][startKey][0] = {}

    -- Main DP loop (0/1 knapsack, so iterate counts backwards)
    for _, unit in ipairs(removableUnits) do
        for removedCount = maxRemovals - 1, 0, -1 do
            if DP[removedCount] then
                DP[removedCount + 1] = DP[removedCount + 1] or {}

                for stateKey, costTable in pairs(DP[removedCount]) do
                    local baseState = TotoWarCbacAiManagerAdjustmentSelection.newFromKey(stateKey, categories, minReq)

                    for removedCost, picked in pairs(costTable) do
                        local newCost = removedCost + unit.armySuppliesCost

                        if newCost <= maxCost then
                            local newState = baseState:clone()
                            ---@diagnostic disable-next-line: param-type-mismatch
                            newState:add(unit.unitCategory)

                            local newKey = newState:getKey()

                            DP[removedCount + 1][newKey] = DP[removedCount + 1][newKey] or {}

                            -- Only store if this exact cost doesn't exist yet.
                            -- (We don't need to compare, because for a fixed cost the picked set is irrelevant,
                            --  but we store one valid set for reconstruction.)
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

    -- Find best solution:
    -- - If exactRemovalCount: only look at DP[requiredRemovalsForSize]
    -- - Else: scan all DP[k] and prefer smaller k, then minimal cost above deficit
    local bestPicked = nil
    local bestCost = nil
    local bestRemovalCount = nil

    local function considerSolutions(k)
        if not DP[k] or not DP[k][finalKey] then
            return
        end

        for cost, picked in pairs(DP[k][finalKey]) do
            if cost >= deficit then
                if bestCost == nil
                    or k < bestRemovalCount
                    or (k == bestRemovalCount and cost < bestCost)
                then
                    bestCost = cost
                    bestPicked = picked
                    bestRemovalCount = k
                end
            end
        end
    end

    if exactRemovalCount then
        considerSolutions(requiredRemovalsForSize)
    else
        for k = 1, maxRemovals do
            considerSolutions(k)
        end
    end

    if not bestPicked then
        TotoWarCbac.loggers.aiManager:logDebug(
            "adjustAiArmyCompositionAndUnits(%s from %s): No valid subset found (deficit: %s, removals: %s)",
            function() return TotoWar.utils:getCharacterCaption(lord) end,
            function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
            function() return deficit end,
            function() return requiredRemovalsForSize end)

        return
    end

    local removedUnitsSummary = {}

    for _, u in ipairs(bestPicked) do
        table.insert(removedUnitsSummary, string.format("%s=%s", u.unitKey, u.armySuppliesCost))
    end

    TotoWarCbac.loggers.aiManager:logDebug(
        "adjustAiArmyCompositionAndUnits(%s from %s): Best subset: %s | Removed count: %s | Removed cost: %s | Deficit: %s",
        function() return TotoWar.utils:getCharacterCaption(lord) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return table.concat(removedUnitsSummary, ", ") end,
        function() return #bestPicked end,
        function() return bestCost end,
        function() return deficit end)

    -- Apply result: mark units to discard + update armySuppliesCost immediately
    table.sort(bestPicked, function(a, b)
        return a.armySuppliesCost > b.armySuppliesCost
    end)

    for _, u in ipairs(bestPicked) do
        table.insert(unitsToDiscard, u)
        armySuppliesCost:removeUnit(u.unitKey)
    end

    TotoWarCbac.loggers.aiManager:logDebug(
        "adjustAiArmyCompositionAndUnits(%s from %s): Selected removals: %s | RemovedCost: %s | Deficit: %s",
        function() return TotoWar.utils:getCharacterCaption(lord) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return bestRemovalCount end,
        function() return bestCost end,
        function() return deficit end)

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
            0.05)
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

    cm:remove_unit_from_character(cm:char_lookup_str(army:general_character()), unitKey)

    TotoWarCbac.loggers.aiManager:logDebug(
        "removeUnitFromAiArmy(%s from %s, %s, %s): COMPLETED",
        function() return TotoWar.utils:getCharacterCaption(army:general_character()) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(unitKey) end,
        function() return unitCqi end)
end
