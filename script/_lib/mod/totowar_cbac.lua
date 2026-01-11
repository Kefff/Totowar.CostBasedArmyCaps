---Name of the TotoWar Cost-Based Army Caps mod.
---@type string
TotoWarCbacModName = "totowar_cost_based_army_caps"

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

---Default amount of army supplies per army.
---Sadly, it cannot be read from DB table (mp_budgets_table) because LUA scripts do not not have access to them.
---@type number
local _defaultArmySupplies = 12400

---Queries for searching TotoWar Cost-Based Army Caps UI components.
---@type string[][]
local _uiComponentQuery = {
    unitsPanelArmySuppliesCost = { "units_panel", "main_units_panel", "icon_list", _armySuppliesCostUIComponentName }
}

---Name of the UI component that displays unit army supplies cost.
---@type string
local _unitArmySuppliesCostUIComponentName = "totowar_cbac_unit_army_supply_cost"

---Y offset of the UI component that displays unit army supplies cost.
---@type number
local _unitArmySuppliesCostUIComponentOffsetY = -18

---TotoWar mod form managing cost-Based army caps.
---@class TotoWarCbac
TotoWarCbac = {
    ---Available army supplies in an army.
    ---@type number
    armyAvailableArmySupplies = nil,

    ---Indicates whether the allied recruitment unit list has been resized to be able to display army supplies cost under each unit price.
    ---It only needs to be resized once per recruitment panel opening.
    isAlliedRecruitmentResized = false,

    ---Indicates whether the global recruitment unit list has been resized to be able to display army supplies cost under each unit price.
    ---It only needs to be resized once per recruitment panel opening.
    isGlobalRecruitmentResized = false,

    ---Indicates whether the local recruitment unit list has been resized to be able to display army supplies cost under each unit price.
    ---It only needs to be resized once per recruitment panel opening.
    isLocalRecruitmentResized = false,

    ---Logger.
    ---@type TotoWarLogger
    logger = nil,

    ---Selected general.
    ---@type CHARACTER_SCRIPT_INTERFACE
    selectedGeneral = nil
}
TotoWarCbac.__index = TotoWarCbac

---Initializes a new instance.
---@return TotoWarCbac
function TotoWarCbac.new()
    local instance = setmetatable({}, TotoWarCbac)

    instance.logger = TotoWarLogger.new(TotoWarCbacModName)

    instance.armyAvailableArmySupplies = _defaultArmySupplies

    instance:addListeners()

    instance.logger:logDebug("TotoWarModsManager.new(): COMPLETED")

    return instance
end

---Adds listeners for events that will display UI elements and trigger cost verifications.
function TotoWarCbac:addListeners()
    self.logger:logDebug("TotoWarCbac:addListeners(): STARTED")

    self.logger:logDebug(
        "TotoWarCbac:addListeners() => Add listener to event \"%s\"",
        TotoWar().utils.enums.event.characterDeselected)
    core:add_listener(
        "totowar_cbac_character_deselected",
        TotoWar().utils.enums.event.characterDeselected,
        true,
        function(context)
            cm:callback(
                function()
                    self:onCharacterDeselected()
                end,
                TotoWar().utils.eventCallbackTriggerDelay)
        end,
        true)

    self.logger:logDebug(
        "TotoWarCbac:addListeners() => Add listener to event \"%s\"",
        TotoWar().utils.enums.event.characterSelected)
    core:add_listener(
        "totowar_cbac_character_selected",
        TotoWar().utils.enums.event.characterSelected,
        true,
        ---@param context CharacterSelected
        function(context)
            local character = context:character()
            cm:callback(
                function()
                    self:onCharacterSelected(character)
                end,
                TotoWar().utils.eventCallbackTriggerDelay)
        end,
        true)

    self.logger:logDebug(
        "TotoWarCbac:addListeners() => Add listener to event \"%s\"",
        TotoWar().utils.enums.event.panelOpenedOrRefreshed)
    core:add_listener(
        "totowar_cbac_panel_opened_or_refreshed",
        TotoWar().utils.enums.event.panelOpenedOrRefreshed,
        true,
        function(context)
            local panelName = context.string
            cm:callback(
                function()
                    self:onPanelOpenedOrRefreshed(panelName)
                end,
                TotoWar().utils.eventCallbackTriggerDelay)
        end,
        true)

    self.logger:logDebug("TotoWarCbac:addListeners(): COMPLETED")
end

---Displays the army supplies cost of a recruitable unit on its unit card.
---@param unitCardUIComponent UIC Unit card UI component.
---@param armySuppliesCost TotoWarCbacArmySuppliesCost Army supplies cost of the army of the selected general.
function TotoWarCbac:displayRecruitableUnitCardArmySuppliesCost(unitCardUIComponent, armySuppliesCost)
    local unitContext = TotoWar().utils.ui:getUIComponentCCO(
        unitCardUIComponent,
        TotoWar().utils.ui.enums.ccoContextTypeId.ccoMainUnitRecord)

    local unitName = unitContext:Call("Name")
    local unitBaseCost = tonumber(unitContext:Call("BaseCost"))

    self.logger:logDebug(
        "TotoWarCbac:displayRecruitableUnitCardArmySuppliesCost(%s, %s): STARTED => (%s, %s)",
        unitCardUIComponent:Id(),
        armySuppliesCost.totalCost,
        unitName,
        unitBaseCost)

    local armyCostUIComponent = TotoWar().utils.ui:findUIComponentChild(
        unitCardUIComponent,
        { "external_holder", _unitArmySuppliesCostUIComponentName })

    if not armyCostUIComponent then
        TotoWar().utils.ui:resizeUIComponent(unitCardUIComponent, 0, _armySuppliesCostUIComponentHeight)

        local externalHolderUIComponent = TotoWar().utils.ui:getUIComponentChild(
            unitCardUIComponent,
            { "external_holder" })
        TotoWar().utils.ui:resizeUIComponent(externalHolderUIComponent, 0, _armySuppliesCostUIComponentHeight)

        -- Moving up each cost / upkeep component (they are docked at the bottom) to display the army supplies cost component last
        TotoWar().utils.ui:offsetChildUIComponents(externalHolderUIComponent, 0, -_armySuppliesCostUIComponentHeight)

        -- Copying the recruitment cost UI component to create the army supplies cost UI component
        local upkeepCostUIComponent = TotoWar().utils.ui:getUIComponentChild(externalHolderUIComponent, { "UpkeepCost" })
        local xPadding = upkeepCostUIComponent:GetDockOffset()
        armyCostUIComponent = UIComponent(upkeepCostUIComponent:CopyComponent(_unitArmySuppliesCostUIComponentName))
        armyCostUIComponent:SetDockOffset(xPadding, _unitArmySuppliesCostUIComponentOffsetY)
        armyCostUIComponent:SetTooltipText(
            common.get_localised_string("totowar_cbac_unit_army_supply_cost_tooltip"),
            true)
    end

    local unitBaseCostText = tostring(unitBaseCost)
    local availableArmySupplies = self.armyAvailableArmySupplies - armySuppliesCost.totalCost

    -- Disabling the unit card when its the army supplies exceeds the available army supplies of the selected general
    if unitBaseCost > availableArmySupplies then
        self.logger:logDebug(
            "TotoWarCbac:displayRecruitableUnitCardArmySuppliesCost(): UNIT DISABLED => (%s, %s)",
            unitName,
            unitBaseCost)

        unitCardUIComponent:SetDisabled(true)
        unitCardUIComponent:SetState("inactive")
        unitBaseCostText = string.format("[[col:%s]]%s[[/col]]", TotoWar().utils.enums.color.red, unitBaseCostText)
    end

    local armyCostUIComponentDetailUIComponent = TotoWar().utils.ui:getUIComponentChild(armyCostUIComponent, { "Upkeep" })
    armyCostUIComponentDetailUIComponent:DestroyChildren() -- Removing the price change arrow copied from the Upkeep UI component
    armyCostUIComponentDetailUIComponent:SetText(unitBaseCostText, "")
    armyCostUIComponentDetailUIComponent:SetImagePath(_armySuppliesIconPath, 0, false)

    self.logger:logDebug(
        "TotoWarCbac:displayRecruitableUnitCardArmySuppliesCost(%s, %s): COMPLETED => (%s, %s)",
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
        "TotoWarCbac:displayRecruitableUnitCardListArmySuppliesCost(%s, %s, %s): STARTED",
        panelName,
        unitCardListUIComponent:Id(),
        armySuppliesCost.totalCost)

    for i = 0, unitCardListUIComponent:ChildCount() - 1 do
        local unitCardUIComponent = find_child_uicomponent_by_index(unitCardListUIComponent, i)
        self:displayRecruitableUnitCardArmySuppliesCost(unitCardUIComponent, armySuppliesCost)
    end

    self.logger:logDebug(
        "TotoWarCbac:displayRecruitableUnitCardListArmySuppliesCost(%s, %s, %s): COMPLETED",
        panelName,
        unitCardListUIComponent:Id(),
        armySuppliesCost.totalCost)
end

---Displays the army supplies costs of the units selectable in a recruitment panel.
---@param panel TotoWarUIPanelInfo | nil Information on the recruitment panel. If `nil`, we search for the first open recruitment UI component we can find.
---@param armySuppliesCost TotoWarCbacArmySuppliesCost Army supplies cost of the army of the selected general.
function TotoWarCbac:displayRecruitmentPanelArmySuppliesCost(panel, armySuppliesCost)
    if not panel then
        for key, p in pairs(TotoWar().utils.ui.panels) do
            if p:hasCategory(TotoWar().utils.ui.enums.panelCategory.hasRecruitmentUnitCards)
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
        "TotoWarCbac:displayRecruitableUnitsArmySuppliesCost(%s, %s): STARTED",
        panel.name,
        armySuppliesCost.totalCost)

    if panel.name == TotoWar().utils.ui.panels.mercenaryRecruitment.name then
        -- Allied recruitment
        local alliedRecruitmentPoolUIComponent = TotoWar().utils.ui:findUIComponent(
            TotoWar().utils.ui.uiComponentQuery.alliedRecruitmentPool)

        if alliedRecruitmentPoolUIComponent then
            local unitListQuery = { "listview", "list_clip", "allied_unit_list" }

            if not self.isAlliedRecruitmentResized then
                -- The listview and its content needs to be resized once until the recruitment panel is closed
                TotoWar().utils.ui:resizeUIComponentAndChildren(
                    alliedRecruitmentPoolUIComponent,
                    0,
                    _armySuppliesCostUIComponentHeight,
                    unitListQuery)
                self.isAlliedRecruitmentResized = true;
            end

            local unitListUIComponent = TotoWar().utils.ui:findUIComponentChild(
                alliedRecruitmentPoolUIComponent,
                unitListQuery)

            if unitListUIComponent then
                self:displayRecruitableUnitCardListArmySuppliesCost(
                    panel.name,
                    unitListUIComponent,
                    armySuppliesCost)
            end
        end

        -- Mercenary recruitment (regiments of renown, grudge settlers, Waaagh units, ...
        local mercenaryRecruitmentPoolUIComponent = TotoWar().utils.ui:findUIComponent(
            TotoWar().utils.ui.uiComponentQuery.mercenaryRecruitmentPool)

        if mercenaryRecruitmentPoolUIComponent then
            local mercenaryUnitListQuery = { "listview", "list_clip", "list_box" }
            local unitListUIComponent = TotoWar().utils.ui:getUIComponentChild(
                mercenaryRecruitmentPoolUIComponent,
                mercenaryUnitListQuery)

            -- The list_box needs to be resized each time the mercenary panel is opened
            TotoWar().utils.ui:resizeUIComponent(
                unitListUIComponent,
                0,
                _armySuppliesCostUIComponentHeight)
            self:displayRecruitableUnitCardListArmySuppliesCost(
                panel.name,
                unitListUIComponent,
                armySuppliesCost)
        end
    elseif panel.name == TotoWar().utils.ui.panels.standardUnitsRecruitment.name then
        -- Global recruitment
        local globalRecruitmentPoolUIComponent = TotoWar().utils.ui:findUIComponent(
            TotoWar().utils.ui.uiComponentQuery.globalRecruitmentPool)

        if globalRecruitmentPoolUIComponent then
            local unitListQuery = { "listview", "list_clip", "list_box" }

            if not self.isGlobalRecruitmentResized then
                -- The listview and its content needs to be resized once until the recruitment panel is closed
                TotoWar().utils.ui:resizeUIComponentAndChildren(
                    globalRecruitmentPoolUIComponent,
                    0,
                    _armySuppliesCostUIComponentHeight,
                    unitListQuery)
                self.isGlobalRecruitmentResized = true
            end

            local unitListUIComponent = TotoWar().utils.ui:findUIComponentChild(
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
        local localRecruitmentPoolUIComponent = TotoWar().utils.ui:findUIComponent(
            TotoWar().utils.ui.uiComponentQuery.localRecruitmentPool)

        if localRecruitmentPoolUIComponent then
            local unitListQuery = { "listview", "list_clip", "list_box" }

            if not self.isLocalRecruitmentResized then
                -- The listview and its content needs to be resized once until the recruitment panel is closed
                TotoWar().utils.ui:resizeUIComponentAndChildren(
                    localRecruitmentPoolUIComponent,
                    0,
                    _armySuppliesCostUIComponentHeight,
                    unitListQuery)
                self.isLocalRecruitmentResized = true
            end

            local unitListUIComponent = TotoWar().utils.ui:findUIComponentChild(
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
        "TotoWarCbac:displayRecruitableUnitsArmySuppliesCost(%s, %s): COMPLETED",
        panel.name,
        armySuppliesCost.totalCost)
end

---Displays the army supplies cost of the army of the selected player faction general.
---@param armySuppliesCost TotoWarCbacArmySuppliesCost Army supplies cost of the army of the selected general.
function TotoWarCbac:displaySelectedGeneralArmySuppliesCost(armySuppliesCost)
    self.logger:logDebug(
        "TotoWarCbac:displaySelectedGeneralArmySuppliesCost(%s): STARTED",
        armySuppliesCost.totalCost)

    local armySuppliesCostUIComponent = TotoWar().utils.ui:findUIComponent(_uiComponentQuery.unitsPanelArmySuppliesCost)

    if not armySuppliesCostUIComponent then
        -- If the army supplies cost is not already displayed,
        -- copying the upkeep cost UI component to create the army supplies cost UI component
        local unitsPanelIconListUIComponent = TotoWar().utils.ui:getUIComponent(
            TotoWar().utils.ui.enums.uiComponentQuery.unitsPanelIconList)
        local upkeepUIComponent = TotoWar().utils.ui:getUIComponentChild(unitsPanelIconListUIComponent, { "dy_upkeep" })
        armySuppliesCostUIComponent = UIComponent(upkeepUIComponent:CopyComponent(_armySuppliesCostUIComponentName))
        armySuppliesCostUIComponent:SetImagePath(_armySuppliesIconPath, 1, false)
    end

    local armySuppliesCostText = ""

    if armySuppliesCost.totalCost > self.armyAvailableArmySupplies then
        armySuppliesCostText = string.format(
            "[[col:%s]]%s[[/col]] / %s [[img:%s]][[/img]]",
            TotoWar().utils.enums.color.red,
            tostring(armySuppliesCost.totalCost),
            self.armyAvailableArmySupplies,
            _armySuppliesDepletedWarningIconId)
    else
        armySuppliesCostText = string.format(
            "%s / %s",
            tostring(armySuppliesCost.totalCost),
            self.armyAvailableArmySupplies)
    end

    armySuppliesCostUIComponent:SetText(armySuppliesCostText, "")
    armySuppliesCostUIComponent:SetTooltipText(
        armySuppliesCost:toTooltipText(self.armyAvailableArmySupplies),
        true)
    armySuppliesCostUIComponent:SetVisible(true)

    self.logger:logDebug(
        "TotoWarCbac:displaySelectedGeneralArmySuppliesCost(%s): COMPLETED",
        armySuppliesCost.totalCost)
end

---Hides the army supplies cost UI component.
function TotoWarCbac:hideArmySuppliesCostUIComponent()
    self.logger:logDebug("TotoWarCbac:hideArmySuppliesCostUIComponent(): STARTED")

    local armyCostUIComponent = TotoWar().utils.ui:findUIComponent(_uiComponentQuery.unitsPanelArmySuppliesCost)

    if armyCostUIComponent then
        armyCostUIComponent:SetVisible(false)
    end

    self.logger:logDebug("TotoWarCbac:hideArmySuppliesCostUIComponent(): COMPLETED")
end

---Reacts to a character being deselected.
function TotoWarCbac:onCharacterDeselected()
    self.logger:logDebug("[EVENT] TotoWarCbac:onCharacterDeselected(): STARTED")

    self.selectedGeneral = nil

    self.isAlliedRecruitmentResized = false
    self.isGlobalRecruitmentResized = false
    self.isLocalRecruitmentResized = false

    self:hideArmySuppliesCostUIComponent()

    self.logger:logDebug("[EVENT] TotoWarCbac:onCharacterDeselected(): COMPLETED")
end

---Reacts to a character being selected.
---@param character CHARACTER_SCRIPT_INTERFACE Selected character.
function TotoWarCbac:onCharacterSelected(character)
    self.logger:logDebug("[EVENT] TotoWarCbac:onCharacterSelected(%s): STARTED", character:cqi())

    local canRecruit =
        TotoWar().utils:isPlayerFactionGeneral(character)
        and TotoWar().utils:canRecruitUnits(character:military_force())

    if canRecruit
    then
        if not self.selectedGeneral
            or character:cqi() ~= self.selectedGeneral:cqi()
        then
            self.selectedGeneral = character

            local armySuppliesCost = TotoWarCbacArmySuppliesCost.new(self.selectedGeneral:military_force())
            self:updatedSelectedGeneralMovement(armySuppliesCost)
            self:displaySelectedGeneralArmySuppliesCost(armySuppliesCost)
            self:displayRecruitmentPanelArmySuppliesCost(nil, armySuppliesCost)
        end
    else
        self.selectedGeneral = character
        self.isLocalRecruitmentResized = false
        self:hideArmySuppliesCostUIComponent()
    end

    self.logger:logDebug("[EVENT] TotoWarCbac:onCharacterSelected(%s): COMPLETED", character:cqi())
end

---Reacts to a panel being opened or refreshed.
---@param panelName string Name of the opened panel.
function TotoWarCbac:onPanelOpenedOrRefreshed(panelName)
    self.logger:logDebug("[EVENT] TotoWarCbac:onPanelOpenedOrRefreshed(%s): STARTED", panelName)

    for key, panel in pairs(TotoWar().utils.ui.panels) do
        if panel.name == panelName
            and panel:hasCategory(TotoWar().utils.ui.enums.panelCategory.hasRecruitmentUnitCards)
        then
            local armySuppliesCost = TotoWarCbacArmySuppliesCost.new(self.selectedGeneral:military_force())
            self:updatedSelectedGeneralMovement(armySuppliesCost)
            self:displaySelectedGeneralArmySuppliesCost(armySuppliesCost)
            self:displayRecruitmentPanelArmySuppliesCost(panel, armySuppliesCost)

            break
        end
    end

    self.logger:logDebug("[EVENT] TotoWarCbac:onPanelOpenedOrRefreshed(%s): COMPLETED", panelName)
end

---Reacts to a unit being added to the recruitment list of the selected general army.
---@param unitKey string Unit key.
function TotoWarCbac:onUnitAddedToRecruitment(unitKey)
    self.logger:logDebug("[EVENT] TotoWarCbac:onUnitAddedToRecruitment(): STARTED")

    --TODO

    self.logger:logDebug("[EVENT] TotoWarCbac:onUnitAddedToRecruitment(): COMPLETED")
end

---Reacts to a unit being removed from the recruitment list of the selected general army.
---@param unitKey string Unit key.
function TotoWarCbac:onUnitRecruitmentCancelled(unitKey)
    self.logger:logDebug("[EVENT] TotoWarCbac:onUnitRecruitmentCancelled(): STARTED")

    --TODO

    self.logger:logDebug("[EVENT] TotoWarCbac:onUnitRecruitmentCancelled(): COMPLETED")
end

---Updates the ability to move of the selected general depending on the army supplies cost of its army.
---@param armySuppliesCost TotoWarCbacArmySuppliesCost Army supplies cost of the army of the selected general.
function TotoWarCbac:updatedSelectedGeneralMovement(armySuppliesCost)
    self.logger:logDebug(
        "TotoWarCbac:updatedSelectedGeneralMovement(%s): STARTED",
        armySuppliesCost.totalCost)

    if armySuppliesCost.totalCost > self.armyAvailableArmySupplies then
        self.logger:logDebug(
            "TotoWarCbac:updatedSelectedGeneralMovement(%s): ARMY BLOCKED",
            armySuppliesCost.totalCost)
        cm:disable_movement_for_character("character_cqi:" .. self.selectedGeneral:cqi())
    else
        cm:enable_movement_for_character("character_cqi:" .. self.selectedGeneral:cqi())
    end

    self.logger:logDebug(
        "TotoWarCbac:updatedSelectedGeneralMovement(%s): COMPLETED",
        armySuppliesCost.totalCost)
end
