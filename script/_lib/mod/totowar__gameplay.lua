require("script._lib.mod.totowar__logger")

local logger = TotoWar__Logger.get(TotoWar__Enum_LogCategories.utils)

---Utility tools for TotoWar mods.
---@class TotoWar__Gameplay
TotoWar__Gameplay = {}
TotoWar__Gameplay.__index = TotoWar__Gameplay

---Indicates whether an army can recruit units.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE  Army.
---@return boolean
function TotoWar__Gameplay:canRecruitUnits(army)
    local canRecruitUnits =
        army:has_general()
        and not army:is_armed_citizenry()
        and not army:is_set_piece_battle_army()
        and not army:force_type():has_feature("unable_to_recruit_units")

    return canRecruitUnits
end

---Removes a value from the game state.
---@param modName string Mod name.
---@param key string Key of the value to remove for the mod.
function TotoWar__Gameplay:clearSavedValue(modName, key)
    logger:logDebug("clearSavedValue(%s, %s): STARTED", modName, key)

    -- cm:clear_saved_value is defined in lib_campaign_manager.lua but missing from the type definitions
    cm:clear_saved_value(string.format("%s_%s", modName, key))

    logger:logDebug("clearSavedValue(%s, %s): COMPLETED", modName, key)
end

---Gets an army.
---@param armyCqi integer Army command queue index.
---@return MILITARY_FORCE_SCRIPT_INTERFACE|nil
function TotoWar__Gameplay:getArmy(armyCqi)
    local army = cm:get_military_force_by_cqi(armyCqi)

    if army == false then
        logger:logDebug("getArmy(%s): NOT FOUND", armyCqi)

        return nil
    end

    return army
end

---Gets the caption of an army: caption of its lord and of its faction.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@return string
function TotoWar__Gameplay:getArmyCaption(army)
    return string.format(
        "%s from %s",
        self:getArmyLordCaption(army),
        self:getFactionCaption(army:faction():name()))
end

---Gets the caption of the lord of an army.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@return string
function TotoWar__Gameplay:getArmyLordCaption(army)
    if not army:has_general() then
        return "No lord"
    end

    return self:getCharacterCaption(army:general_character())
end

---Gets a character.
---@param characterCqi integer Character command queue index. Do not use a unit CQI as it can match the CQI of a totaly unrelated character.
---@return CHARACTER_SCRIPT_INTERFACE|nil
function TotoWar__Gameplay:getCharacter(characterCqi)
    local character = cm:get_character_by_cqi(characterCqi)

    if character == false then
        logger:logWarning("A character could not be found in the campaign (CQI: %s)", characterCqi)

        return nil
    end

    return character
end

---Gets the caption of a character.
---@param character CHARACTER_SCRIPT_INTERFACE Character.
function TotoWar__Gameplay:getCharacterCaption(character)
    local caption = common.get_localised_string(character:get_forename())
    local surname = common.get_localised_string(character:get_surname())

    if caption ~= "" and surname ~= "" then
        caption = caption .. " " .. surname
    end

    return caption
end

---Gets the caption of a culture.
---@param cultureName string Culture name.
function TotoWar__Gameplay:getCultureCaption(cultureName)
    return common.get_localised_string("cultures_name_" .. cultureName)
end

---Gets a faction.
---@param factionCqi integer Faction command queue index.
function TotoWar__Gameplay:getFaction(factionCqi)
    local factionKey = cco(TotoWar__Enum_CcoContextTypeIds.factionRecord, factionCqi):Call("Key")

    return cm:get_faction(factionKey)
end

---Gets the caption of a faction.
---@param factionName string Faction name.
function TotoWar__Gameplay:getFactionCaption(factionName)
    return common.get_localised_string("factions_screen_name_" .. factionName)
end

---Get the Mod Configuration Tool if it is installed.
---@return any
function TotoWar__Gameplay:getMct()
    return core:get_static_object("mod_configuration_tool")
end

---Gets a value in the game state.
---@param modName string Mod name.
---@param key string Key of the value to save for the mod.
---@returns boolean | integer | number | string | table | nil
function TotoWar__Gameplay:getSavedValue(modName, key)
    logger:logDebug("getSavedValue(%s, %s): STARTED", modName, key)

    ---@type boolean | integer | number | string | table | nil
    local value = cm:get_saved_value(string.format("%s_%s", modName, key))

    logger:logDebug("getSavedValue(%s, %s): COMPLETED => %s", modName, key, value)

    return value
end

---Gets the caption of a unit.
---@param unitKey string Unit key.
---@return string
function TotoWar__Gameplay:getUnitCaption(unitKey)
    ---@type string
    local caption = common.get_context_value(TotoWar__Enum_CcoContextTypeIds.mainUnitRecord, unitKey, "Name")

    if caption == nil then
        caption = ''

        logger:logWarning("The name of the unit \"%s\" could not be found", unitKey)
    end

    return caption
end

---Indicates whether a faction is the faction of the local player.
---@param factionName string Faction name.
---@return boolean
function TotoWar__Gameplay:isLocalPlayerFaction(factionName)
    return factionName == cm:get_local_faction_name()
end

---Indicates whether a character is a lord.
---@param character CHARACTER_SCRIPT_INTERFACE character.
---@return boolean
function TotoWar__Gameplay:isLordCharacter(character)
    local isGarrisonCommander = common.get_context_value(
        TotoWar__Enum_CcoContextTypeIds.campaignCharacter,
        tostring(character:cqi()),
        "IsGarrisonCommander")
    return character:has_military_force() and not isGarrisonCommander
end

---Indicates whether a character is a lord.
---@param characterCqi integer Character command queue index. Do not use a unit CQI as it can match the CQI of a totaly unrelated character.
---@return boolean
function TotoWar__Gameplay:isLordUnit(characterCqi)
    -- Directly searching for the character corresponding to the CQI
    ---@type boolean
    local isLord = common.get_context_value(
        TotoWar__Enum_CcoContextTypeIds.campaignCharacter,
        tostring(characterCqi),
        "IsArmy")

    ---@type boolean
    local isGarrisonCommander = common.get_context_value(
        TotoWar__Enum_CcoContextTypeIds.campaignCharacter,
        tostring(characterCqi),
        "IsGarrisonCommander")

    if not isLord then
        -- If the character is not found, it means we have the CQI of a unit
        -- so we need to search for the character context through the unit context
        isLord = common.get_context_value(
            TotoWar__Enum_CcoContextTypeIds.campaignUnit,
            tostring(characterCqi),
            "CharacterContext.IsArmy")
        isGarrisonCommander = common.get_context_value(
            TotoWar__Enum_CcoContextTypeIds.campaignUnit,
            tostring(characterCqi),
            "CharacterContext.IsGarrisonCommander")

        if not isLord then
            -- isLord can be nil when we arrive here
            isLord = false
        end
    end

    return isLord and not isGarrisonCommander
end

---Saves a value in the game state.
---@param modName string Mod name.
---@param key string Key of the value to save for the mod.
---@param value boolean | integer | number | string | table | nil Value to save for the mod.
function TotoWar__Gameplay:saveValue(modName, key, value)
    logger:logDebug("saveValue(%s, %s, %s): STARTED", modName, key, value)

    cm:set_saved_value(string.format("%s_%s", modName, key), value)

    logger:logDebug("saveValue(%s, %s, %s): COMPLETED", modName, key, value)
end
