---@diagnostic disable: missing-return

---Context for the ComponentLClickUp event.
---@class TotoWarEventContext_ComponentLeftClick
TotoWarEventContext_ComponentLeftClick = {
    ---Name of the clicked UI component.
    ---@type string
    string = nil,

    ---Clicked UI component address.
    ---@type UIC_Address
    component = nil
}

---Context for the PanelOpenedCampaign event.
---@class TotoWarEventContext_PanelOpenedOrClosed
TotoWarEventContext_PanelOpenedOrClosed = {
    ---Name of the panel.
    ---@type string
    string = nil
}

---Context for the RecruitmentItemIssuedByPlayer event.
---@class TotoWarEventContext_UnitAddedToRecruitment
TotoWarEventContext_UnitAddedToRecruitment = {
    ---Number of turns to recruit.
    ---@type number
    time_to_build = nil,
}
---Gets the faction.
---@return FACTION_SCRIPT_INTERFACE
function TotoWarEventContext_UnitAddedToRecruitment:faction() end

---Gets the unit key as a string.
---@return string
function TotoWarEventContext_UnitAddedToRecruitment:main_unit_record() end

---Context for the UnitDisbanded event.
---@class TotoWarEventContext_UnitDisbanded
TotoWarEventContext_UnitDisbanded = {}
---Gets the unit.
---@return UNIT_SCRIPT_INTERFACE
function TotoWarEventContext_UnitDisbanded:unit() end

---Context for the UnitDisbanded event.
---@class TotoWarEventContext_UnitMergedAndDestroyed
TotoWarEventContext_UnitMergedAndDestroyed = {}
---Gets the new unit the old unit was merged into.
---@return UNIT_SCRIPT_INTERFACE
function TotoWarEventContext_UnitMergedAndDestroyed:new_unit() end

---Gets the new unit resulting from the merge.
---@return UNIT_SCRIPT_INTERFACE
function TotoWarEventContext_UnitMergedAndDestroyed:unit() end

---Context for the RecruitmentItemCancelledByPlayer event.
---@class TotoWarEventContext_UnitRemovedFromRecruitment
TotoWarEventContext_UnitRemovedFromRecruitment = {}
---Gets the faction.
---@return FACTION_SCRIPT_INTERFACE
function TotoWarEventContext_UnitRemovedFromRecruitment:faction() end

---Gets the unit key as a string.
---@return string
function TotoWarEventContext_UnitRemovedFromRecruitment:main_unit_record() end
