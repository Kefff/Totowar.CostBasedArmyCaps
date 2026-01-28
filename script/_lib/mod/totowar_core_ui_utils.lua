---UI utility tools for TotoWar mods.
---@class TotoWarUIUtils
TotoWarUIUtils = {
    ---Enums.
    ---@class TotoWarUIUtils_Enums
    enums = {
        ---Component context object type IDs.
        ---@class TotoWarUIUtils_Enums_CcoContextTypeIdEnum
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

        ---Events.
        ---@class TotoWarUIUtils_Enums_Event
        event = {
            ---Event triggered when a character is deselected.
            ---Is not triggered when a character is already selected and the player selects another character.
            characterDeselected = "CharacterDeselected",

            ---Event triggered when a character is selected.
            characterSelected = "CharacterSelected",

            ---Event triggered when the left click on a UI component is released.
            componentLeftClick = "ComponentLClickUp",

            ---Event triggered when a panel is opened.
            panelOpened = "PanelOpenedCampaign",

            ---Event triggered when a panel is closed.
            panelClosed = "PanelClosedCampaign",

            ---Event triggered when a unit is removed from the recruitment queue.
            unitRemovedFromRecruitment = "RecruitmentItemCancelledByPlayer",

            ---Event triggered when a unit is added to the recruitment queue.
            unitAddedToRecruitment = "RecruitmentItemIssuedByPlayer",

            ---Event triggered when (a) unit(s) have been disbanded.
            unitDisbanded = "UnitDisbanded",

            ---Event triggered when units are merged unit and some of them have been destroyed.
            unitMergedAndDestroyed = "UnitMergedAndDestroyed",

            ---Event triggered when a unit is added to an army.
            unitTrained = "UnitTrained"
        },

        ---Panels.
        ---@class TotoWarUIUtils_Enums_Panels
        panel = {
            ---Allied recruitment from an allied outpost
            alliedRecruitment = "allied_recruitment",

            ---Mercenary recruitment panel (units of renown, dwarf grudge settlers, Waaagh mobs, ...)
            mercenaryRecruitment = "mercenary_recruitment",

            ---Panel that contains the recruitment panels
            recruitmentOptions = "recruitment_options",

            ---Standard recruitment panel
            standardRecruitment = "units_recruitment",

            ---Selected army unit list panel.
            unitsPanel = "units_panel"
        },

        ---Patterns for finding UI elements.
        ---@class TotoWarUIUtils_Enums_Patterns
        patterns = {
            ---Pattern for identifying a UI component corresponding to the unit card of a recruitable mercenary
            ---unit (regiment of renown, Waaagh mobs, Grudge settlers, ...).
            ---@type string
            inRecruitmentMercenaryUnitCard = "^temp_merc_",

            ---Pattern for identifying a UI component corresponding to the unit card of recruitable standard
            ---unit in the selected army recruitment queue.
            ---@type string
            inRecruitmentStandardUnitCard = "^QueuedLandUnit",

            ---Pattern for identifying a UI component corresponding to the unit card of a mercenary
            ---unit (regiment of renown, Waaagh mobs, Grudge settlers, ...) in the selected army recruitment
            ---queue.
            ---@type string
            recruitableMercenaryUnitCard = "^wh%d*_.*_mercenary$"
        },

        ---UI component states.
        ---@class TotoWarUIUtils_Enums_UIComponentStates
        uiComponentState = {
            active = "active",

            inactive = "inactive"
        }
    },

    ---Logger.
    ---@type TotoWarLogger
    logger = nil,

    ---Queries for finding UI components.
    ---@class TotoWarUIUtils_UIComponentQuery
    uiComponentQueries = {
        alliedRecruitmentPool = { "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "allied_recuitment_display", "recruitment_holder", "unit_list" }, -- The typo in "allied_recuitment_display" is from CA
        globalRecruitmentPool = { "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "recruitment_listbox", "recruitment_pool_list", "list_clip", "list_box", "global", "unit_list" },
        localRecruitmentPool = { "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "recruitment_listbox", "recruitment_pool_list", "list_clip", "list_box", "local1", "unit_list" },
        mercenaryRecruitmentPool = { "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "mercenary_display", "frame" },
        recruitmentPanelCloseButton = { "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "title_docker", "button_holder", "button_minimise" },
        units = { "units_panel", "main_units_panel", "units" },
        unitsPanelIconList = { "units_panel", "main_units_panel", "icon_list" },
    },

}
TotoWarUIUtils.__index = TotoWarUIUtils

---Initializes a new instance.
---@return TotoWarUIUtils
function TotoWarUIUtils.new()
    local instance = setmetatable({}, TotoWarUIUtils)

    instance.logger = TotoWarLogger.new("TotoWar_UIUtils")

    instance.logger:logDebug("new(): COMPLETED")

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
        "findUIComponentChild(%s/%s): STARTED",
        parentUIComponent:Id(),
        queryText)

    local uiComponent = find_uicomponent(parentUIComponent, unpack(query))

    if not uiComponent then
        self.logger:logDebug(
            "findUIComponentChild(%s/%s): NOT FOUND",
            parentUIComponent:Id(),
            queryText)

        return nil
    end

    self.logger:logDebug(
        "findUIComponentChild(%s/%s): COMPLETED",
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
        "getUIComponentCCO(%s, %s): STARTED",
        uiComponent:Id(),
        ccoContextTypeId)

    local contextId = uiComponent:GetContextObjectId(ccoContextTypeId)
    local componentContextObject = cco(ccoContextTypeId, contextId)

    if not componentContextObject then
        self.logger:logDebug(
            "getUIComponentCCO(%s, %s): NOT FOUND",
            uiComponent:Id(),
            ccoContextTypeId)
    end

    self.logger:logDebug(
        "getUIComponentCCO(%s, %s): COMPLETED",
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
        "offsetUIComponent(%s, %s, %s): STARTED",
        uiComponent:Id(),
        offsetX,
        offsetY)

    local uiComponentOffsetX, uiComponentOffsetY = uiComponent:GetDockOffset()
    uiComponent:SetDockOffset(uiComponentOffsetX + offsetX, uiComponentOffsetY + offsetY)

    self.logger:logDebug(
        "offsetUIComponent(%s, %s, %s): COMPLETED",
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
        "offsetChildUIComponents(%s, %s, %s): STARTED",
        uiComponent:Id(),
        offsetX,
        offsetY)

    for i = 0, uiComponent:ChildCount() - 1, 1 do
        local childUIComponent = find_child_uicomponent_by_index(uiComponent, i)
        self:offsetUIComponent(childUIComponent, offsetX, offsetY)
    end

    self.logger:logDebug(
        "offsetChildUIComponents(%s, %s, %s): COMPLETED",
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
        "resizeUIComponent(%s, %s, %s): STARTED",
        uiComponent:Id(),
        widthToAdd,
        heightToAdd)

    local uiComponentWidth, uiComponentHeight = uiComponent:Dimensions()
    uiComponent:SetCanResizeWidth(true)
    uiComponent:SetCanResizeHeight(true)
    uiComponent:Resize(uiComponentWidth + widthToAdd, uiComponentHeight + heightToAdd, false)

    self.logger:logDebug(
        "resizeUIComponent(%s, %s, %s): COMPLETED",
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
        "resizeUIComponentAndChildren(%s, %s, %s): STARTED",
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
        "resizeUIComponentAndChildren(%s, %s, %s): COMPLETED",
        uiComponent:Id(),
        widthToAdd,
        heightToAdd)
end
