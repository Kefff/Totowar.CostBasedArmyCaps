---@diagnostic disable: missing-return

---Context for the ForceAdoptsStance event.
---@class TotoWar__GameEventContext_ArmyStanceChanged
TotoWar__GameEventContext_ArmyStanceChanged = {}
---Gets the army.
---@return MILITARY_FORCE_SCRIPT_INTERFACE
function TotoWar__GameEventContext_ArmyStanceChanged:military_force() end

---Gets a number representing the stance.
---@return integer
function TotoWar__GameEventContext_ArmyStanceChanged:stance_adopted() end

---Context for the ComponentLClickUp event.
---@class TotoWar__GameEventContext_ComponentLeftClick
TotoWar__GameEventContext_ComponentLeftClick = {
    ---Name of the clicked UI component.
    ---@type string
    string = nil,

    ---Clicked UI component address.
    ---@type UIC_Address
    component = nil
}

---Context for the FactionTurnStart event.
---@class TotoWar__GameEventContext_FactionTurnStart
TotoWar__GameEventContext_FactionTurnStart = {}
---Gets the faction.
---@return FACTION_SCRIPT_INTERFACE
function TotoWar__GameEventContext_FactionTurnStart:faction() end

---Context for the MilitaryForceCreated event.
---@class TotoWar__GameEventContext_MilitaryForceCreated
TotoWar__GameEventContext_MilitaryForceCreated = {}
---Gets the army.
---@return MILITARY_FORCE_SCRIPT_INTERFACE
function TotoWar__GameEventContext_MilitaryForceCreated:military_force_created() end

---Context for the PanelOpenedCampaign event.
---@class TotoWar__GameEventContext_PanelOpenedOrClosed
TotoWar__GameEventContext_PanelOpenedOrClosed = {
    ---Name of the panel.
    ---@type string
    string = nil
}

---Context for the RecruitmentItemIssuedByPlayer event.
---@class TotoWar__GameEventContext_UnitAddedToRecruitment
TotoWar__GameEventContext_UnitAddedToRecruitment = {
    ---Number of turns to recruit.
    ---@type integer
    time_to_build = nil,
}
---Gets the faction.
---@return FACTION_SCRIPT_INTERFACE
function TotoWar__GameEventContext_UnitAddedToRecruitment:faction() end

---Gets the unit key as a string.
---@return string
function TotoWar__GameEventContext_UnitAddedToRecruitment:main_unit_record() end

---Context for the UnitConverted event.
---@class TotoWar__GameEventContext_UnitConverted
TotoWar__GameEventContext_UnitConverted = {}
---Gets the new unit the old unit was converted into.
---@return UNIT_SCRIPT_INTERFACE
function TotoWar__GameEventContext_UnitConverted:converted_unit() end

---Gets the old unit.
---@return UNIT_SCRIPT_INTERFACE
function TotoWar__GameEventContext_UnitConverted:unit() end

---Context for the UnitCreated event.
---@class TotoWar__GameEventContext_UnitCreated
TotoWar__GameEventContext_UnitCreated = {}
---Gets the unit.
---@return UNIT_SCRIPT_INTERFACE
function TotoWar__GameEventContext_UnitCreated:unit() end

---Context for the UnitDisbanded event.
---@class TotoWar__GameEventContext_UnitDisbanded
TotoWar__GameEventContext_UnitDisbanded = {}
---Gets the unit.
---@return UNIT_SCRIPT_INTERFACE
function TotoWar__GameEventContext_UnitDisbanded:unit() end

---Context for the UnitDisbanded event.
---@class TotoWar__GameEventContext_UnitMergedAndDestroyed
TotoWar__GameEventContext_UnitMergedAndDestroyed = {}
---Gets the new unit the old unit was merged into.
---@return UNIT_SCRIPT_INTERFACE
function TotoWar__GameEventContext_UnitMergedAndDestroyed:new_unit() end

---Gets the new unit resulting from the merge.
---@return UNIT_SCRIPT_INTERFACE
function TotoWar__GameEventContext_UnitMergedAndDestroyed:unit() end

---Context for the RecruitmentItemCancelledByPlayer event.
---@class TotoWar__GameEventContext_UnitRemovedFromRecruitment
TotoWar__GameEventContext_UnitRemovedFromRecruitment = {}
---Gets the faction.
---@return FACTION_SCRIPT_INTERFACE
function TotoWar__GameEventContext_UnitRemovedFromRecruitment:faction() end

---Gets the unit key as a string.
---@return string
function TotoWar__GameEventContext_UnitRemovedFromRecruitment:main_unit_record() end

---Context for the UnitTrained event.
---@class TotoWar__GameEventContext_UnitTrained
TotoWar__GameEventContext_UnitTrained = {}
---Gets the unit.
---@return UNIT_SCRIPT_INTERFACE
function TotoWar__GameEventContext_UnitTrained:unit() end

---Context for the UnitUpgraded event.
---@class TotoWar__GameEventContext_UnitUpgraded
TotoWar__GameEventContext_UnitUpgraded = {}
---Gets the unit.
---@return UNIT_SCRIPT_INTERFACE
function TotoWar__GameEventContext_UnitUpgraded:unit() end
