---TotoWar base mod.
---@class TotoWarMod
TotoWarMod = {
    ---Generic logger for elements that do not have a dedicated logger.
    ---@type TotoWarLogger
    genericLogger = nil,

    ---Enums
    ---@class TotoWar_Enums
    enums = {
        ---Component context object type IDs.
        ---@class TotoWar_Enums_CcoContextTypeIds
        ccoContextTypeIds = {
            ---Character. ID: character CQI.
            campaignCharacter = "CcoCampaignCharacter",

            ---Unit. ID: unit CQI.
            campaignUnit = "CcoCampaignUnit",

            ---Main unit record. ID: unit key.
            mainUnitRecord = "CcoMainUnitRecord"
        },

        ---Colors.
        ---@class TotoWar_Enums_CharacterTypes
        characterTypes = {
            general = "general"
        },

        ---Events triggered by the game.
        ---@class TotoWar_Enums_GameEvents
        gameEvents = {
            ---Event triggered when a character is deselected.
            ---Is not triggered when a character is already selected and the player selects another character.
            characterDeselected = "CharacterDeselected",

            ---Event triggered when a character is selected.
            characterSelected = "CharacterSelected",

            ---Event triggered when the left click on a UI component is released.
            componentLeftClick = "ComponentLClickUp",

            --Event triggered when the turn of a faction starts.
            factionTurnStart = "FactionTurnStart",

            ---Event triggered when a panel is opened.
            panelOpened = "PanelOpenedCampaign",

            ---Event triggered when a panel is closed.
            panelClosed = "PanelClosedCampaign",

            ---Event triggered when a unit is removed from the recruitment queue.
            unitRemovedFromRecruitment = "RecruitmentItemCancelledByPlayer",

            ---Event triggered when a unit is added to the recruitment queue.
            unitAddedToRecruitment = "RecruitmentItemIssuedByPlayer",

            ---Event triggered when (a) unit(s) have been disbanded.
            unitDisbanded = "UnitDisbanded",

            ---Event triggered when units are merged unit and some of them have been destroyed.
            unitMergedAndDestroyed = "UnitMergedAndDestroyed",

            ---Event triggered when a unit is added to an army.
            unitTrained = "UnitTrained"
        },

        ---Events triggered by the mod.
        ---@class TotoWar_Enums_ModEvents
        modEvents = {
            ---Event triggered when options are updated in the Mod Configuration Tool if it is installed.
            mctOptionsUpdated = "MctFinalized",

            ---Event triggered when options are updated.
            ---This differs from `mctOptionsUpdated` as it is used to signal that TotoWar option values
            ---have been updated by reading values from the Mod Configuration Tool.
            optionsUpdated = "TotoWar_OptionsUpdated"
        },

        ---UI component states.
        ---@class TotoWar_Enums_UIComponentStates
        uiComponentStates = {
            ---Active.
            active = "active",

            ---Inactive.
            inactive = "inactive",

            ---Selected.
            selected = "selected"
        },

        ---Docking points.
        ---@class TotoWar_Enums_DockingPoints
        uiDockingPoints = {
            topLeft = 1,
            topMiddle = 2,
            topRight = 3,
            middleLeft = 4,
            center = 5,
            middleRight = 6,
            bottomLeft = 7,
            bottomMiddle = 8,
            bottomRight = 9
        },

        ---Panels.
        ---@class TotoWar_Enums_Panels
        uiPanels = {
            ---Mercenary recruitment panel (allied recruitment, units of renown, dwarf grudge settlers, Waaagh mobs, ...)
            mercenaryRecruitment = "mercenary_recruitment",

            ---Panel that contains the recruitment panels
            recruitmentOptions = "recruitment_options",

            ---Standard recruitment panel
            standardRecruitment = "units_recruitment",

            ---Panel that allows to exchange units between armies.
            unitExchange = "unit_exchange",

            ---Selected army unit list panel.
            unitsPanel = "units_panel"
        },

        ---Patterns for finding UI elements.
        ---@class TotoWar_Enums_Patterns
        uiPatterns = {
            ---Pattern for identifying a UI component corresponding to the unit card of a recruitable mercenary
            ---unit (regiment of renown, Waaagh mobs, Grudge settlers, ...).
            inRecruitmentMercenaryUnitCard = "^temp_merc_",

            ---Pattern for identifying a UI component corresponding to the unit card of recruitable standard
            ---unit in the selected army recruitment queue.
            inRecruitmentStandardUnitCard = "^QueuedLandUnit",

            ---Pattern for identifying a UI component corresponding to the unit card of a mercenary
            ---unit (regiment of renown, Waaagh mobs, Grudge settlers, ...) in the selected army recruitment
            ---queue.
            recruitableMercenaryUnitCard = "^wh%d*_.*_mercenary$",

            ---Pattern for identifying a UI component corresponding to the unit card of an agent during unit exchange.
            unitExchangeAgentCard = "^AgentCard",

            ---Pattern for identifying a UI component corresponding to a unit card during unit exchange.
            unitExchangeUnitCard = "^UnitCard"
        }
    },

    ---Mods manager.
    ---@type TotoWarModsManager
    modsManager = nil,

    ---Options
    ---@class TotoWar_Options
    options = {
        ---Indicates whether debug messages are logged.
        debugEnabled = TotoWar_OptionDefaultValue_DebugEnabled,
    },

    ---Utility tools for TotoWar mods.
    ---@type TotoWarUtils
    utils = nil,

    ---Utility tools for TotoWar mods.
    ---@type TotoWarUIUtils
    ui = nil
}
TotoWarMod.__index = TotoWarMod

---TotoWar base mod instance.
---@type TotoWarMod
TotoWar = nil

---Initializes a new instance.
---@return TotoWarMod
function TotoWarMod.new()
    TotoWar = setmetatable({}, TotoWarMod)

    TotoWar.genericLogger = TotoWarLogger.new("TotoWar_Generic", nil, true)

    TotoWar.modsManager = TotoWarModsManager.new()
    TotoWar.utils = TotoWarUtils.new()
    TotoWar.ui = TotoWarUIUtils.new()

    TotoWar:loadMctOptions()
    TotoWar:addListeners()

    TotoWar.genericLogger:logDebug("TotoWarCore.new(): COMPLETED")

    return TotoWar
end

---Adds event listeners.
function TotoWarMod:addListeners()
    TotoWar.utils:addListener(
        "TotoWar",
        TotoWar.enums.gameEvents.factionTurnStart,
        true,
        ---@param context TotoWarGameEventContext_FactionTurnStart
        function(context)
            self:onFactionTurnStart(context:faction())
        end)

    TotoWar.utils:addListener(
        "TotoWar",
        TotoWar.enums.modEvents.mctOptionsUpdated,
        true,
        function()
            self:onOptionsUpdated()
        end)
end

---Loads option values stored by the Mod Configuration Tool if it is installed.
function TotoWarMod:loadMctOptions()
    local mct = self.utils:getMct()

    if not mct then
        return
    end

    self.genericLogger:logDebug("loadMctOptions(): STARTED")

    local options = mct:get_mod_by_key(TotoWar_ModName)
    self.genericLogger.isEnabled = options
        :get_option_by_key(TotoWar_OptionName_GenericLoggerEnabled)
        :get_finalized_setting()
    self.ui.logger.isEnabled = options
        :get_option_by_key(TotoWar_OptionName_UiUtilsLoggerEnabled)
        :get_finalized_setting()
    self.utils.logger.isEnabled = options
        :get_option_by_key(TotoWar_OptionName_UtilsLoggerEnabled)
        :get_finalized_setting()
    self.options.debugEnabled = options
        :get_option_by_key(TotoWar_OptionName_DebugEnabled)
        :get_finalized_setting()

    self.genericLogger:logDebug("loadMctOptions(): COMPLETED")
end

---Reacts to the start of the turn of a faction.
---@param faction FACTION_SCRIPT_INTERFACE Faction.
function TotoWarMod:onFactionTurnStart(faction)
    self.genericLogger:logInfo(
        "\n\n==================== NEW TURN | %s ====================\n\n",
        TotoWar.utils:getFactionCaption(faction:name()))
end

---Reacts to options being updated.
function TotoWarMod:onOptionsUpdated()
    self.genericLogger:logDebug("[EVENT] onOptionsUpdated(): STARTED")

    self:loadMctOptions()

    -- Signaling option changes
    core:trigger_event(self.enums.modEvents.optionsUpdated)

    self.genericLogger:logDebug("[EVENT] onOptionsUpdated(): COMPLETED")
end
