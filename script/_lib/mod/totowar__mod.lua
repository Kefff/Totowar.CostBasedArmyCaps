local logger = TotoWar__Logger.get(TotoWar__Enum_LogCategories.generic)

---TotoWar base mod.
---@class TotoWar__Mod
TotoWar__Mod = {
    ---Events manager.
    ---@type TotoWar__EventsManager
    eventsManager = nil,

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

    TotoWar:initializeLogFile()

    logger:logDebug("TotoWar__Mod.new(): STARTED")

    TotoWar.eventsManager = TotoWar__EventsManager.new()

    TotoWar:subscribeToEvents()
    TotoWar:loadMctOptions()

    TotoWar.modsManager = TotoWar__ModsManager.new()

    logger:logInfo("TotoWar base mod initialized")
    logger:logDebug("TotoWar__Mod.new(): COMPLETED")

    return TotoWar
end

---Empties the log file.
function TotoWar__Mod:initializeLogFile()
    local file = io.open(TotoWar.options.logFileName, "w")

    if file ~= nil then
        file:write("")
        file:close()
    end
end

---Loads option values stored by the Mod Configuration Tool if it is installed.
function TotoWar__Mod:loadMctOptions()
    local mct = TotoWar__Gameplay:getMct()

    if mct == nil then
        logger:logInfo("Mod Configuration Tool not installed: TotoWar uses its default options")

        return
    end

    local options = mct:get_mod_by_key(TotoWar__Constant.modName)

    TotoWar.options.debugEnabled = options
        :get_option_by_key(TotoWar__Constant.optionName_debugEnabled)
        :get_finalized_setting()

    if TotoWar.options.debugEnabled then
        TotoWar__Logger.level = TotoWar__Enum_LogSeverities.debug
    else
        TotoWar__Logger.level = TotoWar__Constant.defaultLogLevel
    end

    logger:logInfo(
        "TotoWar options loaded from the Mod Configuration Tool (Debug logs: %s)",
        TotoWar.options.debugEnabled)

    -- Signaling option changes
    TotoWar.eventsManager:trigger(TotoWar__Enum_ModEvents.optionsUpdated)
end

---Reacts to the start of the turn of a faction.
function TotoWar__Mod:onFactionTurnStart()
    if cm:turn_number() == self.turnNumber then
        return
    end

    self.turnNumber = cm:turn_number()

    logger:logInfo(
        "\n\n\n==================== TURN %s ====================\n\n",
        self.turnNumber)
end

---Reacts to MCT options being updated.
function TotoWar__Mod:onMctOptionsUpdated()
    logger:logDebug("TotoWar__Mod:onMctOptionsUpdated(): STARTED")

    TotoWar:loadMctOptions()

    logger:logDebug("TotoWar__Mod:onMctOptionsUpdated(): COMPLETED")
end

---Allows to programatically overwrite option values for local debug purpose.
function TotoWar__Mod:overwriteOptionsForDebug()
    -- Set override values here, for example to show or hide the messages of a log category:
    -- TotoWar__Logger.levelOverrides[TotoWar__Enum_LogCategories.eventsManager] = TotoWar__Enum_LogSeverities.error
    -- TotoWar__Logger.levelOverrides[TotoWar__Enum_LogCategories.ui] = TotoWar__Enum_LogSeverities.debug
end

---Subscribes to events.
function TotoWar__Mod:subscribeToEvents()
    logger:logDebug("TotoWar__Mod:subscribeToEvents(): STARTED")

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

    logger:logDebug("TotoWar__Mod:subscribeToEvents(): COMPLETED")
end
