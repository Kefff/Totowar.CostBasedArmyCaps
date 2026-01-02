totowarCbacModName = "totowar_cost_based_army_caps"

local armySuppliesCostUIComponentHeight = 24
local armySuppliesCostUIComponentName = "totowar_cbac_army_supply_cost"
local armySuppliesIconId = "icon_merc"
local armySuppliesIconPath = "ui/skins/default/merc.png"
local armySuppliesDepletedIconId = "totowar_cbac_army_supply_depleted"
local armySuppliesDepletedIconPath = "ui/skins/warhammer2/icon_status_alert_high.png"
local defaultArmySupplies = 12400 -- Cannot be read from DB table (mp_budgets_table)
local unitArmySuppliesCostUIComponentName = "totowar_cbac_unit_army_supply_cost"
local unitArmySuppliesCostUIComponentOffsetY = -18

---Manager of the Totowar Cost-Based Army Caps.
---@class TotoWarCbacManager
local TotoWarCbacManager = {
    ---Army supplies
    ---@type number
    armySupplies = defaultArmySupplies,

    ---Logger.
    ---@type TotoWarLogger
    logger = nil,

    ---Selected general.
    ---@type CHARACTER_SCRIPT_INTERFACE
    selectedGeneral = nil,

    ---Selected general army cost.
    ---@type TotoWarArmySuppliesCost
    selectedGeneralArmySuppliesCost = nil
}

core:add_static_object(totowarCbacModName, TotoWarCbacManager)

---Gets the unit panel army supplies cost UI component.
---@return UIC
local function getUnitsPanelArmySuppliesCostUIComponent()
    TotoWarCbacManager.logger:logDebug("Get unit panel army supplies cost UI component: Started")

    local unitsPanelIconListUIComponent = TotoWarUtils.UI:getUnitsPanelIconListUIComponent()
    local armyCostUIComponent = find_uicomponent(unitsPanelIconListUIComponent, armySuppliesCostUIComponentName)

    TotoWarCbacManager.logger:logDebug("Get unit panel army supplies cost UI component: Completed")

    return armyCostUIComponent
end

---Destroys the army supplies cost UI component.
local function hideArmySuppliesCostUIComponent()
    TotoWarCbacManager.logger:logDebug("Destroy army supplies cost UI component: Started")

    local armyCostUIComponent = getUnitsPanelArmySuppliesCostUIComponent()

    if armyCostUIComponent then
        armyCostUIComponent:SetVisible(false)
    end

    TotoWarCbacManager.logger:logDebug("Destroy army supplies cost UI component: Completed")
end

---Displays of updates (when switching between generals) the army supplies cost of the army of the selected player faction general.
---@param general CHARACTER_SCRIPT_INTERFACE Player faction general.
local function displayOrUpdateUnitsPanelArmySuppliesCost(general)
    TotoWarCbacManager.logger:logDebug("Display or update army supplies cost: Started")

    local armySuppliesCostUIComponent = getUnitsPanelArmySuppliesCostUIComponent()

    if not armySuppliesCostUIComponent then
        -- Copying the upkeep cost UI component to create the army supplies cost UI component
        local unitsPanelIconListUIComponent = TotoWarUtils.UI:getUnitsPanelIconListUIComponent()
        local upkeepUIComponent = find_uicomponent(unitsPanelIconListUIComponent, "dy_upkeep")
        armySuppliesCostUIComponent = UIComponent(upkeepUIComponent:CopyComponent(armySuppliesCostUIComponentName))
        armySuppliesCostUIComponent:SetImagePath(armySuppliesIconPath, 1, false)
    end

    local totalCostText = ""

    if TotoWarCbacManager.selectedGeneralArmySuppliesCost.totalCost > TotoWarCbacManager.armySupplies then
        totalCostText = string.format(
            "[[col:%s]]%s[[/col]] / %s [[img:%s]][[/img]]",
            TotoWarUtils.Enums.Color.red,
            tostring(TotoWarCbacManager.selectedGeneralArmySuppliesCost.totalCost),
            TotoWarCbacManager.armySupplies,
            armySuppliesDepletedIconId)
    else
        totalCostText = string.format(
            "%s / %s",
            tostring(TotoWarCbacManager.selectedGeneralArmySuppliesCost.totalCost),
            TotoWarCbacManager.armySupplies)
    end

    armySuppliesCostUIComponent:SetText(totalCostText, "")
    armySuppliesCostUIComponent:SetTooltipText(
        TotoWarCbacManager.selectedGeneralArmySuppliesCost:toTooltipText(TotoWarCbacManager.armySupplies),
        true)
    armySuppliesCostUIComponent:SetVisible(true)

    TotoWarCbacManager.logger:logDebug(
        "Display or update army supplies cost (%s): Completed",
        TotoWarCbacManager.selectedGeneralArmySuppliesCost.totalCost)
end

---Displays the army supplies cost of on a unit card.
---@param unitUIComponent UIC Unit UI component.
local function displayRecruitableUnitArmySuppliesCost(unitUIComponent)
    local unitContext = TotoWarUtils.UI:getComponentContextObject(
        unitUIComponent,
        TotoWarUtils.Enums.CcoContextTypeId.ccoMainUnitRecord)

    local unitName = unitContext:Call("Name")
    local unitBaseCost = tonumber(unitContext:Call("BaseCost"))

    TotoWarCbacManager.logger:logDebug("Display unit army supplies cost (\"%s\", %s): Started", unitName, unitBaseCost)

    local externalHolderUIComponent = find_uicomponent(unitUIComponent, "external_holder")
    TotoWarUtils.UI:resizeUIComponent(unitUIComponent, 0, armySuppliesCostUIComponentHeight)
    TotoWarUtils.UI:resizeUIComponent(externalHolderUIComponent, 0, armySuppliesCostUIComponentHeight)

    local recruitmentCostUIComponent = find_uicomponent(externalHolderUIComponent, "RecruitmentCost")
    local xPadding = recruitmentCostUIComponent:GetDockOffset()

    -- Moving up each cost / upkeep component (they are docked at the bottom) to display the army supplies cost component last
    TotoWarUtils.UI:offsetChildUIComponents(externalHolderUIComponent, 0, -armySuppliesCostUIComponentHeight)

    -- Copying the recruitment cost UI component to create the army supplies cost UI component
    local armyCostUIComponent = UIComponent(recruitmentCostUIComponent:CopyComponent(unitArmySuppliesCostUIComponentName))
    armyCostUIComponent:SetDockOffset(xPadding, unitArmySuppliesCostUIComponentOffsetY)
    armyCostUIComponent:SetTooltipText(
        common.get_localised_string("totowar_cbac_unit_army_supply_cost_tooltip"),
        true)

    local unitBaseCostText = tostring(unitBaseCost)
    local availableArmySupplies = TotoWarCbacManager.armySupplies -
        TotoWarCbacManager.selectedGeneralArmySuppliesCost.totalCost

    if unitBaseCost > availableArmySupplies then
        unitBaseCostText = string.format("[[col:%s]]%s[[/col]]", TotoWarUtils.Enums.Color.red, unitBaseCostText)
    end

    local costUIComponent = find_uicomponent(armyCostUIComponent, "Cost")
    costUIComponent:DestroyChildren() -- Removing the price change arrow copied from
    costUIComponent:SetText(unitBaseCostText, "")
    costUIComponent:SetImagePath(armySuppliesIconPath, 0, false)

    TotoWarCbacManager.logger:logDebug("Display unit army supplies cost (\"%s\", %s): Completed", unitName, unitBaseCost)
end

---Displays the army supplies cost of all the units in a recruitment pool UI (global or local).
---@param recruitmentUIComponent UIC Global or local recruitment pool UI component.
local function displayRecruitmentPoolArmySuppliesCost(recruitmentUIComponent)
    TotoWarCbacManager.logger:logDebug(
        "Display recruitable units army supplies cost in recruitment pool (\"%s\"): Started",
        recruitmentUIComponent:Id())

    TotoWarUtils.UI:resizeUIComponentAndChildren(
        recruitmentUIComponent,
        0,
        armySuppliesCostUIComponentHeight,
        "unit_list",
        "listview",
        "list_clip",
        "list_box")
    local unitListUIComponent = find_uicomponent(
        recruitmentUIComponent,
        "unit_list",
        "listview",
        "list_clip",
        "list_box")

    for i = 0, unitListUIComponent:ChildCount() - 1 do
        local unitUIComponent = find_child_uicomponent_by_index(unitListUIComponent, i)
        displayRecruitableUnitArmySuppliesCost(unitUIComponent)
    end

    TotoWarCbacManager.logger:logDebug(
        "Display recruitable units army supplies cost in recruitment pool (\"%s\"): Completed",
        recruitmentUIComponent:Id())
end

---Displays the army supplies costs in the recruitment panel.
local function displayRecruitmentPanelArmySuppliesCosts()
    TotoWarCbacManager.logger:logDebug("Display recruitment panel army supplies costs: Started")

    local globalRecruitmentUIComponent = TotoWarUtils.UI:getGlobalRecruitmentPoolUIComponent()
    local localRecruitmentUIComponent = TotoWarUtils.UI:getLocalRecruitmentPoolUIComponent()

    displayRecruitmentPoolArmySuppliesCost(globalRecruitmentUIComponent)
    displayRecruitmentPoolArmySuppliesCost(localRecruitmentUIComponent)

    TotoWarCbacManager.logger:logDebug("Display recruitment panel army supplies costs: Completed")
end

---Sets the selected general and calculate the price of its army
---@param general? CHARACTER_SCRIPT_INTERFACE Selected general.
local function setSelectedGeneral(general)
    if general then
        TotoWarCbacManager.logger:logDebug("Set selected general (%s): Started", general:cqi())

        TotoWarCbacManager.selectedGeneral = general
        TotoWarCbacManager.selectedGeneralArmySuppliesCost = TotoWarArmySuppliesCost.new(general:military_force())

        TotoWarCbacManager.logger:logDebug("Set selected general (%s): Completed", general:cqi())
    else
        TotoWarCbacManager.logger:logDebug("Set selected general (nil): Started")

        TotoWarCbacManager.selectedGeneral = nil
        TotoWarCbacManager.selectedGeneralArmySuppliesCost = nil

        TotoWarCbacManager.logger:logDebug("Set selected general (nil): Completed")
    end
end

---Reacts to a character being deselected.
local function onCharacterDeselected()
    setSelectedGeneral(nil)
end

---Reacts to a character being selected.
---@param character CHARACTER_SCRIPT_INTERFACE Selected character.
local function onCharacterSelected(character)
    TotoWarCbacManager.logger:logDebug("Event character selected (%s): Started", character:cqi())

    local canRecruit =
        TotoWarUtils:isPlayerFactionGeneral(character)
        and TotoWarUtils:canArmyRecruit(character:military_force())

    if canRecruit then
        setSelectedGeneral(character)
        displayOrUpdateUnitsPanelArmySuppliesCost(character)
    else
        setSelectedGeneral(nil)
        hideArmySuppliesCostUIComponent()
    end

    TotoWarCbacManager.logger:logDebug("Event character selected (%s): Completed", character:cqi())
end

---Reacts to a panel being opened.
---@param panelId string
local function onPanelOpened(panelId)
    TotoWarCbacManager.logger:logDebug("Event panel opened (\"%s\"): Started", panelId)

    if panelId == TotoWarUtils.Enums.Panel.recruitmentOptions then
        displayRecruitmentPanelArmySuppliesCosts()
    end

    TotoWarCbacManager.logger:logDebug("Event panel opened (\"%s\"): Completed", panelId)
end

---Adds listeners for events that will display UI elements and trigger cost verifications.
local function addListeners()
    TotoWarCbacManager.logger:logDebug("Add listeners: Started")

    TotoWarCbacManager.logger:logDebug(
        "Add listener to event \"%s\"",
        TotoWarUtils.Enums.Event.characterDeselected)
    core:add_listener(
        "totowar_cbac_character_deselected",
        TotoWarUtils.Enums.Event.characterDeselected,
        true,
        function(context)
            cm:callback(onCharacterDeselected, TotoWarUtils.eventCallbackTriggerDelay)
        end,
        true)

    TotoWarCbacManager.logger:logDebug(
        "Add listener to event \"%s\"",
        TotoWarUtils.Enums.Event.characterSelected)
    core:add_listener(
        "totowar_cbac_character_selected",
        TotoWarUtils.Enums.Event.characterSelected,
        true,
        ---@param context CharacterSelected
        function(context)
            local character = context:character()
            cm:callback(
                function()
                    onCharacterSelected(character)
                end,
                TotoWarUtils.eventCallbackTriggerDelay)
        end,
        true)

    TotoWarCbacManager.logger:logDebug(
        "Add listener to event \"%s\"",
        TotoWarUtils.Enums.Event.panelOpenedCampaign)
    core:add_listener(
        "totowar_cbac_recruitment_panel_opened",
        TotoWarUtils.Enums.Event.panelOpenedCampaign,
        true,
        function(context)
            local panelId = context.string
            cm:callback(
                function()
                    onPanelOpened(panelId)
                end,
                TotoWarUtils.eventCallbackTriggerDelay)
        end,
        true)

    TotoWarCbacManager.logger:logDebug("Add listeners: Completed")
end

---Initializes the mod.
function TotoWarCbacManager:initialize()
    self.logger = TotoWarLogger.new(totowarCbacModName)
    self.logger:logInfo("Initialize mod: Started")

    addListeners()

    self.logger:logInfo("Initialize mod: Completed")
end
