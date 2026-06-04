---TotoWar base mod.
---@class TotoWar__Mod
TotoWar__Mod = {
    ---Loggers.
    loggers = {
        ---@type TotoWar__Logger
        generic = nil,

        ---@type TotoWar__Logger
        modsManager = nil,

        ---@type TotoWar__Logger
        uiUtils = nil,

        ---@type TotoWar__Logger
        utils = nil
    },

    ---Mods manager.
    ---@type TotoWar__ModsManager
    modsManager = nil,

    ---Options
    options = {
        ---Indicates whether debug messages are logged.
        debugEnabled = TotoWar__Constant.optionDefaultValue_debugEnabled,

        ---Log file name.
        ---@type string
        logFileName = "totowar_logs.txt"
    },

    ---@type integer
    turnNumber = 0
}
TotoWar__Mod.__index = TotoWar__Mod

---TotoWar base mod instance.
---@type TotoWar__Mod
TotoWar = nil

---Initializes a new instance.
---@return TotoWar__Mod
function TotoWar__Mod.new()
    TotoWar = setmetatable({}, TotoWar__Mod)

    TotoWar:initializeLoggers()

    TotoWar.modsManager = TotoWar__ModsManager.new()

    TotoWar:addListeners()
    TotoWar:loadMctOptions()

    TotoWar.loggers.generic:logInfo("TotoWar | Mod initialized")
    TotoWar.loggers.generic:logDebug("TotoWar__Mod.new(): COMPLETED")

    return TotoWar
end

---Adds event listeners.
function TotoWar__Mod:addListeners()
    TotoWar__Gameplay:addListener(
        "TotoWar",
        TotoWar__Enum_GameEvent.factionTurnStart,
        true,
        function()
            TotoWar:onFactionTurnStart()
        end)

    TotoWar__Gameplay:addListener(
        "TotoWar",
        TotoWar__Enum_ModEvents.mctOptionsUpdated,
        true,
        function()
            TotoWar:onMctOptionsUpdated()
        end)

    TotoWar__Gameplay:addListener(
        "TotoWar",
        TotoWar__Enum_ModEvents.optionsUpdated,
        true,
        function()
            TotoWar:onOptionsUpdated()
        end)
end

---Initializes the log file and loggers.
function TotoWar__Mod:initializeLoggers()
    local file = io.open(TotoWar.options.logFileName, "w")

    if file then
        file:write("")
        file:close()
    end

    TotoWar.loggers.generic = TotoWar__Logger.new("TotoWar_Generic")
    TotoWar.loggers.modsManager = TotoWar__Logger.new("TotoWar_ModsManager")
    TotoWar.loggers.uiUtils = TotoWar__Logger.new("TotoWar_UIUtils")
    TotoWar.loggers.utils = TotoWar__Logger.new("TotoWar_Utils")

    TotoWar.loggers.generic:logDebug("initializeLoggers(): COMPLETED")
end

---Loads option values stored by the Mod Configuration Tool if it is installed.
function TotoWar__Mod:loadMctOptions()
    local mct = TotoWar__Gameplay:getMct()

    if not mct then
        return
    end

    TotoWar.loggers.generic:logInfo("TotoWar | Loading options")

    local options = mct:get_mod_by_key(TotoWar__Constant.modName)

    TotoWar.options.debugEnabled = options
        :get_option_by_key(TotoWar__Constant.optionName_debugEnabled)
        :get_finalized_setting()

    -- Signaling option changes
    core:trigger_event(TotoWar__Enum_ModEvents.optionsUpdated)

    TotoWar.loggers.generic:logInfo("TotoWar | Options loaded")
end

---Reacts to the start of the turn of a faction.
function TotoWar__Mod:onFactionTurnStart()
    if cm:turn_number() == self.turnNumber then
        return
    end

    self.turnNumber = cm:turn_number()

    TotoWar.loggers.generic:logInfo(
        "\n\n\n==================== TURN %s ====================\n\n",
        self.turnNumber)
end

---Reacts to MCT options being updated.
function TotoWar__Mod:onMctOptionsUpdated()
    TotoWar.loggers.generic:logDebug("onMctOptionsUpdated(): STARTED")

    TotoWar:loadMctOptions()

    TotoWar.loggers.generic:logDebug("onMctOptionsUpdated(): COMPLETED")
end

---Reacts to TotoWar options being updated.
function TotoWar__Mod:onOptionsUpdated()
    TotoWar.loggers.generic:logDebug("onOptionsUpdated(): STARTED")

    -- Overriding options after they are loaded
    -- Must be executed first in this function
    TotoWar:overwriteOptionsForDebug()

    TotoWar.loggers.generic:logDebug("onOptionsUpdated(): COMPLETED")
end

---Allows to programatically overwrite option values for local debug purpose.
function TotoWar__Mod:overwriteOptionsForDebug()
    TotoWar.loggers.generic:logDebug("overwriteOptionsForDebug(): STARTED")

    -- Set override values here
    -- TotoWar.loggers.generic.logLevel = TotoWar__Enum_LogSeverity.warning
    -- TotoWar.loggers.modsManager.logLevel = TotoWar__Enum_LogSeverity.warning
    -- TotoWar.loggers.uiUtils.logLevel = TotoWar__Enum_LogSeverity.warning
    -- TotoWar.loggers.utils.logLevel = TotoWar__Enum_LogSeverity.warning

    TotoWar.loggers.generic:logDebug("overwriteOptionsForDebug(): COMPLETED")
end
