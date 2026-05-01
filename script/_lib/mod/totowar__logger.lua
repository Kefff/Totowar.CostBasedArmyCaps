---Logger for TotoWar mods.
---@class TotoWarLogger
TotoWarLogger = {
    ---Log level.
    ---@type TotoWar_Enums_LogSeverity
    ---@diagnostic disable-next-line: assign-type-mismatch
    logLevel = nil,

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

    if TotoWar.options.debugEnabled then
        ---@diagnostic disable-next-line: assign-type-mismatch
        instance.logLevel = TotoWar.enums.logSeverity.debug
    else
        ---@diagnostic disable-next-line: assign-type-mismatch
        instance.logLevel = TotoWar.enums.logSeverity.info
    end

    instance.loggerName = loggerName

    instance:addListeners()

    instance:logInfo("Logger instance created")

    return instance
end

---Adds event listeners.
function TotoWarLogger:addListeners()
    core:add_listener(
        "TotoWarLogger",
        TotoWar.enums.modEvents.optionsUpdated,
        true,
        function()
            self:onOptionsUpdated()
        end,
        true)
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

    local messageParameterCount = 0

    for _ in string.gmatch(message, "%%s") do
        messageParameterCount = messageParameterCount + 1
    end

    if messageParameterCount ~= #parameters then
        severity = TotoWar.enums.logSeverity.error
        message = string.format(
            "TotoWarLogger:log(\"%s\", %s) => Invalid amount of parameters",
            message,
            #parameters)
    else
        message = string.format(message, unpack(parameters))
    end

    fullLog = string.format(
        "%s | %s | %s | %s",
        os.date("%Y-%m-%d %H:%M:%S"),
        totoWar_textPadRight(instance.loggerName, 30),
        totoWar_textPadRight(severity, 5),
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
function TotoWarLogger:logDebug(message, ...)
    if self.logLevel == TotoWar.enums.logSeverity.debug then
        local parameters = {}

        for i, valueFunction in ipairs({ ... }) do
            local value = valueFunction()

            if value == nil then
                value = "nil"
            end

            parameters[i] = tostring(valueFunction())
        end

        log(self, TotoWar.enums.logSeverity.debug, message, unpack(parameters))
    end
end

---Logs an error message.
---@param message string Message to log.
---@param ... boolean | integer | number | string Message parameters.
function TotoWarLogger:logError(message, ...)
    log(self, TotoWar.enums.logSeverity.error, message, ...)
end

---Logs an information message.
---@param message string Message to log.
---@param ... boolean | integer | number | string Message parameters.
function TotoWarLogger:logInfo(message, ...)
    if self.logLevel == TotoWar.enums.logSeverity.debug
        or self.logLevel == TotoWar.enums.logSeverity.info
    then
        log(self, TotoWar.enums.logSeverity.info, message, ...)
    end
end

---Logs an warning message.
---@param message string Message to log.
---@param ... boolean | integer | number | string Message parameters.
function TotoWarLogger:logWarning(message, ...)
    if self.logLevel == TotoWar.enums.logSeverity.debug
        or self.logLevel == TotoWar.enums.logSeverity.info
        or self.logLevel == TotoWar.enums.logSeverity.warning
    then
        log(self, TotoWar.enums.logSeverity.warning, message, ...)
    end
end

---Reacts to options being updated.
function TotoWarLogger:onOptionsUpdated()
    if TotoWar.options.debugEnabled
        and self.logLevel ~= TotoWar.enums.logSeverity.debug
    then
        ---@diagnostic disable-next-line: assign-type-mismatch
        self.logLevel = TotoWar.enums.logSeverity.debug
    elseif not TotoWar.options.debugEnabled
        and self.logLevel == TotoWar.enums.logSeverity.debug
    then
        ---@diagnostic disable-next-line: assign-type-mismatch
        self.logLevel = TotoWar.enums.logSeverity.info
    end
end
