---TotoWar mod.
---@class TotoWarMod
TotoWarMod = {
    ---Function for initializing the mod.
    ---@type function
    initializeFunction = nil,

    ---Instance of the mod.
    ---`nil` until the mod has been initializes by the mod manager.
    instance = nil,

    ---Name of the mod.
    ---@type string
    name = nil
}
TotoWarMod.__index = TotoWarMod

---Initializes a new instance.
---@param name string Name of the mod.
---@param initializationFunction function Function for initializing the mod.
---@return TotoWarMod
function TotoWarMod.new(name, initializationFunction)
    TotoWar().genericLogger:logDebug("TotoWarMod.new(%s): STARTED", name)

    local instance = setmetatable({}, TotoWarMod)

    instance.initializeFunction = initializationFunction
    instance.name = name

    TotoWar().genericLogger:logDebug("TotoWarMod.new(%s): COMPLETED", name)

    return instance
end
