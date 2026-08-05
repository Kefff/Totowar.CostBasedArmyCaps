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
