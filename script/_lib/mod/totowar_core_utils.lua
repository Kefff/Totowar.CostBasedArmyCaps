---Utility tools for TotoWar mods.
---@class TotoWarUtils
TotoWarUtils = {
    ---Enumerations
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
            characterDeselected = "CharacterDeselected",
            characterSelected = "CharacterSelected",
            panelOpenedCampaign = "PanelOpenedCampaign",
            unitDisbanded = "UnitDisbanded",
            unitMergedAndDestroyed = "UnitMergedAndDestroyed",
            unitTrained = "UnitTrained"
        }
    },

    ---Delay before triggering the callback of an event.
    ---@type number
    eventCallbackTriggerDelay = 0.1,

    ---Logger.
    ---@type TotoWarLogger
    logger = nil,

    ---Player faction name.
    ---@type string
    playerFactionName = nil,

    ---UI utility tools.
    ---@type TotoWarUIUtils
    ui = nil
}
TotoWarUtils.__index = TotoWarUtils

---Initializes a new instance.
---@return TotoWarUtils
function TotoWarUtils.new()
    local instance = setmetatable({}, TotoWarUtils)

    instance.logger = TotoWarLogger.new("totowar_utils")

    instance.playerFactionName = cm:get_local_faction_name()
    instance.ui = TotoWarUIUtils.new()

    instance.logger:logDebug("TotoWarUtils.new(): COMPLETED")

    return instance
end

---Indicates whether an army can recruit units.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE  Army.
---@return boolean
function TotoWarUtils:canRecruitUnits(army)
    self.logger:logDebug("TotoWarUtils:canRecruitUnits(%s): STARTED", army:command_queue_index())

    local canRecruitUnits =
        army:has_general()
        and not army:is_armed_citizenry()
        and not army:is_set_piece_battle_army()
        and not army:force_type():has_feature("unable_to_recruit_units")

    self.logger:logDebug("TotoWarUtils:canRecruitUnits(%s): COMPLETED => %s", army:command_queue_index(), canRecruitUnits)

    return canRecruitUnits
end

---Gets the caption of a unit.
---@param unitKey string Unit key.
function TotoWarUtils:getUnitCaption(unitKey)
    self.logger:logDebug("TotoWarUtils:getUnitCaption(%s): STARTED", unitKey)

    local caption = common.get_context_value("CcoMainUnitRecord", unitKey, "Name")

    self.logger:logDebug("TotoWarUtils:getUnitCaption(%s): COMPLETED => %s", unitKey, caption)

    return caption
end

---Indicates whether a faction is the faction of the player.
---@param factionName string name.
---@return boolean
function TotoWarUtils:isPlayerFaction(factionName)
    self.logger:logDebug("TotoWarUtils:isPlayerFaction(%s): STARTED", factionName)

    isPlayerFactionGeneral = factionName == self.playerFactionName

    self.logger:logDebug("TotoWarUtils:isPlayerFaction(%s): COMPLETED => %s", factionName, isPlayerFactionGeneral)

    return isPlayerFactionGeneral
end

---Indicates whether a character is general that belongs to the faction of the player.
---@param character CHARACTER_SCRIPT_INTERFACE character.
---@return boolean
function TotoWarUtils:isPlayerFactionGeneral(character)
    self.logger:logDebug("TotoWarUtils:isPlayerFactionGeneral(%s): STARTED", character:cqi())

    isPlayerFactionGeneral = character:has_military_force() and self:isPlayerFaction(character:faction():name())

    self.logger:logDebug(
        "TotoWarUtils:isPlayerFactionGeneral(%s): COMPLETED => %s",
        character:cqi(),
        isPlayerFactionGeneral)

    return isPlayerFactionGeneral
end
