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
        TotoWar().ui.enums.event.characterDeselected)
    core:add_listener(
        "TotoWarCbacPlayerManager_" .. TotoWar().ui.enums.event.characterDeselected,
        TotoWar().ui.enums.event.characterDeselected,
        true,
        function()
            self:onCharacterDeselected()
        end,
        true)

    self.logger:logDebug(
        "addListeners() => Add listener to event \"%s\"",
        TotoWar().ui.enums.event.characterSelected)
    core:add_listener(
        "TotoWarCbacPlayerManager_" .. TotoWar().ui.enums.event.characterSelected,
        TotoWar().ui.enums.event.characterSelected,
        true,
        ---@param context CharacterSelected
        function(context)
            self:onCharacterSelected(context:character())
        end,
        true)

    self.logger:logDebug(
        "addListeners() => Add listener to event \"%s\"",
        TotoWar().ui.enums.event.componentLeftClick)
    core:add_listener(
        "TotoWarCbacPlayerManager_RecruitableMercenaryUnitCard_" .. TotoWar().ui.enums.event.componentLeftClick,
        TotoWar().ui.enums.event.componentLeftClick,
        ---@param context TotoWarEventContext_ComponentLeftClick
        function(context)
            return context.string:match(TotoWar().ui.enums.patterns.recruitableMercenaryUnitCard)
        end,
        ---@param context TotoWarEventContext_ComponentLeftClick
        function(context)
            local uiComponent = UIComponent(context.component)
            self:onRecruitableMercenaryUniCardClick(context.string, uiComponent)
        end,
        true)

    self.logger:logDebug(
        "addListeners() => Add listener to event \"%s\"",
        TotoWar().ui.enums.event.componentLeftClick)
    core:add_listener(
        "TotoWarCbacPlayerManager_InRecruitmentMercenaryUnitCard_" .. TotoWar().ui.enums.event.componentLeftClick,
        TotoWar().ui.enums.event.componentLeftClick,
        ---@param context TotoWarEventContext_ComponentLeftClick
        function(context)
            return context.string:match(TotoWar().ui.enums.patterns.inRecruitmentMercenaryUnitCard)
        end,
        ---@param context TotoWarEventContext_ComponentLeftClick
        function(context)
            local uiComponent = UIComponent(context.component)
            self:onInRecruitmentMercenaryUniCardClick(context.string, uiComponent)
        end,
        true)

    self.logger:logDebug(
        "addListeners() => Add listener to event \"%s\"",
        TotoWar().ui.enums.event.unitAddedToRecruitment)
    core:add_listener(
        "TotoWarCbacPlayerManager_" .. TotoWar().ui.enums.event.unitAddedToRecruitment,
        TotoWar().ui.enums.event.unitAddedToRecruitment,
        ---@param context TotoWarEventContext_UnitAddedToRecruitment
        function(context)
            return context:faction():name() == TotoWar().utils.playerFactionName
        end,
        ---@param context TotoWarEventContext_UnitAddedToRecruitment
        function(context)
            ---@type string
            local unitKey = context:main_unit_record()
            self:onUnitAddedToRecruitment(unitKey, false)
        end,
        true)

    self.logger:logDebug(
        "addListeners() => Add listener to event \"%s\"",
        TotoWar().ui.enums.event.unitDisbanded)
    core:add_listener(
        "TotoWarCbacPlayerManager_" .. TotoWar().ui.enums.event.unitDisbanded,
        TotoWar().ui.enums.event.unitDisbanded,
        true,
        ---@param context TotoWarEventContext_UnitDisbanded
        function(context)
            self:onUnitDisbanded(context:unit():unit_key())
        end,
        true)

    self.logger:logDebug(
        "addListeners() => Add listener to event \"%s\"",
        TotoWar().ui.enums.event.unitMergedAndDestroyed)
    core:add_listener(
        "TotoWarCbacPlayerManager_" .. TotoWar().ui.enums.event.unitMergedAndDestroyed,
        TotoWar().ui.enums.event.unitMergedAndDestroyed,
        true,
        ---@param context TotoWarEventContext_UnitMergedAndDestroyed
        function(context)
            self:onUnitMergedAndDestroyed(context:unit():unit_key())
        end,
        true)

    self.logger:logDebug(
        "addListeners() => Add listener to event \"%s\"",
        TotoWar().ui.enums.event.unitRemovedFromRecruitment)
    core:add_listener(
        "TotoWarCbacPlayerManager_" .. TotoWar().ui.enums.event.unitRemovedFromRecruitment,
        TotoWar().ui.enums.event.unitRemovedFromRecruitment,
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
        self.selectedGeneralArmySuppliesCost:addUnit(unit:unit_key(), false)
    end

    -- Adding units being recruited in the general army
    local unitsUIComponent = TotoWar().ui:getUIComponent(TotoWar().ui.uiComponentQueries.units)

    -- Adding units from the recruitment queue
    for i = unitsUIComponent:ChildCount() - 1, 0, -1 do
        -- Iterating from the last unit card since units being recruited are at the end
        local unitCardUIComponent = find_child_uicomponent_by_index(unitsUIComponent, i)

        if not unitCardUIComponent:Id():match(TotoWar().ui.enums.patterns.inRecruitmentStandardUnitCard)
        then
            -- Stopping the iteration as soon as we encounter a unit that is not being recruited
            break
        end

        local cardImageHolderUIComponent = TotoWar().ui:getUIComponentChild(
            unitCardUIComponent,
            { "card_image_holder" })
        local unitContext = TotoWar().ui:getUIComponentCCO(
            cardImageHolderUIComponent,
            TotoWar().ui.enums.ccoContextTypeId.ccoMainUnitRecord)

        ---@type string
        local unitKey = unitContext:Call("Key")
        self.selectedGeneralArmySuppliesCost:addUnit(unitKey, false)
    end

    -- Updating the selected general ability to move depending on the total army supplies cost
    self:updatedSelectedGeneralMovement()

    -- Signaling army supplies cost change
    core:trigger_event(self.event.selectedGeneralArmySuppliesCostChanged)

    self.logger:logDebug(
        "initializeArmySuppliesCost(%s): COMPLETED => %s",
        general:cqi(),
        self.selectedGeneralArmySuppliesCost.totalCost)
end

---Reacts to a character being deselected.
function TotoWarCbacPlayerManager:onCharacterDeselected()
    if not self.selectedGeneralCqi then
        return
    end

    self.logger:logDebug("[EVENT] onCharacterDeselected(): STARTED")

    self.selectedGeneralCqi = nil
    self.selectedGeneralArmySuppliesCost = nil

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

            if cm:get_campaign_ui_manager():is_panel_open(TotoWar().ui.enums.panel.unitsPanel) then
                --- Initializing the army supplies cost for the newly selected army
                self:initializeArmySuppliesCost(character)
            else
                --- Adding a one-time listener that waits for the unit_panel to open before
                --- initializing the army supplies cost because we need to get the cost of the
                --- units being recruited
                self.logger:logDebug(
                    "onCharacterSelected(%s) => Add one-time listener to event \"%s\"",
                    character:cqi(),
                    TotoWar().ui.enums.event.panelOpened)
                core:add_listener(
                    "TotoWarCbacPlayerManager_OneTime_" .. TotoWar().ui.enums.event.panelOpened,
                    TotoWar().ui.enums.event.panelOpened,
                    ---@param context TotoWarEventContext_PanelOpenedOrClosed
                    function(context)
                        return context.string == TotoWar().ui.enums.panel.unitsPanel
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

---Reacts to the click on the unit card of a mercenary unit in the selected army recruitment queue.
---@param uiComponentName string Name of the clicked UI component.
---@param unitComponent UIC Clicked UI component.
function TotoWarCbacPlayerManager:onInRecruitmentMercenaryUniCardClick(uiComponentName, unitComponent)
    self.logger:logDebug("[EVENT] onInRecruitmentMercenaryUniCardClick(%s): STARTED", uiComponentName)

    -- In recruitment mercenary units are stored in a separate table and use the number at the end of the
    -- UI component ("temp_merc_0", "temp_merc_1", ...) to find the index of the corresponding unit
    -- in this table.
    local unitKey = self.selectedGeneralArmySuppliesCost:removeUnit(uiComponentName)

    -- Signaling army supplies cost change
    core:trigger_event(self.event.selectedGeneralArmySuppliesCostChanged)

    self.logger:logDebug("[EVENT] onInRecruitmentMercenaryUniCardClick(%s): COMPLETED", uiComponentName)
end

---Reacts to the click on the unit card of a recruitable mercenary unit.
---@param uiComponentName string Name of the clicked UI component.
---@param unitUIComponent UIC Clicked UI component.
function TotoWarCbacPlayerManager:onRecruitableMercenaryUniCardClick(uiComponentName, unitUIComponent)
    self.logger:logDebug("[EVENT] onRecruitableMercenaryUniCardClick(%s): STARTED", uiComponentName)

    -- Workaround for the fact that we cannot know whether a unit card was `inactive` before the click
    -- on it or became `inactive` after clicking on it be before the click event was triggered.
    -- This problem prevents us from simply checking the state of the component so we need to check
    -- whether the number of in recruitment mercenary units in the unit list is different from the number
    -- of in recruitment mercenary units we already have added to the army supplies cost.
    -- If there are more in recruitment mercenary units in the unit list, we consider that the unit card
    -- was not `inactive` at the time of the click and we add its army supplies cost.
    -- so we can add the unit army supplies cost.
    local inRecruitmentMercenaryUnitCount = 0
    local unitsUIComponent = TotoWar().ui:getUIComponent(TotoWar().ui.uiComponentQueries.units)

    for i = unitsUIComponent:ChildCount() - 1, 0, -1 do
        -- Iterating from the last unit card since units being recruited are at the end
        local unitCardUIComponent = find_child_uicomponent_by_index(unitsUIComponent, i)

        if not unitCardUIComponent:Id():match(TotoWar().ui.enums.patterns.inRecruitmentMercenaryUnitCard)
        then
            -- Stopping the iteration as soon as we encounter a unit that is not a mercenary unit being recruited
            break
        end

        inRecruitmentMercenaryUnitCount = inRecruitmentMercenaryUnitCount + 1
    end

    self.logger:logDebug(
        "[EVENT] onRecruitableMercenaryUniCardClick(%s): %s mercenary units in the recruitment pool | %s mercenary units tracked in the army supplies cost",
        uiComponentName,
        inRecruitmentMercenaryUnitCount,
        #self.selectedGeneralArmySuppliesCost.inRecruitmentMercenaryUnits)

    if inRecruitmentMercenaryUnitCount > #self.selectedGeneralArmySuppliesCost.inRecruitmentMercenaryUnits then
        local unitContext = TotoWar().ui:getUIComponentCCO(
            unitUIComponent,
            TotoWar().ui.enums.ccoContextTypeId.ccoMainUnitRecord)

        ---@type string
        local unitKey = unitContext:Call("Key")
        self:onUnitAddedToRecruitment(unitKey, true)
    end

    self.logger:logDebug("[EVENT] onRecruitableMercenaryUniCardClick(%s): COMPLETED", uiComponentName)
end

---Reacts to a unit being added to the recruitment queue of the selected general army.
---@param unitKey string Unit key.
---@param isMercenary boolean Indicates whether the unit added to recruitment is a mercenary unit (regiment of renown, Grudge settles, Waaagh mobs, ...).
function TotoWarCbacPlayerManager:onUnitAddedToRecruitment(unitKey, isMercenary)
    self.logger:logDebug("[EVENT] onUnitAddedToRecruitment(%s): STARTED", unitKey)

    self.selectedGeneralArmySuppliesCost:addUnit(unitKey, isMercenary)

    -- Signaling army supplies cost change
    core:trigger_event(self.event.selectedGeneralArmySuppliesCostChanged)

    self.logger:logDebug("[EVENT] onUnitAddedToRecruitment(%s): COMPLETED", unitKey)
end

---Reacts to a unit being disbanded.
---@param unitKey string Unit key
function TotoWarCbacPlayerManager:onUnitDisbanded(unitKey)
    self.logger:logDebug("[EVENT] onUnitDisbanded(%s): STARTED", unitKey)

    self.selectedGeneralArmySuppliesCost:removeUnit(unitKey)

    -- Signaling army supplies cost change
    core:trigger_event(self.event.selectedGeneralArmySuppliesCostChanged)

    self.logger:logDebug("[EVENT] onUnitDisbanded(%s): COMPLETED", unitKey)
end

---Reacts to a unit being destroyed after having been merged with another unit.
---@param unitKey string Unit key.
function TotoWarCbacPlayerManager:onUnitMergedAndDestroyed(unitKey)
    self.logger:logDebug("[EVENT] onUnitMergedAndDestroyed(%s): STARTED", unitKey)

    self.selectedGeneralArmySuppliesCost:removeUnit(unitKey)

    -- Signaling army supplies cost change
    core:trigger_event(self.event.selectedGeneralArmySuppliesCostChanged)

    self.logger:logDebug("[EVENT] onUnitMergedAndDestroyed(%s): COMPLETED", unitKey)
end

---Reacts to a unit being removed from the recruitment queue of the selected general army.
function TotoWarCbacPlayerManager:onUnitRemovedFromRecruitment(unitKey)
    self.logger:logDebug("[EVENT] onUnitRemovedFromRecruitment(%s): STARTED", unitKey)

    self.selectedGeneralArmySuppliesCost:removeUnit(unitKey)

    -- Signaling army supplies cost change
    core:trigger_event(self.event.selectedGeneralArmySuppliesCostChanged)

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
