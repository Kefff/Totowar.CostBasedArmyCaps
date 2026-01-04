---Name of the TotoWar base mod.
---@type string
TotoWarCoreModName = "totowar_core"

---TotoWar base mod.
---@class TotoWarCore
TotoWarCore = {
    ---Generic logger for elements that do not have a dedicated logger.
    ---@type TotoWarLogger
    genericLogger = nil,

    ---Indicates whether debug messages are logged.
    isDebug = false,

    ---Mods manager.
    ---@type TotoWarModsManager
    modsManager = nil,

    ---Utility tools for TotoWar mods.
    ---@type TotoWarUtils
    utils = nil
}
TotoWarCore.__index = TotoWarCore

---Initializes a new instance.
---@return TotoWarCore
function TotoWarCore.new()
    local instance = setmetatable({}, TotoWarCore)

    core:add_static_object(TotoWarCoreModName, instance)

    instance.genericLogger = TotoWarLogger.new("totowar_generic", nil, true)
    instance.modsManager = TotoWarModsManager.new()
    instance.utils = TotoWarUtils.new()

    instance.genericLogger:logDebug("TotoWarCore.new(): COMPLETED")

    return instance
end

---Gets the TotoWar mod instance.
---Allows the use TotoWar mods.
---@return TotoWarCore
function TotoWar()
    ---@type TotoWarCore
    local totoWarCoreMod = core:get_static_object(TotoWarCoreModName)

    return totoWarCoreMod
end
