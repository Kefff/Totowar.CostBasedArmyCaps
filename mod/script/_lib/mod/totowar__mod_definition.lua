local logger = TotoWar__Logger.get(TotoWar__Enum_LogCategories.generic)

---TotoWar mod definition.
---@class TotoWar__ModDefinition
TotoWar__ModDefinition = {
    ---Caption of the mod displayed to the player.
    ---@type string
    caption = nil,

    ---Function for initializing the mod.
    ---@type fun()
    initializeFunction = nil,

    ---Name of the mod.
    ---@type string
    name = nil
}
TotoWar__ModDefinition.__index = TotoWar__ModDefinition

---Initializes a new instance.
---@param name string Name of the mod.
---@param caption string Caption of the mod displayed to the player.
---@param initializationFunction fun() Function for initializing the mod.
---@return TotoWar__ModDefinition
function TotoWar__ModDefinition.new(name, caption, initializationFunction)
    logger:logDebug(
        "TotoWar__ModDefinition.new(%s, %s, %s): STARTED",
        name,
        caption,
        initializationFunction ~= nil and "initializationFunction" or "nil")

    local instance = setmetatable({}, TotoWar__ModDefinition)

    instance.caption = caption
    instance.initializeFunction = initializationFunction
    instance.name = name

    logger:logDebug(
        "TotoWar__ModDefinition.new(%s, %s, %s): COMPLETED",
        name,
        caption,
        initializationFunction ~= nil and "initializationFunction" or "nil")

    return instance
end
