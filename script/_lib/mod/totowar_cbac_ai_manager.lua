---Manager in charge of managing the army supplies for the AI armies.
---@class TotoWarCbacAiManager
TotoWarCbacAiManager = {
    ---Logger.
    ---@type TotoWarLogger
    logger = nil
}
TotoWarCbacAiManager.__index = TotoWarCbacAiManager

---Initializes a new instance.
---@return TotoWarCbacAiManager
function TotoWarCbacAiManager.new()
    local instance = setmetatable({}, TotoWarCbacAiManager)

    instance.logger = TotoWarLogger.new("TotoWar_Cbac_AiManager")

    instance.logger:logDebug("new(): COMPLETED")

    return instance
end

---Adds listeners for events.
function TotoWarCbacAiManager:addListeners()
    self.logger:logDebug("addListeners(): STARTED")

    TotoWar.utils:addListener(
        "TotoWarCbacAiManager",
        TotoWar.enums.uiEvents.unitTrained,
        ---@param context TotoWarEventContext_UnitTrained
        function(context)
            return
                TotoWarCbac.options.aiArmySuppliesEnabled
                and not cm:is_local_players_turn()
                and context:unit():military_force()
                and TotoWar.utils:canRecruitUnits(context:unit():military_force())
        end,
        ---@param context TotoWarEventContext_UnitTrained
        function(context)
            self:onAiUnitRecruited(context:unit():military_force(), context:unit())
        end)

    -- TEST
    TotoWar.utils:addListener(
        "TotoWarCbacAiManager",
        TotoWar.enums.uiEvents.unitDisbanded,
        function()
            return not cm:is_local_players_turn()
        end,
        ---@param context TotoWarEventContext_UnitDisbanded
        function(context)
            self.logger:logDebug(
                "[TEST] AI UNIT DISBANDED => %s from %s | %s",
                function()
                    if context:unit():has_force_commander() then
                        return TotoWar.utils:getCharacterCaption(context:unit():force_commander())
                    end

                    return "???"
                end,
                function() return TotoWar.utils:getFactionCaption(context:unit():faction():name()) end,
                function() return TotoWar.utils:getUnitCaption(context:unit():unit_key()) end)
        end)
    -- /TEST

    self.logger:logDebug("addListeners(): COMPLETED")
end

---Adjusts an AI army by removing excess agents and units when its cost exceeds army supplies.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@param lastRecruitedUnit UNIT_SCRIPT_INTERFACE Last unit recruited. We prioritize getting rid of units cheaper than this unit. Otherwise, we remove this unit.
function TotoWarCbacAiManager:adjustAiArmy(army, lastRecruitedUnit)
    local armySuppliesCost = TotoWarCbacArmySuppliesCost.newFromArmy(TotoWarCbac.options.aiArmySuppliesAmount, army)

    if armySuppliesCost.availableSupplies >= 0 then
        return
    end

    self.logger:logDebug(
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

    if armySuppliesCost.availableSupplies < 0 then
        ---@type TotoWarCbacUnitArmySuppliesCost[]
        local unitsToDiscard = {}

        -- Adding to the list of units to remove the cheapest units of categories that have too many units
        self:adjustAiArmyComposition(army, armySuppliesCost, unitsToDiscard)

        if armySuppliesCost.availableSupplies < 0 then
            -- Adding to the list of units to remove the cheapest units to pass under the maximum army supplies cost
            self:adjustAiArmyUnits(army, armySuppliesCost, unitsToDiscard)
        end

        if armySuppliesCost.availableSupplies < 0 then
            armySuppliesCost:removeUnit(lastRecruitedUnit:unit_key())
            self:removeUnitFromAiArmy(army, lastRecruitedUnit:unit_key(), lastRecruitedUnit:command_queue_index())
        else
            for index, unitToDiscard in ipairs(unitsToDiscard) do
                self:removeUnitFromAiArmy(army, unitToDiscard.unitKey, unitToDiscard.cqi)
            end
        end
    end

    self.logger:logDebug(
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
        function(unit)
            return TotoWar.utils:isAgentUnit(unit.unitKey)
        end)
    local agentsToRemoveAmount = #agents - TotoWarCbac.options.aiArmyAgentMaximumAmount

    if agentsToRemoveAmount <= 0 then
        return
    end

    local general = army:general_character()

    self.logger:logDebug(
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

        self.logger:logDebug(
            "adjustAiArmyAgents(%s from %s): REMOVED => %s (%s) | Total army supplies cost: %s | Available army supplies: %s",
            function() return TotoWar.utils:getCharacterCaption(general) end,
            function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
            function() return TotoWar.utils:getCharacterCaption(cm:get_character_by_cqi(agentToRemove.cqi)) end,
            function() return TotoWar.utils:getUnitCaption(agentToRemove.unitKey) end,
            function() return armySuppliesCost.totalCost end,
            function() return armySuppliesCost.availableSupplies end)


        armySuppliesCost:removeCharacter(agentToRemove.cqi)
        agentsToRemoveAmount = agentsToRemoveAmount - 1
    end

    self.logger:logDebug(
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
    self.logger:logDebug(
        "adjustAiArmyComposition(%s from %s): STARTED => Total army supplies cost: %s | Available army supplies: %s",
        function() return TotoWar.utils:getCharacterCaption(army:general_character()) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return armySuppliesCost.totalCost end,
        function() return armySuppliesCost.availableSupplies end)

    -- Getting the number of units that exceeds the maximum proportion that is configured
    local unitCategoryExcessCounts = armySuppliesCost:getUnitCategoryExcessCounts()

    -- While the army supplies cost exceeds the maximum allowed, we add the exceeding units to the list of units to remove
    for unitCategory, unitCategoryExcessCount in pairs(unitCategoryExcessCounts) do
        self.logger:logDebug(
            "adjustAiArmyComposition(%s from %s): Category: %s | Excess: %s | Total army supplies cost: %s | Available army supplies: %s",
            function() return TotoWar.utils:getCharacterCaption(army:general_character()) end,
            function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
            function() return unitCategory end,
            function() return unitCategoryExcessCount end,
            function() return armySuppliesCost.totalCost end,
            function() return armySuppliesCost.availableSupplies end)

        if armySuppliesCost.availableSupplies > 0 or unitCategoryExcessCount == 0 then
            break
        end

        for index, unitArmySuppliesCost in ipairs(armySuppliesCost.unitArmySuppliesCosts) do
            if armySuppliesCost.availableSupplies > 0 or unitCategoryExcessCount == 0 then
                break
            end

            if unitArmySuppliesCost.unitCategory == unitCategory then
                table.insert(unitsToDiscard, unitArmySuppliesCost)
                armySuppliesCost:removeUnit(unitArmySuppliesCost.unitKey)
                unitCategoryExcessCount = unitCategoryExcessCount - 1

                self.logger:logDebug(
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

    self.logger:logDebug(
        "adjustAiArmyComposition(%s from %s): COMPLETED => Total army supplies cost: %s | Available army supplies: %s",
        function() return TotoWar.utils:getCharacterCaption(army:general_character()) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return armySuppliesCost.totalCost end,
        function() return armySuppliesCost.availableSupplies end)
end

---Reacts to a unit being recruited by an AI army.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@param unit UNIT_SCRIPT_INTERFACE Unit.
function TotoWarCbacAiManager:onAiUnitRecruited(army, unit)
    local general = army:general_character()

    self.logger:logDebug(
        "[EVENT] onAiUnitRecruited(%s from %s, %s): STARTED",
        function() return TotoWar.utils:getCharacterCaption(general) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(unit:unit_key()) end)

    self:adjustAiArmy(army, unit)

    self.logger:logDebug(
        "[EVENT] onAiUnitRecruited(%s from %s, %s): COMPLETED",
        function() return TotoWar.utils:getCharacterCaption(general) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(unit:unit_key()) end)
end

---Removes a unit from an AI army and reimburses the AI faction of the cost of the unit.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@param unitKey string Key of the unit to remove.
---@param unitCqi integer Command queue index of the unit to remove.
function TotoWarCbacAiManager:removeUnitFromAiArmy(army, unitKey, unitCqi)
    local general = army:general_character()

    self.logger:logDebug(
        "[EVENT] removeUnitFromAiArmy(%s from %s, %s, %s): STARTED",
        function() return TotoWar.utils:getCharacterCaption(general) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(unitKey) end,
        function() return unitCqi end)

    local unitRealCost = cco("CcoCampaignUnit", unitCqi):Call("Cost")

    if unitRealCost ~= nil then
        cm:treasury_mod(army:faction():name(), army:faction():treasury() + unitRealCost)
    end

    cm:remove_unit_from_character(cm:char_lookup_str(general), unitKey)

    self.logger:logDebug(
        "[EVENT] removeUnitFromAiArmy(%s from %s, %s, %s): COMPLETED => Reimbursed: %s",
        function() return TotoWar.utils:getCharacterCaption(general) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(unitKey) end,
        function() return unitCqi end,
        function() if unitRealCost ~= nil then return unitRealCost else return 0 end end)
end
