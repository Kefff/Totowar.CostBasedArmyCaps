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
    TotoWar.loggers.modsManager:logDebug("TotoWar__ModsManager.new(): STARTED")

    local instance = setmetatable({}, TotoWar__ModsManager)

    instance.mods = {}

    TotoWar.loggers.modsManager:logDebug("TotoWar__ModsManager.new(): COMPLETED")

    return instance
end

---Finds a registered mod.
---@param modName string Mod name.
---@return TotoWar__ModDefinition | nil
function TotoWar__ModsManager:findMod(modName)
    TotoWar.loggers.modsManager:logDebug(
        "findMod(\"%s\"): STARTED",
        function() return modName end)

    for i, mod in ipairs(self.mods) do
        if mod.name == modName then
            TotoWar.loggers.modsManager:logDebug(
                "findMod(\"%s\"): COMPLETED",
                function() return modName end)

            return mod
        end
    end

    TotoWar.loggers.modsManager:logDebug(
        "findMod(\"%s\"): NOT FOUND",
        function() return modName end)

    return nil
end

---Gets a registered mod.
---Logs an error when the mod is not found.
---@param modName string Mod name.
---@return TotoWar__ModDefinition
function TotoWar__ModsManager:getMod(modName)
    TotoWar.loggers.modsManager:logDebug(
        "getMod(\"%s\"): STARTED",
        function() return modName end)

    local mod = self:findMod(modName)

    if mod then
        TotoWar.loggers.modsManager:logDebug(
            "getMod(\"%s\"): COMPLETED",
            function() return modName end)
    else
        TotoWar.loggers.modsManager:logError("TotoWar mod \"%s\" not found", modName)
    end

    ---@diagnostic disable-next-line: return-type-mismatch
    return mod
end

---Initializes registered mods.
function TotoWar__ModsManager:initializeMods()
    TotoWar.loggers.modsManager:logDebug("initializeMods: STARTED")

    local count = 0

    for i, mod in ipairs(self.mods) do
        count = count + 1

        TotoWar.loggers.modsManager:logInfo("Initializing mod \"%s\"", mod.name)

        mod.instance = mod.initializeFunction(self)
    end

    TotoWar.loggers.modsManager:logInfo("%s TotoWar mods initialized", count)
    TotoWar.loggers.modsManager:logDebug("initializeMods: COMPLETED")
end

---Registers a TotoWar Mod.
---@param modName string Mods name.
---@param initializeFunction fun(modsManager: TotoWar__ModsManager): any Function for initializing the mod.
function TotoWar__ModsManager:registerMod(modName, initializeFunction)
    TotoWar.loggers.modsManager:logDebug(
        "registerMod(\"%s\"): STARTED",
        function() return modName end)

    local mod = self:findMod(modName)

    if mod then
        TotoWar.loggers.modsManager:logWarning(
            "Mod \"%s\" is already registered. New registration has been ignored",
            modName)
    else
        mod = TotoWar__ModDefinition.new(modName, initializeFunction)
        table.insert(self.mods, mod)

        TotoWar.loggers.modsManager:logInfo("Mod \"%s\" registered", modName)
    end

    TotoWar.loggers.modsManager:logDebug(
        "registerMod(\"%s\"): COMPLETED",
        function() return modName end)
end
