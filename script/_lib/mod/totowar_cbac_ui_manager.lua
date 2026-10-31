local logger = TotoWar__Logger.get(TotoWar_Cbac_Enum_LogCategories.uiManager)

---Height the allied recruitment pool UI component should measure when displaying army supplies cost.
local _alliedRecruitmentPoolUIComponentTargetHeight = 229

---Height of the UI components that displays army supplies and army supplies cost.
local _armySuppliesCostUIComponentHeight = 24

---Name of the UI component that displays army supplies.
local _armySuppliesUIComponentName = "totowar_cbac_army_supplies"

---ID of the depleted army supplies warning icon.
local _armySuppliesDepletedWarningIconId = "totowar_alert"

---Path of the army supplies icon.
local _armySuppliesIconPath = "ui/totowar_cbac/icons/totowar_cbac_army_supplies.png"

---Height the global recruitment pool UI component should measure when displaying army supplies cost.
---@type integer | nil
local _defaultUIComponentHeight_globalRecruitmentPool = nil

---Height the local recruitment pool UI component should measure when displaying army supplies cost.
---@type integer | nil
local _defaultUIComponentHeight_localRecruitmentPool = nil

---Height the listbox UI component of the mercenary recruitment pool should measure when displaying army supplies cost.
---@type integer | nil
local _defaultUIComponentHeight_mercenaryRecruitmentPool = nil

---Height the mercenary recruitment pool UI component should measure when displaying army supplies cost.
---@type integer | nil
local _defaultUIComponentHeight_mercenaryRecruitmentPoolListBox = nil

---Height the warband upgrade UI component should measure when displaying army supplies cost.
---@type integer | nil
local _defaultUIComponentHeight_warbandUpgrade = nil

---Template of the UI component that displays unit army supplies.
local _unitArmySuppliesUIComponentTemplate = "ui/totowar/totowar_icon_value.twui.xml"

---Manager in charge of displaying army supplies cost in the UI.
---@class TotoWar_Cbac_UIManager
TotoWar_Cbac_UIManager = {
    ---Last opened panel.
    ---@type string | nil
    lastOpenedPanel = nil,

    ---Last opened recruitment pools.
    ---@type string[]
    lastOpenedRecruitmentPools = {},

    ---Recruitment pool UIs.
    ---@type TotoWar__Dictionary<string, TotoWar_Cbac_RecruitmentPoolUI>
    recruitmentPools = nil
}
TotoWar_Cbac_UIManager.__index = TotoWar_Cbac_UIManager

---Initializes a new instance.
---@return TotoWar_Cbac_UIManager
function TotoWar_Cbac_UIManager.new()
    logger:logDebug("new(): STARTED")

    local instance = setmetatable({}, TotoWar_Cbac_UIManager)

    instance.recruitmentPools = TotoWar__Dictionary.new()
    instance.recruitmentPools:set(
        TotoWar_Cbac_Enum_UiRecruitmentPools.allied,
        TotoWar_Cbac_RecruitmentPoolUI.new(
            TotoWar_Cbac_Enum_UiRecruitmentPools.allied,
            TotoWar__Enum_Panels.mercenaryRecruitment,
            TotoWar__UI.uiComponentQueries.unitsPanel_recruitmentOptions_alliedRecruitmentPool,
            function() instance:updateAlliedRecruitmentPool() end))
    instance.recruitmentPools:set(
        TotoWar_Cbac_Enum_UiRecruitmentPools.global,
        TotoWar_Cbac_RecruitmentPoolUI.new(
            TotoWar_Cbac_Enum_UiRecruitmentPools.global,
            TotoWar__Enum_Panels.standardRecruitment,
            TotoWar__UI.uiComponentQueries.unitsPanel_recruitmentOptions_globalRecruitmentPool,
            function() instance:updateGlobalRecruitmentPool() end))
    instance.recruitmentPools:set(
        TotoWar_Cbac_Enum_UiRecruitmentPools.local1,
        TotoWar_Cbac_RecruitmentPoolUI.new(
            TotoWar_Cbac_Enum_UiRecruitmentPools.local1,
            TotoWar__Enum_Panels.standardRecruitment,
            TotoWar__UI.uiComponentQueries.unitsPanel_recruitmentOptions_localRecruitmentPool1,
            function() instance:updateLocalRecruitmentPool(TotoWar_Cbac_Enum_UiRecruitmentPools.local1) end))
    instance.recruitmentPools:set(
        TotoWar_Cbac_Enum_UiRecruitmentPools.local2,
        TotoWar_Cbac_RecruitmentPoolUI.new(
            TotoWar_Cbac_Enum_UiRecruitmentPools.local2,
            TotoWar__Enum_Panels.standardRecruitment,
            TotoWar__UI.uiComponentQueries.unitsPanel_recruitmentOptions_localRecruitmentPool2,
            function() instance:updateLocalRecruitmentPool(TotoWar_Cbac_Enum_UiRecruitmentPools.local2) end))
    instance.recruitmentPools:set(
        TotoWar_Cbac_Enum_UiRecruitmentPools.mercenary,
        TotoWar_Cbac_RecruitmentPoolUI.new(
            TotoWar_Cbac_Enum_UiRecruitmentPools.mercenary,
            TotoWar__Enum_Panels.mercenaryRecruitment,
            TotoWar__UI.uiComponentQueries.unitsPanel_recruitmentOptions_mercenaryRecruitmentPool,
            function()
                instance:updateMercenaryRecruitmentPool()
            end))

    instance:subscribeToEvents()

    logger:logDebug("new(): COMPLETED")

    return instance
end

---Creates the army supplies UI component and registers it as a child of a parent component.
---@param parentUIComponent UIC Parent UI component.
function TotoWar_Cbac_UIManager:createArmySuppliesUIComponent(parentUIComponent)
    local uiComponentAddress = parentUIComponent:CreateComponent(
        _armySuppliesUIComponentName,
        _unitArmySuppliesUIComponentTemplate)
    local armySuppliesUIComponent = UIComponent(uiComponentAddress)
    armySuppliesUIComponent:SetImagePath(_armySuppliesIconPath, 1, false)
    parentUIComponent:Adopt(uiComponentAddress)

    return armySuppliesUIComponent
end

---Creates the UI component that displays army supplies.
---@param parentUIComponent UIC UI component that contains or will contain the army cost UI component.
---@param text string Text displayed.
---@param tooltip string Tooltip.
function TotoWar_Cbac_UIManager:createOrUpdateArmySuppliesUIComponent(
    parentUIComponent,
    text,
    tooltip
)
    logger:logDebug(
        "createOrUpdateArmySuppliesUIComponent(%s, %s, %s): STARTED",
        function() return parentUIComponent:Id() end,
        text,
        tooltip)

    local armySuppliesUIComponent = TotoWar__UI:findUIComponentChild(
        parentUIComponent,
        { _armySuppliesUIComponentName })

    if armySuppliesUIComponent == nil then
        armySuppliesUIComponent = self:createArmySuppliesUIComponent(parentUIComponent)
        armySuppliesUIComponent:SetDockingPoint(TotoWar__Enum_DockingPoints.topLeft)
    end

    armySuppliesUIComponent:SetText(text, "")
    armySuppliesUIComponent:SetTooltipText(tooltip, true)
    armySuppliesUIComponent:SetVisible(true)

    logger:logDebug(
        "createOrUpdateArmySuppliesUIComponent(%s, %s, %s): COMPLETED",
        function() return parentUIComponent:Id() end,
        text,
        tooltip)

    return armySuppliesUIComponent
end

---Finds the open recruitment pools.
---@return TotoWar_Cbac_RecruitmentPoolUI[]
function TotoWar_Cbac_UIManager:findOpenRecruitmentPools()
    logger:logDebug("findOpenRecruitmentPools(): STARTED")

    local recruitmentPools = {}

    for index, entry in ipairs(self.recruitmentPools.entries) do
        local recruitmentPool = entry.value
        local uiComponent = TotoWar__UI:findUIComponent(recruitmentPool.uiComponentQuery)

        if uiComponent and uiComponent:Visible(true) then
            table.insert(recruitmentPools, recruitmentPool)
        end
    end

    logger:logDebug("findOpenRecruitmentPools(): COMPLETED")

    return recruitmentPools
end

---Find the recruitment pools in a panel.
---@param panelName string Panel name.
---@return TotoWar_Cbac_RecruitmentPoolUI[]
function TotoWar_Cbac_UIManager:findRecruitmentPoolsInPanel(panelName)
    logger:logDebug(
        "findRecruitmentPoolsInPanel(%s): STARTED",
        panelName)

    local recruitmentPools = {}

    for index, entry in ipairs(self.recruitmentPools.entries) do
        local key = entry.key
        local recruitmentPool = entry.value

        if recruitmentPool.panelName == panelName then
            local uiComponent = TotoWar__UI:findUIComponent(recruitmentPool.uiComponentQuery)

            if
                uiComponent
                and uiComponent:Visible(true)
            then
                table.insert(recruitmentPools, recruitmentPool)
            end
        end
    end

    logger:logDebug(
        "findRecruitmentPoolsInPanel(%s): COMPLETED",
        panelName)

    return recruitmentPools
end

---Gets the text representing an army supplies cost.
---@param armySuppliesCost TotoWar_Cbac_ArmySuppliesCost Army supplies cost.
function TotoWar_Cbac_UIManager:getArmySuppliesCostText(armySuppliesCost)
    ---@type string
    local armySuppliesCostText

    if armySuppliesCost.availableSupplies < 0 then
        armySuppliesCostText = string.format(
            "[[col:%s]]%s[[/col]][[img:%s]][[/img]]",
            "red",
            armySuppliesCost.availableSupplies,
            _armySuppliesDepletedWarningIconId)
    else
        armySuppliesCostText = tostring(armySuppliesCost.availableSupplies)
    end

    return armySuppliesCostText
end

---Gets the lord of a unit exchange pool UI component.
---@param unitExchangePoolUIComponent UIC Unit exchange pool UI component that contains the army units.
---@return CHARACTER_SCRIPT_INTERFACE | nil
function TotoWar_Cbac_UIManager:getLordInUnitExchangePool(unitExchangePoolUIComponent)
    logger:logDebug(
        "getLordInUnitExchangePool(%s): STARTED",
        function() return unitExchangePoolUIComponent:Id() end)

    ---@type CHARACTER_SCRIPT_INTERFACE | nil
    local character = nil
    local unitExchangePoolUnitListUIComponent = TotoWar__UI:getUIComponentChild(unitExchangePoolUIComponent, { "units" })

    for i = 0, unitExchangePoolUnitListUIComponent:ChildCount() - 1, 1 do
        ---@type UIC | false
        local unitCardUIComponent = find_child_uicomponent_by_index(unitExchangePoolUnitListUIComponent, i)

        if unitCardUIComponent then
            local objectContextId = unitCardUIComponent:GetContextObjectId(
                TotoWar__Enum_CcoContextTypeIds.campaignUnit)
            local characterCqi = common.get_context_value(
                TotoWar__Enum_CcoContextTypeIds.campaignUnit,
                objectContextId,
                "CharacterContext.CQI")

            if characterCqi ~= nil then
                character = TotoWar__Gameplay:getCharacter(characterCqi)

                if character ~= nil and TotoWar__Gameplay:isLordCharacter(character) then
                    break
                end
            end
        end
    end

    if character == nil then
        logger:logError("The lord of one of the armies exchanging units could not be found: its army supplies cannot be displayed")
    end

    logger:logDebug(
        "getLordInUnitExchangePool(%s): COMPLETED => Faction: %s | Lord: %s",
        function() return unitExchangePoolUIComponent:Id() end,
        function() return character ~= nil and TotoWar__Gameplay:getFactionCaption(character:faction():name()) or "NOT FOUND" end,
        function() return character ~= nil and TotoWar__Gameplay:getCharacterCaption(character) or "NOT FOUND" end)

    return character
end

---Hides the army supplies cost UI component.
function TotoWar_Cbac_UIManager:hideArmySuppliesCostUIComponent()
    logger:logDebug("hideArmySuppliesCostUIComponent(): STARTED")

    local unitsPanelIconListUIComponent = TotoWar__UI:findUIComponent(
        TotoWar__UI.uiComponentQueries.unitsPanel_iconList)

    if unitsPanelIconListUIComponent then
        local armyCostUIComponent = TotoWar__UI:findUIComponentChild(
            unitsPanelIconListUIComponent,
            { _armySuppliesUIComponentName })

        if armyCostUIComponent then
            armyCostUIComponent:SetVisible(false)
        end
    end

    logger:logDebug("hideArmySuppliesCostUIComponent(): COMPLETED")
end

---Indicates whether a panel is a recruitment panel.
---@param panelName string Panel name.
---@return boolean
function TotoWar_Cbac_UIManager:isRecruitmentPanel(panelName)
    logger:logDebug(
        "isRecruitmentPanel(%s): STARTED",
        panelName)

    local result = TotoWar__Linq:any(self.recruitmentPools.entries, function(e) return e.value.panelName == panelName end)

    logger:logDebug(
        "isRecruitmentPanel(%s): COMPLETED => %s",
        panelName,
        result)

    return result
end

---Reacts to a character being deselected.
function TotoWar_Cbac_UIManager:onCharacterDeselected()
    logger:logDebug("onCharacterDeselected(): STARTED")

    self:hideArmySuppliesCostUIComponent()
    self:resetUIChangeFlags()

    logger:logDebug("onCharacterDeselected(): COMPLETED")
end

---Reacts to options being updated.
function TotoWar_Cbac_UIManager:onOptionsUpdated()
    logger:logDebug("onOptionsUpdated(): STARTED")

    -- Clearing the selection for two reasons :
    -- - it resets its movement if the selected character was not able to move, otherwise the character could not be move anymore if the player army supplies option has been disabled
    -- - it closes the unit list and recruitment UI which will hide army supplies if the player army supplies option has been disabled
    CampaignUI.ClearSelection()

    logger:logDebug("onOptionsUpdated(): COMPLETED")
end

---Reacts to the another faction character being selected.
function TotoWar_Cbac_UIManager:onOtherFactionCharacterSelected()
    logger:logDebug("onOtherFactionCharacterSelected(): STARTED")

    self:hideArmySuppliesCostUIComponent()

    logger:logDebug("onOtherFactionCharacterSelected(): COMPLETED")
end

---Reacts to the recruitment panel being closed.
function TotoWar_Cbac_UIManager:onRecruitmentPanelClosed()
    logger:logDebug("onRecruitmentPanelClosed(): STARTED")

    self:resetUIChangeFlags()

    logger:logDebug("onRecruitmentPanelClosed(): COMPLETED")
end

---Reacts to a recruitment panel being opened.
---@param panelName string Name of the panel.
function TotoWar_Cbac_UIManager:onRecruitmentPanelOpened(panelName)
    --- We do not need to update the units_panel when it is opened, because it is the
    --- fact that it is opened that triggers the army supplies cost calculation.
    --- So when it is opened, the army supplies cost is not up to date.
    --- It is later updated when the SelectedLordArmySuppliesCostChanged event is triggered.

    logger:logDebug(
        "onRecruitmentPanelOpened(%s): STARTED",
        panelName)

    local recruitmentPools = self:findRecruitmentPoolsInPanel(panelName)
    local recruitmentPoolsToUpdate = {}

    for i, recruitmentPool in ipairs(recruitmentPools) do
        local wasOpen = TotoWar__Linq:any(
            self.lastOpenedRecruitmentPools,
            function(lorp) return lorp == recruitmentPool.name end)

        if not wasOpen then
            table.insert(recruitmentPoolsToUpdate, recruitmentPool)
        end
    end

    self:updateRecruitmentPools(recruitmentPools)

    self.lastOpenedPanel = panelName
    self.lastOpenedRecruitmentPools = recruitmentPools

    logger:logDebug(
        "onRecruitmentPanelOpened(%s): COMPLETED",
        panelName)
end

---Reacts to the army supplies cost of the selected lord changing.
function TotoWar_Cbac_UIManager:onSelectedLordArmySuppliesCostChanged()
    logger:logDebug("onSelectedLordArmySuppliesCostChanged(): STARTED")

    self:updateUnitsPanel()

    local recruitmentPools = self:findOpenRecruitmentPools()
    self:updateRecruitmentPools(recruitmentPools)

    logger:logDebug("onSelectedLordArmySuppliesCostChanged(): COMPLETED")
end

---Reacts to the army supplies cost of armies exchanging units changing.
function TotoWar_Cbac_UIManager:onUnitExchangeArmySuppliesCostChanged()
    logger:logDebug("onUnitExchangeArmySuppliesCostChanged(): STARTED")

    local unitExchangePool1UIComponent = TotoWar__UI:getUIComponent(
        TotoWar__UI.uiComponentQueries.unitExchange_pool1)
    self:updateUnitExchangePool(unitExchangePool1UIComponent, TotoWar_Cbac.playerManager.unitExchangeArmySuppliesCost1)

    local unitExchangePool2UIComponent = TotoWar__UI:getUIComponent(
        TotoWar__UI.uiComponentQueries.unitExchange_pool2)
    self:updateUnitExchangePool(unitExchangePool2UIComponent, TotoWar_Cbac.playerManager.unitExchangeArmySuppliesCost2)

    logger:logDebug("onUnitExchangeArmySuppliesCostChanged(): COMPLETED")
end

---Reacts to the army supplies cost changing due to a warband upgrade.
function TotoWar_Cbac_UIManager:onWarbandUpgradeArmySuppliesCostChanged()
    logger:logDebug("onWarbandUpgradeArmySuppliesCostChanged(): STARTED")

    -- Resizing the upgrade panel to have space to add the army supplies after update component
    local warbandUpgradesComponent = TotoWar__UI:getUIComponent(
        TotoWar__UI.uiComponentQueries.unitsPanel_warbandUpgrades)

    if _defaultUIComponentHeight_warbandUpgrade == nil then
        _defaultUIComponentHeight_warbandUpgrade = warbandUpgradesComponent:Height()
    end

    if warbandUpgradesComponent:Height() == _defaultUIComponentHeight_warbandUpgrade then
        TotoWar__UI:resizeUIComponentAndChildren(
            warbandUpgradesComponent,
            0,
            _armySuppliesCostUIComponentHeight,
            { "body", "info_holder", "upgrade_info_holder", "unit_info_costs", "holder_requirements", "body" })

        -- Moving the upgrade button to take into account the resizing
        local warbandUpgradesUpgradeButtonComponent = TotoWar__UI:getUIComponentChild(
            warbandUpgradesComponent,
            { "body", "info_holder", "upgrade_info_holder", "unit_info_costs", "holder_requirements", "button_invoke" })
        warbandUpgradesUpgradeButtonComponent:SetDockingPoint(TotoWar__Enum_DockingPoints.bottomMiddle)
    end

    -- Adding / updating the army supplies after upgrade component
    if (TotoWar_Cbac.playerManager.warbandUpgradeArmySuppliesCost ~= nil) then
        local armySuppliesCostText = self:getArmySuppliesCostText(
            TotoWar_Cbac.playerManager.warbandUpgradeArmySuppliesCost)
        local armySuppliesCostTooltip =
            TotoWar_Cbac.playerManager.warbandUpgradeArmySuppliesCost:toArmySuppliesCostTooltipText()

        local armySuppliesCostContainerComponentName = "totowar_cbac_warband_upgrade_army_supplies"
        local warbandUpgradesRequirementsComponent = TotoWar__UI:getUIComponent(
            TotoWar__UI.uiComponentQueries.unitsPanel_warbandUpgradesRequirements)
        local armySuppliesCostContainerComponent = TotoWar__UI:findUIComponentChild(
            warbandUpgradesRequirementsComponent,
            { armySuppliesCostContainerComponentName })

        if armySuppliesCostContainerComponent == nil then
            -- Copying the total cost container component to create the army supplies cost container
            local totalCostContainerComponent = TotoWar__UI:getUIComponentChild(
                warbandUpgradesRequirementsComponent,
                { "total_cost" })
            local armySuppliesCostContainerComponentAddress = totalCostContainerComponent:CopyComponent(
                armySuppliesCostContainerComponentName)
            armySuppliesCostContainerComponent = UIComponent(armySuppliesCostContainerComponentAddress)
            armySuppliesCostContainerComponent:SetVisible(true)

            local armySuppliesCostCaptionComponent = TotoWar__UI:getUIComponentChild(
                armySuppliesCostContainerComponent,
                { "tx_total_cost" })
            armySuppliesCostCaptionComponent:SetStateText(common.get_localised_string(
                "totowar_cbac_warbandUpgradeArmySuppliesCost"))

            -- Deleting the copied value component that will get replaced by the army supplies cost component
            local copiedValueComponentToReplace = TotoWar__UI:getUIComponentChild(
                armySuppliesCostContainerComponent,
                { "total_cost_holder" })
            copiedValueComponentToReplace:Destroy()
        end

        local armySuppliesCostComponent = self:createOrUpdateArmySuppliesUIComponent(
            armySuppliesCostContainerComponent,
            armySuppliesCostText,
            armySuppliesCostTooltip)
        armySuppliesCostComponent:SetDockingPoint(TotoWar__Enum_DockingPoints.middleRight)
        armySuppliesCostComponent:SetDockOffset(15, 0)
    end

    logger:logDebug("onWarbandUpgradeArmySuppliesCostChanged(): COMPLETED")
end

---Resets flags that indicate UI changes have been made to display army supply costs.
function TotoWar_Cbac_UIManager:resetUIChangeFlags()
    logger:logDebug("resetUIChangeFlags(): STARTED")

    self.lastOpenedPanel = nil
    self.lastOpenedRecruitmentPools = {}

    logger:logDebug("resetUIChangeFlags(): COMPLETED")
end

---Subscribes to events.
function TotoWar_Cbac_UIManager:subscribeToEvents()
    logger:logDebug("subscribeToEvents(): STARTED")

    TotoWar.eventsManager:subscribe(
        TotoWar__Enum_GameEvents.characterDeselected,
        function() self:onCharacterDeselected() end,
        function()
            -- We do not check the TotoWar_Cbac.options.playerArmySuppliesEnabled option because when this option
            -- is disabled, we deselect everything and we want onCharacterDeselected to be executed
            -- to reset UI elements.
            return cm:is_local_players_turn(true)
        end)

    TotoWar.eventsManager:subscribe(
        TotoWar__Enum_GameEvents.characterSelected,
        function() self:onOtherFactionCharacterSelected() end,
        ---@param context CharacterSelected
        function(context)
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn(true)
                and not TotoWar__Gameplay:isLocalPlayerFaction(context:character():faction():name())
        end)

    TotoWar.eventsManager:subscribe(
        TotoWar__Enum_ModEvents.optionsUpdated,
        function() self:onOptionsUpdated() end)

    TotoWar.eventsManager:subscribe(
        TotoWar__Enum_GameEvents.panelClosed,
        function() self:onRecruitmentPanelClosed() end,
        ---@param context TotoWar__GameEventContext_PanelOpenedOrClosed
        function(context)
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn(true)
                and context.string == TotoWar__Enum_Panels.recruitmentOptions
        end)

    TotoWar.eventsManager:subscribe(
        TotoWar__Enum_GameEvents.panelOpened,
        ---@param context TotoWar__GameEventContext_PanelOpenedOrClosed
        function(context) self:onRecruitmentPanelOpened(context.string) end,
        ---@param context TotoWar__GameEventContext_PanelOpenedOrClosed
        function(context)
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn(true)
                and not TotoWar_Cbac.playerManager.isInitializingArmySuppliesCost
                and self:isRecruitmentPanel(context.string)
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
        TotoWar_Cbac_Enum_ModEvents.unitExchangeArmySuppliesCostChanged,
        function() self:onUnitExchangeArmySuppliesCostChanged() end,
        function()
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn(true)
        end)

    TotoWar.eventsManager:subscribe(
        TotoWar_Cbac_Enum_ModEvents.warbandUpgradeArmySuppliesCostChanged,
        function() self:onWarbandUpgradeArmySuppliesCostChanged() end,
        function()
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn(true)
        end)

    logger:logDebug("subscribeToEvents(): COMPLETED")
end

---Updates the allied recruitment pool.
function TotoWar_Cbac_UIManager:updateAlliedRecruitmentPool()
    logger:logDebug("updateAlliedRecruitmentPool(): STARTED")

    local alliedRecruitmentPoolUIComponent = TotoWar__UI:getUIComponent(
        TotoWar__UI.uiComponentQueries.unitsPanel_recruitmentOptions_alliedRecruitmentPool)

    if alliedRecruitmentPoolUIComponent ~= nil then
        local unitListQuery = { "listview", "list_clip", "allied_unit_list" }
        local unitListUIComponent = TotoWar__UI:getUIComponentChild(alliedRecruitmentPoolUIComponent, unitListQuery)

        self:updateRecruitableUnitCardList(unitListUIComponent)

        if alliedRecruitmentPoolUIComponent:Height() < _alliedRecruitmentPoolUIComponentTargetHeight then
            TotoWar__UI:resizeUIComponentAndChildren(
                alliedRecruitmentPoolUIComponent,
                0,
                _armySuppliesCostUIComponentHeight,
                unitListQuery)
        end
    end

    logger:logDebug("updateAlliedRecruitmentPool(): COMPLETED")
end

---Updates the global recruitment pool.
function TotoWar_Cbac_UIManager:updateGlobalRecruitmentPool()
    logger:logDebug("updateGlobalRecruitmentPool(): STARTED")

    local unitListQuery = { "listview", "list_clip", "list_box" }
    local globalRecruitmentPoolUIComponent = TotoWar__UI:getUIComponent(
        self.recruitmentPools:get(TotoWar_Cbac_Enum_UiRecruitmentPools.global).uiComponentQuery)

    if globalRecruitmentPoolUIComponent ~= nil then
        local unitListUIComponent = TotoWar__UI:findUIComponentChild(
            globalRecruitmentPoolUIComponent,
            unitListQuery)

        if unitListUIComponent then
            self:updateRecruitableUnitCardList(unitListUIComponent)

            if _defaultUIComponentHeight_globalRecruitmentPool == nil then
                _defaultUIComponentHeight_globalRecruitmentPool = globalRecruitmentPoolUIComponent:Height()
            end

            if globalRecruitmentPoolUIComponent:Height() == _defaultUIComponentHeight_globalRecruitmentPool then
                TotoWar__UI:resizeUIComponentAndChildren(
                    globalRecruitmentPoolUIComponent,
                    0,
                    _armySuppliesCostUIComponentHeight,
                    unitListQuery)
            end
        end
    end

    logger:logDebug("updateGlobalRecruitmentPool(): COMPLETED")
end

---Updates the local recruitment pool.
function TotoWar_Cbac_UIManager:updateLocalRecruitmentPool(recruitmentPoolName)
    logger:logDebug(
        "updateLocalRecruitmentPool(%s): STARTED",
        recruitmentPoolName)

    local unitListQuery = { "listview", "list_clip", "list_box" }
    local localRecruitmentPoolUIComponent = TotoWar__UI:getUIComponent(
        self.recruitmentPools:get(recruitmentPoolName).uiComponentQuery)

    if localRecruitmentPoolUIComponent ~= nil then
        local unitListUIComponent = TotoWar__UI:findUIComponentChild(
            localRecruitmentPoolUIComponent,
            unitListQuery)

        if unitListUIComponent then
            self:updateRecruitableUnitCardList(unitListUIComponent)

            if _defaultUIComponentHeight_localRecruitmentPool == nil then
                _defaultUIComponentHeight_localRecruitmentPool = localRecruitmentPoolUIComponent:Height()
            end

            if localRecruitmentPoolUIComponent:Height() == _defaultUIComponentHeight_localRecruitmentPool then
                TotoWar__UI:resizeUIComponentAndChildren(
                    localRecruitmentPoolUIComponent,
                    0,
                    _armySuppliesCostUIComponentHeight,
                    unitListQuery)
            end
        end
    end

    logger:logDebug(
        "updateLocalRecruitmentPool(%s): COMPLETED",
        recruitmentPoolName)
end

---Updates the mercenary recruitment pool.
function TotoWar_Cbac_UIManager:updateMercenaryRecruitmentPool()
    logger:logDebug("updateMercenaryRecruitmentPool(): STARTED")

    local unitListQuery = { "listview", "list_clip", "list_box" }
    local recruitmentPoolUIComponent = TotoWar__UI:getUIComponent(
        TotoWar__UI.uiComponentQueries.unitsPanel_recruitmentOptions_mercenaryRecruitmentPool)

    if recruitmentPoolUIComponent ~= nil then
        local unitListUIComponent = TotoWar__UI:findUIComponentChild(
            recruitmentPoolUIComponent,
            unitListQuery)

        if unitListUIComponent then
            self:updateRecruitableUnitCardList(unitListUIComponent)

            if _defaultUIComponentHeight_mercenaryRecruitmentPool == nil then
                _defaultUIComponentHeight_mercenaryRecruitmentPool = recruitmentPoolUIComponent:Height()
            end

            if recruitmentPoolUIComponent:Height() == _defaultUIComponentHeight_mercenaryRecruitmentPool then
                TotoWar__UI:resizeUIComponentAndChildren(
                    recruitmentPoolUIComponent,
                    0,
                    _armySuppliesCostUIComponentHeight,
                    { "listview" })
            end

            if _defaultUIComponentHeight_mercenaryRecruitmentPoolListBox == nil then
                _defaultUIComponentHeight_mercenaryRecruitmentPoolListBox = unitListUIComponent:Height()
            end

            if unitListUIComponent:Height() == _defaultUIComponentHeight_mercenaryRecruitmentPoolListBox then
                TotoWar__UI:resizeUIComponent(
                    unitListUIComponent,
                    0,
                    _armySuppliesCostUIComponentHeight)
            end
        end
    end

    logger:logDebug("updateMercenaryRecruitmentPool(): COMPLETED")
end

---Updates the army supplies cost of a recruitable unit card.
---@param unitCardUIComponent UIC Unit card UI component.
function TotoWar_Cbac_UIManager:updateRecruitableUnitCard(unitCardUIComponent)
    local unitContext = TotoWar__UI:getUIComponentCCO(
        unitCardUIComponent,
        TotoWar__Enum_CcoContextTypeIds.mainUnitRecord)

    local unitName = unitContext:Call("Name")
    ---@type number
    local unitBaseCost = unitContext:Call("UnmountedUnitRecordContext.BaseCost")

    local armySuppliesCostUIComponent = TotoWar__UI:findUIComponentChild(
        unitCardUIComponent,
        { "external_holder", _armySuppliesUIComponentName })

    if armySuppliesCostUIComponent == nil then
        local externalHolderUIComponent = TotoWar__UI:getUIComponentChild(unitCardUIComponent, { "external_holder" })
        local visibleComponentsCount = 0
        local visibleComponentsHeight = 0

        for i = 0, unitCardUIComponent:ChildCount() - 1, 1 do
            local childUIComponent = find_child_uicomponent_by_index(externalHolderUIComponent, i)

            if childUIComponent:Visible() then
                visibleComponentsCount = visibleComponentsCount + 1
                visibleComponentsHeight = childUIComponent:Height()
            end
        end

        armySuppliesCostUIComponent = self:createArmySuppliesUIComponent(externalHolderUIComponent)
        armySuppliesCostUIComponent:SetDockingPoint(TotoWar__Enum_DockingPoints.bottomMiddle)
        armySuppliesCostUIComponent:SetTooltipText(
            common.get_localised_string("totowar_cbac_tooltip_unit_armySuppliesCost"), true)

        local heightToAdd = armySuppliesCostUIComponent:Height()

        if visibleComponentsCount == 1 then
            -- When only one cost component is visible (when there is no upkeep mostly),
            -- the space for the upkeep component is still there.
            -- We need to resize because the height of armySuppliesCostUIComponent is greater
            -- than the height of the cost component, but we do not need to add the full
            -- height.
            heightToAdd = heightToAdd - visibleComponentsHeight
        end

        -- Resizing the container to have enough space to display the new component
        -- as it is only sized for 2 components
        TotoWar__UI:resizeUIComponent(unitCardUIComponent, 0, heightToAdd)
        TotoWar__UI:resizeUIComponent(externalHolderUIComponent, 0, heightToAdd)

        -- Moving up each cost / upkeep component (they are docked at the bottom) to display the army supplies cost component last
        TotoWar__UI:offsetChildUIComponents(externalHolderUIComponent, 0, -heightToAdd)
        armySuppliesCostUIComponent:SetDockOffset(-2, 0) -- Cancelling the offset of the army supplies cost component itself (-2 du align the right border with the other cost compoments)
    end

    local unitBaseCostText = tostring(unitBaseCost)

    if unitBaseCost > TotoWar_Cbac.playerManager.selectedLordArmySuppliesCost.availableSupplies then
        -- Displaying the army supplies cost is red when it exceeds the available army supplies
        unitBaseCostText = string.format("[[col:%s]]%s[[/col]]", "red", unitBaseCostText)
    end

    if armySuppliesCostUIComponent ~= nil then
        armySuppliesCostUIComponent:SetText(unitBaseCostText, "")
    end
end

---Updates the army supplies cost of a list of recruitable unit cards.
---@param unitCardListUIComponent UIC UI component that contains the list of recruitable units cards.
function TotoWar_Cbac_UIManager:updateRecruitableUnitCardList(
    unitCardListUIComponent)
    logger:logDebug(
        "updateRecruitableUnitCardList(%s): STARTED",
        function() return unitCardListUIComponent:Id() end)

    for i = 0, unitCardListUIComponent:ChildCount() - 1 do
        local unitCardUIComponent = find_child_uicomponent_by_index(unitCardListUIComponent, i)
        self:updateRecruitableUnitCard(unitCardUIComponent)
    end

    logger:logDebug(
        "updateRecruitableUnitCardList(%s): COMPLETED",
        function() return unitCardListUIComponent:Id() end)
end

---Updates army supplies costs on recruitment pools.
---@param recruitmentPools TotoWar_Cbac_RecruitmentPoolUI Recruitment pools.
function TotoWar_Cbac_UIManager:updateRecruitmentPools(recruitmentPools)
    logger:logDebug("updateRecruitmentPools(recruitmentPools): STARTED")

    for key, recruitmentPool in pairs(recruitmentPools) do
        ---@cast recruitmentPool TotoWar_Cbac_RecruitmentPoolUI

        logger:logDebug(
            "updateRecruitmentPools(recruitmentPools): UPDATING => %s",
            recruitmentPool.name)

        recruitmentPool.updateUIFunction()
    end

    logger:logDebug("updateRecruitmentPools(recruitmentPools): COMPLETED")
end

---Updates unit exchange army supplies cost of two unit exchange pools base on which unit cards
---are selected in one of the pools.
---@param unitExchangePoolUIComponent UIC Current unit exchange pool.
---@param unitExchangePoolArmySuppliesCost TotoWar_Cbac_ArmySuppliesCost Army supplies cost of the current unit exchange pool.
---@param otherUnitExchangePoolArmySuppliesCost TotoWar_Cbac_ArmySuppliesCost Army supplies cost of the other unit exchange pool.
function TotoWar_Cbac_UIManager:updateUnitExchangeArmySuppliesCost(
    unitExchangePoolUIComponent,
    unitExchangePoolArmySuppliesCost,
    otherUnitExchangePoolArmySuppliesCost)
    logger:logDebug(
        "updateUnitExchangeArmySuppliesCost(%s, unitExchangePoolArmySuppliesCost, otherUnitExchangePoolArmySuppliesCost): STARTED => Army 1: %s | Army 2: %s",
        function() return unitExchangePoolUIComponent:Id() end,
        unitExchangePoolArmySuppliesCost.availableSupplies,
        otherUnitExchangePoolArmySuppliesCost.availableSupplies)

    local unitExchangePoolUnitListUIComponent = TotoWar__UI:getUIComponentChild(unitExchangePoolUIComponent, { "units" })

    for i = 0, unitExchangePoolUnitListUIComponent:ChildCount() - 1, 1 do
        ---@type UIC | false
        local unitCardUIComponent = find_child_uicomponent_by_index(unitExchangePoolUnitListUIComponent, i)

        if unitCardUIComponent then
            local objectContextId = unitCardUIComponent:GetContextObjectId(
                TotoWar__Enum_CcoContextTypeIds.campaignUnit)
            local characterCqi = common.get_context_value(
                TotoWar__Enum_CcoContextTypeIds.campaignUnit,
                objectContextId,
                "CharacterContext.CQI")

            if characterCqi ~= nil then
                -- Adding a character
                if string.match(unitCardUIComponent:CurrentState(), "^" .. TotoWar__Enum_UIComponentStates.selected) then
                    otherUnitExchangePoolArmySuppliesCost:addCharacter(characterCqi)
                else
                    unitExchangePoolArmySuppliesCost:addCharacter(characterCqi)
                end
            else
                -- Adding a unit
                local cardImageHolderUIComponent = TotoWar__UI:getUIComponentChild(
                    unitCardUIComponent,
                    { "card_image_holder" })

                local unitContext = TotoWar__UI:getUIComponentCCO(
                    cardImageHolderUIComponent,
                    TotoWar__Enum_CcoContextTypeIds.mainUnitRecord)

                ---@type string
                local unitKey = unitContext:Call("Key")

                if string.match(unitCardUIComponent:CurrentState(), "^" .. TotoWar__Enum_UIComponentStates.selected) then
                    otherUnitExchangePoolArmySuppliesCost:addUnit(unitKey)
                else
                    unitExchangePoolArmySuppliesCost:addUnit(unitKey)
                end
            end
        end
    end

    logger:logDebug(
        "updateUnitExchangeArmySuppliesCost(%s, unitExchangePoolArmySuppliesCost, otherUnitExchangePoolArmySuppliesCost): COMPLETED => Army 1: %s | Army 2: %s",
        function() return unitExchangePoolUIComponent:Id() end,
        unitExchangePoolArmySuppliesCost.availableSupplies,
        otherUnitExchangePoolArmySuppliesCost.availableSupplies)
end

---Updates the army supplies cost of a unit exchange pool.
---@param unitExchangePoolUIComponent UIC Unit exchange pool UI component.
---@param armySuppliesCost TotoWar_Cbac_ArmySuppliesCost Army supplies cost.
function TotoWar_Cbac_UIManager:updateUnitExchangePool(unitExchangePoolUIComponent, armySuppliesCost)
    logger:logDebug(
        "updateUnitExchangePool(%s, armySuppliesCost): STARTED",
        function() return unitExchangePoolUIComponent:Id() end)

    local parent = TotoWar__UI:getUIComponentChild(unitExchangePoolUIComponent, { "panel_smoke_t" })
    local armySuppliesCostText = self:getArmySuppliesCostText(armySuppliesCost)
    local armySuppliesCostTooltip = armySuppliesCost:toArmySuppliesCostTooltipText()
    self:createOrUpdateArmySuppliesUIComponent(
        parent,
        armySuppliesCostText,
        armySuppliesCostTooltip)

    logger:logDebug(
        "updateUnitExchangePool(%s, armySuppliesCost): COMPLETED",
        function() return unitExchangePoolUIComponent:Id() end)
end

---Updates the army supplies cost of the panel that lists all the units in the selected army.
function TotoWar_Cbac_UIManager:updateUnitsPanel()
    logger:logDebug("updateUnitsPanel(): STARTED")

    if TotoWar_Cbac.playerManager.selectedLordArmySuppliesCost == nil then
        -- This occurs when a player faction army is selected, and we select an isolated player faction hero.
        -- The units panel is not close and the CharactedDeselected event is not triggered by the game.
        -- We still manage to set selectedLordArmySuppliesCost to nil.
        -- In that case, we need to hide the army supplies component.
        self:hideArmySuppliesCostUIComponent()
    else
        local armySuppliesCostText = self:getArmySuppliesCostText(
            TotoWar_Cbac.playerManager.selectedLordArmySuppliesCost)
        local armySuppliesCostTooltip =
            TotoWar_Cbac.playerManager.selectedLordArmySuppliesCost:toArmySuppliesCostTooltipText()

        local unitsPanelIconListUIComponent = TotoWar__UI:getUIComponent(
            TotoWar__UI.uiComponentQueries.unitsPanel_iconList)

        if unitsPanelIconListUIComponent ~= nil then
            self:createOrUpdateArmySuppliesUIComponent(
                unitsPanelIconListUIComponent,
                armySuppliesCostText,
                armySuppliesCostTooltip)
        end
    end

    logger:logDebug("updateUnitsPanel(): COMPLETED")
end
