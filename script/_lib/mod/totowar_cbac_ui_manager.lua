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

---Manager in charge of displaying army supplies cost in the UI.
---@class TotoWarCbacUIManager
TotoWarCbacUIManager = {
    ---Enums
    ---@class TotoWarCbacUIManager_Enums
    enums = {
        ---Update mode defining when a recruitment pool should be updated.
        ---@class TotoWarUIUtils_Enums_RecruitmentPoolUpdateMode
        recruitmentPoolUpdateMode = {
            ---Always.
            ---@type string
            always = "always",

            ---When a panel is opened.
            ---@type string
            panelOpened = "panelOpened",

            ---When the selected army supplies cost has changed..
            ---@type string
            selectedGeneralArmySuppliesCostChanged = "selectedGeneralArmySuppliesCostChanged"
        }
    },

    ---Logger.
    ---@type TotoWarLogger
    logger = nil,

    ---Last opened panel.
    ---@type string | nil
    lastOpenedPanel = nil,

    ---Last opened recruitment pools.
    ---@type string[]
    lastOpenedRecruitmentPools = {},

    ---Recruitment pool UIs.
    ---@type table<string, TotoWarCbacRecruitmentPoolUI>
    recruitmentPools = nil,

    ---Queries for finding UI components.
    ---@class TotoWarCbacUIManager_UIComponentQueries
    uiComponentQueries = {
        unitsPanelIconListArmySuppliesCost = { "units_panel", "main_units_panel", "icon_list", _armySuppliesCostUIComponentName }
    }
}
TotoWarCbacUIManager.__index = TotoWarCbacUIManager

---Initializes a new instance.
---@return TotoWarCbacUIManager
function TotoWarCbacUIManager.new()
    local instance = setmetatable({}, TotoWarCbacUIManager)

    instance.logger = TotoWarLogger.new("TotoWar_Cbac_UIManager")

    instance.recruitmentPools = {
        alliedPool = {
            ---Only needs to be resized once per recruitment panel opening.
            isResized = false,
            name = "allied",
            panelName = TotoWar().ui.enums.panels.mercenaryRecruitment,
            uiComponentQuery = TotoWar().ui.uiComponentQueries.recruitmentOptionsAlliedRecruitmentPool,
            updateUIFunction = function()
                instance:updateAlliedRecruitmentPool()
            end,
            updateMode = instance.enums.recruitmentPoolUpdateMode.panelOpened
        },

        globalPool = {
            ---Only needs to be resized once per recruitment panel opening.
            isResized = false,
            name = "global",
            panelName = TotoWar().ui.enums.panels.standardRecruitment,
            uiComponentQuery = TotoWar().ui.uiComponentQueries.recruitmentOptionsGlobalRecruitmentPool,
            updateUIFunction = function()
                instance:updateGlobalRecruitmentPool()
            end,
            updateMode = instance.enums.recruitmentPoolUpdateMode.panelOpened
        },

        localPool = {
            ---Only needs to be resized once per recruitment panel opening.
            isResized = false,
            name = "local",
            panelName = TotoWar().ui.enums.panels.standardRecruitment,
            uiComponentQuery = TotoWar().ui.uiComponentQueries.recruitmentOptionsLocalRecruitmentPool,
            updateUIFunction = function()
                instance:updateLocalRecruitmentPool()
            end,
            updateMode = instance.enums.recruitmentPoolUpdateMode.panelOpened
        },

        mercenaryPool = {
            ---Needs to be resized each time the recruitment panel is opened.
            isResized = false,
            name = "mercenary",
            panelName = TotoWar().ui.enums.panels.mercenaryRecruitment,
            uiComponentQuery = TotoWar().ui.uiComponentQueries.recruitmentOptionsMercenaryRecruitmentPool,
            updateUIFunction = function()
                instance:updateMercenaryRecruitmentPool()
            end,
            updateMode = instance.enums.recruitmentPoolUpdateMode.selectedGeneralArmySuppliesCostChanged
        }
    }

    instance.logger:logDebug("new(): COMPLETED")

    return instance
end

---Adds listeners for events.
function TotoWarCbacUIManager:addListeners()
    self.logger:logDebug("addListeners(): STARTED")

    TotoWar().utils:addListener(
        "TotoWarCbacUIManager",
        TotoWar().ui.enums.events.characterDeselected,
        function()
            return cm:is_local_players_turn()
        end,
        function()
            self:onCharacterDeselected()
        end)

    TotoWar().utils:addListener(
        "TotoWarCbacUIManager",
        TotoWar().ui.enums.events.panelClosed,
        ---@param context TotoWarEventContext_PanelOpenedOrClosed
        function(context)
            return cm:is_local_players_turn()
        end,
        ---@param context TotoWarEventContext_PanelOpenedOrClosed
        function(context)
            self:onPanelClosed(context.string)
        end)

    TotoWar().utils:addListener(
        "TotoWarCbacUIManager",
        TotoWar().ui.enums.events.panelOpened,
        ---@param context TotoWarEventContext_PanelOpenedOrClosed
        function(context)
            return cm:is_local_players_turn() and self:isRecruitmentPanel(context.string)
        end,
        ---@param context TotoWarEventContext_PanelOpenedOrClosed
        function(context)
            self:onPanelOpened(context.string)
        end)

    TotoWar().utils:addListener(
        "TotoWarCbacUIManager",
        TotoWarCbacPlayerManager.enums.events.selectedGeneralArmySuppliesCostChanged,
        function()
            return cm:is_local_players_turn()
        end,
        function()
            self:onSelectedGeneralArmySuppliesCostChanged()
        end)

    self.logger:logDebug("addListeners(): COMPLETED")
end

---Finds the open recruitment pools to update based on their update mode.
---@return TotoWarCbacRecruitmentPoolUI[]
function TotoWarCbacUIManager:findOpenRecruitmentPoolsToUpdate(updateMode)
    self.logger:logDebug("findOpenRecruitmentPool(): STARTED")

    local recruitmentPools = {}

    for key, recruitmentPool in pairs(self.recruitmentPools) do
        ---@cast recruitmentPool TotoWarCbacRecruitmentPoolUI

        if recruitmentPool.updateMode == TotoWar_Cbac().uiManager.enums.recruitmentPoolUpdateMode.always
            or recruitmentPool.updateMode == updateMode
        then
            local uiComponent = TotoWar().ui:findUIComponent(recruitmentPool.uiComponentQuery)

            if
                uiComponent
                and uiComponent:Visible(true)
            then
                table.insert(recruitmentPools, recruitmentPool)
            end
        end
    end

    self.logger:logDebug("findOpenRecruitmentPool(): COMPLETED")

    return recruitmentPools
end

---Find the recruitment pools in a panel.
---@param panelName string Panel name.
---@return TotoWarCbacRecruitmentPoolUI[]
function TotoWarCbacUIManager:findRecruitmentPoolsInPanel(panelName)
    self.logger:logDebug("findRecruitmentPoolInPanel(%s): STARTED", panelName)

    local recruitmentPools = {}

    for key, recruitmentPool in pairs(self.recruitmentPools) do
        ---@cast recruitmentPool TotoWarCbacRecruitmentPoolUI

        if recruitmentPool.panelName == panelName then
            local uiComponent = TotoWar().ui:findUIComponent(recruitmentPool.uiComponentQuery)

            if
                uiComponent
                and uiComponent:Visible(true)
            then
                table.insert(recruitmentPools, recruitmentPool)
            end
        end
    end

    self.logger:logDebug("findRecruitmentPoolInPanel(%s): COMPLETED", panelName)

    return recruitmentPools
end

---Hides the army supplies cost UI component.
function TotoWarCbacUIManager:hideArmySuppliesCostUIComponent()
    self.logger:logDebug("hideArmySuppliesCostUIComponent(): STARTED")

    local armyCostUIComponent = TotoWar().ui:findUIComponent(TotoWarCbacUIManager.uiComponentQueries)

    if armyCostUIComponent then
        armyCostUIComponent:SetVisible(false)
    end

    self.logger:logDebug("hideArmySuppliesCostUIComponent(): COMPLETED")
end

---Indicates whether a panel is a recruitment panel.
---@param panelName string Panel name.
---@return boolean
function TotoWarCbacUIManager:isRecruitmentPanel(panelName)
    self.logger:logDebug("isRecruitmentPanel(%s): STARTED", panelName)

    local result = false

    for key, recruitmentPool in pairs(self.recruitmentPools) do
        ---@cast recruitmentPool TotoWarCbacRecruitmentPoolUI

        if recruitmentPool.panelName == panelName then
            result = true

            break
        end
    end

    self.logger:logDebug("isRecruitmentPanel(%s): COMPLETED => %s", panelName, result)

    return result
end

---Reacts to a character being deselected.
function TotoWarCbacUIManager:onCharacterDeselected()
    self.logger:logDebug("[EVENT] onCharacterDeselected(): STARTED")

    self:resetUIChangeFlags()

    self.logger:logDebug("[EVENT] onCharacterDeselected(): COMPLETED")
end

---Reacts to a panel being closed.
---@param panelName string Name of the panel;
function TotoWarCbacUIManager:onPanelClosed(panelName)
    self.logger:logDebug("[EVENT] onPanelClosed(%s): STARTED", panelName)

    if panelName == TotoWar().ui.enums.panels.recruitmentOptions then
        self:resetUIChangeFlags()
    end

    self.logger:logDebug("[EVENT] onPanelClosed(%s): COMPLETED", panelName)
end

---Reacts to a panel being opened.
---@param panelName string Name of the panel;
function TotoWarCbacUIManager:onPanelOpened(panelName)
    --- We do not need to update the units_panel when it is opened, because it is the
    --- fact that it is opened that triggers the army supplies cost calculation.
    --- So when it is opened, the army supplies cost is not up to date.
    --- It is later updated when the SelectedGeneralArmySuppliesCostChanged event is triggered.

    self.logger:logDebug("[EVENT] onPanelOpened(%s): STARTED", panelName)

    local recruitmentPools = self:findRecruitmentPoolsInPanel(panelName)
    local recruitmentPoolsToUpdate = {}

    for i, recruitmentPool in ipairs(recruitmentPools) do
        local wasOpen = false

        for j, lastOpenedRecruitmentPool in ipairs(self.lastOpenedRecruitmentPools) do
            if recruitmentPool.name == lastOpenedRecruitmentPool then
                wasOpen = true

                break
            end
        end

        if not wasOpen then
            table.insert(recruitmentPoolsToUpdate, recruitmentPool)
        end
    end

    self:updateRecruitmentPools(recruitmentPools)

    self.lastOpenedPanel = panelName
    self.lastOpenedRecruitmentPools = recruitmentPools

    self.logger:logDebug("[EVENT] onPanelOpened(%s): COMPLETED", panelName)
end

---Reacts to the army supplies cost of the selected general changing.
function TotoWarCbacUIManager:onSelectedGeneralArmySuppliesCostChanged()
    self.logger:logDebug("[EVENT] onSelectedGeneralArmySuppliesCostChanged(): STARTED")

    self:updateUnitsPanel()

    local recruitmentPools = self:findOpenRecruitmentPoolsToUpdate(TotoWar_Cbac().uiManager.enums
        .recruitmentPoolUpdateMode.selectedGeneralArmySuppliesCostChanged)
    self:updateRecruitmentPools(recruitmentPools)

    self.logger:logDebug("[EVENT] onSelectedGeneralArmySuppliesCostChanged(): COMPLETED")
end

---Resets flags that indicate UI changes have been made to display army supply costs.
function TotoWarCbacUIManager:resetUIChangeFlags()
    self.logger:logDebug("resetUIChangeFlags(): STARTED")

    self.lastOpenedPanel = nil
    self.lastOpenedRecruitmentPools = {}

    for key, recruitmentPool in pairs(self.recruitmentPools) do
        ---@cast recruitmentPool TotoWarCbacRecruitmentPoolUI

        recruitmentPool.isResized = false
    end

    self.logger:logDebug("resetUIChangeFlags(): COMPLETED")
end

---Updates the allied recruitment pool.
function TotoWarCbacUIManager:updateAlliedRecruitmentPool()
    self.logger:logDebug("updateAlliedRecruitmentPanel(): STARTED")

    local alliedRecruitmentPoolUIComponent = TotoWar().ui:getUIComponent(
        TotoWar().ui.uiComponentQueries.recruitmentOptionsAlliedRecruitmentPool)

    local unitListQuery = { "listview", "list_clip", "allied_unit_list" }

    if not self.recruitmentPools.alliedPool.isResized then
        -- The listview and its content needs to be resized once until the recruitment panel is closed
        TotoWar().ui:resizeUIComponentAndChildren(
            alliedRecruitmentPoolUIComponent,
            0,
            _armySuppliesCostUIComponentHeight,
            unitListQuery)
        self.recruitmentPools.alliedPool.isResized = true;
    end

    local unitListUIComponent = TotoWar().ui:findUIComponentChild(
        alliedRecruitmentPoolUIComponent,
        unitListQuery)

    if unitListUIComponent then
        self:updateRecruitableUnitCardList(unitListUIComponent)
    end

    self.logger:logDebug("updateAlliedRecruitmentPanel(): COMPLETED")
end

---Updates the global recruitment pool.
function TotoWarCbacUIManager:updateGlobalRecruitmentPool()
    self.logger:logDebug("updateGlobalRecruitmentPool(): STARTED")

    local globalRecruitmentPoolUIComponent = TotoWar().ui:getUIComponent(
        self.recruitmentPools.globalPool.uiComponentQuery)

    local unitListQuery = { "listview", "list_clip", "list_box" }

    if not self.recruitmentPools.globalPool.isResized then
        -- The listview and its content needs to be resized once until the recruitment panel is closed
        TotoWar().ui:resizeUIComponentAndChildren(
            globalRecruitmentPoolUIComponent,
            0,
            _armySuppliesCostUIComponentHeight,
            unitListQuery)
        self.recruitmentPools.globalPool.isResized = true
    end

    local unitListUIComponent = TotoWar().ui:findUIComponentChild(
        globalRecruitmentPoolUIComponent,
        unitListQuery)

    if unitListUIComponent then
        self:updateRecruitableUnitCardList(unitListUIComponent)
    end

    self.logger:logDebug("updateGlobalRecruitmentPool(): COMPLETED")
end

---Updates the local recruitment pool.
function TotoWarCbacUIManager:updateLocalRecruitmentPool()
    self.logger:logDebug("updateLocalRecruitmentPool(): STARTED")

    local localRecruitmentPoolUIComponent = TotoWar().ui:getUIComponent(
        self.recruitmentPools.localPool.uiComponentQuery)

    local unitCardListQuery = { "listview", "list_clip", "list_box" }

    if not self.recruitmentPools.localPool.isResized then
        -- The listview and its content needs to be resized once until the recruitment panel is closed
        TotoWar().ui:resizeUIComponentAndChildren(
            localRecruitmentPoolUIComponent,
            0,
            _armySuppliesCostUIComponentHeight,
            unitCardListQuery)
        self.recruitmentPools.localPool.isResized = true
    end

    local unitCardListUIComponent = TotoWar().ui:findUIComponentChild(
        localRecruitmentPoolUIComponent,
        unitCardListQuery)

    if unitCardListUIComponent then
        self:updateRecruitableUnitCardList(unitCardListUIComponent)
    end

    self.logger:logDebug("updateLocalRecruitmentPool(): COMPLETED")
end

---Updates the mercenary recruitment pool.
function TotoWarCbacUIManager:updateMercenaryRecruitmentPool()
    self.logger:logDebug("updateMercenaryRecruitmentPanel(): STARTED")

    local mercenaryRecruitmentPoolUIComponent = TotoWar().ui:getUIComponent(
        TotoWar().ui.uiComponentQueries.recruitmentOptionsMercenaryRecruitmentPool)

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

---Updates the army supplies cost of a recruitable unit card.
---@param unitCardUIComponent UIC Unit card UI component.
function TotoWarCbacUIManager:updateRecruitableUnitCard(unitCardUIComponent)
    local unitContext = TotoWar().ui:getUIComponentCCO(
        unitCardUIComponent,
        TotoWar().ui.enums.ccoContextTypeIds.ccoMainUnitRecord)

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

        unitCardUIComponent:SetDisabled(true)
        unitCardUIComponent:SetState("inactive")
        unitBaseCostText = string.format("[[col:%s]]%s[[/col]]", TotoWar().utils.enums.colors.red, unitBaseCostText)
    end

    local armyCostUIComponentDetailUIComponent = TotoWar().ui:getUIComponentChild(
        armySuppliesCostUIComponent,
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

---Updates army supplies costs on recruitment pools.
---@param recruitmentPools TotoWarCbacRecruitmentPoolUI Recruitment pools.
function TotoWarCbacUIManager:updateRecruitmentPools(recruitmentPools)
    self.logger:logDebug("updateRecruitmentPools(): STARTED")

    for key, recruitmentPool in pairs(recruitmentPools) do
        ---@cast recruitmentPool TotoWarCbacRecruitmentPoolUI

        self.logger:logDebug("updateRecruitmentPools() => %s", recruitmentPool.name)

        recruitmentPool.updateUIFunction()
    end

    self.logger:logDebug("updateRecruitmentPools(): COMPLETED")
end

---Updates the army supplies cost of the panel that lists all the units in the selected army.
function TotoWarCbacUIManager:updateUnitsPanel()
    self.logger:logDebug("updateUnitsPanel(): STARTED")

    local armySuppliesCostUIComponent = TotoWar().ui:findUIComponent(TotoWarCbacUIManager.uiComponentQueries
        .unitsPanelIconListArmySuppliesCost)

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
            TotoWar().utils.enums.colors.red,
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
