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
    isAlliedRecruitmentResized = false,

    ---Indicates whether the global recruitment unit list has been resized to be able to display army supplies cost under each unit price.
    ---It only needs to be resized once per recruitment panel opening.
    isGlobalRecruitmentResized = false,

    ---Indicates whether the local recruitment unit list has been resized to be able to display army supplies cost under each unit price.
    ---It only needs to be resized once per recruitment panel opening.
    isLocalRecruitmentResized = false,

    ---Logger.
    ---@type TotoWarLogger
    logger = nil
}
TotoWarCbacUIManager.__index = TotoWarCbacUIManager

---Initializes a new instance.
---@return TotoWarCbacUIManager
function TotoWarCbacUIManager.new()
    local instance = setmetatable({}, TotoWarCbacUIManager)

    instance.logger = TotoWarLogger.new("TotoWar_Cbac_UIManager", nil, true)
    instance.logger:logDebug("new(): COMPLETED")

    return instance
end

---Adds listeners for events.
function TotoWarCbacUIManager:addListeners()
    self.logger:logDebug("addListeners(): STARTED")

    self.logger:logDebug(
        "addListeners() => Add listener to event \"%s\"",
        TotoWar().ui.enums.event.characterDeselected)
    core:add_listener(
        "TotoWarCbacUIManager_" .. TotoWar().ui.enums.event.characterDeselected,
        TotoWar().ui.enums.event.characterDeselected,
        true,
        function()
            self:onCharacterDeselected()
        end,
        true)

    self.logger:logDebug(
        "addListeners() => Add listener to event \"%s\"",
        TotoWar().ui.enums.event.panelOpened)
    core:add_listener(
        "TotoWarCbacUIManager_" .. TotoWar().ui.enums.event.panelOpened,
        TotoWar().ui.enums.event.panelOpened,
        true,
        ---@param context TotoWarEventContext_PanelOpenedOrClosed
        function(context)
            self:onPanelOpened(context.string)
        end,
        true)

    self.logger:logDebug(
        "addListeners() => Add listener to event \"%s\"",
        TotoWarCbacPlayerManager.event.selectedGeneralArmySuppliesCostChanged)
    core:add_listener(
        "TotoWarCbacUIManager_" .. TotoWarCbacPlayerManager.event.selectedGeneralArmySuppliesCostChanged,
        TotoWarCbacPlayerManager.event.selectedGeneralArmySuppliesCostChanged,
        true,
        function()
            self:onSelectedGeneralArmySuppliesCostChanged()
        end,
        true)

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

    self:updateRecruitmentPanels(panelName)

    self.logger:logDebug("[EVENT] onPanelOpened(%s): COMPLETED", panelName)
end

---Reacts to the army supplies cost of the selected general changing.
function TotoWarCbacUIManager:onSelectedGeneralArmySuppliesCostChanged()
    self.logger:logDebug("[EVENT] onSelectedGeneralArmySuppliesCostChanged(): STARTED")

    self:updateUnitsPanel()
    self:updateRecruitmentPanels()

    self.logger:logDebug("[EVENT] onSelectedGeneralArmySuppliesCostChanged(): COMPLETED")
end

---Updates army supplies costs on open recruitment panels.
---@vararg string Names of the panels to update. If no panel name is passed, we search for open panels to update them.
function TotoWarCbacUIManager:updateRecruitmentPanels(...)
    local panelNames = { ... }

    self.logger:logDebug("updateRecruitmentPanels(%s): STARTED", table.concat(panelNames))

    self.logger:logDebug("updateRecruitmentPanels(%s): COMPLETED", table.concat(panelNames))
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
    local availableArmySupplies = TotoWar_Cbac().armyTotalArmySupplies -
        TotoWar_Cbac().playerManager.selectedGeneralArmySuppliesCost.totalCost

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
        TotoWar_Cbac().playerManager.selectedGeneralArmySuppliesCost:toArmySuppliesCostTooltipText(),
        true)
    armySuppliesCostUIComponent:SetVisible(true)

    self.logger:logDebug("updateUnitsPanel(): COMPLETED")
end
