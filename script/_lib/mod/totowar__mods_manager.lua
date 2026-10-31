local logger = TotoWar__Logger.get(TotoWar__Enum_LogCategories.modsManager)

---Manager for other TotoWar mods.
---@class TotoWar__ModsManager
TotoWar__ModsManager = {
    ---List of registered TotoWar mods.
    ---@type TotoWar__ModDefinition[]
    mods = nil
}
TotoWar__ModsManager.__index = TotoWar__ModsManager

---Initializes a new instance.
---@return TotoWar__ModsManager
function TotoWar__ModsManager.new()
    logger:logDebug("new(): STARTED")

    local instance = setmetatable({}, TotoWar__ModsManager)

    instance.mods = {}

    logger:logDebug("new(): COMPLETED")

    return instance
end

---Finds a registered mod.
---@param modName string Mod name.
---@return TotoWar__ModDefinition | nil
function TotoWar__ModsManager:findMod(modName)
    logger:logDebug(
        "findMod(%s): STARTED",
        modName)

    for i, mod in ipairs(self.mods) do
        if mod.name == modName then
            logger:logDebug(
                "findMod(%s): COMPLETED",
                modName)

            return mod
        end
    end

    logger:logDebug(
        "findMod(%s): NOT FOUND",
        modName)

    return nil
end

---Gets a registered mod.
---Logs an error when the mod is not found.
---@param modName string Mod name.
---@return TotoWar__ModDefinition
function TotoWar__ModsManager:getMod(modName)
    logger:logDebug(
        "getMod(%s): STARTED",
        modName)

    local mod = self:findMod(modName)

    if mod ~= nil then
        logger:logDebug(
            "getMod(%s): COMPLETED",
            modName)
    else
        logger:logError("The TotoWar mod \"%s\" could not be found", modName)
    end

    ---@diagnostic disable-next-line: return-type-mismatch
    return mod
end

---Initializes registered mods.
function TotoWar__ModsManager:initializeMods()
    logger:logDebug("initializeMods(): STARTED")

    local count = 0

    for i, mod in ipairs(self.mods) do
        count = count + 1

        logger:logInfo("Initializing mod \"%s\"", mod.caption)

        mod.instance = mod.initializeFunction(self)
    end

    logger:logInfo("%s TotoWar mod(s) initialized", count)
    logger:logDebug("initializeMods(): COMPLETED")
end

---Registers a TotoWar Mod.
---@param modName string Mods name.
---@param modCaption string Caption of the mod displayed to the player.
---@param initializeFunction fun(modsManager: TotoWar__ModsManager): any Function for initializing the mod.
function TotoWar__ModsManager:registerMod(modName, modCaption, initializeFunction)
    logger:logDebug(
        "registerMod(%s, %s, %s): STARTED",
        modName,
        modCaption,
        initializeFunction ~= nil and "initializeFunction" or "nil")

    local mod = self:findMod(modName)

    if mod ~= nil then
        logger:logWarning(
            "Mod \"%s\" is already registered. New registration has been ignored",
            modCaption)
    else
        mod = TotoWar__ModDefinition.new(modName, modCaption, initializeFunction)
        table.insert(self.mods, mod)

        logger:logInfo("Mod \"%s\" registered", modCaption)
    end

    logger:logDebug(
        "registerMod(%s, %s, %s): COMPLETED",
        modName,
        modCaption,
        initializeFunction ~= nil and "initializeFunction" or "nil")
end
