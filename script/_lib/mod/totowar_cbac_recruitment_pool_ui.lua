---UI of a recruitment pool in a recruitment panel.
---@class TotoWar_Cbac_RecruitmentPoolUI
TotoWar_Cbac_RecruitmentPoolUI = {
    ---Indicates whether the recruitment pool UI component has been resized to be able to display army supplies cost under each unit price.
    isResized = false,

    ---Name.
    ---@type string
    name = nil,

    ---Name of the panel in which the recruitment pool is displayed.
    ---@type string
    panelName = nil,

    ---Query for finding the corresponding  UI component.
    ---@type string[]
    uiComponentQuery = nil,

    ---Function to call to updated the recruitment pool UI.
    ---@type fun()
    updateUIFunction = nil,

    ---Update mode defining when the recruitment pool must be updated.
    ---@type string
    updateMode = nil
}
TotoWar_Cbac_RecruitmentPoolUI.__index = TotoWar_Cbac_RecruitmentPoolUI

---Initializes a new instance of TotoWar_Cbac_RecruitmentPoolUI.
---@param name string Name.
---@param panelName string Name of the panel in which the recruitment pool is displayed.
---@param uiComponentQuery string[] Query for finding the corresponding  UI component.
---@param updateUIFunction fun() Function to call to updated the recruitment pool UI.
---@return TotoWar_Cbac_RecruitmentPoolUI
function TotoWar_Cbac_RecruitmentPoolUI.new(name, panelName, uiComponentQuery, updateUIFunction)
    TotoWar_Cbac.loggers.generic:logDebug("TotoWar_Cbac_RecruitmentPoolUI.new(): STARTED")

    local instance = setmetatable({}, TotoWar_Cbac_RecruitmentPoolUI)

    instance.isResized = false
    instance.name = name
    instance.panelName = panelName
    instance.uiComponentQuery = uiComponentQuery
    instance.updateUIFunction = updateUIFunction

    TotoWar_Cbac.loggers.generic:logDebug("TotoWar_Cbac_RecruitmentPoolUI.new(): COMPLETED")

    return instance
end
