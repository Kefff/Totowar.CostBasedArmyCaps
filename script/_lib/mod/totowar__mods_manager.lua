local logger = TotoWar__Logger.get(TotoWar__Enum_LogCategories.modsManager)

---Manager for other TotoWar mods.
---@class TotoWar__ModsManager
TotoWar__ModsManager = {
    ---List of registered TotoWar mods.
    ---@type TotoWar__ModDefinition[]
    mods = nil
}

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
        logger:logError("%s: TotoWar mod not found", modName)
    end

    ---@diagnostic disable-next-line: return-type-mismatch
    return mod
end

---Initializes the mods manager.
function TotoWar__ModsManager:initialize()
    logger:logDebug("initialize(): STARTED")

    self.mods = {}

    logger:logDebug("initialize(): COMPLETED")
end

---Initializes registered mods.
function TotoWar__ModsManager:initializeMods()
    logger:logDebug("initializeMods(): STARTED")

    local count = 0

    for i, mod in ipairs(self.mods) do
        count = count + 1

        logger:logInfo("Initializing mod \"%s\"", mod.caption)

        mod.initializeFunction()
    end

    logger:logInfo("%s TotoWar mod(s) initialized", count)
    logger:logDebug("initializeMods(): COMPLETED")
end

---Registers a TotoWar Mod.
---@param modName string Mods name.
---@param modCaption string Caption of the mod displayed to the player.
---@param initializeFunction fun() Function for initializing the mod.
function TotoWar__ModsManager:registerMod(modName, modCaption, initializeFunction)
    logger:logDebug(
        "registerMod(%s, %s, %s): STARTED",
        modName,
        modCaption,
        initializeFunction ~= nil and "initializeFunction" or "nil")

    local mod = self:findMod(modName)

    if mod ~= nil then
        logger:logWarning(
            "%s: mod already registered, new registration ignored",
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
