---UI of a recruitment pool in a recruitment panel.
---@class TotoWarCbacRecruitmentPoolUI
TotoWarCbacRecruitmentPoolUI = {
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
TotoWarCbacRecruitmentPoolUI.__index = TotoWarCbacRecruitmentPoolUI

---Initializes a new instance of TotoWarCbacRecruitmentPoolUI.
---@param name string Name.
---@param panelName string Name of the panel in which the recruitment pool is displayed.
---@param uiComponentQuery string[] Query for finding the corresponding  UI component.
---@param updateUIFunction fun() Function to call to updated the recruitment pool UI.
---@return TotoWarCbacRecruitmentPoolUI
function TotoWarCbacRecruitmentPoolUI.new(name, panelName, uiComponentQuery, updateUIFunction)
    local instance = setmetatable({}, TotoWarCbacRecruitmentPoolUI)

    instance.isResized = false
    instance.name = name
    instance.panelName = panelName
    instance.uiComponentQuery = uiComponentQuery
    instance.updateUIFunction = updateUIFunction

    TotoWar.genericLogger:logDebug("TotoWarCbacRecruitmentPoolUI.new(): COMPLETED")

    return instance
end
