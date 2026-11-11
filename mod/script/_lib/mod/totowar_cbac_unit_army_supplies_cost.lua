local logger = TotoWar__Logger.get(TotoWar_Cbac_Enum_LogCategories.unitArmySuppliesCost)

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

---Keys of the base units already found, by unit key.
---@type table<string, string>
local _baseUnitKeysByUnitKey = {}

---Recruitment costs of the unit records already read, by unit key (`false` when the cost is not found).
---They can be negative: the custom battle cost of the unit is then used, which is specific to each unit and not cached.
---@type table<string, integer | false>
local _recordCostsByUnitKey = {}

---Gets the key of the base unit a unit derives from (like mounted characters).
---@param unitKey string Unit key.
---@return string
local function getBaseUnitKey(unitKey)
    local baseUnitKey = _baseUnitKeysByUnitKey[unitKey]

    if baseUnitKey == nil then
        baseUnitKey = common.get_context_value(
            TotoWar__Enum_CcoContextTypeIds.mainUnitRecord,
            unitKey,
            "UnmountedUnitRecordContext.Key")
        _baseUnitKeysByUnitKey[unitKey] = baseUnitKey
    end

    return baseUnitKey
end

---Gets the recruitment cost of a unit record, which is the cost of its base unit if it derives from one.
---@param unitKey string Unit key.
---@return integer | nil # `nil` when the cost is not found.
local function getUnitRecordCost(unitKey)
    local cost = _recordCostsByUnitKey[unitKey]

    if cost == nil then
        cost = common.get_context_value(
            TotoWar__Enum_CcoContextTypeIds.mainUnitRecord,
            unitKey,
            "UnmountedUnitRecordContext.BaseCost")

        if cost == nil or cost == 0 then
            cost = common.get_context_value(TotoWar__Enum_CcoContextTypeIds.mainUnitRecord, unitKey, "BaseCost")
        end

        _recordCostsByUnitKey[unitKey] = cost or false
    end

    return cost or nil
end

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

    ---Experience level of the unit (its rank, from 0 to 9), or 0 when the unit is not yet in the army (being recruited).
    ---For a character, rank of the character.
    ---Used to remove the least experienced units first when adjusting AI armies.
    experienceLevel = 0,

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
    local character = TotoWar__Gameplay:getCharacter(characterCqi)

    logger:logDebug(
        "newCharacter(%s): STARTED => %s",
        characterCqi,
        function()
            return character ~= nil and TotoWar__Gameplay:getCharacterFullCaption(character) or "Character not found"
        end)

    local instance = setmetatable({}, TotoWar_Cbac_UnitArmySuppliesCost)

    -- Finding the unit of the character in its army: a lord commands its army, a hero is embedded in an army
    ---@type UNIT_SCRIPT_INTERFACE | nil
    local unit = nil
    local army = nil

    if character ~= nil and character:has_military_force() then
        army = character:military_force()
    elseif character ~= nil and character:is_embedded_in_military_force() then
        army = character:embedded_in_military_force()
    end

    if army ~= nil then
        local units = army:unit_list()

        for i = 0, units:num_items() - 1, 1 do
            local armyUnit = units:item_at(i)

            -- The unit of a lord has the lord as unit commander
            local isCommandedByCharacter =
                armyUnit:has_unit_commander()
                and armyUnit:unit_commander():command_queue_index() == characterCqi

            -- The unit of a hero (agent) has the hero as associated character
            local associatedCharacter = armyUnit:associated_character()
            local isAssociatedWithCharacter =
                not associatedCharacter:is_null_interface()
                and associatedCharacter:command_queue_index() == characterCqi

            if isCommandedByCharacter or isAssociatedWithCharacter then
                unit = armyUnit
                break
            end
        end
    end

    local unitKey = common.get_context_value(
        TotoWar__Enum_CcoContextTypeIds.campaignCharacter,
        tostring(characterCqi),
        "UnitContext.UnitRecordContext.Key")

    -- Some characters have no unit context, probably because of a bug of the game (a Sorceress (Shadow) hero for example):
    -- the key of their unit in the army is used instead
    if unitKey == nil and unit ~= nil then
        unitKey = unit:unit_key()
    end

    -- A hero alone has no unit context (only a lord commanding an army or a hero embedded in an army has one):
    -- the unit record of its unit details (shown in the unit information panel) is used instead
    if unitKey == nil then
        unitKey = common.get_context_value(
            TotoWar__Enum_CcoContextTypeIds.campaignCharacter,
            tostring(characterCqi),
            "UnitDetailsContext.UnitRecordContext.Key")
    end

    if unitKey == nil then
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

                return TotoWar__Gameplay:getFactionFullCaption(character:faction())
            end,
            function() return character ~= nil and TotoWar__Gameplay:getCharacterCaption(character) or characterCqi end)
        logger:logDebug(
            "newCharacter(%s): COMPLETED => %s | Unit not found",
            characterCqi,
            function()
                return character ~= nil and TotoWar__Gameplay:getCharacterFullCaption(character) or "Character not found"
            end)

        return nil
    end

    instance.unitCqi = unit ~= nil and unit:command_queue_index() or nil
    instance.armySuppliesCost = instance:getUnitCost(unitKey, function() return unit end)
    instance.baseUnitKey = getBaseUnitKey(unitKey)
    instance.characterCqi = characterCqi
    instance.unitKey = unitKey

    instance.experienceLevel = character ~= nil and character:rank() or 0

    if TotoWar__Gameplay:isLordUnit(characterCqi) then
        instance.unitCategory = TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.lord
    else
        instance.unitCategory = TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.hero
    end

    logger:logDebug(
        "newCharacter(%s): COMPLETED => %s | Unit: %s | Unit CQI: %s | Cost: %s | Category: %s",
        characterCqi,
        function()
            return character ~= nil and TotoWar__Gameplay:getCharacterFullCaption(character) or "Character not found"
        end,
        instance.unitKey,
        instance.unitCqi,
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
        "newUnit(%s, %s, unit): STARTED => %s",
        unitKey,
        unitCqi,
        function() return unit ~= nil and TotoWar__Gameplay:getArmyCaption(unit:military_force()) or "No army" end)

    local instance = setmetatable({}, TotoWar_Cbac_UnitArmySuppliesCost)
    instance.armySuppliesCost = instance:getUnitCost(unitKey, function() return unit end)
    instance.baseUnitKey = getBaseUnitKey(unitKey)
    instance.unitCategory = getUnitArmyCompositionUnitType(unitKey)
    instance.unitCqi = unitCqi
    instance.unitKey = unitKey
    -- The unit is not given for a unit being recruited, which has no experience yet
    instance.experienceLevel = unit ~= nil and unit:experience_level() or 0

    logger:logDebug(
        "newUnit(%s, %s, unit): COMPLETED => %s | Cost: %s | Category: %s",
        unitKey,
        unitCqi,
        function() return unit ~= nil and TotoWar__Gameplay:getArmyCaption(unit:military_force()) or "No army" end,
        instance.armySuppliesCost,
        instance.unitCategory)

    return instance
end

---Gets the army supplies cost of a unit: the recruitment cost of its unmounted version,
---or of the unit itself when its unmounted version has no cost.
---When the recruitment cost is not found or negative, the custom battle cost of the unit is used (0 when the unit is not found).
---@param unitKey string Unit key.
---@param findUnit (fun(): UNIT_SCRIPT_INTERFACE | nil) | nil Function returning the unit, called only when its recruitment cost is not found or negative.
---@return integer
function TotoWar_Cbac_UnitArmySuppliesCost:getUnitCost(unitKey, findUnit)
    logger:logDebug("getUnitCost(%s, findUnit): STARTED", unitKey)

    local cost = getUnitRecordCost(unitKey)

    if cost ~= nil and cost >= 0 then
        logger:logDebug(
            "getUnitCost(%s, findUnit): COMPLETED => Cost: %s",
            unitKey,
            cost)

        return cost
    end

    -- Some units have a negative recruitment cost (the Blue Scribes from Tzeentch for example) or no recruitment cost:
    -- their custom battle cost is used instead, but it can only be read from a unit in an army
    local unit = nil

    if findUnit ~= nil then
        unit = findUnit()
    end

    if unit == nil then
        logger:logWarning(
            "%s (%s): invalid recruitment cost (%s), not counted in army supplies (custom battle cost only readable in an army)",
            TotoWar__Gameplay:getUnitCaption(unitKey),
            unitKey,
            cost ~= nil and cost or "not found")
        logger:logDebug("getUnitCost(%s, findUnit): COMPLETED => Cost: 0 (invalid recruitment cost)", unitKey)

        return 0
    end

    local customBattleCost = unit:get_unit_custom_battle_cost()

    logger:logWarning(
        "%s: %s, invalid recruitment cost (%s), custom battle cost used (%s)",
        function() return TotoWar__Gameplay:getArmyCaption(unit:military_force()) end,
        TotoWar__Gameplay:getUnitCaption(unitKey),
        cost ~= nil and cost or "not found",
        customBattleCost)
    logger:logDebug(
        "getUnitCost(%s, findUnit): COMPLETED => Cost: %s (custom battle cost)",
        unitKey,
        customBattleCost)

    return customBattleCost
end
