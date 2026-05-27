---@class TotoWarCbacUnitArmySuppliesCost
TotoWarCbacUnitArmySuppliesCost = {
    ---Army supplies cost of the unit.
    ---If the unit derives from a base unit (like mounted characters),
    ---the cost is the cost of the base unit because we only take into account the base price of units.
    armySuppliesCost = 0,

    ---Key of the base unit this unit derives from (like mounted characters).
    ---Used to identify heroes of the same type but with different mounts.
    ---@type string
    baseUnitKey = nil,

    ---Command queue index of the character if the unit is a character.
    ---
    ---Characters have both a `characterCqi` and a `unitCqi` which are different.
    ---@type integer | nil
    characterCqi = nil,

    ---Category of the unit.
    ---@type TotoWarCbac_Enums_ArmyCompositionUnitCategories
    unitCategory = nil,

    ---Command queue index of the unit.
    ---
    ---Characters have both a `characterCqi` and a `unitCqi` which are different.
    ---@type integer | nil
    unitCqi = nil,

    ---Key of the unit.
    ---@type string
    unitKey = nil
}
TotoWarCbacUnitArmySuppliesCost.__index = TotoWarCbacUnitArmySuppliesCost

---Initializes a new instance from a character.
---@param characterCqi integer Command queue index of the character.
---@return TotoWarCbacUnitArmySuppliesCost | nil
function TotoWarCbacUnitArmySuppliesCost.newCharacter(characterCqi)
    TotoWarCbac.loggers.armySuppliesCost:logDebug(
        "TotoWarCbacUnitArmySuppliesCost.newCharacter(%s): STARTED",
        function() return TotoWar.utils:getCharacterCaption(cm:get_character_by_cqi(characterCqi)) end)

    local instance = setmetatable({}, TotoWarCbacUnitArmySuppliesCost)

    local unitKey = common.get_context_value(
        TotoWar.enums.ccoContextTypeIds.campaignCharacter,
        tostring(characterCqi),
        "UnitContext.UnitRecordContext.Key")

    if unitKey == nil then
        -- For some reason, some characters may have no CcoCampaignCharacter so we cannot obtain information on them
        TotoWarCbac.loggers.armySuppliesCost:logWarning(
            "Unit record found for character \"%s\" not found",
            TotoWar.utils:getCharacterCaption(cm:get_character_by_cqi(characterCqi)))

        return nil
    end

    instance.armySuppliesCost = common.get_context_value(
        TotoWar.enums.ccoContextTypeIds.mainUnitRecord,
        unitKey,
        "UnmountedUnitRecordContext.BaseCost") or 0

    if instance.armySuppliesCost <= 0 then
        -- For some reason, some units have a negative base cost (the Blue Scribes from Tzeench for example).
        -- We use the absolute value as a fallback.
        local transformedCost = math.abs(instance.armySuppliesCost)

        TotoWarCbac.loggers.armySuppliesCost:logWarning(
            "Invalid price found for unit \"%s\" (Price: %s | Used instead: %s)",
            TotoWar.utils:getUnitCaption(unitKey),
            instance.armySuppliesCost,
            transformedCost)

        instance.armySuppliesCost = transformedCost
    end

    instance.baseUnitKey = common.get_context_value(
        TotoWar.enums.ccoContextTypeIds.mainUnitRecord,
        unitKey,
        "UnmountedUnitRecordContext.Key")
    instance.characterCqi = characterCqi
    instance.unitCqi = tonumber(common.get_context_value(
        TotoWar.enums.ccoContextTypeIds.campaignCharacter,
        tostring(characterCqi),
        "UnitContext.UniqueUiId")) -- UnitContext.UniqueUiId is a string
    instance.unitKey = unitKey

    if TotoWar.utils:isLordUnit(characterCqi) then
        ---@diagnostic disable-next-line: assign-type-mismatch
        instance.unitCategory = TotoWarCbac.enums.armyCompositionUnitTypes.lord
    else
        ---@diagnostic disable-next-line: assign-type-mismatch
        instance.unitCategory = TotoWarCbac.enums.armyCompositionUnitTypes.hero
    end

    TotoWarCbac.loggers.armySuppliesCost:logDebug(
        "TotoWarCbacUnitArmySuppliesCost.newCharacter(%s): COMPLETED => %s, %s",
        function() return TotoWar.utils:getCharacterCaption(cm:get_character_by_cqi(characterCqi)) end,
        function() return instance.baseUnitKey end,
        function() return instance.armySuppliesCost end)

    return instance
end

---Initializes a new instance from a unit.
---@param unitKey string Unit key.
---@param unitCqi integer | nil Command queue index of the unit (if we are able to get one).
---@return TotoWarCbacUnitArmySuppliesCost
function TotoWarCbacUnitArmySuppliesCost.newUnit(unitKey, unitCqi)
    TotoWarCbac.loggers.armySuppliesCost:logDebug(
        "TotoWarCbacUnitArmySuppliesCost.newUnit(%s): STARTED",
        function() return TotoWar.utils:getUnitCaption(unitKey) end)

    local instance = setmetatable({}, TotoWarCbacUnitArmySuppliesCost)
    instance.armySuppliesCost = common.get_context_value(
        TotoWar.enums.ccoContextTypeIds.mainUnitRecord,
        unitKey,
        "UnmountedUnitRecordContext.BaseCost")

    if instance.armySuppliesCost <= 0 then
        -- For some reason, some units have a negative base cost (the Blue Scribes from Tzeench for example).
        -- We use the absolute value as a fallback.
        local transformedCost = math.abs(instance.armySuppliesCost)

        TotoWarCbac.loggers.armySuppliesCost:logWarning(
            "Invalid price found for unit \"%s\" (Price: %s | Used instead: %s)",
            TotoWar.utils:getUnitCaption(unitKey),
            instance.armySuppliesCost,
            transformedCost)

        instance.armySuppliesCost = transformedCost
    end

    instance.baseUnitKey = common.get_context_value(
        TotoWar.enums.ccoContextTypeIds.mainUnitRecord,
        unitKey,
        "UnmountedUnitRecordContext.Key")


    instance.unitCategory = instance:getUnitArmyCompositionUnitType(unitKey)
    instance.unitCqi = unitCqi
    instance.unitKey = unitKey

    TotoWarCbac.loggers.armySuppliesCost:logDebug(
        "TotoWarCbacUnitArmySuppliesCost.newUnit(%s): COMPLETED => %s, %s",
        function() return TotoWar.utils:getUnitCaption(unitKey) end,
        function() return instance.baseUnitKey end,
        function() return instance.armySuppliesCost end)

    return instance
end

---Gets the unit army composition type based on the category of a unit.
---@param unitKey string Unit key.
---@param characterCqi integer | nil Character command queue index (if it a character).
---@return TotoWarCbac_Enums_ArmyCompositionUnitCategories
function TotoWarCbacUnitArmySuppliesCost:getUnitArmyCompositionUnitType(unitKey, characterCqi)
    TotoWarCbac.loggers.armySuppliesCost:logDebug(
        "TotoWarCbacUnitArmySuppliesCost:getUnitArmyCompositionUnitType(%s): STARTED",
        function() return unitKey end)

    ---@type string | nil
    local armyCompositionUnitType = nil

    if characterCqi ~= nil then
        if TotoWar.utils:isLordUnit(characterCqi) then
            armyCompositionUnitType = TotoWarCbac.enums.armyCompositionUnitTypes.lord
        else
            armyCompositionUnitType = TotoWarCbac.enums.armyCompositionUnitTypes.hero
        end
    else
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

    TotoWarCbac.loggers.armySuppliesCost:logDebug(
        "TotoWarCbacUnitArmySuppliesCost:getUnitArmyCompositionUnitType(%s): COMPLETED => %s",
        function() return unitKey end,
        function() return armyCompositionUnitType end)

    ---@diagnostic disable-next-line: return-type-mismatch
    return armyCompositionUnitType
end
