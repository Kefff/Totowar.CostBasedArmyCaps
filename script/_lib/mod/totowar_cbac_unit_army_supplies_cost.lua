local logger = TotoWar__Logger.get(TotoWar_Cbac_Enum_LogCategories.armySuppliesCost)

---Army composition unit categories by key of parent unit group (ui_unit_group_parents table).
---Lords and heroes (`commander` and `heroes_agents` groups) are categorized from their character.
---@type table<string, TotoWar_Cbac_Enum_ArmyCompositionUnitCategories>
local _unitCategoriesByParentGroup = {
    artillery_war_machines = TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.warMachines,
    campaign_exclusives = TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.cavalryAndMonsters,
    cavalry_chariots = TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.cavalryAndMonsters,
    constructs = TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.cavalryAndMonsters,
    flying_war_machine = TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.warMachines,
    infantry = TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.meleeInfantry,
    missile_cavalry_chariots = TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.cavalryAndMonsters,
    missile_infantry = TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.rangedInfantry,
    missile_monster_beasts = TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.cavalryAndMonsters,
    monster_beasts = TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.cavalryAndMonsters
}

---Army composition unit categories already found, by unit key.
---@type table<string, TotoWar_Cbac_Enum_ArmyCompositionUnitCategories>
local _unitCategoriesByUnitKey = {}

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
    ---@type TotoWar_Cbac_Enum_ArmyCompositionUnitCategories
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
    local instance = setmetatable({}, TotoWar_Cbac_UnitArmySuppliesCost)

    local unitKey = common.get_context_value(
        TotoWar__Enum_CcoContextTypeIds.campaignCharacter,
        tostring(characterCqi),
        "UnitContext.UnitRecordContext.Key")
    ---@type string | nil
    local unitUniqueUiId = common.get_context_value(
        TotoWar__Enum_CcoContextTypeIds.campaignCharacter,
        tostring(characterCqi),
        "UnitContext.UniqueUiId")
    local unitCqi = tonumber(unitUniqueUiId) -- UnitContext.UniqueUiId is a string

    if unitKey == nil then
        -- Some characters have no unit context (Sorceress (Shadow) heroes for example): their unit is searched in their army
        local character = TotoWar__Gameplay:getCharacter(characterCqi)
        local unit = nil

        if character ~= nil then
            unit = TotoWar__Gameplay:getCharacterUnit(character)
        end

        if unit ~= nil then
            unitKey = unit:unit_key()
            unitCqi = unit:command_queue_index()
        else
            logger:logDebug(
                "newCharacter(%s): UNIT NOT FOUND => Type: %s | Subtype: %s | Commands an army: %s | Embedded in an army: %s | Units linked to a character in its army: %s",
                characterCqi,
                function() return character ~= nil and character:character_type_key() or "character not found" end,
                function() return character ~= nil and character:character_subtype_key() or "character not found" end,
                function() return character ~= nil and character:has_military_force() end,
                function() return character ~= nil and character:is_embedded_in_military_force() end,
                function()
                    if character == nil or not character:is_embedded_in_military_force() then
                        return "none"
                    end

                    local units = character:embedded_in_military_force():unit_list()
                    local commandedUnits = {}

                    for i = 0, units:num_items() - 1, 1 do
                        local armyUnit = units:item_at(i)

                        if armyUnit:has_unit_commander() then
                            table.insert(
                                commandedUnits,
                                string.format("%s (commander: %s)", armyUnit:unit_key(), armyUnit:unit_commander():cqi()))
                        elseif not armyUnit:associated_character():is_null_interface() then
                            table.insert(
                                commandedUnits,
                                string.format("%s (character: %s)", armyUnit:unit_key(), armyUnit:associated_character():cqi()))
                        end
                    end

                    return string.format("%s of %s units: %s", #commandedUnits, units:num_items(), table.concat(commandedUnits, ", "))
                end)
        end
    end

    if unitKey == nil then
        logger:logWarning(
            "The unit of the character \"%s\" could not be found: this character is ignored in army supplies",
            function()
                local character = TotoWar__Gameplay:getCharacter(characterCqi)

                if character == nil then
                    return characterCqi
                end

                return TotoWar__Gameplay:getCharacterCaption(character)
            end)

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

        logger:logWarning(
            "The skirmish cost of the unit \"%s\" is invalid (%s): %s is used as its army supplies cost",
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
    instance.unitCqi = unitCqi
    instance.unitKey = unitKey

    if TotoWar__Gameplay:isLordUnit(characterCqi) then
        instance.unitCategory = TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.lord
    else
        instance.unitCategory = TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.hero
    end

    return instance
end

---Initializes a new instance from a unit.
---@param unitKey string Unit key.
---@param unitCqi integer? Command queue index of the unit (if we are able to get one).
---@return TotoWar_Cbac_UnitArmySuppliesCost
function TotoWar_Cbac_UnitArmySuppliesCost.newUnit(unitKey, unitCqi)
    local instance = setmetatable({}, TotoWar_Cbac_UnitArmySuppliesCost)
    instance.armySuppliesCost = common.get_context_value(
        TotoWar__Enum_CcoContextTypeIds.mainUnitRecord,
        unitKey,
        "UnmountedUnitRecordContext.BaseCost")

    if instance.armySuppliesCost <= 0 then
        -- For some reason, some units have a negative base cost (the Blue Scribes from Tzeench for example).
        -- We use the absolute value as a fallback.
        local transformedCost = math.abs(instance.armySuppliesCost)

        logger:logWarning(
            "The skirmish cost of the unit \"%s\" is invalid (%s): %s is used as its army supplies cost",
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

    return instance
end

---Gets the unit army composition type based on the category of a unit.
---@param unitKey string Unit key.
---@return TotoWar_Cbac_Enum_ArmyCompositionUnitCategories
function TotoWar_Cbac_UnitArmySuppliesCost:getUnitArmyCompositionUnitType(unitKey)
    local armyCompositionUnitType = _unitCategoriesByUnitKey[unitKey]

    if armyCompositionUnitType == nil then
        local unitGroup = common.get_context_value(
            TotoWar__Enum_CcoContextTypeIds.mainUnitRecord,
            unitKey,
            "UiUnitGroupContext.ParentGroup.Key")

        if unitGroup ~= nil then
            armyCompositionUnitType = _unitCategoriesByParentGroup[unitGroup]
        end

        if armyCompositionUnitType == nil then
            logger:logWarning(
                "The unit \"%s\" (%s) belongs to an unknown recruitment category (%s): it is counted as cavalry & monsters",
                TotoWar__Gameplay:getUnitCaption(unitKey),
                unitKey,
                unitGroup)

            armyCompositionUnitType = TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.cavalryAndMonsters
        end

        _unitCategoriesByUnitKey[unitKey] = armyCompositionUnitType
    end

    return armyCompositionUnitType
end
