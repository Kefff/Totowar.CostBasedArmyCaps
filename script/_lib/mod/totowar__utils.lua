---Manager for events.
---@class TotoWar__Utils
TotoWar__Utils = {}
TotoWar__Utils.__index = TotoWar__Utils

---Executes a function after a delay.
---@param callback fun() Function to executed with a delay.
---@param delay integer Delay in seconds.
function TotoWar__Utils:delay(callback, delay)
    TotoWar.loggers.generic:logDebug("TotoWar__Utils.delay(callback, %s): STARTED", function() return delay end)

    ---Reacts to an error when executing the callback
    ---@param error any Error.
    local onError = function(error)
        local stacktrace = debug.traceback(error, 2) -- 2 avoids the inclusion of the stacktrace of this error handling method
        TotoWar.loggers.generic:logError(
            "Error while executing delayed function:\n%s",
            stacktrace)
    end

    cm:callback(
        function()
            xpcall(
                function() callback() end,
                function(error) onError(error) end)
        end,
        delay)

    TotoWar.loggers.generic:logDebug("TotoWar__Utils.delay(callback, %s): COMPLETED", function() return delay end)
end

---Gets a consistent pseudo-random value using a seed generated from parameters.
---@param minValue integer Minimum value.
---@param maxValue integer Maximum value.
---@param ... string Parameters detemining the seed.
---@return integer
function TotoWar__Utils:randomWithSeed(minValue, maxValue, ...)
    local parameters = { ... }

    TotoWar.loggers.generic:logDebug(
        "TotoWar__Utils.randomWithSeed(%s, %s, %s): STARTED",
        function() return minValue end,
        function() return maxValue end,
        function() return #parameters end)

    local seed = 0

    for _, parameter in ipairs(parameters) do
        local parameterAsString = tostring(parameter)

        for i = 1, #parameterAsString do
            seed = seed + string.byte(parameterAsString, i) * (i % 3 + 1) -- Adding ASCII codes
        end
    end

    TotoWar.loggers.generic:logDebug(
        "TotoWar__Utils.randomWithSeed(%s, %s, %s): STARTED => SEED: %s",
        function() return minValue end,
        function() return maxValue end,
        function() return #parameters end,
        function() return seed end)

    math.randomseed(seed)
    local randomValue = math.random(minValue, maxValue)

    TotoWar.loggers.generic:logDebug(
        "TotoWar__Utils.randomWithSeed(%s, %s, %s): COMPLETED => %s",
        function() return minValue end,
        function() return maxValue end,
        function() return #parameters end,
        function() return randomValue end)

    return randomValue
end
