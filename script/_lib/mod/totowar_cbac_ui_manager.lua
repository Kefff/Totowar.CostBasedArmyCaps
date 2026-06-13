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
local _globalRecruitmentPoolUIComponentTargetHeight = 239

---Height the local recruitment pool UI component should measure when displaying army supplies cost.
local _localRecruitmentPoolUIComponentTargetHeight = 239

---Height the mercenary recruitment pool UI component should measure when displaying army supplies cost.
local _mercenaryRecruitmentPoolListBoxUIComponentTargetHeight = 208

---Height the listbox UI component of the mercenary recruitment pool should measure when displaying army supplies cost.
local _mercenaryRecruitmentPoolUIComponentTargetHeight = 272

---Template of the UI component that displays unit army supplies.
local _unitArmySuppliesUIComponentTemplate = "ui/totowar/totowar_icon_value.twui.xml"

---Y offset of the UI component that displays unit army supplies cost.
local _unitArmySuppliesCostUIComponentOffsetY = -18

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
    TotoWar_Cbac.loggers.uiManager:logDebug("TotoWar_Cbac_UIManager.new(): STARTED")

    local instance = setmetatable({}, TotoWar_Cbac_UIManager)

    instance.recruitmentPools = TotoWar__Dictionary.new()
    instance.recruitmentPools:set(TotoWar_Cbac_Enum_UiRecruitmentPoolName.allied, {
        name = TotoWar_Cbac_Enum_UiRecruitmentPoolName.allied,
        panelName = TotoWar__Enum_Panels.mercenaryRecruitment,
        uiComponentQuery = TotoWar__UI.uiComponentQueries.recruitmentOptionsAlliedRecruitmentPool,
        updateUIFunction = function()
            instance:updateAlliedRecruitmentPool()
        end
    })
    instance.recruitmentPools:set(TotoWar_Cbac_Enum_UiRecruitmentPoolName.global, {
        name = TotoWar_Cbac_Enum_UiRecruitmentPoolName.global,
        panelName = TotoWar__Enum_Panels.standardRecruitment,
        uiComponentQuery = TotoWar__UI.uiComponentQueries.recruitmentOptionsGlobalRecruitmentPool,
        updateUIFunction = function()
            instance:updateGlobalRecruitmentPool()
        end
    })
    instance.recruitmentPools:set(TotoWar_Cbac_Enum_UiRecruitmentPoolName.local_, {
        name = TotoWar_Cbac_Enum_UiRecruitmentPoolName.local_,
        panelName = TotoWar__Enum_Panels.standardRecruitment,
        uiComponentQuery = TotoWar__UI.uiComponentQueries.recruitmentOptionsLocalRecruitmentPool,
        updateUIFunction = function()
            instance:updateLocalRecruitmentPool()
        end
    })
    instance.recruitmentPools:set(TotoWar_Cbac_Enum_UiRecruitmentPoolName.mercenary, {
        name = TotoWar_Cbac_Enum_UiRecruitmentPoolName.mercenary,
        panelName = TotoWar__Enum_Panels.mercenaryRecruitment,
        uiComponentQuery = TotoWar__UI.uiComponentQueries.recruitmentOptionsMercenaryRecruitmentPool,
        updateUIFunction = function()
            instance:updateMercenaryRecruitmentPool()
        end
    })

    TotoWar_Cbac.loggers.uiManager:logDebug("TotoWar_Cbac_UIManager.new(): COMPLETED")

    return instance
end

---Adds listeners for events.
function TotoWar_Cbac_UIManager:addListeners()
    TotoWar_Cbac.loggers.uiManager:logDebug("addListeners(): STARTED")

    TotoWar__Gameplay:addListener(
        "TotoWar_Cbac_UIManager",
        TotoWar__Enum_GameEvent.characterDeselected,
        function()
            -- We do not check the TotoWarCbac.playerArmySuppliesEnabled option because when this option
            -- is disabled, we deselect everything and we want onCharacterDeselected to be executed
            -- to reset UI elements.
            return cm:is_local_players_turn()
        end,
        function()
            self:onCharacterDeselected()
        end)

    TotoWar__Gameplay:addListener(
        "TotoWar_Cbac_UIManager",
        TotoWar__Enum_GameEvent.characterSelected,
        ---@param context CharacterSelected
        function(context)
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
                and not TotoWar__Gameplay:isPlayerFaction(context:character():faction():name())
        end,
        function()
            self:onOtherFactionCharacterSelected()
        end)

    TotoWar__Gameplay:addListener(
        "TotoWar_Cbac_UIManager",
        TotoWar_Cbac_Enum_ModEvent.optionsUpdated,
        true,
        function()
            self:onOptionsUpdated()
        end)

    TotoWar__Gameplay:addListener(
        "TotoWar_Cbac_UIManager",
        TotoWar__Enum_GameEvent.panelClosed,
        ---@param context TotoWar__GameEventContext_PanelOpenedOrClosed
        function(context)
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
                and context.string == TotoWar__Enum_Panels.recruitmentOptions
        end,
        function()
            self:onRecruitmentPanelClosed()
        end)

    TotoWar__Gameplay:addListener(
        "TotoWar_Cbac_UIManager",
        TotoWar__Enum_GameEvent.panelOpened,
        ---@param context TotoWar__GameEventContext_PanelOpenedOrClosed
        function(context)
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
                and not TotoWar_Cbac.playerManager.isInitializingArmySuppliesCost
                and self:isRecruitmentPanel(context.string)
        end,
        ---@param context TotoWar__GameEventContext_PanelOpenedOrClosed
        function(context)
            self:onRecruitmentPanelOpened(context.string)
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
        TotoWar_Cbac_Enum_ModEvent.unitExchangeArmySuppliesCostChanged,
        function()
            return
                TotoWar_Cbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
        end,
        function()
            self:onUnitExchangeSuppliesCostChanged()
        end)

    TotoWar_Cbac.loggers.uiManager:logDebug("addListeners(): COMPLETED")
end

---Creates the army supplies UI component and registers it as a child of a parent component.
---@param parentUIComponent UIC Parent UI component.
function TotoWar_Cbac_UIManager:createArmySuppliesUIComponent(parentUIComponent)
    TotoWar_Cbac.loggers.uiManager:logDebug(
        "createArmySuppliesUIComponent(%s): STARTED",
        function() return parentUIComponent:Id() end)

    local uiComponentAddress = parentUIComponent:CreateComponent(
        _armySuppliesUIComponentName,
        _unitArmySuppliesUIComponentTemplate)
    armySuppliesUIComponent = UIComponent(uiComponentAddress)
    armySuppliesUIComponent:SetImagePath(_armySuppliesIconPath, 1, false)
    parentUIComponent:Adopt(uiComponentAddress)

    TotoWar_Cbac.loggers.uiManager:logDebug(
        "createArmySuppliesUIComponent(%s): COMPLETED",
        function() return parentUIComponent:Id() end)

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
    TotoWar_Cbac.loggers.uiManager:logDebug(
        "createOrUpdateArmySuppliesUIComponent(%s, %s, %s): STARTED",
        function() return parentUIComponent:Id() end,
        function() return text end,
        function() return tooltip end)

    local armySuppliesUIComponent = TotoWar__UI:findUIComponentChild(
        parentUIComponent,
        { _armySuppliesUIComponentName })

    if not armySuppliesUIComponent then
        armySuppliesUIComponent = self:createArmySuppliesUIComponent(parentUIComponent)
        armySuppliesUIComponent:SetDockingPoint(TotoWar__Enum_DockingPoints.topLeft)
    end

    armySuppliesUIComponent:SetText(text, "")
    armySuppliesUIComponent:SetTooltipText(tooltip, true)
    armySuppliesUIComponent:SetVisible(true)

    TotoWar_Cbac.loggers.uiManager:logDebug(
        "createOrUpdateArmySuppliesUIComponent(%s, %s, %s): COMPLETED",
        function() return parentUIComponent:Id() end,
        function() return text end,
        function() return tooltip end)

    return armySuppliesUIComponent
end

---Finds the open recruitment pools.
---@return TotoWar_Cbac_RecruitmentPoolUI[]
function TotoWar_Cbac_UIManager:findOpenRecruitmentPools()
    TotoWar_Cbac.loggers.uiManager:logDebug("findOpenRecruitmentPool(): STARTED")

    local recruitmentPools = {}

    for index, entry in ipairs(self.recruitmentPools.entries) do
        local recruitmentPool = entry.value
        local uiComponent = TotoWar__UI:findUIComponent(recruitmentPool.uiComponentQuery)

        if uiComponent and uiComponent:Visible(true) then
            table.insert(recruitmentPools, recruitmentPool)
        end
    end

    TotoWar_Cbac.loggers.uiManager:logDebug("findOpenRecruitmentPool(): COMPLETED")

    return recruitmentPools
end

---Find the recruitment pools in a panel.
---@param panelName string Panel name.
---@return TotoWar_Cbac_RecruitmentPoolUI[]
function TotoWar_Cbac_UIManager:findRecruitmentPoolsInPanel(panelName)
    TotoWar_Cbac.loggers.uiManager:logDebug(
        "findRecruitmentPoolInPanel(%s): STARTED",
        function() return panelName end)

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

    TotoWar_Cbac.loggers.uiManager:logDebug(
        "findRecruitmentPoolInPanel(%s): COMPLETED",
        function() return panelName end)

    return recruitmentPools
end

---Gets the text representing an army supplies cost.
---@param armySuppliesCost TotoWar_Cbac_ArmySuppliesCost Army supplies cost.
function TotoWar_Cbac_UIManager:getArmySuppliesCostText(armySuppliesCost)
    TotoWar_Cbac.loggers.uiManager:logDebug("getArmySuppliesCostText(): STARTED")

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

    TotoWar_Cbac.loggers.uiManager:logDebug(
        "getArmySuppliesCostText(): COMPLETED => %s",
        function() return armySuppliesCostText end)

    return armySuppliesCostText
end

---Hides the army supplies cost UI component.
function TotoWar_Cbac_UIManager:hideArmySuppliesCostUIComponent()
    TotoWar_Cbac.loggers.uiManager:logDebug("hideArmySuppliesCostUIComponent(): STARTED")

    local unitsPanelIconListUIComponent = TotoWar__UI:findUIComponent(
        TotoWar__UI.uiComponentQueries.unitsPanelIconList)

    if unitsPanelIconListUIComponent then
        local armyCostUIComponent = TotoWar__UI:findUIComponentChild(
            unitsPanelIconListUIComponent,
            { _armySuppliesUIComponentName })

        if armyCostUIComponent then
            armyCostUIComponent:SetVisible(false)
        end
    end

    TotoWar_Cbac.loggers.uiManager:logDebug("hideArmySuppliesCostUIComponent(): COMPLETED")
end

---Indicates whether a panel is a recruitment panel.
---@param panelName string Panel name.
---@return boolean
function TotoWar_Cbac_UIManager:isRecruitmentPanel(panelName)
    TotoWar_Cbac.loggers.uiManager:logDebug(
        "isRecruitmentPanel(%s): STARTED",
        function() return panelName end)

    local result = false

    for index, entry in ipairs(self.recruitmentPools.entries) do
        local recruitmentPool = entry.value
        if recruitmentPool.panelName == panelName then
            result = true

            break
        end
    end

    TotoWar_Cbac.loggers.uiManager:logDebug(
        "isRecruitmentPanel(%s): COMPLETED => %s",
        function() return panelName end,
        function() return result end)

    return result
end

---Reacts to a character being deselected.
function TotoWar_Cbac_UIManager:onCharacterDeselected()
    TotoWar_Cbac.loggers.uiManager:logDebug("onCharacterDeselected(): STARTED")

    self:hideArmySuppliesCostUIComponent()
    self:resetUIChangeFlags()

    TotoWar_Cbac.loggers.uiManager:logDebug("onCharacterDeselected(): COMPLETED")
end

---Reacts to options being updated.
function TotoWar_Cbac_UIManager:onOptionsUpdated()
    TotoWar_Cbac.loggers.uiManager:logDebug("onOptionsUpdated(): STARTED")

    -- Clearing the selection for two reasons :
    -- - it resets its movement if the selected character was not able to move, otherwise the character could not be move anymore if the player army supplies option has been disabled
    -- - it closes the unit list and recruitment UI which will hide army supplies if the player army supplies option has been disabled
    CampaignUI.ClearSelection()

    TotoWar_Cbac.loggers.uiManager:logDebug("onOptionsUpdated(): COMPLETED")
end

---Reacts to the recruitment panel being closed.
function TotoWar_Cbac_UIManager:onRecruitmentPanelClosed()
    TotoWar_Cbac.loggers.uiManager:logDebug("onRecruitmentPanelClosed(): STARTED")

    self:resetUIChangeFlags()

    TotoWar_Cbac.loggers.uiManager:logDebug("onRecruitmentPanelClosed(): COMPLETED")
end

---Reacts to a panel being opened.
---@param panelName string Name of the panel;
function TotoWar_Cbac_UIManager:onRecruitmentPanelOpened(panelName)
    --- We do not need to update the units_panel when it is opened, because it is the
    --- fact that it is opened that triggers the army supplies cost calculation.
    --- So when it is opened, the army supplies cost is not up to date.
    --- It is later updated when the SelectedLordArmySuppliesCostChanged event is triggered.

    TotoWar_Cbac.loggers.uiManager:logDebug(
        "onPanelOpened(%s): STARTED",
        function() return panelName end)

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

    TotoWar_Cbac.loggers.uiManager:logDebug(
        "onPanelOpened(%s): COMPLETED",
        function() return panelName end)
end

---Reacts to the army supplies cost of the selected lord changing.
function TotoWar_Cbac_UIManager:onSelectedLordArmySuppliesCostChanged()
    TotoWar_Cbac.loggers.uiManager:logDebug("onSelectedLordArmySuppliesCostChanged(): STARTED")

    self:updateUnitsPanel()

    local recruitmentPools = self:findOpenRecruitmentPools()
    self:updateRecruitmentPools(recruitmentPools)

    TotoWar_Cbac.loggers.uiManager:logDebug("onSelectedLordArmySuppliesCostChanged(): COMPLETED")
end

---Resets flags that indicate UI changes have been made to display army supply costs.
function TotoWar_Cbac_UIManager:resetUIChangeFlags()
    TotoWar_Cbac.loggers.uiManager:logDebug("resetUIChangeFlags(): STARTED")

    self.lastOpenedPanel = nil
    self.lastOpenedRecruitmentPools = {}

    TotoWar_Cbac.loggers.uiManager:logDebug("resetUIChangeFlags(): COMPLETED")
end

---Reacts to the another faction character being selected.
function TotoWar_Cbac_UIManager:onOtherFactionCharacterSelected()
    TotoWar_Cbac.loggers.uiManager:logDebug("onUnitExchangeSuppliesCostChanged(): STARTED")

    self:hideArmySuppliesCostUIComponent()

    TotoWar_Cbac.loggers.uiManager:logDebug("onUnitExchangeSuppliesCostChanged(): COMPLETED")
end

---Reacts to the army supplies cost of armies exchanging units changing.
function TotoWar_Cbac_UIManager:onUnitExchangeSuppliesCostChanged()
    TotoWar_Cbac.loggers.uiManager:logDebug("onUnitExchangeSuppliesCostChanged(): STARTED")

    local unitExchangePool1UIComponent = TotoWar__UI:getUIComponent(TotoWar__UI.uiComponentQueries
        .unitExchangePool1)
    self:updateUnitExchangePool(unitExchangePool1UIComponent, TotoWar_Cbac.playerManager.unitExchangeArmySuppliesCost1)

    local unitExchangePool2UIComponent = TotoWar__UI:getUIComponent(TotoWar__UI.uiComponentQueries
        .unitExchangePool2)
    self:updateUnitExchangePool(unitExchangePool2UIComponent, TotoWar_Cbac.playerManager.unitExchangeArmySuppliesCost2)

    TotoWar_Cbac.loggers.uiManager:logDebug("onUnitExchangeSuppliesCostChanged(): COMPLETED")
end

---Updates the allied recruitment pool.
function TotoWar_Cbac_UIManager:updateAlliedRecruitmentPool()
    TotoWar_Cbac.loggers.uiManager:logDebug("updateAlliedRecruitmentPanel(): STARTED")

    local alliedRecruitmentPoolUIComponent = TotoWar__UI:getUIComponent(
        TotoWar__UI.uiComponentQueries.recruitmentOptionsAlliedRecruitmentPool)

    local unitListQuery = { "listview", "list_clip", "allied_unit_list" }
    local unitListUIComponent = TotoWar__UI:getUIComponentChild(alliedRecruitmentPoolUIComponent, unitListQuery)

    if unitListUIComponent ~= nil then
        self:updateRecruitableUnitCardList(unitListUIComponent)

        if alliedRecruitmentPoolUIComponent:Height() < _alliedRecruitmentPoolUIComponentTargetHeight then
            TotoWar__UI:resizeUIComponentAndChildren(
                alliedRecruitmentPoolUIComponent,
                0,
                _armySuppliesCostUIComponentHeight,
                unitListQuery)
        end
    end

    TotoWar_Cbac.loggers.uiManager:logDebug("updateAlliedRecruitmentPanel(): COMPLETED")
end

---Updates the global recruitment pool.
function TotoWar_Cbac_UIManager:updateGlobalRecruitmentPool()
    TotoWar_Cbac.loggers.uiManager:logDebug("updateGlobalRecruitmentPool(): STARTED")

    local unitListQuery = { "listview", "list_clip", "list_box" }
    local globalRecruitmentPoolUIComponent = TotoWar__UI:getUIComponent(
        self.recruitmentPools:get(TotoWar_Cbac_Enum_UiRecruitmentPoolName.global).uiComponentQuery)
    local unitListUIComponent = TotoWar__UI:findUIComponentChild(
        globalRecruitmentPoolUIComponent,
        unitListQuery)

    if unitListUIComponent then
        self:updateRecruitableUnitCardList(unitListUIComponent)

        if globalRecruitmentPoolUIComponent:Height() < _globalRecruitmentPoolUIComponentTargetHeight then
            TotoWar__UI:resizeUIComponentAndChildren(
                globalRecruitmentPoolUIComponent,
                0,
                _armySuppliesCostUIComponentHeight,
                unitListQuery)
        end
    end

    TotoWar_Cbac.loggers.uiManager:logDebug("updateGlobalRecruitmentPool(): COMPLETED")
end

---Updates the local recruitment pool.
function TotoWar_Cbac_UIManager:updateLocalRecruitmentPool()
    TotoWar_Cbac.loggers.uiManager:logDebug("updateLocalRecruitmentPool(): STARTED")

    local unitListQuery = { "listview", "list_clip", "list_box" }
    local localRecruitmentPoolUIComponent = TotoWar__UI:getUIComponent(
        self.recruitmentPools:get(TotoWar_Cbac_Enum_UiRecruitmentPoolName.local_).uiComponentQuery)
    local unitListUIComponent = TotoWar__UI:findUIComponentChild(
        localRecruitmentPoolUIComponent,
        unitListQuery)

    if unitListUIComponent then
        self:updateRecruitableUnitCardList(unitListUIComponent)

        if localRecruitmentPoolUIComponent:Height() < _localRecruitmentPoolUIComponentTargetHeight then
            TotoWar__UI:resizeUIComponentAndChildren(
                localRecruitmentPoolUIComponent,
                0,
                _armySuppliesCostUIComponentHeight,
                unitListQuery)
        end
    end

    TotoWar_Cbac.loggers.uiManager:logDebug("updateLocalRecruitmentPool(): COMPLETED")
end

---Updates the mercenary recruitment pool.
function TotoWar_Cbac_UIManager:updateMercenaryRecruitmentPool()
    TotoWar_Cbac.loggers.uiManager:logDebug("updateMercenaryRecruitmentPanel(): STARTED")

    local unitListQuery = { "listview", "list_clip", "list_box" }
    local recruitmentPoolUIComponent = TotoWar__UI:getUIComponent(
        TotoWar__UI.uiComponentQueries.recruitmentOptionsMercenaryRecruitmentPool)
    local unitListUIComponent = TotoWar__UI:findUIComponentChild(
        recruitmentPoolUIComponent,
        unitListQuery)

    if unitListUIComponent then
        self:updateRecruitableUnitCardList(unitListUIComponent)

        if recruitmentPoolUIComponent:Height() < _mercenaryRecruitmentPoolUIComponentTargetHeight then
            TotoWar__UI:resizeUIComponentAndChildren(
                recruitmentPoolUIComponent,
                0,
                _armySuppliesCostUIComponentHeight,
                { "listview" })
        end

        if unitListUIComponent:Height() < _mercenaryRecruitmentPoolListBoxUIComponentTargetHeight then
            TotoWar__UI:resizeUIComponent(
                unitListUIComponent,
                0,
                _armySuppliesCostUIComponentHeight)
        end
    end

    TotoWar_Cbac.loggers.uiManager:logDebug("updateMercenaryRecruitmentPanel(): COMPLETED")
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

    TotoWar_Cbac.loggers.uiManager:logDebug(
        "updateRecruitableUnitCard(%s): STARTED => (%s, %s)",
        function() return unitCardUIComponent:Id() end,
        function() return unitName end,
        function() return unitBaseCost end)

    local armySuppliesCostUIComponent = TotoWar__UI:findUIComponentChild(
        unitCardUIComponent,
        { "external_holder", _armySuppliesUIComponentName })

    if armySuppliesCostUIComponent == nil then
        local externalHolderUIComponent = TotoWar__UI:getUIComponentChild(unitCardUIComponent, { "external_holder" })

        if externalHolderUIComponent ~= nil then
            armySuppliesCostUIComponent = self:createArmySuppliesUIComponent(externalHolderUIComponent)
            armySuppliesCostUIComponent:SetDockingPoint(TotoWar__Enum_DockingPoints.bottomMiddle)
            armySuppliesCostUIComponent:SetTooltipText(
                common.get_localised_string("totowar_cbac_tooltip_unit_armySuppliesCost"), true)

            -- Resizing the container to have enough space to display the new component
            TotoWar__UI:resizeUIComponent(unitCardUIComponent, 0, armySuppliesCostUIComponent:Height())
            TotoWar__UI:resizeUIComponent(externalHolderUIComponent, 0, armySuppliesCostUIComponent:Height())

            -- Moving up each cost / upkeep component (they are docked at the bottom) to display the army supplies cost component last
            TotoWar__UI:offsetChildUIComponents(externalHolderUIComponent, 0, -armySuppliesCostUIComponent:Height())
            armySuppliesCostUIComponent:SetDockOffset(0, 0) -- Cancelling the offset of the army supplies cost component itself
        end
    end

    local unitBaseCostText = tostring(unitBaseCost)

    if unitBaseCost > TotoWar_Cbac.playerManager.selectedLordArmySuppliesCost.availableSupplies then
        -- Disabling the unit card when its the army supplies exceeds the available army supplies of the selected lord
        TotoWar_Cbac.loggers.uiManager:logDebug(
            "updateRecruitableUnitCard(%s): UNIT RECRUITMENT DISABLED => (%s, %s)",
            function() return unitCardUIComponent:Id() end,
            function() return unitName end,
            function() return unitBaseCost end)

        unitCardUIComponent:SetDisabled(true)
        unitCardUIComponent:SetState(TotoWar__Enum_UIComponentStates.inactive)
        unitBaseCostText = string.format("[[col:%s]]%s[[/col]]", "red", unitBaseCostText)
    elseif unitCardUIComponent:IsDisabled() then
        -- Reenabling the unit card if it was disabled
        unitCardUIComponent:SetDisabled(false)
    end

    if armySuppliesCostUIComponent ~= nil then
        armySuppliesCostUIComponent:SetText(unitBaseCostText, "")
    end

    TotoWar_Cbac.loggers.uiManager:logDebug(
        "updateRecruitableUnitCard(%s): COMPLETED => (%s, %s)",
        function() return unitCardUIComponent:Id() end,
        function() return unitName end,
        function() return unitBaseCost end)
end

---Updates the army supplies cost of a list of recruitable unit cards.
---@param unitCardListUIComponent UIC UI component that contains the list of recruitable units cards.
function TotoWar_Cbac_UIManager:updateRecruitableUnitCardList(
    unitCardListUIComponent)
    TotoWar_Cbac.loggers.uiManager:logDebug(
        "updateRecruitableUnitCardList(%s): STARTED",
        function() return unitCardListUIComponent:Id() end)

    for i = 0, unitCardListUIComponent:ChildCount() - 1 do
        local unitCardUIComponent = find_child_uicomponent_by_index(unitCardListUIComponent, i)
        self:updateRecruitableUnitCard(unitCardUIComponent)
    end

    TotoWar_Cbac.loggers.uiManager:logDebug(
        "updateRecruitableUnitCardList(%s): COMPLETED",
        function() return unitCardListUIComponent:Id() end)
end

---Updates army supplies costs on recruitment pools.
---@param recruitmentPools TotoWar_Cbac_RecruitmentPoolUI Recruitment pools.
function TotoWar_Cbac_UIManager:updateRecruitmentPools(recruitmentPools)
    TotoWar_Cbac.loggers.uiManager:logDebug("updateRecruitmentPools(): STARTED")

    for key, recruitmentPool in pairs(recruitmentPools) do
        ---@cast recruitmentPool TotoWar_Cbac_RecruitmentPoolUI

        TotoWar_Cbac.loggers.uiManager:logDebug(
            "updateRecruitmentPools() => %s",
            function() return recruitmentPool.name end)

        recruitmentPool.updateUIFunction()
    end

    TotoWar_Cbac.loggers.uiManager:logDebug("updateRecruitmentPools(): COMPLETED")
end

---Updates the army supplies cost of a unit exchange pool.
---@param unitExchangePoolUIComponent UIC Unit exchange pool UI component.
---@param armySuppliesCost TotoWar_Cbac_ArmySuppliesCost Army supplies cost.
function TotoWar_Cbac_UIManager:updateUnitExchangePool(unitExchangePoolUIComponent, armySuppliesCost)
    TotoWar_Cbac.loggers.uiManager:logDebug(
        "updateUnitExchangePool(%s): STARTED",
        function() return unitExchangePoolUIComponent:Id() end)

    local parent = TotoWar__UI:getUIComponentChild(unitExchangePoolUIComponent, { "panel_smoke_t" })

    if parent ~= nil then
        local armySuppliesCostText = self:getArmySuppliesCostText(armySuppliesCost)
        self:createOrUpdateArmySuppliesUIComponent(
            parent,
            armySuppliesCostText,
            armySuppliesCost:toArmySuppliesCostTooltipText())
    end

    TotoWar_Cbac.loggers.uiManager:logDebug(
        "updateUnitExchangePool(%s): COMPLETED",
        function() return unitExchangePoolUIComponent:Id() end)
end

---Updates the army supplies cost of the panel that lists all the units in the selected army.
function TotoWar_Cbac_UIManager:updateUnitsPanel()
    TotoWar_Cbac.loggers.uiManager:logDebug("updateUnitsPanel(): STARTED")

    local unitsPanelIconListUIComponent = TotoWar__UI:getUIComponent(
        TotoWar__UI.uiComponentQueries.unitsPanelIconList)

    local armySuppliesCostText = self:getArmySuppliesCostText(
        TotoWar_Cbac.playerManager.selectedLordArmySuppliesCost)
    local armySuppliesCostTooltip =
        TotoWar_Cbac.playerManager.selectedLordArmySuppliesCost:toArmySuppliesCostTooltipText()
    self:createOrUpdateArmySuppliesUIComponent(
        unitsPanelIconListUIComponent,
        armySuppliesCostText,
        armySuppliesCostTooltip)

    TotoWar_Cbac.loggers.uiManager:logDebug("updateUnitsPanel(): COMPLETED")
end
