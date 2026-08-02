---UI utility tools for TotoWar mods.
---@class TotoWarUI
TotoWar__UI = {
    ---Queries for finding UI components.
    ---@class TotoWarUIUtils_UIComponentQuery
    uiComponentQueries = {
        unitExchangePool1 = { "unit_exchange", "main_units_panel_1" },
        unitExchangePool2 = { "unit_exchange", "main_units_panel_2" },
        unitPanelRecruitmentOptionsLocalRecruitmentPool = { "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "recruitment_listbox", "recruitment_pool_list", "list_clip", "list_box", "local1", "unit_list" },
        unitsPanelIconList = { "units_panel", "main_units_panel", "icon_list" },
        unitsPanelRecruitmentOptionsAlliedRecruitmentPool = { "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "allied_recuitment_display", "recruitment_holder", "unit_list" }, -- The typo in "allied_recuitment_display" is from CA
        unitsPanelRecruitmentOptionsCloseButton = { "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "title_docker", "button_holder", "button_minimise" },
        unitsPanelRecruitmentOptionsGlobalRecruitmentPool = { "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "recruitment_listbox", "recruitment_pool_list", "list_clip", "list_box", "global", "unit_list" },
        unitsPanelRecruitmentOptionsMercenaryRecruitmentPool = { "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "mercenary_display", "frame" },
        unitsPanelUnits = { "units_panel", "main_units_panel", "units" },
        unitsPanelWarbandUpgrades = { "units_panel", "main_units_panel", "warband_upgrades_docker", "warband_upgrades" },
        unitsPanelWarbandUpgradesRequirements = { "units_panel", "main_units_panel", "warband_upgrades_docker", "warband_upgrades", "body", "info_holder", "upgrade_info_holder", "unit_info_costs", "holder_requirements", "body" },
        unitsPanelWarbandUpgradesUnitToUpgrade = { "units_panel", "main_units_panel", "warband_upgrades_docker", "warband_upgrades", "body", "info_holder", "upgrade_info_holder", "holder_card_upgrade", "unit_card_upgrade_small", "card_image_holder" },
        unitsPanelWarbandUpgradesUpgradedUnit = { "units_panel", "main_units_panel", "warband_upgrades_docker", "warband_upgrades", "body", "info_holder", "upgrade_info_holder", "holder_card_upgrade", "unit_card_upgrade", "card_image_holder" }
    }
}
TotoWar__UI.__index = TotoWar__UI

---Finds a UI component from the root.
---@param query string[] Query to the UI component from the root.
---@return UIC | nil
function TotoWar__UI:findUIComponent(query)
    local childUIComponent = self:findUIComponentChild(core:get_ui_root(), query)

    return childUIComponent
end

---Finds a UI component that is a child a parent UI component.
---@param parentUIComponent UIC Parent UI component
---@param query string[] Query to the UI component from the parent UI component.
---@return UIC | nil
function TotoWar__UI:findUIComponentChild(parentUIComponent, query)
    local queryText = table.concat(query, "/")

    TotoWar.loggers.uiUtils:logDebug(
        "findUIComponentChild(%s/%s): STARTED",
        function() return parentUIComponent:Id() end,
        function() return queryText end)

    local uiComponent = find_uicomponent(parentUIComponent, unpack(query))

    if not uiComponent then
        TotoWar.loggers.uiUtils:logDebug(
            "findUIComponentChild(%s/%s): NOT FOUND",
            function() return parentUIComponent:Id() end,
            function() return queryText end)

        return nil
    end

    TotoWar.loggers.uiUtils:logDebug(
        "findUIComponentChild(%s/%s): COMPLETED => %s",
        function() return parentUIComponent:Id() end,
        function() return queryText end,
        function() return uiComponent:Id() end)

    return uiComponent
end

---Gets a UI component from the root.
---If the UI component is not found, throws an error.
---@param query string[] Query to the UI component from the root.
---@return UIC
function TotoWar__UI:getUIComponent(query)
    local uiComponent = self:findUIComponent(query)

    if not uiComponent then
        TotoWar.loggers.uiUtils:logError("UI component \"%s\" not found", table.concat(query, "/"))
    end

    ---@diagnostic disable-next-line: return-type-mismatch
    return uiComponent
end

---Gets a UI component that is a child a parent UI component.
---If the child UI component is not found, throws an error.
---@param parentUIComponent UIC Parent UI component
---@param query string[] Query to the UI component from the parent UI component.
---@return UIC
function TotoWar__UI:getUIComponentChild(parentUIComponent, query)
    local uiComponent = self:findUIComponentChild(parentUIComponent, query)

    if uiComponent == nil then
        TotoWar.loggers.uiUtils:logError("UI component \"%s\" not found", table.concat(query, "/"))
    end

    ---@diagnostic disable-next-line: return-type-mismatch
    return uiComponent
end

---Gets a context object of a UI component.
---@param uiComponent UIC UI component.
---@param ccoContextTypeId string ID of the context object.
---@return ComponentContextObject
function TotoWar__UI:getUIComponentCCO(uiComponent, ccoContextTypeId)
    TotoWar.loggers.uiUtils:logDebug(
        "getUIComponentCCO(%s, %s): STARTED",
        function() return uiComponent:Id() end,
        function() return ccoContextTypeId end)

    local contextId = uiComponent:GetContextObjectId(ccoContextTypeId)
    local componentContextObject = cco(ccoContextTypeId, contextId)

    if not componentContextObject then
        TotoWar.loggers.uiUtils:logDebug(
            "getUIComponentCCO(%s, %s): NOT FOUND",
            function() return uiComponent:Id() end,
            function() return ccoContextTypeId end)
    end

    TotoWar.loggers.uiUtils:logDebug(
        "getUIComponentCCO(%s, %s): COMPLETED",
        function() return uiComponent:Id() end,
        function() return ccoContextTypeId end)

    return componentContextObject
end

---Indicates whether a UI component is a child of other UI components.
---@param uiComponent UIC UI component.
---@param parentNames string[] Parent UI component names.
function TotoWar__UI:isUIComponentChildOf(uiComponent, parentNames)
    local parentNamesText = table.concat(parentNames, ", ")

    TotoWar.loggers.uiUtils:logDebug(
        "isUIComponentChildOf(%s, %s): STARTED",
        function() return uiComponent:Id() end,
        function() return parentNamesText end)

    local hasParent = TotoWar__Linq:any(
        parentNames,
        function(pn)
            return (uicomponent_has_parent_filter(
                uiComponent,
                ---@param uic UIC
                function(uic) return uic:Id() == pn end))
        end)

    TotoWar.loggers.uiUtils:logDebug(
        "isUIComponentChildOf(%s, %s): COMPETED => %s",
        function() return uiComponent:Id() end,
        function() return parentNamesText end,
        function() return hasParent end)

    return hasParent
end

---Offsets the children of a UI component.
---@param uiComponent UIC UI component which children must be offset.
---@param offsetX number X offset.
---@param offsetY number Y offset.
function TotoWar__UI:offsetUIComponent(uiComponent, offsetX, offsetY)
    TotoWar.loggers.uiUtils:logDebug(
        "offsetUIComponent(%s, %s, %s): STARTED",
        function() return uiComponent:Id() end,
        function() return offsetX end,
        function() return offsetY end)

    local uiComponentOffsetX, uiComponentOffsetY = uiComponent:GetDockOffset()
    uiComponent:SetDockOffset(uiComponentOffsetX + offsetX, uiComponentOffsetY + offsetY)

    TotoWar.loggers.uiUtils:logDebug(
        "offsetUIComponent(%s, %s, %s): COMPLETED",
        function() return uiComponent:Id() end,
        function() return offsetX end,
        function() return offsetY end)
end

---Offsets the children of a UI component.
---@param uiComponent UIC UI component which children must be offset.
---@param offsetX number X offset.
---@param offsetY number Y offset.
function TotoWar__UI:offsetChildUIComponents(uiComponent, offsetX, offsetY)
    TotoWar.loggers.uiUtils:logDebug(
        "offsetChildUIComponents(%s, %s, %s): STARTED",
        function() return uiComponent:Id() end,
        function() return offsetX end,
        function() return offsetY end)

    for i = 0, uiComponent:ChildCount() - 1, 1 do
        local childUIComponent = find_child_uicomponent_by_index(uiComponent, i)
        self:offsetUIComponent(childUIComponent, offsetX, offsetY)
    end

    TotoWar.loggers.uiUtils:logDebug(
        "offsetChildUIComponents(%s, %s, %s): COMPLETED",
        function() return uiComponent:Id() end,
        function() return offsetX end,
        function() return offsetY end)
end

---Resizes a UI component.
---@param uiComponent UIC UI component.
---@param widthToAdd number Width to add.
---@param heightToAdd number Height to add.
function TotoWar__UI:resizeUIComponent(uiComponent, widthToAdd, heightToAdd)
    TotoWar.loggers.uiUtils:logDebug(
        "resizeUIComponent(%s, %s, %s): STARTED",
        function() return uiComponent:Id() end,
        function() return widthToAdd end,
        function() return heightToAdd end)

    local uiComponentWidth, uiComponentHeight = uiComponent:Dimensions()
    uiComponent:SetCanResizeWidth(true)
    uiComponent:SetCanResizeHeight(true)
    uiComponent:Resize(uiComponentWidth + widthToAdd, uiComponentHeight + heightToAdd, false)

    TotoWar.loggers.uiUtils:logDebug(
        "resizeUIComponent(%s, %s, %s): COMPLETED",
        function() return uiComponent:Id() end,
        function() return widthToAdd end,
        function() return heightToAdd end)
end

---Resizes a UI components and its children listed in a path.
---@param uiComponent UIC UI component to resize.
---@param widthToAdd number Width to add.
---@param heightToAdd number Height to add.
---@param query string[] Path containing the names of the child UI components to resize.
function TotoWar__UI:resizeUIComponentAndChildren(uiComponent, widthToAdd, heightToAdd, query)
    TotoWar.loggers.uiUtils:logDebug(
        "resizeUIComponentAndChildren(%s, %s, %s, %s): STARTED",
        function() return uiComponent:Id() end,
        function() return widthToAdd end,
        function() return heightToAdd end,
        function() return table.concat(query, "/") end)

    local currentChildUIComponentPath = {}

    self:resizeUIComponent(uiComponent, widthToAdd, heightToAdd)

    for i, childUIComponentName in ipairs(query) do
        currentChildUIComponentPath[i] = childUIComponentName
        local childUIComponent = find_uicomponent(uiComponent, unpack(currentChildUIComponentPath))
        self:resizeUIComponent(childUIComponent, widthToAdd, heightToAdd)
    end

    TotoWar.loggers.uiUtils:logDebug(
        "resizeUIComponentAndChildren(%s, %s, %s, %s): COMPLETED",
        function() return uiComponent:Id() end,
        function() return widthToAdd end,
        function() return heightToAdd end,
        function() return table.concat(query, "/") end)
end
