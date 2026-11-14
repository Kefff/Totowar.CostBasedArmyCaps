local logger = TotoWar__Logger.get(TotoWar_Cbac_Enum_LogCategories.playerManager)

---Adds the unit cards of a unit exchange pool to the army supplies costs of the armies exchanging units.
---@param unitCards TotoWar_Cbac_UnitExchangePoolCard[] Unit cards of the unit exchange pool.
---@param armySuppliesCost TotoWar_Cbac_ArmySuppliesCost Army supplies cost of the army of the unit exchange pool.
---@param otherArmySuppliesCost TotoWar_Cbac_ArmySuppliesCost Army supplies cost of the other army.
local function addUnitExchangePoolCards(unitCards, armySuppliesCost, otherArmySuppliesCost)
    logger:logDebug(
        "addUnitExchangePoolCards(unitCards, armySuppliesCost, otherArmySuppliesCost): STARTED => Unit cards: %s",
        #unitCards)

    for index, unitCard in ipairs(unitCards) do
        -- Selected cards are transferred to the other army
        local targetArmySuppliesCost = unitCard.isSelected and otherArmySuppliesCost or armySuppliesCost

        if unitCard.characterCqi ~= nil then
            targetArmySuppliesCost:addCharacter(unitCard.characterCqi)
        else
            targetArmySuppliesCost:addUnit(unitCard.unitKey)
        end
    end

    logger:logDebug(
        "addUnitExchangePoolCards(unitCards, armySuppliesCost, otherArmySuppliesCost): COMPLETED => Unit cards: %s | Available supplies: %s | Other army available supplies: %s",
        #unitCards,
        armySuppliesCost.availableSupplies,
        otherArmySuppliesCost.availableSupplies)
end

---Gets the lord among the unit cards of a unit exchange pool.
---@param unitCards TotoWar_Cbac_UnitExchangePoolCard[] Unit cards of the unit exchange pool.
---@return CHARACTER_SCRIPT_INTERFACE | nil
local function getLordInUnitExchangePoolCards(unitCards)
    logger:logDebug(
        "getLordInUnitExchangePoolCards(unitCards): STARTED => Unit cards: %s",
        #unitCards)

    for index, unitCard in ipairs(unitCards) do
        if unitCard.characterCqi ~= nil then
            local character = TotoWar__Gameplay:getCharacter(unitCard.characterCqi)

            if character ~= nil and TotoWar__Gameplay:isLordCharacter(character) then
                logger:logDebug(
                    "getLordInUnitExchangePoolCards(unitCards): COMPLETED => Unit cards: %s | %s",
                    #unitCards,
                    function() return TotoWar__Gameplay:getCharacterFullCaption(character) end)

                return character
            end
        end
    end

    logger:logError("Unit exchange: lord of one of the armies not found, its army supplies not displayed")
    logger:logDebug(
        "getLordInUnitExchangePoolCards(unitCards): COMPLETED => Unit cards: %s | Lord not found",
        #unitCards)

    return nil
end

---Reacts to the request to block an army of a player, or to allow it to move again, received by all the players of the game.
---The request is sent by `updateSelectedLordMovement` on the machine of the player who owns the army.
---The effect bundle that blocks the army is applied or removed here, on all the machines, so that the game stays synchronized.
---@param factionCqi integer Command queue index of the faction of the player who sent the request.
---@param dataString string Data of the event: `<army command queue index>|<1 to block the army, 0 to allow it to move>`.
local function onArmyMovementUpdateRequested(factionCqi, dataString)
    logger:logDebug("onArmyMovementUpdateRequested(%s, %s): STARTED", factionCqi, dataString)

    local data = TotoWar__String:split(dataString, "|")
    local armyCqi = tonumber(data[1])
    local isBlocked = data[2] == "1"

    ---@type MILITARY_FORCE_SCRIPT_INTERFACE | nil
    local army = nil

    if armyCqi ~= nil then
        army = TotoWar__Gameplay:getArmy(armyCqi)
    end

    -- Ignoring a request that does not concern an army of the human player who sent it
    if army == nil
        or army:faction():command_queue_index() ~= factionCqi
        or army:faction():is_human() == false
    then
        logger:logWarning(
            "Request to block or unblock an army ignored, the army is not found in the faction of the player who sent it (data: %s)",
            dataString)
        logger:logDebug(
            "onArmyMovementUpdateRequested(%s, %s): COMPLETED => Army not found in the faction of the sender",
            factionCqi,
            dataString)

        return
    end

    local effectBundleKey = TotoWar_Cbac_Constant.armySuppliesExceededEffectBundleKey
    local hasEffectBundle = army:has_effect_bundle(effectBundleKey)

    -- The request may have been sent several times before being received: it is only applied once
    if isBlocked and hasEffectBundle == false then
        logger:logInfo(
            "%s: army cannot move, army supplies exceeded",
            function() return TotoWar__Gameplay:getArmyCaption(army) end)

        -- The type definitions declare the command queue index as a string, but the game requires a number (lib_campaign_manager.lua)
        ---@diagnostic disable-next-line: param-type-mismatch
        cm:apply_effect_bundle_to_force(effectBundleKey, army:command_queue_index(), 0)
    elseif isBlocked == false and hasEffectBundle then
        logger:logInfo(
            "%s: army can move again, army supplies no longer exceeded",
            function() return TotoWar__Gameplay:getArmyCaption(army) end)

        -- The type definitions declare the command queue index as a string, but the game requires a number (lib_campaign_manager.lua)
        ---@diagnostic disable-next-line: param-type-mismatch
        cm:remove_effect_bundle_from_force(effectBundleKey, army:command_queue_index())
    end

    logger:logDebug(
        "onArmyMovementUpdateRequested(%s, %s): COMPLETED => %s | Blocked: %s",
        factionCqi,
        dataString,
        function() return TotoWar__Gameplay:getArmyCaption(army) end,
        isBlocked)
end

---Reacts to the restriction of the player armies being disabled.
---The armies of all the human players are processed, and not only those of the local player:
---this method is executed on all the machines of the game, which must all make the same changes to stay synchronized.
local function onPlayerArmySuppliesDisabled()
    logger:logDebug("onPlayerArmySuppliesDisabled(): STARTED")

    local effectBundleKey = TotoWar_Cbac_Constant.armySuppliesExceededEffectBundleKey

    for index, factionKey in ipairs(cm:get_human_factions()) do
        local armies = cm:get_faction(factionKey):military_force_list()

        -- Allowing the armies blocked by the mod to move again
        for i = 0, armies:num_items() - 1, 1 do
            local army = armies:item_at(i)

            if army:has_effect_bundle(effectBundleKey) then
                logger:logDebug(
                    "onPlayerArmySuppliesDisabled(): EFFECT BUNDLE REMOVED => %s",
                    function() return TotoWar__Gameplay:getArmyCaption(army) end)

                -- The type definitions declare the command queue index as a string, but the game requires a number (lib_campaign_manager.lua)
                ---@diagnostic disable-next-line: param-type-mismatch
                cm:remove_effect_bundle_from_force(effectBundleKey, army:command_queue_index())
            end
        end
    end

    logger:logDebug("onPlayerArmySuppliesDisabled(): COMPLETED")
end

---Manager in charge of managing the army supplies for the player armies.
---@class TotoWar_Cbac_PlayerManager
TotoWar_Cbac_PlayerManager = {
    ---Indicates whether the army supplies cost is being initialized.
    ---When it is the case, methods that update UI elements (such as when a panel is opened)
    ---should not execute because the UI will be updated when the
    ---TotoWar_Cbac_SelectedLordArmySuppliesCostChanged event is triggered at the end ot the
    ---supplies cost initialization.
    ---@type boolean
    isInitializingArmySuppliesCost = nil,

    ---Last request sent to block an army (`true`) or to allow it to move (`false`), by army command queue index.
    ---The request is only applied when all the machines receive it: until then, the effect bundle of the army does not reflect it.
    ---@type table<integer, boolean>
    lastMovementRequests = nil,

    ---ID of the one-time subscription that waits for the units panel to open before initializing
    ---the army supplies cost of the selected lord.
    ---@type integer | nil
    pendingInitializationSubscriptionId = nil,

    ---Army supplies cost of the hero selected alone on the campaign map.
    ---@type TotoWar_Cbac_UnitArmySuppliesCost | nil
    selectedHeroArmySuppliesCost = nil,

    ---Unique identifier of the selected lord.
    ---@type CHARACTER_SCRIPT_INTERFACE  | nil
    selectedLord = nil,

    ---Army supplies cost of the army of the selected lord.
    ---@type TotoWar_Cbac_ArmySuppliesCost | nil
    selectedLordArmySuppliesCost = nil,

    ---Army supplies cost of the first army during unit exchange.
    ---@type TotoWar_Cbac_ArmySuppliesCost | nil
    unitExchangeArmySuppliesCost1 = nil,

    ---Army supplies cost of the second army during unit exchange.
    ---@type TotoWar_Cbac_ArmySuppliesCost | nil
    unitExchangeArmySuppliesCost2 = nil,

    ---Army supplies cost of the warband upgrade screen.
    ---@type TotoWar_Cbac_ArmySuppliesCost | nil
    warbandUpgradeArmySuppliesCost = nil
}

---Cancels the pending initialization of the army supplies cost of the previously selected lord.
function TotoWar_Cbac_PlayerManager:cancelArmySuppliesCostInitialization()
    logger:logDebug(
        "cancelArmySuppliesCostInitialization(): STARTED => %s | Pending subscription: %s",
        function()
            return
                self.selectedLord ~= nil
                and TotoWar__Gameplay:getArmyCaption(self.selectedLord:military_force())
                or "No selected lord"
        end,
        self.pendingInitializationSubscriptionId)

    if self.pendingInitializationSubscriptionId ~= nil then
        TotoWar__EventsManager:unsubscribe(self.pendingInitializationSubscriptionId)
        self.pendingInitializationSubscriptionId = nil
    end

    self.isInitializingArmySuppliesCost = false

    logger:logDebug(
        "cancelArmySuppliesCostInitialization(): COMPLETED => %s",
        function()
            return
                self.selectedLord ~= nil
                and TotoWar__Gameplay:getArmyCaption(self.selectedLord:military_force())
                or "No selected lord"
        end)
end

---Clears the list of in-recruitment mercenary units supply costs.
function TotoWar_Cbac_PlayerManager:clearMercenaryRecruitment()
    logger:logDebug(
        "clearMercenaryRecruitment(): STARTED => %s",
        function()
            return
                self.selectedLord ~= nil
                and TotoWar__Gameplay:getArmyCaption(self.selectedLord:military_force())
                or "No selected lord"
        end)

    if #self.selectedLordArmySuppliesCost.inRecruitmentMercenaryUnits > 0 then
        self.selectedLordArmySuppliesCost:clearMercenaryRecruitment()

        -- Signaling army supplies cost change
        TotoWar__EventsManager:trigger(TotoWar_Cbac_Enum_ModEvents.selectedLordArmySuppliesCostChanged)
    end

    logger:logDebug(
        "clearMercenaryRecruitment(): COMPLETED => %s",
        function()
            return
                self.selectedLord ~= nil
                and TotoWar__Gameplay:getArmyCaption(self.selectedLord:military_force())
                or "No selected lord"
        end)
end

---Initializes the player manager.
function TotoWar_Cbac_PlayerManager:initialize()
    logger:logDebug("initialize(): STARTED")

    self.isInitializingArmySuppliesCost = false
    self.lastMovementRequests = {}
    self.pendingInitializationSubscriptionId = nil
    self.selectedHeroArmySuppliesCost = nil
    self.selectedLord = nil
    self.selectedLordArmySuppliesCost = nil
    self.unitExchangeArmySuppliesCost1 = nil
    self.unitExchangeArmySuppliesCost2 = nil
    self.warbandUpgradeArmySuppliesCost = nil

    self:subscribeToEvents()

    logger:logDebug("initialize(): COMPLETED")
end

---Initializes the army supplies cost of the army of the selected lord.
---@param lord CHARACTER_SCRIPT_INTERFACE Selected lord.
function TotoWar_Cbac_PlayerManager:initializeArmySuppliesCost(lord)
    logger:logDebug(
        "initializeArmySuppliesCost(%s): STARTED => %s",
        function() return lord:cqi() end,
        function() return TotoWar__Gameplay:getCharacterFullCaption(lord) end)

    -- The initialization is delayed, another lord may have been selected or the lord deselected in the meantime
    if self.selectedLord == nil or self.selectedLord:cqi() ~= lord:cqi() then
        logger:logDebug(
            "initializeArmySuppliesCost(%s): COMPLETED => %s | Not calculated, lord no longer selected",
            function() return lord:cqi() end,
            function() return TotoWar__Gameplay:getCharacterFullCaption(lord) end)

        return
    end

    self.selectedLordArmySuppliesCost = TotoWar_Cbac_ArmySuppliesCost.newFromArmy(false, lord:military_force())

    -- Adding units being recruited in the lord army.
    -- The units panel can be closed during the delay before the initialization (end of turn for example).
    local unitsUIComponent = TotoWar__UI:findUIComponent(TotoWar__UI.uiComponentQueries.unitsPanel_units)

    if unitsUIComponent == nil then
        logger:logDebug(
            "initializeArmySuppliesCost(%s): UNITS PANEL CLOSED => %s | Units being recruited not counted",
            function() return lord:cqi() end,
            function() return TotoWar__Gameplay:getCharacterFullCaption(lord) end)
    else
        for i = unitsUIComponent:ChildCount() - 1, 0, -1 do
            -- Iterating from the last unit card since units being recruited are at the end
            local unitCardUIComponent = find_child_uicomponent_by_index(unitsUIComponent, i)
            local isInRecruitmentStandardUnitCard =
                unitCardUIComponent:Id():match(TotoWar__Enum_Patterns.inRecruitmentStandardUnitCard) ~= nil

            if not isInRecruitmentStandardUnitCard
            then
                -- Stopping the iteration as soon as we encounter a unit that is not being recruited
                break
            end

            local unitKey = TotoWar__UI:getUnitCardUnitKey(unitCardUIComponent)
            self.selectedLordArmySuppliesCost:addUnit(unitKey)
        end
    end

    self.isInitializingArmySuppliesCost = false

    -- Signaling army supplies cost change
    TotoWar__EventsManager:trigger(TotoWar_Cbac_Enum_ModEvents.selectedLordArmySuppliesCostChanged)

    logger:logDebug(
        "initializeArmySuppliesCost(%s): COMPLETED => %s | Total cost: %s | Available supplies: %s",
        function() return lord:cqi() end,
        function() return TotoWar__Gameplay:getCharacterFullCaption(lord) end,
        self.selectedLordArmySuppliesCost.totalCost,
        self.selectedLordArmySuppliesCost.availableSupplies)
end

---Indicates whether the army supplies cost of the selected lord army can be used by the methods reacting to events:
---the player army supplies are enabled, it is the turn of the local player and the cost is initialized
---(it is nil while it is being initialized, and when no lord is selected).
---@return boolean
function TotoWar_Cbac_PlayerManager:isSelectedLordArmySuppliesCostAvailable()
    return
        TotoWar_Cbac_Mod.options.playerArmySuppliesEnabled
        and cm:is_local_players_turn(true)
        and self.selectedLordArmySuppliesCost ~= nil
end

---Reacts to a character being deselected.
function TotoWar_Cbac_PlayerManager:onCharacterDeselected()
    logger:logDebug("onCharacterDeselected(): STARTED")

    self:cancelArmySuppliesCostInitialization()

    if self.selectedLord ~= nil then
        self.selectedLord = nil
        self.selectedLordArmySuppliesCost = nil
    end

    self.selectedHeroArmySuppliesCost = nil

    logger:logDebug("onCharacterDeselected(): COMPLETED")
end

---Reacts to a character being selected.
---@param character CHARACTER_SCRIPT_INTERFACE Selected character.
function TotoWar_Cbac_PlayerManager:onCharacterSelected(character)
    logger:logDebug(
        "onCharacterSelected(%s): STARTED => %s",
        function() return character:cqi() end,
        function() return TotoWar__Gameplay:getCharacterFullCaption(character) end)

    self:cancelArmySuppliesCostInitialization()

    if TotoWar__Gameplay:isLordCharacter(character)
        and (TotoWar__Gameplay:isLocalPlayerFaction(character:faction():name())
            or TotoWar__Mod.options.debugEnabled) -- In debug mode, we see the army supplies cost or other faction lords
    then
        self.selectedHeroArmySuppliesCost = nil
        self.selectedLord = character
        self.selectedLordArmySuppliesCost = nil
        self.isInitializingArmySuppliesCost = true

        if cm:get_campaign_ui_manager():is_panel_open(TotoWar__Enum_Panels.unitsPanel) then
            -- Delay otherwise the units_panel is not up to date and still contains the units of the previously selected lord army
            TotoWar__Utils:delay(
                function()
                    --- Initializing the army supplies cost for the newly selected army
                    self:initializeArmySuppliesCost(character)
                end,
                0.25)
        else
            --- Adding a one-time listener that waits for the unit_panel to open before
            --- initializing the army supplies cost because we need to get the cost of the
            --- units being recruited
            local pendingInitializationSubscription = TotoWar__EventsManager:subscribe(
                TotoWar__Enum_GameEvents.panelOpened,
                function()
                    self.pendingInitializationSubscriptionId = nil
                    self:initializeArmySuppliesCost(character)
                end,
                ---@param context TotoWar__GameEventContext_PanelOpenedOrClosed
                function(context) return context.string == TotoWar__Enum_Panels.unitsPanel end,
                1)
            self.pendingInitializationSubscriptionId = pendingInitializationSubscription.id
        end
    elseif cm:char_is_agent(character)
        and (TotoWar__Gameplay:isLocalPlayerFaction(character:faction():name())
            or TotoWar__Mod.options.debugEnabled) -- In debug mode, we see the army supplies cost or other faction heroes
    then
        -- A hero selected on the campaign map is alone: heroes embedded in an army are selected with its lord.
        -- Its army supplies cost is displayed in the units panel, like the army supplies of an army.
        self.selectedLord = nil
        self.selectedLordArmySuppliesCost = nil
        self.selectedHeroArmySuppliesCost = TotoWar_Cbac_UnitArmySuppliesCost.newCharacter(character:cqi())

        -- Signaling army supplies cost change
        TotoWar__EventsManager:trigger(TotoWar_Cbac_Enum_ModEvents.selectedHeroArmySuppliesCostChanged)
    elseif self.selectedLordArmySuppliesCost ~= nil or self.selectedHeroArmySuppliesCost ~= nil then
        self.selectedLord = nil
        self.selectedLordArmySuppliesCost = nil
        self.selectedHeroArmySuppliesCost = nil

        -- Signaling army supplies cost change.
        -- This is only useful in the case the player has one of their armies or heroes selected
        -- and selects a character whose army supplies are not displayed (a character of another faction for example).
        -- In this case, the units panel is not closed and the CharacterDeselected event is not triggered by the game.
        -- So we set selectedLordArmySuppliesCost and selectedHeroArmySuppliesCost to nil and we still trigger
        -- the selectedLordArmySuppliesCostChanged event to make the UI manager react.
        -- In this case, it will hide the army supplies because selectedLordArmySuppliesCost and
        -- selectedHeroArmySuppliesCost are nil.
        TotoWar__EventsManager:trigger(TotoWar_Cbac_Enum_ModEvents.selectedLordArmySuppliesCostChanged)
    end

    logger:logDebug(
        "onCharacterSelected(%s): COMPLETED => %s",
        function() return character:cqi() end,
        function() return TotoWar__Gameplay:getCharacterFullCaption(character) end)
end

---Reacts to the click on the unit card of a mercenary unit in the selected army recruitment queue.
---@param uiComponentName string Name of the clicked UI component.
function TotoWar_Cbac_PlayerManager:onInRecruitmentMercenaryUnitCardClick(uiComponentName)
    logger:logDebug(
        "onInRecruitmentMercenaryUnitCardClick(%s): STARTED => %s",
        uiComponentName,
        function()
            return
                self.selectedLord ~= nil
                and TotoWar__Gameplay:getArmyCaption(self.selectedLord:military_force())
                or "No selected lord"
        end)

    self.selectedLordArmySuppliesCost:removeUnit(uiComponentName)

    -- Signaling army supplies cost change
    TotoWar__EventsManager:trigger(TotoWar_Cbac_Enum_ModEvents.selectedLordArmySuppliesCostChanged)

    logger:logDebug(
        "onInRecruitmentMercenaryUnitCardClick(%s): COMPLETED => %s",
        uiComponentName,
        function()
            return
                self.selectedLord ~= nil
                and TotoWar__Gameplay:getArmyCaption(self.selectedLord:military_force())
                or "No selected lord"
        end)
end

---Reacts to the mercenary recruitment panel being closed.
function TotoWar_Cbac_PlayerManager:onMercenaryRecruitmentPanelClosed()
    logger:logDebug(
        "onMercenaryRecruitmentPanelClosed(): STARTED => %s",
        function()
            return
                self.selectedLord ~= nil
                and TotoWar__Gameplay:getArmyCaption(self.selectedLord:military_force())
                or "No selected lord"
        end)

    if #self.selectedLordArmySuppliesCost.inRecruitmentMercenaryUnits > 0 then
        self.selectedLordArmySuppliesCost:clearMercenaryRecruitment()

        -- Signaling army supplies cost change
        TotoWar__EventsManager:trigger(TotoWar_Cbac_Enum_ModEvents.selectedLordArmySuppliesCostChanged)
    end

    logger:logDebug(
        "onMercenaryRecruitmentPanelClosed(): COMPLETED => %s",
        function()
            return
                self.selectedLord ~= nil
                and TotoWar__Gameplay:getArmyCaption(self.selectedLord:military_force())
                or "No selected lord"
        end)
end

---Reacts to the mercenary recruitment panel being opened or closed.
function TotoWar_Cbac_PlayerManager:onMercenaryRecruitmentPanelOpened()
    logger:logDebug(
        "onMercenaryRecruitmentPanelOpened(): STARTED => %s",
        function()
            return
                self.selectedLord ~= nil
                and TotoWar__Gameplay:getArmyCaption(self.selectedLord:military_force())
                or "No selected lord"
        end)

    self:clearMercenaryRecruitment()

    logger:logDebug(
        "onMercenaryRecruitmentPanelOpened(): COMPLETED => %s",
        function()
            return
                self.selectedLord ~= nil
                and TotoWar__Gameplay:getArmyCaption(self.selectedLord:military_force())
                or "No selected lord"
        end)
end

---Reacts to a mercenary unit being recruited in the selected lord army.
---@param unitKey string Unit key.
---@param cqi integer Unit command queue index.
function TotoWar_Cbac_PlayerManager:onMercenaryUnitsRecruited(unitKey, cqi)
    logger:logDebug(
        "onMercenaryUnitsRecruited(%s, %s): STARTED => %s | Unit: %s",
        unitKey,
        cqi,
        function() return TotoWar__Gameplay:getCharacterFullCaption(self.selectedLord) end,
        function() return TotoWar__Gameplay:getUnitCaption(unitKey) end)

    self.selectedLordArmySuppliesCost:addUnit(unitKey, cqi)

    -- Signaling army supplies cost change
    TotoWar__EventsManager:trigger(TotoWar_Cbac_Enum_ModEvents.selectedLordArmySuppliesCostChanged)

    logger:logDebug(
        "onMercenaryUnitsRecruited(%s, %s): COMPLETED => %s | Unit: %s | Total cost: %s | Available supplies: %s",
        unitKey,
        cqi,
        function() return TotoWar__Gameplay:getCharacterFullCaption(self.selectedLord) end,
        function() return TotoWar__Gameplay:getUnitCaption(unitKey) end,
        self.selectedLordArmySuppliesCost.totalCost,
        self.selectedLordArmySuppliesCost.availableSupplies)
end

---Reacts to the click on the unit card of a recruitable mercenary unit.
---@param uiComponentName string Name of the clicked UI component.
---@param unitUIComponent UIC Clicked UI component.
function TotoWar_Cbac_PlayerManager:onRecruitableMercenaryUnitCardClick(uiComponentName, unitUIComponent)
    logger:logDebug(
        "onRecruitableMercenaryUnitCardClick(%s, unitUIComponent): STARTED => %s",
        uiComponentName,
        function()
            return
                self.selectedLord ~= nil
                and TotoWar__Gameplay:getArmyCaption(self.selectedLord:military_force())
                or "No selected lord"
        end)

    -- Workaround for the fact that we cannot know whether a unit card was `inactive` before clicking
    -- on it or became `inactive` after clicking on it because the click event is triggered after.
    -- This problem prevents us from simply checking the state of the component so we need to check
    -- whether the number of in recruitment mercenary units in the unit list is different from the number
    -- of in recruitment mercenary units we already have added to the army supplies cost.
    -- If there are more in recruitment mercenary units in the unit list, we consider that the unit card
    -- was not `inactive` at the time of the click and we add its army supplies cost.
    -- so we can add the unit army supplies cost.
    local inRecruitmentMercenaryUnitCount = 0
    local unitsUIComponent = TotoWar__UI:getUIComponent(TotoWar__UI.uiComponentQueries.unitsPanel_units)

    for i = unitsUIComponent:ChildCount() - 1, 0, -1 do
        -- Iterating from the last unit card since units being recruited are at the end
        local unitCardUIComponent = find_child_uicomponent_by_index(unitsUIComponent, i)
        local isMercenaryUnitCard =
            unitCardUIComponent:Id():match(TotoWar__Enum_Patterns.inRecruitmentMercenaryUnitCard) ~= nil

        if not isMercenaryUnitCard
        then
            -- Stopping the iteration as soon as we encounter a unit that is not a mercenary unit being recruited
            break
        end

        inRecruitmentMercenaryUnitCount = inRecruitmentMercenaryUnitCount + 1
    end

    logger:logDebug(
        "onRecruitableMercenaryUnitCardClick(%s, unitUIComponent): MERCENARIES => %s | In the recruitment queue: %s | Counted in army supplies: %s",
        uiComponentName,
        function()
            return
                self.selectedLord ~= nil
                and TotoWar__Gameplay:getArmyCaption(self.selectedLord:military_force())
                or "No selected lord"
        end,
        inRecruitmentMercenaryUnitCount,
        #self.selectedLordArmySuppliesCost.inRecruitmentMercenaryUnits)

    if inRecruitmentMercenaryUnitCount > #self.selectedLordArmySuppliesCost.inRecruitmentMercenaryUnits then
        local unitContext = TotoWar__UI:getUIComponentCCO(
            unitUIComponent,
            TotoWar__Enum_CcoContextTypeIds.mainUnitRecord)

        ---@type string
        local unitKey = unitContext:Call("Key")
        self:onUnitAddedToRecruitment(unitKey, true)
    end

    logger:logDebug(
        "onRecruitableMercenaryUnitCardClick(%s, unitUIComponent): COMPLETED => %s",
        uiComponentName,
        function()
            return
                self.selectedLord ~= nil
                and TotoWar__Gameplay:getArmyCaption(self.selectedLord:military_force())
                or "No selected lord"
        end)
end

---Reacts to the army supplies cost of the selected lord changing.
function TotoWar_Cbac_PlayerManager:onSelectedLordArmySuppliesCostChanged()
    logger:logDebug(
        "onSelectedLordArmySuppliesCostChanged(): STARTED => %s",
        function()
            return
                self.selectedLord ~= nil
                and TotoWar__Gameplay:getArmyCaption(self.selectedLord:military_force())
                or "No selected lord"
        end)

    if self.selectedLord == nil then
        logger:logDebug("onSelectedLordArmySuppliesCostChanged(): COMPLETED => No selected lord")

        return
    end

    local needsSelectedLordMovementUpdate = true

    if TotoWar__Mod.options.debugEnabled then
        -- In debug mode, if we select a lord from another faction, we see the army supplies cost
        -- but we do not want to block the army movement
        needsSelectedLordMovementUpdate = TotoWar__Gameplay:isLocalPlayerFaction(self.selectedLord:faction():name())
    end

    if needsSelectedLordMovementUpdate then
        self:updateSelectedLordMovement()
    end

    logger:logDebug(
        "onSelectedLordArmySuppliesCostChanged(): COMPLETED => %s",
        function()
            return
                self.selectedLord ~= nil
                and TotoWar__Gameplay:getArmyCaption(self.selectedLord:military_force())
                or "No selected lord"
        end)
end

---Reacts to a unit being added to the recruitment queue of the selected lord army.
---@param unitKey string Unit key.
---@param isMercenary boolean Indicates whether the unit added to recruitment is a mercenary unit (regiment of renown, Grudge settles, Waaagh mobs, ...).
function TotoWar_Cbac_PlayerManager:onUnitAddedToRecruitment(unitKey, isMercenary)
    logger:logDebug(
        "onUnitAddedToRecruitment(%s, %s): STARTED => %s | Unit: %s",
        unitKey,
        isMercenary,
        function() return TotoWar__Gameplay:getCharacterFullCaption(self.selectedLord) end,
        function() return TotoWar__Gameplay:getUnitCaption(unitKey) end)

    self.selectedLordArmySuppliesCost:addUnit(unitKey, nil, isMercenary)

    -- Signaling army supplies cost change
    TotoWar__EventsManager:trigger(TotoWar_Cbac_Enum_ModEvents.selectedLordArmySuppliesCostChanged)

    logger:logDebug(
        "onUnitAddedToRecruitment(%s, %s): COMPLETED => %s | Unit: %s | Total cost: %s | Available supplies: %s",
        unitKey,
        isMercenary,
        function() return TotoWar__Gameplay:getCharacterFullCaption(self.selectedLord) end,
        function() return TotoWar__Gameplay:getUnitCaption(unitKey) end,
        self.selectedLordArmySuppliesCost.totalCost,
        self.selectedLordArmySuppliesCost.availableSupplies)
end

---Reacts to a unit being disbanded.
---@param unitKey string Unit key
---@param unitCqi integer Unit command queue index.
function TotoWar_Cbac_PlayerManager:onUnitDisbanded(unitKey, unitCqi)
    logger:logDebug(
        "onUnitDisbanded(%s, %s): STARTED => %s | Unit: %s",
        unitKey,
        unitCqi,
        function() return TotoWar__Gameplay:getCharacterFullCaption(self.selectedLord) end,
        function() return TotoWar__Gameplay:getUnitCaption(unitKey) end)

    self.selectedLordArmySuppliesCost:removeUnit(unitKey, unitCqi)

    -- Signaling army supplies cost change
    TotoWar__EventsManager:trigger(TotoWar_Cbac_Enum_ModEvents.selectedLordArmySuppliesCostChanged)

    logger:logDebug(
        "onUnitDisbanded(%s, %s): COMPLETED => %s | Unit: %s | Total cost: %s | Available supplies: %s",
        unitKey,
        unitCqi,
        function() return TotoWar__Gameplay:getCharacterFullCaption(self.selectedLord) end,
        function() return TotoWar__Gameplay:getUnitCaption(unitKey) end,
        self.selectedLordArmySuppliesCost.totalCost,
        self.selectedLordArmySuppliesCost.availableSupplies)
end

---Reacts to the unit exchange being confirmed.
---The game triggers no event when units are transferred between armies, and the armies are not updated yet
---when the button is clicked: the army supplies cost of the selected lord army is taken from the costs calculated
---from the unit exchange pools, which already include the transferred units.
function TotoWar_Cbac_PlayerManager:onUnitExchangeConfirmed()
    logger:logDebug(
        "onUnitExchangeConfirmed(): STARTED => %s",
        function()
            return
                self.selectedLord ~= nil
                and TotoWar__Gameplay:getArmyCaption(self.selectedLord:military_force())
                or "No selected lord"
        end)

    -- Never nil: the subscription condition of this method checks that a lord is selected and that the costs of the
    -- unit exchange are calculated
    local lord = self.selectedLord
    local armySuppliesCost1 = self.unitExchangeArmySuppliesCost1
    local armySuppliesCost2 = self.unitExchangeArmySuppliesCost2
    ---@cast lord CHARACTER_SCRIPT_INTERFACE
    ---@cast armySuppliesCost1 TotoWar_Cbac_ArmySuppliesCost
    ---@cast armySuppliesCost2 TotoWar_Cbac_ArmySuppliesCost

    -- A lord cannot be transferred: the selected lord is in the army supplies cost of its own army
    local isSelectedLordArmy1 = TotoWar__Linq:any(
        armySuppliesCost1.unitArmySuppliesCosts,
        function(unitArmySuppliesCost) return unitArmySuppliesCost.characterCqi == lord:cqi() end)

    self.selectedLordArmySuppliesCost = isSelectedLordArmy1 and armySuppliesCost1 or armySuppliesCost2

    -- Signaling army supplies cost change
    TotoWar__EventsManager:trigger(TotoWar_Cbac_Enum_ModEvents.selectedLordArmySuppliesCostChanged)

    logger:logDebug(
        "onUnitExchangeConfirmed(): COMPLETED => %s | Total cost: %s | Available supplies: %s",
        function() return TotoWar__Gameplay:getArmyCaption(lord:military_force()) end,
        self.selectedLordArmySuppliesCost.totalCost,
        self.selectedLordArmySuppliesCost.availableSupplies)
end

---Reacts to the unit exchange panel being opened.
function TotoWar_Cbac_PlayerManager:onUnitExchangePanelOpened()
    logger:logDebug("onUnitExchangePanelOpened(): STARTED")

    self:updateUnitExchangeArmySuppliesCosts()

    logger:logDebug("onUnitExchangePanelOpened(): COMPLETED")
end

---Reacts to a unit card of one of the unit exchange pools being clicked.
function TotoWar_Cbac_PlayerManager:onUnitExchangePoolUnitCardClick()
    logger:logDebug("onUnitExchangePoolUnitCardClick(): STARTED")

    -- Each time a unit exchange unit card is clicked, we need to go through each unit exchange pool
    -- to see which units are selected and which are not.
    -- This is because the user can select multiple unit cards at once using SHIFT + Click,
    -- we have no other way to know which cards have been added to the selection.
    self:updateUnitExchangeArmySuppliesCosts()

    logger:logDebug("onUnitExchangePoolUnitCardClick(): COMPLETED")
end

---Reacts to a unit being destroyed after having been merged with another unit.
---@param unitKey string Unit key.
---@param unitCqi integer Unit command queue index.
function TotoWar_Cbac_PlayerManager:onUnitMergedAndDestroyed(unitKey, unitCqi)
    logger:logDebug(
        "onUnitMergedAndDestroyed(%s, %s): STARTED => %s | Unit: %s",
        unitKey,
        unitCqi,
        function() return TotoWar__Gameplay:getCharacterFullCaption(self.selectedLord) end,
        function() return TotoWar__Gameplay:getUnitCaption(unitKey) end)

    self.selectedLordArmySuppliesCost:removeUnit(unitKey, unitCqi)

    -- Signaling army supplies cost change
    TotoWar__EventsManager:trigger(TotoWar_Cbac_Enum_ModEvents.selectedLordArmySuppliesCostChanged)

    logger:logDebug(
        "onUnitMergedAndDestroyed(%s, %s): COMPLETED => %s | Unit: %s | Total cost: %s | Available supplies: %s",
        unitKey,
        unitCqi,
        function() return TotoWar__Gameplay:getCharacterFullCaption(self.selectedLord) end,
        function() return TotoWar__Gameplay:getUnitCaption(unitKey) end,
        self.selectedLordArmySuppliesCost.totalCost,
        self.selectedLordArmySuppliesCost.availableSupplies)
end

---Reacts to a unit being removed from the recruitment queue of the selected lord army.
function TotoWar_Cbac_PlayerManager:onUnitRemovedFromRecruitment(unitKey)
    logger:logDebug(
        "onUnitRemovedFromRecruitment(%s): STARTED => %s | Unit: %s",
        unitKey,
        function() return TotoWar__Gameplay:getCharacterFullCaption(self.selectedLord) end,
        function() return TotoWar__Gameplay:getUnitCaption(unitKey) end)

    self.selectedLordArmySuppliesCost:removeUnit(unitKey)

    -- Signaling army supplies cost change
    TotoWar__EventsManager:trigger(TotoWar_Cbac_Enum_ModEvents.selectedLordArmySuppliesCostChanged)

    logger:logDebug(
        "onUnitRemovedFromRecruitment(%s): COMPLETED => %s | Unit: %s | Total cost: %s | Available supplies: %s",
        unitKey,
        function() return TotoWar__Gameplay:getCharacterFullCaption(self.selectedLord) end,
        function() return TotoWar__Gameplay:getUnitCaption(unitKey) end,
        self.selectedLordArmySuppliesCost.totalCost,
        self.selectedLordArmySuppliesCost.availableSupplies)
end

---Reacts to a unit of the selected lord army being upgraded (warband upgrade).
---@param unit UNIT_SCRIPT_INTERFACE Upgraded unit, which replaces the unit before the upgrade.
function TotoWar_Cbac_PlayerManager:onUnitUpgraded(unit)
    logger:logDebug(
        "onUnitUpgraded(%s): STARTED => %s",
        function() return unit:command_queue_index() end,
        function() return TotoWar__Gameplay:getArmyCaption(unit:military_force()) end)

    -- Never nil: the subscription condition of this method checks that a lord is selected
    local lord = self.selectedLord
    ---@cast lord CHARACTER_SCRIPT_INTERFACE

    -- The game replaces the upgraded unit by a new unit (with a new command queue index), and triggers this event
    -- once the army has been updated, on all the machines: the army supplies cost is recalculated from the army.
    -- When several units are upgraded at once, the event is triggered for each of them and only the last calculation
    -- includes all the upgraded units
    self:initializeArmySuppliesCost(lord)

    logger:logDebug(
        "onUnitUpgraded(%s): COMPLETED => %s | Unit: %s",
        function() return unit:command_queue_index() end,
        function() return TotoWar__Gameplay:getArmyCaption(unit:military_force()) end,
        function() return TotoWar__Gameplay:getUnitCaption(unit:unit_key()) end)
end

---Reacts to a unit card or a warband upgrade being clicked when the Warband Upgrade panel is open.
function TotoWar_Cbac_PlayerManager:onWarbandUpgradeUnitClicked()
    logger:logDebug(
        "onWarbandUpgradeUnitClicked(): STARTED => %s",
        function()
            return
                self.selectedLord ~= nil
                and TotoWar__Gameplay:getArmyCaption(self.selectedLord:military_force())
                or "No selected lord"
        end)

    self:updateWarbandUpgradeArmySupplies()

    logger:logDebug(
        "onWarbandUpgradeUnitClicked(): COMPLETED => %s",
        function()
            return
                self.selectedLord ~= nil
                and TotoWar__Gameplay:getArmyCaption(self.selectedLord:military_force())
                or "No selected lord"
        end)
end

---Subscribes to events.
function TotoWar_Cbac_PlayerManager:subscribeToEvents()
    logger:logDebug("subscribeToEvents(): STARTED")

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_GameEvents.characterDeselected,
        function() self:onCharacterDeselected() end,
        function()
            -- We do not check the TotoWar_Cbac_Mod.options.playerArmySuppliesEnabled option because when this option
            -- is disabled, we deselect everything and we want onCharacterDeselected to be executed
            -- to reset the selected lord.
            return cm:is_local_players_turn(true)
        end)

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_GameEvents.characterSelected,
        ---@param context CharacterSelected
        function(context) self:onCharacterSelected(context:character()) end,
        function()
            return
                TotoWar_Cbac_Mod.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn(true)
        end)

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_GameEvents.componentLeftClick,
        ---@param context TotoWar__GameEventContext_ComponentLeftClick
        function(context) self:onInRecruitmentMercenaryUnitCardClick(context.string) end,
        ---@param context TotoWar__GameEventContext_ComponentLeftClick
        function(context)
            local isInRecruitmentMercenaryUnitCard =
                context.string:match(TotoWar__Enum_Patterns.inRecruitmentMercenaryUnitCard) ~= nil

            return
                self:isSelectedLordArmySuppliesCostAvailable()
                and isInRecruitmentMercenaryUnitCard
        end)

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_GameEvents.componentLeftClick,
        ---@param context TotoWar__GameEventContext_ComponentLeftClick
        function(context)
            local uiComponent = UIComponent(context.component)
            self:onRecruitableMercenaryUnitCardClick(context.string, uiComponent)
        end,
        ---@param context TotoWar__GameEventContext_ComponentLeftClick
        function(context)
            local uiComponent = UIComponent(context.component)

            -- A recruitable mercenary unit card is in the unit card list (list_box) of a recruitment pool (listview)
            -- of the mercenary panel. The name of the card is not used: it depends on the unit key, whose prefix
            -- differs for the units added by mods
            local isRecruitableMercenaryUnitCard =
                UIComponent(uiComponent:Parent()):Id() == "list_box"
                and TotoWar__UI:isUIComponentChildOf(uiComponent, { "mercenary_display", "listview" })

            return
                self:isSelectedLordArmySuppliesCostAvailable()
                and isRecruitableMercenaryUnitCard
        end)

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_GameEvents.componentLeftClick,
        function() self:onWarbandUpgradeUnitClicked() end,
        ---@param context TotoWar__GameEventContext_ComponentLeftClick
        function(context)
            if self.selectedLord == nil or not self:isSelectedLordArmySuppliesCostAvailable() then
                return false
            end

            local warbandUpgradesUIComponent = TotoWar__UI:findUIComponent(
                TotoWar__UI.uiComponentQueries.unitsPanel_warbandUpgrades)
            local isStandardUnitCard = context.string:match(TotoWar__Enum_Patterns.standardUnitCard) ~= nil
            local isWarbandUpgrade =
                TotoWar__String:startsWith(context.string, "CcoMainUnitRecord")
                and TotoWar__UI:isUIComponentChildOf(
                    UIComponent(context.component),
                    { "warband_upgrades", "body", "upgrade_tree", "slot_parent" })

            return
                warbandUpgradesUIComponent ~= nil
                and warbandUpgradesUIComponent:Visible(true)
                and (isStandardUnitCard or isWarbandUpgrade)
        end)

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_GameEvents.componentLeftClick,
        function() self:onUnitExchangePoolUnitCardClick() end,
        ---@param context TotoWar__GameEventContext_ComponentLeftClick
        function(context)
            if TotoWar_Cbac_Mod.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn(true)
                and (string.match(context.string, TotoWar__Enum_Patterns.unitExchangeHeroCard)
                    or string.match(context.string, TotoWar__Enum_Patterns.unitExchangeUnitCard))
            then
                local uiComponent = UIComponent(context.component)

                return TotoWar__UI:isUIComponentChildOf(uiComponent, { "unit_exchange" })
            end

            return false
        end)

    -- The click on the confirmation button is received after the unit exchange panel is closed:
    -- the costs of the unit exchange are kept after the panel is closed, and recalculated when it is opened again
    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_GameEvents.componentLeftClick,
        function() self:onUnitExchangeConfirmed() end,
        ---@param context TotoWar__GameEventContext_ComponentLeftClick
        function(context)
            return
                self:isSelectedLordArmySuppliesCostAvailable()
                and self.selectedLord ~= nil
                and self.unitExchangeArmySuppliesCost1 ~= nil
                and self.unitExchangeArmySuppliesCost2 ~= nil
                and context.string == "button_ok"
                and TotoWar__UI:isUIComponentChildOf(
                    UIComponent(context.component),
                    { "unit_exchange", "hud_center_docker", "ok_cancel_buttongroup" })
        end)

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_ModEvents.optionsUpdated,
        function() onPlayerArmySuppliesDisabled() end,
        function() return TotoWar_Cbac_Mod.options.playerArmySuppliesEnabled == false end)

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_GameEvents.panelClosed,
        function() self:onMercenaryRecruitmentPanelClosed() end,
        ---@param context TotoWar__GameEventContext_PanelOpenedOrClosed
        function(context)
            return
                self:isSelectedLordArmySuppliesCostAvailable()
                and context.string == TotoWar__Enum_Panels.mercenaryRecruitment
        end)

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_GameEvents.panelOpened,
        function() self:onMercenaryRecruitmentPanelOpened() end,
        ---@param context TotoWar__GameEventContext_PanelOpenedOrClosed
        function(context)
            return
                self:isSelectedLordArmySuppliesCostAvailable()
                and context.string == TotoWar__Enum_Panels.mercenaryRecruitment
        end)

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_GameEvents.panelOpened,
        function() self:onUnitExchangePanelOpened() end,
        ---@param context TotoWar__GameEventContext_PanelOpenedOrClosed
        function(context)
            return
                TotoWar_Cbac_Mod.options.playerArmySuppliesEnabled
                and cm:is_local_players_turn(true)
                and context.string == TotoWar__Enum_Panels.unitExchange
        end)

    TotoWar__EventsManager:subscribe(
        TotoWar_Cbac_Enum_ModEvents.selectedLordArmySuppliesCostChanged,
        function() self:onSelectedLordArmySuppliesCostChanged() end,
        function() return self:isSelectedLordArmySuppliesCostAvailable() end)

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_GameEvents.unitAddedToRecruitment,
        ---@param context TotoWar__GameEventContext_UnitAddedToRecruitment
        function(context)
            ---@type string
            local unitKey = context:main_unit_record()
            self:onUnitAddedToRecruitment(unitKey, false)
        end,
        ---@param context TotoWar__GameEventContext_UnitAddedToRecruitment
        function(context)
            return
                self:isSelectedLordArmySuppliesCostAvailable()
                and TotoWar__Gameplay:isLocalPlayerFaction(context:faction():name())
        end)

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_GameEvents.unitDisbanded,
        ---@param context TotoWar__GameEventContext_UnitDisbanded
        function(context)
            local unit = context:unit()
            self:onUnitDisbanded(unit:unit_key(), unit:command_queue_index())
        end,
        ---@param context TotoWar__GameEventContext_UnitDisbanded
        function(context)
            local army = context:unit():military_force()

            return
                self:isSelectedLordArmySuppliesCostAvailable()
                and self.selectedLord ~= nil
                and army:has_general()
                and army:general_character():cqi() == self.selectedLord:cqi()
        end)

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_GameEvents.unitMergedAndDestroyed,
        ---@param context TotoWar__GameEventContext_UnitMergedAndDestroyed
        function(context)
            local unit = context:unit()
            self:onUnitMergedAndDestroyed(unit:unit_key(), unit:command_queue_index())
        end,
        ---@param context TotoWar__GameEventContext_UnitMergedAndDestroyed
        function(context)
            local army = context:unit():military_force()

            return
                self:isSelectedLordArmySuppliesCostAvailable()
                and self.selectedLord ~= nil
                and army:has_general()
                and army:general_character():cqi() == self.selectedLord:cqi()
        end)

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_GameEvents.unitRemovedFromRecruitment,
        ---@param context TotoWar__GameEventContext_UnitRemovedFromRecruitment
        function(context) self:onUnitRemovedFromRecruitment(context:main_unit_record()) end,
        ---@param context TotoWar__GameEventContext_UnitRemovedFromRecruitment
        function(context)
            return
                self:isSelectedLordArmySuppliesCostAvailable()
                and TotoWar__Gameplay:isLocalPlayerFaction(context:faction():name())
        end)

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_GameEvents.unitTrained,
        ---@param context TotoWar__GameEventContext_UnitTrained
        function(context)
            local unit = context:unit()
            self:onMercenaryUnitsRecruited(unit:unit_key(), unit:command_queue_index())
        end,
        ---@param context TotoWar__GameEventContext_UnitTrained
        function(context)
            -- A unit trained in the army of the selected lord comes from the recruitment button
            -- of the mercenary panel
            local army = context:unit():military_force()

            return
                self:isSelectedLordArmySuppliesCostAvailable()
                and self.selectedLord ~= nil
                and army:has_general()
                and army:general_character():cqi() == self.selectedLord:cqi()
        end)

    TotoWar__EventsManager:subscribe(
        TotoWar__Enum_GameEvents.unitUpgraded,
        ---@param context TotoWar__GameEventContext_UnitUpgraded
        function(context) self:onUnitUpgraded(context:unit()) end,
        ---@param context TotoWar__GameEventContext_UnitUpgraded
        function(context)
            local army = context:unit():military_force()

            return
                self:isSelectedLordArmySuppliesCostAvailable()
                and self.selectedLord ~= nil
                and army:has_general()
                and army:general_character():cqi() == self.selectedLord:cqi()
        end)

    -- Received on all the machines, including the one of the player who sent the request
    TotoWar__EventsManager:subscribeMultiplayer(
        TotoWar_Cbac_Enum_ModEvents.mpArmyMovementUpdateRequested,
        function(factionCqi, dataString) onArmyMovementUpdateRequested(factionCqi, dataString) end,
        function() return TotoWar_Cbac_Mod.options.playerArmySuppliesEnabled end)

    logger:logDebug("subscribeToEvents(): COMPLETED")
end

---Updates the ability to move of the army of the selected lord depending on its army supplies cost.
---The update is requested to all the machines of the game, and made by `onArmyMovementUpdateRequested` when they receive the request.
function TotoWar_Cbac_PlayerManager:updateSelectedLordMovement()
    logger:logDebug(
        "updateSelectedLordMovement(): STARTED => %s | Available supplies: %s",
        function()
            return
                self.selectedLord ~= nil
                and TotoWar__Gameplay:getArmyCaption(self.selectedLord:military_force())
                or "No selected lord"
        end,
        self.selectedLordArmySuppliesCost.availableSupplies)

    local army = self.selectedLord:military_force()
    local armyCqi = army:command_queue_index()
    local isBlocked = self.selectedLordArmySuppliesCost.availableSupplies < 0
    local lastRequest = self.lastMovementRequests[armyCqi]

    -- This method reacts to the interface of the local player (selection, clicks, recruitment), so changing the game
    -- here would only change it on this machine and desynchronize a multiplayer game.
    -- The decision is sent to all the machines, and onArmyMovementUpdateRequested applies or removes the effect bundle on each of them.
    -- For example, when the player recruits a unit that exceeds the army supplies, the request "<army cqi>|1" is sent,
    -- and the army is blocked on all the machines a fraction of a second later.
    -- The last request is also compared because it may not have been executed yet in a scenario where a rapid succession of UI actions are performed.
    -- Sending a request twice is harmless because onArmyMovementUpdateRequested only applies it once.
    if army:has_effect_bundle(TotoWar_Cbac_Constant.armySuppliesExceededEffectBundleKey) ~= isBlocked
        or (lastRequest ~= nil and lastRequest ~= isBlocked)
    then
        logger:logDebug(
            "updateSelectedLordMovement(): REQUEST SENT => %s | Available supplies: %s | Blocked: %s | Last request: %s",
            function() return TotoWar__Gameplay:getArmyCaption(army) end,
            self.selectedLordArmySuppliesCost.availableSupplies,
            isBlocked,
            lastRequest)

        self.lastMovementRequests[armyCqi] = isBlocked

        TotoWar__EventsManager:triggerMultiplayer(
            army:faction():command_queue_index(),
            TotoWar_Cbac_Enum_ModEvents.mpArmyMovementUpdateRequested,
            string.format("%d|%d", armyCqi, isBlocked and 1 or 0))
    end

    logger:logDebug(
        "updateSelectedLordMovement(): COMPLETED => %s | Available supplies: %s",
        function()
            return
                self.selectedLord ~= nil
                and TotoWar__Gameplay:getArmyCaption(self.selectedLord:military_force())
                or "No selected lord"
        end,
        self.selectedLordArmySuppliesCost.availableSupplies)
end

---Updates unit exchange army supplies costs.
function TotoWar_Cbac_PlayerManager:updateUnitExchangeArmySuppliesCosts()
    logger:logDebug("updateUnitExchangeArmySuppliesCosts(): STARTED")

    local unitCards1 = TotoWar_Cbac_UIManager:getUnitExchangePoolCards(TotoWar__UI.uiComponentQueries.unitExchange_pool1)
    local unitCards2 = TotoWar_Cbac_UIManager:getUnitExchangePoolCards(TotoWar__UI.uiComponentQueries.unitExchange_pool2)

    local lord1 = getLordInUnitExchangePoolCards(unitCards1)
    local lord1Rank = 1
    local lord2 = getLordInUnitExchangePoolCards(unitCards2)
    local lord2Rank = 1

    if lord1 ~= nil then
        lord1Rank = lord1:rank()
    end

    if lord2 ~= nil then
        lord2Rank = lord2:rank()
    end

    self.unitExchangeArmySuppliesCost1 = TotoWar_Cbac_ArmySuppliesCost.new(false, lord1Rank)
    self.unitExchangeArmySuppliesCost2 = TotoWar_Cbac_ArmySuppliesCost.new(false, lord2Rank)

    addUnitExchangePoolCards(unitCards1, self.unitExchangeArmySuppliesCost1, self.unitExchangeArmySuppliesCost2)
    addUnitExchangePoolCards(unitCards2, self.unitExchangeArmySuppliesCost2, self.unitExchangeArmySuppliesCost1)

    -- Signaling unit exchange army supplies cost change
    TotoWar__EventsManager:trigger(TotoWar_Cbac_Enum_ModEvents.unitExchangeArmySuppliesCostChanged)

    logger:logDebug("updateUnitExchangeArmySuppliesCosts(): COMPLETED")
end

---Updates the army supplies displayed in the Warband Upgrade panel.
function TotoWar_Cbac_PlayerManager:updateWarbandUpgradeArmySupplies()
    logger:logDebug(
        "updateWarbandUpgradeArmySupplies(): STARTED => %s",
        function()
            return
                self.selectedLord ~= nil
                and TotoWar__Gameplay:getArmyCaption(self.selectedLord:military_force())
                or "No selected lord"
        end)

    local unitToUpgradeUiComponent = TotoWar__UI:findUIComponent(
        TotoWar__UI.uiComponentQueries.unitsPanel_warbandUpgradesUnitToUpgrade)
    local upgradedUnitUiComponent = TotoWar__UI:findUIComponent(
        TotoWar__UI.uiComponentQueries.unitsPanel_warbandUpgradesUpgradedUnit)

    if unitToUpgradeUiComponent == nil
        or upgradedUnitUiComponent == nil
        or not unitToUpgradeUiComponent:Visible(true)
        or not upgradedUnitUiComponent:Visible(true)
    then
        logger:logDebug(
            "updateWarbandUpgradeArmySupplies(): COMPLETED => %s | %s",
            function()
                return
                    self.selectedLord ~= nil
                    and TotoWar__Gameplay:getArmyCaption(self.selectedLord:military_force())
                    or "No selected lord"
            end,
            "Not calculated, no unit selected for upgrade")

        return
    end

    -- Getting the unit type to upgrade
    local objectContextId = unitToUpgradeUiComponent:GetContextObjectId(TotoWar__Enum_CcoContextTypeIds.campaignUnit)

    if objectContextId == nil then
        logger:logWarning(
            "Warband upgrade: unit to upgrade not found, army supplies after the upgrade not displayed")
        logger:logDebug(
            "updateWarbandUpgradeArmySupplies(): COMPLETED => %s | Not calculated, unit to upgrade not found",
            function()
                return
                    self.selectedLord ~= nil
                    and TotoWar__Gameplay:getArmyCaption(self.selectedLord:military_force())
                    or "No selected lord"
            end)

        return
    end

    ---@type string
    local unitToUpgradeKey = common.get_context_value(
        TotoWar__Enum_CcoContextTypeIds.campaignUnit,
        objectContextId,
        "UnitRecordContext.Key")

    -- Counting how many units of this type are selected
    local unitsToUpgradeCount = 0
    local unitsUIComponent = TotoWar__UI:getUIComponent(TotoWar__UI.uiComponentQueries.unitsPanel_units)

    -- Getting the number of units selected
    for i = 0, unitsUIComponent:ChildCount() - 1, 1 do
        local unitCardUIComponent = find_child_uicomponent_by_index(unitsUIComponent, i)

        local isInRecruitmentStandardUnitCard =
            unitCardUIComponent:Id():match(TotoWar__Enum_Patterns.standardUnitCard) ~= nil

        if TotoWar__UI:isUIComponentSelected(unitCardUIComponent) and isInRecruitmentStandardUnitCard
        then
            local unitKey = TotoWar__UI:getUnitCardUnitKey(unitCardUIComponent)

            if unitKey == unitToUpgradeKey then
                unitsToUpgradeCount = unitsToUpgradeCount + 1
            end
        end
    end

    -- Getting the army supplies cost without the units that are selected to be upgraded
    local unitsNotToInclude = unitsToUpgradeCount
    self.warbandUpgradeArmySuppliesCost = TotoWar_Cbac_ArmySuppliesCost.new(
        false,
        self.selectedLordArmySuppliesCost.lordLevel)

    for index, unitArmySuppliesCost in ipairs(self.selectedLordArmySuppliesCost.unitArmySuppliesCosts) do
        if unitArmySuppliesCost.unitKey == unitToUpgradeKey and unitsNotToInclude > 0 then
            unitsNotToInclude = unitsNotToInclude - 1
        elseif unitArmySuppliesCost.characterCqi ~= nil then
            self.warbandUpgradeArmySuppliesCost:addCharacter(unitArmySuppliesCost.characterCqi)
        else
            self.warbandUpgradeArmySuppliesCost:addUnit(
                unitArmySuppliesCost.unitKey,
                unitArmySuppliesCost.unitCqi,
                false)
        end
    end

    -- Getting the upgraded unit type
    local upgradedUnitContext = TotoWar__UI:getUIComponentCCO(
        upgradedUnitUiComponent,
        TotoWar__Enum_CcoContextTypeIds.mainUnitRecord)

    ---@type string
    local upgradedUnitKey = upgradedUnitContext:Call("Key")

    -- Adding the upgraded unit cost to the army supplies cost
    for i = 1, unitsToUpgradeCount, 1 do
        self.warbandUpgradeArmySuppliesCost:addUnit(upgradedUnitKey)
    end

    -- Sending an event to update the warband upgrade UI with the upgraded army supplies cost
    TotoWar__EventsManager:trigger(TotoWar_Cbac_Enum_ModEvents.warbandUpgradeArmySuppliesCostChanged)

    logger:logDebug(
        "updateWarbandUpgradeArmySupplies(): COMPLETED => %s | %s",
        function()
            return
                self.selectedLord ~= nil
                and TotoWar__Gameplay:getArmyCaption(self.selectedLord:military_force())
                or "No selected lord"
        end,
        function()
            if self.warbandUpgradeArmySuppliesCost ~= nil then
                return self.warbandUpgradeArmySuppliesCost.totalCost
            end

            return "Not calculated"
        end)
end
