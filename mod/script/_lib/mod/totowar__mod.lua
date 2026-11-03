local logger = TotoWar__Logger.get(TotoWar__Enum_LogCategories.mod)

---Indicates whether a message of the multiplayer event that gives the settings of the host is the last one.
---The Mod Configuration Tool splits the settings into several messages when they are too long for a single one,
---and only applies them when the last message is received.
---For example, the data `002/003|...` is the second message out of three, and data without a part number is a single message.
---@param dataString string Data of the message.
---@return boolean
local function isMctMultiplayerInitialLoadLastMessage(dataString)
    logger:logDebug("isMctMultiplayerInitialLoadLastMessage(%s): STARTED", dataString)

    local partNumber, partCount = string.match(dataString, "^(%d+)/(%d+)|")
    local isLastMessage = partNumber == nil or tonumber(partNumber) == tonumber(partCount)

    logger:logDebug(
        "isMctMultiplayerInitialLoadLastMessage(%s): COMPLETED => Part: %s/%s | Last message: %s",
        dataString,
        partNumber,
        partCount,
        isLastMessage)

    return isLastMessage
end

---Reacts to the Mod Configuration Tool receiving the settings of the host at the start of a new multiplayer campaign.
---
---The Mod Configuration Tool applies these settings without triggering `MctFinalized`, so TotoWar mods would keep
---the settings of their own machine, read at the first tick. On a machine whose settings differ from those of the host,
---the AI would then be adjusted differently, which desynchronizes the game.
---
---The listener of the Mod Configuration Tool is registered after the one of TotoWar, so it reacts to the message afterwards:
---the options are reloaded with a short delay to read the settings it has applied.
---The delay uses a timer of the game synchronized between the machines, because the message is received by all of them.
local function onMctMultiplayerInitialLoadReceived()
    logger:logDebug("onMctMultiplayerInitialLoadReceived(): STARTED")

    TotoWar__Utils:delay(
        function()
            logger:logInfo("Settings of the host received from the Mod Configuration Tool: reloading the options")
            TotoWar__EventsManager:trigger(TotoWar__Enum_ModEvents.mctOptionsSynchronized)
        end,
        0.1)

    logger:logDebug("onMctMultiplayerInitialLoadReceived(): COMPLETED")
end

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
    logger:logDebug("TotoWar__Mod:loadMctOptions(): STARTED")

    local mct = TotoWar__Gameplay:getMct()

    if mct == nil then
        logger:logInfo("Mod Configuration Tool not installed: TotoWar uses its default options")
        logger:logDebug("TotoWar__Mod:loadMctOptions(): COMPLETED => Mod Configuration Tool not installed")

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

    logger:logDebug("TotoWar__Mod:loadMctOptions(): COMPLETED")
end

---Reacts to the start of the turn of a faction.
function TotoWar__Mod:onFactionTurnStart()
    logger:logDebug("TotoWar__Mod:onFactionTurnStart(): STARTED")

    if cm:turn_number() == self.turnNumber then
        logger:logDebug("TotoWar__Mod:onFactionTurnStart(): COMPLETED => Turn already started")

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

    logger:logDebug("TotoWar__Mod:onFactionTurnStart(): COMPLETED")
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
        TotoWar__Enum_ModEvents.mctOptionsSynchronized,
        function() self:onMctOptionsUpdated() end)

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_ModEvents.mctOptionsUpdated,
        function() self:onMctOptionsUpdated() end)

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_ModEvents.optionsUpdated,
        function() overwriteOptionsForDebug() end,
        nil,
        nil,
        9999) -- To force overwriteOptionsForDebug to be executed after other methods reacting to the optionsUpdated event

    -- Only sent in multiplayer: no effect in a singleplayer campaign
    TotoWar__EventsManager:subscribeMultiplayer(
        TotoWar__Enum_ModEvents.mpMctInitialLoad,
        function() onMctMultiplayerInitialLoadReceived() end,
        function(factionCqi, dataString) return isMctMultiplayerInitialLoadLastMessage(dataString) end)

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
