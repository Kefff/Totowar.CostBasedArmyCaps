local TotowarLoggerSeverity = {
    debug = "DEBUG",
    info = "INFO ",
    warning = "WARN ",
    error = "ERROR"
}

---@class TotowarLogger
TotowarLogger = {
    ---@type boolean
    isDebug = false,
    ---@type string
    logFileName = nil,
    ---@type string
    modName = nil
}
TotowarLogger.__index = TotowarLogger

---Initializes a new instance.
---@param modName string Mod name.
---@param logFileName string Log file name.
---@param isDebug boolean Indicates whether debug logs are taken into consideration.
---@return TotowarLogger
function TotowarLogger.new(modName, logFileName, isDebug)
    local instance = setmetatable({}, TotowarLogger)
    instance.isDebug = isDebug
    instance.logFileName = logFileName
    instance.modName = modName

    instance:logInfo("Logger created")

    return instance
end

---Logs a message.
---@param instance TotowarLogger Logger instance.
---@param severity string Severity.
---@param message string Message to log.
---@param ... any Message parameters.
local function log(instance, severity, message, ...)
    message = string.format(message, ...)
    fullLog = string.format("[%s] %s | %s: %s", instance.modName, os.date("%c"), severity, message)
    ModLog(fullLog)

    local file = io.open(instance.logFileName, "a")

    if file then
        file:write(fullLog .. "\n")
        file:close()
    end
end

---Logs a debug message.
---@param message string Message to log.
---@param ... any Message parameters.
function TotowarLogger:logDebug(message, ...)
    if self.isDebug then
        log(self, TotowarLoggerSeverity.debug, message, ...)
    end
end

---Logs an error message.
---@param message string Message to log.
---@param ... any Message parameters.
function TotowarLogger:logError(message, ...)
    log(self, TotowarLoggerSeverity.error, message, ...)
end

---Logs an information message.
---@param message string Message to log.
---@param ... any Message parameters.
function TotowarLogger:logInfo(message, ...)
    log(self, TotowarLoggerSeverity.info, message, ...)
end

---Logs an warning message.
---@param message string Message to log.
---@param ... any Message parameters.
function TotowarLogger:logWarning(message, ...)
    log(self, TotowarLoggerSeverity.warning, message, ...)
end
