---Name of the TotoWar Cost-Based Army Caps mod.
---@type string
TotoWarCbacModName = "totowar_cost_based_army_caps"

---Manager in charge of calculating the army supplies cost for the player armies.
---@class TotoWarCbacPlayerManager
TotoWarCbacPlayerManager = {
    ---Events.
    ---@class TotoWarCbacPlayerManagerEventEnum
    event = {
        ---Event triggered when the army supplies cost of the selected army changes.
        selectedGeneralArmySuppliesCostChanged = "TotoWarCbac_SelectedGeneralArmySuppliesCostChanged",
    },

    ---Logger.
    ---@type TotoWarLogger
    logger = nil,

    ---Unique identifier of the selected general.
    ---@type number | nil
    selectedGeneralCqi = nil,

    ---Army supplies of the army of the selected general.
    ---@type TotoWarCbacArmySuppliesCost | nil
    selectedGeneralArmySuppliesCost = nil
}
TotoWarCbacPlayerManager.__index = TotoWarCbacPlayerManager

---Initializes a new instance.
---@return TotoWarCbacPlayerManager
function TotoWarCbacPlayerManager.new()
    local instance = setmetatable({}, TotoWarCbacPlayerManager)

    instance.logger = TotoWarLogger.new("TotoWar_Cbac_PlayerManager", nil, true)
    instance.logger:logDebug("new(): COMPLETED")

    return instance
end

---Adds listeners for events.
function TotoWarCbacPlayerManager:addListeners()
    self.logger:logDebug("addListeners(): STARTED")

    self.logger:logDebug(
        "addListeners() => Add listener to event \"%s\"",
        TotoWar().uiUtils.enums.event.unitAddedToRecruitment)
    core:add_listener(
        "totowar_cbac_unit_added_to_recruitment",
        TotoWar().uiUtils.enums.event.unitAddedToRecruitment,
        ---@param context TotoWarEventContext_UnitAddedToRecruitment
        function(context)
            return context:faction():name() == TotoWar().utils.playerFactionName
        end,
        ---@param context TotoWarEventContext_UnitAddedToRecruitment
        function(context)
            ---@type string
            local unitKey = context:main_unit_record()
            self:onUnitAddedToRecruitment(unitKey)
        end,
        true)

    self.logger:logDebug(
        "addListeners() => Add listener to event \"%s\"",
        TotoWar().uiUtils.enums.event.unitRemovedFromRecruitment)
    core:add_listener(
        "totowar_cbac_unit_removed_from_recruitment",
        TotoWar().uiUtils.enums.event.unitRemovedFromRecruitment,
        ---@param context TotoWarEventContext_UnitAddedToRecruitment
        function(context)
            return context:faction():name() == TotoWar().utils.playerFactionName
        end,
        ---@param context TotoWarEventContext_UnitAddedToRecruitment
        function(context)
            ---@type string
            local unitKey = context:main_unit_record()
            self:onUnitRemovedFromRecruitment(unitKey)
        end,
        true)

    self.logger:logDebug(
        "addListeners() => Add listener to event \"%s\"",
        TotoWar().uiUtils.enums.event.characterDeselected)
    core:add_listener(
        "totowar_cbac_character_deselected",
        TotoWar().uiUtils.enums.event.characterDeselected,
        true,
        function()
            self:onCharacterDeselected()
        end,
        true)

    self.logger:logDebug(
        "addListeners() => Add listener to event \"%s\"",
        TotoWar().uiUtils.enums.event.characterSelected)
    core:add_listener(
        "totowar_cbac_character_selected",
        TotoWar().uiUtils.enums.event.characterSelected,
        true,
        ---@param context CharacterSelected
        function(context)
            self:onCharacterSelected(context:character())
        end,
        true)

    self.logger:logDebug("addListeners(): COMPLETED")
end

---Initializes the army supplies cost of the army of the selected general.
---@param general CHARACTER_SCRIPT_INTERFACE Selected general.
function TotoWarCbacPlayerManager:initializeArmySuppliesCost(general)
    self.logger:logDebug("initializeArmySuppliesCost(%s): STARTED", general:cqi())

    self.selectedGeneralArmySuppliesCost = TotoWarCbacArmySuppliesCost.new()

    -- Adding units from the general army
    local units = general:military_force():unit_list()

    for i = 0, units:num_items() - 1, 1 do
        local unit = units:item_at(i)
        self.selectedGeneralArmySuppliesCost:addUnit(unit:unit_key())
    end

    -- Adding units being recruited in the general army
    local unitsUIComponent = TotoWar().uiUtils:findUIComponent(TotoWar().uiUtils.uiComponentQuery.units)

    if not unitsUIComponent then
        return
    end

    self:initializeUnitsInRecruitmentArmySuppliesCost(unitsUIComponent)

    -- Updating the selected general ability to move
    self:updatedSelectedGeneralMovement()

    self.logger:logDebug(
        "initializeArmySuppliesCost(%s): COMPLETED => %s",
        general:cqi(),
        self.selectedGeneralArmySuppliesCost.totalCost)
end

---Initializes the army supplies cost of the units being recruited in the army of the selected general.
---@param unitsUIComponent UIC Units list UI component.
function TotoWarCbacPlayerManager:initializeUnitsInRecruitmentArmySuppliesCost(unitsUIComponent)
    for i = unitsUIComponent:ChildCount() - 1, 0, -1 do
        -- Iterating from the last unit card since units being recruited are at the end
        local unitCardUIComponent = find_child_uicomponent_by_index(unitsUIComponent, i)

        if not self:isRecruitmentUnitCardUIComponent(unitCardUIComponent:Id()) then
            -- Stopping the iteration as soon as we encounter a unit that is not being recruited
            break
        end

        local cardImageHolderUIComponent = TotoWar().uiUtils:getUIComponentChild(
            unitCardUIComponent,
            { "card_image_holder" })
        local unitContext = TotoWar().uiUtils:getUIComponentCCO(
            cardImageHolderUIComponent,
            TotoWar().uiUtils.enums.ccoContextTypeId.ccoMainUnitRecord)

        ---@type string
        local unitKey = unitContext:Call("Key")
        self.selectedGeneralArmySuppliesCost:addUnit(unitKey)
    end
end

---Indicates whether a UI component corresponds to the unit card of a unit being recruited.
---@param uiComponentName string UI component name.
---@return boolean
function TotoWarCbacPlayerManager:isRecruitmentUnitCardUIComponent(uiComponentName)
    local result =
        string.find(uiComponentName, "QueuedLandUnit") ~= nil
        or string.find(uiComponentName, "temp_merc") ~= nil

    return result
end

---Reacts to a character being deselected.
function TotoWarCbacPlayerManager:onCharacterDeselected()
    if not self.selectedGeneralCqi then
        return
    end

    self.logger:logDebug("[EVENT] onCharacterDeselected(): STARTED")

    self.selectedGeneralCqi = nil
    self.selectedGeneralArmySuppliesCost = nil
    -- self.isAlliedRecruitmentResized = false
    -- self.isGlobalRecruitmentResized = false
    -- self.isLocalRecruitmentResized = false

    self.logger:logDebug("[EVENT] onCharacterDeselected(): COMPLETED")
end

---Reacts to a character being selected.
---@param character CHARACTER_SCRIPT_INTERFACE Selected character.
function TotoWarCbacPlayerManager:onCharacterSelected(character)
    self.logger:logDebug("[EVENT] onCharacterSelected(%s): STARTED", character:cqi())

    local canRecruit =
        TotoWar().utils:isPlayerFactionGeneral(character)
        and TotoWar().utils:canRecruitUnits(character:military_force())

    if canRecruit then
        if
            not self.selectedGeneralArmySuppliesCost
            or character:cqi() ~= self.selectedGeneralCqi
        then
            self.selectedGeneralCqi = character:cqi()

            if cm:get_campaign_ui_manager():is_panel_open(TotoWar().uiUtils.panels.unitsPanel.name) then
                --- Initializing the army supplies cost for the newly selected army
                self:initializeArmySuppliesCost(character)
            else
                --- Adding a one-time listener that waits for the unit_panel to open before
                --- initializing the army supplies cost because we need to get the cost of the
                --- units being recruited
                self.logger:logDebug(
                    "onCharacterSelected(%s) => Add one-time listener to event \"%s\"",
                    character:cqi(),
                    TotoWar().uiUtils.enums.event.panelOpened)
                core:add_listener(
                    "totowar_cbac_units_panel_opened",
                    TotoWar().uiUtils.enums.event.panelOpened,
                    ---@param context TotoWarEventContext_PanelOpenedOrClosed
                    function(context)
                        return context.string == TotoWar().uiUtils.panels.unitsPanel.name
                    end,
                    function()
                        self:initializeArmySuppliesCost(character)
                    end,
                    false)
            end
        end
    elseif self.selectedGeneralArmySuppliesCost then
        self:onCharacterDeselected()
    end

    self.logger:logDebug("[EVENT] onCharacterSelected(%s): COMPLETED", character:cqi())
end

---Reacts to a unit being added to the recruitment queue of the selected general army.
function TotoWarCbacPlayerManager:onUnitAddedToRecruitment(unitKey)
    self.logger:logDebug("[EVENT] onUnitAddedToRecruitment(%s): STARTED", unitKey)

    self.selectedGeneralArmySuppliesCost:addUnit(unitKey)

    self.logger:logDebug("[EVENT] onUnitAddedToRecruitment(%s): COMPLETED", unitKey)
end

---Reacts to a unit being removed from the recruitment queue of the selected general army.
function TotoWarCbacPlayerManager:onUnitRemovedFromRecruitment(unitKey)
    self.logger:logDebug("[EVENT] onUnitRemovedFromRecruitment(%s): STARTED", unitKey)

    self.selectedGeneralArmySuppliesCost:removeUnit(unitKey)

    self.logger:logDebug("[EVENT] onUnitRemovedFromRecruitment(%s): COMPLETED", unitKey)
end

---Updates the ability to move of the selected general depending on the army supplies cost of its army.
function TotoWarCbacPlayerManager:updatedSelectedGeneralMovement()
    self.logger:logDebug("updatedSelectedGeneralMovement(): STARTED")

    if self.selectedGeneralArmySuppliesCost.totalCost > TotoWar_Cbac().armyTotalArmySupplies then
        self.logger:logDebug("updatedSelectedGeneralMovement(): ARMY BLOCKED")

        cm:disable_movement_for_character("character_cqi:" .. self.selectedGeneralCqi)
    else
        cm:enable_movement_for_character("character_cqi:" .. self.selectedGeneralCqi)
    end

    self.logger:logDebug("updatedSelectedGeneralMovement(): COMPLETED")
end
