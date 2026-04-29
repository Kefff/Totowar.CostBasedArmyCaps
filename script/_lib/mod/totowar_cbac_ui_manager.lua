---Height the allied recruitment pool UI component should measure when displaying army supplies cost.
local _alliedRecruitmentPoolUIComponentTargetHeight = 229

---Height of the UI components that displays army supplies and army supplies cost.
local _armySuppliesCostUIComponentHeight = 24

---Name of the UI component that displays army supplies.
local _armySuppliesUIComponentName = "totowar_cbac_army_supplies"

---ID of the depleted army supplies warning icon.
local _armySuppliesDepletedWarningIconId = "totowar_alert"

---Path of the army supplies icon.
local _armySuppliesIconPath = "ui/skins/default/merc.png"

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
---@class TotoWarCbacUIManager
TotoWarCbacUIManager = {
    ---Last opened panel.
    ---@type string | nil
    lastOpenedPanel = nil,

    ---Last opened recruitment pools.
    ---@type string[]
    lastOpenedRecruitmentPools = {},

    ---Recruitment pool UIs.
    ---@type{ [string]: TotoWarCbacRecruitmentPoolUI }
    recruitmentPools = nil
}
TotoWarCbacUIManager.__index = TotoWarCbacUIManager

---Initializes a new instance.
---@return TotoWarCbacUIManager
function TotoWarCbacUIManager.new()
    TotoWarCbac.loggers.uiManager:logDebug("TotoWarCbacUIManager.new(): STARTED")

    local instance = setmetatable({}, TotoWarCbacUIManager)

    instance.recruitmentPools = {}
    instance.recruitmentPools[TotoWarCbac.enums.uiRecruitmentPoolNames.allied] = {
        name = TotoWarCbac.enums.uiRecruitmentPoolNames.allied,
        panelName = TotoWar.enums.uiPanels.mercenaryRecruitment,
        uiComponentQuery = TotoWar.ui.uiComponentQueries.recruitmentOptionsAlliedRecruitmentPool,
        updateUIFunction = function()
            instance:updateAlliedRecruitmentPool()
        end
    }
    instance.recruitmentPools[TotoWarCbac.enums.uiRecruitmentPoolNames.global] = {
        name = TotoWarCbac.enums.uiRecruitmentPoolNames.global,
        panelName = TotoWar.enums.uiPanels.standardRecruitment,
        uiComponentQuery = TotoWar.ui.uiComponentQueries.recruitmentOptionsGlobalRecruitmentPool,
        updateUIFunction = function()
            instance:updateGlobalRecruitmentPool()
        end
    }
    instance.recruitmentPools[TotoWarCbac.enums.uiRecruitmentPoolNames.local_] = {
        name = TotoWarCbac.enums.uiRecruitmentPoolNames.local_,
        panelName = TotoWar.enums.uiPanels.standardRecruitment,
        uiComponentQuery = TotoWar.ui.uiComponentQueries.recruitmentOptionsLocalRecruitmentPool,
        updateUIFunction = function()
            instance:updateLocalRecruitmentPool()
        end
    }
    instance.recruitmentPools[TotoWarCbac.enums.uiRecruitmentPoolNames.mercenary] = {
        name = TotoWarCbac.enums.uiRecruitmentPoolNames.mercenary,
        panelName = TotoWar.enums.uiPanels.mercenaryRecruitment,
        uiComponentQuery = TotoWar.ui.uiComponentQueries.recruitmentOptionsMercenaryRecruitmentPool,
        updateUIFunction = function()
            instance:updateMercenaryRecruitmentPool()
        end
    }

    TotoWarCbac.loggers.uiManager:logDebug("TotoWarCbacUIManager.new(): COMPLETED")

    return instance
end

---Adds listeners for events.
function TotoWarCbacUIManager:addListeners()
    TotoWarCbac.loggers.uiManager:logDebug("addListeners(): STARTED")

    TotoWar.utils:addListener(
        "TotoWarCbacUIManager",
        TotoWar.enums.gameEvents.characterDeselected,
        function()
            -- We do not check the TotoWarCbac.playerArmySuppliesEnabled option because when this option
            -- is disabled, we deselect everything and we want onCharacterDeselected to be executed
            -- to reset UI elements.
            return cm:is_local_players_turn()
        end,
        function()
            self:onCharacterDeselected()
        end)

    TotoWar.utils:addListener(
        "TotoWarCbacUIManager",
        TotoWar.enums.gameEvents.characterSelected,
        ---@param context CharacterSelected
        function(context)
            return
                TotoWarCbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
                and not TotoWar.utils:isPlayerFaction(context:character():faction():name())
        end,
        function()
            self:onOtherFactionCharacterSelected()
        end)

    TotoWar.utils:addListener(
        "TotoWarCbacUIManager",
        TotoWarCbac.enums.modEvents.optionsUpdated,
        true,
        function()
            self:onOptionsUpdated()
        end)

    TotoWar.utils:addListener(
        "TotoWarCbacUIManager",
        TotoWar.enums.gameEvents.panelClosed,
        ---@param context TotoWarGameEventContext_PanelOpenedOrClosed
        function(context)
            return
                TotoWarCbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
                and context.string == TotoWar.enums.uiPanels.recruitmentOptions
        end,
        function()
            self:onRecruitmentPanelClosed()
        end)

    TotoWar.utils:addListener(
        "TotoWarCbacUIManager",
        TotoWar.enums.gameEvents.panelOpened,
        ---@param context TotoWarGameEventContext_PanelOpenedOrClosed
        function(context)
            return
                TotoWarCbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
                and not TotoWarCbac.playerManager.isInitializingArmySuppliesCost
                and self:isRecruitmentPanel(context.string)
        end,
        ---@param context TotoWarGameEventContext_PanelOpenedOrClosed
        function(context)
            self:onRecruitmentPanelOpened(context.string)
        end)

    TotoWar.utils:addListener(
        "TotoWarCbacUIManager",
        TotoWarCbac.enums.modEvents.selectedGeneralArmySuppliesCostChanged,
        function()
            return
                TotoWarCbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
        end,
        function()
            self:onSelectedGeneralArmySuppliesCostChanged()
        end)

    TotoWar.utils:addListener(
        "TotoWarCbacPlayerManager",
        TotoWarCbac.enums.modEvents.unitExchangeArmySuppliesCostChanged,
        function()
            return
                TotoWarCbac.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn()
        end,
        function()
            self:onUnitExchangeSuppliesCostChanged()
        end)

    TotoWarCbac.loggers.uiManager:logDebug("addListeners(): COMPLETED")
end

---Creates the army supplies UI component and registers it as a child of a parent component.
---@param parentUIComponent UIC Parent UI component.
function TotoWarCbacUIManager:createArmySuppliesUIComponent(parentUIComponent)
    TotoWarCbac.loggers.uiManager:logDebug(
        "createArmySuppliesUIComponent(%s): STARTED",
        function() return parentUIComponent:Id() end)

    local uiComponentAddress = parentUIComponent:CreateComponent(
        _armySuppliesUIComponentName,
        _unitArmySuppliesUIComponentTemplate)
    armySuppliesUIComponent = UIComponent(uiComponentAddress)
    armySuppliesUIComponent:SetImagePath(_armySuppliesIconPath, 1, false)
    parentUIComponent:Adopt(uiComponentAddress)

    TotoWarCbac.loggers.uiManager:logDebug(
        "createArmySuppliesUIComponent(%s): COMPLETED",
        function() return parentUIComponent:Id() end)

    return armySuppliesUIComponent
end

---Creates the UI component that displays army supplies.
---@param parentUIComponent UIC UI component that contains or will contain the army cost UI component.
---@param text string Text displayed.
---@param tooltip string Tooltip.
function TotoWarCbacUIManager:createOrUpdateArmySuppliesUIComponent(
    parentUIComponent,
    text,
    tooltip
)
    TotoWarCbac.loggers.uiManager:logDebug(
        "createOrUpdateArmySuppliesUIComponent(%s, %s, %s): STARTED",
        function() return parentUIComponent:Id() end,
        function() return text end,
        function() return tooltip end)

    local armySuppliesUIComponent = TotoWar.ui:findUIComponentChild(
        parentUIComponent,
        { _armySuppliesUIComponentName })

    if not armySuppliesUIComponent then
        armySuppliesUIComponent = self:createArmySuppliesUIComponent(parentUIComponent)
        armySuppliesUIComponent:SetDockingPoint(TotoWar.enums.uiDockingPoints.topLeft)
    end

    armySuppliesUIComponent:SetText(text, "")
    armySuppliesUIComponent:SetTooltipText(tooltip, true)
    armySuppliesUIComponent:SetVisible(true)

    TotoWarCbac.loggers.uiManager:logDebug(
        "createOrUpdateArmySuppliesUIComponent(%s, %s, %s): COMPLETED",
        function() return parentUIComponent:Id() end,
        function() return text end,
        function() return tooltip end)

    return armySuppliesUIComponent
end

---Finds the open recruitment pools.
---@return TotoWarCbacRecruitmentPoolUI[]
function TotoWarCbacUIManager:findOpenRecruitmentPools()
    TotoWarCbac.loggers.uiManager:logDebug("findOpenRecruitmentPool(): STARTED")

    local recruitmentPools = {}

    for key, recruitmentPool in pairs(self.recruitmentPools) do
        local uiComponent = TotoWar.ui:findUIComponent(recruitmentPool.uiComponentQuery)

        if uiComponent and uiComponent:Visible(true) then
            table.insert(recruitmentPools, recruitmentPool)
        end
    end

    TotoWarCbac.loggers.uiManager:logDebug("findOpenRecruitmentPool(): COMPLETED")

    return recruitmentPools
end

---Find the recruitment pools in a panel.
---@param panelName string Panel name.
---@return TotoWarCbacRecruitmentPoolUI[]
function TotoWarCbacUIManager:findRecruitmentPoolsInPanel(panelName)
    TotoWarCbac.loggers.uiManager:logDebug(
        "findRecruitmentPoolInPanel(%s): STARTED",
        function() return panelName end)

    local recruitmentPools = {}

    for key, recruitmentPool in pairs(self.recruitmentPools) do
        ---@cast recruitmentPool TotoWarCbacRecruitmentPoolUI

        if recruitmentPool.panelName == panelName then
            local uiComponent = TotoWar.ui:findUIComponent(recruitmentPool.uiComponentQuery)

            if
                uiComponent
                and uiComponent:Visible(true)
            then
                table.insert(recruitmentPools, recruitmentPool)
            end
        end
    end

    TotoWarCbac.loggers.uiManager:logDebug(
        "findRecruitmentPoolInPanel(%s): COMPLETED",
        function() return panelName end)

    return recruitmentPools
end

---Gets the text representing an army supplies cost.
---@param armySuppliesCost TotoWarCbacArmySuppliesCost Army supplies cost.
function TotoWarCbacUIManager:getArmySuppliesCostText(armySuppliesCost)
    TotoWarCbac.loggers.uiManager:logDebug("getArmySuppliesCostText(): STARTED")

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

    TotoWarCbac.loggers.uiManager:logDebug(
        "getArmySuppliesCostText(): COMPLETED => %s",
        function() return armySuppliesCostText end)

    return armySuppliesCostText
end

---Hides the army supplies cost UI component.
function TotoWarCbacUIManager:hideArmySuppliesCostUIComponent()
    TotoWarCbac.loggers.uiManager:logDebug("hideArmySuppliesCostUIComponent(): STARTED")

    local unitsPanelIconListUIComponent = TotoWar.ui:findUIComponent(
        TotoWar.ui.uiComponentQueries.unitsPanelIconList)

    if unitsPanelIconListUIComponent then
        local armyCostUIComponent = TotoWar.ui:findUIComponentChild(
            unitsPanelIconListUIComponent,
            { _armySuppliesUIComponentName })

        if armyCostUIComponent then
            armyCostUIComponent:SetVisible(false)
        end
    end

    TotoWarCbac.loggers.uiManager:logDebug("hideArmySuppliesCostUIComponent(): COMPLETED")
end

---Indicates whether a panel is a recruitment panel.
---@param panelName string Panel name.
---@return boolean
function TotoWarCbacUIManager:isRecruitmentPanel(panelName)
    TotoWarCbac.loggers.uiManager:logDebug(
        "isRecruitmentPanel(%s): STARTED",
        function() return panelName end)

    local result = false

    for key, recruitmentPool in pairs(self.recruitmentPools) do
        if recruitmentPool.panelName == panelName then
            result = true

            break
        end
    end

    TotoWarCbac.loggers.uiManager:logDebug(
        "isRecruitmentPanel(%s): COMPLETED => %s",
        function() return panelName end,
        function() return result end)

    return result
end

---Reacts to a character being deselected.
function TotoWarCbacUIManager:onCharacterDeselected()
    TotoWarCbac.loggers.uiManager:logDebug("onCharacterDeselected(): STARTED")

    self:hideArmySuppliesCostUIComponent()
    self:resetUIChangeFlags()

    TotoWarCbac.loggers.uiManager:logDebug("onCharacterDeselected(): COMPLETED")
end

---Reacts to options being updated.
function TotoWarCbacUIManager:onOptionsUpdated()
    TotoWarCbac.loggers.uiManager:logDebug("onOptionsUpdated(): STARTED")

    -- Clearing the selection for two reasons :
    -- - it resets its movement if the selected character was not able to move, otherwise the character could not be move anymore if the player army supplies option has been disabled
    -- - it closes the unit list and recruitment UI which will hide army supplies if the player army supplies option has been disabled
    CampaignUI.ClearSelection()

    TotoWarCbac.loggers.uiManager:logDebug("onOptionsUpdated(): COMPLETED")
end

---Reacts to the recruitment panel being closed.
function TotoWarCbacUIManager:onRecruitmentPanelClosed()
    TotoWarCbac.loggers.uiManager:logDebug("onRecruitmentPanelClosed(): STARTED")

    self:resetUIChangeFlags()

    TotoWarCbac.loggers.uiManager:logDebug("onRecruitmentPanelClosed(): COMPLETED")
end

---Reacts to a panel being opened.
---@param panelName string Name of the panel;
function TotoWarCbacUIManager:onRecruitmentPanelOpened(panelName)
    --- We do not need to update the units_panel when it is opened, because it is the
    --- fact that it is opened that triggers the army supplies cost calculation.
    --- So when it is opened, the army supplies cost is not up to date.
    --- It is later updated when the SelectedGeneralArmySuppliesCostChanged event is triggered.

    TotoWarCbac.loggers.uiManager:logDebug(
        "onPanelOpened(%s): STARTED",
        function() return panelName end)

    local recruitmentPools = self:findRecruitmentPoolsInPanel(panelName)
    local recruitmentPoolsToUpdate = {}

    for i, recruitmentPool in ipairs(recruitmentPools) do
        local wasOpen = totoWar_linqAny(
            self.lastOpenedRecruitmentPools,
            function(lorp) return lorp == recruitmentPool.name end)

        if not wasOpen then
            table.insert(recruitmentPoolsToUpdate, recruitmentPool)
        end
    end

    self:updateRecruitmentPools(recruitmentPools)

    self.lastOpenedPanel = panelName
    self.lastOpenedRecruitmentPools = recruitmentPools

    TotoWarCbac.loggers.uiManager:logDebug(
        "onPanelOpened(%s): COMPLETED",
        function() return panelName end)
end

---Reacts to the army supplies cost of the selected general changing.
function TotoWarCbacUIManager:onSelectedGeneralArmySuppliesCostChanged()
    TotoWarCbac.loggers.uiManager:logDebug("onSelectedGeneralArmySuppliesCostChanged(): STARTED")

    self:updateUnitsPanel()

    local recruitmentPools = self:findOpenRecruitmentPools()
    self:updateRecruitmentPools(recruitmentPools)

    TotoWarCbac.loggers.uiManager:logDebug("onSelectedGeneralArmySuppliesCostChanged(): COMPLETED")
end

---Resets flags that indicate UI changes have been made to display army supply costs.
function TotoWarCbacUIManager:resetUIChangeFlags()
    TotoWarCbac.loggers.uiManager:logDebug("resetUIChangeFlags(): STARTED")

    self.lastOpenedPanel = nil
    self.lastOpenedRecruitmentPools = {}

    TotoWarCbac.loggers.uiManager:logDebug("resetUIChangeFlags(): COMPLETED")
end

---Reacts to the another faction character being selected.
function TotoWarCbacUIManager:onOtherFactionCharacterSelected()
    TotoWarCbac.loggers.uiManager:logDebug("onUnitExchangeSuppliesCostChanged(): STARTED")

    self:hideArmySuppliesCostUIComponent()

    TotoWarCbac.loggers.uiManager:logDebug("onUnitExchangeSuppliesCostChanged(): COMPLETED")
end

---Reacts to the army supplies cost of armies exchanging units changing.
function TotoWarCbacUIManager:onUnitExchangeSuppliesCostChanged()
    TotoWarCbac.loggers.uiManager:logDebug("onUnitExchangeSuppliesCostChanged(): STARTED")

    local unitExchangePool1UIComponent = TotoWar.ui:getUIComponent(TotoWar.ui.uiComponentQueries.unitExchangePool1)
    self:updateUnitExchangePool(unitExchangePool1UIComponent, TotoWarCbac.playerManager.unitExchangeArmySuppliesCost1)

    local unitExchangePool2UIComponent = TotoWar.ui:getUIComponent(TotoWar.ui.uiComponentQueries.unitExchangePool2)
    self:updateUnitExchangePool(unitExchangePool2UIComponent, TotoWarCbac.playerManager.unitExchangeArmySuppliesCost2)

    TotoWarCbac.loggers.uiManager:logDebug("onUnitExchangeSuppliesCostChanged(): COMPLETED")
end

---Updates the allied recruitment pool.
function TotoWarCbacUIManager:updateAlliedRecruitmentPool()
    TotoWarCbac.loggers.uiManager:logDebug("updateAlliedRecruitmentPanel(): STARTED")

    local alliedRecruitmentPoolUIComponent = TotoWar.ui:getUIComponent(
        TotoWar.ui.uiComponentQueries.recruitmentOptionsAlliedRecruitmentPool)

    local unitListQuery = { "listview", "list_clip", "allied_unit_list" }

    local unitListUIComponent = TotoWar.ui:getUIComponentChild(
        alliedRecruitmentPoolUIComponent,
        unitListQuery)

    if unitListUIComponent then
        self:updateRecruitableUnitCardList(unitListUIComponent)

        if alliedRecruitmentPoolUIComponent:Height() < _alliedRecruitmentPoolUIComponentTargetHeight then
            TotoWar.ui:resizeUIComponentAndChildren(
                alliedRecruitmentPoolUIComponent,
                0,
                _armySuppliesCostUIComponentHeight,
                unitListQuery)
        end
    end

    TotoWarCbac.loggers.uiManager:logDebug("updateAlliedRecruitmentPanel(): COMPLETED")
end

---Updates the global recruitment pool.
function TotoWarCbacUIManager:updateGlobalRecruitmentPool()
    TotoWarCbac.loggers.uiManager:logDebug("updateGlobalRecruitmentPool(): STARTED")

    local unitListQuery = { "listview", "list_clip", "list_box" }
    local globalRecruitmentPoolUIComponent = TotoWar.ui:getUIComponent(
        self.recruitmentPools[TotoWarCbac.enums.uiRecruitmentPoolNames.global].uiComponentQuery)
    local unitListUIComponent = TotoWar.ui:findUIComponentChild(
        globalRecruitmentPoolUIComponent,
        unitListQuery)

    if unitListUIComponent then
        self:updateRecruitableUnitCardList(unitListUIComponent)

        if globalRecruitmentPoolUIComponent:Height() < _globalRecruitmentPoolUIComponentTargetHeight then
            TotoWar.ui:resizeUIComponentAndChildren(
                globalRecruitmentPoolUIComponent,
                0,
                _armySuppliesCostUIComponentHeight,
                unitListQuery)
        end
    end

    TotoWarCbac.loggers.uiManager:logDebug("updateGlobalRecruitmentPool(): COMPLETED")
end

---Updates the local recruitment pool.
function TotoWarCbacUIManager:updateLocalRecruitmentPool()
    TotoWarCbac.loggers.uiManager:logDebug("updateLocalRecruitmentPool(): STARTED")

    local unitListQuery = { "listview", "list_clip", "list_box" }
    local localRecruitmentPoolUIComponent = TotoWar.ui:getUIComponent(
        self.recruitmentPools[TotoWarCbac.enums.uiRecruitmentPoolNames.local_].uiComponentQuery)
    local unitListUIComponent = TotoWar.ui:findUIComponentChild(
        localRecruitmentPoolUIComponent,
        unitListQuery)

    if unitListUIComponent then
        self:updateRecruitableUnitCardList(unitListUIComponent)

        if localRecruitmentPoolUIComponent:Height() < _localRecruitmentPoolUIComponentTargetHeight then
            TotoWar.ui:resizeUIComponentAndChildren(
                localRecruitmentPoolUIComponent,
                0,
                _armySuppliesCostUIComponentHeight,
                unitListQuery)
        end
    end

    TotoWarCbac.loggers.uiManager:logDebug("updateLocalRecruitmentPool(): COMPLETED")
end

---Updates the mercenary recruitment pool.
function TotoWarCbacUIManager:updateMercenaryRecruitmentPool()
    TotoWarCbac.loggers.uiManager:logDebug("updateMercenaryRecruitmentPanel(): STARTED")

    local unitListQuery = { "listview", "list_clip", "list_box" }
    local recruitmentPoolUIComponent = TotoWar.ui:getUIComponent(
        TotoWar.ui.uiComponentQueries.recruitmentOptionsMercenaryRecruitmentPool)
    local unitListUIComponent = TotoWar.ui:findUIComponentChild(
        recruitmentPoolUIComponent,
        unitListQuery)

    if unitListUIComponent then
        self:updateRecruitableUnitCardList(unitListUIComponent)

        if recruitmentPoolUIComponent:Height() < _mercenaryRecruitmentPoolUIComponentTargetHeight then
            TotoWar.ui:resizeUIComponentAndChildren(
                recruitmentPoolUIComponent,
                0,
                _armySuppliesCostUIComponentHeight,
                { "listview" })
        end

        if unitListUIComponent:Height() < _mercenaryRecruitmentPoolListBoxUIComponentTargetHeight then
            TotoWar.ui:resizeUIComponent(
                unitListUIComponent,
                0,
                _armySuppliesCostUIComponentHeight)
        end
    end

    TotoWarCbac.loggers.uiManager:logDebug("updateMercenaryRecruitmentPanel(): COMPLETED")
end

---Updates the army supplies cost of a recruitable unit card.
---@param unitCardUIComponent UIC Unit card UI component.
function TotoWarCbacUIManager:updateRecruitableUnitCard(unitCardUIComponent)
    local unitContext = TotoWar.ui:getUIComponentCCO(
        unitCardUIComponent,
        TotoWar.enums.ccoContextTypeIds.mainUnitRecord)

    local unitName = unitContext:Call("Name")
    ---@type number
    local unitBaseCost = unitContext:Call("UnmountedUnitRecordContext.BaseCost")

    TotoWarCbac.loggers.uiManager:logDebug(
        "updateRecruitableUnitCard(%s): STARTED => (%s, %s)",
        function() return unitCardUIComponent:Id() end,
        function() return unitName end,
        function() return unitBaseCost end)

    local armySuppliesCostUIComponent = TotoWar.ui:findUIComponentChild(
        unitCardUIComponent,
        { "external_holder", _armySuppliesUIComponentName })

    if not armySuppliesCostUIComponent then
        local externalHolderUIComponent = TotoWar.ui:getUIComponentChild(
            unitCardUIComponent,
            { "external_holder" })

        armySuppliesCostUIComponent = self:createArmySuppliesUIComponent(
            externalHolderUIComponent)
        armySuppliesCostUIComponent:SetDockingPoint(
            TotoWar.enums.uiDockingPoints.bottomMiddle)
        armySuppliesCostUIComponent:SetTooltipText(
            common.get_localised_string("totowar_cbac_tooltip_unit_armySuppliesCost"), true)

        -- Resizing the container to have enough space to display the new component
        TotoWar.ui:resizeUIComponent(unitCardUIComponent, 0, armySuppliesCostUIComponent:Height())
        TotoWar.ui:resizeUIComponent(externalHolderUIComponent, 0, armySuppliesCostUIComponent:Height())

        -- Moving up each cost / upkeep component (they are docked at the bottom) to display the army supplies cost component last
        TotoWar.ui:offsetChildUIComponents(externalHolderUIComponent, 0, -armySuppliesCostUIComponent:Height())
        armySuppliesCostUIComponent:SetDockOffset(0, 0) -- Cancelling the offset of the army supplies cost component itself
    end

    local unitBaseCostText = tostring(unitBaseCost)

    if unitBaseCost > TotoWarCbac.playerManager.selectedGeneralArmySuppliesCost.availableSupplies then
        -- Disabling the unit card when its the army supplies exceeds the available army supplies of the selected general
        TotoWarCbac.loggers.uiManager:logDebug(
            "updateRecruitableUnitCard(%s): UNIT RECRUITMENT DISABLED => (%s, %s)",
            function() return unitCardUIComponent:Id() end,
            function() return unitName end,
            function() return unitBaseCost end)

        unitCardUIComponent:SetDisabled(true)
        unitCardUIComponent:SetState(TotoWar.enums.uiComponentStates.inactive)
        unitBaseCostText = string.format("[[col:%s]]%s[[/col]]", "red", unitBaseCostText)
    elseif unitCardUIComponent:IsDisabled() then
        -- Reenabling the unit card if it was disabled
        unitCardUIComponent:SetDisabled(false)
    end

    armySuppliesCostUIComponent:SetText(unitBaseCostText, "")

    TotoWarCbac.loggers.uiManager:logDebug(
        "updateRecruitableUnitCard(%s): COMPLETED => (%s, %s)",
        function() return unitCardUIComponent:Id() end,
        function() return unitName end,
        function() return unitBaseCost end)
end

---Updates the army supplies cost of a list of recruitable unit cards.
---@param unitCardListUIComponent UIC UI component that contains the list of recruitable units cards.
function TotoWarCbacUIManager:updateRecruitableUnitCardList(
    unitCardListUIComponent)
    TotoWarCbac.loggers.uiManager:logDebug(
        "updateRecruitableUnitCardList(%s): STARTED",
        function() return unitCardListUIComponent:Id() end)

    for i = 0, unitCardListUIComponent:ChildCount() - 1 do
        local unitCardUIComponent = find_child_uicomponent_by_index(unitCardListUIComponent, i)
        self:updateRecruitableUnitCard(unitCardUIComponent)
    end

    TotoWarCbac.loggers.uiManager:logDebug(
        "updateRecruitableUnitCardList(%s): COMPLETED",
        function() return unitCardListUIComponent:Id() end)
end

---Updates army supplies costs on recruitment pools.
---@param recruitmentPools TotoWarCbacRecruitmentPoolUI Recruitment pools.
function TotoWarCbacUIManager:updateRecruitmentPools(recruitmentPools)
    TotoWarCbac.loggers.uiManager:logDebug("updateRecruitmentPools(): STARTED")

    for key, recruitmentPool in pairs(recruitmentPools) do
        ---@cast recruitmentPool TotoWarCbacRecruitmentPoolUI

        TotoWarCbac.loggers.uiManager:logDebug(
            "updateRecruitmentPools() => %s",
            function() return recruitmentPool.name end)

        recruitmentPool.updateUIFunction()
    end

    TotoWarCbac.loggers.uiManager:logDebug("updateRecruitmentPools(): COMPLETED")
end

---Updates the army supplies cost of a unit exchange pool.
---@param unitExchangePoolUIComponent UIC Unit exchange pool UI component.
---@param armySuppliesCost TotoWarCbacArmySuppliesCost Army supplies cost.
function TotoWarCbacUIManager:updateUnitExchangePool(unitExchangePoolUIComponent, armySuppliesCost)
    TotoWarCbac.loggers.uiManager:logDebug(
        "updateUnitExchangePool(%s): STARTED",
        function() return unitExchangePoolUIComponent:Id() end)

    local parent = TotoWar.ui:getUIComponentChild(unitExchangePoolUIComponent, { "panel_smoke_t" })
    local armySuppliesCostText = self:getArmySuppliesCostText(armySuppliesCost)
    self:createOrUpdateArmySuppliesUIComponent(
        parent,
        armySuppliesCostText,
        armySuppliesCost:toArmySuppliesCostTooltipText())

    TotoWarCbac.loggers.uiManager:logDebug(
        "updateUnitExchangePool(%s): COMPLETED",
        function() return unitExchangePoolUIComponent:Id() end)
end

---Updates the army supplies cost of the panel that lists all the units in the selected army.
function TotoWarCbacUIManager:updateUnitsPanel()
    TotoWarCbac.loggers.uiManager:logDebug("updateUnitsPanel(): STARTED")

    local unitsPanelIconListUIComponent = TotoWar.ui:getUIComponent(
        TotoWar.ui.uiComponentQueries.unitsPanelIconList)
    local armySuppliesCostText = self:getArmySuppliesCostText(TotoWarCbac.playerManager
        .selectedGeneralArmySuppliesCost)
    self:createOrUpdateArmySuppliesUIComponent(
        unitsPanelIconListUIComponent,
        armySuppliesCostText,
        TotoWarCbac.playerManager.selectedGeneralArmySuppliesCost:toArmySuppliesCostTooltipText())

    TotoWarCbac.loggers.uiManager:logDebug("updateUnitsPanel(): COMPLETED")
end
