---Manager for other TotoWar mods.
---@class TotoWarModsManager
TotoWarModsManager = {
    ---Logger.
    ---@type TotoWarLogger
    logger = nil,

    ---List of registered TotoWar mods.
    ---@type TotoWarModDefinition[]
    mods = nil
}
TotoWarModsManager.__index = TotoWarModsManager

---Initializes a new instance.
---@return TotoWarModsManager
function TotoWarModsManager.new()
    local instance = setmetatable({}, TotoWarModsManager)

    instance.logger = TotoWarLogger.new("TotoWar_ModsManager")
    instance.mods = {}

    instance.logger:logDebug("new(): COMPLETED")

    return instance
end

---Finds a registered mod.
---@param modName string Mod name.
---@return TotoWarModDefinition | nil
function TotoWarModsManager:findMod(modName)
    self.logger:logDebug(
        "findMod(\"%s\"): STARTED",
        function() return modName end)

    for i, mod in ipairs(self.mods) do
        if mod.name == modName then
            self.logger:logDebug(
                "findMod(\"%s\"): COMPLETED",
                function() return modName end)

            return mod
        end
    end

    self.logger:logDebug(
        "findMod(\"%s\"): NOT FOUND",
        function() return modName end)

    return nil
end

---Gets a registered mod.
---Logs an error when the mod is not found.
---@param modName string Mod name.
---@return TotoWarModDefinition
function TotoWarModsManager:getMod(modName)
    self.logger:logDebug(
        "getMod(\"%s\"): STARTED",
        function() return modName end)

    local mod = self:findMod(modName)

    if mod then
        self.logger:logDebug(
            "getMod(\"%s\"): COMPLETED",
            function() return modName end)
    else
        self.logger:logError("TotoWar mod \"%s\" not found", modName)
    end

    ---@diagnostic disable-next-line: return-type-mismatch
    return mod
end

---Initializes registered mods.
function TotoWarModsManager:initializeMods()
    self.logger:logDebug("initializeMods: STARTED")

    local count = 0

    for i, mod in ipairs(self.mods) do
        count = count + 1

        self.logger:logInfo("Initializing mod \"%s\"", mod.name)

        mod.instance = mod.initializeFunction(self)
    end

    self.logger:logInfo("%s TotoWar mods initialized", count)
    self.logger:logDebug("initializeMods: COMPLETED")
end

---Registers a TotoWar Mod.
---@param modName string Mods name.
---@param initializeFunction fun(modsManager: TotoWarModsManager): nil Function for initializing the mod.
function TotoWarModsManager:registerMod(modName, initializeFunction)
    self.logger:logDebug(
        "registerMod(\"%s\"): STARTED",
        function() return modName end)

    local mod = self:findMod(modName)

    if mod then
        self.logger:logWarning("Mod \"%s\" is already registered. New registration has been ignored.", modName)
    else
        mod = TotoWarModDefinition.new(modName, initializeFunction)
        table.insert(self.mods, mod)

        self.logger:logInfo("Mod \"%s\" registered", modName)
    end

    self.logger:logDebug(
        "registerMod(\"%s\"): COMPLETED",
        function() return modName end)
end
