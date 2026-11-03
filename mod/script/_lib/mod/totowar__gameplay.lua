require("script._lib.mod.totowar__logger")

local logger = TotoWar__Logger.get(TotoWar__Enum_LogCategories.gameplay)

---Utility tools for TotoWar mods.
---@class TotoWar__Gameplay
TotoWar__Gameplay = {}
TotoWar__Gameplay.__index = TotoWar__Gameplay

---Indicates whether an army can recruit units.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE  Army.
---@return boolean
function TotoWar__Gameplay:canRecruitUnits(army)
    logger:logDebug(
        "canRecruitUnits(army): STARTED => %s",
        function() return self:getArmyCaption(army) end)

    local canRecruitUnits =
        army:has_general()
        and not army:is_armed_citizenry()
        and not army:is_set_piece_battle_army()
        and not army:force_type():has_feature("unable_to_recruit_units")

    logger:logDebug(
        "canRecruitUnits(army): COMPLETED => %s | Can recruit units: %s",
        function() return self:getArmyCaption(army) end,
        canRecruitUnits)

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
    logger:logDebug("getArmy(%s): STARTED", armyCqi)

    local army = cm:get_military_force_by_cqi(armyCqi)

    if army == false then
        logger:logDebug("getArmy(%s): COMPLETED => Not found", armyCqi)

        return nil
    end

    logger:logDebug(
        "getArmy(%s): COMPLETED => %s",
        armyCqi,
        function() return self:getArmyCaption(army) end)

    return army
end

---Gets the caption of an army: caption of its culture, of its faction and of its lord (`Culture | Faction | Lord`).
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@return string
function TotoWar__Gameplay:getArmyCaption(army)
    return string.format(
        "%s | %s",
        self:getFactionFullCaption(army:faction()),
        self:getArmyLordCaption(army))
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
    logger:logDebug("getCharacter(%s): STARTED", characterCqi)

    local character = cm:get_character_by_cqi(characterCqi)

    if character == false then
        logger:logWarning("Character %s: not found in the campaign", characterCqi)
        logger:logDebug("getCharacter(%s): COMPLETED => Not found", characterCqi)

        return nil
    end

    logger:logDebug(
        "getCharacter(%s): COMPLETED => %s",
        characterCqi,
        function() return self:getCharacterFullCaption(character) end)

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

---Gets the full caption of a character: caption of its culture, of its faction and of the character (`Culture | Faction | Character`).
---@param character CHARACTER_SCRIPT_INTERFACE Character.
---@return string
function TotoWar__Gameplay:getCharacterFullCaption(character)
    return string.format(
        "%s | %s",
        self:getFactionFullCaption(character:faction()),
        self:getCharacterCaption(character))
end

---Gets the caption of a culture.
---@param cultureName string Culture name.
function TotoWar__Gameplay:getCultureCaption(cultureName)
    return common.get_localised_string("cultures_name_" .. cultureName)
end

---Gets a faction.
---@param factionCqi integer Faction command queue index.
function TotoWar__Gameplay:getFaction(factionCqi)
    logger:logDebug("getFaction(%s): STARTED", factionCqi)

    local faction = cm:model():faction_for_command_queue_index(factionCqi)

    logger:logDebug(
        "getFaction(%s): COMPLETED => %s",
        factionCqi,
        function() return self:getFactionFullCaption(faction) end)

    return faction
end

---Gets the caption of a faction.
---@param factionName string Faction name.
function TotoWar__Gameplay:getFactionCaption(factionName)
    return common.get_localised_string("factions_screen_name_" .. factionName)
end

---Gets the full caption of a faction: caption of its culture and of the faction (`Culture | Faction`).
---@param faction FACTION_SCRIPT_INTERFACE Faction.
---@return string
function TotoWar__Gameplay:getFactionFullCaption(faction)
    return string.format(
        "%s | %s",
        self:getCultureCaption(faction:culture()),
        self:getFactionCaption(faction:name()))
end

---Get the Mod Configuration Tool if it is installed.
---@return any
function TotoWar__Gameplay:getMct()
    logger:logDebug("getMct(): STARTED")

    local mct = core:get_static_object("mod_configuration_tool")

    logger:logDebug("getMct(): COMPLETED => Installed: %s", mct ~= nil)

    return mct
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

        logger:logWarning("%s: unit name not found", unitKey)
    end

    return caption
end

---Indicates whether a faction is the faction of the local player.
---@param factionName string Faction name.
---@return boolean
function TotoWar__Gameplay:isLocalPlayerFaction(factionName)
    logger:logDebug(
        "isLocalPlayerFaction(%s): STARTED => %s",
        factionName,
        function() return self:getFactionFullCaption(cm:get_faction(factionName)) end)

    local isLocalPlayerFaction = factionName == cm:get_local_faction_name()

    logger:logDebug(
        "isLocalPlayerFaction(%s): COMPLETED => %s | Local player faction: %s",
        factionName,
        function() return self:getFactionFullCaption(cm:get_faction(factionName)) end,
        isLocalPlayerFaction)

    return isLocalPlayerFaction
end

---Indicates whether a character is a lord.
---@param character CHARACTER_SCRIPT_INTERFACE character.
---@return boolean
function TotoWar__Gameplay:isLordCharacter(character)
    logger:logDebug(
        "isLordCharacter(character): STARTED => %s",
        function() return self:getCharacterFullCaption(character) end)

    local isGarrisonCommander = common.get_context_value(
        TotoWar__Enum_CcoContextTypeIds.campaignCharacter,
        tostring(character:cqi()),
        "IsGarrisonCommander")
    local isLord = character:has_military_force() and not isGarrisonCommander

    logger:logDebug(
        "isLordCharacter(character): COMPLETED => %s | Lord: %s",
        function() return self:getCharacterFullCaption(character) end,
        isLord)

    return isLord
end

---Indicates whether a character is a lord.
---@param characterCqi integer Character command queue index. Do not use a unit CQI as it can match the CQI of a totaly unrelated character.
---@return boolean
function TotoWar__Gameplay:isLordUnit(characterCqi)
    logger:logDebug("isLordUnit(%s): STARTED", characterCqi)

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

    local isLordUnit = isLord and not isGarrisonCommander

    logger:logDebug("isLordUnit(%s): COMPLETED => %s", characterCqi, isLordUnit)

    return isLordUnit
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
