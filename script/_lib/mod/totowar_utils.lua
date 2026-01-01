---UI utility tools for Totowar mods.
---@class UI
local UI = {}

---Utility tools for Totowar mods.
---@class TotowarUtils
TotoWarUtils = {
    ---Indicates whether debug messages are logged.
    ---@type boolean
    isDebug = false,

    ---Delay before triggering the callback of an event.
    ---@type number
    eventCallbackTriggerDelay = 0.1,

    ---Enumerations
    Enums = {
        ---Component context object type IDs.
        CcoContextTypeId = {
            ccoCampaignCharacter = "CcoCampaignCharacter",
            ccoMainUnitRecord = "CcoMainUnitRecord"
        },
        ---Docking points.
        DockingPoint = {
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
        Event = {
            characterSelected = "CharacterSelected",
            panelOpenedCampaign = "PanelOpenedCampaign",
        }
    },

    ---Player faction name.
    ---@type string
    playerFactionName = nil,

    ---UI utility tools.
    ---@class UI
    UI = UI
}

---Indicates whether a faction is the faction of the player.
---@param factionName string name.
---@return boolean
function TotoWarUtils:isPlayerFaction(factionName)
    TotowarLogger:logDebug("Is player faction (\"%s\"): Completed", factionName)

    if TotoWarUtils.playerFactionName == nil then
        TotoWarUtils.playerFactionName = cm:get_local_faction_name()
    end

    isPlayerFaction = factionName == TotoWarUtils.playerFactionName

    TotowarLogger:logDebug("Is player faction (\"%s\", %s): Started", factionName, isPlayerFaction)

    return isPlayerFaction
end

---Gets a context object of a UI component.
---@param uiComponent UIC UI component.
---@param ccoContextTypeId string ID of the context object.
---@return ComponentContextObject
function UI:getComponentContextObject(uiComponent, ccoContextTypeId)
    TotowarLogger:logDebug("Get component context object (\"%s\", \"%s\"): Started", uiComponent:Id(), ccoContextTypeId)

    local contextId = uiComponent:GetContextObjectId(ccoContextTypeId)
    local componentContextObject = cco(ccoContextTypeId, contextId)

    TotowarLogger:logDebug("Get component context object (\"%s\", \"%s\"): Completed", uiComponent:Id(), ccoContextTypeId)

    return componentContextObject
end

---Gets the global recruitment pool UI component.
---@return UIC
function UI:getGlobalRecruitmentPoolUIComponent()
    TotowarLogger:logDebug("Get global recruitment pool UI component: Started")

    local globalRecruitmentUIComponent = find_uicomponent(
        core:get_ui_root(),
        "units_panel",
        "main_units_panel",
        "recruitment_docker",
        "recruitment_options",
        "recruitment_listbox",
        "recruitment_pool_list",
        "list_clip",
        "list_box",
        "global")

    TotowarLogger:logDebug("Get global recruitment pool UI component: Completed")

    return globalRecruitmentUIComponent
end

---Gets the local recruitment pool UI component.
---@return UIC
function UI:getLocalRecruitmentPoolUIComponent()
    TotowarLogger:logDebug("Get local recruitment pool UI component: Started")

    local localRecruitmentUIComponent = find_uicomponent(
        core:get_ui_root(),
        "units_panel",
        "main_units_panel",
        "recruitment_docker",
        "recruitment_options",
        "recruitment_listbox",
        "recruitment_pool_list",
        "list_clip",
        "list_box",
        "local1")

    TotowarLogger:logDebug("Get local recruitment pool UI component: Completed")

    return localRecruitmentUIComponent
end

---Gets the UI component for the list of icons of the units panel.
---@return UIC
function UI:getUnitsPanelIconListUIComponent()
    TotowarLogger:logDebug("Get units panel icon list UI component: Started")

    local unitsPanelIconList = find_uicomponent(
        core:get_ui_root(),
        "units_panel",
        "main_units_panel",
        "icon_list")

    TotowarLogger:logDebug("Get units panel icon list UI component: Completed")

    return unitsPanelIconList
end

---Offsets the children of a UI component.
---@param uiComponent UIC UI component which children must be offset.
---@param offsetX number X offset.
---@param offsetY number Y offset.
function UI:offsetUIComponent(uiComponent, offsetX, offsetY)
    TotowarLogger:logDebug("Offset UI components (\"%s\"): Started", uiComponent:Id())

    local uiComponentOffsetX, uiComponentOffsetY = uiComponent:GetDockOffset()
    uiComponent:SetDockOffset(uiComponentOffsetX + offsetX, uiComponentOffsetY + offsetY)

    TotowarLogger:logDebug("Offset UI components (\"%s\"): Completed", uiComponent:Id())
end

---Offsets the children of a UI component.
---@param uiComponent UIC UI component which children must be offset.
---@param offsetX number X offset.
---@param offsetY number Y offset.
function UI:offsetChildUIComponents(uiComponent, offsetX, offsetY)
    TotowarLogger:logDebug("Offset child UI components (\"%s\"): Started", uiComponent:Id())

    for i = 0, uiComponent:ChildCount() - 1, 1 do
        local childUIComponent = find_child_uicomponent_by_index(uiComponent, i)
        UI:offsetUIComponent(childUIComponent, offsetX, offsetY)
    end

    TotowarLogger:logDebug("Offset child UI components (\"%s\"): Completed", uiComponent:Id())
end

---Resizes a UI component.
---@param uiComponent UIC UI component.
---@param widthToAdd number Width to add.
---@param heightToAdd number Height to add.
function UI:resizeUIComponent(uiComponent, widthToAdd, heightToAdd)
    TotowarLogger:logDebug("Resize UI component (\"%s\"): Started", uiComponent:Id())

    local uiComponentWidth, uiComponentHeight = uiComponent:Dimensions()
    uiComponent:SetCanResizeWidth(true)
    uiComponent:SetCanResizeHeight(true)
    uiComponent:Resize(uiComponentWidth + widthToAdd, uiComponentHeight + heightToAdd, false)

    TotowarLogger:logDebug("Resize UI component (\"%s\"): Completed", uiComponent:Id())
end

---A UI components and its children listed in a path.
---@param uiComponent UIC UI component to resize.
---@param widthToAdd number Width to add.
---@param heightToAdd number Height to add.
---@param ... string Path containing the names of the child UI components to resize.
function UI:resizeUIComponentAndChildren(uiComponent, widthToAdd, heightToAdd, ...)
    TotowarLogger:logDebug("Resize UI component and children (\"%s\"): Started", uiComponent:Id())

    local childUIComponentsPath = { ... }
    local currentChildUIComponentPath = {}

    UI:resizeUIComponent(uiComponent, widthToAdd, heightToAdd)

    for i, childUIComponentName in ipairs(childUIComponentsPath) do
        currentChildUIComponentPath[i] = childUIComponentName
        local childUIComponent = find_uicomponent(uiComponent, unpack(currentChildUIComponentPath))
        UI:resizeUIComponent(childUIComponent, widthToAdd, heightToAdd)
    end

    TotowarLogger:logDebug("Resize UI component and children (\"%s\"): Completed", uiComponent:Id())
end
