local logger = TotoWar__Logger.get(TotoWar__Enum_LogCategories.ui)

---UI utility tools for TotoWar mods.
---@class TotoWarUI
TotoWar__UI = {
    ---Queries for finding UI components: names of the UI components from the root, separated by "/".
    ---@class TotoWarUIUtils_UIComponentQuery
    uiComponentQueries = {
        unitExchange_pool1 = "unit_exchange/main_units_panel_1",
        unitExchange_pool2 = "unit_exchange/main_units_panel_2",
        unitsPanel_iconList = "units_panel/main_units_panel/icon_list",
        unitsPanel_recruitmentOptions_alliedRecruitmentDisplay = "units_panel/main_units_panel/recruitment_docker/recruitment_options/allied_recuitment_display", -- The typo in "allied_recuitment_display" is from CA
        unitsPanel_recruitmentOptions_mercenaryRecruitmentPoolList = "units_panel/main_units_panel/recruitment_docker/recruitment_options/mercenary_display/mercenary_recruitment_pool_list/list_clip/list_box",
        unitsPanel_recruitmentOptions_standardRecruitmentPoolList = "units_panel/main_units_panel/recruitment_docker/recruitment_options/recruitment_listbox/recruitment_pool_list/list_clip/list_box",
        unitsPanel_units = "units_panel/main_units_panel/units",
        unitsPanel_warbandUpgrades = "units_panel/main_units_panel/warband_upgrades_docker/warband_upgrades",
        unitsPanel_warbandUpgradesRequirements = "units_panel/main_units_panel/warband_upgrades_docker/warband_upgrades/body/info_holder/upgrade_info_holder/unit_info_costs/holder_requirements/body",
        unitsPanel_warbandUpgradesRequirementsHolder = "units_panel/main_units_panel/warband_upgrades_docker/warband_upgrades/body/info_holder/upgrade_info_holder/unit_info_costs/holder_requirements",
        unitsPanel_warbandUpgradesUnitToUpgrade = "units_panel/main_units_panel/warband_upgrades_docker/warband_upgrades/body/info_holder/upgrade_info_holder/holder_card_upgrade/unit_card_upgrade_small/card_image_holder",
        unitsPanel_warbandUpgradesUpgradedUnit = "units_panel/main_units_panel/warband_upgrades_docker/warband_upgrades/body/info_holder/upgrade_info_holder/holder_card_upgrade/unit_card_upgrade/card_image_holder"
    }
}
TotoWar__UI.__index = TotoWar__UI

---Finds a UI component from the root.
---@param query string Query to the UI component from the root: names of the UI components separated by "/".
---@return UIC | nil
function TotoWar__UI:findUIComponent(query)
    logger:logDebug("findUIComponent(%s): STARTED", query)

    local childUIComponent = self:findUIComponentChild(core:get_ui_root(), query)

    logger:logDebug(
        "findUIComponent(%s): COMPLETED => Found: %s",
        query,
        childUIComponent ~= nil)

    return childUIComponent
end

---Finds a UI component that is a child a parent UI component.
---@param parentUIComponent UIC Parent UI component
---@param query string Query to the UI component from the parent UI component: names of the UI components separated by "/".
---@return UIC | nil
function TotoWar__UI:findUIComponentChild(parentUIComponent, query)
    logger:logDebug(
        "findUIComponentChild(%s, %s): STARTED",
        function() return parentUIComponent:Id() end,
        query)

    local uiComponent = find_uicomponent(parentUIComponent, unpack(TotoWar__String:split(query, "/")))

    if uiComponent == false then
        logger:logDebug(
            "findUIComponentChild(%s, %s): COMPLETED => Not found",
            function() return parentUIComponent:Id() end,
            query)

        return nil
    end

    logger:logDebug(
        "findUIComponentChild(%s, %s): COMPLETED => Found: %s",
        function() return parentUIComponent:Id() end,
        query,
        function() return uiComponent:Id() end)

    return uiComponent
end

---Gets a UI component from the root.
---If the UI component is not found, throws an error.
---@param query string Query to the UI component from the root: names of the UI components separated by "/".
---@return UIC
function TotoWar__UI:getUIComponent(query)
    logger:logDebug("getUIComponent(%s): STARTED", query)

    local uiComponent = self:findUIComponent(query)

    if uiComponent == nil then
        logger:logError(
            "Game interface: %s not found, army supplies may not be displayed correctly",
            query)
    end

    logger:logDebug(
        "getUIComponent(%s): COMPLETED => Found: %s",
        query,
        uiComponent ~= nil)

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
---@param query string Query to the UI component from the parent UI component: names of the UI components separated by "/".
---@return UIC
function TotoWar__UI:getUIComponentChild(parentUIComponent, query)
    logger:logDebug(
        "getUIComponentChild(%s, %s): STARTED",
        function() return parentUIComponent:Id() end,
        query)

    local uiComponent = self:findUIComponentChild(parentUIComponent, query)

    if uiComponent == nil then
        logger:logError(
            "Game interface: %s/%s not found, army supplies may not be displayed correctly",
            parentUIComponent:Id(),
            query)
    end

    logger:logDebug(
        "getUIComponentChild(%s, %s): COMPLETED => Found: %s",
        function() return parentUIComponent:Id() end,
        query,
        uiComponent ~= nil)

    ---@diagnostic disable-next-line: return-type-mismatch
    return uiComponent
end

---Gets the CQI of the character represented by a unit card.
---@param unitCardUIComponent UIC Unit card UI component.
---@return integer | nil # `nil` when the unit card does not represent a character.
function TotoWar__UI:getUnitCardCharacterCqi(unitCardUIComponent)
    logger:logDebug(
        "getUnitCardCharacterCqi(%s): STARTED",
        function() return unitCardUIComponent:Id() end)

    local objectContextId = unitCardUIComponent:GetContextObjectId(TotoWar__Enum_CcoContextTypeIds.campaignUnit)

    ---@type integer | nil
    local characterCqi = common.get_context_value(
        TotoWar__Enum_CcoContextTypeIds.campaignUnit,
        objectContextId,
        "CharacterContext.CQI")

    logger:logDebug(
        "getUnitCardCharacterCqi(%s): COMPLETED => %s",
        function() return unitCardUIComponent:Id() end,
        characterCqi)

    return characterCqi
end

---Gets the key of the unit represented by a unit card.
---@param unitCardUIComponent UIC Unit card UI component.
---@return string
function TotoWar__UI:getUnitCardUnitKey(unitCardUIComponent)
    logger:logDebug(
        "getUnitCardUnitKey(%s): STARTED",
        function() return unitCardUIComponent:Id() end)

    local cardImageHolderUIComponent = self:getUIComponentChild(unitCardUIComponent, "card_image_holder")
    local unitContext = self:getUIComponentCCO(cardImageHolderUIComponent, TotoWar__Enum_CcoContextTypeIds.mainUnitRecord)

    ---@type string
    local unitKey = unitContext:Call("Key")

    logger:logDebug(
        "getUnitCardUnitKey(%s): COMPLETED => %s",
        function() return unitCardUIComponent:Id() end,
        unitKey)

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
    logger:logDebug(
        "isUIComponentSelected(%s): STARTED",
        function() return uiComponent:Id() end)

    local isSelected = TotoWar__String:startsWith(uiComponent:CurrentState(), TotoWar__Enum_UIComponentStates.selected)

    logger:logDebug(
        "isUIComponentSelected(%s): COMPLETED => %s",
        function() return uiComponent:Id() end,
        isSelected)

    return isSelected
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

---Resizes, with `TotoWar__UI:resizeUIComponentOnce`, each child UI component along a query, without the parent UI component.
---@param parentUIComponent UIC Parent UI component.
---@param query string Query to the last child UI component to resize: names of the UI components separated by "/".
---@param widthToAdd number Width to add.
---@param heightToAdd number Height to add.
---@param sizePropertyName string Name of the property that stores the size reached (one per mod to avoid conflicts).
function TotoWar__UI:resizeUIComponentChildrenOnce(parentUIComponent, query, widthToAdd, heightToAdd, sizePropertyName)
    logger:logDebug(
        "resizeUIComponentChildrenOnce(%s, %s, %s, %s, %s): STARTED",
        function() return parentUIComponent:Id() end,
        query,
        widthToAdd,
        heightToAdd,
        sizePropertyName)

    local childUIComponentQuery = nil

    for index, childUIComponentName in ipairs(TotoWar__String:split(query, "/")) do
        childUIComponentQuery = childUIComponentQuery == nil
            and childUIComponentName
            or childUIComponentQuery .. "/" .. childUIComponentName

        self:resizeUIComponentOnce(
            self:getUIComponentChild(parentUIComponent, childUIComponentQuery),
            widthToAdd,
            heightToAdd,
            sizePropertyName)
    end

    logger:logDebug(
        "resizeUIComponentChildrenOnce(%s, %s, %s, %s, %s): COMPLETED",
        function() return parentUIComponent:Id() end,
        query,
        widthToAdd,
        heightToAdd,
        sizePropertyName)
end

---Resizes a UI component, unless it already has the size it reached the last time it was resized by this function.
---This size is stored in a property of the UI component: the UI component is resized again when the game recreates it or changes its size.
---@param uiComponent UIC UI component.
---@param widthToAdd number Width to add.
---@param heightToAdd number Height to add.
---@param sizePropertyName string Name of the property that stores the size reached (one per mod to avoid conflicts).
---@return boolean # `true` when the UI component has been resized.
function TotoWar__UI:resizeUIComponentOnce(uiComponent, widthToAdd, heightToAdd, sizePropertyName)
    logger:logDebug(
        "resizeUIComponentOnce(%s, %s, %s, %s): STARTED",
        function() return uiComponent:Id() end,
        widthToAdd,
        heightToAdd,
        sizePropertyName)

    local width, height = uiComponent:Dimensions()

    if tostring(uiComponent:GetProperty(sizePropertyName)) == string.format("%sx%s", width, height) then
        logger:logDebug(
            "resizeUIComponentOnce(%s, %s, %s, %s): COMPLETED => Already resized (%sx%s)",
            function() return uiComponent:Id() end,
            widthToAdd,
            heightToAdd,
            sizePropertyName,
            width,
            height)

        return false
    end

    self:resizeUIComponent(uiComponent, widthToAdd, heightToAdd)

    width, height = uiComponent:Dimensions()
    uiComponent:SetProperty(sizePropertyName, string.format("%sx%s", width, height))

    logger:logDebug(
        "resizeUIComponentOnce(%s, %s, %s, %s): COMPLETED => Resized (%sx%s)",
        function() return uiComponent:Id() end,
        widthToAdd,
        heightToAdd,
        sizePropertyName,
        width,
        height)

    return true
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
