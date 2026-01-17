---@class TotoWarUIUtils_PanelCategory
local _panelCategories = {
    hasRecruitmentUnitCards = "hasRecruitmentUnitCards"
}

---@class TotoWarUIUtils_UIComponentQuery
local _uiComponentQueries = {
    alliedRecruitmentPool = { "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "allied_recuitment_display", "recruitment_holder", "unit_list" }, -- The typo in "allied_recuitment_display" is from CA
    globalRecruitmentPool = { "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "recruitment_listbox", "recruitment_pool_list", "list_clip", "list_box", "global", "unit_list" },
    localRecruitmentPool = { "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "recruitment_listbox", "recruitment_pool_list", "list_clip", "list_box", "local1", "unit_list" },
    mercenaryRecruitmentPool = { "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "mercenary_display", "frame" },
    recruitmentPanelCloseButton = { "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "title_docker", "button_holder", "button_minimise" },
    units = { "units_panel", "main_units_panel", "units" },
    unitsPanelIconList = { "units_panel", "main_units_panel", "icon_list" },
}

---UI utility tools for TotoWar mods.
---@class TotoWarUIUtils
TotoWarUIUtils = {
    ---Enums.
    enums = {
        ---Component context object type IDs.
        ---@class TotoWarUIUtils_CcoContextTypeIdEnum
        ccoContextTypeId = {
            ccoAgentSubtypeRecord = "ccoAgentSubtypeRecord",
            ccoCampaignCharacter = "CcoCampaignCharacter",
            ccoMainUnitRecord = "CcoMainUnitRecord"
        },

        ---Docking points.
        ---@class TotoWarUIUtils_DockingPoint
        dockingPoint = {
            topLeft = 1,
            topMiddle = 2,
            topRight = 3,
            middleLeft = 4,
            center = 5,
            middleRight = 6,
            bottomLeft = 7,
            bottomMiddle = 8,
            bottomRight = 9
        },

        --Categories indicating the purpose of the panel.
        panelCategory = _panelCategories,

        ---Queries for finding UI components.
        uiComponentQuery = _uiComponentQueries
    },

    ---Logger.
    ---@type TotoWarLogger
    logger = nil,

    --Panels.
    ---@class TotoWarUIUtils_Panels
    panels = {
        ---Allied recruitment from an allied outpost
        alliedRecruitment = TotoWarUIPanelInfo.new(
            "allied_recruitment",
            { _panelCategories.hasRecruitmentUnitCards }),

        ---Mercenary recruitment panel (units of renown, dwarf grudge settlers, ...)
        mercenaryRecruitment = TotoWarUIPanelInfo.new(
            "mercenary_recruitment",
            { _panelCategories.hasRecruitmentUnitCards }),

        ---Panel that contains the recruitment panels
        recruitmentOptions = TotoWarUIPanelInfo.new(
            "recruitment_options",
            {}),

        ---Standard recruitment panel
        standardUnitsRecruitment = TotoWarUIPanelInfo.new(
            "units_recruitment",
            { _panelCategories.hasRecruitmentUnitCards })
    },

    ---Queries for finding UI components.
    uiComponentQuery = _uiComponentQueries
}
TotoWarUIUtils.__index = TotoWarUIUtils

---Initializes a new instance.
---@return TotoWarUIUtils
function TotoWarUIUtils.new()
    local instance = setmetatable({}, TotoWarUIUtils)

    instance.logger = TotoWarLogger.new("totowar_ui_utils")

    instance.logger:logDebug("TotoWarUIUtils.new(): COMPLETED")

    return instance
end

---Finds a UI component from the root.
---@param query string[] Query to the UI component from the root.
---@return UIC | nil
function TotoWarUIUtils:findUIComponent(query)
    local childUIComponent = self:findUIComponentChild(core:get_ui_root(), query)

    return childUIComponent
end

---Finds a UI component that is a child a parent UI component.
---@param parentUIComponent UIC Parent UI component
---@param query string[] Query to the UI component from the parent UI component.
---@return UIC | nil
function TotoWarUIUtils:findUIComponentChild(parentUIComponent, query)
    local queryText = table.concat(query, "/")

    self.logger:logDebug(
        "TotoWarUIUtils:findUIComponentChild(%s/%s): STARTED",
        parentUIComponent:Id(),
        queryText)

    local uiComponent = find_uicomponent(parentUIComponent, unpack(query))

    if not uiComponent then
        self.logger:logDebug(
            "Find UI component (%s/%s): NOT FOUND",
            parentUIComponent:Id(),
            queryText)

        return nil
    end

    self.logger:logDebug(
        "TotoWarUIUtils:findUIComponentChild(%s/%s): COMPLETED",
        parentUIComponent:Id(),
        queryText)

    return uiComponent
end

---Gets a UI component from the root.
---If the UI component is not found, throws an error.
---@param query string[] Query to the UI component from the root.
---@return UIC
function TotoWarUIUtils:getUIComponent(query)
    local uiComponent = self:findUIComponent(query)

    if not uiComponent then
        self.logger:logError("Cannot find UI component %s", table.concat(query, "/"))
    end

    ---@diagnostic disable-next-line: return-type-mismatch
    return uiComponent
end

---Gets a UI component that is a child a parent UI component.
---If the child UI component is not found, throws an error.
---@param parentUIComponent UIC Parent UI component
---@param query string[] Query to the UI component from the parent UI component.
---@return UIC
function TotoWarUIUtils:getUIComponentChild(parentUIComponent, query)
    local uiComponent = self:findUIComponentChild(parentUIComponent, query)

    if not uiComponent then
        self.logger:logError("Cannot find UI component %s", table.concat(query, "/"))
    end

    ---@diagnostic disable-next-line: return-type-mismatch
    return uiComponent
end

---Gets a context object of a UI component.
---@param uiComponent UIC UI component.
---@param ccoContextTypeId string ID of the context object.
---@return ComponentContextObject
function TotoWarUIUtils:getUIComponentCCO(uiComponent, ccoContextTypeId)
    self.logger:logDebug(
        "TotoWarUIUtils:getUIComponentCCO(%s, %s): STARTED",
        uiComponent:Id(),
        ccoContextTypeId)

    local contextId = uiComponent:GetContextObjectId(ccoContextTypeId)
    local componentContextObject = cco(ccoContextTypeId, contextId)

    if not componentContextObject then
        self.logger:logDebug(
            "TotoWarUIUtils:getUIComponentCCO(%s, %s): NOT FOUND",
            uiComponent:Id(),
            ccoContextTypeId)
    end

    self.logger:logDebug(
        "TotoWarUIUtils:getUIComponentCCO(%s, %s): COMPLETED",
        uiComponent:Id(),
        ccoContextTypeId)

    return componentContextObject
end

---Offsets the children of a UI component.
---@param uiComponent UIC UI component which children must be offset.
---@param offsetX number X offset.
---@param offsetY number Y offset.
function TotoWarUIUtils:offsetUIComponent(uiComponent, offsetX, offsetY)
    self.logger:logDebug(
        "TotoWarUIUtils:offsetUIComponent(%s, %s, %s): STARTED",
        uiComponent:Id(),
        offsetX,
        offsetY)

    local uiComponentOffsetX, uiComponentOffsetY = uiComponent:GetDockOffset()
    uiComponent:SetDockOffset(uiComponentOffsetX + offsetX, uiComponentOffsetY + offsetY)

    self.logger:logDebug(
        "TotoWarUIUtils:offsetUIComponent(%s, %s, %s): COMPLETED",
        uiComponent:Id(),
        offsetX,
        offsetY)
end

---Offsets the children of a UI component.
---@param uiComponent UIC UI component which children must be offset.
---@param offsetX number X offset.
---@param offsetY number Y offset.
function TotoWarUIUtils:offsetChildUIComponents(uiComponent, offsetX, offsetY)
    self.logger:logDebug(
        "TotoWarUIUtils:offsetChildUIComponents(%s, %s, %s): STARTED",
        uiComponent:Id(),
        offsetX,
        offsetY)

    for i = 0, uiComponent:ChildCount() - 1, 1 do
        local childUIComponent = find_child_uicomponent_by_index(uiComponent, i)
        self:offsetUIComponent(childUIComponent, offsetX, offsetY)
    end

    self.logger:logDebug(
        "TotoWarUIUtils:offsetChildUIComponents(%s, %s, %s): COMPLETED",
        uiComponent:Id(),
        offsetX,
        offsetY)
end

---Resizes a UI component.
---@param uiComponent UIC UI component.
---@param widthToAdd number Width to add.
---@param heightToAdd number Height to add.
function TotoWarUIUtils:resizeUIComponent(uiComponent, widthToAdd, heightToAdd)
    self.logger:logDebug(
        "TotoWarUIUtils:resizeUIComponent(%s, %s, %s): STARTED",
        uiComponent:Id(),
        widthToAdd,
        heightToAdd)

    local uiComponentWidth, uiComponentHeight = uiComponent:Dimensions()
    uiComponent:SetCanResizeWidth(true)
    uiComponent:SetCanResizeHeight(true)
    uiComponent:Resize(uiComponentWidth + widthToAdd, uiComponentHeight + heightToAdd, false)

    self.logger:logDebug(
        "TotoWarUIUtils:resizeUIComponent(%s, %s, %s): COMPLETED",
        uiComponent:Id(),
        widthToAdd,
        heightToAdd)
end

---A UI components and its children listed in a path.
---@param uiComponent UIC UI component to resize.
---@param widthToAdd number Width to add.
---@param heightToAdd number Height to add.
---@param query string[] Path containing the names of the child UI components to resize.
function TotoWarUIUtils:resizeUIComponentAndChildren(uiComponent, widthToAdd, heightToAdd, query)
    self.logger:logDebug(
        "TotoWarUIUtils:resizeUIComponentAndChildren(%s, %s, %s): STARTED",
        uiComponent:Id(),
        widthToAdd,
        heightToAdd)

    local currentChildUIComponentPath = {}

    self:resizeUIComponent(uiComponent, widthToAdd, heightToAdd)

    for i, childUIComponentName in ipairs(query) do
        currentChildUIComponentPath[i] = childUIComponentName
        local childUIComponent = find_uicomponent(uiComponent, unpack(currentChildUIComponentPath))
        self:resizeUIComponent(childUIComponent, widthToAdd, heightToAdd)
    end

    self.logger:logDebug(
        "TotoWarUIUtils:resizeUIComponentAndChildren(%s, %s, %s): COMPLETED",
        uiComponent:Id(),
        widthToAdd,
        heightToAdd)
end
