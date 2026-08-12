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
    TotoWar.loggers.eventsManager:logDebug("TotoWar__EventsManager.new(): STARTED")

    local instance = setmetatable({}, TotoWar__EventsManager)

    instance.idCounter = 0
    instance.eventSubscriptions = {}

    TotoWar.loggers.eventsManager:logDebug("TotoWar__EventsManager.new(): COMPLETED")

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
        "TotoWar__EventsManager.subscribe(%s, %s, %s, %s): STARTED",
        ---@diagnostic disable-next-line: return-type-mismatch
        function() return event end,
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
            "TotoWar__EventsManager.subscribe(%s, %s, %s, %s): LISTENER ADDED",
            ---@diagnostic disable-next-line: return-type-mismatch
            function() return event end,
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
        "TotoWar__EventsManager.subscribe(%s, %s, %s, %s): COMPLETED => %s",
        ---@diagnostic disable-next-line: return-type-mismatch
        function() return event end,
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
