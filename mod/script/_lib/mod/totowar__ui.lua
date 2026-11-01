local logger = TotoWar__Logger.get(TotoWar__Enum_LogCategories.ui)

---UI utility tools for TotoWar mods.
---@class TotoWarUI
TotoWar__UI = {
    ---Queries for finding UI components.
    ---@class TotoWarUIUtils_UIComponentQuery
    uiComponentQueries = {
        unitExchange_pool1 = { "unit_exchange", "main_units_panel_1" },
        unitExchange_pool2 = { "unit_exchange", "main_units_panel_2" },
        unitsPanel_iconList = { "units_panel", "main_units_panel", "icon_list" },
        unitsPanel_recruitmentOptions_alliedRecruitmentPool = { "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "allied_recuitment_display", "recruitment_holder", "unit_list" },                                 -- The typo in "allied_recuitment_display" is from CA
        unitsPanel_recruitmentOptions_closeButton = { "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "title_docker", "button_holder", "button_minimise" },
        unitsPanel_recruitmentOptions_mercenaryRecruitmentPoolList = { "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "mercenary_display", "mercenary_recruitment_pool_list", "list_clip", "list_box" },
        unitsPanel_recruitmentOptions_standardRecruitmentPoolList = { "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "recruitment_listbox", "recruitment_pool_list", "list_clip", "list_box" },
        unitsPanel_units = { "units_panel", "main_units_panel", "units" },
        unitsPanel_warbandUpgrades = { "units_panel", "main_units_panel", "warband_upgrades_docker", "warband_upgrades" },
        unitsPanel_warbandUpgradesRequirements = { "units_panel", "main_units_panel", "warband_upgrades_docker", "warband_upgrades", "body", "info_holder", "upgrade_info_holder", "unit_info_costs", "holder_requirements", "body" },
        unitsPanel_warbandUpgradesUnitToUpgrade = { "units_panel", "main_units_panel", "warband_upgrades_docker", "warband_upgrades", "body", "info_holder", "upgrade_info_holder", "holder_card_upgrade", "unit_card_upgrade_small", "card_image_holder" },
        unitsPanel_warbandUpgradesUpgradedUnit = { "units_panel", "main_units_panel", "warband_upgrades_docker", "warband_upgrades", "body", "info_holder", "upgrade_info_holder", "holder_card_upgrade", "unit_card_upgrade", "card_image_holder" }
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
    logger:logDebug(
        "findUIComponentChild(%s/%s): STARTED",
        function() return parentUIComponent:Id() end,
        function() return table.concat(query, "/") end)

    local uiComponent = find_uicomponent(parentUIComponent, unpack(query))

    if uiComponent == false then
        logger:logDebug(
            "findUIComponentChild(%s/%s): NOT FOUND",
            function() return parentUIComponent:Id() end,
            function() return table.concat(query, "/") end)

        return nil
    end

    logger:logDebug(
        "findUIComponentChild(%s/%s): COMPLETED => %s",
        function() return parentUIComponent:Id() end,
        function() return table.concat(query, "/") end,
        function() return uiComponent:Id() end)

    return uiComponent
end

---Gets a UI component from the root.
---If the UI component is not found, throws an error.
---@param query string[] Query to the UI component from the root.
---@return UIC
function TotoWar__UI:getUIComponent(query)
    local uiComponent = self:findUIComponent(query)

    if uiComponent == nil then
        logger:logError(
            "Game interface: %s not found, army supplies may not be displayed correctly",
            table.concat(query, "/"))
    end

    ---@diagnostic disable-next-line: return-type-mismatch
    return uiComponent
end

---Gets a context object of a UI component.
---@param uiComponent UIC UI component.
---@param ccoContextTypeId string ID of the context object.
---@return ComponentContextObject
function TotoWar__UI:getUIComponentCCO(uiComponent, ccoContextTypeId)
    logger:logDebug(
        "getUIComponentCCO(%s, %s): STARTED",
        function() return uiComponent:Id() end,
        ccoContextTypeId)

    local contextId = uiComponent:GetContextObjectId(ccoContextTypeId)
    local componentContextObject = cco(ccoContextTypeId, contextId)

    if componentContextObject == nil then
        logger:logDebug(
            "getUIComponentCCO(%s, %s): NOT FOUND",
            function() return uiComponent:Id() end,
            ccoContextTypeId)
    end

    logger:logDebug(
        "getUIComponentCCO(%s, %s): COMPLETED",
        function() return uiComponent:Id() end,
        ccoContextTypeId)

    ---@diagnostic disable-next-line: return-type-mismatch
    return componentContextObject
end

---Gets a UI component that is a child a parent UI component.
---If the child UI component is not found, throws an error.
---@param parentUIComponent UIC Parent UI component
---@param query string[] Query to the UI component from the parent UI component.
---@return UIC
function TotoWar__UI:getUIComponentChild(parentUIComponent, query)
    local uiComponent = self:findUIComponentChild(parentUIComponent, query)

    if uiComponent == nil then
        logger:logError(
            "Game interface: %s/%s not found, army supplies may not be displayed correctly",
            parentUIComponent:Id(),
            table.concat(query, "/"))
    end

    ---@diagnostic disable-next-line: return-type-mismatch
    return uiComponent
end

---Gets the CQI of the character represented by a unit card.
---@param unitCardUIComponent UIC Unit card UI component.
---@return integer | nil # `nil` when the unit card does not represent a character.
function TotoWar__UI:getUnitCardCharacterCqi(unitCardUIComponent)
    local objectContextId = unitCardUIComponent:GetContextObjectId(TotoWar__Enum_CcoContextTypeIds.campaignUnit)

    ---@type integer | nil
    local characterCqi = common.get_context_value(
        TotoWar__Enum_CcoContextTypeIds.campaignUnit,
        objectContextId,
        "CharacterContext.CQI")

    return characterCqi
end

---Gets the key of the unit represented by a unit card.
---@param unitCardUIComponent UIC Unit card UI component.
---@return string
function TotoWar__UI:getUnitCardUnitKey(unitCardUIComponent)
    local cardImageHolderUIComponent = self:getUIComponentChild(unitCardUIComponent, { "card_image_holder" })
    local unitContext = self:getUIComponentCCO(cardImageHolderUIComponent, TotoWar__Enum_CcoContextTypeIds.mainUnitRecord)

    ---@type string
    local unitKey = unitContext:Call("Key")

    return unitKey
end

---Indicates whether a UI component is a child of other UI components.
---@param uiComponent UIC UI component.
---@param parentNames string[] Parent UI component names.
function TotoWar__UI:isUIComponentChildOf(uiComponent, parentNames)
    logger:logDebug(
        "isUIComponentChildOf(%s, %s): STARTED",
        function() return uiComponent:Id() end,
        function() return table.concat(parentNames, ", ") end)

    local isChildOfAll = TotoWar__Linq:all(
        parentNames,
        function(pn)
            return (uicomponent_has_parent_filter(
                uiComponent,
                ---@param uic UIC
                function(uic) return uic:Id() == pn end))
        end)

    logger:logDebug(
        "isUIComponentChildOf(%s, %s): COMPLETED => %s",
        function() return uiComponent:Id() end,
        function() return table.concat(parentNames, ", ") end,
        isChildOfAll)

    return isChildOfAll
end

---Indicates whether a UI component is selected (hovered or not).
---@param uiComponent UIC UI component.
---@return boolean
function TotoWar__UI:isUIComponentSelected(uiComponent)
    return TotoWar__String:startsWith(uiComponent:CurrentState(), TotoWar__Enum_UIComponentStates.selected)
end

---Offsets the children of a UI component.
---@param uiComponent UIC UI component which children must be offset.
---@param offsetX number X offset.
---@param offsetY number Y offset.
function TotoWar__UI:offsetChildUIComponents(uiComponent, offsetX, offsetY)
    logger:logDebug(
        "offsetChildUIComponents(%s, %s, %s): STARTED",
        function() return uiComponent:Id() end,
        offsetX,
        offsetY)

    for i = 0, uiComponent:ChildCount() - 1, 1 do
        local childUIComponent = find_child_uicomponent_by_index(uiComponent, i)
        self:offsetUIComponent(childUIComponent, offsetX, offsetY)
    end

    logger:logDebug(
        "offsetChildUIComponents(%s, %s, %s): COMPLETED",
        function() return uiComponent:Id() end,
        offsetX,
        offsetY)
end

---Offsets the children of a UI component.
---@param uiComponent UIC UI component which children must be offset.
---@param offsetX number X offset.
---@param offsetY number Y offset.
function TotoWar__UI:offsetUIComponent(uiComponent, offsetX, offsetY)
    logger:logDebug(
        "offsetUIComponent(%s, %s, %s): STARTED",
        function() return uiComponent:Id() end,
        offsetX,
        offsetY)

    local uiComponentOffsetX, uiComponentOffsetY = uiComponent:GetDockOffset()
    uiComponent:SetDockOffset(uiComponentOffsetX + offsetX, uiComponentOffsetY + offsetY)

    logger:logDebug(
        "offsetUIComponent(%s, %s, %s): COMPLETED",
        function() return uiComponent:Id() end,
        offsetX,
        offsetY)
end

---Resizes a UI component.
---@param uiComponent UIC UI component.
---@param widthToAdd number Width to add.
---@param heightToAdd number Height to add.
function TotoWar__UI:resizeUIComponent(uiComponent, widthToAdd, heightToAdd)
    logger:logDebug(
        "resizeUIComponent(%s, %s, %s): STARTED",
        function() return uiComponent:Id() end,
        widthToAdd,
        heightToAdd)

    local uiComponentWidth, uiComponentHeight = uiComponent:Dimensions()
    self:setUIComponentSize(uiComponent, uiComponentWidth + widthToAdd, uiComponentHeight + heightToAdd)

    logger:logDebug(
        "resizeUIComponent(%s, %s, %s): COMPLETED",
        function() return uiComponent:Id() end,
        widthToAdd,
        heightToAdd)
end

---Resizes a UI components and its children listed in a path.
---@param uiComponent UIC UI component to resize.
---@param widthToAdd number Width to add.
---@param heightToAdd number Height to add.
---@param query string[] Path containing the names of the child UI components to resize.
function TotoWar__UI:resizeUIComponentAndChildren(uiComponent, widthToAdd, heightToAdd, query)
    logger:logDebug(
        "resizeUIComponentAndChildren(%s, %s, %s, %s): STARTED",
        function() return uiComponent:Id() end,
        widthToAdd,
        heightToAdd,
        function() return table.concat(query, "/") end)

    local currentChildUIComponentPath = {}

    self:resizeUIComponent(uiComponent, widthToAdd, heightToAdd)

    for i, childUIComponentName in ipairs(query) do
        currentChildUIComponentPath[i] = childUIComponentName
        local childUIComponent = find_uicomponent(uiComponent, unpack(currentChildUIComponentPath))
        self:resizeUIComponent(childUIComponent, widthToAdd, heightToAdd)
    end

    logger:logDebug(
        "resizeUIComponentAndChildren(%s, %s, %s, %s): COMPLETED",
        function() return uiComponent:Id() end,
        widthToAdd,
        heightToAdd,
        function() return table.concat(query, "/") end)
end

---Sets the size of a UI component.
---@param uiComponent UIC UI component.
---@param width number Width to add.
---@param height number Height to add.
function TotoWar__UI:setUIComponentSize(uiComponent, width, height)
    logger:logDebug(
        "setUIComponentSize(%s, %s, %s): STARTED",
        function() return uiComponent:Id() end,
        width,
        height)

    uiComponent:SetCanResizeWidth(true)
    uiComponent:SetCanResizeHeight(true)
    uiComponent:Resize(width, height, false)

    logger:logDebug(
        "setUIComponentSize(%s, %s, %s): COMPLETED",
        function() return uiComponent:Id() end,
        width,
        height)
end
