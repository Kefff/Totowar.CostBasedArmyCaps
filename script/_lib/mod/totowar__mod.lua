---TotoWar base mod.
---@class TotoWar__Mod
TotoWar__Mod = {
    ---Events manager.
    ---@type TotoWar__EventsManager
    eventsManager = nil,

    ---Loggers.
    loggers = {
        ---@type TotoWar__Logger
        eventsManager = nil,

        ---@type TotoWar__Logger
        generic = nil,

        ---@type TotoWar__Logger
        modsManager = nil,

        ---@type TotoWar__Logger
        ui = nil,

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

    TotoWar.eventsManager = TotoWar__EventsManager.new()
    core:trigger_event(TotoWar__Enum_ModEvents.eventsManagerInitialized) -- Signaling loggers that they can subscribe to the events manager

    TotoWar:subscribeToEvents()
    TotoWar:loadMctOptions()

    TotoWar.modsManager = TotoWar__ModsManager.new()

    TotoWar.loggers.generic:logInfo("TotoWar | Mod initialized")
    TotoWar.loggers.generic:logDebug("TotoWar__Mod.new(): COMPLETED")

    return TotoWar
end

---Initializes the log file and loggers.
function TotoWar__Mod:initializeLoggers()
    local file = io.open(TotoWar.options.logFileName, "w")

    if file then
        file:write("")
        file:close()
    end

    TotoWar.loggers.eventsManager = TotoWar__Logger.new("TotoWar__EventsManager")
    TotoWar.loggers.generic = TotoWar__Logger.new("TotoWar__Generic")
    TotoWar.loggers.modsManager = TotoWar__Logger.new("TotoWar__ModsManager")
    TotoWar.loggers.ui = TotoWar__Logger.new("TotoWar__UI")
    TotoWar.loggers.utils = TotoWar__Logger.new("TotoWar__Utils")

    TotoWar.loggers.generic:logDebug("TotoWar__Mod:initializeLoggers(): COMPLETED")
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
    TotoWar.eventsManager:trigger(TotoWar__Enum_ModEvents.optionsUpdated)

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
    TotoWar.loggers.generic:logDebug("TotoWar__Mod:onMctOptionsUpdated(): STARTED")

    TotoWar:loadMctOptions()

    TotoWar.loggers.generic:logDebug("TotoWar__Mod:onMctOptionsUpdated(): COMPLETED")
end

---Allows to programatically overwrite option values for local debug purpose.
function TotoWar__Mod:overwriteOptionsForDebug()
    -- Set override values here

    -- TotoWar.loggers.eventsManager.logLevel = TotoWar__Enum_LogSeverities.debug
    -- TotoWar.loggers.generic.logLevel = TotoWar__Enum_LogSeverities.debug
    -- TotoWar.loggers.modsManager.logLevel = TotoWar__Enum_LogSeverities.debug
    TotoWar.loggers.ui.logLevel = TotoWar__Enum_LogSeverities.debug
    -- TotoWar.loggers.utils.logLevel = TotoWar__Enum_LogSeverities.debug
end

---Subscribes to events.
function TotoWar__Mod:subscribeToEvents()
    TotoWar.loggers.generic:logDebug("TotoWar__Mod:subscribeToEvents(): STARTED")

    self.eventsManager:subscribe(
        TotoWar__Enum_GameEvents.factionTurnStart,
        function() TotoWar:onFactionTurnStart() end)

    self.eventsManager:subscribe(
        TotoWar__Enum_ModEvents.mctOptionsUpdated,
        function() TotoWar:onMctOptionsUpdated() end)

    self.eventsManager:subscribe(
        TotoWar__Enum_ModEvents.optionsUpdated,
        function() TotoWar:overwriteOptionsForDebug() end,
        nil,
        nil,
        9999) -- To force overwriteOptionsForDebug to be executed after other methods reacting to the optionsUpdated event

    TotoWar.loggers.generic:logDebug("TotoWar__Mod:subscribeToEvents(): COMPLETED")
end
