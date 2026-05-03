---TotoWar base mod.
---@class TotoWarMod
TotoWarMod = {
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
            lord = "lord"
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

            --Event triggered when an army is created.
            militaryForceCreated = "MilitaryForceCreated",

            ---Event triggered when a panel is opened.
            panelOpened = "PanelOpenedCampaign",

            ---Event triggered when a panel is closed.
            panelClosed = "PanelClosedCampaign",

            ---Event triggered when a unit is removed from the recruitment queue.
            unitRemovedFromRecruitment = "RecruitmentItemCancelledByPlayer",

            ---Event triggered when a unit is added to the recruitment queue.
            unitAddedToRecruitment = "RecruitmentItemIssuedByPlayer",

            ---Event triggered when a unit have been converted.
            unitConverted = "UnitConverted",

            ---Event triggered when a unit have been created.
            unitCreated = "UnitCreated",

            ---Event triggered when a unit have been disbanded.
            unitDisbanded = "UnitDisbanded",

            ---Event triggered when units are merged unit and some of them have been destroyed.
            unitMergedAndDestroyed = "UnitMergedAndDestroyed",

            ---Event triggered when a unit is added to an army.
            unitTrained = "UnitTrained",

            ---Event triggered when a unit have been upgraded.
            unitUpgraded = "UnitUpgraded"
        },

        ---Log severities.
        ---@class TotoWar_Enums_LogSeverity
        logSeverity = {
            debug = "DEBUG",
            info = "INFO",
            warning = "WARN",
            error = "ERROR"
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

            ---Pattern for identifying a UI component corresponding to the unit card of an hero during unit exchange.
            unitExchangeHeroCard = "^HeroCard",

            ---Pattern for identifying a UI component corresponding to a unit card during unit exchange.
            unitExchangeUnitCard = "^UnitCard"
        }
    },

    ---Loggers.
    ---@class TotoWar_Loggers
    loggers = {
        ---@type TotoWarLogger
        generic = nil,

        ---@type TotoWarLogger
        modsManager = nil,

        ---@type TotoWarLogger
        uiUtils = nil,

        ---@type TotoWarLogger
        utils = nil
    },

    ---Mods manager.
    ---@type TotoWarModsManager
    modsManager = nil,

    ---Options
    ---@class TotoWar_Options
    options = {
        ---Indicates whether debug messages are logged.
        debugEnabled = TotoWar_OptionDefaultValue_DebugEnabled,

        ---Log file name.
        ---@type string
        logFileName = "totowar_logs.txt"
    },

    ---@type integer
    turnNumber = 0,

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

    TotoWar:initializeLoggers()

    TotoWar.modsManager = TotoWarModsManager.new()
    TotoWar.utils = TotoWarUtils.new()
    TotoWar.ui = TotoWarUIUtils.new()

    TotoWar:addListeners()
    TotoWar:loadMctOptions()

    TotoWar.loggers.generic:logInfo("TotoWar | Mod initialized")
    TotoWar.loggers.generic:logDebug("TotoWarMod.new(): COMPLETED")

    return TotoWar
end

---Adds event listeners.
function TotoWarMod:addListeners()
    TotoWar.utils:addListener(
        "TotoWar",
        TotoWar.enums.gameEvents.factionTurnStart,
        true,
        function()
            TotoWar:onFactionTurnStart()
        end)

    TotoWar.utils:addListener(
        "TotoWar",
        TotoWar.enums.modEvents.mctOptionsUpdated,
        true,
        function()
            TotoWar:onMctOptionsUpdated()
        end)

    TotoWar.utils:addListener(
        "TotoWar",
        TotoWar.enums.modEvents.optionsUpdated,
        true,
        function()
            TotoWar:onOptionsUpdated()
        end)
end

---Initializes the log file and loggers.
function TotoWarMod:initializeLoggers()
    local file = io.open(TotoWar.options.logFileName, "w")

    if file then
        file:write("")
        file:close()
    end

    TotoWar.loggers.generic = TotoWarLogger.new("TotoWar_Generic")
    TotoWar.loggers.modsManager = TotoWarLogger.new("TotoWar_ModsManager")
    TotoWar.loggers.uiUtils = TotoWarLogger.new("TotoWar_UIUtils")
    TotoWar.loggers.utils = TotoWarLogger.new("TotoWar_Utils")

    TotoWar.loggers.generic:logDebug("initializeLoggers(): COMPLETED")
end

---Loads option values stored by the Mod Configuration Tool if it is installed.
function TotoWarMod:loadMctOptions()
    local mct = TotoWar.utils:getMct()

    if not mct then
        return
    end

    TotoWar.loggers.generic:logInfo("TotoWar | Loading options")

    local options = mct:get_mod_by_key(TotoWar_ModName)

    TotoWar.options.debugEnabled = options
        :get_option_by_key(TotoWar_OptionName_DebugEnabled)
        :get_finalized_setting()

    -- Signaling option changes
    core:trigger_event(TotoWar.enums.modEvents.optionsUpdated)

    TotoWar.loggers.generic:logInfo("TotoWar | Options loaded")
end

---Reacts to the start of the turn of a faction.
function TotoWarMod:onFactionTurnStart()
    if cm:turn_number() == self.turnNumber then
        return
    end

    self.turnNumber = cm:turn_number()

    TotoWar.loggers.generic:logInfo(
        "\n\n\n==================== TURN %s ====================\n\n",
        self.turnNumber)
end

---Reacts to MCT options being updated.
function TotoWarMod:onMctOptionsUpdated()
    TotoWar.loggers.generic:logDebug("onMctOptionsUpdated(): STARTED")

    TotoWar:loadMctOptions()

    TotoWar.loggers.generic:logDebug("onMctOptionsUpdated(): COMPLETED")
end

---Reacts to TotoWar options being updated.
function TotoWarMod:onOptionsUpdated()
    TotoWar.loggers.generic:logDebug("onOptionsUpdated(): STARTED")

    -- Overriding options after they are loaded
    -- Must be executed first in this function
    TotoWar:overwriteOptionsForDebug()

    TotoWar.loggers.generic:logDebug("onOptionsUpdated(): COMPLETED")
end

---Allows to programatically overwrite option values for local debug purpose.
function TotoWarMod:overwriteOptionsForDebug()
    TotoWar.loggers.generic:logDebug("overwriteOptionsForDebug(): STARTED")

    -- Set override values here
    -- TotoWar.loggers.generic.logLevel = TotoWar.enums.logSeverity.warning
    -- TotoWar.loggers.modsManager.logLevel = TotoWar.enums.logSeverity.warning
    -- TotoWar.loggers.uiUtils.logLevel = TotoWar.enums.logSeverity.warning
    -- TotoWar.loggers.utils.logLevel = TotoWar.enums.logSeverity.warning

    TotoWar.loggers.generic:logDebug("overwriteOptionsForDebug(): COMPLETED")
end
