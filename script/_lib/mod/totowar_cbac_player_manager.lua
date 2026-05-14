---Manager in charge of managing the army supplies for the player armies.
---@class TotoWarCbacPlayerManager
TotoWarCbacPlayerManager = {
    ---Indicates whether the army supplies cost is being initialized.
    ---When it is the case, methods that update UI elements (such as when a panel is opened)
    ---should not execute because the UI will be updated when the
    ---TotoWarCbac_SelectedLordArmySuppliesCostChanged event is triggered at the end ot the
    ---supplies cost initialization.
    isInitializingArmySuppliesCost = false,

    ---Unique identifier of the selected lord.
    ---@type CHARACTER_SCRIPT_INTERFACE  | nil
    selectedLord = nil,

    ---Army supplies cost of the army of the selected lord.
    ---@type TotoWarCbacArmySuppliesCost | nil
    selectedLordArmySuppliesCost = nil,

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
    TotoWarCbac.loggers.playerManager:logDebug("TotoWarCbacPlayerManager.new(): STARTED")

    local instance = setmetatable({}, TotoWarCbacPlayerManager)

    instance.selectedLord = nil
    instance.selectedLordArmySuppliesCost = nil

    TotoWarCbac.loggers.playerManager:logDebug("TotoWarCbacPlayerManager.new(): COMPLETED")

    return instance
end

---Adds listeners for events.
function TotoWarCbacPlayerManager:addListeners()
    TotoWarCbac.loggers.playerManager:logDebug("addListeners(): STARTED")

    TotoWar.utils:addListener(
        "TotoWarCbacPlayerManager",
        TotoWar.enums.gameEvents.characterDeselected,
        function()
            -- We do not check the TotoWarCbac.options.playerArmySuppliesEnabled option because when this option
            -- is disabled, we deselect everything and we want onCharacterDeselected to be executed
            -- to reset army movement. This avoids having the last selected army unable to move after
            -- disabling the option.
            return cm:is_local_players_turn()
        end,
        function()
            self:onCharacterDeselected()
        end)

    TotoWar.utils:addListener(
        "TotoWarCbacPlayerManager",
        TotoWar.enums.gameEvents.characterSelected,
        function()
            return
                TotoWarCbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
        end,
        ---@param context CharacterSelected
        function(context)
            self:onCharacterSelected(context:character())
        end)

    TotoWar.utils:addListener(
        "TotoWarCbacPlayerManager_InRecruitmentMercenaryUnitCard",
        TotoWar.enums.gameEvents.componentLeftClick,
        ---@param context TotoWarGameEventContext_ComponentLeftClick
        function(context)
            return
                TotoWarCbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
                and context.string:match(TotoWar.enums.uiPatterns.inRecruitmentMercenaryUnitCard)
        end,
        ---@param context TotoWarGameEventContext_ComponentLeftClick
        function(context)
            self:onInRecruitmentMercenaryUniCardClick(context.string)
        end)

    TotoWar.utils:addListener(
        "TotoWarCbacPlayerManager",
        TotoWar.enums.gameEvents.componentLeftClick,
        ---@param context TotoWarGameEventContext_ComponentLeftClick
        function(context)
            return
                TotoWarCbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
                and context.string:match(TotoWar.enums.uiPatterns.recruitableMercenaryUnitCard)
        end,
        ---@param context TotoWarGameEventContext_ComponentLeftClick
        function(context)
            local uiComponent = UIComponent(context.component)
            self:onRecruitableMercenaryUniCardClick(context.string, uiComponent)
        end)

    TotoWar.utils:addListener(
        "TotoWarCbacPlayerManager",
        TotoWar.enums.gameEvents.componentLeftClick,
        ---@param context TotoWarGameEventContext_ComponentLeftClick
        function(context)
            if TotoWarCbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
                and (string.match(context.string, TotoWar.enums.uiPatterns.unitExchangeHeroCard)
                    or string.match(context.string, TotoWar.enums.uiPatterns.unitExchangeUnitCard))
            then
                local uiComponent = UIComponent(context.component)

                return TotoWar.ui:isUIComponentChildOf(uiComponent, { "unit_exchange" })
            end

            return false
        end,
        function()
            self:updateUnitExchangeArmySuppliesCosts()
        end)

    TotoWar.utils:addListener(
        "TotoWarCbacPlayerManager",
        TotoWar.enums.gameEvents.panelClosed,
        ---@param context TotoWarGameEventContext_PanelOpenedOrClosed
        function(context)
            return
                TotoWarCbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
                and context.string == TotoWar.enums.uiPanels.mercenaryRecruitment
                and self.selectedLordArmySuppliesCost ~= nil
        end,
        function()
            self:onMercenaryRecruitmentPanelClosed()
        end)

    TotoWar.utils:addListener(
        "TotoWarCbacPlayerManager",
        TotoWar.enums.gameEvents.panelClosed,
        ---@param context TotoWarGameEventContext_PanelOpenedOrClosed
        function(context)
            return
                TotoWarCbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
                and context.string == TotoWar.enums.uiPanels.unitExchange
        end,
        ---@param context TotoWarGameEventContext_PanelOpenedOrClosed
        function(context)
            self:onUnitExchangePanelClosed()
        end)

    TotoWar.utils:addListener(
        "TotoWarCbacPlayerManager",
        TotoWar.enums.gameEvents.panelOpened,
        ---@param context TotoWarGameEventContext_PanelOpenedOrClosed
        function(context)
            return
                TotoWarCbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
                and context.string == TotoWar.enums.uiPanels.mercenaryRecruitment
                and self.selectedLordArmySuppliesCost ~= nil
        end,
        function()
            self:onMercenaryRecruitmentPanelOpened()
        end)

    TotoWar.utils:addListener(
        "TotoWarCbacPlayerManager",
        TotoWar.enums.gameEvents.panelOpened,
        ---@param context TotoWarGameEventContext_PanelOpenedOrClosed
        function(context)
            return
                TotoWarCbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
                and context.string == TotoWar.enums.uiPanels.unitExchange
        end,
        function()
            self:onUnitExchangePanelOpened()
        end)

    TotoWar.utils:addListener(
        "TotoWarCbacUIManager",
        TotoWarCbac.enums.modEvents.selectedLordArmySuppliesCostChanged,
        function()
            return
                TotoWarCbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
        end,
        function()
            self:onSelectedLordArmySuppliesCostChanged()
        end)

    TotoWar.utils:addListener(
        "TotoWarCbacPlayerManager",
        TotoWar.enums.gameEvents.unitAddedToRecruitment,
        ---@param context TotoWarGameEventContext_UnitAddedToRecruitment
        function(context)
            return
                TotoWarCbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
                and context:faction():name() == TotoWar.utils.playerFactionName
        end,
        ---@param context TotoWarGameEventContext_UnitAddedToRecruitment
        function(context)
            ---@type string
            local unitKey = context:main_unit_record()
            self:onUnitAddedToRecruitment(unitKey, false)
        end)

    TotoWar.utils:addListener(
        "TotoWarCbacPlayerManager",
        TotoWar.enums.gameEvents.unitDisbanded,
        function()
            return
                TotoWarCbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
        end,
        ---@param context TotoWarGameEventContext_UnitDisbanded
        function(context)
            self:onUnitDisbanded(context:unit():unit_key())
        end)

    TotoWar.utils:addListener(
        "TotoWarCbacPlayerManager",
        TotoWar.enums.gameEvents.unitMergedAndDestroyed,
        function()
            return
                TotoWarCbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
        end,
        ---@param context TotoWarGameEventContext_UnitMergedAndDestroyed
        function(context)
            self:onUnitMergedAndDestroyed(context:unit():unit_key())
        end)

    TotoWar.utils:addListener(
        "TotoWarCbacPlayerManager",
        TotoWar.enums.gameEvents.unitRemovedFromRecruitment,
        ---@param context TotoWarGameEventContext_UnitRemovedFromRecruitment
        function(context)
            return
                TotoWarCbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
                and context:faction():name() == TotoWar.utils.playerFactionName
        end,
        ---@param context TotoWarGameEventContext_UnitRemovedFromRecruitment
        function(context)
            self:onUnitRemovedFromRecruitment(context:main_unit_record())
        end)

    TotoWar.utils:addListener(
        "TotoWarCbacPlayerManager",
        TotoWar.enums.gameEvents.unitTrained,
        function()
            return
            -- When the UnitTrained event is triggered while an army is selected, it means that we have
            -- clicked on the mercenary panel recruitment button
                TotoWarCbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
                and self.selectedLordArmySuppliesCost ~= nil
        end,
        ---@param context TotoWarGameEventContext_UnitTrained
        function(context)
            local unit = context:unit()
            self:onMercenaryUnitsRecruited(unit:unit_key(), unit:command_queue_index())
        end)

    TotoWarCbac.loggers.playerManager:logDebug("addListeners(): COMPLETED")
end

---Clears the list of in-recruitment mercenary units supply costs.
function TotoWarCbacPlayerManager:clearMercenaryRecruitment()
    TotoWarCbac.loggers.playerManager:logDebug("clearMercenaryRecruitment(): STARTED")

    if #self.selectedLordArmySuppliesCost.inRecruitmentMercenaryUnits > 0 then
        self.selectedLordArmySuppliesCost:clearMercenaryRecruitment()

        -- Signaling army supplies cost change
        core:trigger_event(TotoWarCbac.enums.modEvents.selectedLordArmySuppliesCostChanged)
    end

    TotoWarCbac.loggers.playerManager:logDebug("clearMercenaryRecruitment(): COMPLETED")
end

---Initializes the army supplies cost of the army of the selected lord.
---@param lord CHARACTER_SCRIPT_INTERFACE Selected lord.
function TotoWarCbacPlayerManager:initializeArmySuppliesCost(lord)
    TotoWarCbac.loggers.playerManager:logDebug(
        "initializeArmySuppliesCost(%s): STARTED",
        function() return TotoWar.utils:getCharacterCaption(lord) end)

    self.selectedLordArmySuppliesCost = TotoWarCbacArmySuppliesCost.newFromArmy(false, lord:military_force())

    -- Adding units being recruited in the lord army
    local unitsUIComponent = TotoWar.ui:getUIComponent(TotoWar.ui.uiComponentQueries.unitsPanelUnits)

    -- Adding units from the recruitment queue
    for i = unitsUIComponent:ChildCount() - 1, 0, -1 do
        -- Iterating from the last unit card since units being recruited are at the end
        local unitCardUIComponent = find_child_uicomponent_by_index(unitsUIComponent, i)

        if not unitCardUIComponent:Id():match(TotoWar.enums.uiPatterns.inRecruitmentStandardUnitCard)
        then
            -- Stopping the iteration as soon as we encounter a unit that is not being recruited
            break
        end

        local cardImageHolderUIComponent = TotoWar.ui:getUIComponentChild(
            unitCardUIComponent,
            { "card_image_holder" })
        local unitContext = TotoWar.ui:getUIComponentCCO(
            cardImageHolderUIComponent,
            TotoWar.enums.ccoContextTypeIds.mainUnitRecord)

        ---@type string
        local unitKey = unitContext:Call("Key")
        self.selectedLordArmySuppliesCost:addUnit(unitKey)
    end

    self.isInitializingArmySuppliesCost = false

    -- Signaling army supplies cost change
    core:trigger_event(TotoWarCbac.enums.modEvents.selectedLordArmySuppliesCostChanged)

    TotoWarCbac.loggers.playerManager:logDebug(
        "initializeArmySuppliesCost(%s): COMPLETED => %s",
        function() return TotoWar.utils:getCharacterCaption(lord) end,
        function() return self.selectedLordArmySuppliesCost.totalCost end)
end

---Reacts to a character being deselected.
function TotoWarCbacPlayerManager:onCharacterDeselected()
    TotoWarCbac.loggers.playerManager:logDebug("onCharacterDeselected(): STARTED")

    if self.selectedLord then
        cm:enable_movement_for_character("character_cqi:" .. self.selectedLord:cqi())
        self.selectedLord = nil
        self.selectedLordArmySuppliesCost = nil
    end

    TotoWarCbac.loggers.playerManager:logDebug("onCharacterDeselected(): COMPLETED")
end

---Reacts to a character being selected.
---@param character CHARACTER_SCRIPT_INTERFACE Selected character.
function TotoWarCbacPlayerManager:onCharacterSelected(character)
    TotoWarCbac.loggers.playerManager:logDebug(
        "onCharacterSelected(%s from %s): STARTED",
        function() return TotoWar.utils:getCharacterCaption(character) end,
        function() return TotoWar.utils:getFactionCaption(character:faction():name()) end)

    if TotoWar.utils:isLordCharacter(character)
        and (TotoWar.utils:isPlayerFaction(character:faction():name())
            or TotoWar.options.debugEnabled) -- In debug mode, we see the army supplies cost or other faction lords
    then
        self.selectedLord = character
        self.isInitializingArmySuppliesCost = true

        if cm:get_campaign_ui_manager():is_panel_open(TotoWar.enums.uiPanels.unitsPanel) then
            cm:callback(
                function()
                    --- Initializing the army supplies cost for the newly selected army
                    self:initializeArmySuppliesCost(character)
                end,
                0.05) -- 50ms delay otherwise the units_panel is not up to date an still contains the units of the previously selected lord army
        else
            --- Adding a one-time listener that waits for the unit_panel to open before
            --- initializing the army supplies cost because we need to get the cost of the
            --- units being recruited
            TotoWar.utils:addListener(
                "TotoWarCbacPlayerManager_UnitsPanel",
                TotoWar.enums.gameEvents.panelOpened,
                ---@param context TotoWarGameEventContext_PanelOpenedOrClosed
                function(context)
                    return context.string == TotoWar.enums.uiPanels.unitsPanel
                end,
                function()
                    self:initializeArmySuppliesCost(character)
                end,
                false)
        end
    elseif self.selectedLordArmySuppliesCost then
        self.selectedLord = nil
        self.selectedLordArmySuppliesCost = nil
    end

    TotoWarCbac.loggers.playerManager:logDebug(
        "onCharacterSelected(%s from %s): COMPLETED",
        function() return TotoWar.utils:getCharacterCaption(character) end,
        function() return TotoWar.utils:getFactionCaption(character:faction():name()) end)
end

---Reacts to the click on the unit card of a mercenary unit in the selected army recruitment queue.
---@param uiComponentName string Name of the clicked UI component.
function TotoWarCbacPlayerManager:onInRecruitmentMercenaryUniCardClick(uiComponentName)
    TotoWarCbac.loggers.playerManager:logDebug(
        "onInRecruitmentMercenaryUniCardClick(%s): STARTED",
        function() return uiComponentName end)

    self.selectedLordArmySuppliesCost:removeUnit(uiComponentName)

    -- Signaling army supplies cost change
    core:trigger_event(TotoWarCbac.enums.modEvents.selectedLordArmySuppliesCostChanged)

    TotoWarCbac.loggers.playerManager:logDebug(
        "onInRecruitmentMercenaryUniCardClick(%s): COMPLETED",
        function() return uiComponentName end)
end

---Reacts to the mercenary recruitment panel being closed.
function TotoWarCbacPlayerManager:onMercenaryRecruitmentPanelClosed()
    TotoWarCbac.loggers.playerManager:logDebug("onMercenaryRecruitmentPanelClosed(): STARTED")

    if #self.selectedLordArmySuppliesCost.inRecruitmentMercenaryUnits > 0 then
        self.selectedLordArmySuppliesCost:clearMercenaryRecruitment()

        -- Signaling army supplies cost change
        core:trigger_event(TotoWarCbac.enums.modEvents.selectedLordArmySuppliesCostChanged)
    end

    TotoWarCbac.loggers.playerManager:logDebug("onMercenaryRecruitmentPanelClosed(): COMPLETED")
end

---Reacts to the mercenary recruitment panel being opened or closed.
function TotoWarCbacPlayerManager:onMercenaryRecruitmentPanelOpened()
    TotoWarCbac.loggers.playerManager:logDebug("onMercenaryRecruitmentPanelOpened(): STARTED")

    self:clearMercenaryRecruitment()

    TotoWarCbac.loggers.playerManager:logDebug("onMercenaryRecruitmentPanelOpened(): COMPLETED")
end

---Reacts to a mercenary unit being recruited in the selected lord army.
---@param unitKey string Unit key.
---@param cqi integer Unit command queue index.
function TotoWarCbacPlayerManager:onMercenaryUnitsRecruited(unitKey, cqi)
    TotoWarCbac.loggers.playerManager:logDebug(
        "onMercenaryUnitRecruited(%s): STARTED",
        function() return TotoWar.utils:getUnitCaption(unitKey) end)

    self.selectedLordArmySuppliesCost:addUnit(unitKey, cqi)

    -- Signaling army supplies cost change
    core:trigger_event(TotoWarCbac.enums.modEvents.selectedLordArmySuppliesCostChanged)

    TotoWarCbac.loggers.playerManager:logDebug(
        "onMercenaryUnitRecruited(%s): COMPLETED",
        function() return TotoWar.utils:getUnitCaption(unitKey) end)
end

---Reacts to the click on the unit card of a recruitable mercenary unit.
---@param uiComponentName string Name of the clicked UI component.
---@param unitUIComponent UIC Clicked UI component.
function TotoWarCbacPlayerManager:onRecruitableMercenaryUniCardClick(uiComponentName, unitUIComponent)
    TotoWarCbac.loggers.playerManager:logDebug(
        "onRecruitableMercenaryUniCardClick(%s): STARTED",
        function() return uiComponentName end)

    -- Workaround for the fact that we cannot know whether a unit card was `inactive` before clicking
    -- on it or became `inactive` after clicking on it because the click event is triggered after.
    -- This problem prevents us from simply checking the state of the component so we need to check
    -- whether the number of in recruitment mercenary units in the unit list is different from the number
    -- of in recruitment mercenary units we already have added to the army supplies cost.
    -- If there are more in recruitment mercenary units in the unit list, we consider that the unit card
    -- was not `inactive` at the time of the click and we add its army supplies cost.
    -- so we can add the unit army supplies cost.
    local inRecruitmentMercenaryUnitCount = 0
    local unitsUIComponent = TotoWar.ui:getUIComponent(TotoWar.ui.uiComponentQueries.unitsPanelUnits)

    for i = unitsUIComponent:ChildCount() - 1, 0, -1 do
        -- Iterating from the last unit card since units being recruited are at the end
        local unitCardUIComponent = find_child_uicomponent_by_index(unitsUIComponent, i)

        if not unitCardUIComponent:Id():match(TotoWar.enums.uiPatterns.inRecruitmentMercenaryUnitCard)
        then
            -- Stopping the iteration as soon as we encounter a unit that is not a mercenary unit being recruited
            break
        end

        inRecruitmentMercenaryUnitCount = inRecruitmentMercenaryUnitCount + 1
    end

    TotoWarCbac.loggers.playerManager:logDebug(
        "onRecruitableMercenaryUniCardClick(%s): %s mercenary units in the recruitment pool | %s mercenary units tracked in the army supplies cost",
        function() return uiComponentName end,
        function() return inRecruitmentMercenaryUnitCount end,
        function() return #self.selectedLordArmySuppliesCost.inRecruitmentMercenaryUnits end)

    if inRecruitmentMercenaryUnitCount > #self.selectedLordArmySuppliesCost.inRecruitmentMercenaryUnits then
        local unitContext = TotoWar.ui:getUIComponentCCO(
            unitUIComponent,
            TotoWar.enums.ccoContextTypeIds.mainUnitRecord)

        ---@type string
        local unitKey = unitContext:Call("Key")
        self:onUnitAddedToRecruitment(unitKey, true)
    end

    TotoWarCbac.loggers.playerManager:logDebug(
        "onRecruitableMercenaryUniCardClick(%s): COMPLETED",
        function() return uiComponentName end)
end

---Reacts to the army supplies cost of the selected lord changing.
function TotoWarCbacPlayerManager:onSelectedLordArmySuppliesCostChanged()
    if not self.selectedLord then
        return
    end

    TotoWarCbac.loggers.playerManager:logDebug("onSelectedLordArmySuppliesCostChanged(): STARTED")

    local needsSelectedLordMovementUpdate = true

    if TotoWar.options.debugEnabled then
        -- In debug mode, if we select a lord from another faction, we see the army supplies cost
        -- but we do not want to block the army movement
        needsSelectedLordMovementUpdate = TotoWar.utils:isPlayerFaction(self.selectedLord:faction():name())
    end

    if needsSelectedLordMovementUpdate then
        self:updatedSelectedLordMovement()
    end

    TotoWarCbac.loggers.playerManager:logDebug("onSelectedLordArmySuppliesCostChanged(): COMPLETED")
end

---Reacts to a unit being added to the recruitment queue of the selected lord army.
---@param unitKey string Unit key.
---@param isMercenary boolean Indicates whether the unit added to recruitment is a mercenary unit (regiment of renown, Grudge settles, Waaagh mobs, ...).
function TotoWarCbacPlayerManager:onUnitAddedToRecruitment(unitKey, isMercenary)
    TotoWarCbac.loggers.playerManager:logDebug(
        "onUnitAddedToRecruitment(%s, %s): STARTED",
        function() return TotoWar.utils:getUnitCaption(unitKey) end,
        function() return isMercenary end)

    self.selectedLordArmySuppliesCost:addUnit(unitKey, nil, isMercenary)

    -- Signaling army supplies cost change
    core:trigger_event(TotoWarCbac.enums.modEvents.selectedLordArmySuppliesCostChanged)

    TotoWarCbac.loggers.playerManager:logDebug(
        "onUnitAddedToRecruitment(%s, %s): COMPLETED",
        function() return TotoWar.utils:getUnitCaption(unitKey) end,
        function() return isMercenary end)
end

---Reacts to a unit being disbanded.
---@param unitKey string Unit key
function TotoWarCbacPlayerManager:onUnitDisbanded(unitKey)
    TotoWarCbac.loggers.playerManager:logDebug(
        "onUnitDisbanded(%s): STARTED",
        function() return TotoWar.utils:getUnitCaption(unitKey) end)

    self.selectedLordArmySuppliesCost:removeUnit(unitKey)

    -- Signaling army supplies cost change
    core:trigger_event(TotoWarCbac.enums.modEvents.selectedLordArmySuppliesCostChanged)

    TotoWarCbac.loggers.playerManager:logDebug(
        "onUnitDisbanded(%s): COMPLETED",
        function() return TotoWar.utils:getUnitCaption(unitKey) end)
end

---Reacts to the unit exchange panel being closed.
function TotoWarCbacPlayerManager:onUnitExchangePanelClosed()
    TotoWarCbac.loggers.playerManager:logDebug("onUnitExchangePanelClosed(): STARTED")

    self.unitExchangeArmySuppliesCost1 = nil
    self.unitExchangeArmySuppliesCost2 = nil

    TotoWarCbac.loggers.playerManager:logDebug("onUnitExchangePanelClosed(): COMPLETED")
end

---Reacts to the unit exchange panel being opened.
function TotoWarCbacPlayerManager:onUnitExchangePanelOpened()
    TotoWarCbac.loggers.playerManager:logDebug("onUnitExchangePanelOpened(): STARTED")

    self:updateUnitExchangeArmySuppliesCosts()

    TotoWarCbac.loggers.playerManager:logDebug("onUnitExchangePanelOpened(): COMPLETED")
end

---Reacts to a unit card in the first army unit exchange pool being clicked.
function TotoWarCbacPlayerManager:onUnitExchangePoolUnitCardClick()
    TotoWarCbac.loggers.playerManager:logDebug("onUnitExchangePoolUnitCardClick(): STARTED")

    -- Each time a unit exchange unit card is clicked, we need to go through each unit exchange pool
    -- to see which units are selected and which are not.
    -- This is because the user can select multiple unit cards at once using SHIFT + Click,
    -- we have no other way to know which cards have been added to the selection.
    self:updateUnitExchangeArmySuppliesCosts()

    TotoWarCbac.loggers.playerManager:logDebug("onUnitExchangePoolUnitCardClick(): COMPLETED")
end

---Reacts to a unit being destroyed after having been merged with another unit.
---@param unitKey string Unit key.
function TotoWarCbacPlayerManager:onUnitMergedAndDestroyed(unitKey)
    TotoWarCbac.loggers.playerManager:logDebug(
        "onUnitMergedAndDestroyed(%s): STARTED",
        function() return TotoWar.utils:getUnitCaption(unitKey) end)

    self.selectedLordArmySuppliesCost:removeUnit(unitKey)

    -- Signaling army supplies cost change
    core:trigger_event(TotoWarCbac.enums.modEvents.selectedLordArmySuppliesCostChanged)

    TotoWarCbac.loggers.playerManager:logDebug(
        "onUnitMergedAndDestroyed(%s): COMPLETED",
        function() return TotoWar.utils:getUnitCaption(unitKey) end)
end

---Reacts to a unit being removed from the recruitment queue of the selected lord army.
function TotoWarCbacPlayerManager:onUnitRemovedFromRecruitment(unitKey)
    TotoWarCbac.loggers.playerManager:logDebug(
        "onUnitRemovedFromRecruitment(%s): STARTED",
        function() return TotoWar.utils:getUnitCaption(unitKey) end)

    self.selectedLordArmySuppliesCost:removeUnit(unitKey)

    -- Signaling army supplies cost change
    core:trigger_event(TotoWarCbac.enums.modEvents.selectedLordArmySuppliesCostChanged)

    TotoWarCbac.loggers.playerManager:logDebug(
        "onUnitRemovedFromRecruitment(%s): COMPLETED",
        function() return TotoWar.utils:getUnitCaption(unitKey) end)
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
    local unitExchangePoolUnitListUIComponent = TotoWar.ui:getUIComponentChild(
        unitExchangePoolUIComponent,
        { "units" })

    for i = 0, unitExchangePoolUnitListUIComponent:ChildCount() - 1, 1 do
        local unitCardUIComponent = find_child_uicomponent_by_index(unitExchangePoolUnitListUIComponent, i)
        local cardImageHolderUIComponent = TotoWar.ui:getUIComponentChild(unitCardUIComponent, { "card_image_holder" })
        local unitContext = TotoWar.ui:getUIComponentCCO(
            cardImageHolderUIComponent,
            TotoWar.enums.ccoContextTypeIds.mainUnitRecord)

        ---@type string
        local unitKey = unitContext:Call("Key")

        if string.match(unitCardUIComponent:CurrentState(), "^" .. TotoWar.enums.uiComponentStates.selected) then
            otherUnitExchangePoolArmySuppliesCost:addUnit(unitKey)
        else
            unitExchangePoolArmySuppliesCost:addUnit(unitKey)
        end
    end
end

---Updates unit exchange army supplies costs.
function TotoWarCbacPlayerManager:updateUnitExchangeArmySuppliesCosts()
    TotoWarCbac.loggers.playerManager:logDebug("updateUnitExchangeArmySuppliesCosts(): STARTED")

    self.unitExchangeArmySuppliesCost1 = TotoWarCbacArmySuppliesCost.new(false, self.selectedLord:rank())
    self.unitExchangeArmySuppliesCost2 = TotoWarCbacArmySuppliesCost.new(false, self.selectedLord:rank())

    local unitExchangePool1UIComponent = TotoWar.ui:getUIComponent(TotoWar.ui.uiComponentQueries.unitExchangePool1)
    self:updateUnitExchangeArmySuppliesCost(
        unitExchangePool1UIComponent,
        self.unitExchangeArmySuppliesCost1,
        self.unitExchangeArmySuppliesCost2)

    local unitExchangePool2UIComponent = TotoWar.ui:getUIComponent(TotoWar.ui.uiComponentQueries.unitExchangePool2)
    self:updateUnitExchangeArmySuppliesCost(
        unitExchangePool2UIComponent,
        self.unitExchangeArmySuppliesCost2,
        self.unitExchangeArmySuppliesCost1)

    -- Signaling unit exchange army supplies cost change
    core:trigger_event(TotoWarCbac.enums.modEvents.unitExchangeArmySuppliesCostChanged)

    TotoWarCbac.loggers.playerManager:logDebug("updateUnitExchangeArmySuppliesCosts(): COMPLETED")
end

---Updates the ability to move of the selected lord depending on the army supplies cost of its army.
function TotoWarCbacPlayerManager:updatedSelectedLordMovement()
    TotoWarCbac.loggers.playerManager:logDebug("updatedSelectedLordMovement(): STARTED")

    if self.selectedLordArmySuppliesCost.availableSupplies < 0 then
        TotoWarCbac.loggers.playerManager:logDebug(
            "updatedSelectedLordMovement(): BLOCKED => %s",
            function() return TotoWar.utils:getCharacterCaption(self.selectedLord) end)

        cm:disable_movement_for_character(cm:char_lookup_str(self.selectedLord:cqi()))

        -- Reactivating movement for heroes contained in the army as they should be able to leave the army
        local selectedLordArmyCharacters = self.selectedLord:military_force():character_list()

        for i = 0, selectedLordArmyCharacters:num_items() - 1, 1 do
            local character = selectedLordArmyCharacters:item_at(i)

            if character:character_type_key() ~= TotoWar.enums.characterTypes.lord then
                cm:enable_movement_for_character(cm:char_lookup_str(character:cqi()))
            end
        end
    else
        TotoWarCbac.loggers.playerManager:logDebug(
            "updatedSelectedLordMovement(): FREE TO MOVE => %s",
            function() return TotoWar.utils:getCharacterCaption(self.selectedLord) end)

        cm:enable_movement_for_character("character_cqi:" .. self.selectedLord:cqi())
    end

    TotoWarCbac.loggers.playerManager:logDebug("updatedSelectedLordMovement(): COMPLETED")
end
