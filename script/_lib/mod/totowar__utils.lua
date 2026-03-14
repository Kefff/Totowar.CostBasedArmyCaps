---Utility tools for TotoWar mods.
---@class TotoWarUtils
TotoWarUtils = {
    ---Logger.
    ---@type TotoWarLogger
    logger = nil,

    ---Player faction name.
    ---@type string
    playerFactionName = nil
}
TotoWarUtils.__index = TotoWarUtils

---Initializes a new instance.
---@return TotoWarUtils
function TotoWarUtils.new()
    local instance = setmetatable({}, TotoWarUtils)

    instance.logger = TotoWarLogger.new("TotoWar_Utils")
    instance.playerFactionName = cm:get_local_faction_name()

    instance.logger:logDebug("new(): COMPLETED")

    return instance
end

---Adds a listener.
---@param listenerNamePrefix string Prefix added to the event to name the listener.
---@param event string Event.
---@param conditionFunction function | true Function for checking whether the callback should be called when the event is triggered. Takes a context as an argument. Return a boolean. Can be `true` instead of a function to always trigger the callback function.
---@param callbackFunction function Function to execute when the event is triggered and the condition function returns `true`.
---@param isPermanent boolean? Indicates whether the listener is permanent or it should be removed immediately after the event is triggered.
function TotoWarUtils:addListener(listenerNamePrefix, event, conditionFunction, callbackFunction, isPermanent)
    if isPermanent == nil then
        isPermanent = true
    end

    ---@type string
    local listenerName = nil

    if not isPermanent then
        listenerName = string.format("%s_SingleUse_%s", listenerNamePrefix, event)
        self.logger:logDebug(
            "addListener() => Add single-use listener \"%s\" to event \"%s\"",
            function() return listenerName end,
            function() return event end)
    else
        listenerName = string.format("%s_%s", listenerNamePrefix, event)
        self.logger:logDebug(
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
    self.logger:logDebug(
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

    self.logger:logDebug(
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
    self.logger:logDebug(
        "getCharacterCaption(%s): STARTED",
        function() return character:cqi() end)

    local caption = common.get_localised_string(character:get_forename())
    local surname = common.get_localised_string(character:get_surname())

    if caption ~= "" and surname ~= "" then
        caption = caption .. " " .. surname
    end

    self.logger:logDebug(
        "getCharacterCaption(%s): COMPLETED => %s",
        function() return character:cqi() end,
        function() return caption end)

    return caption
end

---Gets the caption of a faction.
---@param factionName string Faction name.
function TotoWarUtils:getFactionCaption(factionName)
    self.logger:logDebug(
        "getFactionCaption(%s): STARTED",
        function() return factionName end)

    local caption = common.get_localised_string("factions_screen_name_" .. factionName)

    self.logger:logDebug(
        "getFactionCaption(%s): COMPLETED => %s",
        function() return factionName end,
        function() return caption end)

    return caption
end

---Get the Mod Configuration Tool if it is installed.
---@return any
function TotoWarUtils:getMct()
    self.logger:logDebug("getMct(): STARTED")

    local mct = core:get_static_object("mod_configuration_tool")

    if not mct then
        self.logger:logDebug("getMct(): NOT FOUND")
    end

    self.logger:logDebug("getMct(): COMPLETED")

    return mct
end

---Gets the caption of a unit.
---@param unitKey string Unit key.
function TotoWarUtils:getUnitCaption(unitKey)
    self.logger:logDebug(
        "getUnitCaption(%s): STARTED",
        function() return unitKey end)

    local caption = common.get_context_value("CcoMainUnitRecord", unitKey, "Name")

    self.logger:logDebug(
        "getUnitCaption(%s): COMPLETED => %s",
        function() return unitKey end,
        function() return caption end)

    return caption
end

---Indicates whether a unit is a character.
---@param unitKey string Unit key.
---@return boolean
function TotoWarUtils:isCharacter(unitKey)
    self.logger:logDebug(
        "isCharacter(%s): STARTED",
        function() return self:getUnitCaption(unitKey) end)

    -- This is a bit of a hack but it's the only way I have found to tell if a unit is a character based on the unit key
    local categoryParentIcon = common.get_context_value(
        TotoWar.enums.ccoContextTypeIds.mainUnitRecord,
        unitKey,
        "CategoryParentIcon()")
    local isCharacter = categoryParentIcon == "commander" or categoryParentIcon == "hero"

    self.logger:logDebug(
        "isCharacter(%s): COMPLETED => %s",
        function() return self:getUnitCaption(unitKey) end,
        function() return isCharacter end)

    return isCharacter
end

---Indicates whether a character is general.
---@param character CHARACTER_SCRIPT_INTERFACE character.
---@return boolean
function TotoWarUtils:isGeneral(character)
    self.logger:logDebug(
        "isGeneral(%s): STARTED",
        function() return self:getCharacterCaption(character) end)

    local isPlayerFactionGeneral =
        character:has_military_force()
        and self:canRecruitUnits(character:military_force())

    self.logger:logDebug(
        "isGeneral(%s): COMPLETED => %s",
        function() return self:getCharacterCaption(character) end,
        function() return isPlayerFactionGeneral end)

    return isPlayerFactionGeneral
end

---Indicates whether a faction is the faction of the player.
---@param factionName string Faction name.
---@return boolean
function TotoWarUtils:isPlayerFaction(factionName)
    self.logger:logDebug(
        "isPlayerFaction(%s): STARTED",
        function() return self:getFactionCaption(factionName) end)

    local isPlayerFactionGeneral = factionName == self.playerFactionName

    self.logger:logDebug(
        "isPlayerFaction(%s): COMPLETED => %s",
        function() return self:getFactionCaption(factionName) end,
        function() return isPlayerFactionGeneral end)

    return isPlayerFactionGeneral
end

---Indicates whether a character is general that belongs to the faction of the player.
---@param character CHARACTER_SCRIPT_INTERFACE Character.
---@return boolean
function TotoWarUtils:isPlayerFactionGeneral(character)
    self.logger:logDebug(
        "isPlayerFactionGeneral(%s): STARTED",
        function() return character:character_subtype_key() end)

    local isPlayerFactionGeneral =
        self:isGeneral(character)
        and self:isPlayerFaction(character:faction():name())

    self.logger:logDebug(
        "TotoWarUtils:isPlayerFactionGeneral(%s): COMPLETED => %s",
        function() return character:character_subtype_key() end,
        function() return isPlayerFactionGeneral end)

    return isPlayerFactionGeneral
end
