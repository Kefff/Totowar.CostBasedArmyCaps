---Manager for other TotoWar mods.
---@class TotoWarModsManager
TotoWarModsManager = {
    ---Logger.
    ---@type TotoWarLogger
    logger = nil,

    ---List of registered TotoWar mods.
    ---@type TotoWarMod[]
    mods = {}
}
TotoWarModsManager.__index = TotoWarModsManager

---Initializes a new instance.
---@return TotoWarModsManager
function TotoWarModsManager.new()
    local instance = setmetatable({}, TotoWarModsManager)

    instance.logger = TotoWarLogger.new("totowar_mods_manager")

    instance.logger:logDebug("TotoWarModsManager.new(): COMPLETED")

    return instance
end

---Finds a registered mod.
---@param modName string Mod name.
---@return TotoWarMod | nil
function TotoWarModsManager:findMod(modName)
    self.logger:logDebug("TotoWarModsManager:findMod(\"%s\"): STARTED", modName)

    for i, mod in ipairs(self.mods) do
        if mod.name == modName then
            self.logger:logDebug("TotoWarModsManager:findMod(\"%s\"): COMPLETED", modName)

            return mod
        end
    end

    self.logger:logDebug("TotoWarModsManager:findMod(\"%s\"): NOT FOUND", modName)

    return nil
end

---Gets a registered mod.
---Logs an error when the mod is not found.
---@param modName string Mod name.
---@return TotoWarMod
function TotoWarModsManager:getMod(modName)
    self.logger:logDebug("TotoWarModsManager:getMod(\"%s\"): STARTED", modName)

    local mod = self:findMod(modName)

    if mod then
        self.logger:logDebug("TotoWarModsManager:getMod(\"%s\"): COMPLETED", modName)
    else
        self.logger:logError("TotoWar mod \"%s\" not found", modName)
    end

    ---@diagnostic disable-next-line: return-type-mismatch
    return mod
end

---Initializes registered mods.
function TotoWarModsManager:initializeMods()
    self.logger:logDebug("TotoWarModsManager:initializeMods: STARTED")

    local count = 0

    for i, mod in ipairs(self.mods) do
        count = count + 1

        self.logger:logInfo("Initializing mod \"%s\"", mod.name)

        mod.instance = mod.initializeFunction(self)
    end

    self.logger:logInfo("%s TotoWar mods initialized", count)
    self.logger:logDebug("TotoWarModsManager:initializeMods: COMPLETED")
end

---Registers a TotoWar Mod.
---@param modName string Mods name.
---@param initializeFunction function Function for initializing the mod.
function TotoWarModsManager:registerMod(modName, initializeFunction)
    self.logger:logDebug("TotoWarModsManager:registerMod(\"%s\"): STARTED", modName)

    local mod = self:findMod(modName)

    if mod then
        self.logger:logWarning("Mod \"%s\" is already registered. New registration has been ignored.", modName)
    else
        mod = TotoWarMod.new(modName, initializeFunction)
        table.insert(self.mods, mod)

        self.logger:logInfo("Mod \"%s\" registered", modName)
    end

    self.logger:logDebug("TotoWarModsManager:registerMod(\"%s\"): COMPLETED", modName)
end
