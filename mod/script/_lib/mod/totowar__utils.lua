local logger = TotoWar__Logger.get(TotoWar__Enum_LogCategories.generic)

---Executes a delayed function and logs its errors, which would otherwise be lost.
---@param callback fun() Delayed function.
local function executeDelayedCallback(callback)
    xpcall(
        function() callback() end,
        function(error)
            local stacktrace = debug.traceback(error, 2) -- 2 avoids the inclusion of the stacktrace of this error handling method
            logger:logError(
                "An error occurred while executing a delayed action of the mod:\n%s",
                stacktrace)
        end)
end

---Utility functions for TotoWar mods.
---@class TotoWar__Utils
TotoWar__Utils = {}
TotoWar__Utils.__index = TotoWar__Utils

---Executes a function after a delay in game time (campaign model time).
---- Paused with the game, accelerated during the end turn sequence, resolution of a model update (100 to 200 ms).
---- Synchronised between the clients of a multiplayer game: the function is executed at the same moment of the game on each client.
---  Only when it is scheduled on every client, from a game event: scheduled from a UI event (click, selection...), it only runs on the client of the player who triggered it.
---- To use for everything that changes the game (units, characters, effect bundles, movement...) or relies on its state.
---@param callback fun() Function to execute with a delay.
---@param delay number Delay in seconds. A delay of 0 or less executes the function immediately.
function TotoWar__Utils:delay(callback, delay)
    cm:callback(function() executeDelayedCallback(callback) end, delay)
end

---Executes a function after a delay in real time.
---- Not paused with the game, constant speed, resolution of a UI update (one frame).
---- Not synchronised between the clients of a multiplayer game, and the game model may not be in a state to be queried.
---- To use only for UI changes of the local player (displaying, resizing...), never to change the game:
---  in multiplayer, a game change made at different moments on each client desynchronises the game.
---@param callback fun() Function to execute with a delay.
---@param delay integer Delay in milliseconds. A delay of 1 executes the function at the next UI update, a delay of 0 or less immediately.
function TotoWar__Utils:delayInRealTime(callback, delay)
    core:get_tm():real_callback(function() executeDelayedCallback(callback) end, delay)
end
