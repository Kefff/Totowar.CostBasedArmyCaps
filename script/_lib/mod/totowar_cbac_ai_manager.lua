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
        "TotoWarCbacPlayerManager",
        TotoWar.ui.enums.events.unitTrained,
        ---@param context TotoWarEventContext_UnitTrained
        function(context)
            return
                not cm:is_local_players_turn()
                and TotoWar.utils:canRecruitUnits(context:unit():military_force())
        end,
        ---@param context TotoWarEventContext_UnitTrained
        function(context)
            self:onAiUnitRecruited(context:unit():military_force(), context:unit())
        end)

    self.logger:logDebug("addListeners(): COMPLETED")
end

---Adjusts an army composition by removing excess units when its cost exceeds army supplies.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@param armySuppliesCost TotoWarCbacArmySuppliesCost Army supplies cost of the army.
---@param lastRecruitedUnit UNIT_SCRIPT_INTERFACE Last unit recruited. We prioritize getting rid of units cheaper than this unit. Otherwise, we remove this unit.
function TotoWarCbacAiManager:adjustAiArmyComposition(army, armySuppliesCost, lastRecruitedUnit)
    self.logger:logDebug(
        "adjustAiArmyComposition(%s from %s, %s, %s): STARTED",
        function() return TotoWar.utils:getCharacterCaption(army:general_character()) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(lastRecruitedUnit:unit_key()) end,
        function() return armySuppliesCost.totalCost end
    )

    table.sort(
        armySuppliesCost.unitGroups,
        function(a, b)
            return a.unitArmySuppliesCost < b.unitArmySuppliesCost
        end)

    ---@type TotoWarCbacAiDisposableUnit[]
    local disposableUnits = {}
    local lastRecruitedUnitArmySuppliesCost = 0

    for index, unitGroup in ipairs(armySuppliesCost.unitGroups) do
        if unitGroup.unitKey == lastRecruitedUnit:unit_key() then
            -- The last recruited unit and units that come after (which are more expensive) are not disposable
            lastRecruitedUnitArmySuppliesCost = unitGroup.unitArmySuppliesCost

            break
        end

        local isCharacter = TotoWar.utils:isCharacter(unitGroup.unitKey)

        if not isCharacter then
            ---@type UNIT_SCRIPT_INTERFACE
            local unit = nil

            for i = 1, unitGroup.unitCount, 1 do
                if not unit then
                    for j = 0, army:unit_list():num_items() - 1, 1 do
                        unit = army:unit_list():item_at(j)

                        if unit:unit_key() == unitGroup.unitKey then
                            break
                        end
                    end
                end

                self.logger:logDebug(
                    "adjustAiArmyComposition(%s from %s, %s, %s): ADDED TO DISPOSABLE UNITS => %s (%s)",
                    function() return TotoWar.utils:getCharacterCaption(army:general_character()) end,
                    function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
                    function() return TotoWar.utils:getUnitCaption(lastRecruitedUnit:unit_key()) end,
                    function() return armySuppliesCost.totalCost end,
                    function() return TotoWar.utils:getUnitCaption(unit:unit_key()) end,
                    function() return unitGroup.unitArmySuppliesCost end
                )

                table.insert(
                    disposableUnits,
                    TotoWarCbacAiDisposableUnit.new(unit, unitGroup.unitArmySuppliesCost))
            end
        end
    end

    ---@type TotoWarCbacAiDisposableUnit[] |nil
    local unitsToDiscard = nil

    if #disposableUnits > 0 then
        -- Getting the list of units to discard if
        local costToDiscard = -armySuppliesCost.availableSupplies
        unitsToDiscard = self:getUnitsToDiscard(disposableUnits, costToDiscard)
    end

    if unitsToDiscard then
        -- Removing the units we were able to find to make room for the last recruited unit and reimbursing the AI for their real cost (not the base cost)
        for index, unitToDiscard in ipairs(unitsToDiscard) do
            cm:remove_unit_from_character(cm:char_lookup_str(army:general_character()), unitToDiscard.key)
            cm:treasury_mod(army:faction():name(), army:faction():treasury() + unitToDiscard.realCost)

            self.logger:logDebug(
                "adjustAiArmyComposition(%s from %s, %s, %s): REMOVED UNIT => %s (%s, %s)",
                function() return TotoWar.utils:getCharacterCaption(army:general_character()) end,
                function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
                function() return TotoWar.utils:getUnitCaption(lastRecruitedUnit:unit_key()) end,
                function() return armySuppliesCost.totalCost end,
                function() return TotoWar.utils:getUnitCaption(unitToDiscard.key) end,
                function() return unitToDiscard.armySuppliesCost end,
                function() return unitToDiscard.realCost end)
        end
    else
        -- Removing the last recruited unit and reimbursing the AI for their real cost (not the base cost)
        local lastRecruitedUnitRealCost = cco("CcoCampaignUnit", lastRecruitedUnit:command_queue_index()):Call("Cost")
        cm:treasury_mod(army:faction():name(), army:faction():treasury() + lastRecruitedUnitRealCost)
        cm:remove_unit_from_character(cm:char_lookup_str(army:general_character()), lastRecruitedUnit:unit_key())

        self.logger:logDebug(
            "adjustAiArmyComposition(%s from %s, %s, %s): REMOVED LAST RECRUITED UNIT => %s (%s, %s)",
            function() return TotoWar.utils:getCharacterCaption(army:general_character()) end,
            function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
            function() return TotoWar.utils:getUnitCaption(lastRecruitedUnit:unit_key()) end,
            function() return armySuppliesCost.totalCost end,
            function() return TotoWar.utils:getUnitCaption(lastRecruitedUnit:unit_key()) end,
            function() return lastRecruitedUnitRealCost end,
            function() return lastRecruitedUnitArmySuppliesCost end)
    end

    self.logger:logDebug(
        "adjustAiArmyComposition(%s from %s, %s, %s): COMPLETED",
        function() return TotoWar.utils:getCharacterCaption(army:general_character()) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(lastRecruitedUnit:unit_key()) end,
        function() return armySuppliesCost.totalCost end
    )
end

---Gets the keys of units to discard from an army in order to not exceed the army supplies.
---Priorities the cheapest units.
---@param disposableUnits TotoWarCbacAiDisposableUnit[] List of units that can be discarded.
---@param costToDiscard number Army supplies cost that exceeds the available army supplies.
---@return TotoWarCbacAiDisposableUnit[] | nil
function TotoWarCbacAiManager:getUnitsToDiscard(disposableUnits, costToDiscard)
    self.logger:logDebug(
        "getUnitsToDiscard(%s, %s): STARTED",
        function() return #disposableUnits end,
        function() return costToDiscard end)

    ---@type TotoWarCbacAiDisposableUnit[]
    local unitsToDiscard = {}
    self:getUnitsToDiscardRecursive(unitsToDiscard, disposableUnits, #disposableUnits, costToDiscard)

    self.logger:logDebug(
        "getUnitsToDiscard(%s, %s): COMPLETED => %s",
        function() return #disposableUnits end,
        function() return costToDiscard end,
        function() return #unitsToDiscard end)

    if #unitsToDiscard == 0 then
        return nil
    end

    return unitsToDiscard
end

---Recursively gets units to discard, from the priciest to the cheapest.
---@param unitsToDiscard TotoWarCbacAiDisposableUnit[] List of units to discard that is filled by this method.
---@param disposableUnits TotoWarCbacAiDisposableUnit[] List of disposable units to pick from, ordered by army supplies cost.
---@param maxDisposableUnitIndex number Maximum index the search can use when searching a disposable unit. It represents the index of the last priciest unit that have been picked.
---@param armySuppliesCostToDiscard number Remaining army supplies cost to discard since the last priciest unit has been picked.
function TotoWarCbacAiManager:getUnitsToDiscardRecursive(
    unitsToDiscard,
    disposableUnits,
    maxDisposableUnitIndex,
    armySuppliesCostToDiscard)
    self.logger:logDebug(
        "getUnitsToDiscardRecursive(%s, %s, %s, %s): STARTED",
        function() return #unitsToDiscard end,
        function() return #disposableUnits end,
        function() return maxDisposableUnitIndex end,
        function() return armySuppliesCostToDiscard end)

    for i = 1, maxDisposableUnitIndex, 1 do
        ---@type TotoWarCbacAiDisposableUnit
        local unitToDiscard = nil
        local totalArmySuppliesCost = 0
        local currentIndex = 0

        for j = 0, TotoWarCbac.aiDisposableUnitsMaximumAmount - 1, 1 do
            if totalArmySuppliesCost >= armySuppliesCostToDiscard then
                break
            end

            currentIndex = i + j

            if currentIndex > maxDisposableUnitIndex then
                break;
            end

            -- We browse disposable units, starting at index i and taking up to the TotoWarCbacaiUnitsToDiscardMaximumNumber next disposable units
            unitToDiscard = disposableUnits[currentIndex]
            totalArmySuppliesCost = totalArmySuppliesCost + unitToDiscard.armySuppliesCost
        end

        if totalArmySuppliesCost >= armySuppliesCostToDiscard then
            armySuppliesCostToDiscard = armySuppliesCostToDiscard - unitToDiscard.armySuppliesCost
            table.insert(unitsToDiscard, unitToDiscard)

            self.logger:logDebug(
                "getUnitsToDiscardRecursive(%s, %s, %s, %s): UNIT TO DISCARD => %s (%s, %s)",
                function() return #unitsToDiscard end,
                function() return #disposableUnits end,
                function() return maxDisposableUnitIndex end,
                function() return armySuppliesCostToDiscard end,
                function() return TotoWar.utils:getUnitCaption(unitToDiscard.key) end,
                function() return unitToDiscard.armySuppliesCost end,
                function() return unitToDiscard.realCost end)

            if armySuppliesCostToDiscard > 0
                and #unitsToDiscard < TotoWarCbac.aiDisposableUnitsMaximumAmount
                and currentIndex > 1
            then
                self:getUnitsToDiscardRecursive(
                    unitsToDiscard,
                    disposableUnits,
                    currentIndex - 1,
                    armySuppliesCostToDiscard)
            end

            self.logger:logDebug(
                "getUnitsToDiscardRecursive(%s, %s, %s, %s): COMPLETED",
                function() return #unitsToDiscard end,
                function() return #disposableUnits end,
                function() return maxDisposableUnitIndex end,
                function() return armySuppliesCostToDiscard end)

            return
        end
    end

    self.logger:logDebug(
        "getUnitsToDiscardRecursive(%s, %s, %s, %s): NO UNIT TO DISCARD FOUND",
        function() return #unitsToDiscard end,
        function() return #disposableUnits end,
        function() return maxDisposableUnitIndex end,
        function() return armySuppliesCostToDiscard end)
end

---Indicates whether the first unit combination is cheaper that the second.
---@param firstUnitCombination TotoWarCbacUnitArmySuppliesCost[] First unit combination.
---@param secondUnitCombination TotoWarCbacUnitArmySuppliesCost[] | nil Second unit combination.
---@return boolean
function TotoWarCbacAiManager:isCheaperUnitCombination(firstUnitCombination, secondUnitCombination)
    if secondUnitCombination == nil then
        return true
    end

    for i = 1, math.min(#firstUnitCombination, #secondUnitCombination) do
        if firstUnitCombination[i].unitArmySuppliesCost < secondUnitCombination[i].unitArmySuppliesCost then
            return true
        elseif firstUnitCombination[i].unitArmySuppliesCost > secondUnitCombination[i].unitArmySuppliesCost then
            return false
        end
    end

    -- When the two combinations have the same army supplies cost, choosing the one with the most units (which are the cheapest units)
    return #firstUnitCombination > #secondUnitCombination
end

---Reacts to a unit being recruited by an AI army.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@param unit UNIT_SCRIPT_INTERFACE Unit.
function TotoWarCbacAiManager:onAiUnitRecruited(army, unit)
    self.logger:logDebug(
        "[EVENT] onAiUnitRecruited(%s from %s, %s): STARTED",
        function() return TotoWar.utils:getCharacterCaption(army:general_character()) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(unit:unit_key()) end)

    local armySuppliesCost = TotoWarCbacArmySuppliesCost.new(TotoWarCbac.aiArmySuppliesAmount)
    local units = army:unit_list()

    for i = 0, units:num_items() - 1, 1 do
        local armyUnit = units:item_at(i)
        armySuppliesCost:addUnit(armyUnit:unit_key(), false)
    end

    if armySuppliesCost.availableSupplies < 0 then
        self:adjustAiArmyComposition(army, armySuppliesCost, unit)
    end

    self.logger:logDebug(
        "[EVENT] onAiUnitRecruited(%s from %s, %s): COMPLETED",
        function() return TotoWar.utils:getCharacterCaption(army:general_character()) end,
        function() return TotoWar.utils:getFactionCaption(army:faction():name()) end,
        function() return TotoWar.utils:getUnitCaption(unit:unit_key()) end)
end
