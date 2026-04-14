---@class TotoWarCbacUnitArmySuppliesCost
TotoWarCbacUnitArmySuppliesCost = {
    ---Army supplies cost of the unit.
    ---If the unit derives from a base unit (like mounted characters),
    ---the cost is the cost of the base unit because we only take into account the base price of units.
    armySuppliesCost = 0,

    ---Key of the base unit this unit derives from (like mounted characters).
    ---Used to identify agents of the same type but with different mounts.
    baseUnitKey = nil,

    ---Command queue index of the unit or character if we are able to get one.
    ---@type integer | nil
    cqi = nil,

    ---Category of the unit.
    ---@type TotoWarCbac_Enums_ArmyCompositionUnitCategories
    unitCategory = nil,

    ---Key of the unit.
    ---@type string
    unitKey = nil
}
TotoWarCbacUnitArmySuppliesCost.__index = TotoWarCbacUnitArmySuppliesCost

---Initializes a new instance from a character.
---@param cqi integer Command queue index of the character.
---@return TotoWarCbacUnitArmySuppliesCost
function TotoWarCbacUnitArmySuppliesCost.newCharacter(cqi)
    local character = cm:get_character_by_cqi(cqi)

    TotoWar.genericLogger:logDebug(
        "TotoWarCbacUnitArmySuppliesCost.newCharacter(%s): STARTED",
        function() return TotoWar.utils:getCharacterCaption(character) end)

    local unitKey = common.get_context_value(
        TotoWar.enums.ccoContextTypeIds.campaignCharacter,
        tostring(cqi),
        "UnitContext.UnitRecordContext.Key")

    local instance = setmetatable({}, TotoWarCbacUnitArmySuppliesCost)
    instance.armySuppliesCost = common.get_context_value(
        TotoWar.enums.ccoContextTypeIds.mainUnitRecord,
        unitKey,
        "UnmountedUnitRecordContext.BaseCost")
    instance.baseUnitKey = common.get_context_value(
        TotoWar.enums.ccoContextTypeIds.mainUnitRecord,
        unitKey,
        "UnmountedUnitRecordContext.Key")
    instance.cqi = cqi
    instance.unitCategory = instance:getUnitArmyCompositionUnitType(unitKey, cqi)
    instance.unitKey = unitKey

    TotoWar.genericLogger:logDebug(
        "TotoWarCbacUnitArmySuppliesCost.newCharacter(%s): COMPLETED => %s, %s",
        function() return TotoWar.utils:getCharacterCaption(character) end,
        function() return instance.baseUnitKey end,
        function() return instance.armySuppliesCost end)

    return instance
end

---Initializes a new instance from a unit.
---@param unitKey string Unit key.
---@param cqi integer | nil Command queue index of the unit (if we are able to get one).
---@return TotoWarCbacUnitArmySuppliesCost
function TotoWarCbacUnitArmySuppliesCost.newUnit(unitKey, cqi)
    TotoWar.genericLogger:logDebug(
        "TotoWarCbacUnitArmySuppliesCost.newUnit(%s): STARTED",
        function() return TotoWar.utils:getUnitCaption(unitKey) end)

    local instance = setmetatable({}, TotoWarCbacUnitArmySuppliesCost)
    instance.armySuppliesCost = common.get_context_value(
        TotoWar.enums.ccoContextTypeIds.mainUnitRecord,
        unitKey,
        "UnmountedUnitRecordContext.BaseCost")
    instance.baseUnitKey = common.get_context_value(
        TotoWar.enums.ccoContextTypeIds.mainUnitRecord,
        unitKey,
        "UnmountedUnitRecordContext.Key")
    instance.cqi = cqi
    instance.unitCategory = instance:getUnitArmyCompositionUnitType(unitKey, cqi)
    instance.unitKey = unitKey

    TotoWar.genericLogger:logDebug(
        "TotoWarCbacUnitArmySuppliesCost.newUnit(%s): COMPLETED => %s, %s",
        function() return TotoWar.utils:getUnitCaption(unitKey) end,
        function() return instance.baseUnitKey end,
        function() return instance.armySuppliesCost end)

    return instance
end

---Gets the unit army composition type based on the category of a unit.
---@param unitKey string Unit key.
---@param cqi integer | nil Unit command queue index (if it has one).
---@return TotoWarCbac_Enums_ArmyCompositionUnitCategories
function TotoWarCbacUnitArmySuppliesCost:getUnitArmyCompositionUnitType(unitKey, cqi)
    TotoWar.genericLogger:logDebug(
        "TotoWarCbacUnitArmySuppliesCost:getUnitArmyCompositionUnitType(%s): STARTED",
        function() return unitKey end)

    ---@type string | nil
    local armyCompositionUnitType = nil

    if cqi ~= nil then
        if TotoWar.utils:isGeneralUnit(cqi) then
            armyCompositionUnitType = TotoWarCbac.enums.armyCompositionUnitTypes.general
        elseif TotoWar.utils:isAgentUnit(cqi) then
            armyCompositionUnitType = TotoWarCbac.enums.armyCompositionUnitTypes.agent
        end
    end

    if armyCompositionUnitType == nil then
        local unitGroup = common.get_context_value(
            TotoWar.enums.ccoContextTypeIds.mainUnitRecord,
            unitKey,
            "UiUnitGroupContext.ParentGroup.Key")

        if unitGroup:find('artillery') then
            armyCompositionUnitType = TotoWarCbac.enums.armyCompositionUnitTypes.artillery
        elseif unitGroup:find('infantry') then
            if unitGroup:find('missile') then
                armyCompositionUnitType = TotoWarCbac.enums.armyCompositionUnitTypes.rangedInfantry
            else
                armyCompositionUnitType = TotoWarCbac.enums.armyCompositionUnitTypes.meleeInfantry
            end
        else
            armyCompositionUnitType = TotoWarCbac.enums.armyCompositionUnitTypes.cavalryAndMonsters
        end
    end

    TotoWar.genericLogger:logDebug(
        "TotoWarCbacUnitArmySuppliesCost:getUnitArmyCompositionUnitType(%s): COMPLETED => %s",
        function() return unitKey end,
        function() return armyCompositionUnitType end)

    ---@diagnostic disable-next-line: return-type-mismatch
    return armyCompositionUnitType
end

---Gets a unit army supplies cost as a tooltip string.
---@return string
function TotoWarCbacUnitArmySuppliesCost:toArmySuppliesCostTooltipText()
    TotoWar.genericLogger:logDebug("TotoWarCbacUnitArmySuppliesCost:toTooltipText: STARTED")

    ---@type string
    local tooltipText

    if self.unitCategory == TotoWarCbac.enums.armyCompositionUnitTypes.general
        or self.unitCategory == TotoWarCbac.enums.armyCompositionUnitTypes.agent
    then
        local character = cm:get_character_by_cqi(self.cqi)

        if character:has_military_force() then
            tooltipText = string.format(
                common.get_localised_string("totowar_cbac_tooltip_unit_armySuppliesCostOfGeneral"),
                TotoWar.utils:getCharacterCaption(character),
                TotoWar.utils:getUnitCaption(self.unitKey),
                self.armySuppliesCost)
        else
            tooltipText = string.format(
                common.get_localised_string("totowar_cbac_tooltip_unit_armySuppliesCostOfAgent"),
                TotoWar.utils:getCharacterCaption(character),
                TotoWar.utils:getUnitCaption(self.unitKey),
                self.armySuppliesCost)
        end
    else
        tooltipText = string.format(
            common.get_localised_string("totowar_cbac_tooltip_unit_armySuppliesCostOfUnit"),
            TotoWar.utils:getUnitCaption(self.unitKey),
            self.armySuppliesCost)
    end

    TotoWar.genericLogger:logDebug("TotoWarCbacUnitArmySuppliesCost:toTooltipText: COMPLETED")

    return tooltipText
end
