---TotoWar base mod.
---@class TotoWarMod
TotoWarMod = {
    ---Generic logger for elements that do not have a dedicated logger.
    ---@type TotoWarLogger
    genericLogger = nil,

    ---Indicates whether debug messages are logged.
    ---@type boolean
    debugEnabled = TotoWar_OptionDefaultValue_DebugEnabled,

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
TotoWarMod.__index = TotoWarMod

---TotoWar base mod instance.
---@type TotoWarMod
TotoWar = nil

---Initializes a new instance.
---@return TotoWarMod
function TotoWarMod.new()
    TotoWar = setmetatable({}, TotoWarMod)

    TotoWar.genericLogger = TotoWarLogger.new("TotoWar_Generic", nil, true)

    TotoWar.modsManager = TotoWarModsManager.new()
    TotoWar.utils = TotoWarUtils.new()
    TotoWar.ui = TotoWarUIUtils.new()

    TotoWar:loadMctOptions()

    TotoWar:addListeners()

    TotoWar.genericLogger:logDebug("TotoWarCore.new(): COMPLETED")

    return TotoWar
end

---Adds event listeners.
function TotoWarMod:addListeners()
    -- Listener for option updates
    TotoWar.utils:addListener(
        "TotoWarCbac",
        TotoWar.utils.enums.events.mctOptionsUpdated,
        true,
        function()
            self:loadMctOptions()
        end)
end

---Loads option values stored by the Mod Configuration Tool if it is installed.
function TotoWarMod:loadMctOptions()
    local mct = self.utils:getMct()

    if not mct then
        return
    end

    self.genericLogger:logDebug("addMctOptions(): STARTED")

    local options = mct:get_mod_by_key(TotoWar_ModName)
    self.debugEnabled = options:get_option_by_key(TotoWar_OptionName_DebugEnabled):get_finalized_setting()

    self.genericLogger:logDebug("addMctOptions(): COMPLETED")
end
