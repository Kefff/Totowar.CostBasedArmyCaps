local logger = TotoWar__Logger.get(TotoWar__Enum_LogCategories.generic)

---Allows to programatically overwrite option values for local debug purpose.
local function overwriteOptionsForDebug()
    -- Set override values here, for example to show or hide the messages of a log category:
    -- TotoWar__Logger.levelOverrides[TotoWar__Enum_LogCategories.eventsManager] = TotoWar__Enum_LogSeverities.error
    -- TotoWar__Logger.levelOverrides[TotoWar__Enum_LogCategories.ui] = TotoWar__Enum_LogSeverities.debug
end

---TotoWar base mod.
---@class TotoWar__Mod
TotoWar__Mod = {
    ---Options.
    ---Declared with their default values because the logger reads them before the initialization.
    options = {
        ---Indicates whether debug messages are logged.
        debugEnabled = TotoWar__Constant.optionDefaultValue_debugEnabled,

        ---Log file name.
        ---@type string
        logFileName = "totowar_logs.txt",

        ---Indicates whether the fog of war is removed from the whole campaign map.
        mapRevealed = TotoWar__Constant.optionDefaultValue_mapRevealed
    },

    ---Number of the current turn.
    ---@type integer
    turnNumber = nil
}

---Initializes the TotoWar base mod and its services.
function TotoWar__Mod:initialize()
    self.turnNumber = 0

    self:initializeLogFile()

    logger:logDebug("TotoWar__Mod:initialize(): STARTED")

    TotoWar__EventsManager:initialize()

    self:subscribeToEvents()
    self:loadMctOptions()

    TotoWar__ModsManager:initialize()

    logger:logInfo("TotoWar base mod initialized")
    logger:logDebug("TotoWar__Mod:initialize(): COMPLETED")
end

---Empties the log file.
function TotoWar__Mod:initializeLogFile()
    local file = io.open(self.options.logFileName, "w")

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

    self.options.debugEnabled = options
        :get_option_by_key(TotoWar__Constant.optionName_debugEnabled)
        :get_finalized_setting()

    self.options.mapRevealed = options
        :get_option_by_key(TotoWar__Constant.optionName_mapRevealed)
        :get_finalized_setting()

    if self.options.debugEnabled then
        TotoWar__Logger.level = TotoWar__Enum_LogSeverities.debug
    else
        TotoWar__Logger.level = TotoWar__Constant.defaultLogLevel
    end

    self:updateMapShroud()

    logger:logInfo(
        "TotoWar options loaded from the Mod Configuration Tool (Debug logs: %s | Map revealed: %s)",
        self.options.debugEnabled,
        self.options.mapRevealed)

    -- Signaling option changes
    TotoWar__EventsManager:trigger(TotoWar__Enum_ModEvents.optionsUpdated)
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

    -- The game restores the shroud over settlements and armies when a turn ends
    if self.options.mapRevealed then
        self:updateMapShroud()
    end
end

---Reacts to MCT options being updated.
function TotoWar__Mod:onMctOptionsUpdated()
    logger:logDebug("TotoWar__Mod:onMctOptionsUpdated(): STARTED")

    self:loadMctOptions()

    logger:logDebug("TotoWar__Mod:onMctOptionsUpdated(): COMPLETED")
end

---Subscribes to events.
function TotoWar__Mod:subscribeToEvents()
    logger:logDebug("TotoWar__Mod:subscribeToEvents(): STARTED")

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_GameEvents.factionTurnStart,
        function() self:onFactionTurnStart() end)

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_ModEvents.mctOptionsUpdated,
        function() self:onMctOptionsUpdated() end)

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_ModEvents.optionsUpdated,
        function() overwriteOptionsForDebug() end,
        nil,
        nil,
        9999) -- To force overwriteOptionsForDebug to be executed after other methods reacting to the optionsUpdated event

    logger:logDebug("TotoWar__Mod:subscribeToEvents(): COMPLETED")
end

---Shows or removes the fog of war of the campaign map depending on the options.
function TotoWar__Mod:updateMapShroud()
    logger:logDebug("TotoWar__Mod:updateMapShroud(): STARTED")

    cm:show_shroud(not self.options.mapRevealed)

    logger:logDebug(
        "TotoWar__Mod:updateMapShroud(): COMPLETED => Map revealed: %s",
        self.options.mapRevealed)
end
