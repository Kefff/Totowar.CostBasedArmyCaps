---@diagnostic disable: missing-return

---Context for the ComponentLClickUp event.
---@class TotoWarGameEventContext_ComponentLeftClick
TotoWarGameEventContext_ComponentLeftClick = {
    ---Name of the clicked UI component.
    ---@type string
    string = nil,

    ---Clicked UI component address.
    ---@type UIC_Address
    component = nil
}

---Context for the FactionTurnStart event.
---@class TotoWarGameEventContext_FactionTurnStart
TotoWarGameEventContext_FactionTurnStart = {}

---Gets the faction.
---@return FACTION_SCRIPT_INTERFACE
function TotoWarGameEventContext_FactionTurnStart:faction() end

---Context for the PanelOpenedCampaign event.
---@class TotoWarGameEventContext_PanelOpenedOrClosed
TotoWarGameEventContext_PanelOpenedOrClosed = {
    ---Name of the panel.
    ---@type string
    string = nil
}

---Context for the RecruitmentItemIssuedByPlayer event.
---@class TotoWarGameEventContext_UnitAddedToRecruitment
TotoWarGameEventContext_UnitAddedToRecruitment = {
    ---Number of turns to recruit.
    ---@type integer
    time_to_build = nil,
}
---Gets the faction.
---@return FACTION_SCRIPT_INTERFACE
function TotoWarGameEventContext_UnitAddedToRecruitment:faction() end

---Gets the unit key as a string.
---@return string
function TotoWarGameEventContext_UnitAddedToRecruitment:main_unit_record() end

---Context for the UnitDisbanded event.
---@class TotoWarGameEventContext_UnitDisbanded
TotoWarGameEventContext_UnitDisbanded = {}
---Gets the unit.
---@return UNIT_SCRIPT_INTERFACE
function TotoWarGameEventContext_UnitDisbanded:unit() end

---Context for the UnitDisbanded event.
---@class TotoWarGameEventContext_UnitMergedAndDestroyed
TotoWarGameEventContext_UnitMergedAndDestroyed = {}
---Gets the new unit the old unit was merged into.
---@return UNIT_SCRIPT_INTERFACE
function TotoWarGameEventContext_UnitMergedAndDestroyed:new_unit() end

---Gets the new unit resulting from the merge.
---@return UNIT_SCRIPT_INTERFACE
function TotoWarGameEventContext_UnitMergedAndDestroyed:unit() end

---Context for the RecruitmentItemCancelledByPlayer event.
---@class TotoWarGameEventContext_UnitRemovedFromRecruitment
TotoWarGameEventContext_UnitRemovedFromRecruitment = {}
---Gets the faction.
---@return FACTION_SCRIPT_INTERFACE
function TotoWarGameEventContext_UnitRemovedFromRecruitment:faction() end

---Gets the unit key as a string.
---@return string
function TotoWarGameEventContext_UnitRemovedFromRecruitment:main_unit_record() end

---Context for the UnitTrained event.
---@class TotoWarGameEventContext_UnitTrained
TotoWarGameEventContext_UnitTrained = {}
---Gets the unit.
---@return UNIT_SCRIPT_INTERFACE
function TotoWarGameEventContext_UnitTrained:unit() end
