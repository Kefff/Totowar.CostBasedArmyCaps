---Logger for TotoWar mods.
---@class TotoWar__Logger
TotoWar__Logger = {
    ---Log level.
    ---@type TotoWar__Enum_LogSeverity
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
        instance.logLevel = TotoWar__Enum_LogSeverity.debug
    else
        ---@diagnostic disable-next-line: assign-type-mismatch
        instance.logLevel = TotoWar__Enum_LogSeverity.info
    end

    instance.loggerName = loggerName

    instance:addListeners()

    instance:logInfo("Logger instance created")

    return instance
end

---Adds event listeners.
function TotoWar__Logger:addListeners()
    core:add_listener(
        "TotoWar__Logger",
        TotoWar__Enum_ModEvents.optionsUpdated,
        true,
        function()
            self:onOptionsUpdated()
        end,
        true)
end

---Logs a message.
---@param instance TotoWar__Logger Logger instance.
---@param severity string Severity.
---@param message string Message to log.
---@param ... boolean | integer | number | string Message parameters.
local function log(instance, severity, message, ...)
    local parameters = {}

    for i, value in ipairs({ ... }) do
        if value == nil then
            value = "nil"
        end

        parameters[i] = tostring(value)
    end

    local messageParameterCount = 0

    for _ in string.gmatch(message, "%%s") do
        messageParameterCount = messageParameterCount + 1
    end

    if messageParameterCount ~= #parameters then
        severity = TotoWar__Enum_LogSeverity.error
        message = string.format(
            "TotoWar__Logger:log(\"%s\", %s) => Invalid amount of parameters",
            message,
            #parameters)
    else
        message = string.format(message, unpack(parameters))
    end

    fullLog = string.format(
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
    if self.logLevel == TotoWar__Enum_LogSeverity.debug then
        local parameters = {}

        for i, valueFunction in ipairs({ ... }) do
            local value = valueFunction()
            parameters[i] = tostring(value)
        end

        log(self, TotoWar__Enum_LogSeverity.debug, message, unpack(parameters))
    end
end

---Logs an error message.
---@param message string Message to log.
---@param ... boolean | integer | number | string Message parameters.
function TotoWar__Logger:logError(message, ...)
    log(self, TotoWar__Enum_LogSeverity.error, message, ...)
end

---Logs an information message.
---@param message string Message to log.
---@param ... boolean | integer | number | string Message parameters.
function TotoWar__Logger:logInfo(message, ...)
    if self.logLevel == TotoWar__Enum_LogSeverity.debug
        or self.logLevel == TotoWar__Enum_LogSeverity.info
    then
        log(self, TotoWar__Enum_LogSeverity.info, message, ...)
    end
end

---Logs an warning message.
---@param message string Message to log.
---@param ... boolean | integer | number | string Message parameters.
function TotoWar__Logger:logWarning(message, ...)
    if self.logLevel == TotoWar__Enum_LogSeverity.debug
        or self.logLevel == TotoWar__Enum_LogSeverity.info
        or self.logLevel == TotoWar__Enum_LogSeverity.warning
    then
        log(self, TotoWar__Enum_LogSeverity.warning, message, ...)
    end
end

---Reacts to options being updated.
function TotoWar__Logger:onOptionsUpdated()
    if TotoWar.options.debugEnabled
        and self.logLevel ~= TotoWar__Enum_LogSeverity.debug
    then
        ---@diagnostic disable-next-line: assign-type-mismatch
        self.logLevel = TotoWar__Enum_LogSeverity.debug
    elseif not TotoWar.options.debugEnabled
        and self.logLevel == TotoWar__Enum_LogSeverity.debug
    then
        ---@diagnostic disable-next-line: assign-type-mismatch
        self.logLevel = TotoWar__Enum_LogSeverity.info
    end
end
