---Manager for other TotoWar mods.
---@class TotoWarModsManager
TotoWarModsManager = {
    ---List of registered TotoWar mods.
    ---@type TotoWarModDefinition[]
    mods = nil
}
TotoWarModsManager.__index = TotoWarModsManager

---Initializes a new instance.
---@return TotoWarModsManager
function TotoWarModsManager.new()
    TotoWar.loggers.modsManager:logDebug("TotoWarModsManager.new(): STARTED")

    local instance = setmetatable({}, TotoWarModsManager)

    instance.mods = {}

    TotoWar.loggers.modsManager:logDebug("TotoWarModsManager.new(): COMPLETED")

    return instance
end

---Finds a registered mod.
---@param modName string Mod name.
---@return TotoWarModDefinition | nil
function TotoWarModsManager:findMod(modName)
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
---@return TotoWarModDefinition
function TotoWarModsManager:getMod(modName)
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
function TotoWarModsManager:initializeMods()
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
---@param initializeFunction fun(modsManager: TotoWarModsManager) Function for initializing the mod.
function TotoWarModsManager:registerMod(modName, initializeFunction)
    TotoWar.loggers.modsManager:logDebug(
        "registerMod(\"%s\"): STARTED",
        function() return modName end)

    local mod = self:findMod(modName)

    if mod then
        TotoWar.loggers.modsManager:logWarning("Mod \"%s\" is already registered. New registration has been ignored.",
            modName)
    else
        mod = TotoWarModDefinition.new(modName, initializeFunction)
        table.insert(self.mods, mod)

        TotoWar.loggers.modsManager:logInfo("Mod \"%s\" registered", modName)
    end

    TotoWar.loggers.modsManager:logDebug(
        "registerMod(\"%s\"): COMPLETED",
        function() return modName end)
end
