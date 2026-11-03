require("script._lib.mod.totowar__logger")

local logger = TotoWar__Logger.get(TotoWar__Enum_LogCategories.eventsManager)

---Separator used to separated the event
local _multiplayerEventDataSeparator = "|"

---Maximum amount of characters that can be passed in a multiplayer event.
local _multiplayerEventMaximumDataLength = 100

---Reacts to an error when executing the callback of an event subscription.
---@param eventSubscription TotoWar__EventSubscription Event subscription for which the callback
---@param error any Error.
local function onCallbackError(eventSubscription, error)
    local stacktrace = debug.traceback(error, 2) -- 2 avoids the inclusion of the stacktrace of this error handling method
    logger:logError(
        "An error occurred while reacting to the game event \"%s\" (subscription %s):\n%s",
        eventSubscription.event,
        eventSubscription.id,
        stacktrace)
end

---Reacts to an error when executing the callback of an event subscription.
---@param eventSubscription TotoWar__EventSubscription Event subscription for which the callback
---@param error any Error.
local function onConditionError(eventSubscription, error)
    local stacktrace = debug.traceback(error, 2) -- 2 avoids the inclusion of the stacktrace of this error handling method
    logger:logError(
        "An error occurred while checking whether to react to the game event \"%s\" (subscription %s):\n%s",
        eventSubscription.event,
        eventSubscription.id,
        stacktrace)
end

---Checks the condition for executing the callback function of an event subscription and executes it if conditions are met.
---@param eventSubscription TotoWar__EventSubscription Event subscription.
---@param event string Triggered event.
---@param context any Event context.
local function executeEventSubscriptionIfConditionMet(eventSubscription, event, context)
    logger:logDebug(
        "executeEventSubscriptionIfConditionMet(%s, %s, %s): STARTED",
        eventSubscription.id,
        event,
        context ~= nil and "context" or "nil")

    local isSuccess, isToBeExecuted = xpcall(
        function() return eventSubscription.conditionFunction(context) end,
        function(error) onConditionError(eventSubscription, error) end)

    logger:logDebug(
        "executeEventSubscriptionIfConditionMet(%s, %s, %s): CONDITION => Execute: %s (Condition succeeded: %s | Condition result: %s)",
        eventSubscription.id,
        event,
        context ~= nil and "context" or "nil",
        isSuccess and isToBeExecuted,
        isSuccess,
        isToBeExecuted)

    if isSuccess and isToBeExecuted then
        logger:logDebug(
            "executeEventSubscriptionIfConditionMet(%s, %s, %s): EXECUTING",
            eventSubscription.id,
            event,
            context ~= nil and "context" or "nil")

        isSuccess = xpcall(
            function() eventSubscription.callbackFunction(context) end,
            function(error) onCallbackError(eventSubscription, error) end)

        if isSuccess then
            eventSubscription.executions = eventSubscription.executions + 1
        end
    end

    logger:logDebug(
        "executeEventSubscriptionIfConditionMet(%s, %s, %s): COMPLETED",
        eventSubscription.id,
        event,
        context ~= nil and "context" or "nil")
end

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

---Initializes the events manager.
function TotoWar__EventsManager:initialize()
    logger:logDebug("initialize(): STARTED")

    self.idCounter = 0
    self.eventSubscriptions = {}

    logger:logDebug("initialize(): COMPLETED")
end

---Reacts to an event being triggered by executing
---@param event string Triggered event.
---@param context any Event context.
function TotoWar__EventsManager:onEvent(event, context)
    logger:logDebug("onEvent(%s, %s): STARTED", event, context ~= nil and "context" or "nil")

    -- Executing event subscriptions in the intended order
    local eventSubscriptions = TotoWar__Linq:where(
        self.eventSubscriptions,
        function(es) return es.event == event and (es.maximumExecutions == nil or es.executions < es.maximumExecutions) end)
    table.sort(eventSubscriptions, function(a, b) return a.priority < b.priority end)

    for index, eventSubscription in ipairs(eventSubscriptions) do
        executeEventSubscriptionIfConditionMet(eventSubscription, event, context)
    end

    -- Removing event subscriptions that have been executed the maximum number of times they were allowed
    local finishedEventSubscriptions = TotoWar__Linq:where(
        self.eventSubscriptions,
        function(es) return es.event == event and es.maximumExecutions ~= nil and es.executions >= es.maximumExecutions end)

    for index, finishedEventSubscription in ipairs(finishedEventSubscriptions) do
        TotoWar__Linq:remove(
            self.eventSubscriptions,
            function(es) return es.id == finishedEventSubscription.id end)

        logger:logDebug(
            "onEvent(%s, %s): REMOVED FINISHED SUBSCRIPTION => %s",
            event,
            context ~= nil and "context" or "nil",
            finishedEventSubscription.id)
    end

    logger:logDebug("onEvent(%s, %s): COMPLETED", event, context ~= nil and "context" or "nil")
end

---Subscribes to an event.
---@param event string Subscribed event.
---@param callbackFunction fun(context: any) Function executed when the subscribed event being triggered.
---@param conditionFunction (fun(context: any): boolean)? Function for deciding whether the callback function should be triggered, when the event subscribed event is fired based on the event context.
---@param maximumExecutions integer? Maximum number of times the callback function will be executed when the subscribed event is triggered.
---@param priority integer? Priority that determines in which order event subscriptions to the same event are executed.
---@return TotoWar__EventSubscription
function TotoWar__EventsManager:subscribe(event, callbackFunction, conditionFunction, maximumExecutions, priority)
    logger:logDebug(
        "subscribe(%s, callbackFunction, %s, %s, %s): STARTED",
        event,
        conditionFunction ~= nil and "conditionFunction" or "nil",
        maximumExecutions,
        priority)

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

        logger:logDebug(
            "subscribe(%s, callbackFunction, %s, %s, %s): LISTENER ADDED",
            event,
            conditionFunction ~= nil and "conditionFunction" or "nil",
            maximumExecutions,
            priority)
    end

    table.insert(self.eventSubscriptions, eventSubscription)

    logger:logDebug(
        "subscribe(%s, callbackFunction, %s, %s, %s): COMPLETED => Subscription %s",
        event,
        conditionFunction ~= nil and "conditionFunction" or "nil",
        maximumExecutions,
        priority,
        eventSubscription.id)

    return eventSubscription
end

---Subscribes to a multiplayer event.
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
    logger:logDebug(
        "subscribeMultiplayer(%s, callbackFunction, %s, %s, %s): STARTED",
        event,
        conditionFunction ~= nil and "conditionFunction" or "nil",
        maximumExecutions,
        priority)

    local multiplayerCallbackFunction = function(context)
        local factionCqi = context:faction_cqi()

        -- Extracting the data string from the context and passing it to the callback function
        ---@type string
        local fullDataString = context:trigger()
        local dataString = fullDataString:gsub("^" .. event, "", 1)
        dataString = dataString:gsub("^" .. _multiplayerEventDataSeparator, "", 1)

        logger:logDebug(
            "subscribeMultiplayer(%s, callbackFunction, %s, %s, %s): CALLBACK STARTED => Origin: %s | Data: %s",
            event,
            conditionFunction ~= nil and "conditionFunction" or "nil",
            maximumExecutions,
            priority,
            function() return TotoWar__Gameplay:getFactionFullCaption(TotoWar__Gameplay:getFaction(factionCqi)) end,
            dataString)

        callbackFunction(dataString)

        logger:logDebug(
            "subscribeMultiplayer(%s, callbackFunction, %s, %s, %s): CALLBACK COMPLETED => Origin: %s | Data: %s",
            event,
            conditionFunction ~= nil and "conditionFunction" or "nil",
            maximumExecutions,
            priority,
            function() return TotoWar__Gameplay:getFactionFullCaption(TotoWar__Gameplay:getFaction(factionCqi)) end,
            dataString)
    end

    local multiplayerConditionFunction = function(context)
        local factionCqi = context:faction_cqi()

        -- Extracting the data string from the context and passing it to the condition function
        ---@type string
        local fullDataString = context:trigger()
        local dataString = fullDataString:gsub("^" .. event, "", 1)
        dataString = dataString:gsub("^" .. _multiplayerEventDataSeparator, "", 1)

        logger:logDebug(
            "subscribeMultiplayer(%s, callbackFunction, %s, %s, %s): CONDITION STARTED => Origin: %s | Data: %s",
            event,
            conditionFunction ~= nil and "conditionFunction" or "nil",
            maximumExecutions,
            priority,
            function() return TotoWar__Gameplay:getFactionFullCaption(TotoWar__Gameplay:getFaction(factionCqi)) end,
            dataString)

        -- Checking whether the event stored in the context corresponds to the subcribed event
        if fullDataString == event -- Case where no data is passed in the event
            or TotoWar__String:startsWith(fullDataString, event .. _multiplayerEventDataSeparator)
        then
            if result and conditionFunction ~= nil then
                result = conditionFunction(dataString)
            end
        end

        logger:logDebug(
            "subscribeMultiplayer(%s, callbackFunction, %s, %s, %s): CONDITION COMPLETED => Origin: %s | Data: %s | Execute callback: %s",
            event,
            conditionFunction ~= nil and "conditionFunction" or "nil",
            maximumExecutions,
            priority,
            function() return TotoWar__Gameplay:getFactionFullCaption(TotoWar__Gameplay:getFaction(factionCqi)) end,
            dataString,
            result)

        return result
    end

    local eventSubscription = self:subscribe(
        TotoWar__Enum_GameEvents.multiplayerEventTriggered,
        multiplayerCallbackFunction,
        multiplayerConditionFunction,
        maximumExecutions,
        priority)

    logger:logDebug(
        "subscribeMultiplayer(%s, callbackFunction, %s, %s, %s): COMPLETED => Subscription %s",
        event,
        conditionFunction ~= nil and "conditionFunction" or "nil",
        maximumExecutions,
        priority,
        eventSubscription.id)

    return eventSubscription
end

---Triggers an event.
---@param event string Event.
---@param context any? Event context.
function TotoWar__EventsManager:trigger(event, context)
    logger:logDebug(
        "trigger(%s, %s): STARTED",
        event,
        context ~= nil and "context" or "nil")

    if TotoWar__Linq:any(self.eventSubscriptions, function(es) return es.event == event end) then
        core:trigger_event(event, context)
    else
        logger:logDebug(
            "trigger(%s, %s): NO SUBSCRIPTION",
            event,
            context ~= nil and "context" or "nil")
    end

    logger:logDebug(
        "trigger(%s, %s): COMPLETED",
        event,
        context ~= nil and "context" or "nil")
end

---Triggers a multiplayer event that is received by all players in the game.
---Used to synchronize state between all players to avoid desyncs.
---
---WARNING : `event` and `dataString` are concatenated using a `|` character. THEIR COMBINED SIZE MUST BE LESSER OR EQUAL TO 100 CHARACTERS.
---@param factionCqi integer Faction CQI.
---@param event string Event.
---@param dataString string? Data to pass in the event.
function TotoWar__EventsManager:triggerMultiplayer(factionCqi, event, dataString)
    logger:logDebug(
        "triggerMultiplayer(%s, %s, %s): STARTED => %s",
        factionCqi,
        event,
        dataString,
        function() return TotoWar__Gameplay:getFactionFullCaption(TotoWar__Gameplay:getFaction(factionCqi)) end)

    local fullDataString = event

    if dataString ~= nil and #dataString > 0 then
        fullDataString = fullDataString .. _multiplayerEventDataSeparator .. dataString
    end

    if #fullDataString > _multiplayerEventMaximumDataLength then
        -- Due to technical limitation in the game, we cannot send more that 100 characters as data in the event
        logger:logError(
            "A message to synchronize the players of the multiplayer game could not be sent because it is too long: \"%s\"",
            fullDataString)
        logger:logDebug(
            "triggerMultiplayer(%s, %s, %s): COMPLETED => %s | Not sent, message too long",
            factionCqi,
            event,
            dataString,
            function() return TotoWar__Gameplay:getFactionFullCaption(TotoWar__Gameplay:getFaction(factionCqi)) end)

        return
    end

    CampaignUI.TriggerCampaignScriptEvent(factionCqi, fullDataString);

    logger:logDebug(
        "triggerMultiplayer(%s, %s, %s): COMPLETED => %s",
        factionCqi,
        event,
        dataString,
        function() return TotoWar__Gameplay:getFactionFullCaption(TotoWar__Gameplay:getFaction(factionCqi)) end)
end

---Cancels the specified event subscription.
---@param eventSubscriptionId integer ID of the subscription to cancel.
function TotoWar__EventsManager:unsubscribe(eventSubscriptionId)
    logger:logDebug("unsubscribe(%s): STARTED", eventSubscriptionId)

    TotoWar__Linq:remove(self.eventSubscriptions, function(es) return es.id == eventSubscriptionId end)

    logger:logDebug("unsubscribe(%s): COMPLETED", eventSubscriptionId)
end
