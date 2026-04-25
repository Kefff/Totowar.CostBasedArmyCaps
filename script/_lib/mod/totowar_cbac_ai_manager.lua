---Manager in charge of managing the army supplies for the AI armies.
---@class TotoWarCbacAiManager
TotoWarCbacAiManager = {}
TotoWarCbacAiManager.__index = TotoWarCbacAiManager

---Initializes a new instance.
---@return TotoWarCbacAiManager
function TotoWarCbacAiManager.new()
    TotoWarCbac.loggers.aiManager:logDebug("new(): STARTED")

    local instance = setmetatable({}, TotoWarCbacAiManager)

    TotoWarCbac.loggers.aiManager:logDebug("new(): COMPLETED")

    return instance
end

---Adds listeners for events.
function TotoWarCbacAiManager:addListeners()
    TotoWarCbac.loggers.aiManager:logDebug("addListeners(): STARTED")

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
            self:onAiUnitDisbanded(context:unit():military_force(), context:unit())
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
            self:onAiUnitRecruited(context:unit():military_force(), context:unit())
        end)

    TotoWarCbac.loggers.aiManager:logDebug("addListeners(): COMPLETED")
end

---Adjusts an AI army by removing excess agents and units when its cost exceeds army supplies.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@param lastRecruitedUnit UNIT_SCRIPT_INTERFACE Last unit recruited.
function TotoWarCbacAiManager:adjustAiArmy(army, lastRecruitedUnit)
    local armySuppliesCost = TotoWarCbacArmySuppliesCost.newFromArmy(TotoWarCbac.options.aiArmySuppliesAmount, army)

    if armySuppliesCost.availableSupplies >= 0 then
        return
    end

    TotoWarCbac.loggers.aiManager:logDebug(
        "adjustAiArmy(%s from %s, %s): STARTED => Total army supplies cost: %s | Available army supplies: %s",
        function() return TotoWar.utils:getCharacterCaption(army:general_character()) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(lastRecruitedUnit:unit_key()) end,
        function() return armySuppliesCost.totalCost end,
        function() return armySuppliesCost.availableSupplies end)

    -- Sorting units from the cheapest to the priciest
    table.sort(
        armySuppliesCost.unitArmySuppliesCosts,
        function(a, b)
            return a.armySuppliesCost < b.armySuppliesCost
        end)

    -- Removing excess of agents
    self:adjustAiArmyAgents(army, armySuppliesCost)

    ---@type TotoWarCbacUnitArmySuppliesCost[]
    local unitsToDiscard = {}

    -- Adding to the list of units to remove the cheapest units of categories that have too many units
    self:adjustAiArmyComposition(army, armySuppliesCost, unitsToDiscard)

    -- Adding to the list of units to remove the cheapest units to pass under the maximum army supplies cost
    self:adjustAiArmyUnits(army, armySuppliesCost, unitsToDiscard, lastRecruitedUnit)

    if armySuppliesCost.availableSupplies < 0 then
        -- Removing only the last recruited unit if we could not find other units to remove to stay within the army supplies limit
        armySuppliesCost:removeUnit(lastRecruitedUnit:unit_key())
        self:removeUnitFromAiArmy(army, lastRecruitedUnit:unit_key(), lastRecruitedUnit:command_queue_index())
    else
        -- Removing units flagged as discardable to stay within the army supplies limit
        for index, unitToDiscard in ipairs(unitsToDiscard) do
            self:removeUnitFromAiArmy(army, unitToDiscard.unitKey, unitToDiscard.cqi)
        end
    end

    TotoWarCbac.loggers.aiManager:logDebug(
        "adjustAiArmy(%s from %s, %s): COMPLETED => Total army supplies cost: %s | Available army supplies: %s",
        function() return TotoWar.utils:getCharacterCaption(army:general_character()) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(lastRecruitedUnit:unit_key()) end,
        function() return armySuppliesCost.totalCost end,
        function() return armySuppliesCost.availableSupplies end)
end

---Adjusts the amount of agents in an army if it exceeds the limit.
---
---Duplicate agent types are removed first.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@param armySuppliesCost TotoWarCbacArmySuppliesCost Army supplies cost of the army. Updated if agents are removed.
function TotoWarCbacAiManager:adjustAiArmyAgents(army, armySuppliesCost)
    local agents = TotoWar.utils:linqWhere(
        armySuppliesCost.unitArmySuppliesCosts,
        function(unit) return TotoWar.utils:isAgentUnit(unit.cqi) end)
    local agentsToRemoveAmount = #agents - TotoWarCbac.options.aiArmyAgentMaximumAmount

    if agentsToRemoveAmount <= 0 then
        return
    end

    local general = army:general_character()

    TotoWarCbac.loggers.aiManager:logDebug(
        "adjustAiArmyAgents(%s from %s): STARTED => Total army supplies cost: %s | Available army supplies: %s",
        function() return TotoWar.utils:getCharacterCaption(general) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return armySuppliesCost.totalCost end,
        function() return armySuppliesCost.availableSupplies end)

    -- Grouping agents by their base type to ignore their mount
    local agentUnitGroups = TotoWar.utils:linqGroupBy(agents, function(a) return a.baseUnitKey end)

    while agentsToRemoveAmount > 0 do
        -- Finding the group of agents with the most agents (or the last agent group when they all have the same amount of agents)
        ---@type string
        local agentGroupKey
        local agentGroupUnitCount = 0

        for key, agentUnits in pairs(agentUnitGroups) do
            if #agentUnits >= agentGroupUnitCount then
                agentGroupUnitCount = #agentUnits
                agentGroupKey = key
            end
        end

        local agentToRemoveIndex = #agentUnitGroups[agentGroupKey]
        local agentToRemove = agentUnitGroups[agentGroupKey][agentToRemoveIndex]

        -- Getting the location where the agent will be teleported
        local agentTargetPositionX, agentTargetPositionY = cm:find_valid_spawn_location_for_character_from_position(
            general:faction():name(),
            general:logical_position_x(),
            general:logical_position_y(),
            true);

        -- Teleporting the last agent of the group out of the general army.
        -- Forced to use the teleport method instead of just moving the agent because teleporting is
        -- done instantly while moving is done after the next `UnitTrained` events are received.
        -- If we do not teleport the agent, it is still in the army when we calculate army
        -- supplies costs during later `UnitTrained` events which we do not want.
        cm:teleport_to(
            cm:char_lookup_str(agentToRemove.cqi),
            ---@diagnostic disable-next-line: param-type-mismatch
            agentTargetPositionX,
            ---@diagnostic disable-next-line: param-type-mismatch
            agentTargetPositionY)

        armySuppliesCost:removeCharacter(agentToRemove.cqi)
        agentsToRemoveAmount = agentsToRemoveAmount - 1

        TotoWarCbac.loggers.aiManager:logDebug(
            "adjustAiArmyAgents(%s from %s): REMOVED => %s (%s)",
            function() return TotoWar.utils:getCharacterCaption(general) end,
            function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
            function() return TotoWar.utils:getCharacterCaption(cm:get_character_by_cqi(agentToRemove.cqi)) end,
            function() return TotoWar.utils:getUnitCaption(agentToRemove.unitKey) end)
    end

    TotoWarCbac.loggers.aiManager:logDebug(
        "adjustAiArmyAgents(%s from %s): COMPLETED => Total army supplies cost: %s | Available army supplies: %s",
        function() return TotoWar.utils:getCharacterCaption(general) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return armySuppliesCost.totalCost end,
        function() return armySuppliesCost.availableSupplies end)
end

---Adjusts the units in an army to stay within maximum number of units allowed in each unit category.
---
---Cheapest units are removed first.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@param armySuppliesCost TotoWarCbacArmySuppliesCost Army supplies cost of the army. Updated if units are flagged as to removed.
---@param unitsToDiscard TotoWarCbacUnitArmySuppliesCost[] List of units to discard. Updated if units are flagged as to be removed.
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

---Adjusts the units in an army to stay below the army supplies cost limit by removing units cheaper than the last recruited unit.
---
---Cheapest units are removed first.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@param armySuppliesCost TotoWarCbacArmySuppliesCost Army supplies cost of the army. Updated if agents are removed.
---@param unitsToDiscard TotoWarCbacUnitArmySuppliesCost[] List of units to discard. Updated if units are flagged as to be removed.
---@param lastRecruitedUnit UNIT_SCRIPT_INTERFACE Last unit recruited.
function TotoWarCbacAiManager:adjustAiArmyUnits(army, armySuppliesCost, unitsToDiscard, lastRecruitedUnit)
    if armySuppliesCost.availableSupplies >= 0 then
        return
    end

    local lastRecruitedUnitArmySuppliesCost = TotoWar.utils:linqFirstOrDefault(
        armySuppliesCost.unitArmySuppliesCosts,
        function(uasc) return uasc.unitKey == lastRecruitedUnit:unit_key() end)

    if lastRecruitedUnitArmySuppliesCost == nil then
        -- If we do not find the last recruited unit in armySuppliesCost.unitArmySuppliesCosts, it means that it has already
        -- been added to the units to discard in adjustAiArmyComposition because it made a unit category exceed its limit
        return
    end

    TotoWarCbac.loggers.aiManager:logDebug(
        "adjustAiArmyUnits(%s from %s, %s): STARTED => Total army supplies cost: %s | Available army supplies: %s",
        function() return TotoWar.utils:getCharacterCaption(army:general_character()) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(lastRecruitedUnit:unit_key()) end,
        function() return armySuppliesCost.totalCost end,
        function() return armySuppliesCost.availableSupplies end)

    local disposableUnits = TotoWar.utils:linqWhere(
        armySuppliesCost.unitArmySuppliesCosts,
        function(uasc)
            return
                uasc.unitCategory ~= TotoWarCbac.enums.armyCompositionUnitTypes.general
                and uasc.unitCategory ~= TotoWarCbac.enums.armyCompositionUnitTypes.agent
                and uasc.armySuppliesCost < lastRecruitedUnitArmySuppliesCost.armySuppliesCost
        end)

    ---@type TotoWarCbacUnitArmySuppliesCost[]
    local finalSelectedUnits = {}
    local armySuppliesCostToDiscard = -armySuppliesCost.availableSupplies

    for i = 1, TotoWarCbac.options.aiArmyDisposableUnitsMaximumAmount, 1 do
        -- Iterating to find up to TotoWarCbac.options.aiArmyDisposableUnitsMaximumAmount units that can be discarded to cover armySuppliesCostToDiscard
        local startIndex = 0
        local endIndex = startIndex + TotoWarCbac.options.aiArmyDisposableUnitsMaximumAmount - 1

        if endIndex > #disposableUnits - 1 then
            endIndex = #disposableUnits - 1
        end

        ---@type TotoWarCbacUnitArmySuppliesCost[]
        local selectedUnits = {}
        local selectedUnitsArmySuppliesCost = 0

        while endIndex < #disposableUnits and selectedUnitsArmySuppliesCost < armySuppliesCostToDiscard do
            -- Iterating throught each combination of TotoWarCbac.options.aiArmyDisposableUnitsMaximumAmount units until we find the first
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

        if selectedUnitsArmySuppliesCost < armySuppliesCostToDiscard then
            -- If we get here, it means that the combination of the TotoWarCbac.options.aiArmyDisposableUnitsMaximumAmount priciest
            -- disposable units cannot cover the army supplies cost excess.
            -- Therefore we can stop immediatly.
            break
        end

        -- Adding the priciest unit of the combination to the list of units that will be discarded.
        -- Since it is this unit that made it possible to reach the armySuppliesCostToDiscard, we know for sure that it must be discarded.
        -- Further iterations are used to optimise the cost of the other units that must also be discarded to the reach remaining armySuppliesCostToDiscard.
        table.insert(finalSelectedUnits, selectedUnits[#selectedUnits])
        armySuppliesCostToDiscard = armySuppliesCostToDiscard - selectedUnits[#selectedUnits].armySuppliesCost

        TotoWarCbac.loggers.aiManager:logDebug(
            "adjustAiArmyUnits(%s from %s, %s): UNIT TO DISCARD: %s (%s)",
            function() return TotoWar.utils:getCharacterCaption(army:general_character()) end,
            function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
            function() return TotoWar.utils:getUnitCaption(lastRecruitedUnit:unit_key()) end,
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
        "adjustAiArmyUnits(%s from %s, %s): COMPLETED => Total army supplies cost: %s | Available army supplies: %s",
        function() return TotoWar.utils:getCharacterCaption(army:general_character()) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(lastRecruitedUnit:unit_key()) end,
        function() return armySuppliesCost.totalCost end,
        function() return armySuppliesCost.availableSupplies end)
end

---Reacts to a unit being disbanded by an AI army.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@param unit UNIT_SCRIPT_INTERFACE Unit.
function TotoWarCbacAiManager:onAiUnitDisbanded(army, unit)
    TotoWarCbac.loggers.aiManager:logDebug(
        "[EVENT] onAiUnitDisbanded(%s from %s, %s): STARTED",
        function() return TotoWar.utils:getCharacterCaption(army:general_character()) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(unit:unit_key()) end)

    -- This is just to log how AI disbands units and how it impacts the mod

    TotoWarCbac.loggers.aiManager:logDebug(
        "[EVENT] onAiUnitDisbanded(%s from %s, %s): COMPLETED",
        function() return TotoWar.utils:getCharacterCaption(army:general_character()) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(unit:unit_key()) end)
end

---Reacts to a unit being recruited by an AI army.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@param unit UNIT_SCRIPT_INTERFACE Unit.
function TotoWarCbacAiManager:onAiUnitRecruited(army, unit)
    TotoWarCbac.loggers.aiManager:logDebug(
        "[EVENT] onAiUnitRecruited(%s from %s, %s): STARTED",
        function() return TotoWar.utils:getCharacterCaption(army:general_character()) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(unit:unit_key()) end)

    self:adjustAiArmy(army, unit)

    TotoWarCbac.loggers.aiManager:logDebug(
        "[EVENT] onAiUnitRecruited(%s from %s, %s): COMPLETED",
        function() return TotoWar.utils:getCharacterCaption(army:general_character()) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
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
