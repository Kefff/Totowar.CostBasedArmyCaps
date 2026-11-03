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

---Gets the unit army composition type based on the category of a unit.
---@param unitKey string Unit key.
---@return TotoWar_Cbac_Enum_ArmyCompositionUnitCategories
local function getUnitArmyCompositionUnitType(unitKey)
    logger:logDebug("getUnitArmyCompositionUnitType(%s): STARTED", unitKey)

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
                "%s (%s): unknown recruitment category %s, counted as cavalry & monsters",
                TotoWar__Gameplay:getUnitCaption(unitKey),
                unitKey,
                unitGroup)

            armyCompositionUnitType = TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.cavalryAndMonsters
        end

        _unitCategoriesByUnitKey[unitKey] = armyCompositionUnitType
    end

    logger:logDebug(
        "getUnitArmyCompositionUnitType(%s): COMPLETED => Category: %s",
        unitKey,
        armyCompositionUnitType)

    return armyCompositionUnitType
end

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
    logger:logDebug("newCharacter(%s): STARTED", characterCqi)

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
        -- Some characters have no unit context, probably because of a bug of the game (a Sorceress (Shadow) hero for example)
        local character = TotoWar__Gameplay:getCharacter(characterCqi)

        logger:logWarning(
            "%s: %s, unit not found, character not counted in army supplies",
            function()
                if character == nil then
                    return "Unknown army"
                end

                if character:has_military_force() then
                    return TotoWar__Gameplay:getArmyCaption(character:military_force())
                end

                if character:is_embedded_in_military_force() then
                    return TotoWar__Gameplay:getArmyCaption(character:embedded_in_military_force())
                end

                return string.format(
                    "%s | %s",
                    TotoWar__Gameplay:getCultureCaption(character:faction():culture()),
                    TotoWar__Gameplay:getFactionCaption(character:faction():name()))
            end,
            function() return character ~= nil and TotoWar__Gameplay:getCharacterCaption(character) or characterCqi end)
        logger:logDebug("newCharacter(%s): COMPLETED => Unit not found", characterCqi)

        return nil
    end

    instance.unitCqi = unitCqi
    instance.armySuppliesCost = instance:getUnitCost(
        unitKey,
        function()
            local character = TotoWar__Gameplay:getCharacter(characterCqi)

            if character == nil then
                return nil
            end

            -- A lord commands its army, a hero is embedded in an army
            local army = nil

            if character:has_military_force() then
                army = character:military_force()
            elseif character:is_embedded_in_military_force() then
                army = character:embedded_in_military_force()
            else
                return nil
            end

            local units = army:unit_list()

            for i = 0, units:num_items() - 1, 1 do
                local unit = units:item_at(i)

                if unit:command_queue_index() == instance.unitCqi then
                    return unit
                end
            end

            return nil
        end)
    instance.baseUnitKey = common.get_context_value(
        TotoWar__Enum_CcoContextTypeIds.mainUnitRecord,
        unitKey,
        "UnmountedUnitRecordContext.Key")
    instance.characterCqi = characterCqi
    instance.unitKey = unitKey

    if TotoWar__Gameplay:isLordUnit(characterCqi) then
        instance.unitCategory = TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.lord
    else
        instance.unitCategory = TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.hero
    end

    logger:logDebug(
        "newCharacter(%s): COMPLETED => Unit: %s | Cost: %s | Category: %s",
        characterCqi,
        instance.unitKey,
        instance.armySuppliesCost,
        instance.unitCategory)

    return instance
end

---Initializes a new instance from a unit.
---@param unitKey string Unit key.
---@param unitCqi integer? Command queue index of the unit (if we are able to get one).
---@param unit UNIT_SCRIPT_INTERFACE? Unit (if we are able to get one), used when its recruitment cost is negative.
---@return TotoWar_Cbac_UnitArmySuppliesCost
function TotoWar_Cbac_UnitArmySuppliesCost.newUnit(unitKey, unitCqi, unit)
    logger:logDebug(
        "newUnit(%s, %s, unit): STARTED",
        unitKey,
        unitCqi)

    local instance = setmetatable({}, TotoWar_Cbac_UnitArmySuppliesCost)
    instance.armySuppliesCost = instance:getUnitCost(unitKey, function() return unit end)
    instance.baseUnitKey = common.get_context_value(
        TotoWar__Enum_CcoContextTypeIds.mainUnitRecord,
        unitKey,
        "UnmountedUnitRecordContext.Key")
    instance.unitCategory = getUnitArmyCompositionUnitType(unitKey)
    instance.unitCqi = unitCqi
    instance.unitKey = unitKey

    logger:logDebug(
        "newUnit(%s, %s, unit): COMPLETED => Cost: %s | Category: %s",
        unitKey,
        unitCqi,
        instance.armySuppliesCost,
        instance.unitCategory)

    return instance
end

---Gets the army supplies cost of a unit: the recruitment cost of its unmounted version,
---or of the unit itself when its unmounted version has no cost (0 when neither has a cost).
---@param unitKey string Unit key.
---@param findUnit (fun(): UNIT_SCRIPT_INTERFACE | nil) | nil Function returning the unit, called only when its recruitment cost is negative.
---@return integer
function TotoWar_Cbac_UnitArmySuppliesCost:getUnitCost(unitKey, findUnit)
    logger:logDebug("getUnitCost(%s, findUnit): STARTED", unitKey)

    ---@type integer | nil
    local cost = common.get_context_value(
        TotoWar__Enum_CcoContextTypeIds.mainUnitRecord,
        unitKey,
        "UnmountedUnitRecordContext.BaseCost")

    if cost == nil or cost == 0 then
        cost = common.get_context_value(TotoWar__Enum_CcoContextTypeIds.mainUnitRecord, unitKey, "BaseCost")
    end

    if cost == nil then
        logger:logWarning(
            "%s (%s): recruitment cost not found, not counted in army supplies",
            TotoWar__Gameplay:getUnitCaption(unitKey),
            unitKey)
        logger:logDebug("getUnitCost(%s, findUnit): COMPLETED => Cost: 0 (recruitment cost not found)", unitKey)

        return 0
    end

    if cost >= 0 then
        logger:logDebug(
            "getUnitCost(%s, findUnit): COMPLETED => Cost: %s",
            unitKey,
            cost)

        return cost
    end

    -- Some units have a negative recruitment cost (the Blue Scribes from Tzeentch for example)
    local unit = nil

    if findUnit ~= nil then
        unit = findUnit()
    end

    if unit == nil then
        logger:logWarning(
            "%s: invalid recruitment cost (%s), not counted in army supplies (custom battle cost only readable in an army)",
            TotoWar__Gameplay:getUnitCaption(unitKey),
            cost)
        logger:logDebug("getUnitCost(%s, findUnit): COMPLETED => Cost: 0 (invalid recruitment cost)", unitKey)

        return 0
    end

    local customBattleCost = unit:get_unit_custom_battle_cost()

    logger:logWarning(
        "%s: %s, invalid recruitment cost (%s), custom battle cost used (%s)",
        function() return TotoWar__Gameplay:getArmyCaption(unit:military_force()) end,
        TotoWar__Gameplay:getUnitCaption(unitKey),
        cost,
        customBattleCost)
    logger:logDebug(
        "getUnitCost(%s, findUnit): COMPLETED => Cost: %s (custom battle cost)",
        unitKey,
        customBattleCost)

    return customBattleCost
end
