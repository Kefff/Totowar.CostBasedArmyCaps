local totowarUtils = "totowar_utils"

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
        ---Colors.
        Color = {
            blue = "alliance_ally",
            red = "alliance_enemy",
            yellow = "yellow"
        },
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
        ---Events.
        Event = {
            characterDeselected = "CharacterDeselected",
            characterSelected = "CharacterSelected",
            panelOpenedCampaign = "PanelOpenedCampaign",
        },
        Icon = {

        },
        Panel = {
            recruitmentOptions = "recruitment_options"
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
    TotoWarUtils.logger:logDebug("Can recruit: Started")

    local canRecruit =
        army:has_general()
        and not army:is_armed_citizenry()
        and not army:is_set_piece_battle_army()
        and not army:force_type():has_feature("unable_to_recruit_units")

    TotoWarUtils.logger:logDebug("Can recruit (%s): Completed", canRecruit)

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
    TotoWarUtils.logger:logDebug("Is player faction (\"%s\"): Started", factionName)

    if TotoWarUtils.playerFactionName == nil then
        TotoWarUtils.playerFactionName = cm:get_local_faction_name()
    end

    isPlayerFactionGeneral = factionName == TotoWarUtils.playerFactionName

    TotoWarUtils.logger:logDebug("Is player faction (\"%s\", %s): Completed", factionName, isPlayerFactionGeneral)

    return isPlayerFactionGeneral
end

---Indicates whether a character is general that belongs to the faction of the player.
---@param character CHARACTER_SCRIPT_INTERFACE character.
---@return boolean
function TotoWarUtils:isPlayerFactionGeneral(character)
    TotoWarUtils.logger:logDebug("Is player faction general (%s): Started", character:cqi())

    isPlayerFactionGeneral = character:has_military_force() and TotoWarUtils:isPlayerFaction(character:faction():name())

    TotoWarUtils.logger:logDebug("Is player faction general (%s, %s): Completed", character:cqi(), isPlayerFactionGeneral)

    return isPlayerFactionGeneral
end

---Gets a context object of a UI component.
---@param uiComponent UIC UI component.
---@param ccoContextTypeId string ID of the context object.
---@return ComponentContextObject
function UI:getComponentContextObject(uiComponent, ccoContextTypeId)
    TotoWarUtils.logger:logDebug("Get component context object (\"%s\", \"%s\"): Started", uiComponent:Id(),
        ccoContextTypeId)

    local contextId = uiComponent:GetContextObjectId(ccoContextTypeId)
    local componentContextObject = cco(ccoContextTypeId, contextId)

    TotoWarUtils.logger:logDebug("Get component context object (\"%s\", \"%s\"): Completed", uiComponent:Id(),
        ccoContextTypeId)

    return componentContextObject
end

---Gets the global recruitment pool UI component.
---@return UIC
function UI:getGlobalRecruitmentPoolUIComponent()
    TotoWarUtils.logger:logDebug("Get global recruitment pool UI component: Started")

    local unitsPanelUIComponent = UI:getUnitsPanelUIComponent()
    local globalRecruitmentUIComponent = find_uicomponent(
        unitsPanelUIComponent,
        "main_units_panel",
        "recruitment_docker",
        "recruitment_options",
        "recruitment_listbox",
        "recruitment_pool_list",
        "list_clip",
        "list_box",
        "global")

    TotoWarUtils.logger:logDebug("Get global recruitment pool UI component: Completed")

    return globalRecruitmentUIComponent
end

---Gets the local recruitment pool UI component.
---@return UIC
function UI:getLocalRecruitmentPoolUIComponent()
    TotoWarUtils.logger:logDebug("Get local recruitment pool UI component: Started")

    local unitsPanelUIComponent = UI:getUnitsPanelUIComponent()
    local localRecruitmentUIComponent = find_uicomponent(
        unitsPanelUIComponent,
        "main_units_panel",
        "recruitment_docker",
        "recruitment_options",
        "recruitment_listbox",
        "recruitment_pool_list",
        "list_clip",
        "list_box",
        "local1")

    TotoWarUtils.logger:logDebug("Get local recruitment pool UI component: Completed")

    return localRecruitmentUIComponent
end

---Gets the UI component for the units panel.
---@return UIC
function UI:getUnitsPanelUIComponent()
    TotoWarUtils.logger:logDebug("Get units panel UI component: Started")

    local unitsPanelUIComponent = find_uicomponent(core:get_ui_root(), "units_panel")

    TotoWarUtils.logger:logDebug("Get units panel UI component: Completed")

    return unitsPanelUIComponent
end

---Gets the UI component for the list of icons of the units panel.
---@return UIC
function UI:getUnitsPanelIconListUIComponent()
    TotoWarUtils.logger:logDebug("Get units panel icon list UI component: Started")

    local unitsPanelUIComponent = UI:getUnitsPanelUIComponent()
    local unitsPanelIconListUIComponent = find_uicomponent(
        unitsPanelUIComponent,
        "main_units_panel",
        "icon_list")

    TotoWarUtils.logger:logDebug("Get units panel icon list UI component: Completed")

    return unitsPanelIconListUIComponent
end

---Offsets the children of a UI component.
---@param uiComponent UIC UI component which children must be offset.
---@param offsetX number X offset.
---@param offsetY number Y offset.
function UI:offsetUIComponent(uiComponent, offsetX, offsetY)
    TotoWarUtils.logger:logDebug("Offset UI components (\"%s\"): Started", uiComponent:Id())

    local uiComponentOffsetX, uiComponentOffsetY = uiComponent:GetDockOffset()
    uiComponent:SetDockOffset(uiComponentOffsetX + offsetX, uiComponentOffsetY + offsetY)

    TotoWarUtils.logger:logDebug("Offset UI components (\"%s\"): Completed", uiComponent:Id())
end

---Offsets the children of a UI component.
---@param uiComponent UIC UI component which children must be offset.
---@param offsetX number X offset.
---@param offsetY number Y offset.
function UI:offsetChildUIComponents(uiComponent, offsetX, offsetY)
    TotoWarUtils.logger:logDebug("Offset child UI components (\"%s\"): Started", uiComponent:Id())

    for i = 0, uiComponent:ChildCount() - 1, 1 do
        local childUIComponent = find_child_uicomponent_by_index(uiComponent, i)
        UI:offsetUIComponent(childUIComponent, offsetX, offsetY)
    end

    TotoWarUtils.logger:logDebug("Offset child UI components (\"%s\"): Completed", uiComponent:Id())
end

---Resizes a UI component.
---@param uiComponent UIC UI component.
---@param widthToAdd number Width to add.
---@param heightToAdd number Height to add.
function UI:resizeUIComponent(uiComponent, widthToAdd, heightToAdd)
    TotoWarUtils.logger:logDebug("Resize UI component (\"%s\"): Started", uiComponent:Id())

    local uiComponentWidth, uiComponentHeight = uiComponent:Dimensions()
    uiComponent:SetCanResizeWidth(true)
    uiComponent:SetCanResizeHeight(true)
    uiComponent:Resize(uiComponentWidth + widthToAdd, uiComponentHeight + heightToAdd, false)

    TotoWarUtils.logger:logDebug("Resize UI component (\"%s\"): Completed", uiComponent:Id())
end

---A UI components and its children listed in a path.
---@param uiComponent UIC UI component to resize.
---@param widthToAdd number Width to add.
---@param heightToAdd number Height to add.
---@param ... string Path containing the names of the child UI components to resize.
function UI:resizeUIComponentAndChildren(uiComponent, widthToAdd, heightToAdd, ...)
    TotoWarUtils.logger:logDebug("Resize UI component and children (\"%s\"): Started", uiComponent:Id())

    local childUIComponentsPath = { ... }
    local currentChildUIComponentPath = {}

    UI:resizeUIComponent(uiComponent, widthToAdd, heightToAdd)

    for i, childUIComponentName in ipairs(childUIComponentsPath) do
        currentChildUIComponentPath[i] = childUIComponentName
        local childUIComponent = find_uicomponent(uiComponent, unpack(currentChildUIComponentPath))
        UI:resizeUIComponent(childUIComponent, widthToAdd, heightToAdd)
    end

    TotoWarUtils.logger:logDebug("Resize UI component and children (\"%s\"): Completed", uiComponent:Id())
end
