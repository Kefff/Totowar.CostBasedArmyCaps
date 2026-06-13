---@class TotoWar_Cbac_UnitArmySuppliesCost
TotoWar_Cbac_UnitArmySuppliesCost = {
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
    ---@type TotoWar_Cbac_Enum_ArmyCompositionUnitCategory
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
TotoWar_Cbac_UnitArmySuppliesCost.__index = TotoWar_Cbac_UnitArmySuppliesCost

---Initializes a new instance from a character.
---@param characterCqi integer Command queue index of the character.
---@return TotoWar_Cbac_UnitArmySuppliesCost | nil
function TotoWar_Cbac_UnitArmySuppliesCost.newCharacter(characterCqi)
    TotoWar_Cbac.loggers.armySuppliesCost:logDebug(
        "TotoWar_Cbac_UnitArmySuppliesCost.newCharacter(%s): STARTED",
        function() return TotoWar__Gameplay:getCharacterCaption(TotoWar__Gameplay:getCharacter(characterCqi)) end)

    local instance = setmetatable({}, TotoWar_Cbac_UnitArmySuppliesCost)

    local unitKey = common.get_context_value(
        TotoWar__Enum_CcoContextTypeIds.campaignCharacter,
        tostring(characterCqi),
        "UnitContext.UnitRecordContext.Key")

    if unitKey == nil then
        -- For some reason, some characters may have no CcoCampaignCharacter so we cannot obtain information on them
        TotoWar_Cbac.loggers.armySuppliesCost:logWarning(
            "Unit record found for character \"%s\" not found",
            TotoWar__Gameplay:getCharacterCaption(TotoWar__Gameplay:getCharacter(characterCqi)))

        return nil
    end

    instance.armySuppliesCost = common.get_context_value(
        TotoWar__Enum_CcoContextTypeIds.mainUnitRecord,
        unitKey,
        "UnmountedUnitRecordContext.BaseCost") or 0

    if instance.armySuppliesCost <= 0 then
        -- For some reason, some units have a negative base cost (the Blue Scribes from Tzeench for example).
        -- We use the absolute value as a fallback.
        local transformedCost = math.abs(instance.armySuppliesCost)

        TotoWar_Cbac.loggers.armySuppliesCost:logWarning(
            "Invalid price found for unit \"%s\" (Price: %s | Used instead: %s)",
            TotoWar__Gameplay:getUnitCaption(unitKey),
            instance.armySuppliesCost,
            transformedCost)

        instance.armySuppliesCost = transformedCost
    end

    instance.baseUnitKey = common.get_context_value(
        TotoWar__Enum_CcoContextTypeIds.mainUnitRecord,
        unitKey,
        "UnmountedUnitRecordContext.Key")
    instance.characterCqi = characterCqi
    instance.unitCqi = tonumber(common.get_context_value(
        TotoWar__Enum_CcoContextTypeIds.campaignCharacter,
        tostring(characterCqi),
        "UnitContext.UniqueUiId")) -- UnitContext.UniqueUiId is a string
    instance.unitKey = unitKey

    if TotoWar__Gameplay:isLordUnit(characterCqi) then
        ---@diagnostic disable-next-line: assign-type-mismatch
        instance.unitCategory = TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.lord
    else
        ---@diagnostic disable-next-line: assign-type-mismatch
        instance.unitCategory = TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.hero
    end

    TotoWar_Cbac.loggers.armySuppliesCost:logDebug(
        "TotoWar_Cbac_UnitArmySuppliesCost.newCharacter(%s): COMPLETED => %s, %s",
        function() return TotoWar__Gameplay:getCharacterCaption(TotoWar__Gameplay:getCharacter(characterCqi)) end,
        function() return instance.baseUnitKey end,
        function() return instance.armySuppliesCost end)

    return instance
end

---Initializes a new instance from a unit.
---@param unitKey string Unit key.
---@param unitCqi integer | nil Command queue index of the unit (if we are able to get one).
---@return TotoWar_Cbac_UnitArmySuppliesCost
function TotoWar_Cbac_UnitArmySuppliesCost.newUnit(unitKey, unitCqi)
    TotoWar_Cbac.loggers.armySuppliesCost:logDebug(
        "TotoWar_Cbac_UnitArmySuppliesCost.newUnit(%s): STARTED",
        function() return TotoWar__Gameplay:getUnitCaption(unitKey) end)

    local instance = setmetatable({}, TotoWar_Cbac_UnitArmySuppliesCost)
    instance.armySuppliesCost = common.get_context_value(
        TotoWar__Enum_CcoContextTypeIds.mainUnitRecord,
        unitKey,
        "UnmountedUnitRecordContext.BaseCost")

    if instance.armySuppliesCost <= 0 then
        -- For some reason, some units have a negative base cost (the Blue Scribes from Tzeench for example).
        -- We use the absolute value as a fallback.
        local transformedCost = math.abs(instance.armySuppliesCost)

        TotoWar_Cbac.loggers.armySuppliesCost:logWarning(
            "Invalid price found for unit \"%s\" (Price: %s | Used instead: %s)",
            TotoWar__Gameplay:getUnitCaption(unitKey),
            instance.armySuppliesCost,
            transformedCost)

        instance.armySuppliesCost = transformedCost
    end

    instance.baseUnitKey = common.get_context_value(
        TotoWar__Enum_CcoContextTypeIds.mainUnitRecord,
        unitKey,
        "UnmountedUnitRecordContext.Key")


    instance.unitCategory = instance:getUnitArmyCompositionUnitType(unitKey)
    instance.unitCqi = unitCqi
    instance.unitKey = unitKey

    TotoWar_Cbac.loggers.armySuppliesCost:logDebug(
        "TotoWar_Cbac_UnitArmySuppliesCost.newUnit(%s): COMPLETED => %s, %s",
        function() return TotoWar__Gameplay:getUnitCaption(unitKey) end,
        function() return instance.baseUnitKey end,
        function() return instance.armySuppliesCost end)

    return instance
end

---Gets the unit army composition type based on the category of a unit.
---@param unitKey string Unit key.
---@param characterCqi integer | nil Character command queue index (if it a character).
---@return TotoWar_Cbac_Enum_ArmyCompositionUnitCategory
function TotoWar_Cbac_UnitArmySuppliesCost:getUnitArmyCompositionUnitType(unitKey, characterCqi)
    TotoWar_Cbac.loggers.armySuppliesCost:logDebug(
        "TotoWar_Cbac_UnitArmySuppliesCost:getUnitArmyCompositionUnitType(%s): STARTED",
        function() return unitKey end)

    ---@type string | nil
    local armyCompositionUnitType = nil

    if characterCqi ~= nil then
        if TotoWar__Gameplay:isLordUnit(characterCqi) then
            armyCompositionUnitType = TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.lord
        else
            armyCompositionUnitType = TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.hero
        end
    else
        local unitGroup = common.get_context_value(
            TotoWar__Enum_CcoContextTypeIds.mainUnitRecord,
            unitKey,
            "UiUnitGroupContext.ParentGroup.Key")

        if unitGroup:find('artillery') or unitGroup:find('war_machines') then
            armyCompositionUnitType = TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.warMachines
        elseif unitGroup:find('infantry') then
            if unitGroup:find('missile') then
                armyCompositionUnitType = TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.rangedInfantry
            else
                armyCompositionUnitType = TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.meleeInfantry
            end
        else
            armyCompositionUnitType = TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.cavalryAndMonsters
        end
    end

    TotoWar_Cbac.loggers.armySuppliesCost:logDebug(
        "TotoWar_Cbac_UnitArmySuppliesCost:getUnitArmyCompositionUnitType(%s): COMPLETED => %s",
        function() return unitKey end,
        function() return armyCompositionUnitType end)

    ---@diagnostic disable-next-line: return-type-mismatch
    return armyCompositionUnitType
end
