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
    ---Army supplies
    ---@type number
    armySupplies = nil,

    ---Indicates whether recruitment panel has been resized to be able to display army supplies cost under each unit price.
    ---It only needs to be resized once per recruitment panel opening.
    hasStandardUnitsRecruitmentPanelBeenResized = false,

    ---Logger.
    ---@type TotoWarLogger
    logger = nil,

    ---Selected general.
    ---@type CHARACTER_SCRIPT_INTERFACE
    selectedGeneral = nil,

    ---Army supplies cost of the army of the selected general.
    ---@type TotoWarCbacArmySuppliesCost
    selectedGeneralArmySuppliesCost = nil,

    ---Army supplies cost of the units being recruited in the selected general army.
    ---@type TotoWarCbacArmySuppliesCost
    selectedGeneralCurrentRecruitmentArmySuppliesCost = nil,
}
TotoWarCbac.__index = TotoWarCbac

---Initializes a new instance.
---@return TotoWarCbac
function TotoWarCbac.new()
    local instance = setmetatable({}, TotoWarCbac)

    instance.logger = TotoWarLogger.new(TotoWarCbacModName)

    instance.armySupplies = _defaultArmySupplies

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
        TotoWar().utils.enums.event.panelOpened)
    core:add_listener(
        "totowar_cbac_panel_opened",
        TotoWar().utils.enums.event.panelOpened,
        true,
        function(context)
            local panelName = context.string
            cm:callback(
                function()
                    self:onPanelOpened(panelName)
                end,
                TotoWar().utils.eventCallbackTriggerDelay)
        end,
        true)

    self.logger:logDebug(
        "TotoWarCbac:addListeners() => Add listener to event \"%s\"",
        TotoWar().utils.enums.event.unitDisbanded)
    core:add_listener(
        "totowar_cbac_unit_disbanded",
        TotoWar().utils.enums.event.unitDisbanded,
        true,
        function(context)
            cm:callback(
                function()
                    self:onUnitDisbanded()
                end,
                TotoWar().utils.eventCallbackTriggerDelay)
        end,
        true)

    self.logger:logDebug(
        "TotoWarCbac:addListeners() => Add listener to event \"%s\"",
        TotoWar().utils.enums.event.unitMerged)
    core:add_listener(
        "totowar_cbac_unit_merged_and_destroyed",
        TotoWar().utils.enums.event.unitMerged,
        true,
        function(context)
            cm:callback(
                function()
                    self:onUnitMergedAndDestroyed()
                end,
                TotoWar().utils.eventCallbackTriggerDelay)
        end,
        true)

    -- self.logger:logDebug(
    --     "TotoWarCbac:addListeners() => Add listener to event \"%s\"",
    --     TotoWar().utils.enums.event.unitRecruitmentCancelled)
    -- core:add_listener(
    --     "totowar_cbac_recruitment_item_cancelled_by_player",
    --     TotoWar().utils.enums.event.unitRecruitmentCancelled,
    --     true,
    --     ---@param context RecruitmentItemCancelledByPlayer
    --     function(context)
    --         local unitKey = context:main_unit_record()
    --         cm:callback(
    --             function()
    --                 ---@diagnostic disable-next-line: param-type-mismatch
    --                 self:onUnitRecruitmentCancelled(unitKey)
    --             end,
    --             TotoWar().utils.eventCallbackTriggerDelay)
    --     end,
    --     true)

    -- self.logger:logDebug(
    --     "TotoWarCbac:addListeners() => Add listener to event \"%s\"",
    --     TotoWar().utils.enums.event.unitAddedToRecruitment)
    -- core:add_listener(
    --     "totowar_cbac_recruitment_item_issued_by_player",
    --     TotoWar().utils.enums.event.unitAddedToRecruitment,
    --     true,
    --     ---@param context RecruitmentItemIssuedByPlayer
    --     function(context)
    --         local unitKey = context:main_unit_record()
    --         cm:callback(
    --             function()
    --                 ---@diagnostic disable-next-line: param-type-mismatch
    --                 self:onUnitAddedToRecruitment(unitKey)
    --             end,
    --             TotoWar().utils.eventCallbackTriggerDelay)
    --     end,
    --     true)

    self.logger:logDebug("TotoWarCbac:addListeners(): COMPLETED")
end

---Closes the recruitment panel if it is open.
function TotoWarCbac:closeRecruitmentPanel()
    local isOpen = cm:get_campaign_ui_manager():is_panel_open(TotoWar().utils.ui.panels.recruitmentOptions.name)

    if isOpen then
        local closeButton = TotoWar().utils.ui:findUIComponent(
            TotoWar().utils.ui.uiComponentQuery.recruitmentPanelCloseButton)

        if closeButton then
            closeButton:SimulateLClick()
        end
    end
end

---Displays the army supplies cost of on a recruitable unit card.
---@param unitUIComponent UIC Unit UI component.
function TotoWarCbac:displayRecruitableUnitArmySuppliesCost(unitUIComponent)
    self.logger:logDebug("TotoWarCbac:displayRecruitableUnitArmySuppliesCost(): STARTED")

    local unitContext = TotoWar().utils.ui:getUIComponentCCO(
        unitUIComponent,
        TotoWar().utils.ui.enums.ccoContextTypeId.ccoMainUnitRecord)

    local unitName = unitContext:Call("Name")
    local unitBaseCost = tonumber(unitContext:Call("BaseCost"))

    self.logger:logDebug("TotoWarCbac:displayRecruitableUnitArmySuppliesCost() => (%s, %s)", unitName, unitBaseCost)

    local armyCostUIComponent = TotoWar().utils.ui:findUIComponentChild(
        unitUIComponent,
        { "external_holder", _unitArmySuppliesCostUIComponentName })

    if not armyCostUIComponent then
        TotoWar().utils.ui:resizeUIComponent(unitUIComponent, 0, _armySuppliesCostUIComponentHeight)

        local externalHolderUIComponent = TotoWar().utils.ui:findUIComponentChild(unitUIComponent, { "external_holder" })

        if not externalHolderUIComponent then
            return
        end

        TotoWar().utils.ui:resizeUIComponent(externalHolderUIComponent, 0, _armySuppliesCostUIComponentHeight)

        local recruitmentCostUIComponent = TotoWar().utils.ui:findUIComponentChild(
            externalHolderUIComponent,
            { "RecruitmentCost" })

        if not recruitmentCostUIComponent then
            return
        end

        local xPadding = recruitmentCostUIComponent:GetDockOffset()

        -- Moving up each cost / upkeep component (they are docked at the bottom) to display the army supplies cost component last
        TotoWar().utils.ui:offsetChildUIComponents(externalHolderUIComponent, 0, -_armySuppliesCostUIComponentHeight)

        -- Copying the recruitment cost UI component to create the army supplies cost UI component
        armyCostUIComponent = UIComponent(recruitmentCostUIComponent:CopyComponent(_unitArmySuppliesCostUIComponentName))
        armyCostUIComponent:SetDockOffset(xPadding, _unitArmySuppliesCostUIComponentOffsetY)
        armyCostUIComponent:SetTooltipText(
            common.get_localised_string("totowar_cbac_unit_army_supply_cost_tooltip"),
            true)
    end

    local unitBaseCostText = tostring(unitBaseCost)
    local availableArmySupplies = self.armySupplies - self.selectedGeneralArmySuppliesCost.totalCost

    if unitBaseCost > availableArmySupplies then
        unitBaseCostText = string.format("[[col:%s]]%s[[/col]]", TotoWar().utils.enums.color.red, unitBaseCostText)
    end

    local armyCostUIComponentDetailUIComponent = TotoWar().utils.ui:findUIComponentChild(armyCostUIComponent, { "Cost" })

    if not armyCostUIComponentDetailUIComponent then
        return
    end

    armyCostUIComponentDetailUIComponent:DestroyChildren() -- Removing the price change arrow copied from
    armyCostUIComponentDetailUIComponent:SetText(unitBaseCostText, "")
    armyCostUIComponentDetailUIComponent:SetImagePath(_armySuppliesIconPath, 0, false)

    self.logger:logDebug(
        "TotoWarCbac:displayRecruitableUnitArmySuppliesCost(): COMPLETED => %s, %s",
        unitName,
        unitBaseCost)
end

---Displays the army supplies costs on all the recruitable unit cards.
---@param panel? TotoWarUIPanelInfo  Information on the recruitment panel. If `nil`, we search for the first recruitment UI component we find.
function TotoWarCbac:displayRecruitableUnitsArmySuppliesCost(panel)
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

    if panel then
        self.logger:logDebug("TotoWarCbac:displayRecruitableUnitsArmySuppliesCost(%s): STARTED", panel.name)

        if panel.name == TotoWar().utils.ui.panels.alliedRecruitment.name then
            local alliedRecruitmentPoolUIComponent = TotoWar().utils.ui:findUIComponent(
                TotoWar().utils.ui.uiComponentQuery.alliedRecruitmentPool)

            if alliedRecruitmentPoolUIComponent then
                self:displayRecruitmentPoolArmySuppliesCost(panel.name, alliedRecruitmentPoolUIComponent)
            end
        elseif panel.name == TotoWar().utils.ui.panels.mercenaryRecruitment.name then
            local mercenaryRecruitmentPoolUIComponent = TotoWar().utils.ui:findUIComponent(
                TotoWar().utils.ui.uiComponentQuery.mercenaryRecruitmentPool)

            if mercenaryRecruitmentPoolUIComponent then
                self:displayRecruitmentPoolArmySuppliesCost(panel.name, mercenaryRecruitmentPoolUIComponent)
            end
        elseif panel.name == TotoWar().utils.ui.panels.standardUnitsRecruitment.name then
            local globalRecruitmentPoolUIComponent = TotoWar().utils.ui:findUIComponent(
                TotoWar().utils.ui.uiComponentQuery.globalRecruitmentPool)

            if globalRecruitmentPoolUIComponent then
                if not self.hasStandardUnitsRecruitmentPanelBeenResized then
                    -- The listview and its content needs to be resized once until the recruitment panel is closed
                    TotoWar().utils.ui:resizeUIComponentAndChildren(
                        globalRecruitmentPoolUIComponent,
                        0,
                        _armySuppliesCostUIComponentHeight,
                        {
                            "listview",
                            "list_clip",
                            "list_box"
                        })
                end

                self:displayRecruitmentPoolArmySuppliesCost(panel.name, globalRecruitmentPoolUIComponent)
            end

            local localRecruitmentPoolUIComponent = TotoWar().utils.ui:findUIComponent(
                TotoWar().utils.ui.uiComponentQuery.localRecruitmentPool)

            if localRecruitmentPoolUIComponent then
                if not self.hasStandardUnitsRecruitmentPanelBeenResized then
                    -- The listview and its content needs to be resized once until the recruitment panel is closed
                    TotoWar().utils.ui:resizeUIComponentAndChildren(
                        localRecruitmentPoolUIComponent,
                        0,
                        _armySuppliesCostUIComponentHeight,
                        {
                            "listview",
                            "list_clip",
                            "list_box"
                        })
                end

                self:displayRecruitmentPoolArmySuppliesCost(panel.name, localRecruitmentPoolUIComponent)
            end

            self.hasStandardUnitsRecruitmentPanelBeenResized = true
        end

        self.logger:logDebug("TotoWarCbac:displayRecruitableUnitsArmySuppliesCost(): COMPLETED")
    end
end

---Displays the army supplies cost of all the units in a recruitment pool UI.
---@param panelName string Name of the recruitment panel.
---@param recruitmentPoolUIComponent UIC UI component that contains the list of recruitable units.
function TotoWarCbac:displayRecruitmentPoolArmySuppliesCost(panelName, recruitmentPoolUIComponent)
    self.logger:logDebug(
        "TotoWarCbac:displayRecruitmentPoolArmySuppliesCost(%s, %s): STARTED",
        panelName,
        recruitmentPoolUIComponent:Id())

    local listBoxUIComponent = TotoWar().utils.ui:findUIComponentChild(
        recruitmentPoolUIComponent,
        {
            "listview",
            "list_clip",
            "list_box"
        })

    if not listBoxUIComponent then
        return
    end

    for i = 0, listBoxUIComponent:ChildCount() - 1 do
        local unitUIComponent = find_child_uicomponent_by_index(listBoxUIComponent, i)
        self:displayRecruitableUnitArmySuppliesCost(unitUIComponent)
    end

    self.logger:logDebug(
        "TotoWarCbac:displayRecruitmentPoolArmySuppliesCost(%s): COMPLETED",
        recruitmentPoolUIComponent:Id())
end

---Displays the army supplies cost of the army of the selected player faction general.
function TotoWarCbac:displaySelectedGeneralArmySuppliesCost()
    self.logger:logDebug("TotoWarCbac:displaySelectedGeneralArmySuppliesCost: STARTED")

    local armySuppliesCostUIComponent = TotoWar().utils.ui:findUIComponent(_uiComponentQuery.unitsPanelArmySuppliesCost)

    if not armySuppliesCostUIComponent then
        -- When the recruitment panel was not already open,
        -- copying the upkeep cost UI component to create the army supplies cost UI component
        local unitsPanelIconListUIComponent = TotoWar().utils.ui:findUIComponent(
            TotoWar().utils.ui.enums.uiComponentQuery.unitsPanelIconList)

        if not unitsPanelIconListUIComponent then
            return
        end

        local upkeepUIComponent = TotoWar().utils.ui:findUIComponentChild(unitsPanelIconListUIComponent, { "dy_upkeep" })

        if not upkeepUIComponent then
            return
        end

        armySuppliesCostUIComponent = UIComponent(upkeepUIComponent:CopyComponent(_armySuppliesCostUIComponentName))
        armySuppliesCostUIComponent:SetImagePath(_armySuppliesIconPath, 1, false)
    end

    local totalCostText = ""

    if self.selectedGeneralArmySuppliesCost.totalCost > self.armySupplies then
        totalCostText = string.format(
            "[[col:%s]]%s[[/col]] / %s [[img:%s]][[/img]]",
            TotoWar().utils.enums.color.red,
            tostring(self.selectedGeneralArmySuppliesCost.totalCost),
            self.armySupplies,
            _armySuppliesDepletedWarningIconId)
    else
        totalCostText = string.format(
            "%s / %s",
            tostring(self.selectedGeneralArmySuppliesCost.totalCost),
            self.armySupplies)
    end

    armySuppliesCostUIComponent:SetText(totalCostText, "")
    armySuppliesCostUIComponent:SetTooltipText(
        self.selectedGeneralArmySuppliesCost:toTooltipText(self.armySupplies),
        true)
    armySuppliesCostUIComponent:SetVisible(true)

    self.logger:logDebug(
        "TotoWarCbac:displaySelectedGeneralArmySuppliesCost: COMPLETED",
        self.selectedGeneralArmySuppliesCost.totalCost)
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
    self.logger:logDebug("TotoWarCbac:onCharacterDeselected(): STARTED")

    self:setSelectedGeneral(nil)

    self.logger:logDebug("TotoWarCbac:onCharacterDeselected(): COMPLETED")
end

---Reacts to a character being selected.
---@param character CHARACTER_SCRIPT_INTERFACE Selected character.
function TotoWarCbac:onCharacterSelected(character)
    self.logger:logDebug("TotoWarCbac:onCharacterSelected(%s): STARTED", character:cqi())

    self.hasStandardUnitsRecruitmentPanelBeenResized = false
    local canRecruit =
        TotoWar().utils:isPlayerFactionGeneral(character)
        and TotoWar().utils:canRecruitUnits(character:military_force())

    if canRecruit then
        self:setSelectedGeneral(character)
        self:displayRecruitableUnitsArmySuppliesCost()
    else
        self:setSelectedGeneral(nil)
        self:hideArmySuppliesCostUIComponent()
    end

    self.logger:logDebug("TotoWarCbac:onCharacterSelected(%s): COMPLETED", character:cqi())
end

---Reacts to a panel being opened.
---@param panelName string Name of the opened panel.
function TotoWarCbac:onPanelOpened(panelName)
    self.logger:logDebug("TotoWarCbac:onPanelOpened(%s): STARTED", panelName)

    for key, panel in pairs(TotoWar().utils.ui.panels) do
        if panel.name == panelName
            and panel:hasCategory(TotoWar().utils.ui.enums.panelCategory.hasRecruitmentUnitCards)
        then
            self:displayRecruitableUnitsArmySuppliesCost(panel)

            break
        end
    end

    self.logger:logDebug("TotoWarCbac:onPanelOpened(%s): COMPLETED", panelName)
end

---Reacts to a unit being disbanded.
function TotoWarCbac:onUnitDisbanded()
    self.logger:logDebug("TotoWarCbac:onUnitDisbanded(): STARTED")

    self:updateSelectedGeneralArmySuppliesCost()

    self.logger:logDebug("TotoWarCbac:onUnitDisbanded(): COMPLETED")
end

---Reacts to a unit being merged and destroyed.
function TotoWarCbac:onUnitMergedAndDestroyed()
    self.logger:logDebug("TotoWarCbac:onUnitMergedAndDestroyed(): STARTED")

    self:updateSelectedGeneralArmySuppliesCost()

    self.logger:logDebug("TotoWarCbac:onUnitMergedAndDestroyed(): COMPLETED")
end

---Reacts to a unit being added to the recruitment list of the selected general army.
---@param unitKey string Unit key.
function TotoWarCbac:onUnitAddedToRecruitment(unitKey)
    self.logger:logDebug("TotoWarCbac:onUnitAddedToRecruitment(): STARTED")

    self:updateSelectedGeneralArmySuppliesCost()

    self.logger:logDebug("TotoWarCbac:onUnitAddedToRecruitment(): COMPLETED")
end

---Reacts to a unit being removed from the recruitment list of the selected general army.
---@param unitKey string Unit key.
function TotoWarCbac:onUnitRecruitmentCancelled(unitKey)
    self.logger:logDebug("TotoWarCbac:onUnitRecruitmentCancelled(): STARTED")

    self:updateSelectedGeneralArmySuppliesCost()

    self.logger:logDebug("TotoWarCbac:onUnitRecruitmentCancelled(): COMPLETED")
end

---Sets the selected general and calculate the price of its army.
---If the price of the army exceeds army supplies, the selected general cannot move.
---@param character? CHARACTER_SCRIPT_INTERFACE Selected general.
function TotoWarCbac:setSelectedGeneral(character)
    if character then
        self.logger:logDebug(
            "TotoWarCbac:setSelectedGeneral(%s): STARTED => %s",
            character:cqi(),
            character:military_force():command_queue_index())

        if not self.selectedGeneral
            or character:cqi() ~= self.selectedGeneral:cqi()
        then
            self.selectedGeneral = character
            self:updateSelectedGeneralArmySuppliesCost()
        end

        self.logger:logDebug(
            "TotoWarCbac:setSelectedGeneral(%s): COMPLETED => %s",
            character:cqi(),
            character:military_force():command_queue_index())
    else
        self.logger:logDebug("TotoWarCbac:setSelectedGeneral(nil): STARTED")

        self.selectedGeneral = nil
        self.selectedGeneralArmySuppliesCost = nil

        self.logger:logDebug("TotoWarCbac:setSelectedGeneral(nil): COMPLETED")
    end
end

---Updates the army supplies cost of the selected general army.
function TotoWarCbac:updateSelectedGeneralArmySuppliesCost()
    if not self.selectedGeneral then
        return
    end

    self.logger:logDebug("TotoWarCbac:updateSelectedGeneralArmySuppliesCost: STARTED")

    self.selectedGeneralArmySuppliesCost = TotoWarCbacArmySuppliesCost.new(self.selectedGeneral:military_force())
    self:displaySelectedGeneralArmySuppliesCost()

    if self.selectedGeneralArmySuppliesCost.totalCost > self.armySupplies then
        self.logger:logDebug(
            "TotoWarCbac:updateSelectedGeneralArmySuppliesCost: ARMY SUPPLIES DEPLETE, ARMY BLOCKED => %s",
            self.selectedGeneralArmySuppliesCost.totalCost)
        cm:disable_movement_for_character("character_cqi:" .. self.selectedGeneral:cqi())
    else
        cm:enable_movement_for_character("character_cqi:" .. self.selectedGeneral:cqi())
    end

    self.logger:logDebug(
        "TotoWarCbac:updateSelectedGeneralArmySuppliesCost: COMPLETED => %s",
        self.selectedGeneralArmySuppliesCost.totalCost)
end
