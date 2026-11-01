local logger = TotoWar__Logger.get(TotoWar_Cbac_Enum_LogCategories.uiManager)

---Height of the UI components that displays army supplies and army supplies cost.
local _armySuppliesCostUIComponentHeight = 24

---Name of the UI component that displays army supplies.
local _armySuppliesUIComponentName = "totowar_cbac_army_supplies"

---ID of the depleted army supplies warning icon.
local _armySuppliesDepletedWarningIconId = "totowar_alert"

---Path of the army supplies icon.
local _armySuppliesIconPath = "ui/totowar_cbac/icons/totowar_cbac_army_supplies.png"

---Recruitment pools of a recruitment panel on which army supplies costs are displayed.
---@class TotoWar_Cbac_RecruitmentPoolUI
---@field listQuery string Query to the UI component that contains one recruitment pool per child. Children without unit card list are ignored.
---@field name string Name, used in logs.
---@field unitCardListQuery string Query from a recruitment pool to the list of its unit cards. The UI components along this query have a fixed height: they are enlarged so that army supplies costs fit under the unit cards.

---Recruitment pools on which army supplies costs are displayed.
---@type TotoWar_Cbac_RecruitmentPoolUI[]
local _recruitmentPools = {
    {
        listQuery = TotoWar__UI.uiComponentQueries.unitsPanel_recruitmentOptions_alliedRecruitmentDisplay,
        name = "allied",
        unitCardListQuery = "unit_list/listview/list_clip/allied_unit_list"
    },
    {
        listQuery = TotoWar__UI.uiComponentQueries.unitsPanel_recruitmentOptions_mercenaryRecruitmentPoolList,
        name = "mercenary",
        unitCardListQuery = "listview/list_clip/list_box"
    },
    {
        listQuery = TotoWar__UI.uiComponentQueries.unitsPanel_recruitmentOptions_standardRecruitmentPoolList,
        name = "standard",
        unitCardListQuery = "unit_list/listview/list_clip/list_box"
    }
}

---Name of the property that stores the size of a UI component enlarged by the mod.
local _resizedUIComponentSizePropertyName = "totowar_cbac_resized_size"

---Template of the UI component that displays unit army supplies.
local _unitArmySuppliesUIComponentTemplate = "ui/totowar/totowar_icon_value.twui.xml"

---Unit card of a unit exchange pool.
---@class TotoWar_Cbac_UnitExchangePoolCard
---@field characterCqi integer | nil CQI of the character represented by the card, `nil` for a unit card.
---@field isSelected boolean Indicates whether the card is selected to be transferred to the other army.
---@field unitKey string | nil Key of the unit represented by the card, `nil` for a character card.

---Creates the army supplies UI component and registers it as a child of a parent component.
---@param parentUIComponent UIC Parent UI component.
local function createArmySuppliesUIComponent(parentUIComponent)
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
local function createOrUpdateArmySuppliesUIComponent(
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
        _armySuppliesUIComponentName)

    if armySuppliesUIComponent == nil then
        armySuppliesUIComponent = createArmySuppliesUIComponent(parentUIComponent)
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
local function findOpenRecruitmentPools()
    logger:logDebug("findOpenRecruitmentPools(): STARTED")

    local recruitmentPools = {}

    for index, recruitmentPool in ipairs(_recruitmentPools) do
        local uiComponent = TotoWar__UI:findUIComponent(recruitmentPool.listQuery)

        if uiComponent and uiComponent:Visible(true) then
            table.insert(recruitmentPools, recruitmentPool)
        end
    end

    logger:logDebug("findOpenRecruitmentPools(): COMPLETED")

    return recruitmentPools
end

---Gets the text representing an army supplies cost.
---@param armySuppliesCost TotoWar_Cbac_ArmySuppliesCost Army supplies cost.
local function getArmySuppliesCostText(armySuppliesCost)
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

---Hides the army supplies cost UI component.
local function hideArmySuppliesCostUIComponent()
    logger:logDebug("hideArmySuppliesCostUIComponent(): STARTED")

    local unitsPanelIconListUIComponent = TotoWar__UI:findUIComponent(
        TotoWar__UI.uiComponentQueries.unitsPanel_iconList)

    if unitsPanelIconListUIComponent then
        local armyCostUIComponent = TotoWar__UI:findUIComponentChild(
            unitsPanelIconListUIComponent,
            _armySuppliesUIComponentName)

        if armyCostUIComponent then
            armyCostUIComponent:SetVisible(false)
        end
    end

    logger:logDebug("hideArmySuppliesCostUIComponent(): COMPLETED")
end

---Reacts to a character being deselected.
local function onCharacterDeselected()
    logger:logDebug("onCharacterDeselected(): STARTED")

    hideArmySuppliesCostUIComponent()

    logger:logDebug("onCharacterDeselected(): COMPLETED")
end

---Reacts to options being updated.
local function onOptionsUpdated()
    logger:logDebug("onOptionsUpdated(): STARTED")

    -- Clearing the selection for two reasons :
    -- - it resets its movement if the selected character was not able to move, otherwise the character could not be move anymore if the player army supplies option has been disabled
    -- - it closes the unit list and recruitment UI which will hide army supplies if the player army supplies option has been disabled
    CampaignUI.ClearSelection()

    logger:logDebug("onOptionsUpdated(): COMPLETED")
end

---Reacts to the another faction character being selected.
local function onOtherFactionCharacterSelected()
    logger:logDebug("onOtherFactionCharacterSelected(): STARTED")

    hideArmySuppliesCostUIComponent()

    logger:logDebug("onOtherFactionCharacterSelected(): COMPLETED")
end

---Updates the army supplies cost of a unit exchange pool.
---@param unitExchangePoolUIComponent UIC Unit exchange pool UI component.
---@param armySuppliesCost TotoWar_Cbac_ArmySuppliesCost Army supplies cost.
local function updateUnitExchangePool(unitExchangePoolUIComponent, armySuppliesCost)
    logger:logDebug(
        "updateUnitExchangePool(%s, armySuppliesCost): STARTED",
        function() return unitExchangePoolUIComponent:Id() end)

    local parent = TotoWar__UI:getUIComponentChild(unitExchangePoolUIComponent, "panel_smoke_t")
    local armySuppliesCostText = getArmySuppliesCostText(armySuppliesCost)
    local armySuppliesCostTooltip = armySuppliesCost:toArmySuppliesCostTooltipText()
    createOrUpdateArmySuppliesUIComponent(
        parent,
        armySuppliesCostText,
        armySuppliesCostTooltip)

    logger:logDebug(
        "updateUnitExchangePool(%s, armySuppliesCost): COMPLETED",
        function() return unitExchangePoolUIComponent:Id() end)
end

---Reacts to the army supplies cost of armies exchanging units changing.
local function onUnitExchangeArmySuppliesCostChanged()
    logger:logDebug("onUnitExchangeArmySuppliesCostChanged(): STARTED")

    local unitExchangePool1UIComponent = TotoWar__UI:getUIComponent(
        TotoWar__UI.uiComponentQueries.unitExchange_pool1)
    updateUnitExchangePool(unitExchangePool1UIComponent, TotoWar_Cbac_PlayerManager.unitExchangeArmySuppliesCost1)

    local unitExchangePool2UIComponent = TotoWar__UI:getUIComponent(
        TotoWar__UI.uiComponentQueries.unitExchange_pool2)
    updateUnitExchangePool(unitExchangePool2UIComponent, TotoWar_Cbac_PlayerManager.unitExchangeArmySuppliesCost2)

    logger:logDebug("onUnitExchangeArmySuppliesCostChanged(): COMPLETED")
end

---Reacts to the army supplies cost changing due to a warband upgrade.
local function onWarbandUpgradeArmySuppliesCostChanged()
    logger:logDebug("onWarbandUpgradeArmySuppliesCostChanged(): STARTED")

    -- Enlarging the requirements holder, which has a fixed height, to have space to add the army supplies after
    -- upgrade line. Its parents fit their content.
    local requirementsHolderComponent = TotoWar__UI:getUIComponent(
        TotoWar__UI.uiComponentQueries.unitsPanel_warbandUpgradesRequirementsHolder)
    TotoWar__UI:resizeUIComponentOnce(
        requirementsHolderComponent,
        0,
        _armySuppliesCostUIComponentHeight,
        _resizedUIComponentSizePropertyName)

    -- Moving the upgrade button to the bottom of the enlarged requirements holder
    local upgradeButtonComponent = TotoWar__UI:getUIComponentChild(requirementsHolderComponent, "button_invoke")
    upgradeButtonComponent:SetDockingPoint(TotoWar__Enum_DockingPoints.bottomMiddle)
    UIComponent(requirementsHolderComponent:Parent()):Layout()

    -- Adding / updating the army supplies after upgrade component
    if (TotoWar_Cbac_PlayerManager.warbandUpgradeArmySuppliesCost ~= nil) then
        local armySuppliesCostText = getArmySuppliesCostText(
            TotoWar_Cbac_PlayerManager.warbandUpgradeArmySuppliesCost)
        local armySuppliesCostTooltip =
            TotoWar_Cbac_PlayerManager.warbandUpgradeArmySuppliesCost:toArmySuppliesCostTooltipText()

        local armySuppliesCostContainerComponentName = "totowar_cbac_warband_upgrade_army_supplies"
        local warbandUpgradesRequirementsComponent = TotoWar__UI:getUIComponent(
            TotoWar__UI.uiComponentQueries.unitsPanel_warbandUpgradesRequirements)
        local armySuppliesCostContainerComponent = TotoWar__UI:findUIComponentChild(
            warbandUpgradesRequirementsComponent,
            armySuppliesCostContainerComponentName)

        if armySuppliesCostContainerComponent == nil then
            -- Copying the total cost container component to create the army supplies cost container
            local totalCostContainerComponent = TotoWar__UI:getUIComponentChild(
                warbandUpgradesRequirementsComponent,
                "total_cost")
            local armySuppliesCostContainerComponentAddress = totalCostContainerComponent:CopyComponent(
                armySuppliesCostContainerComponentName)
            armySuppliesCostContainerComponent = UIComponent(armySuppliesCostContainerComponentAddress)
            armySuppliesCostContainerComponent:SetVisible(true)

            local armySuppliesCostCaptionComponent = TotoWar__UI:getUIComponentChild(
                armySuppliesCostContainerComponent,
                "tx_total_cost")
            armySuppliesCostCaptionComponent:SetStateText(common.get_localised_string(
                "totowar_cbac_warbandUpgradeArmySuppliesCost"))

            -- Deleting the copied value component that will get replaced by the army supplies cost component
            local copiedValueComponentToReplace = TotoWar__UI:getUIComponentChild(
                armySuppliesCostContainerComponent,
                "total_cost_holder")
            copiedValueComponentToReplace:Destroy()
        end

        local armySuppliesCostComponent = createOrUpdateArmySuppliesUIComponent(
            armySuppliesCostContainerComponent,
            armySuppliesCostText,
            armySuppliesCostTooltip)
        armySuppliesCostComponent:SetDockingPoint(TotoWar__Enum_DockingPoints.middleRight)
        armySuppliesCostComponent:SetDockOffset(15, 0)
    end

    logger:logDebug("onWarbandUpgradeArmySuppliesCostChanged(): COMPLETED")
end

---Updates the army supplies cost of a recruitable unit card.
---@param unitCardUIComponent UIC Unit card UI component.
local function updateRecruitableUnitCard(unitCardUIComponent)
    local unitContext = TotoWar__UI:getUIComponentCCO(
        unitCardUIComponent,
        TotoWar__Enum_CcoContextTypeIds.mainUnitRecord)

    local unitCost = TotoWar_Cbac_UnitArmySuppliesCost:getUnitCost(unitContext:Call("Key"))

    local armySuppliesCostUIComponent = TotoWar__UI:findUIComponentChild(
        unitCardUIComponent,
        "external_holder/" .. _armySuppliesUIComponentName)

    if armySuppliesCostUIComponent == nil then
        local externalHolderUIComponent = TotoWar__UI:getUIComponentChild(unitCardUIComponent, "external_holder")
        local visibleComponentsCount = 0
        local visibleComponentsHeight = 0

        for i = 0, unitCardUIComponent:ChildCount() - 1, 1 do
            local childUIComponent = find_child_uicomponent_by_index(externalHolderUIComponent, i)

            if childUIComponent:Visible() then
                visibleComponentsCount = visibleComponentsCount + 1
                visibleComponentsHeight = childUIComponent:Height()
            end
        end

        armySuppliesCostUIComponent = createArmySuppliesUIComponent(externalHolderUIComponent)
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

    local unitCostText = tostring(unitCost)
    local selectedLordArmySuppliesCost = TotoWar_Cbac_PlayerManager.selectedLordArmySuppliesCost

    -- The army supplies cost of the selected lord is nil while it is being initialized
    if selectedLordArmySuppliesCost ~= nil and unitCost > selectedLordArmySuppliesCost.availableSupplies then
        -- Displaying the army supplies cost is red when it exceeds the available army supplies
        unitCostText = string.format("[[col:%s]]%s[[/col]]", "red", unitCostText)
    end

    if armySuppliesCostUIComponent ~= nil then
        armySuppliesCostUIComponent:SetText(unitCostText, "")
    end
end

---Updates the army supplies cost of a list of recruitable unit cards.
---@param unitCardListUIComponent UIC UI component that contains the list of recruitable units cards.
local function updateRecruitableUnitCardList(
    unitCardListUIComponent)
    logger:logDebug(
        "updateRecruitableUnitCardList(%s): STARTED",
        function() return unitCardListUIComponent:Id() end)

    for i = 0, unitCardListUIComponent:ChildCount() - 1 do
        local unitCardUIComponent = find_child_uicomponent_by_index(unitCardListUIComponent, i)
        updateRecruitableUnitCard(unitCardUIComponent)
    end

    logger:logDebug(
        "updateRecruitableUnitCardList(%s): COMPLETED",
        function() return unitCardListUIComponent:Id() end)
end

---Updates the army supplies costs displayed on a recruitment pool.
---@param recruitmentPool TotoWar_Cbac_RecruitmentPoolUI Description of the recruitment pool.
---@param recruitmentPoolUIComponent UIC Recruitment pool UI component.
local function updateRecruitmentPool(recruitmentPool, recruitmentPoolUIComponent)
    logger:logDebug(
        "updateRecruitmentPool(%s, %s): STARTED",
        recruitmentPool.name,
        function() return recruitmentPoolUIComponent:Id() end)

    local unitCardListUIComponent = TotoWar__UI:findUIComponentChild(
        recruitmentPoolUIComponent,
        recruitmentPool.unitCardListQuery)

    -- Recruitment pools in which recruitment is not possible are minimised and have no unit card list,
    -- other children of a list of recruitment pools (headers, padding...) neither
    if unitCardListUIComponent == nil then
        logger:logDebug(
            "updateRecruitmentPool(%s, %s): COMPLETED => No unit card list",
            recruitmentPool.name,
            function() return recruitmentPoolUIComponent:Id() end)

        return
    end

    updateRecruitableUnitCardList(unitCardListUIComponent)

    -- Enlarging the UI components along the query to the unit card list, which have a fixed height
    TotoWar__UI:resizeUIComponentChildrenOnce(
        recruitmentPoolUIComponent,
        recruitmentPool.unitCardListQuery,
        0,
        _armySuppliesCostUIComponentHeight,
        _resizedUIComponentSizePropertyName)

    -- The recruitment pool fits its content
    recruitmentPoolUIComponent:Layout()

    logger:logDebug(
        "updateRecruitmentPool(%s, %s): COMPLETED",
        recruitmentPool.name,
        function() return recruitmentPoolUIComponent:Id() end)
end

---Updates army supplies costs on recruitment pools.
---@param recruitmentPools TotoWar_Cbac_RecruitmentPoolUI[] Recruitment pools.
local function updateRecruitmentPools(recruitmentPools)
    logger:logDebug("updateRecruitmentPools(recruitmentPools): STARTED")

    for key, recruitmentPool in pairs(recruitmentPools) do
        ---@cast recruitmentPool TotoWar_Cbac_RecruitmentPoolUI

        logger:logDebug(
            "updateRecruitmentPools(recruitmentPools): UPDATING => %s",
            recruitmentPool.name)

        local recruitmentPoolListUIComponent = TotoWar__UI:findUIComponent(recruitmentPool.listQuery)

        if recruitmentPoolListUIComponent ~= nil then
            for i = 0, recruitmentPoolListUIComponent:ChildCount() - 1, 1 do
                updateRecruitmentPool(recruitmentPool, find_child_uicomponent_by_index(recruitmentPoolListUIComponent, i))
            end
        end
    end

    logger:logDebug("updateRecruitmentPools(recruitmentPools): COMPLETED")
end

---Updates the army supplies cost of the panel that lists all the units in the selected army.
local function updateUnitsPanel()
    logger:logDebug("updateUnitsPanel(): STARTED")

    if TotoWar_Cbac_PlayerManager.selectedLordArmySuppliesCost == nil then
        -- This occurs when a player faction army is selected, and we select an isolated player faction hero.
        -- The units panel is not closed and the CharacterDeselected event is not triggered by the game.
        -- We still manage to set selectedLordArmySuppliesCost to nil.
        -- In that case, we need to hide the army supplies component.
        hideArmySuppliesCostUIComponent()
    else
        local armySuppliesCostText = getArmySuppliesCostText(
            TotoWar_Cbac_PlayerManager.selectedLordArmySuppliesCost)
        local armySuppliesCostTooltip =
            TotoWar_Cbac_PlayerManager.selectedLordArmySuppliesCost:toArmySuppliesCostTooltipText()

        local unitsPanelIconListUIComponent = TotoWar__UI:findUIComponent(
            TotoWar__UI.uiComponentQueries.unitsPanel_iconList)

        if unitsPanelIconListUIComponent ~= nil then
            createOrUpdateArmySuppliesUIComponent(
                unitsPanelIconListUIComponent,
                armySuppliesCostText,
                armySuppliesCostTooltip)
        end
    end

    logger:logDebug("updateUnitsPanel(): COMPLETED")
end

---Updates the army supplies displayed on the visible screens: units panel and recruitment pools.
local function updateScreens()
    logger:logDebug("updateScreens(): STARTED")

    -- The screens are updated when the army supplies cost of the newly selected lord is initialized
    if TotoWar_Cbac_PlayerManager.isInitializingArmySuppliesCost then
        logger:logDebug("updateScreens(): COMPLETED => Not updated, army supplies cost being initialized")

        return
    end

    updateUnitsPanel()
    updateRecruitmentPools(findOpenRecruitmentPools())

    logger:logDebug("updateScreens(): COMPLETED")
end

---Manager in charge of displaying army supplies cost in the UI.
---@class TotoWar_Cbac_UIManager
TotoWar_Cbac_UIManager = {
    ---Indicates whether an update of the screens is scheduled.
    ---@type boolean
    isScreenUpdateScheduled = nil
}

---Gets the unit cards of a unit exchange pool.
---@param unitExchangePoolUIComponentQuery string Query to the unit exchange pool UI component.
---@return TotoWar_Cbac_UnitExchangePoolCard[]
function TotoWar_Cbac_UIManager:getUnitExchangePoolCards(unitExchangePoolUIComponentQuery)
    logger:logDebug(
        "getUnitExchangePoolCards(%s): STARTED",
        unitExchangePoolUIComponentQuery)

    ---@type TotoWar_Cbac_UnitExchangePoolCard[]
    local unitCards = {}
    local unitExchangePoolUIComponent = TotoWar__UI:getUIComponent(unitExchangePoolUIComponentQuery)
    local unitListUIComponent = TotoWar__UI:getUIComponentChild(unitExchangePoolUIComponent, "units")

    for i = 0, unitListUIComponent:ChildCount() - 1, 1 do
        ---@type UIC | false
        local unitCardUIComponent = find_child_uicomponent_by_index(unitListUIComponent, i)

        if unitCardUIComponent then
            local characterCqi = TotoWar__UI:getUnitCardCharacterCqi(unitCardUIComponent)
            local unitKey = nil

            if characterCqi == nil then
                unitKey = TotoWar__UI:getUnitCardUnitKey(unitCardUIComponent)
            end

            table.insert(unitCards, {
                characterCqi = characterCqi,
                isSelected = TotoWar__UI:isUIComponentSelected(unitCardUIComponent),
                unitKey = unitKey
            })
        end
    end

    logger:logDebug(
        "getUnitExchangePoolCards(%s): COMPLETED => %s unit card(s)",
        unitExchangePoolUIComponentQuery,
        #unitCards)

    return unitCards
end

---Initializes the UI manager.
function TotoWar_Cbac_UIManager:initialize()
    logger:logDebug("initialize(): STARTED")

    self.isScreenUpdateScheduled = false
    self:subscribeToEvents()

    logger:logDebug("initialize(): COMPLETED")
end

---Schedules an update of the army supplies displayed on the visible screens.
---The update is deferred to the next update of the interface, so that the game has finished building the screens,
---and the triggers that occur meanwhile lead to a single update.
function TotoWar_Cbac_UIManager:scheduleScreenUpdate()
    logger:logDebug(
        "scheduleScreenUpdate(): STARTED => Already scheduled: %s",
        self.isScreenUpdateScheduled)

    if self.isScreenUpdateScheduled == false then
        self.isScreenUpdateScheduled = true

        TotoWar__Utils:delayInRealTime(
            function()
                self.isScreenUpdateScheduled = false
                updateScreens()
            end,
            1)
    end

    logger:logDebug("scheduleScreenUpdate(): COMPLETED")
end

---Subscribes to events.
function TotoWar_Cbac_UIManager:subscribeToEvents()
    logger:logDebug("subscribeToEvents(): STARTED")

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_GameEvents.characterDeselected,
        function() onCharacterDeselected() end,
        function()
            -- We do not check the TotoWar_Cbac_Mod.options.playerArmySuppliesEnabled option because when this option
            -- is disabled, we deselect everything and we want onCharacterDeselected to be executed
            -- to reset UI elements.
            return cm:is_local_players_turn(true)
        end)

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_GameEvents.componentLeftClick,
        -- Choosing another faction in the allied recruitment rebuilds the unit cards, without army supplies costs
        function() self:scheduleScreenUpdate() end,
        ---@param context TotoWar__GameEventContext_ComponentLeftClick
        function(context)
            return
                TotoWar_Cbac_Mod.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn(true)
                and TotoWar__UI:isUIComponentChildOf(
                    UIComponent(context.component),
                    { "allied_factions_dropdown", "popup_list" })
        end)

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_GameEvents.characterSelected,
        function() onOtherFactionCharacterSelected() end,
        ---@param context CharacterSelected
        function(context)
            return
                TotoWar_Cbac_Mod.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn(true)
                and not TotoWar__Gameplay:isLocalPlayerFaction(context:character():faction():name())
        end)

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_ModEvents.optionsUpdated,
        function() onOptionsUpdated() end)

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_GameEvents.panelOpened,
        -- The recruitment pools are built when their panel opens
        function() self:scheduleScreenUpdate() end,
        ---@param context TotoWar__GameEventContext_PanelOpenedOrClosed
        function(context)
            return
                TotoWar_Cbac_Mod.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn(true)
                and (context.string == TotoWar__Enum_Panels.standardRecruitment
                    or context.string == TotoWar__Enum_Panels.mercenaryRecruitment)
        end)

    TotoWar__EventsManager:subscribe(
        TotoWar_Cbac_Enum_ModEvents.selectedLordArmySuppliesCostChanged,
        -- The available army supplies change the army supplies displayed and the colour of the unit costs
        function() self:scheduleScreenUpdate() end,
        function()
            return
                TotoWar_Cbac_Mod.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn(true)
        end)

    TotoWar__EventsManager:subscribe(
        TotoWar_Cbac_Enum_ModEvents.unitExchangeArmySuppliesCostChanged,
        function() onUnitExchangeArmySuppliesCostChanged() end,
        function()
            return
                TotoWar_Cbac_Mod.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn(true)
        end)

    TotoWar__EventsManager:subscribe(
        TotoWar_Cbac_Enum_ModEvents.warbandUpgradeArmySuppliesCostChanged,
        function() onWarbandUpgradeArmySuppliesCostChanged() end,
        function()
            return
                TotoWar_Cbac_Mod.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn(true)
        end)

    logger:logDebug("subscribeToEvents(): COMPLETED")
end
