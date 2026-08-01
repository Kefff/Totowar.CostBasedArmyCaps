---Event subscription.
---@class TotoWar__EventSubscription
TotoWar__EventSubscription = {
    ---Function executed when the subscribed event is triggered.
    ---@type fun(context: any)
    callbackFunction = nil,

    ---Function for deciding whether the callback function should be triggered when the event subscribed event is triggered, based on the event context.
    ---@type fun(context: any): boolean
    conditionFunction = nil,

    ---Subscribed event.
    ---@type string
    event = nil,

    ---Number of times the callback function has been executed.
    ---@type integer
    executions = nil,

    ---Unique identifier used to be able to cancel a subscription.
    ---@type integer
    id = nil,

    ---Maximum number of times the callback function will be executed when the subscribed event is triggered.
    ---@type integer | nil
    maximumExecutions = nil,

    ---Priority that determines in which order event subscriptions to the same event are executed.
    ---@type integer
    priority = nil
}
TotoWar__EventSubscription.__index = TotoWar__EventSubscription

---Initializes a new instance.
---@param id integer Unique identifier.
---@param event string Subscribed event.
---@param callbackFunction fun(context: any) Function executed when the subscribed event is triggered.
---@param conditionFunction (fun(context: any): boolean)? Function for deciding whether the callback function should be triggered, when the event subscribed event is fired based on the event context.
---@param maximumExecutions integer? Maximum number of times the callback function will be executed when the subscribed event is triggered.
---@param priority integer? Priority that determines in which order event subscriptions to the same event are executed.
---@return TotoWar__EventSubscription
function TotoWar__EventSubscription.new(id, event, callbackFunction, conditionFunction, maximumExecutions, priority)
    local instance = setmetatable({}, TotoWar__EventSubscription)

    instance.callbackFunction = callbackFunction
    instance.conditionFunction = conditionFunction or function() return true end
    instance.event = event
    instance.executions = 0
    instance.id = id
    instance.maximumExecutions = maximumExecutions
    instance.priority = priority or 100000

    return instance
end
