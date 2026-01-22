---Context for the `ComponentLClickUp`.
---@class TotoWarEventContext_ComponentLeftClick
TotoWarEventContext_ComponentLeftClick = {
    ---Name of the clicked UI component.
    ---@type string
    string = nil,

    ---Clicked UI component address.
    ---@type UIC_Address
    component = nil
}

---Context for the `PanelOpenedCampaign`.
---@class TotoWarEventContext_PanelOpenedOrClosed
TotoWarEventContext_PanelOpenedOrClosed = {
    ---Name of the panel.
    ---@type string
    string = nil
}

---Context for the `RecruitmentItemIssuedByPlayer`.
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

---Context for the RecruitmentItemCancelledByPlayer.
---@class TotoWarEventContext_UnitRemovedFromRecruitment
TotoWarEventContext_UnitRemovedFromRecruitment = {
    ---Faction.
    ---@type FACTION_SCRIPT_INTERFACE
    faction = nil,

    ---Information on the unit.
    ---@type ComponentContextObject
    main_unit_record = nil
}
