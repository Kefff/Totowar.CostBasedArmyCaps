---Log severities.
---@class TotoWarLoggerSeverity
TotoWarLoggerSeverity = {
    debug = "DEBUG",
    info = "INFO",
    warning = "WARN",
    error = "ERROR"
}

---Logger for TotoWar mods.
---@class TotoWarLogger
TotoWarLogger = {
    ---Indicates whether the logger is enabled.
    ---@type TotoWarLoggerSeverity
    ---@diagnostic disable-next-line: assign-type-mismatch
    logLevel = TotoWarLoggerSeverity.info,

    ---Mod name.
    ---@type string
    loggerName = nil
}
TotoWarLogger.__index = TotoWarLogger

---Initializes a new instance.
---@param loggerName string Logger name.
---@return TotoWarLogger
function TotoWarLogger.new(loggerName)
    local instance = setmetatable({}, TotoWarLogger)

    instance.loggerName = loggerName
    instance:logInfo("Logger instance created")

    return instance
end

---Logs a message.
---@param instance TotoWarLogger Logger instance.
---@param severity string Severity.
---@param message string Message to log.
---@param ... boolean | integer | number | string Message parameters.
local function log(instance, severity, message, ...)
    local parameters = {}

    for i, value in ipairs({ ... }) do
        parameters[i] = tostring(value)
    end

    message = string.format(message, unpack(parameters))
    fullLog = string.format("%s | %s [%s] %s", os.date("%Y-%m-%d %H:%M:%S"), severity, instance.loggerName, message)
    ModLog(fullLog)

    local file = io.open(TotoWar.logFileName, "a")

    if file then
        file:write(fullLog .. "\n")
        file:close()
    end
end

---Logs a debug message.
---@param message string Message to log.
---@param ... (fun(): boolean | integer | nil | number | string) Functions for getting parameter values.
function TotoWarLogger:logDebug(message, ...)
    if TotoWar.options.debugEnabled then
        local parameters = {}

        for i, valueFunction in ipairs({ ... }) do
            local value = valueFunction()

            if value == nil then
                value = "nil"
            end

            parameters[i] = tostring(valueFunction())
        end

        log(self, TotoWarLoggerSeverity.debug, message, unpack(parameters))
    end
end

---Logs an error message.
---@param message string Message to log.
---@param ... boolean | integer | number | string Message parameters.
function TotoWarLogger:logError(message, ...)
    log(self, TotoWarLoggerSeverity.error, message, ...)
end

---Logs an information message.
---@param message string Message to log.
---@param ... boolean | integer | number | string Message parameters.
function TotoWarLogger:logInfo(message, ...)
    if TotoWar.options.debugEnabled
        or self.logLevel == TotoWarLoggerSeverity.info
    then
        log(self, TotoWarLoggerSeverity.info, message, ...)
    end
end

---Logs an warning message.
---@param message string Message to log.
---@param ... boolean | integer | number | string Message parameters.
function TotoWarLogger:logWarning(message, ...)
    if TotoWar.options.debugEnabled
        or self.logLevel == TotoWarLoggerSeverity.info
        or self.logLevel == TotoWarLoggerSeverity.warning
    then
        log(self, TotoWarLoggerSeverity.warning, message, ...)
    end
end
