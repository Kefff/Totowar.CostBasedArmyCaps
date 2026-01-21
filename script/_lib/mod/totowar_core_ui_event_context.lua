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
---@class TotoWarEventContext_PanelOpenedOrClosed
TotoWarEventContext_PanelOpenedOrClosed = {
    ---Name of the panel.
    ---@type string
    string = nil
}

---Context for the `unitAddedToRecruitment` event (`RecruitmentItemIssuedByPlayer`).
---@class TotoWarEventContext_UnitAddedToRecruitment
TotoWarEventContext_UnitAddedToRecruitment = {
    ---Function that return the faction as an object.
    ---@type function
    faction = nil,

    ---Function that returns the unit key as a string.
    ---@type function
    main_unit_record = nil,

    ---Number of turns to recruit.
    ---@type number
    time_to_build = nil,
}

---Context for the `unitRemovedFromRecruitment` event (`RecruitmentItemCancelledByPlayer`).
---@class TotoWarEventContext_UnitRemovedFromRecruitment
TotoWarEventContext_UnitAddedToRecruitment = {
    ---Faction.
    ---@type FACTION_SCRIPT_INTERFACE
    faction = nil,

    ---Information on the unit.
    ---@type ComponentContextObject
    main_unit_record = nil
}
