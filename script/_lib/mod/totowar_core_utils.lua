---Utility tools for TotoWar mods.
---@class TotoWarUtils
TotoWarUtils = {
    ---Enumerations
    ---@class TotoWarUtils_Enums
    enums = {
        ---Colors.
        ---@class TotoWarUtilsColorEnum
        color = {
            blue = "alliance_ally",
            red = "alliance_enemy",
            yellow = "yellow"
        },

        ---Events.
        ---@class TotoWarUtilsEventEnum
        event = {
            ---Event triggered when a unit has been recruited.
            unitRecruited = "UnitTrained"
        }
    },

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

---Indicates whether an army can recruit units.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE  Army.
---@return boolean
function TotoWarUtils:canRecruitUnits(army)
    self.logger:logDebug("canRecruitUnits(%s): STARTED", army:command_queue_index())

    local canRecruitUnits =
        army:has_general()
        and not army:is_armed_citizenry()
        and not army:is_set_piece_battle_army()
        and not army:force_type():has_feature("unable_to_recruit_units")

    self.logger:logDebug("canRecruitUnits(%s): COMPLETED => %s", army:command_queue_index(), canRecruitUnits)

    return canRecruitUnits
end

---Gets the caption of a unit.
---@param unitKey string Unit key.
function TotoWarUtils:getUnitCaption(unitKey)
    self.logger:logDebug("getUnitCaption(%s): STARTED", unitKey)

    local caption = common.get_context_value("CcoMainUnitRecord", unitKey, "Name")

    self.logger:logDebug("getUnitCaption(%s): COMPLETED => %s", unitKey, caption)

    return caption
end

---Indicates whether a faction is the faction of the player.
---@param factionName string name.
---@return boolean
function TotoWarUtils:isPlayerFaction(factionName)
    self.logger:logDebug("isPlayerFaction(%s): STARTED", factionName)

    isPlayerFactionGeneral = factionName == self.playerFactionName

    self.logger:logDebug("isPlayerFaction(%s): COMPLETED => %s", factionName, isPlayerFactionGeneral)

    return isPlayerFactionGeneral
end

---Indicates whether a character is general that belongs to the faction of the player.
---@param character CHARACTER_SCRIPT_INTERFACE character.
---@return boolean
function TotoWarUtils:isPlayerFactionGeneral(character)
    self.logger:logDebug("isPlayerFactionGeneral(%s): STARTED", character:cqi())

    isPlayerFactionGeneral = character:has_military_force() and self:isPlayerFaction(character:faction():name())

    self.logger:logDebug(
        "TotoWarUtils:isPlayerFactionGeneral(%s): COMPLETED => %s",
        character:cqi(),
        isPlayerFactionGeneral)

    return isPlayerFactionGeneral
end
