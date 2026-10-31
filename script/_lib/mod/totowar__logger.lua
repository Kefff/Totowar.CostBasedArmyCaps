---Loggers already created, by category.
---@type table<string, TotoWar__Logger>
local _loggers = {}

---Rank of each log severity, from the most detailed to the least detailed.
---A message is written when the rank of its severity is greater than or equal to the rank of the level of its logger,
---so errors are always written.
---@type table<TotoWar__Enum_LogSeverities, integer>
local _severityRanks = {
    [TotoWar__Enum_LogSeverities.debug] = 1,
    [TotoWar__Enum_LogSeverities.info] = 2,
    [TotoWar__Enum_LogSeverities.warning] = 3,
    [TotoWar__Enum_LogSeverities.error] = 4
}

---Writes a message in the game script log and in the TotoWar log file.
---@param logger TotoWar__Logger Logger.
---@param severity TotoWar__Enum_LogSeverities Severity of the message.
---@param message string Message to log.
---@param ... any | fun(): any Message parameters. Functions are called to get the value of the parameter.
local function write(logger, severity, message, ...)
    local parameterCount = select("#", ...)
    local parameters = {}

    for i = 1, parameterCount, 1 do
        local parameterValue = select(i, ...)

        if type(parameterValue) == "function" then
            parameterValue = parameterValue()
        end

        if parameterValue == nil then
            -- nil values would be lost when unpacking the parameters
            parameters[i] = "nil"
        elseif type(parameterValue) == "table" then
            -- Savegame format to get the table on a single line
            parameters[i] = table.tostring(parameterValue, true)
        else
            parameters[i] = tostring(parameterValue)
        end
    end

    local messageParameterCount = 0

    for _ in string.gmatch(message, "%%s") do
        messageParameterCount = messageParameterCount + 1
    end

    if messageParameterCount ~= parameterCount then
        severity = TotoWar__Enum_LogSeverities.error
        message = string.format(
            'Invalid amount of parameters for message "%s" (Expected: %d | Received: %d)',
            message,
            messageParameterCount,
            parameterCount)
    else
        message = string.format(message, unpack(parameters))
    end

    local fullLog = string.format(
        "%s | %s | %s | %s",
        os.date("%Y-%m-%d %H:%M:%S"),
        TotoWar__String:padRight(logger.category, 30),
        TotoWar__String:padRight(severity, 5),
        message)

    ModLog(fullLog)

    local file = io.open(TotoWar__Mod.options.logFileName, "a")

    if file ~= nil then
        file:write(fullLog .. "\n")
        file:close()
    end
end

---Logger for TotoWar mods.
---
---Loggers are identified by a category (usually the service using it) that is displayed on each line of the log.
---Each message parameter can be a value or a function returning the value: functions are only called when the message
---is written, which avoids computing values (captions for example) for messages that are not logged.
---@class TotoWar__Logger
TotoWar__Logger = {
    ---Category of the logger.
    ---@type string
    category = nil,

    ---Minimum severity of the messages written by all loggers.
    ---@type TotoWar__Enum_LogSeverities
    level = TotoWar__Constant.defaultLogLevel,

    ---Minimum severity of the messages written by the loggers of a category. Takes precedence over `level`.
    ---Used to show or hide the messages of a category when debugging.
    ---@type table<string, TotoWar__Enum_LogSeverities>
    levelOverrides = {}
}
TotoWar__Logger.__index = TotoWar__Logger

---Gets the logger of a category. The logger is created the first time it is requested.
---@param category string Category of the logger.
---@return TotoWar__Logger
function TotoWar__Logger.get(category)
    local logger = _loggers[category]

    if logger == nil then
        logger = setmetatable({}, TotoWar__Logger)
        logger.category = category
        _loggers[category] = logger
    end

    return logger
end

---Indicates whether the messages of a severity are written by the logger.
---@param severity TotoWar__Enum_LogSeverities Severity.
---@return boolean
function TotoWar__Logger:isEnabled(severity)
    local level = TotoWar__Logger.levelOverrides[self.category] or TotoWar__Logger.level

    return _severityRanks[severity] >= _severityRanks[level]
end

---Logs a debug message: technical details for the developer of the mod.
---@param message string Message to log.
---@param ... any | fun(): any Message parameters. Functions are called to get the value of the parameter.
function TotoWar__Logger:logDebug(message, ...)
    if self:isEnabled(TotoWar__Enum_LogSeverities.debug) then
        write(self, TotoWar__Enum_LogSeverities.debug, message, ...)
    end
end

---Logs an error message: an operation of the mod failed.
---@param message string Message to log.
---@param ... any | fun(): any Message parameters. Functions are called to get the value of the parameter.
function TotoWar__Logger:logError(message, ...)
    if self:isEnabled(TotoWar__Enum_LogSeverities.error) then
        write(self, TotoWar__Enum_LogSeverities.error, message, ...)
    end
end

---Logs an information message: a decision or a step of the mod that a player can understand.
---@param message string Message to log.
---@param ... any | fun(): any Message parameters. Functions are called to get the value of the parameter.
function TotoWar__Logger:logInfo(message, ...)
    if self:isEnabled(TotoWar__Enum_LogSeverities.info) then
        write(self, TotoWar__Enum_LogSeverities.info, message, ...)
    end
end

---Logs a warning message: an unexpected situation that the mod handled.
---@param message string Message to log.
---@param ... any | fun(): any Message parameters. Functions are called to get the value of the parameter.
function TotoWar__Logger:logWarning(message, ...)
    if self:isEnabled(TotoWar__Enum_LogSeverities.warning) then
        write(self, TotoWar__Enum_LogSeverities.warning, message, ...)
    end
end
