---Separator used to separated the event
local _multiplayerEventDataSeparator = "|"

---Maximum amount of characters that can be passed in a multiplayer event.
local _multiplayerEventMaximumDataLength = 100

---Manager for events.
---@class TotoWar__EventsManager
TotoWar__EventsManager = {
    ---Counter that determines the ID of new event subscriptions.
    ---@type integer
    idCounter = nil,

    ---List of event subscriptions.
    ---@type TotoWar__EventSubscription[]
    eventSubscriptions = nil
}
TotoWar__EventsManager.__index = TotoWar__EventsManager

---Initializes a new instance.
---@return TotoWar__EventsManager
function TotoWar__EventsManager.new()
    TotoWar.loggers.eventsManager:logDebug("new(): STARTED")

    local instance = setmetatable({}, TotoWar__EventsManager)

    instance.idCounter = 0
    instance.eventSubscriptions = {}

    TotoWar.loggers.eventsManager:logDebug("new(): COMPLETED")

    return instance
end

---Checks the condition for executing the callback function of an event subscription and executes it if conditions are met.
---@param eventSubscription TotoWar__EventSubscription Event subscription.
---@param event string Triggered event.
---@param context any Event context.
function TotoWar__EventsManager:executeEventSubscriptionIfConditionMet(eventSubscription, event, context)
    TotoWar.loggers.eventsManager:logDebug(
        "executeEventSubscriptionIfConditionMet(%s, %s, %s): STARTED",
        function() return eventSubscription.id end,
        function() return event end,
        function()
            if context ~= nil then
                return "context"
            end

            return nil
        end)

    local isSuccess, isToBeExecuted = xpcall(
        function() return eventSubscription.conditionFunction(context) end,
        function(error) self:onConditionError(eventSubscription, error) end)

    TotoWar.loggers.eventsManager:logDebug(
        "executeEventSubscriptionIfConditionMet(%s, %s, %s): CONDITION => %s | %s (%s, %s)",
        function() return eventSubscription.id end,
        function() return event end,
        function()
            if context ~= nil then
                return "context"
            end

            return nil
        end,
        function() return eventSubscription.id end,
        function() return isSuccess and isToBeExecuted end,
        function() return isSuccess end,
        function() return isToBeExecuted end)

    if isSuccess and isToBeExecuted then
        TotoWar.loggers.eventsManager:logDebug(
            "executeEventSubscriptionIfConditionMet(%s, %s, %s): EXECUTING => %s",
            function() return eventSubscription.id end,
            function() return event end,
            function()
                if context ~= nil then
                    return "context"
                end

                return nil
            end,
            function() return eventSubscription.id end)

        isSuccess = xpcall(
            function() eventSubscription.callbackFunction(context) end,
            function(error) self:onCallbackError(eventSubscription, error) end)

        if isSuccess then
            eventSubscription.executions = eventSubscription.executions + 1
        end
    end

    TotoWar.loggers.eventsManager:logDebug(
        "executeEventSubscriptionIfConditionMet(%s, %s, %s): COMPLETED",
        function() return eventSubscription.id end,
        function() return event end,
        function()
            if context ~= nil then
                return "context"
            end

            return nil
        end)
end

---Reacts to an error when executing the callback of an event subscription.
---@param eventSubscription TotoWar__EventSubscription Event subscription for which the callback
---@param error any Error.
function TotoWar__EventsManager:onCallbackError(eventSubscription, error)
    local stacktrace = debug.traceback(error, 2) -- 2 avoids the inclusion of the stacktrace of this error handling method
    TotoWar.loggers.eventsManager:logError(
        "Error during event \"%s\" when executing the callback of event subscription %s :\n%s",
        eventSubscription.event,
        eventSubscription.id,
        stacktrace)
end

---Reacts to an error when executing the callback of an event subscription.
---@param eventSubscription TotoWar__EventSubscription Event subscription for which the callback
---@param error any Error.
function TotoWar__EventsManager:onConditionError(eventSubscription, error)
    local stacktrace = debug.traceback(error, 2) -- 2 avoids the inclusion of the stacktrace of this error handling method
    TotoWar.loggers.eventsManager:logError(
        "Error during event \"%s\" when executing the condition of event subscription %s :\n%s",
        eventSubscription.event,
        eventSubscription.id,
        stacktrace)
end

---Reacts to an event being triggered by executing
---@param event string Triggered event.
---@param context any Event context.
function TotoWar__EventsManager:onEvent(event, context)
    TotoWar.loggers.eventsManager:logDebug(
        "onEvent(%s, %s): STARTED",
        function() return event end,
        function()
            if context ~= nil then
                return "context"
            end

            return nil
        end)

    -- Executing event subscriptions in the intended order
    local eventSubscriptions = TotoWar__Linq:where(
        self.eventSubscriptions,
        function(es) return es.event == event and (es.maximumExecutions == nil or es.executions < es.maximumExecutions) end)
    table.sort(eventSubscriptions, function(a, b) return a.priority < b.priority end)

    for index, eventSubscription in ipairs(eventSubscriptions) do
        self:executeEventSubscriptionIfConditionMet(eventSubscription, event, context)
    end

    -- Removing event subscriptions that have been executed the maximum number of times they were allowed
    local finishedEventSubscriptions = TotoWar__Linq:where(
        self.eventSubscriptions,
        function(es) return es.event == event and es.maximumExecutions ~= nil and es.executions >= es.maximumExecutions end)

    for index, finishedEventSubscription in ipairs(finishedEventSubscriptions) do
        TotoWar__Linq:remove(
            self.eventSubscriptions,
            function(es) return es.id == finishedEventSubscription.id end)

        TotoWar.loggers.eventsManager:logDebug(
            "onEvent(%s, %s): REMOVED FINISHED => %s",
            function() return event end,
            function()
                if context ~= nil then
                    return "context"
                end

                return nil
            end,
            function() return finishedEventSubscription.id end)
    end

    TotoWar.loggers.eventsManager:logDebug(
        "onEvent(%s, %s): COMPLETED",
        function() return event end,
        function()
            if context ~= nil then
                return "context"
            end

            return nil
        end)
end

---Initializes a new instance.
---@param event string Subscribed event.
---@param callbackFunction fun(context: any) Function executed when the subscribed event being triggered.
---@param conditionFunction (fun(context: any): boolean)? Function for deciding whether the callback function should be triggered, when the event subscribed event is fired based on the event context.
---@param maximumExecutions integer? Maximum number of times the callback function will be executed when the subscribed event is triggered.
---@param priority integer? Priority that determines in which order event subscriptions to the same event are executed.
---@return TotoWar__EventSubscription
function TotoWar__EventsManager:subscribe(event, callbackFunction, conditionFunction, maximumExecutions, priority)
    TotoWar.loggers.eventsManager:logDebug(
        "subscribe(%s, %s %s, %s, %s): STARTED",
        ---@diagnostic disable-next-line: return-type-mismatch
        function() return event end,
        function() return "callbackFunction" end,
        function()
            if conditionFunction ~= nil then
                return "conditionFunction"
            end

            return nil
        end,
        function() return maximumExecutions end,
        function() return priority end)

    self.idCounter = self.idCounter + 1
    local eventSubscription = TotoWar__EventSubscription.new(
        self.idCounter,
        event,
        callbackFunction,
        conditionFunction,
        maximumExecutions,
        priority)

    if not TotoWar__Linq:any(self.eventSubscriptions, function(es) return es.event == event end) then
        core:add_listener(
            "TotoWar__" .. event,
            event,
            true,
            function(context) self:onEvent(event, context) end,
            true)

        TotoWar.loggers.eventsManager:logDebug(
            "subscribe(%s, %s, %s, %s, %s): LISTENER ADDED",
            ---@diagnostic disable-next-line: return-type-mismatch
            function() return event end,
            function() return "callbackFunction" end,
            function()
                if conditionFunction ~= nil then
                    return "conditionFunction"
                end

                return nil
            end,
            function() return maximumExecutions end,
            function() return priority end)
    end

    table.insert(self.eventSubscriptions, eventSubscription)

    TotoWar.loggers.eventsManager:logDebug(
        "subscribe(%s, %s, %s, %s, %s): COMPLETED => %s",
        ---@diagnostic disable-next-line: return-type-mismatch
        function() return event end,
        function() return "callbackFunction" end,
        function()
            if conditionFunction ~= nil then
                return "conditionFunction"
            end

            return nil
        end,
        function() return maximumExecutions end,
        function() return priority end,
        function() return eventSubscription.id end)

    return eventSubscription
end

---Initializes a new instance.
---@param event string Subscribed event.
---@param callbackFunction fun(dataString: string) Function executed when the subscribed event being triggered. `dataString` can be empty when no data is passed in the event.
---@param conditionFunction (fun(dataString: string): boolean)? Function for deciding whether the callback function should be triggered, when the event subscribed event is fired based on the event context. `dataString` can be empty when no data is passed in the event.
---@param maximumExecutions integer? Maximum number of times the callback function will be executed when the subscribed event is triggered.
---@param priority integer? Priority that determines in which order event subscriptions to the same event are executed.
---@return TotoWar__EventSubscription
function TotoWar__EventsManager:subscribeMultiplayer(
    event,
    callbackFunction,
    conditionFunction,
    maximumExecutions,
    priority)
    TotoWar.loggers.eventsManager:logDebug(
        "subscribeMultiplayer(%s, %s, %s, %s, %s): STARTED",
        ---@diagnostic disable-next-line: return-type-mismatch
        function() return event end,
        function() return "callbackFunction" end,
        function()
            if conditionFunction ~= nil then
                return "conditionFunction"
            end

            return nil
        end,
        function() return maximumExecutions end,
        function() return priority end)

    local multiplayerCallbackFunction = function(context)
        local factionCqi = context:faction_cqi()

        -- Extracting the data string from the context and passing it to the callback function
        ---@type string
        local fullDataString = context:trigger()
        local dataString = fullDataString:gsub("^" .. event, "", 1)
        dataString = dataString:gsub("^" .. _multiplayerEventDataSeparator, "", 1)

        TotoWar.loggers.eventsManager:logDebug(
            "multiplayerCallbackFunction(context): STARTED => Origin: %s | Event: %s | Data: %s",
            function() return TotoWar__Gameplay:getFactionCaption(TotoWar__Gameplay:getFaction(factionCqi):name()) end,
            function() return event end,
            function() return dataString end)

        callbackFunction(dataString)

        TotoWar.loggers.eventsManager:logDebug(
            "multiplayerCallbackFunction(context): COMPLETED => Origin: %s | Event: %s | Data: %s",
            function() return TotoWar__Gameplay:getFactionCaption(TotoWar__Gameplay:getFaction(factionCqi):name()) end,
            function() return event end,
            function() return dataString end)
    end

    local multiplayerConditionFunction = function(context)
        local factionCqi = context:faction_cqi()

        -- Extracting the data string from the context and passing it to the condition function
        ---@type string
        local fullDataString = context:trigger()
        local dataString = fullDataString:gsub("^" .. event, "", 1)
        dataString = dataString:gsub("^" .. _multiplayerEventDataSeparator, "", 1)

        TotoWar.loggers.eventsManager:logDebug(
            "multiplayerConditionFunction(context): STARTED => Origin: %s | Event: %s | Data: %s",
            function() return TotoWar__Gameplay:getFactionCaption(TotoWar__Gameplay:getFaction(factionCqi):name()) end,
            function() return event end,
            function() return dataString end)

        -- Checking whether the event stored in the context corresponds to the subcribed event
        if fullDataString == event -- Case where no data is passed in the event
            or TotoWar__String:startsWith(fullDataString, event .. _multiplayerEventDataSeparator)
        then
            if result and conditionFunction ~= nil then
                result = conditionFunction(dataString)
            end
        end

        TotoWar.loggers.eventsManager:logDebug(
            "multiplayerConditionFunction(context): COMPLETE => Origin: %s | Event: %s | Data: %s | Execute callback: %s",
            function() return TotoWar__Gameplay:getFactionCaption(TotoWar__Gameplay:getFaction(factionCqi):name()) end,
            function() return event end,
            function() return dataString end,
            function() return result end)

        return result
    end

    local eventSubscription = self:subscribe(
        TotoWar__Enum_GameEvents.multiplayerEventTriggered,
        multiplayerCallbackFunction,
        multiplayerConditionFunction,
        maximumExecutions,
        priority)

    TotoWar.loggers.eventsManager:logDebug(
        "subscribeMultiplayer(%s, %s, %s, %s, %s): COMPLETED => %s",
        ---@diagnostic disable-next-line: return-type-mismatch
        function() return event end,
        function() return "callbackFunction" end,
        function()
            if conditionFunction ~= nil then
                return "conditionFunction"
            end

            return nil
        end,
        function() return maximumExecutions end,
        function() return priority end,
        function() return eventSubscription.id end)

    return eventSubscription
end

---Triggers an event.
---@param event string Event.
---@param context any? Event context.
function TotoWar__EventsManager:trigger(event, context)
    TotoWar.loggers.eventsManager:logDebug(
        "trigger(%s, %s): STARTED",
        function() return event end,
        function()
            if context ~= nil then
                return "context"
            end

            return nil
        end)

    if TotoWar__Linq:any(self.eventSubscriptions, function(es) return es.event == event end) then
        core:trigger_event(event, context)
    else
        TotoWar.loggers.eventsManager:logDebug(
            "trigger(%s, %s): NO SUBSCRIPTION",
            function() return event end,
            function()
                if context ~= nil then
                    return "context"
                end

                return nil
            end)
    end

    TotoWar.loggers.eventsManager:logDebug(
        "trigger(%s, %s): COMPLETED",
        function() return event end,
        function()
            if context ~= nil then
                return "context"
            end

            return nil
        end)
end

---Triggers a multiplayer event that is received by all players in the game.
---Used to synchronize state between all players to avoid desyncs.
---
---WARNING : `event` and `dataString` are concatenated using a `|` character. THEIR COMBINED SIZE MUST BE LESSER OR EQUAL TO 100 CHARACTERS.
---@param factionCqi integer Faction CQI.
---@param event string Event.
---@param dataString string? Data to pass in the event.
function TotoWar__EventsManager:triggerMultiplayer(factionCqi, event, dataString)
    TotoWar.loggers.eventsManager:logDebug(
        "triggerMultiplayer(%s, %s, %s): STARTED",
        function()
            return TotoWar__Gameplay:getFactionCaption(TotoWar__Gameplay:getFaction(factionCqi):name())
        end,
        function() return event end,
        function() return dataString end)

    local fullDataString = event

    if dataString ~= nil and #dataString > 0 then
        fullDataString = fullDataString .. _multiplayerEventDataSeparator .. dataString
    end

    if #fullDataString > _multiplayerEventMaximumDataLength then
        -- Due to technical limitation in the game, we cannot send more that 100 characters as data in the event
        TotoWar.loggers.eventsManager:logError(
            "Multiplayer event data string \"%s\" is too long and cannot be sent",
            fullDataString)

        return
    end

    CampaignUI.TriggerCampaignScriptEvent(factionCqi, fullDataString);

    TotoWar.loggers.eventsManager:logDebug(
        "triggerMultiplayer(%s, %s, %s): COMPLETED",
        function()
            return TotoWar__Gameplay:getFactionCaption(TotoWar__Gameplay:getFaction(factionCqi):name())
        end,
        function() return event end,
        function() return dataString end)
end

---Cancels the specified event subscription.
---@param eventSubscriptionId integer ID of the subscription to cancel.
function TotoWar__EventsManager:unsubscribe(eventSubscriptionId)
    TotoWar.loggers.eventsManager:logDebug(
        "unsubscribe(%s): STARTED",
        function() return eventSubscriptionId end)

    TotoWar__Linq:remove(self.eventSubscriptions, function(es) return es.id == eventSubscriptionId end)

    TotoWar.loggers.eventsManager:logDebug(
        "unsubscribe(%s): COMPLETED",
        function() return eventSubscriptionId end)
end
