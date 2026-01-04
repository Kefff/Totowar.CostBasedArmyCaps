---Name of the TotoWar Cost-Based Army Caps mod.
---@type string
TotoWarCbacModName = "totowar_cost_based_army_caps"

---Height of the UI components that displays army supplies and army supplies cost.
---@type number
local _armySuppliesCostUIComponentHeight = 24

---Name of the UI component that displays army supplies.
---@type string
local _armySuppliesCostUIComponentName = "totowar_cbac_army_supply_cost"

---ID of the army supplies icon.
---@type string
local _armySuppliesIconId = "icon_merc"

---Path of the army supplies icon.
---@type string
local _armySuppliesIconPath = "ui/skins/default/merc.png"

---ID of the depleted army supplies warning icon.
---@type string
local _armySuppliesDepletedWarningIconId = "totowar_cbac_army_supply_depleted"

---Path of the depleted army supplies warning icon.
---@type string
local _armySuppliesDepletedWarningIconPath = "ui/skins/warhammer2/icon_status_alert_high.png"

---Default amount of army supplies per army.
---Sadly, it cannot be read from DB table (mp_budgets_table) because LUA scripts do not not have access to them.
---@type number
local _defaultArmySupplies = 12400

--- Names of the recruitment panel that have already been resized.
---@type string[]
local _resizedRecruitmentPanelNames = {}

---Queries for searching TotoWar Cost-Based Army Caps UI components.
---@type string[][]
local UIComponentQuery = {
    unitsPanelArmySuppliesCost = { "units_panel", "main_units_panel", "icon_list", _armySuppliesCostUIComponentName }
}

---Name of the UI component that displays unit army supplies cost.
---@type string
local unitArmySuppliesCostUIComponentName = "totowar_cbac_unit_army_supply_cost"

---Y offset of the UI component that displays unit army supplies cost.
---@type number
local unitArmySuppliesCostUIComponentOffsetY = -18

---TotoWar mod form managing cost-Based army caps.
---@class TotoWarCbac
TotoWarCbac = {
    ---Army supplies
    ---@type number
    armySupplies = nil,

    ---Logger.
    ---@type TotoWarLogger
    logger = nil,

    ---Selected general.
    ---@type CHARACTER_SCRIPT_INTERFACE
    selectedGeneral = nil,

    ---Selected general army cost.
    ---@type TotoWarCbacArmySuppliesCost
    selectedGeneralArmySuppliesCost = nil
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
        TotoWar().utils.enums.event.panelOpenedCampaign)
    core:add_listener(
        "totowar_cbac_recruitment_panel_opened",
        TotoWar().utils.enums.event.panelOpenedCampaign,
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

    self.logger:logDebug("TotoWarCbac:addListeners(): COMPLETED")
end

---Displays of updates (when switching between generals) the army supplies cost of the army of the selected player faction general.
function TotoWarCbac:displayOrUpdateUnitsPanelArmySuppliesCost()
    self.logger:logDebug("TotoWarCbac:displayOrUpdateUnitsPanelArmySuppliesCost: STARTED")

    local armySuppliesCostUIComponent = TotoWar().utils.ui:findUIComponent(UIComponentQuery.unitsPanelArmySuppliesCost)

    if not armySuppliesCostUIComponent then
        -- Copying the upkeep cost UI component to create the army supplies cost UI component
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
        "TotoWarCbac:displayOrUpdateUnitsPanelArmySuppliesCost: COMPLETED",
        self.selectedGeneralArmySuppliesCost.totalCost)
end

---Displays the army supplies cost of on a unit card.
---@param unitUIComponent UIC Unit UI component.
function TotoWarCbac:displayRecruitableUnitArmySuppliesCost(unitUIComponent)
    self.logger:logDebug("TotoWarCbac:displayRecruitableUnitArmySuppliesCost(): STARTED")

    local unitContext = TotoWar().utils.ui:getUIComponentCCO(
        unitUIComponent,
        TotoWar().utils.ui.enums.ccoContextTypeId.ccoMainUnitRecord)

    local unitName = unitContext:Call("Name")
    local unitBaseCost = tonumber(unitContext:Call("BaseCost"))

    self.logger:logDebug("TotoWarCbac:displayRecruitableUnitArmySuppliesCost() => (%s, %s)", unitName, unitBaseCost)

    TotoWar().utils.ui:resizeUIComponent(unitUIComponent, 0, _armySuppliesCostUIComponentHeight)

    local externalHolderUIComponent = TotoWar().utils.ui:findUIComponentChild(unitUIComponent, { "external_holder" })

    if not externalHolderUIComponent then
        return
    end

    TotoWar().utils.ui:resizeUIComponent(externalHolderUIComponent, 0, _armySuppliesCostUIComponentHeight)

    local recruitmentCostUIComponent = TotoWar().utils.ui:findUIComponentChild(externalHolderUIComponent,
        { "RecruitmentCost" })

    if not recruitmentCostUIComponent then
        return
    end

    local xPadding = recruitmentCostUIComponent:GetDockOffset()

    -- Moving up each cost / upkeep component (they are docked at the bottom) to display the army supplies cost component last
    TotoWar().utils.ui:offsetChildUIComponents(externalHolderUIComponent, 0, -_armySuppliesCostUIComponentHeight)

    -- Copying the recruitment cost UI component to create the army supplies cost UI component
    local armyCostUIComponent = UIComponent(recruitmentCostUIComponent:CopyComponent(unitArmySuppliesCostUIComponentName))
    armyCostUIComponent:SetDockOffset(xPadding, unitArmySuppliesCostUIComponentOffsetY)
    armyCostUIComponent:SetTooltipText(
        common.get_localised_string("totowar_cbac_unit_army_supply_cost_tooltip"),
        true)

    local unitBaseCostText = tostring(unitBaseCost)
    local availableArmySupplies = self.armySupplies -
        self.selectedGeneralArmySuppliesCost.totalCost

    if unitBaseCost > availableArmySupplies then
        unitBaseCostText = string.format("[[col:%s]]%s[[/col]]", TotoWar().utils.enums.color.red, unitBaseCostText)
    end

    local costUIComponent = TotoWar().utils.ui:findUIComponentChild(armyCostUIComponent, { "Cost" })

    if not costUIComponent then
        return
    end

    costUIComponent:DestroyChildren() -- Removing the price change arrow copied from
    costUIComponent:SetText(unitBaseCostText, "")
    costUIComponent:SetImagePath(_armySuppliesIconPath, 0, false)

    self.logger:logDebug("TotoWarCbac:displayRecruitableUnitArmySuppliesCost(): COMPLETED => %s, %s", unitName,
        unitBaseCost)
end

---Displays the army supplies costs in the recruitment panel.
---@param panelInfo? TotoWarUIPanelInfo  Information on the recruitment panel. If `nil`, we search for the first recruitment UI component we find.
function TotoWarCbac:displayRecruitmentPanelArmySuppliesCosts(panelInfo)
    self.logger:logDebug("TotoWarCbac:displayRecruitmentPanelArmySuppliesCosts(): STARTED")

    if not panelInfo then
        for key, p in pairs(TotoWar().utils.ui.panels) do
            if p:hasCategory(TotoWar().utils.ui.enums.panelCategory.hasRecruitmentUnitList)
                and cm:get_campaign_ui_manager():is_panel_open(p.name)
            then
                panelInfo = p
            end
        end
    end

    if panelInfo then
        local resize = true

        for i, resizedRecruitmentPanelName in ipairs(_resizedRecruitmentPanelNames) do
            if panelInfo.name == resizedRecruitmentPanelName then
                resize = false

                break
            end
        end

        for i, uiComponentQuery in ipairs(panelInfo.uiComponentQueries) do
            local uiComponent = TotoWar().utils.ui:findUIComponent(uiComponentQuery)

            if uiComponent then
                self:displayRecruitmentPoolArmySuppliesCost(uiComponent, resize)
            end
        end
    end

    self.logger:logDebug("TotoWarCbac:displayRecruitmentPanelArmySuppliesCosts(): COMPLETED")
end

---Displays the army supplies cost of all the units in a recruitment pool UI.
---@param recruitmentUIComponent UIC Global or local recruitment pool UI component.
---@param resizePanel boolean Indicates whether the recruitment panel needs to be resized. This is the case only when the recruitment panel was not already open.
function TotoWarCbac:displayRecruitmentPoolArmySuppliesCost(recruitmentUIComponent, resizePanel)
    self.logger:logDebug(
        "TotoWarCbac:displayRecruitmentPoolArmySuppliesCost(%s, %s): STARTED",
        recruitmentUIComponent:Id(),
        resizePanel)

    if resizePanel then
        TotoWar().utils.ui:resizeUIComponentAndChildren(
            recruitmentUIComponent,
            0,
            _armySuppliesCostUIComponentHeight,
            "listview",
            "list_clip",
            "list_box")
    end

    local unitListUIComponent = TotoWar().utils.ui:findUIComponentChild(
        recruitmentUIComponent,
        {
            "listview",
            "list_clip",
            "list_box"
        })

    if not unitListUIComponent then
        return
    end

    for i = 0, unitListUIComponent:ChildCount() - 1 do
        local unitUIComponent = find_child_uicomponent_by_index(unitListUIComponent, i)
        self:displayRecruitableUnitArmySuppliesCost(unitUIComponent)
    end

    self.logger:logDebug(
        "TotoWarCbac:displayRecruitmentPoolArmySuppliesCost(%s, %s): COMPLETED",
        recruitmentUIComponent:Id(),
        resizePanel)
end

---Hides the army supplies cost UI component.
function TotoWarCbac:hideArmySuppliesCostUIComponent()
    self.logger:logDebug("TotoWarCbac:hideArmySuppliesCostUIComponent(): STARTED")

    local armyCostUIComponent = TotoWar().utils.ui:findUIComponent(UIComponentQuery.unitsPanelArmySuppliesCost)

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

    local canRecruit =
        TotoWar().utils:isPlayerFactionGeneral(character)
        and TotoWar().utils:canRecruitUnits(character:military_force())

    if canRecruit then
        self:setSelectedGeneral(character)
        self:displayOrUpdateUnitsPanelArmySuppliesCost()

        -- When the recruitment options panel is open and we select the same or another character,
        -- it is refreshed so we need to display the supplies costs again
        if cm:get_campaign_ui_manager():is_panel_open(TotoWar().utils.ui.panels.recruitmentOptions.name) then
            self:displayRecruitmentPanelArmySuppliesCosts()
        end
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
            -- and panel:hasCategory(TotoWar().utils.ui.enums.panelCategory.hasRecruitmentUnitList)
            and panel:hasCategory("hasRecruitmentUnitList")
        then
            self:displayRecruitmentPanelArmySuppliesCosts(panel)

            break
        end
    end

    self.logger:logDebug("TotoWarCbac:onPanelOpened(%s): COMPLETED", panelName)
end

---Sets the selected general and calculate the price of its army
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
            self.selectedGeneralArmySuppliesCost = TotoWarCbacArmySuppliesCost.new(character:military_force())
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
