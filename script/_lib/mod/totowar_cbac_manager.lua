totowarCbacModName = "totowar_cost_based_army_caps"

local armySupplyCostUIComponentHeight = 24
local armySupplyCostUIComponentName = "totowar_cbac_army_cost"
local armySupplyIcon = "ui/skins/default/wulfhart_imperial_supplies.png"
local unitArmySupplyCostUIComponentName = "totowar_cbac_unit_army_cost"
local unitArmySupplyCostUIComponentOffsetY = -18

---Manager of the Totowar Cost-Based Army Caps.
---@class TotowarCbacManager
local TotowarCbacManager = {
    ---Logger.
    ---@type TotowarLogger
    logger = nil
}

core:add_static_object(totowarCbacModName, TotowarCbacManager)

---Gets the army supply cost of an army.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@return number
local function getArmySupplyCost(army)
    TotowarCbacManager.logger:logDebug("Get army supply cost (%s): Started", army:general_character():cqi())

    local armyCost = 0
    local units = army:unit_list()

    for i = 0, units:num_items() - 1, 1 do
        local unit = units:item_at(i)
        local unitCost = unit:get_unit_custom_battle_cost()
        armyCost = armyCost + unitCost
    end

    TotowarCbacManager.logger:logDebug("Get army supply cost (%s, %s): Completed", army:general_character():cqi(),
        armyCost)

    return armyCost
end

---Gets the unit panel army supply cost UI component.
---@return UIC
local function getUnitsPanelArmySupplyCostUIComponent()
    TotowarCbacManager.logger:logDebug("Get unit panel army supply cost UI component: Started")

    local unitsPanelIconListUIComponent = TotoWarUtils.UI:getUnitsPanelIconListUIComponent()
    local armyCostUIComponent = find_uicomponent(unitsPanelIconListUIComponent, armySupplyCostUIComponentName)

    TotowarCbacManager.logger:logDebug("Get unit panel army supply cost UI component: Completed")

    return armyCostUIComponent
end

---Destroys the army supply cost UI component.
local function hideArmySupplyCostUIComponent()
    TotowarCbacManager.logger:logDebug("Destroy army supply cost UI component: Started")

    local armyCostUIComponent = getUnitsPanelArmySupplyCostUIComponent()

    if armyCostUIComponent then
        armyCostUIComponent:SetVisible(false)
    end

    TotowarCbacManager.logger:logDebug("Destroy army supply cost UI component: Completed")
end

---Displays of updates (when switching between generals) the army supply cost of the army of the selected player faction general.
---@param general CHARACTER_SCRIPT_INTERFACE Player faction general.
local function displayOrUpdateUnitsPanelArmySupplyCost(general)
    TotowarCbacManager.logger:logDebug("Display or update army supply cost: Started")

    local armyCost = getArmySupplyCost(general:military_force())
    local armyCostUIComponent = getUnitsPanelArmySupplyCostUIComponent()

    if not armyCostUIComponent then
        -- Copying the upkeep cost UI component to create the army supply cost UI component
        local unitsPanelIconListUIComponent = TotoWarUtils.UI:getUnitsPanelIconListUIComponent()
        local upkeepUIComponent = find_uicomponent(unitsPanelIconListUIComponent, "dy_upkeep")
        armyCostUIComponent = UIComponent(upkeepUIComponent:CopyComponent(armySupplyCostUIComponentName))
        armyCostUIComponent:SetImagePath(armySupplyIcon, 1, false)
        armyCostUIComponent:SetTooltipText(
            "TODO LOCALIZE Army supplies||Total amount of supplies the army can provide to sustain recruited units.",
            true)
    end

    armyCostUIComponent:SetText(tostring(armyCost) .. " / " .. "TODO", "")
    armyCostUIComponent:SetVisible(true)

    TotowarCbacManager.logger:logDebug("Display or update army supply cost (%s): Completed", armyCost)
end

---Displays the army supply cost of on a unit card.
---@param unitUIComponent UIC Unit UI component.
local function displayRecruitableUnitArmySupplyCost(unitUIComponent)
    local unitContext = TotoWarUtils.UI:getComponentContextObject(
        unitUIComponent,
        TotoWarUtils.Enums.CcoContextTypeId.ccoMainUnitRecord)

    local unitName = unitContext:Call("Name")
    local unitBaseCost = tonumber(unitContext:Call("BaseCost"))

    TotowarCbacManager.logger:logDebug("Display unit army supply cost (\"%s\", %s): Started", unitName, unitBaseCost)

    local externalHolderUIComponent = find_uicomponent(unitUIComponent, "external_holder")
    TotoWarUtils.UI:resizeUIComponent(unitUIComponent, 0, armySupplyCostUIComponentHeight)
    TotoWarUtils.UI:resizeUIComponent(externalHolderUIComponent, 0, armySupplyCostUIComponentHeight)

    local recruitmentCostUIComponent = find_uicomponent(externalHolderUIComponent, "RecruitmentCost")
    local xPadding = recruitmentCostUIComponent:GetDockOffset()

    -- Moving up each cost / upkeep component (they are docked at the bottom) to display the army supply cost component last
    TotoWarUtils.UI:offsetChildUIComponents(externalHolderUIComponent, 0, -armySupplyCostUIComponentHeight)

    -- Copying the recruitment cost UI component to create the army supply cost UI component
    local armyCostUIComponent = UIComponent(recruitmentCostUIComponent:CopyComponent(unitArmySupplyCostUIComponentName))
    armyCostUIComponent:SetDockOffset(xPadding, unitArmySupplyCostUIComponentOffsetY)

    local costUIComponent = find_uicomponent(armyCostUIComponent, "Cost")
    costUIComponent:DestroyChildren() -- Removing the price change arrow copied from
    costUIComponent:SetText(tostring(unitBaseCost), "")
    costUIComponent:SetTooltipText(
        "TODO LOCALIZE Army supplies||This unit consumes this amount of [[img:wulfhart_imperial_supplies]][[/img]]Army supplies.",
        true)
    costUIComponent:SetImagePath(armySupplyIcon, 0, false)

    TotowarCbacManager.logger:logDebug("Display unit army supply cost (\"%s\", %s): Completed", unitName, unitBaseCost)
end

---Displays the army supply cost of all the units in a recruitment pool UI (global or local).
---@param recruitmentUIComponent UIC Global or local recruitment pool UI component.
local function displayRecruitmentPoolArmySupplyCost(recruitmentUIComponent)
    TotowarCbacManager.logger:logDebug(
        "Display recruitable units army supply cost in recruitment pool (\"%s\"): Started",
        recruitmentUIComponent:Id())

    TotoWarUtils.UI:resizeUIComponentAndChildren(
        recruitmentUIComponent,
        0,
        armySupplyCostUIComponentHeight,
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
        displayRecruitableUnitArmySupplyCost(unitUIComponent)
    end

    TotowarCbacManager.logger:logDebug(
        "Display recruitable units army supply cost in recruitment pool (\"%s\"): Completed",
        recruitmentUIComponent:Id())
end

---Displays the army supply costs in the recruitment panel.
local function displayRecruitmentPanelArmySupplyCosts()
    TotowarCbacManager.logger:logDebug("Display recruitment panel army supply costs: Started")

    local globalRecruitmentUIComponent = TotoWarUtils.UI:getGlobalRecruitmentPoolUIComponent()
    local localRecruitmentUIComponent = TotoWarUtils.UI:getLocalRecruitmentPoolUIComponent()

    displayRecruitmentPoolArmySupplyCost(globalRecruitmentUIComponent)
    displayRecruitmentPoolArmySupplyCost(localRecruitmentUIComponent)

    TotowarCbacManager.logger:logDebug("Display recruitment panel army supply costs: Completed")
end

---Reacts to a character being selected.
---@param character CHARACTER_SCRIPT_INTERFACE Selected character.
function onCharacterSelected(character)
    TotowarCbacManager.logger:logDebug("Event character selected (%s): Started", character:cqi())

    local canRecruit =
        TotoWarUtils:isPlayerFactionGeneral(character)
        and TotoWarUtils:canArmyRecruit(character:military_force())

    if canRecruit then
        displayOrUpdateUnitsPanelArmySupplyCost(character)
    else
        hideArmySupplyCostUIComponent()
    end

    TotowarCbacManager.logger:logDebug("Event character selected (%s): Completed", character:cqi())
end

---Reacts to a panel being opened.
---@param panelId string
function onPanelOpened(panelId)
    TotowarCbacManager.logger:logDebug("Event panel opened (\"%s\"): Started", panelId)

    if panelId == "recruitment_options" then
        displayRecruitmentPanelArmySupplyCosts()
    end

    TotowarCbacManager.logger:logDebug("Event panel opened (\"%s\"): Completed", panelId)
end

---Adds listeners for events that will display UI elements and trigger cost verifications.
local function addListeners()
    TotowarCbacManager.logger:logDebug("Add listeners: Started")

    TotowarCbacManager.logger:logDebug(
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

    TotowarCbacManager.logger:logDebug(
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

    TotowarCbacManager.logger:logDebug("Add listeners: Completed")
end

---Initializes the mod.
function TotowarCbacManager:initialize()
    self.logger = TotowarLogger.new(totowarCbacModName)
    self.logger:logInfo("Initialize mod: Started")

    addListeners()

    self.logger:logInfo("Initialize mod: Completed")
end
