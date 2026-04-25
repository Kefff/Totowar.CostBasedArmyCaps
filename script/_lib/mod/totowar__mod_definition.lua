---TotoWar mod definition.
---@class TotoWarModDefinition
TotoWarModDefinition = {
    ---Function for initializing the mod.
    ---@type fun(modsManager: TotoWarModsManager)
    initializeFunction = nil,

    ---Instance of the mod.
    ---`nil` until the mod has been initializes by the mod manager.
    instance = nil,

    ---Name of the mod.
    ---@type string
    name = nil
}
TotoWarModDefinition.__index = TotoWarModDefinition

---Initializes a new instance.
---@param name string Name of the mod.
---@param initializationFunction fun(modsManager: TotoWarModsManager) Function for initializing the mod.
---@return TotoWarModDefinition
function TotoWarModDefinition.new(name, initializationFunction)
    TotoWar.loggers.generic:logDebug(
        "TotoWarModDefinition.new(%s): STARTED",
        function() return name end)

    local instance = setmetatable({}, TotoWarModDefinition)

    instance.initializeFunction = initializationFunction
    instance.name = name

    TotoWar.loggers.generic:logDebug(
        "TotoWarModDefinition.new(%s): COMPLETED",
        function() return name end)

    return instance
end
