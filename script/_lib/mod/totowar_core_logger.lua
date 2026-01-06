local _defaultLogFileName = "totowar_logs.txt"

---Log severities.
local TotoWarLoggerSeverity = {
    debug = "DEBUG",
    info = "INFO ",
    warning = "WARN ",
    error = "ERROR"
}

---Logger for TotoWar mods.
---@class TotoWarLogger
TotoWarLogger = {
    ---Indicates whether the logger is enabled.
    ---@type boolean
    isEnabled = true,

    ---Log file name.
    ---@type string
    logFileName = nil,

    ---Mod name.
    ---@type string
    modName = nil
}
TotoWarLogger.__index = TotoWarLogger

---Initializes a new instance.
---@param modName string Mod name.
---@param logFileName string? Log file name. If `nil`, the default log file name is used.
---@param resetLogFile boolean? Indicates whether the log file should be reset. If `nil`, `false`.
---@return TotoWarLogger
function TotoWarLogger.new(modName, logFileName, resetLogFile)
    local instance = setmetatable({}, TotoWarLogger)

    if logFileName then
        instance.logFileName = logFileName
    else
        instance.logFileName = _defaultLogFileName
    end

    if resetLogFile then
        local file = io.open(instance.logFileName, "w")

        if file then
            file:write("")
            file:close()
        end
    end

    instance.modName = modName

    instance:logInfo("Logger instance created")

    return instance
end

---Logs a message.
---@param instance TotoWarLogger Logger instance.
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
    fullLog = string.format("%s | %s [%s] %s", os.date("%Y-%m-%d %H:%M:%S"), severity, instance.modName, message)
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
function TotoWarLogger:logDebug(message, ...)
    if TotoWar().isDebug then
        log(self, TotoWarLoggerSeverity.debug, message, ...)
    end
end

---Logs an error message.
---@param message string Message to log.
---@param ... any Message parameters.
function TotoWarLogger:logError(message, ...)
    log(self, TotoWarLoggerSeverity.error, message, ...)
end

---Logs an information message.
---@param message string Message to log.
---@param ... any Message parameters.
function TotoWarLogger:logInfo(message, ...)
    log(self, TotoWarLoggerSeverity.info, message, ...)
end

---Logs an warning message.
---@param message string Message to log.
---@param ... any Message parameters.
function TotoWarLogger:logWarning(message, ...)
    log(self, TotoWarLoggerSeverity.warning, message, ...)
end
