---Utility tools for TotoWar mods.
---@class TotoWar__Gameplay
TotoWar__Gameplay = {}
TotoWar__Gameplay.__index = TotoWar__Gameplay

---Indicates whether an army can recruit units.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE  Army.
---@return boolean
function TotoWar__Gameplay:canRecruitUnits(army)
    TotoWar.loggers.utils:logDebug(
        "canRecruitUnits(%s): STARTED",
        function()
            if army:has_general() then
                return self:getCharacterCaption(army:general_character())
            end

            return army:command_queue_index()
        end)

    local canRecruitUnits =
        army:has_general()
        and not army:is_armed_citizenry()
        and not army:is_set_piece_battle_army()
        and not army:force_type():has_feature("unable_to_recruit_units")

    TotoWar.loggers.utils:logDebug(
        "canRecruitUnits(%s): COMPLETED => %s",
        function()
            if army:has_general() then
                return self:getCharacterCaption(army:general_character())
            end

            return army:command_queue_index()
        end,
        function() return canRecruitUnits end)

    return canRecruitUnits
end

---Gets a character.
---@param characterCqi integer Character command queue index. Do not use a unit CQI as it can match the CQI of a totaly unrelated character.
---@return CHARACTER_SCRIPT_INTERFACE|nil
function TotoWar__Gameplay:getCharacter(characterCqi)
    TotoWar.loggers.utils:logDebug(
        "getCharacterCaption(%s): STARTED",
        function() return characterCqi end)

    local character = cm:get_character_by_cqi(characterCqi)

    if not character then
        TotoWar.loggers.utils:logWarning(
            "getCharacterCaption(%s): NOT FOUND",
            characterCqi)

        return nil
    else
        TotoWar.loggers.utils:logDebug(
            "getCharacterCaption(%s): COMPLETED => %s",
            function() return characterCqi end,
            function() return self:getCharacterCaption(character) end)
    end

    return character
end

---Gets the caption of a character.
---@param character CHARACTER_SCRIPT_INTERFACE Character.
function TotoWar__Gameplay:getCharacterCaption(character)
    TotoWar.loggers.utils:logDebug(
        "getCharacterCaption(%s): STARTED",
        function() return character:cqi() end)

    local caption = common.get_localised_string(character:get_forename())
    local surname = common.get_localised_string(character:get_surname())

    if caption ~= "" and surname ~= "" then
        caption = caption .. " " .. surname
    end

    TotoWar.loggers.utils:logDebug(
        "getCharacterCaption(%s): COMPLETED => %s",
        function() return character:cqi() end,
        function() return caption end)

    return caption
end

---Gets the caption of a culture.
---@param cultureName string Culture name.
function TotoWar__Gameplay:getCultureCaption(cultureName)
    TotoWar.loggers.utils:logDebug(
        "getCultureCaption(%s): STARTED",
        function() return cultureName end)

    local caption = common.get_localised_string("cultures_name_" .. cultureName)

    TotoWar.loggers.utils:logDebug(
        "getCultureCaption(%s): COMPLETED => %s",
        function() return cultureName end,
        function() return caption end)

    return caption
end

---Gets a faction.
---@param factionCqi integer Faction command queue index.
function TotoWar__Gameplay:getFaction(factionCqi)
    TotoWar.loggers.utils:logDebug(
        "getFaction(%s): STARTED",
        function() return factionCqi end)

    local factionKey = cco(TotoWar__Enum_CcoContextTypeIds.factionRecord, factionCqi):Call("Key")
    local faction = cm:get_faction(factionKey)

    TotoWar.loggers.utils:logDebug(
        "getFaction(%s): COMPLETED => %s",
        function() return factionCqi end,
        function() return self:getFactionCaption(faction:name()) end)

    return faction
end

---Gets the caption of a faction.
---@param factionName string Faction name.
function TotoWar__Gameplay:getFactionCaption(factionName)
    TotoWar.loggers.utils:logDebug(
        "getFactionCaption(%s): STARTED",
        function() return factionName end)

    local caption = common.get_localised_string("factions_screen_name_" .. factionName)

    TotoWar.loggers.utils:logDebug(
        "getFactionCaption(%s): COMPLETED => %s",
        function() return factionName end,
        function() return caption end)

    return caption
end

---Get the Mod Configuration Tool if it is installed.
---@return any
function TotoWar__Gameplay:getMct()
    TotoWar.loggers.utils:logDebug("getMct(): STARTED")

    local mct = core:get_static_object("mod_configuration_tool")

    if not mct then
        TotoWar.loggers.utils:logDebug("getMct(): NOT FOUND")
    end

    TotoWar.loggers.utils:logDebug("getMct(): COMPLETED")

    return mct
end

---Gets the caption of a unit.
---@param unitKey string Unit key.
---@return string
function TotoWar__Gameplay:getUnitCaption(unitKey)
    TotoWar.loggers.utils:logDebug(
        "getUnitCaption(%s): STARTED",
        function() return unitKey end)

    ---@type string
    local caption = common.get_context_value(TotoWar__Enum_CcoContextTypeIds.mainUnitRecord, unitKey, "Name")

    if caption == nil then
        caption = ''

        TotoWar.loggers.utils:logWarning("Caption not found for unit \"%s\"", unitKey)
    end

    TotoWar.loggers.utils:logDebug(
        "getUnitCaption(%s): COMPLETED => %s",
        function() return unitKey end,
        function() return caption end)

    return caption
end

---Indicates whether a character is a lord.
---@param character CHARACTER_SCRIPT_INTERFACE character.
---@return boolean
function TotoWar__Gameplay:isLordCharacter(character)
    TotoWar.loggers.utils:logDebug(
        "isLordCharacter(%s): STARTED",
        function() return self:getCharacterCaption(character) end)

    local isGarrisonCommander = common.get_context_value(
        TotoWar__Enum_CcoContextTypeIds.campaignCharacter,
        tostring(character:cqi()),
        "IsGarrisonCommander")
    local isLord = character:has_military_force() and not isGarrisonCommander

    TotoWar.loggers.utils:logDebug(
        "isLordCharacter(%s): COMPLETED => %s",
        function() return self:getCharacterCaption(character) end,
        function() return isLord end)

    return isLord
end

---Indicates whether a character is a lord.
---@param characterCqi integer Character command queue index. Do not use a unit CQI as it can match the CQI of a totaly unrelated character.
---@return boolean
function TotoWar__Gameplay:isLordUnit(characterCqi)
    TotoWar.loggers.utils:logDebug(
        "isLordUnit(%s): STARTED",
        function() return characterCqi end)

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

    isLord = isLord and not isGarrisonCommander

    TotoWar.loggers.utils:logDebug(
        "isLordUnit(%s): COMPLETED => %s",
        function() return characterCqi end,
        function() return isLord end)

    return isLord
end

---Indicates whether a faction is the faction of the player.
---@param factionName string Faction name.
---@return boolean
function TotoWar__Gameplay:isPlayerFaction(factionName)
    TotoWar.loggers.utils:logDebug(
        "isPlayerFaction(%s): STARTED",
        function() return self:getFactionCaption(factionName) end)

    local isPlayerFactionLord = factionName == cm:get_local_faction_name()

    TotoWar.loggers.utils:logDebug(
        "isPlayerFaction(%s): COMPLETED => %s",
        function() return self:getFactionCaption(factionName) end,
        function() return isPlayerFactionLord end)

    return isPlayerFactionLord
end

---Gets a value in the game state.
---@param modName string Mod name.
---@param key string Key of the value to save for the mod.
---@returns boolean | integer | number | string | nil
function TotoWar__Gameplay:getSavedValue(modName, key)
    TotoWar.loggers.utils:logDebug(
        "getValue(%s, %s): STARTED",
        function() return modName end,
        function() return key end)

    ---@type boolean | integer | number | string | nil
    local value = cm:get_saved_value(string.format("%s_%s", modName, key))

    TotoWar.loggers.utils:logDebug(
        "getValue(%s, %s): COMPLETED => %s",
        function() return modName end,
        function() return key end,
        function() return value end)

    return value
end

---Saves a value in the game state.
---@param modName string Mod name.
---@param key string Key of the value to save for the mod.
---@param value boolean | integer | number | string | nil Value to save for the mod.
function TotoWar__Gameplay:saveValue(modName, key, value)
    TotoWar.loggers.utils:logDebug(
        "saveValue(%s, %s, %s): STARTED",
        function() return modName end,
        function() return key end,
        function() return value end)

    cm:set_saved_value(string.format("%s_%s", modName, key), value)

    TotoWar.loggers.utils:logDebug(
        "saveValue(%s, %s, %s): COMPLETED",
        function() return modName end,
        function() return key end,
        function() return value end)
end
