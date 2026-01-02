local TotowarLoggerSeverity = {
    debug = "DEBUG",
    info = "INFO ",
    warning = "WARN ",
    error = "ERROR"
}

---@class TotowarLogger
TotowarLogger = {
    ---Indicates whether the logger is enabled.
    ---@type boolean
    isEnabled = true,

    ---Log file name.
    ---@type string
    logFileName = "totowar_logs.txt",

    ---Mod name.
    ---@type string
    modName = nil
}
TotowarLogger.__index = TotowarLogger

---Initializes a new instance.
---@param modName string Mod name.
---@param logFileName string? Log file name.
---@return TotowarLogger
function TotowarLogger.new(modName, logFileName)
    local instance = setmetatable({}, TotowarLogger)

    if logFileName then
        instance.logFileName = logFileName
    end

    instance.modName = modName

    -- Resetting the file
    local file = io.open(instance.logFileName, "w")

    if file then
        file:write("")
        file:close()
    end

    instance:logInfo("Logger: Initialized")

    return instance
end

---Logs a message.
---@param instance TotowarLogger Logger instance.
---@param severity string Severity.
---@param message string Message to log.
---@param ... any Message parameters.
local function log(instance, severity, message, ...)
    if not instance.isEnabled then
        return
    end

    parameters = {}

    for i, value in ipairs({ ... }) do
        parameters[i] = tostring(value)
    end

    message = string.format(message, unpack(parameters))
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
    if TotoWarUtils.isDebug then
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
