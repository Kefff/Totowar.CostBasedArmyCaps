local armyCostUIComponentName = "totowar_cbac_army_cost"
local modName = "totowar_cost_based_army_caps"
local logFileName = "totowar_cost_based_army_caps_logs.txt"

---@class TotowarCbacManager
local TotowarCbacManager = {
    ---@type boolean
    isDebug = false,
    ---@type TotowarLogger
    logger = nil
};

---Displays the army cost of on a unit card.
---@param unitUIComponent UIC Unit UI component.
local function displayUnitArmyCost(unitUIComponent)
    TotowarCbacManager.logger:logDebug("Displaying cost for unit %s", unitUIComponent:GetTooltipText())

    local recruitmentCostUIComponent = find_uicomponent(unitUIComponent, "external_holder", "RecruitmentCost")
    local armyCostUIComponent = UIComponent(recruitmentCostUIComponent:CopyComponent(armyCostUIComponentName))
    local costUIComponent = find_uicomponent(armyCostUIComponent, "Cost")
    armyCostUIComponent:SetDockOffset(0, -19)
    costUIComponent:SetText("Hello", "Hello")
    costUIComponent:SetImagePath("ui/skins/default/wulfhart_imperial_supplies.png", 1);
end

---Displays the army cost of all the units in a recruitment UI (global or local).
---@param recruitmentUIComponent UIC Global or local recruitment UI component.
local function displayUnitsArmyCost(recruitmentUIComponent)
    for i = 0, recruitmentUIComponent:ChildCount() - 1 do
        local unitUIComponent = find_child_uicomponent_by_index(recruitmentUIComponent, i)
        displayUnitArmyCost(unitUIComponent)
    end
end

---Displays the army cost of the units in the global and local.
local function displayAllUnitsArmyCost()
    TotowarCbacManager.logger:logDebug("Displaying unit costs")

    local recruitmentUIComponent = find_uicomponent(
        core:get_ui_root(),
        "units_panel",
        "main_units_panel",
        "recruitment_docker",
        "recruitment_options",
        "recruitment_listbox",
        "recruitment_pool_list",
        "list_clip",
        "list_box")
    local globalRecruitmentUnitCardListUIComponent = find_uicomponent(
        recruitmentUIComponent,
        "global",
        "unit_list",
        "listview",
        "list_clip",
        "list_box")
    local localRecruitmentUnitCardListUIComponent = find_uicomponent(
        recruitmentUIComponent,
        "local1",
        "unit_list",
        "listview",
        "list_clip",
        "list_box")
    displayUnitsArmyCost(globalRecruitmentUnitCardListUIComponent)
    displayUnitsArmyCost(localRecruitmentUnitCardListUIComponent)
end

---Adds listeners for events that will display UI elements and trigger cost verifications.
local function addListeners()
    TotowarCbacManager.logger:logDebug("Listeners subscription: Started")

    core:add_listener(
        "totowar_cbac_recruitment_panel",
        "PanelOpenedCampaign",
        function(context)
            return cm:get_campaign_ui_manager():is_panel_open("recruitment_options");
        end,
        function(context)
            cm:callback(
                function()
                    displayAllUnitsArmyCost()
                end,
                0.01)
        end,
        true
    );

    TotowarCbacManager.logger:logDebug("Listeners subscription: Completed")
end

---Initializes the mod.
function TotowarCbacManager:initialize()
    self.logger = TotowarLogger.new(modName, logFileName, self.isDebug)
    self.logger:logInfo("Mod initialization: Started")

    addListeners()

    self.logger:logInfo("Mod initialization: Completed")
end

core:add_static_object(modName, TotowarCbacManager);
