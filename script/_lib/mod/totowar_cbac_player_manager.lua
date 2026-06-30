---Manager in charge of managing the army supplies for the player armies.
---@class TotoWar_Cbac_PlayerManager
TotoWar_Cbac_PlayerManager = {
    ---Indicates whether the army supplies cost is being initialized.
    ---When it is the case, methods that update UI elements (such as when a panel is opened)
    ---should not execute because the UI will be updated when the
    ---TotoWar_Cbac_SelectedLordArmySuppliesCostChanged event is triggered at the end ot the
    ---supplies cost initialization.
    isInitializingArmySuppliesCost = false,

    ---Unique identifier of the selected lord.
    ---@type CHARACTER_SCRIPT_INTERFACE  | nil
    selectedLord = nil,

    ---Army supplies cost of the army of the selected lord.
    ---@type TotoWar_Cbac_ArmySuppliesCost | nil
    selectedLordArmySuppliesCost = nil,

    ---Army supplies cost of the first army during unit exchange.
    ---@type TotoWar_Cbac_ArmySuppliesCost | nil
    unitExchangeArmySuppliesCost1 = nil,

    ---Army supplies cost of the second army during unit exchange.
    ---@type TotoWar_Cbac_ArmySuppliesCost | nil
    unitExchangeArmySuppliesCost2 = nil
}
TotoWar_Cbac_PlayerManager.__index = TotoWar_Cbac_PlayerManager

---Initializes a new instance.
---@return TotoWar_Cbac_PlayerManager
function TotoWar_Cbac_PlayerManager.new()
    TotoWar_Cbac.loggers.playerManager:logDebug("TotoWar_Cbac_PlayerManager.new(): STARTED")

    local instance = setmetatable({}, TotoWar_Cbac_PlayerManager)

    instance.selectedLord = nil
    instance.selectedLordArmySuppliesCost = nil

    TotoWar_Cbac.loggers.playerManager:logDebug("TotoWar_Cbac_PlayerManager.new(): COMPLETED")

    return instance
end

---Adds listeners for events.
function TotoWar_Cbac_PlayerManager:addListeners()
    TotoWar_Cbac.loggers.playerManager:logDebug("addListeners(): STARTED")

    TotoWar__Gameplay:addListener(
        "TotoWar_Cbac_PlayerManager",
        TotoWar__Enum_GameEvent.characterDeselected,
        function()
            -- We do not check the TotoWar_Cbac.options.playerArmySuppliesEnabled option because when this option
            -- is disabled, we deselect everything and we want onCharacterDeselected to be executed
            -- to reset army movement. This avoids having the last selected army unable to move after
            -- disabling the option.
            return cm:is_local_players_turn()
        end,
        function()
            self:onCharacterDeselected()
        end)

    TotoWar__Gameplay:addListener(
        "TotoWar_Cbac_PlayerManager",
        TotoWar__Enum_GameEvent.characterSelected,
        function()
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
        end,
        ---@param context CharacterSelected
        function(context)
            self:onCharacterSelected(context:character())
        end)

    TotoWar__Gameplay:addListener(
        "TotoWar_Cbac_PlayerManager_InRecruitmentMercenaryUnitCard",
        TotoWar__Enum_GameEvent.componentLeftClick,
        ---@param context TotoWar__GameEventContext_ComponentLeftClick
        function(context)
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
                and context.string:match(TotoWar__Enum_Patterns.inRecruitmentMercenaryUnitCard)
        end,
        ---@param context TotoWar__GameEventContext_ComponentLeftClick
        function(context)
            self:onInRecruitmentMercenaryUniCardClick(context.string)
        end)

    TotoWar__Gameplay:addListener(
        "TotoWar_Cbac_PlayerManager",
        TotoWar__Enum_GameEvent.componentLeftClick,
        ---@param context TotoWar__GameEventContext_ComponentLeftClick
        function(context)
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
                and context.string:match(TotoWar__Enum_Patterns.recruitableMercenaryUnitCard)
        end,
        ---@param context TotoWar__GameEventContext_ComponentLeftClick
        function(context)
            local uiComponent = UIComponent(context.component)
            self:onRecruitableMercenaryUniCardClick(context.string, uiComponent)
        end)

    TotoWar__Gameplay:addListener(
        "TotoWar_Cbac_PlayerManager",
        TotoWar__Enum_GameEvent.componentLeftClick,
        ---@param context TotoWar__GameEventContext_ComponentLeftClick
        function(context)
            if TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
                and (string.match(context.string, TotoWar__Enum_Patterns.unitExchangeHeroCard)
                    or string.match(context.string, TotoWar__Enum_Patterns.unitExchangeUnitCard))
            then
                local uiComponent = UIComponent(context.component)

                return TotoWar__UI:isUIComponentChildOf(uiComponent, { "unit_exchange" })
            end

            return false
        end,
        function()
            self:updateUnitExchangeArmySuppliesCosts()
        end)

    TotoWar__Gameplay:addListener(
        "TotoWar_Cbac_PlayerManager",
        TotoWar__Enum_GameEvent.panelClosed,
        ---@param context TotoWar__GameEventContext_PanelOpenedOrClosed
        function(context)
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
                and context.string == TotoWar__Enum_Panels.mercenaryRecruitment
                and self.selectedLordArmySuppliesCost ~= nil
        end,
        function()
            self:onMercenaryRecruitmentPanelClosed()
        end)

    TotoWar__Gameplay:addListener(
        "TotoWar_Cbac_PlayerManager",
        TotoWar__Enum_GameEvent.panelClosed,
        ---@param context TotoWar__GameEventContext_PanelOpenedOrClosed
        function(context)
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
                and context.string == TotoWar__Enum_Panels.unitExchange
        end,
        ---@param context TotoWar__GameEventContext_PanelOpenedOrClosed
        function(context)
            self:onUnitExchangePanelClosed()
        end)

    TotoWar__Gameplay:addListener(
        "TotoWar_Cbac_PlayerManager",
        TotoWar__Enum_GameEvent.panelOpened,
        ---@param context TotoWar__GameEventContext_PanelOpenedOrClosed
        function(context)
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
                and context.string == TotoWar__Enum_Panels.mercenaryRecruitment
                and self.selectedLordArmySuppliesCost ~= nil
        end,
        function()
            self:onMercenaryRecruitmentPanelOpened()
        end)

    TotoWar__Gameplay:addListener(
        "TotoWar_Cbac_PlayerManager",
        TotoWar__Enum_GameEvent.panelOpened,
        ---@param context TotoWar__GameEventContext_PanelOpenedOrClosed
        function(context)
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
                and context.string == TotoWar__Enum_Panels.unitExchange
        end,
        function()
            self:onUnitExchangePanelOpened()
        end)

    TotoWar__Gameplay:addListener(
        "TotoWar_Cbac_UIManager",
        TotoWar_Cbac_Enum_ModEvent.selectedLordArmySuppliesCostChanged,
        function()
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
        end,
        function()
            self:onSelectedLordArmySuppliesCostChanged()
        end)

    TotoWar__Gameplay:addListener(
        "TotoWar_Cbac_PlayerManager",
        TotoWar__Enum_GameEvent.unitAddedToRecruitment,
        ---@param context TotoWar__GameEventContext_UnitAddedToRecruitment
        function(context)
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
                and context:faction():name() == cm:get_local_faction_name()
        end,
        ---@param context TotoWar__GameEventContext_UnitAddedToRecruitment
        function(context)
            ---@type string
            local unitKey = context:main_unit_record()
            self:onUnitAddedToRecruitment(unitKey, false)
        end)

    TotoWar__Gameplay:addListener(
        "TotoWar_Cbac_PlayerManager",
        TotoWar__Enum_GameEvent.unitDisbanded,
        function()
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
        end,
        ---@param context TotoWar__GameEventContext_UnitDisbanded
        function(context)
            self:onUnitDisbanded(context:unit():unit_key())
        end)

    TotoWar__Gameplay:addListener(
        "TotoWar_Cbac_PlayerManager",
        TotoWar__Enum_GameEvent.unitMergedAndDestroyed,
        function()
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
        end,
        ---@param context TotoWar__GameEventContext_UnitMergedAndDestroyed
        function(context)
            self:onUnitMergedAndDestroyed(context:unit():unit_key())
        end)

    TotoWar__Gameplay:addListener(
        "TotoWar_Cbac_PlayerManager",
        TotoWar__Enum_GameEvent.unitRemovedFromRecruitment,
        ---@param context TotoWar__GameEventContext_UnitRemovedFromRecruitment
        function(context)
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
                and context:faction():name() == cm:get_local_faction_name()
        end,
        ---@param context TotoWar__GameEventContext_UnitRemovedFromRecruitment
        function(context)
            self:onUnitRemovedFromRecruitment(context:main_unit_record())
        end)

    TotoWar__Gameplay:addListener(
        "TotoWar_Cbac_PlayerManager",
        TotoWar__Enum_GameEvent.unitTrained,
        function()
            return
            -- When the UnitTrained event is triggered while an army is selected, it means that we have
            -- clicked on the mercenary panel recruitment button
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
                and self.selectedLordArmySuppliesCost ~= nil
        end,
        ---@param context TotoWar__GameEventContext_UnitTrained
        function(context)
            local unit = context:unit()
            self:onMercenaryUnitsRecruited(unit:unit_key(), unit:command_queue_index())
        end)

    TotoWar_Cbac.loggers.playerManager:logDebug("addListeners(): COMPLETED")
end

---Clears the list of in-recruitment mercenary units supply costs.
function TotoWar_Cbac_PlayerManager:clearMercenaryRecruitment()
    TotoWar_Cbac.loggers.playerManager:logDebug("clearMercenaryRecruitment(): STARTED")

    if #self.selectedLordArmySuppliesCost.inRecruitmentMercenaryUnits > 0 then
        self.selectedLordArmySuppliesCost:clearMercenaryRecruitment()

        -- Signaling army supplies cost change
        core:trigger_event(TotoWar_Cbac_Enum_ModEvent.selectedLordArmySuppliesCostChanged)
    end

    TotoWar_Cbac.loggers.playerManager:logDebug("clearMercenaryRecruitment(): COMPLETED")
end

---Initializes the army supplies cost of the army of the selected lord.
---@param lord CHARACTER_SCRIPT_INTERFACE Selected lord.
function TotoWar_Cbac_PlayerManager:initializeArmySuppliesCost(lord)
    TotoWar_Cbac.loggers.playerManager:logDebug(
        "initializeArmySuppliesCost(%s): STARTED",
        function() return TotoWar__Gameplay:getCharacterCaption(lord) end)

    self.selectedLordArmySuppliesCost = TotoWar_Cbac_ArmySuppliesCost.newFromArmy(false, lord:military_force())

    -- Adding units being recruited in the lord army
    local unitsUIComponent = TotoWar__UI:getUIComponent(TotoWar__UI.uiComponentQueries.unitsPanelUnits)

    if unitsUIComponent ~= nil then
        -- Adding units from the recruitment queue
        for i = unitsUIComponent:ChildCount() - 1, 0, -1 do
            -- Iterating from the last unit card since units being recruited are at the end
            local unitCardUIComponent = find_child_uicomponent_by_index(unitsUIComponent, i)

            if not unitCardUIComponent:Id():match(TotoWar__Enum_Patterns.inRecruitmentStandardUnitCard)
            then
                -- Stopping the iteration as soon as we encounter a unit that is not being recruited
                break
            end

            local cardImageHolderUIComponent = TotoWar__UI:getUIComponentChild(unitCardUIComponent,
                { "card_image_holder" })

            if cardImageHolderUIComponent ~= nil then
                local unitContext = TotoWar__UI:getUIComponentCCO(
                    cardImageHolderUIComponent,
                    TotoWar__Enum_CcoContextTypeIds.mainUnitRecord)

                ---@type string
                local unitKey = unitContext:Call("Key")
                self.selectedLordArmySuppliesCost:addUnit(unitKey)
            end
        end
    end

    self.isInitializingArmySuppliesCost = false

    -- Signaling army supplies cost change
    core:trigger_event(TotoWar_Cbac_Enum_ModEvent.selectedLordArmySuppliesCostChanged)

    TotoWar_Cbac.loggers.playerManager:logDebug(
        "initializeArmySuppliesCost(%s): COMPLETED => %s",
        function() return TotoWar__Gameplay:getCharacterCaption(lord) end,
        function() return self.selectedLordArmySuppliesCost.totalCost end)
end

---Reacts to a character being deselected.
function TotoWar_Cbac_PlayerManager:onCharacterDeselected()
    TotoWar_Cbac.loggers.playerManager:logDebug("onCharacterDeselected(): STARTED")

    if self.selectedLord then
        cm:enable_movement_for_character("character_cqi:" .. self.selectedLord:cqi())
        self.selectedLord = nil
        self.selectedLordArmySuppliesCost = nil
    end

    TotoWar_Cbac.loggers.playerManager:logDebug("onCharacterDeselected(): COMPLETED")
end

---Reacts to a character being selected.
---@param character CHARACTER_SCRIPT_INTERFACE Selected character.
function TotoWar_Cbac_PlayerManager:onCharacterSelected(character)
    TotoWar_Cbac.loggers.playerManager:logDebug(
        "onCharacterSelected(%s from %s): STARTED",
        function() return TotoWar__Gameplay:getCharacterCaption(character) end,
        function() return TotoWar__Gameplay:getFactionCaption(character:faction():name()) end)

    if TotoWar__Gameplay:isLordCharacter(character)
        and (TotoWar__Gameplay:isPlayerFaction(character:faction():name())
            or TotoWar.options.debugEnabled) -- In debug mode, we see the army supplies cost or other faction lords
    then
        self.selectedLord = character
        self.isInitializingArmySuppliesCost = true

        if cm:get_campaign_ui_manager():is_panel_open(TotoWar__Enum_Panels.unitsPanel) then
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
            TotoWar__Gameplay:addListener(
                "TotoWar_Cbac_PlayerManager_UnitsPanel",
                TotoWar__Enum_GameEvent.panelOpened,
                ---@param context TotoWar__GameEventContext_PanelOpenedOrClosed
                function(context)
                    return context.string == TotoWar__Enum_Panels.unitsPanel
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

    TotoWar_Cbac.loggers.playerManager:logDebug(
        "onCharacterSelected(%s from %s): COMPLETED",
        function() return TotoWar__Gameplay:getCharacterCaption(character) end,
        function() return TotoWar__Gameplay:getFactionCaption(character:faction():name()) end)
end

---Reacts to the click on the unit card of a mercenary unit in the selected army recruitment queue.
---@param uiComponentName string Name of the clicked UI component.
function TotoWar_Cbac_PlayerManager:onInRecruitmentMercenaryUniCardClick(uiComponentName)
    TotoWar_Cbac.loggers.playerManager:logDebug(
        "onInRecruitmentMercenaryUniCardClick(%s): STARTED",
        function() return uiComponentName end)

    self.selectedLordArmySuppliesCost:removeUnit(uiComponentName)

    -- Signaling army supplies cost change
    core:trigger_event(TotoWar_Cbac_Enum_ModEvent.selectedLordArmySuppliesCostChanged)

    TotoWar_Cbac.loggers.playerManager:logDebug(
        "onInRecruitmentMercenaryUniCardClick(%s): COMPLETED",
        function() return uiComponentName end)
end

---Reacts to the mercenary recruitment panel being closed.
function TotoWar_Cbac_PlayerManager:onMercenaryRecruitmentPanelClosed()
    TotoWar_Cbac.loggers.playerManager:logDebug("onMercenaryRecruitmentPanelClosed(): STARTED")

    if #self.selectedLordArmySuppliesCost.inRecruitmentMercenaryUnits > 0 then
        self.selectedLordArmySuppliesCost:clearMercenaryRecruitment()

        -- Signaling army supplies cost change
        core:trigger_event(TotoWar_Cbac_Enum_ModEvent.selectedLordArmySuppliesCostChanged)
    end

    TotoWar_Cbac.loggers.playerManager:logDebug("onMercenaryRecruitmentPanelClosed(): COMPLETED")
end

---Reacts to the mercenary recruitment panel being opened or closed.
function TotoWar_Cbac_PlayerManager:onMercenaryRecruitmentPanelOpened()
    TotoWar_Cbac.loggers.playerManager:logDebug("onMercenaryRecruitmentPanelOpened(): STARTED")

    self:clearMercenaryRecruitment()

    TotoWar_Cbac.loggers.playerManager:logDebug("onMercenaryRecruitmentPanelOpened(): COMPLETED")
end

---Reacts to a mercenary unit being recruited in the selected lord army.
---@param unitKey string Unit key.
---@param cqi integer Unit command queue index.
function TotoWar_Cbac_PlayerManager:onMercenaryUnitsRecruited(unitKey, cqi)
    TotoWar_Cbac.loggers.playerManager:logDebug(
        "onMercenaryUnitRecruited(%s): STARTED",
        function() return TotoWar__Gameplay:getUnitCaption(unitKey) end)

    self.selectedLordArmySuppliesCost:addUnit(unitKey, cqi)

    -- Signaling army supplies cost change
    core:trigger_event(TotoWar_Cbac_Enum_ModEvent.selectedLordArmySuppliesCostChanged)

    TotoWar_Cbac.loggers.playerManager:logDebug(
        "onMercenaryUnitRecruited(%s): COMPLETED",
        function() return TotoWar__Gameplay:getUnitCaption(unitKey) end)
end

---Reacts to the click on the unit card of a recruitable mercenary unit.
---@param uiComponentName string Name of the clicked UI component.
---@param unitUIComponent UIC Clicked UI component.
function TotoWar_Cbac_PlayerManager:onRecruitableMercenaryUniCardClick(uiComponentName, unitUIComponent)
    TotoWar_Cbac.loggers.playerManager:logDebug(
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
    local unitsUIComponent = TotoWar__UI:getUIComponent(TotoWar__UI.uiComponentQueries.unitsPanelUnits)

    if unitsUIComponent ~= nil then
        for i = unitsUIComponent:ChildCount() - 1, 0, -1 do
            -- Iterating from the last unit card since units being recruited are at the end
            local unitCardUIComponent = find_child_uicomponent_by_index(unitsUIComponent, i)

            if not unitCardUIComponent:Id():match(TotoWar__Enum_Patterns.inRecruitmentMercenaryUnitCard)
            then
                -- Stopping the iteration as soon as we encounter a unit that is not a mercenary unit being recruited
                break
            end

            inRecruitmentMercenaryUnitCount = inRecruitmentMercenaryUnitCount + 1
        end
    end

    TotoWar_Cbac.loggers.playerManager:logDebug(
        "onRecruitableMercenaryUniCardClick(%s): %s mercenary units in the recruitment pool | %s mercenary units tracked in the army supplies cost",
        function() return uiComponentName end,
        function() return inRecruitmentMercenaryUnitCount end,
        function() return #self.selectedLordArmySuppliesCost.inRecruitmentMercenaryUnits end)

    if inRecruitmentMercenaryUnitCount > #self.selectedLordArmySuppliesCost.inRecruitmentMercenaryUnits then
        local unitContext = TotoWar__UI:getUIComponentCCO(
            unitUIComponent,
            TotoWar__Enum_CcoContextTypeIds.mainUnitRecord)

        ---@type string
        local unitKey = unitContext:Call("Key")
        self:onUnitAddedToRecruitment(unitKey, true)
    end

    TotoWar_Cbac.loggers.playerManager:logDebug(
        "onRecruitableMercenaryUniCardClick(%s): COMPLETED",
        function() return uiComponentName end)
end

---Reacts to the army supplies cost of the selected lord changing.
function TotoWar_Cbac_PlayerManager:onSelectedLordArmySuppliesCostChanged()
    if not self.selectedLord then
        return
    end

    TotoWar_Cbac.loggers.playerManager:logDebug("onSelectedLordArmySuppliesCostChanged(): STARTED")

    local needsSelectedLordMovementUpdate = true

    if TotoWar.options.debugEnabled then
        -- In debug mode, if we select a lord from another faction, we see the army supplies cost
        -- but we do not want to block the army movement
        needsSelectedLordMovementUpdate = TotoWar__Gameplay:isPlayerFaction(self.selectedLord:faction():name())
    end

    if needsSelectedLordMovementUpdate then
        self:updatedSelectedLordMovement()
    end

    TotoWar_Cbac.loggers.playerManager:logDebug("onSelectedLordArmySuppliesCostChanged(): COMPLETED")
end

---Reacts to a unit being added to the recruitment queue of the selected lord army.
---@param unitKey string Unit key.
---@param isMercenary boolean Indicates whether the unit added to recruitment is a mercenary unit (regiment of renown, Grudge settles, Waaagh mobs, ...).
function TotoWar_Cbac_PlayerManager:onUnitAddedToRecruitment(unitKey, isMercenary)
    TotoWar_Cbac.loggers.playerManager:logDebug(
        "onUnitAddedToRecruitment(%s, %s): STARTED",
        function() return TotoWar__Gameplay:getUnitCaption(unitKey) end,
        function() return isMercenary end)

    self.selectedLordArmySuppliesCost:addUnit(unitKey, nil, isMercenary)

    -- Signaling army supplies cost change
    core:trigger_event(TotoWar_Cbac_Enum_ModEvent.selectedLordArmySuppliesCostChanged)

    TotoWar_Cbac.loggers.playerManager:logDebug(
        "onUnitAddedToRecruitment(%s, %s): COMPLETED",
        function() return TotoWar__Gameplay:getUnitCaption(unitKey) end,
        function() return isMercenary end)
end

---Reacts to a unit being disbanded.
---@param unitKey string Unit key
function TotoWar_Cbac_PlayerManager:onUnitDisbanded(unitKey)
    TotoWar_Cbac.loggers.playerManager:logDebug(
        "onUnitDisbanded(%s): STARTED",
        function() return TotoWar__Gameplay:getUnitCaption(unitKey) end)

    self.selectedLordArmySuppliesCost:removeUnit(unitKey)

    -- Signaling army supplies cost change
    core:trigger_event(TotoWar_Cbac_Enum_ModEvent.selectedLordArmySuppliesCostChanged)

    TotoWar_Cbac.loggers.playerManager:logDebug(
        "onUnitDisbanded(%s): COMPLETED",
        function() return TotoWar__Gameplay:getUnitCaption(unitKey) end)
end

---Reacts to the unit exchange panel being closed.
function TotoWar_Cbac_PlayerManager:onUnitExchangePanelClosed()
    TotoWar_Cbac.loggers.playerManager:logDebug("onUnitExchangePanelClosed(): STARTED")

    self.unitExchangeArmySuppliesCost1 = nil
    self.unitExchangeArmySuppliesCost2 = nil

    TotoWar_Cbac.loggers.playerManager:logDebug("onUnitExchangePanelClosed(): COMPLETED")
end

---Reacts to the unit exchange panel being opened.
function TotoWar_Cbac_PlayerManager:onUnitExchangePanelOpened()
    TotoWar_Cbac.loggers.playerManager:logDebug("onUnitExchangePanelOpened(): STARTED")

    self:updateUnitExchangeArmySuppliesCosts()

    TotoWar_Cbac.loggers.playerManager:logDebug("onUnitExchangePanelOpened(): COMPLETED")
end

---Reacts to a unit card in the first army unit exchange pool being clicked.
function TotoWar_Cbac_PlayerManager:onUnitExchangePoolUnitCardClick()
    TotoWar_Cbac.loggers.playerManager:logDebug("onUnitExchangePoolUnitCardClick(): STARTED")

    -- Each time a unit exchange unit card is clicked, we need to go through each unit exchange pool
    -- to see which units are selected and which are not.
    -- This is because the user can select multiple unit cards at once using SHIFT + Click,
    -- we have no other way to know which cards have been added to the selection.
    self:updateUnitExchangeArmySuppliesCosts()

    TotoWar_Cbac.loggers.playerManager:logDebug("onUnitExchangePoolUnitCardClick(): COMPLETED")
end

---Reacts to a unit being destroyed after having been merged with another unit.
---@param unitKey string Unit key.
function TotoWar_Cbac_PlayerManager:onUnitMergedAndDestroyed(unitKey)
    TotoWar_Cbac.loggers.playerManager:logDebug(
        "onUnitMergedAndDestroyed(%s): STARTED",
        function() return TotoWar__Gameplay:getUnitCaption(unitKey) end)

    self.selectedLordArmySuppliesCost:removeUnit(unitKey)

    -- Signaling army supplies cost change
    core:trigger_event(TotoWar_Cbac_Enum_ModEvent.selectedLordArmySuppliesCostChanged)

    TotoWar_Cbac.loggers.playerManager:logDebug(
        "onUnitMergedAndDestroyed(%s): COMPLETED",
        function() return TotoWar__Gameplay:getUnitCaption(unitKey) end)
end

---Reacts to a unit being removed from the recruitment queue of the selected lord army.
function TotoWar_Cbac_PlayerManager:onUnitRemovedFromRecruitment(unitKey)
    TotoWar_Cbac.loggers.playerManager:logDebug(
        "onUnitRemovedFromRecruitment(%s): STARTED",
        function() return TotoWar__Gameplay:getUnitCaption(unitKey) end)

    self.selectedLordArmySuppliesCost:removeUnit(unitKey)

    -- Signaling army supplies cost change
    core:trigger_event(TotoWar_Cbac_Enum_ModEvent.selectedLordArmySuppliesCostChanged)

    TotoWar_Cbac.loggers.playerManager:logDebug(
        "onUnitRemovedFromRecruitment(%s): COMPLETED",
        function() return TotoWar__Gameplay:getUnitCaption(unitKey) end)
end

---Updates unit exchange army supplies costs.
function TotoWar_Cbac_PlayerManager:updateUnitExchangeArmySuppliesCosts()
    TotoWar_Cbac.loggers.playerManager:logDebug("updateUnitExchangeArmySuppliesCosts(): STARTED")

    local unitExchangePool1UIComponent = TotoWar__UI:getUIComponent(
        TotoWar__UI.uiComponentQueries.unitExchangePool1)
    local unitExchangePool2UIComponent = TotoWar__UI:getUIComponent(
        TotoWar__UI.uiComponentQueries.unitExchangePool2)

    local lord1 = TotoWar_Cbac_UIManager:getLordInUnitExchangePool(unitExchangePool1UIComponent)
    local lord1Rank = 1
    local lord2 = TotoWar_Cbac_UIManager:getLordInUnitExchangePool(unitExchangePool2UIComponent)
    local lord2Rank = 1

    if lord1 ~= nil then
        lord1Rank = lord1:rank()
    end

    if lord2 ~= nil then
        lord2Rank = lord2:rank()
    end

    self.unitExchangeArmySuppliesCost1 = TotoWar_Cbac_ArmySuppliesCost.new(false, lord1Rank)
    TotoWar_Cbac_UIManager:updateUnitExchangeArmySuppliesCost(
        unitExchangePool1UIComponent,
        self.unitExchangeArmySuppliesCost1,
        self.unitExchangeArmySuppliesCost2)

    self.unitExchangeArmySuppliesCost2 = TotoWar_Cbac_ArmySuppliesCost.new(false, lord2Rank)
    TotoWar_Cbac_UIManager:updateUnitExchangeArmySuppliesCost(
        unitExchangePool2UIComponent,
        self.unitExchangeArmySuppliesCost2,
        self.unitExchangeArmySuppliesCost1)

    -- Signaling unit exchange army supplies cost change
    core:trigger_event(TotoWar_Cbac_Enum_ModEvent.unitExchangeArmySuppliesCostChanged)

    TotoWar_Cbac.loggers.playerManager:logDebug("updateUnitExchangeArmySuppliesCosts(): COMPLETED")
end

---Updates the ability to move of the selected lord depending on the army supplies cost of its army.
function TotoWar_Cbac_PlayerManager:updatedSelectedLordMovement()
    TotoWar_Cbac.loggers.playerManager:logDebug("updatedSelectedLordMovement(): STARTED")

    if self.selectedLordArmySuppliesCost.availableSupplies < 0 then
        TotoWar_Cbac.loggers.playerManager:logDebug(
            "updatedSelectedLordMovement(): BLOCKED => %s",
            function() return TotoWar__Gameplay:getCharacterCaption(self.selectedLord) end)

        cm:disable_movement_for_character(cm:char_lookup_str(self.selectedLord:cqi()))

        -- Reactivating movement for heroes contained in the army as they should be able to leave the army
        local selectedLordArmyCharacters = self.selectedLord:military_force():character_list()

        for i = 0, selectedLordArmyCharacters:num_items() - 1, 1 do
            local character = selectedLordArmyCharacters:item_at(i)

            if not TotoWar__Gameplay:isLordCharacter(character) then
                TotoWar_Cbac.loggers.playerManager:logDebug(
                    "updatedSelectedLordMovement(): REACTIVATING MOVEMENT FOR HERO => %s",
                    function() return TotoWar__Gameplay:getCharacterCaption(character) end)

                cm:enable_movement_for_character(cm:char_lookup_str(character:cqi()))
            end
        end
    else
        TotoWar_Cbac.loggers.playerManager:logDebug(
            "updatedSelectedLordMovement(): FREE TO MOVE => %s",
            function() return TotoWar__Gameplay:getCharacterCaption(self.selectedLord) end)

        cm:enable_movement_for_character("character_cqi:" .. self.selectedLord:cqi())
    end

    TotoWar_Cbac.loggers.playerManager:logDebug("updatedSelectedLordMovement(): COMPLETED")
end
