---Name of the TotoWar Cost-Based Army Caps mod.
---@type string
TotoWarCbacModName = "totowar_cost_based_army_caps"

---Default amount of army supplies per army.
---Sadly, it cannot be read from DB table (mp_budgets_table) because LUA scripts do not not have access to them.
---@type number
local _defaultArmySupplies = 12400

---@type TotoWarCbac
local _instance = nil

---TotoWar mod form managing cost-Based army caps.
---@class TotoWarCbac
TotoWarCbac = {
    ---Total army supplies in an army.
    ---@type number
    armyTotalArmySupplies = nil,

    ---Logger.
    ---@type TotoWarLogger
    logger = nil,

    ---@type TotoWarCbacPlayerManager
    playerManager = nil,

    ---@type TotoWarCbacUIManager
    uiManager = nil

}
TotoWarCbac.__index = TotoWarCbac

---Gets the TotoWarCbac mod instance.
---@return TotoWarCbac
function TotoWar_Cbac()
    return _instance
end

---Initializes a new instance.
---@return TotoWarCbac
function TotoWarCbac.new()
    _instance = setmetatable({}, TotoWarCbac)

    _instance.logger = TotoWarLogger.new("TotoWar_Cbac")

    _instance.armyTotalArmySupplies = _defaultArmySupplies

    _instance.playerManager = TotoWarCbacPlayerManager:new()
    _instance.uiManager = TotoWarCbacUIManager:new()

    _instance:addListeners()

    _instance.logger:logDebug("new(): COMPLETED")

    return _instance
end

---Adds listeners for events that will display UI elements and trigger cost verifications.
function TotoWarCbac:addListeners()
    self.logger:logDebug("addListeners(): STARTED")

    self.logger:logDebug(
        "addListeners() => Add listener to event \"%s\"",
        TotoWar().ui.enums.event.panelOpened)
    core:add_listener(
        "TotoWarCbac_" .. TotoWar().ui.enums.event.panelOpened,
        TotoWar().ui.enums.event.panelOpened,
        true,
        ---@param context TotoWarEventContext_PanelOpenedOrClosed
        function(context)
            self:onPanelOpened(context.string)
        end,
        true)

    self.logger:logDebug(
        "addListeners() => Add listener to event \"%s\"",
        TotoWar().ui.enums.event.panelClosed)
    core:add_listener(
        "TotoWarCbac_" .. TotoWar().ui.enums.event.panelClosed,
        TotoWar().ui.enums.event.panelClosed,
        true,
        ---@param context TotoWarEventContext_PanelOpenedOrClosed
        function(context)
            self:onPanelClosed(context.string)
        end,
        true)

    _instance.playerManager:addListeners()
    _instance.uiManager:addListeners()

    self.logger:logDebug("addListeners(): COMPLETED")
end

---Displays the army supplies cost of a recruitable unit on its unit card.
---@param unitCardUIComponent UIC Unit card UI component.
---@param armySuppliesCost TotoWarCbacArmySuppliesCost Army supplies cost of the army of the selected general.
function TotoWarCbac:displayRecruitableUnitCardArmySuppliesCost(unitCardUIComponent, armySuppliesCost)
    local unitContext = TotoWar().ui:getUIComponentCCO(
        unitCardUIComponent,
        TotoWar().ui.enums.ccoContextTypeId.ccoMainUnitRecord)

    local unitName = unitContext:Call("Name")
    local unitBaseCost = tonumber(unitContext:Call("BaseCost"))

    self.logger:logDebug(
        "displayRecruitableUnitCardArmySuppliesCost(%s, %s): STARTED => (%s, %s)",
        unitCardUIComponent:Id(),
        armySuppliesCost.totalCost,
        unitName,
        unitBaseCost)

    local armyCostUIComponent = TotoWar().ui:findUIComponentChild(
        unitCardUIComponent,
        { "external_holder", _unitArmySuppliesCostUIComponentName })

    if not armyCostUIComponent then
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
        armyCostUIComponent = UIComponent(upkeepCostUIComponent:CopyComponent(_unitArmySuppliesCostUIComponentName))
        armyCostUIComponent:SetDockOffset(xPadding, _unitArmySuppliesCostUIComponentOffsetY)
        armyCostUIComponent:SetTooltipText(
            common.get_localised_string("totowar_cbac_unit_army_supply_cost_tooltip"),
            true)
    end

    local unitBaseCostText = tostring(unitBaseCost)
    local availableArmySupplies = self.armyTotalArmySupplies - armySuppliesCost.totalCost

    -- Disabling the unit card when its the army supplies exceeds the available army supplies of the selected general
    if unitBaseCost > availableArmySupplies then
        self.logger:logDebug(
            "displayRecruitableUnitCardArmySuppliesCost(): UNIT DISABLED => (%s, %s)",
            unitName,
            unitBaseCost)

        unitCardUIComponent:SetDisabled(true)
        unitCardUIComponent:SetState("inactive")
        unitBaseCostText = string.format("[[col:%s]]%s[[/col]]", TotoWar().utils.enums.color.red, unitBaseCostText)
    end

    local armyCostUIComponentDetailUIComponent = TotoWar().ui:getUIComponentChild(armyCostUIComponent, { "Upkeep" })
    armyCostUIComponentDetailUIComponent:DestroyChildren() -- Removing the price change arrow copied from the Upkeep UI component
    armyCostUIComponentDetailUIComponent:SetText(unitBaseCostText, "")
    armyCostUIComponentDetailUIComponent:SetImagePath(_armySuppliesIconPath, 0, false)

    self.logger:logDebug(
        "displayRecruitableUnitCardArmySuppliesCost(%s, %s): COMPLETED => (%s, %s)",
        unitCardUIComponent:Id(),
        armySuppliesCost.totalCost,
        unitName,
        unitBaseCost)
end

---Displays the army supplies cost of a list of recruitable units in a recruitment panel (for example, the Global recruitment list).
---@param panelName string Name of the open recruitment panel.
---@param unitCardListUIComponent UIC UI component that contains the list of recruitable units cards.
---@param armySuppliesCost TotoWarCbacArmySuppliesCost Army supplies cost of the army of the selected general.
function TotoWarCbac:displayRecruitableUnitCardListArmySuppliesCost(
    panelName,
    unitCardListUIComponent,
    armySuppliesCost)
    self.logger:logDebug(
        "displayRecruitableUnitCardListArmySuppliesCost(%s, %s, %s): STARTED",
        panelName,
        unitCardListUIComponent:Id(),
        armySuppliesCost.totalCost)

    for i = 0, unitCardListUIComponent:ChildCount() - 1 do
        local unitCardUIComponent = find_child_uicomponent_by_index(unitCardListUIComponent, i)
        self:displayRecruitableUnitCardArmySuppliesCost(unitCardUIComponent, armySuppliesCost)
    end

    self.logger:logDebug(
        "displayRecruitableUnitCardListArmySuppliesCost(%s, %s, %s): COMPLETED",
        panelName,
        unitCardListUIComponent:Id(),
        armySuppliesCost.totalCost)
end

---Displays the army supplies costs of the units selectable in a recruitment panel.
---@param panel TotoWarUIPanelInfo | nil Information on the recruitment panel. If `nil`, we search for the first open recruitment UI component we can find.
---@param armySuppliesCost TotoWarCbacArmySuppliesCost Army supplies cost of the army of the selected general.
function TotoWarCbac:displayRecruitmentPanelArmySuppliesCost(panel, armySuppliesCost)
    if not panel then
        for key, p in pairs(TotoWar().ui.enums.panel) do
            if p:hasCategory(TotoWar().ui.enums.panelCategory.hasRecruitmentUnitCards)
                and cm:get_campaign_ui_manager():is_panel_open(p.name)
            then
                panel = p

                break
            end
        end
    end

    if not panel then
        return
    end

    self.logger:logDebug(
        "displayRecruitableUnitsArmySuppliesCost(%s, %s): STARTED",
        panel.name,
        armySuppliesCost.totalCost)

    if panel.name == TotoWar().ui.enums.panel.mercenaryRecruitment.name then
        -- Allied recruitment
        local alliedRecruitmentPoolUIComponent = TotoWar().ui:findUIComponent(
            TotoWar().ui.uiComponentQuery.alliedRecruitmentPool)

        if alliedRecruitmentPoolUIComponent then
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
                self:displayRecruitableUnitCardListArmySuppliesCost(
                    panel.name,
                    unitListUIComponent,
                    armySuppliesCost)
            end
        else
            -- Mercenary recruitment (regiments of renown, grudge settlers, Waaagh units, ...
            local mercenaryRecruitmentPoolUIComponent = TotoWar().ui:findUIComponent(
                TotoWar().ui.uiComponentQuery.mercenaryRecruitmentPool)

            if mercenaryRecruitmentPoolUIComponent then
                local mercenaryUnitListQuery = { "listview", "list_clip", "list_box" }
                local unitListUIComponent = TotoWar().ui:getUIComponentChild(
                    mercenaryRecruitmentPoolUIComponent,
                    mercenaryUnitListQuery)

                -- The list_box needs to be resized each time the mercenary panel is opened
                TotoWar().ui:resizeUIComponent(
                    unitListUIComponent,
                    0,
                    _armySuppliesCostUIComponentHeight)
                self:displayRecruitableUnitCardListArmySuppliesCost(
                    panel.name,
                    unitListUIComponent,
                    armySuppliesCost)
            end
        end
    elseif panel.name == TotoWar().ui.enums.panel.standardUnitsRecruitment.name then
        -- Global recruitment
        local globalRecruitmentPoolUIComponent = TotoWar().ui:findUIComponent(
            TotoWar().ui.uiComponentQuery.globalRecruitmentPool)

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
                self:displayRecruitableUnitCardListArmySuppliesCost(
                    panel.name,
                    unitListUIComponent,
                    armySuppliesCost)
            end
        end

        -- Local recruitment
        local localRecruitmentPoolUIComponent = TotoWar().ui:findUIComponent(
            TotoWar().ui.uiComponentQuery.localRecruitmentPool)

        if localRecruitmentPoolUIComponent then
            local unitListQuery = { "listview", "list_clip", "list_box" }

            if not self.isLocalRecruitmentResized then
                -- The listview and its content needs to be resized once until the recruitment panel is closed
                TotoWar().ui:resizeUIComponentAndChildren(
                    localRecruitmentPoolUIComponent,
                    0,
                    _armySuppliesCostUIComponentHeight,
                    unitListQuery)
                self.isLocalRecruitmentResized = true
            end

            local unitListUIComponent = TotoWar().ui:findUIComponentChild(
                localRecruitmentPoolUIComponent,
                unitListQuery)

            if unitListUIComponent then
                self:displayRecruitableUnitCardListArmySuppliesCost(
                    panel.name,
                    unitListUIComponent,
                    armySuppliesCost)
            end
        end
    end

    self.logger:logDebug(
        "displayRecruitableUnitsArmySuppliesCost(%s, %s): COMPLETED",
        panel.name,
        armySuppliesCost.totalCost)
end

---Displays the army supplies cost of the army of the selected player faction general.
---@param armySuppliesCost TotoWarCbacArmySuppliesCost Army supplies cost of the army of the selected general.
function TotoWarCbac:displaySelectedGeneralArmySuppliesCost(armySuppliesCost)
    self.logger:logDebug(
        "displaySelectedGeneralArmySuppliesCost(%s): STARTED",
        armySuppliesCost.totalCost)

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
    local availableArmySupplies = self.armyTotalArmySupplies - armySuppliesCost.totalCost

    if availableArmySupplies < 0 then
        armySuppliesCostText = string.format(
            "[[col:%s]]%s[[/col]][[img:%s]][[/img]]",
            TotoWar().utils.enums.color.red,
            availableArmySupplies,
            _armySuppliesDepletedWarningIconId)
    else
        armySuppliesCostText = tostring(availableArmySupplies)
    end

    armySuppliesCostUIComponent:SetText(armySuppliesCostText, "")
    armySuppliesCostUIComponent:SetTooltipText(
        armySuppliesCost:toArmySuppliesCostTooltipText(self.armyTotalArmySupplies),
        true)
    armySuppliesCostUIComponent:SetVisible(true)

    self.logger:logDebug(
        "displaySelectedGeneralArmySuppliesCost(%s): COMPLETED",
        armySuppliesCost.totalCost)
end

---Reacts to a panel being closed.
---@param panelName string Name of the opened panel.
function TotoWarCbac:onPanelClosed(panelName)
    self.logger:logDebug("[EVENT] TotoWarCbac:onPanelClosed(%s): STARTED", panelName)

    self.logger:logDebug("[EVENT] TotoWarCbac:onPanelClosed(%s): COMPLETED", panelName)
end

---Reacts to a panel being opened.
---@param panelName string Name of the opened panel.
function TotoWarCbac:onPanelOpened(panelName)
    self.logger:logDebug("[EVENT] TotoWarCbac:onPanelOpened(%s): STARTED", panelName)

    -- for key, panel in pairs(TotoWar().uiUtils.panels) do
    --     if panel.name == panelName
    --         and panel:hasCategory(TotoWar().uiUtils.enums.panelCategory.hasRecruitmentUnitCards)
    --     then
    --         self:updateArmySuppliesCost(panel)

    --         break
    --     end
    -- end

    self.logger:logDebug("[EVENT] TotoWarCbac:onPanelOpened(%s): COMPLETED", panelName)
end
