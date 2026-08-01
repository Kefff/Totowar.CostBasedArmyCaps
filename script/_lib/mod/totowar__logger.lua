---Logger for TotoWar mods.
---@class TotoWar__Logger
TotoWar__Logger = {
    ---Log level.
    ---@type TotoWar__Enum_LogSeverities
    ---@diagnostic disable-next-line: assign-type-mismatch
    logLevel = nil,

    ---Mod name.
    ---@type string
    loggerName = nil
}
TotoWar__Logger.__index = TotoWar__Logger

---Initializes a new instance.
---@param loggerName string Logger name.
---@return TotoWar__Logger
function TotoWar__Logger.new(loggerName)
    local instance = setmetatable({}, TotoWar__Logger)

    if TotoWar.options.debugEnabled then
        ---@diagnostic disable-next-line: assign-type-mismatch
        instance.logLevel = TotoWar__Enum_LogSeverities.debug
    else
        ---@diagnostic disable-next-line: assign-type-mismatch
        instance.logLevel = TotoWar__Constant.defaultLogLevel
    end

    instance.loggerName = loggerName

    instance:addEventListeners()

    instance:logInfo("Logger instance created")

    return instance
end

---Adds event listeners.
---Special case where we directly use the core:add_listener instead of TotoWar__EventsManager because loggers must be instanciated as soon as possible, before the manager.
function TotoWar__Logger:addEventListeners()
    core:add_listener(
        "TotoWar__Logger_" .. TotoWar__Enum_ModEvents.optionsUpdated,
        TotoWar__Enum_ModEvents.optionsUpdated,
        true,
        function() self:onOptionsUpdated() end,
        true)
end

---Logs a message.
---@param instance TotoWar__Logger Logger instance.
---@param severity TotoWar__Enum_LogSeverities Severity.
---@param message string Message to log.
---@param ... boolean | integer | nil | number | string Message parameters.
local function log(instance, severity, message, ...)
    local parameterCount = select("#", ...)
    local parameters = {}

    for i = 1, parameterCount, 1 do
        local parameterValue = select(i, ...)

        if parameterValue == nil then
            parameters[i] = "nil"
        else
            parameters[i] = tostring(parameterValue)
        end
    end

    local messageParameterCount = 0

    for _ in string.gmatch(message, "%%s") do
        messageParameterCount = messageParameterCount + 1
    end

    if messageParameterCount ~= parameterCount then
        ---@diagnostic disable-next-line: cast-local-type
        severity = TotoWar__Enum_LogSeverities.error
        message = string.format(
            'TotoWar__Logger:log("%s", %d) => Invalid amount of parameters',
            message,
            parameterCount)
    else
        message = string.format(message, unpack(parameters))
    end

    local fullLog = string.format(
        "%s | %s | %s | %s",
        os.date("%Y-%m-%d %H:%M:%S"),
        TotoWar__String:padRight(instance.loggerName, 30),
        TotoWar__String:padRight(severity, 5),
        message)

    ModLog(fullLog)

    local file = io.open(TotoWar.options.logFileName, "a")

    if file then
        file:write(fullLog .. "\n")
        file:close()
    end
end

---Logs a debug message.
---@param message string Message to log.
---@param ... (fun(): boolean | integer | nil | number | string) Functions for getting parameter values.
function TotoWar__Logger:logDebug(message, ...)
    if self.logLevel == TotoWar__Enum_LogSeverities.debug then
        local parameterValueFunctionCount = select("#", ...)
        local parameters = {}

        for i = 1, parameterValueFunctionCount, 1 do
            local parameterValueFunction = select(i, ...)
            parameters[i] = parameterValueFunction()

            if parameters[i] == nil then
                -- nil values in the table are lost when upacking because LUA considers a nil value is a table as a non existing elements, so we are forced to replace them here
                parameters[i] = "nil"
            end
        end

        log(self, TotoWar__Enum_LogSeverities.debug, message, unpack(parameters))
    end
end

---Logs an error message.
---@param message string Message to log.
---@param ... boolean | integer | number | string Message parameters.
function TotoWar__Logger:logError(message, ...)
    log(self, TotoWar__Enum_LogSeverities.error, message, ...)
end

---Logs an information message.
---@param message string Message to log.
---@param ... boolean | integer | number | string Message parameters.
function TotoWar__Logger:logInfo(message, ...)
    if self.logLevel == TotoWar__Enum_LogSeverities.debug
        or self.logLevel == TotoWar__Enum_LogSeverities.info
    then
        log(self, TotoWar__Enum_LogSeverities.info, message, ...)
    end
end

---Logs an warning message.
---@param message string Message to log.
---@param ... boolean | integer | number | string Message parameters.
function TotoWar__Logger:logWarning(message, ...)
    if self.logLevel == TotoWar__Enum_LogSeverities.debug
        or self.logLevel == TotoWar__Enum_LogSeverities.info
        or self.logLevel == TotoWar__Enum_LogSeverities.warning
    then
        log(self, TotoWar__Enum_LogSeverities.warning, message, ...)
    end
end

---Reacts to options being updated.
function TotoWar__Logger:onOptionsUpdated()
    if TotoWar.options.debugEnabled
        and self.logLevel ~= TotoWar__Enum_LogSeverities.debug
    then
        ---@diagnostic disable-next-line: assign-type-mismatch
        self.logLevel = TotoWar__Enum_LogSeverities.debug
    elseif not TotoWar.options.debugEnabled
        and self.logLevel == TotoWar__Enum_LogSeverities.debug
    then
        ---@diagnostic disable-next-line: assign-type-mismatch
        self.logLevel = TotoWar__Enum_LogSeverities.info
    end
end
