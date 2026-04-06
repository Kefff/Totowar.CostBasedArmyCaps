---@class TotoWarCbacUnitArmySuppliesCost
TotoWarCbacUnitArmySuppliesCost = {
    ---Army supplies cost of the unit.
    ---If the unit derives from a base unit (like mounted characters),
    ---the cost is the cost of the base unit because we only take into account the base price of units.
    armySuppliesCost = 0,

    ---Key of the base unit this unit derives from (like mounted characters).
    ---Used to identify agents of the same type but with different mounts.
    baseUnitKey = nil,

    ---Command queue index of the unit if it is a character.
    ---@type integer | nil
    cqi = nil,

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
---@return TotoWarCbacUnitArmySuppliesCost
function TotoWarCbacUnitArmySuppliesCost.newUnit(unitKey)
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
    instance.unitKey = unitKey

    TotoWar.genericLogger:logDebug(
        "TotoWarCbacUnitArmySuppliesCost.newUnit(%s): COMPLETED => %s, %s",
        function() return TotoWar.utils:getUnitCaption(unitKey) end,
        function() return instance.baseUnitKey end,
        function() return instance.armySuppliesCost end)

    return instance
end

---Gets a unit army supplies cost as a tooltip string.
---@return string
function TotoWarCbacUnitArmySuppliesCost:toArmySuppliesCostTooltipText()
    TotoWar.genericLogger:logDebug("TotoWarCbacUnitArmySuppliesCost:toTooltipText: STARTED")

    ---@type string
    local tooltipText

    if self.cqi then
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
