---Name of the TotoWar base mod.
---@type string
TotoWarCoreModName = "totowar"

---TotoWar base mod.
---@class TotoWarCore
TotoWarCore = {
    ---Generic logger for elements that do not have a dedicated logger.
    ---@type TotoWarLogger
    genericLogger = nil,

    ---Indicates whether debug messages are logged.
    ---@type boolean
    isDebug = nil,

    ---Mods manager.
    ---@type TotoWarModsManager
    modsManager = nil,

    ---Utility tools for TotoWar mods.
    ---@type TotoWarUtils
    utils = nil,

    ---Utility tools for TotoWar mods.
    ---@type TotoWarUIUtils
    ui = nil
}
TotoWarCore.__index = TotoWarCore

---Instance.
---@type TotoWarCore
local _instance = nil

---Gets the TotoWarCore mod instance.
---Allows the use TotoWar mods.
---@return TotoWarCore
function TotoWar()
    return _instance
end

---Initializes a new instance.
---@return TotoWarCore
function TotoWarCore.new()
    _instance = setmetatable({}, TotoWarCore)

    _instance.genericLogger = TotoWarLogger.new("TotoWar_Generic", nil, true)
    _instance.isDebug = false
    _instance.modsManager = TotoWarModsManager.new()
    _instance.utils = TotoWarUtils.new()
    _instance.ui = TotoWarUIUtils.new()

    _instance.genericLogger:logDebug("TotoWarCore.new(): COMPLETED")

    return _instance
end
