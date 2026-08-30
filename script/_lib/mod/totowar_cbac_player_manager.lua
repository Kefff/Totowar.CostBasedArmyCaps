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
    unitExchangeArmySuppliesCost2 = nil,

    ---Army supplies cost of the warband upgrade screen.
    ---@type TotoWar_Cbac_ArmySuppliesCost | nil
    warbandUpgradeArmySuppliesCost = nil
}
TotoWar_Cbac_PlayerManager.__index = TotoWar_Cbac_PlayerManager

---Initializes a new instance.
---@return TotoWar_Cbac_PlayerManager
function TotoWar_Cbac_PlayerManager.new()
    TotoWar_Cbac.loggers.playerManager:logDebug("new(): STARTED")

    local instance = setmetatable({}, TotoWar_Cbac_PlayerManager)

    instance:subscribeToEvents()

    TotoWar_Cbac.loggers.playerManager:logDebug("new(): COMPLETED")

    return instance
end

---Clears the list of in-recruitment mercenary units supply costs.
function TotoWar_Cbac_PlayerManager:clearMercenaryRecruitment()
    TotoWar_Cbac.loggers.playerManager:logDebug("clearMercenaryRecruitment(): STARTED")

    if #self.selectedLordArmySuppliesCost.inRecruitmentMercenaryUnits > 0 then
        self.selectedLordArmySuppliesCost:clearMercenaryRecruitment()

        -- Signaling army supplies cost change
        TotoWar.eventsManager:trigger(TotoWar_Cbac_Enum_ModEvents.selectedLordArmySuppliesCostChanged)
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
    local unitsUIComponent = TotoWar__UI:getUIComponent(TotoWar__UI.uiComponentQueries.unitsPanel_units)

    -- Adding units from the recruitment queue
    for i = unitsUIComponent:ChildCount() - 1, 0, -1 do
        -- Iterating from the last unit card since units being recruited are at the end
        local unitCardUIComponent = find_child_uicomponent_by_index(unitsUIComponent, i)
        local isInRecruitmentStandardUnitCard =
            unitCardUIComponent:Id():match(TotoWar__Enum_Patterns.inRecruitmentStandardUnitCard) ~= nil

        if not isInRecruitmentStandardUnitCard
        then
            -- Stopping the iteration as soon as we encounter a unit that is not being recruited
            break
        end

        local cardImageHolderUIComponent = TotoWar__UI:getUIComponentChild(
            unitCardUIComponent,
            { "card_image_holder" })
        local unitContext = TotoWar__UI:getUIComponentCCO(
            cardImageHolderUIComponent,
            TotoWar__Enum_CcoContextTypeIds.mainUnitRecord)

        ---@type string
        local unitKey = unitContext:Call("Key")
        self.selectedLordArmySuppliesCost:addUnit(unitKey)
    end

    self.isInitializingArmySuppliesCost = false

    -- Signaling army supplies cost change
    TotoWar.eventsManager:trigger(TotoWar_Cbac_Enum_ModEvents.selectedLordArmySuppliesCostChanged)

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
        and (TotoWar__Gameplay:isLocalPlayerFaction(character:faction():name())
            or TotoWar.options.debugEnabled) -- In debug mode, we see the army supplies cost or other faction lords
    then
        self.selectedLord = character
        self.isInitializingArmySuppliesCost = true

        if cm:get_campaign_ui_manager():is_panel_open(TotoWar__Enum_Panels.unitsPanel) then
            -- Delay otherwise the units_panel is not up to date and still contains the units of the previously selected lord army
            TotoWar__Utils:delay(
                function()
                    --- Initializing the army supplies cost for the newly selected army
                    self:initializeArmySuppliesCost(character)
                end,
                0.25)
        else
            --- Adding a one-time listener that waits for the unit_panel to open before
            --- initializing the army supplies cost because we need to get the cost of the
            --- units being recruited
            TotoWar.eventsManager:subscribe(
                TotoWar__Enum_GameEvents.panelOpened,
                function() self:initializeArmySuppliesCost(character) end,
                ---@param context TotoWar__GameEventContext_PanelOpenedOrClosed
                function(context) return context.string == TotoWar__Enum_Panels.unitsPanel end,
                1)
        end
    elseif self.selectedLordArmySuppliesCost then
        self.selectedLord = nil
        self.selectedLordArmySuppliesCost = nil

        -- Signaling army supplies cost change.
        -- This is only useful in the case we the player has one of its armies selected
        -- and selects on of its isolated heroes.
        -- In this case, the units panel is not closed and the CharactedDeselected event is not triggered by the game.
        -- So we set selectedLordArmySuppliesCost to nil and we still trigger the selectedLordArmySuppliesCostChanged
        -- event to make the UI manager react.
        -- In this case, it will hide the army supplies because selectedLordArmySuppliesCost is nil.
        TotoWar.eventsManager:trigger(TotoWar_Cbac_Enum_ModEvents.selectedLordArmySuppliesCostChanged)
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
    TotoWar.eventsManager:trigger(TotoWar_Cbac_Enum_ModEvents.selectedLordArmySuppliesCostChanged)

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
        TotoWar.eventsManager:trigger(TotoWar_Cbac_Enum_ModEvents.selectedLordArmySuppliesCostChanged)
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
    TotoWar.eventsManager:trigger(TotoWar_Cbac_Enum_ModEvents.selectedLordArmySuppliesCostChanged)

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
    local unitsUIComponent = TotoWar__UI:getUIComponent(TotoWar__UI.uiComponentQueries.unitsPanel_units)

    for i = unitsUIComponent:ChildCount() - 1, 0, -1 do
        -- Iterating from the last unit card since units being recruited are at the end
        local unitCardUIComponent = find_child_uicomponent_by_index(unitsUIComponent, i)
        local isMercenaryUnitCard =
            unitCardUIComponent:Id():match(TotoWar__Enum_Patterns.inRecruitmentMercenaryUnitCard) ~= nil

        if not isMercenaryUnitCard
        then
            -- Stopping the iteration as soon as we encounter a unit that is not a mercenary unit being recruited
            break
        end

        inRecruitmentMercenaryUnitCount = inRecruitmentMercenaryUnitCount + 1
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
    if self.selectedLord == nil then
        return
    end

    TotoWar_Cbac.loggers.playerManager:logDebug("onSelectedLordArmySuppliesCostChanged(): STARTED")

    local needsSelectedLordMovementUpdate = true

    if TotoWar.options.debugEnabled then
        -- In debug mode, if we select a lord from another faction, we see the army supplies cost
        -- but we do not want to block the army movement
        needsSelectedLordMovementUpdate = TotoWar__Gameplay:isLocalPlayerFaction(self.selectedLord:faction():name())
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
    TotoWar.eventsManager:trigger(TotoWar_Cbac_Enum_ModEvents.selectedLordArmySuppliesCostChanged)

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
    TotoWar.eventsManager:trigger(TotoWar_Cbac_Enum_ModEvents.selectedLordArmySuppliesCostChanged)

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
    TotoWar.eventsManager:trigger(TotoWar_Cbac_Enum_ModEvents.selectedLordArmySuppliesCostChanged)

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
    TotoWar.eventsManager:trigger(TotoWar_Cbac_Enum_ModEvents.selectedLordArmySuppliesCostChanged)

    TotoWar_Cbac.loggers.playerManager:logDebug(
        "onUnitRemovedFromRecruitment(%s): COMPLETED",
        function() return TotoWar__Gameplay:getUnitCaption(unitKey) end)
end

---Reacts to the "Upgrade" button in the Warband Upgrade pnael being clicked.
function TotoWar_Cbac_PlayerManager:onWarbandUpgradeButtonClicked()
    TotoWar_Cbac.loggers.playerManager:logDebug("onWarbandUpgradeButtonClicked(): STARTED")

    -- Delay used here to allow the unit list to be updated before updating the army supplies
    TotoWar__Utils:delay(
        function() self:initializeArmySuppliesCost(self.selectedLord) end,
        0.1)

    TotoWar_Cbac.loggers.playerManager:logDebug("onWarbandUpgradeButtonClicked(): COMPLETED")
end

---Reacts to a unit card or a warband upgrade being clicked when the Warband Upgrade panel is open.
function TotoWar_Cbac_PlayerManager:onWarbandUpgradeUnitClicked()
    TotoWar_Cbac.loggers.playerManager:logDebug("onWarbandUpgradeUnitClicked(): STARTED")

    self:updateWarbandUpgradeArmySupplies()

    TotoWar_Cbac.loggers.playerManager:logDebug("onWarbandUpgradeUnitClicked(): COMPLETED")
end

---Subscribes to events.
function TotoWar_Cbac_PlayerManager:subscribeToEvents()
    TotoWar_Cbac.loggers.playerManager:logDebug("subscribeToEvents(): STARTED")

    TotoWar.eventsManager:subscribe(
        TotoWar__Enum_GameEvents.characterDeselected,
        function() self:onCharacterDeselected() end,
        function()
            -- We do not check the TotoWar_Cbac.options.playerArmySuppliesEnabled option because when this option
            -- is disabled, we deselect everything and we want onCharacterDeselected to be executed
            -- to reset army movement. This avoids having the last selected army unable to move after
            -- disabling the option.
            return cm:is_local_players_turn(true)
        end)

    TotoWar.eventsManager:subscribe(
        TotoWar__Enum_GameEvents.characterSelected,
        ---@param context CharacterSelected
        function(context) self:onCharacterSelected(context:character()) end,
        function()
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn(true)
        end)

    TotoWar.eventsManager:subscribe(
        TotoWar__Enum_GameEvents.componentLeftClick,
        ---@param context TotoWar__GameEventContext_ComponentLeftClick
        function(context) self:onInRecruitmentMercenaryUniCardClick(context.string) end,
        ---@param context TotoWar__GameEventContext_ComponentLeftClick
        function(context)
            local isInRecruitmentMercenaryUnitCard =
                context.string:match(TotoWar__Enum_Patterns.inRecruitmentMercenaryUnitCard) ~= nil

            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn(true)
                and isInRecruitmentMercenaryUnitCard
        end)

    TotoWar.eventsManager:subscribe(
        TotoWar__Enum_GameEvents.componentLeftClick,
        ---@param context TotoWar__GameEventContext_ComponentLeftClick
        function(context)
            local uiComponent = UIComponent(context.component)
            self:onRecruitableMercenaryUniCardClick(context.string, uiComponent)
        end,
        ---@param context TotoWar__GameEventContext_ComponentLeftClick
        function(context)
            local isRecruitableMercenaryUnitCard =
                context.string:match(TotoWar__Enum_Patterns.recruitableMercenaryUnitCard) ~= nil

            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn(true)
                and isRecruitableMercenaryUnitCard
        end)

    TotoWar.eventsManager:subscribe(
        TotoWar__Enum_GameEvents.componentLeftClick,
        function() self:onWarbandUpgradeUnitClicked() end,
        ---@param context TotoWar__GameEventContext_ComponentLeftClick
        function(context)
            if self.selectedLord == nil then
                return false
            end

            local warbandUpgradesUIComponent = TotoWar__UI:findUIComponent(
                TotoWar__UI.uiComponentQueries.unitsPanel_warbandUpgrades)
            local isStandardUnitCard = context.string:match(TotoWar__Enum_Patterns.standardUnitCard) ~= nil
            local isWarbandUpgrade =
                TotoWar__String:startsWith(context.string, "CcoMainUnitRecord")
                and TotoWar__UI:isUIComponentChildOf(
                    UIComponent(context.component),
                    { "warband_upgrades", "body", "upgrade_tree", "slot_parent" })

            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn(true)
                and warbandUpgradesUIComponent ~= nil
                and warbandUpgradesUIComponent:Visible(true)
                and (isStandardUnitCard or isWarbandUpgrade)
        end)

    TotoWar.eventsManager:subscribe(
        TotoWar__Enum_GameEvents.componentLeftClick,
        function() self:onWarbandUpgradeButtonClicked() end,
        ---@param context TotoWar__GameEventContext_ComponentLeftClick
        function(context)
            if self.selectedLord == nil then
                return false
            end

            local warbandUpgradesUIComponent = TotoWar__UI:findUIComponent(
                TotoWar__UI.uiComponentQueries.unitsPanel_warbandUpgrades)

            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn(true)
                and warbandUpgradesUIComponent ~= nil
                and warbandUpgradesUIComponent:Visible(true)
                and context.string == "button_invoke"
                and TotoWar__UI:isUIComponentChildOf(
                    UIComponent(context.component),
                    {
                        "warband_upgrades",
                        "body",
                        "info_holder",
                        "upgrade_info_holder",
                        "unit_info_costs",
                        "holder_requirements"
                    })
        end)

    TotoWar.eventsManager:subscribe(
        TotoWar__Enum_GameEvents.componentLeftClick,
        function() self:updateUnitExchangeArmySuppliesCosts() end,
        ---@param context TotoWar__GameEventContext_ComponentLeftClick
        function(context)
            if TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn(true)
                and (string.match(context.string, TotoWar__Enum_Patterns.unitExchangeHeroCard)
                    or string.match(context.string, TotoWar__Enum_Patterns.unitExchangeUnitCard))
            then
                local uiComponent = UIComponent(context.component)

                return TotoWar__UI:isUIComponentChildOf(uiComponent, { "unit_exchange" })
            end

            return false
        end)

    TotoWar.eventsManager:subscribe(
        TotoWar__Enum_GameEvents.panelClosed,
        function() self:onMercenaryRecruitmentPanelClosed() end,
        ---@param context TotoWar__GameEventContext_PanelOpenedOrClosed
        function(context)
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn(true)
                and context.string == TotoWar__Enum_Panels.mercenaryRecruitment
                and self.selectedLordArmySuppliesCost ~= nil
        end)

    TotoWar.eventsManager:subscribe(
        TotoWar__Enum_GameEvents.panelClosed,
        function() self:onUnitExchangePanelClosed() end,
        ---@param context TotoWar__GameEventContext_PanelOpenedOrClosed
        function(context)
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn(true)
                and context.string == TotoWar__Enum_Panels.unitExchange
        end)

    TotoWar.eventsManager:subscribe(
        TotoWar__Enum_GameEvents.panelOpened,
        function() self:onMercenaryRecruitmentPanelOpened() end,
        ---@param context TotoWar__GameEventContext_PanelOpenedOrClosed
        function(context)
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn(true)
                and context.string == TotoWar__Enum_Panels.mercenaryRecruitment
                and self.selectedLordArmySuppliesCost ~= nil
        end)

    TotoWar.eventsManager:subscribe(
        TotoWar__Enum_GameEvents.panelOpened,
        function() self:onUnitExchangePanelOpened() end,
        ---@param context TotoWar__GameEventContext_PanelOpenedOrClosed
        function(context)
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn(true)
                and context.string == TotoWar__Enum_Panels.unitExchange
        end)

    TotoWar.eventsManager:subscribe(
        TotoWar_Cbac_Enum_ModEvents.selectedLordArmySuppliesCostChanged,
        function() self:onSelectedLordArmySuppliesCostChanged() end,
        function()
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn(true)
        end)

    TotoWar.eventsManager:subscribe(
        TotoWar__Enum_GameEvents.unitAddedToRecruitment,
        ---@param context TotoWar__GameEventContext_UnitAddedToRecruitment
        function(context)
            ---@type string
            local unitKey = context:main_unit_record()
            self:onUnitAddedToRecruitment(unitKey, false)
        end,
        ---@param context TotoWar__GameEventContext_UnitAddedToRecruitment
        function(context)
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn(true)
                and TotoWar__Gameplay:isLocalPlayerFaction(context:faction():name())
        end)

    TotoWar.eventsManager:subscribe(
        TotoWar__Enum_GameEvents.unitDisbanded,
        ---@param context TotoWar__GameEventContext_UnitDisbanded
        function(context) self:onUnitDisbanded(context:unit():unit_key()) end,
        ---@param context TotoWar__GameEventContext_UnitDisbanded
        function(context)
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn(true)
                and TotoWar__Gameplay:isLocalPlayerFaction(context:unit():military_force():faction():name())
        end)

    TotoWar.eventsManager:subscribe(
        TotoWar__Enum_GameEvents.unitMergedAndDestroyed,
        ---@param context TotoWar__GameEventContext_UnitMergedAndDestroyed
        function(context) self:onUnitMergedAndDestroyed(context:unit():unit_key()) end,
        ---@param context TotoWar__GameEventContext_UnitDisbanded
        function(context)
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn(true)
                and TotoWar__Gameplay:isLocalPlayerFaction(context:unit():military_force():faction():name())
        end)

    TotoWar.eventsManager:subscribe(
        TotoWar__Enum_GameEvents.unitRemovedFromRecruitment,
        ---@param context TotoWar__GameEventContext_UnitRemovedFromRecruitment
        function(context) self:onUnitRemovedFromRecruitment(context:main_unit_record()) end,
        ---@param context TotoWar__GameEventContext_UnitRemovedFromRecruitment
        function(context)
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn(true)
                and TotoWar__Gameplay:isLocalPlayerFaction(context:faction():name())
        end)

    TotoWar.eventsManager:subscribe(
        TotoWar__Enum_GameEvents.unitTrained,
        ---@param context TotoWar__GameEventContext_UnitTrained
        function(context)
            local unit = context:unit()
            self:onMercenaryUnitsRecruited(unit:unit_key(), unit:command_queue_index())
        end,
        ---@param context TotoWar__GameEventContext_UnitTrained
        function(context)
            -- When the UnitTrained event is triggered while an army is selected, it means that we have
            -- clicked on the mercenary panel recruitment button
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn(true)
                and TotoWar__Gameplay:isLocalPlayerFaction(context:unit():military_force():faction():name())
                and self.selectedLordArmySuppliesCost ~= nil
        end)

    TotoWar_Cbac.loggers.playerManager:logDebug("subscribeToEvents(): COMPLETED")
end

---Updates unit exchange army supplies costs.
function TotoWar_Cbac_PlayerManager:updateUnitExchangeArmySuppliesCosts()
    TotoWar_Cbac.loggers.playerManager:logDebug("updateUnitExchangeArmySuppliesCosts(): STARTED")

    local unitExchangePool1UIComponent = TotoWar__UI:getUIComponent(
        TotoWar__UI.uiComponentQueries.unitExchange_pool1)
    local unitExchangePool2UIComponent = TotoWar__UI:getUIComponent(
        TotoWar__UI.uiComponentQueries.unitExchange_pool2)

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
    self.unitExchangeArmySuppliesCost2 = TotoWar_Cbac_ArmySuppliesCost.new(false, lord2Rank)

    TotoWar_Cbac_UIManager:updateUnitExchangeArmySuppliesCost(
        unitExchangePool1UIComponent,
        self.unitExchangeArmySuppliesCost1,
        self.unitExchangeArmySuppliesCost2)
    TotoWar_Cbac_UIManager:updateUnitExchangeArmySuppliesCost(
        unitExchangePool2UIComponent,
        self.unitExchangeArmySuppliesCost2,
        self.unitExchangeArmySuppliesCost1)

    -- Signaling unit exchange army supplies cost change
    TotoWar.eventsManager:trigger(TotoWar_Cbac_Enum_ModEvents.unitExchangeArmySuppliesCostChanged)

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

---Updates the army supplies displayed in the Warband Upgrade panel.
function TotoWar_Cbac_PlayerManager:updateWarbandUpgradeArmySupplies()
    TotoWar_Cbac.loggers.playerManager:logDebug("updateWarbandUpgradeArmySupplies(): STARTED")

    local unitToUpgradeUiComponent = TotoWar__UI:findUIComponent(
        TotoWar__UI.uiComponentQueries.unitsPanel_warbandUpgradesUnitToUpgrade)
    local upgradedUnitUiComponent = TotoWar__UI:findUIComponent(
        TotoWar__UI.uiComponentQueries.unitsPanel_warbandUpgradesUpgradedUnit)

    if unitToUpgradeUiComponent == nil
        or upgradedUnitUiComponent == nil
        or not unitToUpgradeUiComponent:Visible(true)
        or not upgradedUnitUiComponent:Visible(true)
    then
        TotoWar_Cbac.loggers.playerManager:logDebug(
            "updateWarbandUpgradeArmySupplies(): COMPLETED => %s",
            function() return "Not calculated" end)

        return
    end

    -- Getting the unit type to upgrade
    local objectContextId = unitToUpgradeUiComponent:GetContextObjectId(TotoWar__Enum_CcoContextTypeIds.campaignUnit)

    if objectContextId == nil then
        TotoWar_Cbac.loggers.playerManager:logDebug(
            "updateWarbandUpgradeArmySupplies(): COMPLETED => %s",
            function() return "Not calculated" end)

        return
    end

    ---@type string
    local unitToUpgradeKey = common.get_context_value(
        TotoWar__Enum_CcoContextTypeIds.campaignUnit,
        objectContextId,
        "UnitRecordContext.Key")

    -- Counting how many units of this type are selected
    local unitsToUpgradeCount = 0
    local unitsUIComponent = TotoWar__UI:getUIComponent(TotoWar__UI.uiComponentQueries.unitsPanel_units)

    -- Getting the number of units selected
    for i = 0, unitsUIComponent:ChildCount() - 1, 1 do
        local unitCardUIComponent = find_child_uicomponent_by_index(unitsUIComponent, i)

        local isSelected =
            unitCardUIComponent:CurrentState() == TotoWar__Enum_UIComponentStates.selected
            or unitCardUIComponent:CurrentState() == TotoWar__Enum_UIComponentStates.selectedHover
        local isInRecruitmentStandardUnitCard =
            unitCardUIComponent:Id():match(TotoWar__Enum_Patterns.standardUnitCard) ~= nil

        if isSelected and isInRecruitmentStandardUnitCard
        then
            local cardImageHolderUIComponent = TotoWar__UI:getUIComponentChild(
                unitCardUIComponent,
                { "card_image_holder" })

            local unitContext = TotoWar__UI:getUIComponentCCO(
                cardImageHolderUIComponent,
                TotoWar__Enum_CcoContextTypeIds.mainUnitRecord)

            --- @type string
            local unitKey = unitContext:Call("Key")

            if unitKey == unitToUpgradeKey then
                unitsToUpgradeCount = unitsToUpgradeCount + 1
            end
        end
    end

    -- Getting the army supplies cost without the units that are selected to be upgraded
    local unitsNotToInclude = unitsToUpgradeCount
    self.warbandUpgradeArmySuppliesCost = TotoWar_Cbac_ArmySuppliesCost.new(
        false,
        self.selectedLordArmySuppliesCost.lordLevel)

    for index, unitArmySuppliesCost in ipairs(self.selectedLordArmySuppliesCost.unitArmySuppliesCosts) do
        if unitArmySuppliesCost.unitKey == unitToUpgradeKey and unitsNotToInclude > 0 then
            unitsNotToInclude = unitsNotToInclude - 1
        elseif unitArmySuppliesCost.characterCqi ~= nil then
            self.warbandUpgradeArmySuppliesCost:addCharacter(unitArmySuppliesCost.characterCqi)
        else
            self.warbandUpgradeArmySuppliesCost:addUnit(
                unitArmySuppliesCost.unitKey,
                unitArmySuppliesCost.unitCqi,
                false)
        end
    end

    -- Getting the upgraded unit type
    local upgradedUnitContext = TotoWar__UI:getUIComponentCCO(
        upgradedUnitUiComponent,
        TotoWar__Enum_CcoContextTypeIds.mainUnitRecord)

    ---@type string
    local upgradedUnitKey = upgradedUnitContext:Call("Key")

    -- Adding the upgraded unit cost to the army supplies cost
    for i = 1, unitsToUpgradeCount, 1 do
        self.warbandUpgradeArmySuppliesCost:addUnit(upgradedUnitKey)
    end

    -- Sending an event to update the warband upgrade UI with the upgraded army supplies cost
    TotoWar.eventsManager:trigger(TotoWar_Cbac_Enum_ModEvents.warbandUpgradeArmySuppliesCostChanged)

    TotoWar_Cbac.loggers.playerManager:logDebug(
        "updateWarbandUpgradeArmySupplies(): COMPLETED => %s",
        function()
            if self.warbandUpgradeArmySuppliesCost ~= nil then
                return self.warbandUpgradeArmySuppliesCost.totalCost
            end

            return "Not calculated"
        end)
end
