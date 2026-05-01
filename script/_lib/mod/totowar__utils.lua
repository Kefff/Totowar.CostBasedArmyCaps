---Utility tools for TotoWar mods.
---@class TotoWarUtils
TotoWarUtils = {
    ---Player faction name.
    ---@type string
    playerFactionName = nil
}
TotoWarUtils.__index = TotoWarUtils

---Initializes a new instance.
---@return TotoWarUtils
function TotoWarUtils.new()
    TotoWar.loggers.utils:logDebug("TotoWarUtils.new(): STARTED")

    local instance = setmetatable({}, TotoWarUtils)

    instance.playerFactionName = cm:get_local_faction_name()

    TotoWar.loggers.utils:logDebug("TotoWarUtils.new(): COMPLETED")

    return instance
end

---Adds a listener.
---@param listenerNamePrefix string Prefix added to the event to name the listener.
---@param event string Event.
---@param conditionFunction boolean | fun(eventParameter: any): boolean Function for checking whether the callback should be called when the event is triggered. Takes a context as an argument. Return a boolean. Can be `true` instead of a function to always trigger the callback function.
---@param callbackFunction fun(eventParameter: any) Function to execute when the event is triggered and the condition function returns `true`.
---@param isPermanent boolean? Indicates whether the listener is permanent or it should be removed immediately after the event is triggered.
function TotoWarUtils:addListener(listenerNamePrefix, event, conditionFunction, callbackFunction, isPermanent)
    if isPermanent == nil then
        isPermanent = true
    end

    ---@type string
    local listenerName = nil

    if not isPermanent then
        listenerName = string.format("%s_SingleUse_%s", listenerNamePrefix, event)
        TotoWar.loggers.utils:logDebug(
            "addListener() => Add single-use listener \"%s\" to event \"%s\"",
            function() return listenerName end,
            function() return event end)
    else
        listenerName = string.format("%s_%s", listenerNamePrefix, event)
        TotoWar.loggers.utils:logDebug(
            "addListener() => Add listener \"%s\" to event \"%s\"",
            function() return listenerName end,
            function() return event end)
    end

    core:add_listener(listenerName, event, conditionFunction, callbackFunction, isPermanent)
end

---Indicates whether an army can recruit units.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE  Army.
---@return boolean
function TotoWarUtils:canRecruitUnits(army)
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

---Gets the caption of a character.
---@param character CHARACTER_SCRIPT_INTERFACE Character.
function TotoWarUtils:getCharacterCaption(character)
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

---Gets the caption of a faction.
---@param factionName string Faction name.
function TotoWarUtils:getFactionCaption(factionName)
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
function TotoWarUtils:getMct()
    TotoWar.loggers.utils:logDebug("getMct(): STARTED")

    local mct = core:get_static_object("mod_configuration_tool")

    if not mct then
        TotoWar.loggers.utils:logDebug("getMct(): NOT FOUND")
    end

    TotoWar.loggers.utils:logDebug("getMct(): COMPLETED")

    return mct
end

---Gets the keys of dictionary sorted in an order based on a predicate.
---
---This is because a dictionary cannot directly be sorted because when using pair() to iterate on a table,
---keys are in a random order in LUA.
---@generic T
---@param dictionary { [string]: T[] } Dictionary to sort.
---@param predicate fun(item1: T, item2: T): boolean Predicate.
---@return string[]
function TotoWarUtils:getSortedDictionaryKeys(dictionary, predicate)
    TotoWar.loggers.utils:logDebug("getSorterDictionaryKeys(): STARTED")

    local keys = {}

    for key in pairs(dictionary) do
        table.insert(keys, key)
    end

    table.sort(keys, function(key1, key2)
        return predicate(dictionary[key1], dictionary[key2])
    end)

    TotoWar.loggers.utils:logDebug("getSorterDictionaryKeys(): COMPLETED")

    return keys
end

---Gets the caption of a unit.
---@param unitKey string Unit key.
---@return string
function TotoWarUtils:getUnitCaption(unitKey)
    TotoWar.loggers.utils:logDebug(
        "getUnitCaption(%s): STARTED",
        function() return unitKey end)

    ---@type string
    local caption = common.get_context_value(TotoWar.enums.ccoContextTypeIds.mainUnitRecord, unitKey, "Name")

    TotoWar.loggers.utils:logDebug(
        "getUnitCaption(%s): COMPLETED => %s",
        function() return unitKey end,
        function() return caption end)

    return caption
end

---Indicates whether a character is a general.
---@param character CHARACTER_SCRIPT_INTERFACE character.
---@return boolean
function TotoWarUtils:isGeneralCharacter(character)
    TotoWar.loggers.utils:logDebug(
        "isGeneralCharacter(%s): STARTED",
        function() return self:getCharacterCaption(character) end)

    local isPlayerFactionGeneral =
        character:has_military_force()
        and self:canRecruitUnits(character:military_force())

    TotoWar.loggers.utils:logDebug(
        "isGeneralCharacter(%s): COMPLETED => %s",
        function() return self:getCharacterCaption(character) end,
        function() return isPlayerFactionGeneral end)

    return isPlayerFactionGeneral
end

---Indicates whether a character is a general.
---@param characterCqi integer Character command queue index. Do not use a unit CQI as it can match the CQI of a totaly unrelated character.
---@return boolean
function TotoWarUtils:isGeneralUnit(characterCqi)
    TotoWar.loggers.utils:logDebug(
        "isGeneralUnit(%s): STARTED",
        function() return characterCqi end)

    local isGeneral = false

    -- Directly searching for the character corresponding to the CQI
    isGeneral = common.get_context_value(
        TotoWar.enums.ccoContextTypeIds.campaignCharacter,
        tostring(characterCqi),
        "IsArmy")

    if not isGeneral then
        -- If the character is not found, it means we have the CQI of a unit
        -- so we need to search for the character context through the unit context
        isGeneral = common.get_context_value(
            TotoWar.enums.ccoContextTypeIds.campaignUnit,
            tostring(characterCqi),
            "CharacterContext.IsArmy")

        if not isGeneral then
            -- isGeneral can be nil when we arrive here
            isGeneral = false
        end
    end

    TotoWar.loggers.utils:logDebug(
        "isGeneralUnit(%s): COMPLETED => %s",
        function() return characterCqi end,
        function() return isGeneral end)

    return isGeneral
end

---Indicates whether a faction is the faction of the player.
---@param factionName string Faction name.
---@return boolean
function TotoWarUtils:isPlayerFaction(factionName)
    TotoWar.loggers.utils:logDebug(
        "isPlayerFaction(%s): STARTED",
        function() return self:getFactionCaption(factionName) end)

    local isPlayerFactionGeneral = factionName == self.playerFactionName

    TotoWar.loggers.utils:logDebug(
        "isPlayerFaction(%s): COMPLETED => %s",
        function() return self:getFactionCaption(factionName) end,
        function() return isPlayerFactionGeneral end)

    return isPlayerFactionGeneral
end
