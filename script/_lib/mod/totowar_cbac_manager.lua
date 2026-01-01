totowarCbacModName = "totowar_cost_based_army_caps"

local armyCostUIComponentHeight = 24
local armyCostUIComponentName = "totowar_cbac_army_cost"
local armyCostUIComponentWidth = 150
local unitArmyCostUIComponentName = "totowar_cbac_unit_army_cost"
local unitArmyCostUIComponentOffsetY = -18

---Manager of the Totowar Cost-Based Army Caps.
---@class TotowarCbacManager
local TotowarCbacManager = {
    ---@type TotowarLogger
    logger = nil,
}

core:add_static_object(totowarCbacModName, TotowarCbacManager)

---Gets the army cost of an army.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE Army.
---@return number
local function getArmyCost(army)
    TotowarCbacManager.logger:logDebug("Get army cost (%s): Started", army:general_character():cqi())

    local armyCost = 0
    local units = army:unit_list()

    for i = 0, units:num_items() - 1, 1 do
        local unit = units:item_at(i)
        local unitCost = unit:get_unit_custom_battle_cost()
        armyCost = armyCost + unitCost
    end

    TotowarCbacManager.logger:logDebug("Get army cost (%s, %s): Completed", army:general_character():cqi(), armyCost)

    return armyCost
end

---Gets the unit panel army cost UI component.
---@return UIC
local function getUnitsPanelArmyCostUIComponent()
    TotowarCbacManager.logger:logDebug("Get unit panel army cost UI component: Started")

    local unitsPanelIconListUIComponent = TotoWarUtils.UI:getUnitsPanelIconListUIComponent()
    local armyCostUIComponent = find_uicomponent(unitsPanelIconListUIComponent, armyCostUIComponentName)

    TotowarCbacManager.logger:logDebug("Get unit panel army cost UI component: Completed")

    return armyCostUIComponent
end

---Destroys the army cost UI component.
local function destroyArmyCostUIComponent()
    TotowarCbacManager.logger:logDebug("Destroy army cost UI component: Started")

    local armyCostUIComponent = getUnitsPanelArmyCostUIComponent()
    armyCostUIComponent:Destroy()

    TotowarCbacManager.logger:logDebug("Destroy army cost UI component: Completed")
end

---Displays the army cost of on a unit card.
---@param unitUIComponent UIC Unit UI component.
local function displayRecruitableUnitArmyCost(unitUIComponent)
    local unitContext = TotoWarUtils.UI:getComponentContextObject(
        unitUIComponent,
        TotoWarUtils.Enums.CcoContextTypeId.ccoMainUnitRecord)

    local unitName = unitContext:Call("Name")
    local unitBaseCost = tonumber(unitContext:Call("BaseCost"))

    TotowarCbacManager.logger:logDebug("Display unit army cost (\"%s\", %s): Started", unitName, unitBaseCost)

    local externalHolderUIComponent = find_uicomponent(unitUIComponent, "external_holder")
    TotoWarUtils.UI:resizeUIComponent(unitUIComponent, 0, armyCostUIComponentHeight)
    TotoWarUtils.UI:resizeUIComponent(externalHolderUIComponent, 0, armyCostUIComponentHeight)

    local recruitmentCostUIComponent = find_uicomponent(externalHolderUIComponent, "RecruitmentCost")
    local xPadding = recruitmentCostUIComponent:GetDockOffset()

    -- Moving up each cost / upkeep component to display the army cost component last
    TotoWarUtils.UI:offsetChildUIComponents(externalHolderUIComponent, 0, -armyCostUIComponentHeight)

    -- Copying the recruitment cost UI component to create the army cost UI component
    local armyCostUIComponent = UIComponent(recruitmentCostUIComponent:CopyComponent(unitArmyCostUIComponentName))
    armyCostUIComponent:SetDockOffset(xPadding, unitArmyCostUIComponentOffsetY)

    local costUIComponent = find_uicomponent(armyCostUIComponent, "Cost")
    costUIComponent:DestroyChildren() -- Removing the price change arrow copied from
    costUIComponent:SetText(tostring(unitBaseCost), "")
    costUIComponent:SetImagePath("ui/skins/default/wulfhart_imperial_supplies.png", 0, false)

    TotowarCbacManager.logger:logDebug("Display unit army cost (\"%s\", %s): Completed", unitName, unitBaseCost)
end

---Displays the army cost of all the units in a recruitment pool UI (global or local).
---@param recruitmentUIComponent UIC Global or local recruitment pool UI component.
local function displayRecruitmentPoolArmyCost(recruitmentUIComponent)
    TotowarCbacManager.logger:logDebug(
        "Display recruitable units army cost in recruitment pool (\"%s\"): Started",
        recruitmentUIComponent:Id())

    TotoWarUtils.UI:resizeUIComponentAndChildren(
        recruitmentUIComponent,
        0,
        armyCostUIComponentHeight,
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
        displayRecruitableUnitArmyCost(unitUIComponent)
    end

    TotowarCbacManager.logger:logDebug(
        "Display recruitable units army cost in recruitment pool (\"%s\"): Completed",
        recruitmentUIComponent:Id())
end

---Displays the army costs in the recruitment panel.
local function displayRecruitmentPanelArmyCosts()
    TotowarCbacManager.logger:logDebug("Display recruitment panel army costs: Started")

    local globalRecruitmentUIComponent = TotoWarUtils.UI:getGlobalRecruitmentPoolUIComponent()
    local localRecruitmentUIComponent = TotoWarUtils.UI:getLocalRecruitmentPoolUIComponent()

    displayRecruitmentPoolArmyCost(globalRecruitmentUIComponent)
    displayRecruitmentPoolArmyCost(localRecruitmentUIComponent)

    TotowarCbacManager.logger:logDebug("Display recruitment panel army costs: Completed")
end

---Updates or displays the army cost of the army of a character.
---@param character CHARACTER_SCRIPT_INTERFACE Selected character.
local function updateOrDisplayUnitsPanelArmyCost(character)
    TotowarCbacManager.logger:logDebug("Update or display army cost: Started")

    local armyCost = getArmyCost(character:military_force())
    local armyCostUIComponent = getUnitsPanelArmyCostUIComponent()

    if not armyCostUIComponent then
        -- The UI component still exists when clicking on another army after already selecting an army.
        -- In that case, we only need to update its text
        TotowarCbacManager.logger:logDebug("Creating army cost UI component: Started")

        -- Copying the upkeep cost UI component to create the army cost UI component
        local unitsPanelIconListUIComponent = TotoWarUtils.UI:getUnitsPanelIconListUIComponent()
        local upkeepUIComponent = find_uicomponent(unitsPanelIconListUIComponent, "dy_upkeep")
        armyCostUIComponent = UIComponent(upkeepUIComponent:CopyComponent(armyCostUIComponentName))
        armyCostUIComponent:SetImagePath("ui/skins/default/wulfhart_imperial_supplies.png", 1, false)

        TotowarCbacManager.logger:logDebug("Creating army cost UI component: Completed")
    end

    armyCostUIComponent:SetText(tostring(armyCost) .. " / " .. "TODO", "")

    TotowarCbacManager.logger:logDebug("Update or display army cost: Completed")
end

---Reacts to a character being selected.
---@param character CHARACTER_SCRIPT_INTERFACE Selected character.
function onCharacterSelected(character)
    TotowarCbacManager.logger:logDebug("Event character selected (%s): Started", character:cqi())

    if character:has_military_force() and TotoWarUtils:isPlayerFaction(character:faction():name()) then
        updateOrDisplayUnitsPanelArmyCost(character)
    else
        destroyArmyCostUIComponent()
    end

    TotowarCbacManager.logger:logDebug("Event character selected (%s): Completed", character:cqi())
end

---Reacts to a panel being opened.
function onPanelOpened()
    TotowarCbacManager.logger:logDebug("Event panel opened: Started")

    if cm:get_campaign_ui_manager():is_panel_open("recruitment_options") then
        displayRecruitmentPanelArmyCosts()
    end

    TotowarCbacManager.logger:logDebug("Event panel opened: Completed")
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
            cm:callback(onPanelOpened, TotoWarUtils.eventCallbackTriggerDelay)
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
