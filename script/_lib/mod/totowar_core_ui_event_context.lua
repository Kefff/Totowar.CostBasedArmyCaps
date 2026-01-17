---Context for the `componentLeftClick` event (`ComponentLClickUp`).
---@class TotoWarUIEventContext_ComponentClick
TotoWarEventContext_ComponentLeftClick = {
    ---Name of the clicked UI component.
    ---@type string
    string = nil,

    ---Clicked UI component.
    ---@type UIC
    component = nil
}

---Context for the `panelOpenedOrRefreshed` event (`PanelOpenedCampaign`).
---@class TotoWarEventContext_PanelOpenedOrRefreshed
TotoWarEventContext_PanelOpenedOrRefreshed = {
    ---Name of the panel.
    ---@type string
    string = nil
}
