local _panelCategories = {
    hasRecruitmentUnitList = "hasRecruitmentUnitList"
}

local _uiComponentQueries = {
    alliedRecruitmentPool = { "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "allied_recruitment_display", "recruitment_holder", "unit_list" },
    globalRecruitmentPool = { "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "recruitment_listbox", "recruitment_pool_list", "list_clip", "list_box", "global", "unit_list" },
    localRecruitmentPool = { "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "recruitment_listbox", "recruitment_pool_list", "list_clip", "list_box", "local1", "unit_list" },
    mercenaryRecruitmentPool = { "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "mercenary_display", "frame" },
    recruitmentOptions = { "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options" },
    unitsPanel = { "units_panel" },
    unitsPanelIconList = { "units_panel", "main_units_panel", "icon_list" }
}

---UI utility tools for TotoWar mods.
---@class TotoWarUIUtils
TotoWarUIUtils = {
    ---Enums.
    enums = {
        ---Component context object type IDs.
        ccoContextTypeId = {
            ccoAgentSubtypeRecord = "ccoAgentSubtypeRecord",
            ccoCampaignCharacter = "CcoCampaignCharacter",
            ccoMainUnitRecord = "CcoMainUnitRecord"
        },

        ---Docking points.
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
    ---@type table<string, TotoWarUIPanelInfo>
    panels = {
        alliedRecruitment = TotoWarUIPanelInfo.new(
            "allied_recruitment",
            { _panelCategories.hasRecruitmentUnitList },
            { _uiComponentQueries.alliedRecruitmentPool }),
        mercenaryRecruitment = TotoWarUIPanelInfo.new(
            "mercenary_recruitment",
            { _panelCategories.hasRecruitmentUnitList },
            { _uiComponentQueries.mercenaryRecruitmentPool }),
        recruitmentOptions = TotoWarUIPanelInfo.new(
            "recruitment_options",
            { _panelCategories.hasRecruitmentUnitList },
            { _uiComponentQueries.recruitmentOptions }),
        unitsRecruitment = TotoWarUIPanelInfo.new(
            "units_recruitment",
            { _panelCategories.hasRecruitmentUnitList },
            {
                _uiComponentQueries.globalRecruitmentPool,
                _uiComponentQueries.localRecruitmentPool
            })
    }
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
    local pathString = table.concat(query, "/")

    self.logger:logDebug(
        "TotoWarUIUtils:findUIComponentChild(%s/%s): STARTED",
        parentUIComponent:Id(),
        pathString)

    local uiComponent = find_uicomponent(parentUIComponent, unpack(query))

    if not uiComponent then
        self.logger:logDebug("Find UI component (%s/%s): NOT FOUND", parentUIComponent:Id(),
            pathString)

        return nil
    end

    self.logger:logDebug(
        "TotoWarUIUtils:findUIComponentChild(%s/%s): COMPLETED",
        parentUIComponent:Id(),
        pathString)

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
---@param ... string Path containing the names of the child UI components to resize.
function TotoWarUIUtils:resizeUIComponentAndChildren(uiComponent, widthToAdd, heightToAdd, ...)
    self.logger:logDebug(
        "TotoWarUIUtils:resizeUIComponentAndChildren(%s, %s, %s): STARTED",
        uiComponent:Id(),
        widthToAdd,
        heightToAdd)

    local childUIComponentsPath = { ... }
    local currentChildUIComponentPath = {}

    self:resizeUIComponent(uiComponent, widthToAdd, heightToAdd)

    for i, childUIComponentName in ipairs(childUIComponentsPath) do
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
