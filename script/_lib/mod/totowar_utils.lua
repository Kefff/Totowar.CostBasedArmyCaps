local totowarUtils = "totowar_utils"

---Queries for finding UI components.
---@class UIComponentSearchQuery
local UIComponentSearchQuery = {
    globalRecruitmentPool = { "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "recruitment_listbox", "recruitment_pool_list", "list_clip", "list_box", "global" },
    localRecruitmentPool = { "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "recruitment_listbox", "recruitment_pool_list", "list_clip", "list_box", "local1" },
    recruitmentOptions = { "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options" },
    unitsPanel = { "units_panel" },
    unitsPanelIconList = { "units_panel", "main_units_panel", "icon_list" }
}

---UI utility tools for Totowar mods.
---@class UI
local UI = {
    Enums = {
        ---Component context object type IDs.
        CcoContextTypeId = {
            ccoAgentSubtypeRecord = "ccoAgentSubtypeRecord",
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

        --Panels
        Panel = {
            recruitmentOptions = "recruitment_options"
        },

        ---Queries for finding UI components.
        ---@type UIComponentSearchQuery
        UIComponentSearchQuery = UIComponentSearchQuery
    }
}

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
        ---Colors.
        Color = {
            blue = "alliance_ally",
            red = "alliance_enemy",
            yellow = "yellow"
        },

        ---Events.
        Event = {
            characterDeselected = "CharacterDeselected",
            characterSelected = "CharacterSelected",
            panelOpenedCampaign = "PanelOpenedCampaign",
        }
    },

    ---Logger for utility tools.
    logger = TotoWarLogger.new(totowarUtils),

    ---Player faction name.
    ---@type string
    playerFactionName = nil,

    ---UI utility tools.
    ---@class UI
    UI = UI
}

---Indicates whether an army can recruit units.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE  Army.
---@return boolean
function TotoWarUtils:canArmyRecruit(army)
    TotoWarUtils.logger:logDebug("Can recruit: STARTED")

    local canRecruit =
        army:has_general()
        and not army:is_armed_citizenry()
        and not army:is_set_piece_battle_army()
        and not army:force_type():has_feature("unable_to_recruit_units")

    TotoWarUtils.logger:logDebug("Can recruit (%s): COMPLETED", canRecruit)

    return canRecruit
end

---Gets the caption of a unit.
---@param unitKey string Unit key.
function TotoWarUtils:getUnitCaption(unitKey)
    local caption = common.get_context_value("CcoMainUnitRecord", unitKey, "Name")

    return caption
end

---Indicates whether a faction is the faction of the player.
---@param factionName string name.
---@return boolean
function TotoWarUtils:isPlayerFaction(factionName)
    TotoWarUtils.logger:logDebug("Is player faction (\"%s\"): STARTED", factionName)

    if TotoWarUtils.playerFactionName == nil then
        TotoWarUtils.playerFactionName = cm:get_local_faction_name()
    end

    isPlayerFactionGeneral = factionName == TotoWarUtils.playerFactionName

    TotoWarUtils.logger:logDebug("Is player faction (\"%s\", %s): COMPLETED", factionName, isPlayerFactionGeneral)

    return isPlayerFactionGeneral
end

---Indicates whether a character is general that belongs to the faction of the player.
---@param character CHARACTER_SCRIPT_INTERFACE character.
---@return boolean
function TotoWarUtils:isPlayerFactionGeneral(character)
    TotoWarUtils.logger:logDebug("Is player faction general (%s): STARTED", character:cqi())

    isPlayerFactionGeneral = character:has_military_force() and TotoWarUtils:isPlayerFaction(character:faction():name())

    TotoWarUtils.logger:logDebug("Is player faction general (%s, %s): COMPLETED", character:cqi(), isPlayerFactionGeneral)

    return isPlayerFactionGeneral
end

---Finds a UI component from the root.
---@param path string[] Path to the UI component from the root.
---@return UIC | nil
function UI:findUIComponent(path)
    local childUIComponent = UI:findUIComponentChild(core:get_ui_root(), path)

    return childUIComponent
end

---Finds a UI component that is a child another UI component.
---@param parentUIComponent UIC Parent UI component
---@param path string[] ID of the context object.
---@return UIC | nil
function UI:findUIComponentChild(parentUIComponent, path)
    local pathString = table.concat(path, "/")

    TotoWarUtils.logger:logDebug("Find UI component (\"%s/%s\"): STARTED", parentUIComponent:Id(), pathString)

    local uiComponent = find_uicomponent(parentUIComponent, unpack(path))

    if not uiComponent then
        TotoWarUtils.logger:logDebug("Find UI component (\"%s/%s\"): NOT FOUND", parentUIComponent:Id(), pathString)

        return nil
    end

    TotoWarUtils.logger:logDebug("Find UI component (\"%s/%s\"): COMPLETED", parentUIComponent:Id(), pathString)

    return uiComponent
end

---Gets a context object of a UI component.
---@param uiComponent UIC UI component.
---@param ccoContextTypeId string ID of the context object.
---@return ComponentContextObject
function UI:getComponentContextObject(uiComponent, ccoContextTypeId)
    TotoWarUtils.logger:logDebug(
        "Get component context object (\"%s\", \"%s\"): STARTED",
        uiComponent:Id(),
        ccoContextTypeId)

    local contextId = uiComponent:GetContextObjectId(ccoContextTypeId)
    local componentContextObject = cco(ccoContextTypeId, contextId)

    TotoWarUtils.logger:logDebug(
        "Get component context object (\"%s\", \"%s\"): COMPLETED",
        uiComponent:Id(),
        ccoContextTypeId)

    return componentContextObject
end

---Offsets the children of a UI component.
---@param uiComponent UIC UI component which children must be offset.
---@param offsetX number X offset.
---@param offsetY number Y offset.
function UI:offsetUIComponent(uiComponent, offsetX, offsetY)
    TotoWarUtils.logger:logDebug("Offset UI components (\"%s\"): STARTED", uiComponent:Id())

    local uiComponentOffsetX, uiComponentOffsetY = uiComponent:GetDockOffset()
    uiComponent:SetDockOffset(uiComponentOffsetX + offsetX, uiComponentOffsetY + offsetY)

    TotoWarUtils.logger:logDebug("Offset UI components (\"%s\"): COMPLETED", uiComponent:Id())
end

---Offsets the children of a UI component.
---@param uiComponent UIC UI component which children must be offset.
---@param offsetX number X offset.
---@param offsetY number Y offset.
function UI:offsetChildUIComponents(uiComponent, offsetX, offsetY)
    TotoWarUtils.logger:logDebug("Offset child UI components (\"%s\"): STARTED", uiComponent:Id())

    for i = 0, uiComponent:ChildCount() - 1, 1 do
        local childUIComponent = find_child_uicomponent_by_index(uiComponent, i)
        UI:offsetUIComponent(childUIComponent, offsetX, offsetY)
    end

    TotoWarUtils.logger:logDebug("Offset child UI components (\"%s\"): COMPLETED", uiComponent:Id())
end

---Resizes a UI component.
---@param uiComponent UIC UI component.
---@param widthToAdd number Width to add.
---@param heightToAdd number Height to add.
function UI:resizeUIComponent(uiComponent, widthToAdd, heightToAdd)
    TotoWarUtils.logger:logDebug("Resize UI component (\"%s\"): STARTED", uiComponent:Id())

    local uiComponentWidth, uiComponentHeight = uiComponent:Dimensions()
    uiComponent:SetCanResizeWidth(true)
    uiComponent:SetCanResizeHeight(true)
    uiComponent:Resize(uiComponentWidth + widthToAdd, uiComponentHeight + heightToAdd, false)

    TotoWarUtils.logger:logDebug("Resize UI component (\"%s\"): COMPLETED", uiComponent:Id())
end

---A UI components and its children listed in a path.
---@param uiComponent UIC UI component to resize.
---@param widthToAdd number Width to add.
---@param heightToAdd number Height to add.
---@param ... string Path containing the names of the child UI components to resize.
function UI:resizeUIComponentAndChildren(uiComponent, widthToAdd, heightToAdd, ...)
    TotoWarUtils.logger:logDebug("Resize UI component and children (\"%s\"): STARTED", uiComponent:Id())

    local childUIComponentsPath = { ... }
    local currentChildUIComponentPath = {}

    UI:resizeUIComponent(uiComponent, widthToAdd, heightToAdd)

    for i, childUIComponentName in ipairs(childUIComponentsPath) do
        currentChildUIComponentPath[i] = childUIComponentName
        local childUIComponent = find_uicomponent(uiComponent, unpack(currentChildUIComponentPath))
        UI:resizeUIComponent(childUIComponent, widthToAdd, heightToAdd)
    end

    TotoWarUtils.logger:logDebug("Resize UI component and children (\"%s\"): COMPLETED", uiComponent:Id())
end
