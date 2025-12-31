local armyCostUIComponentHeight = 24
local armyCostUIComponentName = "totowar_cbac_army_cost"
local armyCostUIComponentOffsetY = -18
local modName = "totowar_cost_based_army_caps"
local logFileName = "totowar_cost_based_army_caps_logs.txt"

local TotowarDockingPoint = {
    topLeft = 1,
    topMiddle = 2,
    topRight = 3,
    middleLeft = 4,
    center = 5,
    middleRight = 6,
    bottomLeft = 7,
    bottomMiddle = 8,
    bottomRight = 9
}

---@class TotowarCbacManager
local TotowarCbacManager = {
    ---@type boolean
    isDebug = false,
    ---@type TotowarLogger
    logger = nil
}

---Resizes a UI component.
---@param uiComponent UIC UI component.
---@param widthToAdd number Width to add.
---@param heightToAdd number Height to add.
local function resizeUIComponent(uiComponent, widthToAdd, heightToAdd)
    TotowarCbacManager.logger:logDebug("Resizing UI component \"%s\"", uiComponent:Id())

    local uiComponentWidth, uiComponentHeight = uiComponent:Dimensions()
    uiComponent:SetCanResizeWidth(true)
    uiComponent:SetCanResizeHeight(true)
    uiComponent:Resize(uiComponentWidth + widthToAdd, uiComponentHeight + heightToAdd, false)
end

---A UI components and its children listed in a path.
---@param uiComponent UIC UI component to resize.
---@param widthToAdd number Width to add.
---@param heightToAdd number Height to add.
---@param ... string Path containing the names of the child UI components to resize.
local function resizeUIComponentAndChildren(uiComponent, widthToAdd, heightToAdd, ...)
    TotowarCbacManager.logger:logDebug("Resizing UI component \"%s\" and its children", uiComponent:Id())

    local childUIComponentsPath = { ... }
    local currentChildUIComponentPath = {}

    resizeUIComponent(uiComponent, widthToAdd, heightToAdd)

    for i, childUIComponentName in ipairs(childUIComponentsPath) do
        TotowarCbacManager.logger:logDebug("Resizing child UI component \"%s\"", childUIComponentName)

        currentChildUIComponentPath[i] = childUIComponentName
        local childUIComponent = find_uicomponent(uiComponent, unpack(currentChildUIComponentPath))
        resizeUIComponent(childUIComponent, widthToAdd, heightToAdd)
    end
end

---Displays the army cost of on a unit card.
---@param unitUIComponent UIC Unit UI component.
local function displayUnitArmyCost(unitUIComponent)
    local unitContextId = unitUIComponent:GetContextObjectId("CcoMainUnitRecord")
    local unitContext = cco("CcoMainUnitRecord", unitContextId)

    unitName = unitContext:Call("Name")
    unitBaseCost = tonumber(unitContext:Call("BaseCost"))

    TotowarCbacManager.logger:logDebug("Displaying cost (%s) for unit \"%s\" (%s)", unitBaseCost, unitName, unitContextId)

    resizeUIComponent(unitUIComponent, 0, armyCostUIComponentHeight)

    local externalHolderUIComponent = find_uicomponent(unitUIComponent, "external_holder")
    resizeUIComponent(externalHolderUIComponent, 0, armyCostUIComponentHeight)

    local recruitmentCostUIComponent = find_uicomponent(externalHolderUIComponent, "RecruitmentCost")
    local recruitmentCostUIComponentOffsetX = recruitmentCostUIComponent:GetDockOffset()

    for i = 0, externalHolderUIComponent:ChildCount() - 1, 1 do
        -- Moving up each cost / upkeep component to display the army cost component last
        local childUIComponent = find_child_uicomponent_by_index(externalHolderUIComponent, i)
        local childUIComponentOffsetX, childUIComponentOffsetY = childUIComponent:GetDockOffset()
        childUIComponent:SetDockOffset(childUIComponentOffsetX, childUIComponentOffsetY - armyCostUIComponentHeight)
    end

    local armyCostUIComponent = UIComponent(recruitmentCostUIComponent:CopyComponent(armyCostUIComponentName))
    armyCostUIComponent:SetDockOffset(recruitmentCostUIComponentOffsetX, armyCostUIComponentOffsetY) -- OffsetX corresponds to the left padding

    local costUIComponent = find_uicomponent(armyCostUIComponent, "Cost")
    costUIComponent:DestroyChildren() -- Removing the price change arrow
    costUIComponent:SetText(tostring(unitBaseCost), tostring(unitBaseCost))
    costUIComponent:SetImagePath("ui/skins/default/wulfhart_imperial_supplies.png", 0, false)
end

---Displays the army cost of all the units in a recruitment UI (global or local).
---@param recruitmentUIComponent UIC Global or local recruitment UI component.
local function displayUnitsArmyCost(recruitmentUIComponent)
    resizeUIComponentAndChildren(
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
        displayUnitArmyCost(unitUIComponent)
    end
end

---Displays the army cost of the units in the global and local.
local function displayAllUnitsArmyCost()
    TotowarCbacManager.logger:logDebug("Displaying unit costs")

    local recruitmentDockerUIComponent = find_uicomponent(
        core:get_ui_root(),
        "units_panel",
        "main_units_panel",
        "recruitment_docker")
    local globalRecruitmentUIComponent = find_uicomponent(
        recruitmentDockerUIComponent,
        "recruitment_options",
        "recruitment_listbox",
        "recruitment_pool_list",
        "list_clip",
        "list_box",
        "global")
    local localRecruitmentUIComponent = find_uicomponent(
        recruitmentDockerUIComponent,
        "recruitment_options",
        "recruitment_listbox",
        "recruitment_pool_list",
        "list_clip",
        "list_box",
        "local1")

    -- TODO : Voir comment gérer les autres sources de recrutement (régiments de renom, grudge settlers, ...)

    displayUnitsArmyCost(globalRecruitmentUIComponent)
    displayUnitsArmyCost(localRecruitmentUIComponent)
end

---Adds listeners for events that will display UI elements and trigger cost verifications.
local function addListeners()
    TotowarCbacManager.logger:logDebug("Listeners subscription: Started")

    core:add_listener(
        "totowar_cbac_recruitment_panel",
        "PanelOpenedCampaign",
        function(context)
            return cm:get_campaign_ui_manager():is_panel_open("recruitment_options")
        end,
        function(context)
            cm:callback(
                function()
                    displayAllUnitsArmyCost()
                end,
                0.01)
        end,
        true
    )

    TotowarCbacManager.logger:logDebug("Listeners subscription: Completed")
end

---Initializes the mod.
function TotowarCbacManager:initialize()
    self.logger = TotowarLogger.new(modName, logFileName, self.isDebug)
    self.logger:logInfo("Mod initialization: Started")

    addListeners()

    self.logger:logInfo("Mod initialization: Completed")
end

core:add_static_object(modName, TotowarCbacManager)
