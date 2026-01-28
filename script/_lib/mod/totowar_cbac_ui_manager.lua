---Height of the UI components that displays army supplies and army supplies cost.
---@type number
local _armySuppliesCostUIComponentHeight = 24

---Name of the UI component that displays army supplies.
---@type string
local _armySuppliesCostUIComponentName = "totowar_cbac_army_supply_cost"

---ID of the depleted army supplies warning icon.
---@type string
local _armySuppliesDepletedWarningIconId = "totowar_cbac_army_supply_depleted"

---Path of the depleted army supplies warning icon.
---@type string
local _armySuppliesDepletedWarningIconPath = "ui/skins/warhammer2/icon_status_alert_high.png"

---ID of the army supplies icon.
---@type string
local _armySuppliesIconId = "icon_merc"

---Path of the army supplies icon.
---@type string
local _armySuppliesIconPath = "ui/skins/default/merc.png"

---Name of the UI component that displays unit army supplies cost.
---@type string
local _unitArmySuppliesCostUIComponentName = "totowar_cbac_unit_army_supply_cost"

---Y offset of the UI component that displays unit army supplies cost.
---@type number
local _unitArmySuppliesCostUIComponentOffsetY = -18

---Queries for searching TotoWar Cost-Based Army Caps UI components.
---@type string[][]
local _uiComponentQuery = {
    unitsPanelArmySuppliesCost = { "units_panel", "main_units_panel", "icon_list", _armySuppliesCostUIComponentName }
}

---Manager in charge of displaying army supplies cost in the UI.
---@class TotoWarCbacUIManager
TotoWarCbacUIManager = {
    ---Indicates whether the allied recruitment unit list has been resized to be able to display army supplies cost under each unit price.
    ---It only needs to be resized once per recruitment panel opening.
    ---@type boolean
    isAlliedRecruitmentResized = nil,

    ---Indicates whether the global recruitment unit list has been resized to be able to display army supplies cost under each unit price.
    ---It only needs to be resized once per recruitment panel opening.
    ---@type boolean
    isGlobalRecruitmentResized = nil,

    ---Indicates whether the local recruitment unit list has been resized to be able to display army supplies cost under each unit price.
    ---It only needs to be resized once per recruitment panel opening.
    ---@type boolean
    isLocalRecruitmentResized = nil,

    ---Logger.
    ---@type TotoWarLogger
    logger = nil
}
TotoWarCbacUIManager.__index = TotoWarCbacUIManager

---Initializes a new instance.
---@return TotoWarCbacUIManager
function TotoWarCbacUIManager.new()
    local instance = setmetatable({}, TotoWarCbacUIManager)

    instance.logger = TotoWarLogger.new("TotoWar_Cbac_UIManager")
    isAlliedRecruitmentResized = false
    isGlobalRecruitmentResized = false
    isLocalRecruitmentResized = false

    instance.logger:logDebug("new(): COMPLETED")

    return instance
end

---Adds listeners for events.
function TotoWarCbacUIManager:addListeners()
    self.logger:logDebug("addListeners(): STARTED")

    TotoWar().utils:addListener(
        "TotoWarCbacUIManager",
        TotoWar().ui.enums.event.characterDeselected,
        function()
            return cm:is_local_players_turn()
        end,
        function()
            self:onCharacterDeselected()
        end)

    TotoWar().utils:addListener(
        "TotoWarCbacUIManager",
        TotoWar().ui.enums.event.panelOpened,
        ---@param context TotoWarEventContext_PanelOpenedOrClosed
        function(context)
            return cm:is_local_players_turn()
        end,
        ---@param context TotoWarEventContext_PanelOpenedOrClosed
        function(context)
            self:onPanelOpened(context.string)
        end)

    TotoWar().utils:addListener(
        "TotoWarCbacUIManager",
        TotoWarCbacPlayerManager.event.selectedGeneralArmySuppliesCostChanged,
        function()
            return cm:is_local_players_turn()
        end,
        function()
            self:onSelectedGeneralArmySuppliesCostChanged()
        end)

    self.logger:logDebug("addListeners(): COMPLETED")
end

---Hides the army supplies cost UI component.
function TotoWarCbacUIManager:hideArmySuppliesCostUIComponent()
    self.logger:logDebug("hideArmySuppliesCostUIComponent(): STARTED")

    local armyCostUIComponent = TotoWar().ui:findUIComponent(_uiComponentQuery.unitsPanelArmySuppliesCost)

    if armyCostUIComponent then
        armyCostUIComponent:SetVisible(false)
    end

    self.logger:logDebug("hideArmySuppliesCostUIComponent(): COMPLETED")
end

---Reacts to a character being deselected.
function TotoWarCbacUIManager:onCharacterDeselected()
    self.logger:logDebug("[EVENT] onCharacterDeselected(): STARTED")

    self.isAlliedRecruitmentResized = false
    self.isGlobalRecruitmentResized = false
    self.isLocalRecruitmentResized = false

    self.logger:logDebug("[EVENT] onCharacterDeselected(): COMPLETED")
end

---Reacts to a panel being opened.
---@param panelName string Name of the panel;
function TotoWarCbacUIManager:onPanelOpened(panelName)
    if panelName == TotoWar().ui.enums.panel.unitsPanel then
        --- We do not need to update the units_panel when it is opened, because it is the
        --- fact that it is opened that triggers the army supplies cost calculation.
        --- So when it is opened, the army supplies cost is not up to date.
        --- It is later updated when the SelectedGeneralArmySuppliesCostChanged event is triggered.
        return
    end

    self.logger:logDebug("[EVENT] onPanelOpened(%s): STARTED", panelName)

    self:updateOpenRecruitmentPanel(panelName)

    self.logger:logDebug("[EVENT] onPanelOpened(%s): COMPLETED", panelName)
end

---Reacts to the army supplies cost of the selected general changing.
function TotoWarCbacUIManager:onSelectedGeneralArmySuppliesCostChanged()
    self.logger:logDebug("[EVENT] onSelectedGeneralArmySuppliesCostChanged(): STARTED")

    self:updateUnitsPanel()
    self:updateOpenRecruitmentPanel()

    self.logger:logDebug("[EVENT] onSelectedGeneralArmySuppliesCostChanged(): COMPLETED")
end

---Updates the allied recruitment panel.
function TotoWarCbacUIManager:updateAlliedRecruitmentPanel()
    self.logger:logDebug("updateAlliedRecruitmentPanel(): STARTED")

    local alliedRecruitmentPoolUIComponent = TotoWar().ui:getUIComponent(
        TotoWar().ui.uiComponentQueries.alliedRecruitmentPool)

    local unitListQuery = { "listview", "list_clip", "allied_unit_list" }

    if not self.isAlliedRecruitmentResized then
        -- The listview and its content needs to be resized once until the recruitment panel is closed
        TotoWar().ui:resizeUIComponentAndChildren(
            alliedRecruitmentPoolUIComponent,
            0,
            _armySuppliesCostUIComponentHeight,
            unitListQuery)
        self.isAlliedRecruitmentResized = true;
    end

    local unitListUIComponent = TotoWar().ui:findUIComponentChild(
        alliedRecruitmentPoolUIComponent,
        unitListQuery)

    if unitListUIComponent then
        self:updateRecruitableUnitCardList(unitListUIComponent)
    end

    self.logger:logDebug("updateAlliedRecruitmentPanel(): COMPLETED")
end

---Updates the mercenary recruitment panel.
function TotoWarCbacUIManager:updateMercenaryRecruitmentPanel()
    self.logger:logDebug("updateMercenaryRecruitmentPanel(): STARTED")

    local mercenaryRecruitmentPoolUIComponent = TotoWar().ui:getUIComponent(
        TotoWar().ui.uiComponentQueries.mercenaryRecruitmentPool)

    local mercenaryUnitListQuery = { "listview", "list_clip", "list_box" }
    local unitListUIComponent = TotoWar().ui:getUIComponentChild(
        mercenaryRecruitmentPoolUIComponent,
        mercenaryUnitListQuery)

    -- The list_box needs to be resized each time the mercenary panel is opened
    TotoWar().ui:resizeUIComponent(
        unitListUIComponent,
        0,
        _armySuppliesCostUIComponentHeight)
    self:updateRecruitableUnitCardList(unitListUIComponent)

    self.logger:logDebug("updateMercenaryRecruitmentPanel(): COMPLETED")
end

---Updates army supplies costs on open recruitment panels.
---@param panelName string | nil Name of the panel to update. If nil, we search for an open recruitment panel to update them.
function TotoWarCbacUIManager:updateOpenRecruitmentPanel(panelName)
    if panelName then
        self.logger:logDebug("updateRecruitmentPanels(%s): STARTED", panelName)

        if panelName == TotoWar().ui.enums.panel.standardRecruitment then
            self:updateStandardRecruitmentPanel()
        elseif panelName == TotoWar().ui.enums.panel.mercenaryRecruitment then
            self:updateMercenaryRecruitmentPanel()
        elseif panelName == TotoWar().ui.enums.panel.alliedRecruitment then
            self:updateAlliedRecruitmentPanel()
        end

        self.logger:logDebug("updateRecruitmentPanels(%s): COMPLETED", panelName)
    else
        self.logger:logDebug("updateRecruitmentPanels(): STARTED")

        if cm:get_campaign_ui_manager():is_panel_open(TotoWar().ui.enums.panel.standardRecruitment) then
            self:updateStandardRecruitmentPanel()
        elseif cm:get_campaign_ui_manager():is_panel_open(TotoWar().ui.enums.panel.mercenaryRecruitment) then
            self:updateMercenaryRecruitmentPanel()
        elseif cm:get_campaign_ui_manager():is_panel_open(TotoWar().ui.enums.panel.alliedRecruitment) then
            self:updateAlliedRecruitmentPanel()
        end

        self.logger:logDebug("updateRecruitmentPanels(): COMPLETED")
    end
end

---Updates the army supplies cost of a recruitable unit card.
---@param unitCardUIComponent UIC Unit card UI component.
function TotoWarCbacUIManager:updateRecruitableUnitCard(unitCardUIComponent)
    local unitContext = TotoWar().ui:getUIComponentCCO(
        unitCardUIComponent,
        TotoWar().ui.enums.ccoContextTypeId.ccoMainUnitRecord)

    local unitName = unitContext:Call("Name")
    local unitBaseCost = tonumber(unitContext:Call("BaseCost"))

    self.logger:logDebug(
        "updateRecruitableUnitCard(%s): STARTED => (%s, %s)",
        unitCardUIComponent:Id(),
        unitName,
        unitBaseCost)

    local armySuppliesCostUIComponent = TotoWar().ui:findUIComponentChild(
        unitCardUIComponent,
        { "external_holder", _unitArmySuppliesCostUIComponentName })

    if not armySuppliesCostUIComponent then
        TotoWar().ui:resizeUIComponent(unitCardUIComponent, 0, _armySuppliesCostUIComponentHeight)

        local externalHolderUIComponent = TotoWar().ui:getUIComponentChild(
            unitCardUIComponent,
            { "external_holder" })
        TotoWar().ui:resizeUIComponent(externalHolderUIComponent, 0, _armySuppliesCostUIComponentHeight)

        -- Moving up each cost / upkeep component (they are docked at the bottom) to display the army supplies cost component last
        TotoWar().ui:offsetChildUIComponents(externalHolderUIComponent, 0, -_armySuppliesCostUIComponentHeight)

        -- Copying the recruitment cost UI component to create the army supplies cost UI component
        local upkeepCostUIComponent = TotoWar().ui:getUIComponentChild(externalHolderUIComponent, { "UpkeepCost" })
        local xPadding = upkeepCostUIComponent:GetDockOffset()
        armySuppliesCostUIComponent = UIComponent(upkeepCostUIComponent:CopyComponent(
            _unitArmySuppliesCostUIComponentName))
        armySuppliesCostUIComponent:SetDockOffset(xPadding, _unitArmySuppliesCostUIComponentOffsetY)
        armySuppliesCostUIComponent:SetTooltipText(
            common.get_localised_string("totowar_cbac_unit_army_supply_cost_tooltip"),
            true)
    end

    local unitBaseCostText = tostring(unitBaseCost)

    -- Disabling the unit card when its the army supplies exceeds the available army supplies of the selected general
    if unitBaseCost > TotoWar_Cbac().playerManager.selectedGeneralArmySuppliesCost.availableSupplies then
        self.logger:logDebug(
            "updateRecruitableUnitCard(%s): UNIT RECRUITMENT DISABLED => (%s, %s)",
            unitCardUIComponent:Id(),
            unitName,
            unitBaseCost)

        --unitCardUIComponent:SetDisabled(true)
        unitCardUIComponent:SetState("inactive")
        unitBaseCostText = string.format("[[col:%s]]%s[[/col]]", TotoWar().utils.enums.color.red, unitBaseCostText)
    end

    local armyCostUIComponentDetailUIComponent = TotoWar().ui:getUIComponentChild(armySuppliesCostUIComponent,
        { "Upkeep" })
    armyCostUIComponentDetailUIComponent:DestroyChildren() -- Removing the price change arrow copied from the Upkeep UI component
    armyCostUIComponentDetailUIComponent:SetText(unitBaseCostText, "")
    armyCostUIComponentDetailUIComponent:SetImagePath(_armySuppliesIconPath, 0, false)

    self.logger:logDebug(
        "updateRecruitableUnitCard(%s): COMPLETED => (%s, %s)",
        unitCardUIComponent:Id(),
        unitName,
        unitBaseCost)
end

---Updates the army supplies cost of a list of recruitable unit cards.
---@param unitCardListUIComponent UIC UI component that contains the list of recruitable units cards.
function TotoWarCbacUIManager:updateRecruitableUnitCardList(
    unitCardListUIComponent)
    self.logger:logDebug("updateRecruitableUnitCardList(%s): STARTED", unitCardListUIComponent:Id())

    for i = 0, unitCardListUIComponent:ChildCount() - 1 do
        local unitCardUIComponent = find_child_uicomponent_by_index(unitCardListUIComponent, i)
        self:updateRecruitableUnitCard(unitCardUIComponent)
    end

    self.logger:logDebug("updateRecruitableUnitCardList(%s): COMPLETED", unitCardListUIComponent:Id())
end

---Updates the standard recruitment panel.
function TotoWarCbacUIManager:updateStandardRecruitmentPanel()
    self.logger:logDebug("updateStandardRecruitmentPanel(): STARTED")

    -- Global recruitment
    local globalRecruitmentPoolUIComponent = TotoWar().ui:getUIComponent(
        TotoWar().ui.uiComponentQueries.globalRecruitmentPool)

    if globalRecruitmentPoolUIComponent then
        local unitListQuery = { "listview", "list_clip", "list_box" }

        if not self.isGlobalRecruitmentResized then
            -- The listview and its content needs to be resized once until the recruitment panel is closed
            TotoWar().ui:resizeUIComponentAndChildren(
                globalRecruitmentPoolUIComponent,
                0,
                _armySuppliesCostUIComponentHeight,
                unitListQuery)
            self.isGlobalRecruitmentResized = true
        end

        local unitListUIComponent = TotoWar().ui:findUIComponentChild(
            globalRecruitmentPoolUIComponent,
            unitListQuery)

        if unitListUIComponent then
            self:updateRecruitableUnitCardList(unitListUIComponent)
        end
    end

    -- Local recruitment
    local localRecruitmentPoolUIComponent = TotoWar().ui:findUIComponent(
        TotoWar().ui.uiComponentQueries.localRecruitmentPool)

    if localRecruitmentPoolUIComponent then
        local unitCardListQuery = { "listview", "list_clip", "list_box" }

        if not self.isLocalRecruitmentResized then
            -- The listview and its content needs to be resized once until the recruitment panel is closed
            TotoWar().ui:resizeUIComponentAndChildren(
                localRecruitmentPoolUIComponent,
                0,
                _armySuppliesCostUIComponentHeight,
                unitCardListQuery)
            self.isLocalRecruitmentResized = true
        end

        local unitCardListUIComponent = TotoWar().ui:findUIComponentChild(
            localRecruitmentPoolUIComponent,
            unitCardListQuery)

        if unitCardListUIComponent then
            self:updateRecruitableUnitCardList(unitCardListUIComponent)
        end
    end

    self.logger:logDebug("updateStandardRecruitmentPanel(): COMPLETED")
end

---Updates the army supplies cost of the panel that lists all the units in the selected army.
function TotoWarCbacUIManager:updateUnitsPanel()
    self.logger:logDebug("updateUnitsPanel(): STARTED")

    local armySuppliesCostUIComponent = TotoWar().ui:findUIComponent(_uiComponentQuery.unitsPanelArmySuppliesCost)

    if not armySuppliesCostUIComponent then
        -- If the army supplies cost is not already displayed,
        -- copying the upkeep cost UI component to create the army supplies cost UI component
        local unitsPanelIconListUIComponent = TotoWar().ui:getUIComponent(
            TotoWar().ui.uiComponentQueries.unitsPanelIconList)
        local upkeepUIComponent = TotoWar().ui:getUIComponentChild(unitsPanelIconListUIComponent, { "dy_upkeep" })
        armySuppliesCostUIComponent = UIComponent(upkeepUIComponent:CopyComponent(_armySuppliesCostUIComponentName))
        armySuppliesCostUIComponent:SetImagePath(_armySuppliesIconPath, 1, false)
    end

    local armySuppliesCostText = ""

    if TotoWar_Cbac().playerManager.selectedGeneralArmySuppliesCost.availableSupplies < 0 then
        armySuppliesCostText = string.format(
            "[[col:%s]]%s[[/col]][[img:%s]][[/img]]",
            TotoWar().utils.enums.color.red,
            TotoWar_Cbac().playerManager.selectedGeneralArmySuppliesCost.availableSupplies,
            _armySuppliesDepletedWarningIconId)
    else
        armySuppliesCostText = tostring(TotoWar_Cbac().playerManager.selectedGeneralArmySuppliesCost.availableSupplies)
    end

    armySuppliesCostUIComponent:SetText(armySuppliesCostText, "")
    armySuppliesCostUIComponent:SetTooltipText(
        TotoWar_Cbac().playerManager.selectedGeneralArmySuppliesCost:toArmySuppliesCostTooltipText(),
        true)
    armySuppliesCostUIComponent:SetVisible(true)

    self.logger:logDebug("updateUnitsPanel(): COMPLETED")
end
