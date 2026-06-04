---TotoWar mod definition.
---@class TotoWar__ModDefinition
TotoWar__ModDefinition = {
    ---Function for initializing the mod.
    ---@type fun(modsManager: TotoWar__ModsManager): any
    initializeFunction = nil,

    ---Instance of the mod.
    ---`nil` until the mod has been initializes by the mod manager.
    instance = nil,

    ---Name of the mod.
    ---@type string
    name = nil
}
TotoWar__ModDefinition.__index = TotoWar__ModDefinition

---Initializes a new instance.
---@param name string Name of the mod.
---@param initializationFunction fun(modsManager: TotoWar__ModsManager) Function for initializing the mod.
---@return TotoWar__ModDefinition
function TotoWar__ModDefinition.new(name, initializationFunction)
    TotoWar.loggers.generic:logDebug(
        "TotoWar__ModDefinition.new(%s): STARTED",
        function() return name end)

    local instance = setmetatable({}, TotoWar__ModDefinition)

    instance.initializeFunction = initializationFunction
    instance.name = name

    TotoWar.loggers.generic:logDebug(
        "TotoWar__ModDefinition.new(%s): COMPLETED",
        function() return name end)

    return instance
end
