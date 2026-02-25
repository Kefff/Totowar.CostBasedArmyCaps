---Manager in charge of calculating the army supplies cost for the player armies.
---@class TotoWarCbacPlayerManager
TotoWarCbacPlayerManager = {
    ---Enums
    ---@class TotoWarCbacPlayerManager_Enums
    enums = {
        ---Events.
        ---@class TotoWarCbacPlayerManager_Enums_Event
        events = {
            ---Event triggered when the army supplies cost of the selected army changes.
            selectedGeneralArmySuppliesCostChanged = "TotoWarCbac_SelectedGeneralArmySuppliesCostChanged",

            ---Event triggered when the army supplies cost of army exchanging units changes.
            unitExchangeArmySuppliesCostChanged = "TotoWarCbac_UnitExchangeArmySuppliesCostChanged",
        }
    },

    ---Indicates whether the army supplies cost is being initialized.
    ---When it is the case, methods that update UI elements (such as when a panel is opened)
    ---should not execute because the UI will be updated when the
    ---TotoWarCbac_SelectedGeneralArmySuppliesCostChanged event is triggered at the end ot the
    ---supplies cost initialization.
    isInitializingArmySuppliesCost = false,

    ---Logger.
    ---@type TotoWarLogger
    logger = nil,

    ---Unique identifier of the selected general.
    ---@type number | nil
    selectedGeneralCqi = nil,

    ---Army supplies cost of the army of the selected general.
    ---@type TotoWarCbacArmySuppliesCost | nil
    selectedGeneralArmySuppliesCost = nil,

    ---Army supplies cost of the first army during unit exchange.
    ---@type TotoWarCbacArmySuppliesCost | nil
    unitExchangeArmySuppliesCost1 = nil,

    ---Army supplies cost of the second army during unit exchange.
    ---@type TotoWarCbacArmySuppliesCost | nil
    unitExchangeArmySuppliesCost2 = nil
}
TotoWarCbacPlayerManager.__index = TotoWarCbacPlayerManager

---Initializes a new instance.
---@return TotoWarCbacPlayerManager
function TotoWarCbacPlayerManager.new()
    local instance = setmetatable({}, TotoWarCbacPlayerManager)

    instance.logger = TotoWarLogger.new("TotoWar_Cbac_PlayerManager")
    instance.selectedGeneralCqi = nil
    instance.selectedGeneralArmySuppliesCost = nil

    instance.logger:logDebug("new(): COMPLETED")

    return instance
end

---Adds listeners for events.
function TotoWarCbacPlayerManager:addListeners()
    self.logger:logDebug("addListeners(): STARTED")

    TotoWar().utils:addListener(
        "TotoWarCbacPlayerManager",
        TotoWar().ui.enums.events.characterDeselected,
        function()
            return cm:is_local_players_turn()
        end,
        function()
            self:onCharacterDeselected()
        end)

    TotoWar().utils:addListener(
        "TotoWarCbacPlayerManager",
        TotoWar().ui.enums.events.characterSelected,
        function()
            return cm:is_local_players_turn()
        end,
        ---@param context CharacterSelected
        function(context)
            self:onCharacterSelected(context:character())
        end)

    TotoWar().utils:addListener(
        "TotoWarCbacPlayerManager_InRecruitmentMercenaryUnitCard",
        TotoWar().ui.enums.events.componentLeftClick,
        ---@param context TotoWarEventContext_ComponentLeftClick
        function(context)
            return
                cm:is_local_players_turn()
                and context.string:match(TotoWar().ui.enums.patterns.inRecruitmentMercenaryUnitCard)
        end,
        ---@param context TotoWarEventContext_ComponentLeftClick
        function(context)
            local uiComponent = UIComponent(context.component)
            self:onInRecruitmentMercenaryUniCardClick(context.string, uiComponent)
        end)

    TotoWar().utils:addListener(
        "TotoWarCbacPlayerManager",
        TotoWar().ui.enums.events.componentLeftClick,
        ---@param context TotoWarEventContext_ComponentLeftClick
        function(context)
            return
                cm:is_local_players_turn()
                and context.string:match(TotoWar().ui.enums.patterns.recruitableMercenaryUnitCard)
        end,
        ---@param context TotoWarEventContext_ComponentLeftClick
        function(context)
            local uiComponent = UIComponent(context.component)
            self:onRecruitableMercenaryUniCardClick(context.string, uiComponent)
        end)

    TotoWar().utils:addListener(
        "TotoWarCbacPlayerManager",
        TotoWar().ui.enums.events.componentLeftClick,
        ---@param context TotoWarEventContext_ComponentLeftClick
        function(context)
            if cm:is_local_players_turn()
                and (string.match(context.string, TotoWar().ui.enums.patterns.unitExchangeAgentCard)
                    or string.match(context.string, TotoWar().ui.enums.patterns.unitExchangeUnitCard))
            then
                local uiComponent = UIComponent(context.component)

                return TotoWar().ui:isUIComponentChildOf(uiComponent, { "unit_exchange" })
            end

            return false
        end,
        function()
            self:updateUnitExchangeArmySuppliesCosts()
        end)

    TotoWar().utils:addListener(
        "TotoWarCbacPlayerManager",
        TotoWar().ui.enums.events.panelClosed,
        ---@param context TotoWarEventContext_PanelOpenedOrClosed
        function(context)
            return
                cm:is_local_players_turn()
                and context.string == TotoWar().ui.enums.panels.mercenaryRecruitment
                and self.selectedGeneralArmySuppliesCost
        end,
        function()
            self:onMercenaryRecruitmentPanelClosed()
        end)

    TotoWar().utils:addListener(
        "TotoWarCbacPlayerManager",
        TotoWar().ui.enums.events.panelClosed,
        ---@param context TotoWarEventContext_PanelOpenedOrClosed
        function(context)
            return
                cm:is_local_players_turn()
                and context.string == TotoWar().ui.enums.panels.unitExchange
        end,
        ---@param context TotoWarEventContext_PanelOpenedOrClosed
        function(context)
            self:onUnitExchangePanelClosed()
        end)

    TotoWar().utils:addListener(
        "TotoWarCbacPlayerManager",
        TotoWar().ui.enums.events.panelOpened,
        ---@param context TotoWarEventContext_PanelOpenedOrClosed
        function(context)
            return
                cm:is_local_players_turn()
                and context.string == TotoWar().ui.enums.panels.mercenaryRecruitment
                and self.selectedGeneralArmySuppliesCost
        end,
        function()
            self:onMercenaryRecruitmentPanelOpened()
        end)

    TotoWar().utils:addListener(
        "TotoWarCbacPlayerManager",
        TotoWar().ui.enums.events.panelOpened,
        ---@param context TotoWarEventContext_PanelOpenedOrClosed
        function(context)
            return
                cm:is_local_players_turn()
                and context.string == TotoWar().ui.enums.panels.unitExchange
        end,
        function()
            self:onUnitExchangePanelOpened()
        end)

    TotoWar().utils:addListener(
        "TotoWarCbacUIManager",
        TotoWarCbacPlayerManager.enums.events.selectedGeneralArmySuppliesCostChanged,
        function()
            return cm:is_local_players_turn()
        end,
        function()
            self:onSelectedGeneralArmySuppliesCostChanged()
        end)

    TotoWar().utils:addListener(
        "TotoWarCbacPlayerManager",
        TotoWar().ui.enums.events.unitAddedToRecruitment,
        ---@param context TotoWarEventContext_UnitAddedToRecruitment
        function(context)
            return
                cm:is_local_players_turn()
                and context:faction():name() == TotoWar().utils.playerFactionName
        end,
        ---@param context TotoWarEventContext_UnitAddedToRecruitment
        function(context)
            ---@type string
            local unitKey = context:main_unit_record()
            self:onUnitAddedToRecruitment(unitKey, false)
        end)

    TotoWar().utils:addListener(
        "TotoWarCbacPlayerManager",
        TotoWar().ui.enums.events.unitDisbanded,
        function()
            return cm:is_local_players_turn()
        end,
        ---@param context TotoWarEventContext_UnitDisbanded
        function(context)
            self:onUnitDisbanded(context:unit():unit_key())
        end)

    TotoWar().utils:addListener(
        "TotoWarCbacPlayerManager",
        TotoWar().ui.enums.events.unitMergedAndDestroyed,
        function()
            return cm:is_local_players_turn()
        end,
        ---@param context TotoWarEventContext_UnitMergedAndDestroyed
        function(context)
            self:onUnitMergedAndDestroyed(context:unit():unit_key())
        end)

    TotoWar().utils:addListener(
        "TotoWarCbacPlayerManager",
        TotoWar().ui.enums.events.unitRemovedFromRecruitment,
        ---@param context TotoWarEventContext_UnitRemovedFromRecruitment
        function(context)
            return
                cm:is_local_players_turn()
                and context:faction():name() == TotoWar().utils.playerFactionName
        end,
        ---@param context TotoWarEventContext_UnitRemovedFromRecruitment
        function(context)
            ---@type string
            self:onUnitRemovedFromRecruitment(context:main_unit_record())
        end)

    TotoWar().utils:addListener(
        "TotoWarCbacPlayerManager",
        TotoWar().ui.enums.events.unitTrained,
        function()
            return
            -- When the UnitTrained event is triggered while an army is selected, it means that we have
            -- clicked on the mercenary panel recruitment button
                cm:is_local_players_turn()
                and self.selectedGeneralArmySuppliesCost
        end,
        ---@param context TotoWarEventContext_UnitTrained
        function(context)
            self:onMercenaryUnitsRecruited(context:unit():unit_key())
        end)

    self.logger:logDebug("addListeners(): COMPLETED")
end

---Clears the list of in-recruitment mercenary units supply costs.
function TotoWarCbacPlayerManager:clearMercenaryRecruitment()
    self.logger:logDebug("clearMercenaryRecruitment(): STARTED")

    if #self.selectedGeneralArmySuppliesCost.inRecruitmentMercenaryUnits > 0 then
        self.selectedGeneralArmySuppliesCost:clearMercenaryRecruitment()

        -- Signaling army supplies cost change
        core:trigger_event(self.enums.events.selectedGeneralArmySuppliesCostChanged)
    end

    self.logger:logDebug("clearMercenaryRecruitment(): COMPLETED")
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
    local unitsUIComponent = TotoWar().ui:getUIComponent(TotoWar().ui.uiComponentQueries.unitsPanelUnits)

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
            TotoWar().ui.enums.ccoContextTypeIds.ccoMainUnitRecord)

        ---@type string
        local unitKey = unitContext:Call("Key")
        self.selectedGeneralArmySuppliesCost:addUnit(unitKey, false)
    end

    self.isInitializingArmySuppliesCost = false

    -- Signaling army supplies cost change
    core:trigger_event(self.enums.events.selectedGeneralArmySuppliesCostChanged)

    self.logger:logDebug(
        "initializeArmySuppliesCost(%s): COMPLETED => %s",
        general:cqi(),
        self.selectedGeneralArmySuppliesCost.totalCost)
end

---Reacts to a character being deselected.
function TotoWarCbacPlayerManager:onCharacterDeselected()
    self.logger:logDebug("[EVENT] onCharacterDeselected(): STARTED")

    self.selectedGeneralCqi = nil
    self.selectedGeneralArmySuppliesCost = nil

    self.logger:logDebug("[EVENT] onCharacterDeselected(): COMPLETED")
end

---Reacts to a character being selected.
---@param character CHARACTER_SCRIPT_INTERFACE Selected character.
function TotoWarCbacPlayerManager:onCharacterSelected(character)
    self.logger:logDebug("[EVENT] onCharacterSelected(%s): STARTED", character:cqi())

    local areArmySuppliesVisible =
        TotoWar().isDebug -- In debug mode, we see the army supplies cost
        or (TotoWar().utils:isPlayerFactionGeneral(character)
            and TotoWar().utils:canRecruitUnits(character:military_force()))

    if areArmySuppliesVisible then
        if character:cqi() ~= self.selectedGeneralCqi
        then
            self.selectedGeneralCqi = character:cqi()
            self.isInitializingArmySuppliesCost = true

            if cm:get_campaign_ui_manager():is_panel_open(TotoWar().ui.enums.panels.unitsPanel) then
                cm:real_callback(
                    function()
                        --- Initializing the army supplies cost for the newly selected army
                        self:initializeArmySuppliesCost(character)
                    end,
                    50) -- 50ms delay otherwise the units_panel is not up to date an still contains the units of the previously selected general army
            else
                --- Adding a one-time listener that waits for the unit_panel to open before
                --- initializing the army supplies cost because we need to get the cost of the
                --- units being recruited
                TotoWar().utils:addListener(
                    "TotoWarCbacPlayerManager_UnitsPanel",
                    TotoWar().ui.enums.events.panelOpened,
                    ---@param context TotoWarEventContext_PanelOpenedOrClosed
                    function(context)
                        return context.string == TotoWar().ui.enums.panels.unitsPanel
                    end,
                    function()
                        self:initializeArmySuppliesCost(character)
                    end,
                    false)
            end
        end
    elseif self.selectedGeneralArmySuppliesCost then
        self.selectedGeneralCqi = nil
        self.selectedGeneralArmySuppliesCost = nil
    end

    self.logger:logDebug("[EVENT] onCharacterSelected(%s): COMPLETED", character:cqi())
end

---Reacts to the click on the unit card of a mercenary unit in the selected army recruitment queue.
---@param uiComponentName string Name of the clicked UI component.
---@param unitComponent UIC Clicked UI component.
function TotoWarCbacPlayerManager:onInRecruitmentMercenaryUniCardClick(uiComponentName, unitComponent)
    self.logger:logDebug("[EVENT] onInRecruitmentMercenaryUniCardClick(%s): STARTED", uiComponentName)

    self.selectedGeneralArmySuppliesCost:removeUnit(uiComponentName)

    -- Signaling army supplies cost change
    core:trigger_event(self.enums.events.selectedGeneralArmySuppliesCostChanged)

    self.logger:logDebug("[EVENT] onInRecruitmentMercenaryUniCardClick(%s): COMPLETED", uiComponentName)
end

---Reacts to the mercenary recruitment panel being closed.
function TotoWarCbacPlayerManager:onMercenaryRecruitmentPanelClosed()
    self.logger:logDebug("[EVENT] onMercenaryRecruitmentPanelClosed(): STARTED")

    if #self.selectedGeneralArmySuppliesCost.inRecruitmentMercenaryUnits > 0 then
        self.selectedGeneralArmySuppliesCost:clearMercenaryRecruitment()

        -- Signaling army supplies cost change
        core:trigger_event(self.enums.events.selectedGeneralArmySuppliesCostChanged)
    end

    self.logger:logDebug("[EVENT] onMercenaryRecruitmentPanelClosed(): COMPLETED")
end

---Reacts to the mercenary recruitment panel being opened or closed.
function TotoWarCbacPlayerManager:onMercenaryRecruitmentPanelOpened()
    self.logger:logDebug("[EVENT] onMercenaryRecruitmentPanelOpened(): STARTED")

    self:clearMercenaryRecruitment()

    self.logger:logDebug("[EVENT] onMercenaryRecruitmentPanelOpened(): COMPLETED")
end

---Reacts to a mercenary unit being recruited in the selected general army.
---@param unitKey string Unit key.
function TotoWarCbacPlayerManager:onMercenaryUnitsRecruited(unitKey)
    self.logger:logDebug("[EVENT] onMercenaryUnitRecruited(): STARTED")

    self.selectedGeneralArmySuppliesCost:addUnit(unitKey, false)

    -- Signaling army supplies cost change
    core:trigger_event(self.enums.events.selectedGeneralArmySuppliesCostChanged)

    self.logger:logDebug("[EVENT] onMercenaryUnitRecruited(): COMPLETED")
end

---Reacts to the click on the unit card of a recruitable mercenary unit.
---@param uiComponentName string Name of the clicked UI component.
---@param unitUIComponent UIC Clicked UI component.
function TotoWarCbacPlayerManager:onRecruitableMercenaryUniCardClick(uiComponentName, unitUIComponent)
    self.logger:logDebug("[EVENT] onRecruitableMercenaryUniCardClick(%s): STARTED", uiComponentName)

    -- Workaround for the fact that we cannot know whether a unit card was `inactive` before clicking
    -- on it or became `inactive` after clicking on it because the click event is triggered after.
    -- This problem prevents us from simply checking the state of the component so we need to check
    -- whether the number of in recruitment mercenary units in the unit list is different from the number
    -- of in recruitment mercenary units we already have added to the army supplies cost.
    -- If there are more in recruitment mercenary units in the unit list, we consider that the unit card
    -- was not `inactive` at the time of the click and we add its army supplies cost.
    -- so we can add the unit army supplies cost.
    local inRecruitmentMercenaryUnitCount = 0
    local unitsUIComponent = TotoWar().ui:getUIComponent(TotoWar().ui.uiComponentQueries.unitsPanelUnits)

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
            TotoWar().ui.enums.ccoContextTypeIds.ccoMainUnitRecord)

        ---@type string
        local unitKey = unitContext:Call("Key")
        self:onUnitAddedToRecruitment(unitKey, true)
    end

    self.logger:logDebug("[EVENT] onRecruitableMercenaryUniCardClick(%s): COMPLETED", uiComponentName)
end

---Reacts to the army supplies cost of the selected general changing.
function TotoWarCbacPlayerManager:onSelectedGeneralArmySuppliesCostChanged()
    if not self.selectedGeneralCqi then
        return
    end

    self.logger:logDebug("[EVENT] onSelectedGeneralArmySuppliesCostChanged(): STARTED")

    local needsSelectedGeneralMovementUpdate = true

    if TotoWar().isDebug then
        -- In debug mode, if we select a general from another faction, we see the army supplies cost
        -- but we do not want to block the army movement
        local selectedGeneral = cm:get_character_by_cqi(self.selectedGeneralCqi)
        needsSelectedGeneralMovementUpdate = TotoWar().utils:isPlayerFactionGeneral(selectedGeneral)
    end

    if needsSelectedGeneralMovementUpdate then
        self:updatedSelectedGeneralMovement()
    end

    self.logger:logDebug("[EVENT] onSelectedGeneralArmySuppliesCostChanged(): COMPLETED")
end

---Reacts to a unit being added to the recruitment queue of the selected general army.
---@param unitKey string Unit key.
---@param isMercenary boolean Indicates whether the unit added to recruitment is a mercenary unit (regiment of renown, Grudge settles, Waaagh mobs, ...).
function TotoWarCbacPlayerManager:onUnitAddedToRecruitment(unitKey, isMercenary)
    self.logger:logDebug("[EVENT] onUnitAddedToRecruitment(%s): STARTED", unitKey)

    self.selectedGeneralArmySuppliesCost:addUnit(unitKey, isMercenary)

    -- Signaling army supplies cost change
    core:trigger_event(self.enums.events.selectedGeneralArmySuppliesCostChanged)

    self.logger:logDebug("[EVENT] onUnitAddedToRecruitment(%s): COMPLETED", unitKey)
end

---Reacts to a unit being disbanded.
---@param unitKey string Unit key
function TotoWarCbacPlayerManager:onUnitDisbanded(unitKey)
    self.logger:logDebug("[EVENT] onUnitDisbanded(%s): STARTED", unitKey)

    self.selectedGeneralArmySuppliesCost:removeUnit(unitKey)

    -- Signaling army supplies cost change
    core:trigger_event(self.enums.events.selectedGeneralArmySuppliesCostChanged)

    self.logger:logDebug("[EVENT] onUnitDisbanded(%s): COMPLETED", unitKey)
end

---Reacts to the unit exchange panel being closed.
function TotoWarCbacPlayerManager:onUnitExchangePanelClosed()
    self.logger:logDebug("[EVENT] onUnitExchangePanelClosed(): STARTED")

    self.unitExchangeArmySuppliesCost1 = nil
    self.unitExchangeArmySuppliesCost2 = nil

    self.logger:logDebug("[EVENT] onUnitExchangePanelClosed(): COMPLETED")
end

---Reacts to the unit exchange panel being opened.
function TotoWarCbacPlayerManager:onUnitExchangePanelOpened()
    self.logger:logDebug("[EVENT] onUnitExchangePanelOpened(): STARTED")

    self:updateUnitExchangeArmySuppliesCosts()

    self.logger:logDebug("[EVENT] onUnitExchangePanelOpened(): COMPLETED")
end

---Reacts to a unit card in the first army unit exchange pool being clicked.
function TotoWarCbacPlayerManager:onUnitExchangePoolUnitCardClick()
    self.logger:logDebug("[EVENT] onUnitExchangePoolUnitCardClick(): STARTED")

    -- Each time a unit exchange unit card is clicked, we need to go through each unit exchange pool
    -- to see which units are selected and which are not.
    -- This is because the user can select multiple unit cards at once using SHIFT + Click,
    -- we have no other way to know which cards have been added to the selection.
    self:updateUnitExchangeArmySuppliesCosts()

    self.logger:logDebug("[EVENT] onUnitExchangePoolUnitCardClick(): COMPLETED")
end

---Reacts to a unit being destroyed after having been merged with another unit.
---@param unitKey string Unit key.
function TotoWarCbacPlayerManager:onUnitMergedAndDestroyed(unitKey)
    self.logger:logDebug("[EVENT] onUnitMergedAndDestroyed(%s): STARTED", unitKey)

    self.selectedGeneralArmySuppliesCost:removeUnit(unitKey)

    -- Signaling army supplies cost change
    core:trigger_event(self.enums.events.selectedGeneralArmySuppliesCostChanged)

    self.logger:logDebug("[EVENT] onUnitMergedAndDestroyed(%s): COMPLETED", unitKey)
end

---Reacts to a unit being removed from the recruitment queue of the selected general army.
function TotoWarCbacPlayerManager:onUnitRemovedFromRecruitment(unitKey)
    self.logger:logDebug("[EVENT] onUnitRemovedFromRecruitment(%s): STARTED", unitKey)

    self.selectedGeneralArmySuppliesCost:removeUnit(unitKey)

    -- Signaling army supplies cost change
    core:trigger_event(self.enums.events.selectedGeneralArmySuppliesCostChanged)

    self.logger:logDebug("[EVENT] onUnitRemovedFromRecruitment(%s): COMPLETED", unitKey)
end

---Updates unit exchange army supplies cost of two unit exchange pools base on which unit cards
---are selected in one of the pools.
---@param unitExchangePoolUIComponent UIC Current unit exchange pool.
---@param unitExchangePoolArmySuppliesCost TotoWarCbacArmySuppliesCost Army supplies cost of the current unit exchange pool.
---@param otherUnitExchangePoolArmySuppliesCost TotoWarCbacArmySuppliesCost Army supplies cost of the other unit exchange pool.
function TotoWarCbacPlayerManager:updateUnitExchangeArmySuppliesCost(
    unitExchangePoolUIComponent,
    unitExchangePoolArmySuppliesCost,
    otherUnitExchangePoolArmySuppliesCost)
    local unitExchangePoolUnitListUIComponent = TotoWar().ui:getUIComponentChild(
        unitExchangePoolUIComponent,
        { "units" })

    for i = 0, unitExchangePoolUnitListUIComponent:ChildCount() - 1, 1 do
        local unitCardUIComponent = find_child_uicomponent_by_index(unitExchangePoolUnitListUIComponent, i)
        local cardImageHolderUIComponent = TotoWar().ui:getUIComponentChild(unitCardUIComponent, { "card_image_holder" })
        local unitContext = TotoWar().ui:getUIComponentCCO(
            cardImageHolderUIComponent,
            TotoWar().ui.enums.ccoContextTypeIds.ccoMainUnitRecord)

        ---@type string
        local unitKey = unitContext:Call("Key")

        if string.match(unitCardUIComponent:CurrentState(), "^" .. TotoWar().ui.enums.uiComponentStates.selected) then
            otherUnitExchangePoolArmySuppliesCost:addUnit(unitKey, false)
        else
            unitExchangePoolArmySuppliesCost:addUnit(unitKey, false)
        end
    end
end

---Updates unit exchange army supplies costs.
function TotoWarCbacPlayerManager:updateUnitExchangeArmySuppliesCosts()
    self.logger:logDebug("updateUnitExchangeArmySuppliesCosts(): STARTED")

    self.unitExchangeArmySuppliesCost1 = TotoWarCbacArmySuppliesCost.new()
    self.unitExchangeArmySuppliesCost2 = TotoWarCbacArmySuppliesCost.new()

    local unitExchangePool1UIComponent = TotoWar().ui:getUIComponent(TotoWar().ui.uiComponentQueries.unitExchangePool1)
    self:updateUnitExchangeArmySuppliesCost(
        unitExchangePool1UIComponent,
        self.unitExchangeArmySuppliesCost1,
        self.unitExchangeArmySuppliesCost2)

    local unitExchangePool2UIComponent = TotoWar().ui:getUIComponent(TotoWar().ui.uiComponentQueries.unitExchangePool2)
    self:updateUnitExchangeArmySuppliesCost(
        unitExchangePool2UIComponent,
        self.unitExchangeArmySuppliesCost2,
        self.unitExchangeArmySuppliesCost1)

    -- Signaling unit exchange army supplies cost change
    core:trigger_event(self.enums.events.unitExchangeArmySuppliesCostChanged)

    self.logger:logDebug("updateUnitExchangeArmySuppliesCosts(): COMPLETED")
end

---Updates the ability to move of the selected general depending on the army supplies cost of its army.
function TotoWarCbacPlayerManager:updatedSelectedGeneralMovement()
    self.logger:logDebug("updatedSelectedGeneralMovement(): STARTED")

    if self.selectedGeneralArmySuppliesCost.availableSupplies < 0 then
        self.logger:logDebug("updatedSelectedGeneralMovement(): ARMY BLOCKED")

        cm:disable_movement_for_character("character_cqi:" .. self.selectedGeneralCqi)
    else
        cm:enable_movement_for_character("character_cqi:" .. self.selectedGeneralCqi)
    end

    self.logger:logDebug("updatedSelectedGeneralMovement(): COMPLETED")
end
