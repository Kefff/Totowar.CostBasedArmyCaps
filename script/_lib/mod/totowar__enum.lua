---Component context object type IDs.
---@class TotoWar__Enum_CcoContextTypeIds
TotoWar__Enum_CcoContextTypeIds = {
    ---Character. ID: character CQI.
    campaignCharacter = "CcoCampaignCharacter",

    ---Unit. ID: unit CQI.
    campaignUnit = "CcoCampaignUnit",

    ---Main unit record. ID: unit key.
    mainUnitRecord = "CcoMainUnitRecord"
}

---Colors.
---@class TotoWar__Enum_CharacterTypes
TotoWar__Enum_CharacterTypes = {
    lord = "lord"
}

---Events triggered by the game.
---@class TotoWar__Enum_GameEvent
TotoWar__Enum_GameEvent = {
    ---Event triggered when an army changes its stance.
    armyStanceChanged = "ForceAdoptsStance",

    ---Event triggered when a character is deselected.
    ---Is not triggered when a character is already selected and the player selects another character.
    characterDeselected = "CharacterDeselected",

    ---Event triggered when a character is selected.
    characterSelected = "CharacterSelected",

    ---Event triggered when the turn of a character ends.
    characterTurnEnd = "CharacterTurnEnd",

    ---Event triggered when the left click on a UI component is released.
    componentLeftClick = "ComponentLClickUp",

    --Event triggered when the turn of a faction starts.
    factionTurnStart = "FactionTurnStart",

    --Event triggered when an army is created.
    militaryForceCreated = "MilitaryForceCreated",

    ---Event triggered when a panel is opened.
    panelOpened = "PanelOpenedCampaign",

    ---Event triggered when a panel is closed.
    panelClosed = "PanelClosedCampaign",

    ---Event triggered when a unit is removed from the recruitment queue.
    unitRemovedFromRecruitment = "RecruitmentItemCancelledByPlayer",

    ---Event triggered when a unit is added to the recruitment queue.
    unitAddedToRecruitment = "RecruitmentItemIssuedByPlayer",

    ---Event triggered when a unit have been converted.
    unitConverted = "UnitConverted",

    ---Event triggered when a unit have been created.
    unitCreated = "UnitCreated",

    ---Event triggered when a unit have been disbanded.
    unitDisbanded = "UnitDisbanded",

    ---Event triggered when units are merged unit and some of them have been destroyed.
    unitMergedAndDestroyed = "UnitMergedAndDestroyed",

    ---Event triggered when a unit is added to an army.
    unitTrained = "UnitTrained",

    ---Event triggered when a unit have been upgraded.
    unitUpgraded = "UnitUpgraded"
}

---Log severities.
---@class TotoWar__Enum_LogSeverity
TotoWar__Enum_LogSeverity = {
    debug = "DEBUG",
    info = "INFO",
    warning = "WARN",
    error = "ERROR"
}

---Events triggered by the mod.
---@class TotoWar__Enum_ModEvents
TotoWar__Enum_ModEvents = {
    ---Event triggered when options are updated in the Mod Configuration Tool if it is installed.
    mctOptionsUpdated = "MctFinalized",

    ---Event triggered when options are updated.
    ---This differs from `mctOptionsUpdated` as it is used to signal that TotoWar option values
    ---have been updated by reading values from the Mod Configuration Tool.
    optionsUpdated = "TotoWar_OptionsUpdated"
}

---UI component states.
---@class TotoWar__Enum_UIComponentStates
TotoWar__Enum_UIComponentStates = {
    ---Active.
    active = "active",

    ---Inactive.
    inactive = "inactive",

    ---Selected.
    selected = "selected"
}

---Docking points.
---@class TotoWar__Enum_DockingPoints
TotoWar__Enum_DockingPoints = {
    topLeft = 1,
    topMiddle = 2,
    topRight = 3,
    middleLeft = 4,
    center = 5,
    middleRight = 6,
    bottomLeft = 7,
    bottomMiddle = 8,
    bottomRight = 9
}

---Panels.
---@class TotoWar__Enum_Panels
TotoWar__Enum_Panels = {
    ---Mercenary recruitment panel (allied recruitment, units of renown, dwarf grudge settlers, Waaagh mobs, ...)
    mercenaryRecruitment = "mercenary_recruitment",

    ---Panel that contains the recruitment panels
    recruitmentOptions = "recruitment_options",

    ---Standard recruitment panel
    standardRecruitment = "units_recruitment",

    ---Panel that allows to exchange units between armies.
    unitExchange = "unit_exchange",

    ---Selected army unit list panel.
    unitsPanel = "units_panel"
}

---Patterns for finding UI elements.
---@class TotoWar__Enum_Patterns
TotoWar__Enum_Patterns = {
    ---Pattern for identifying a UI component corresponding to the unit card of a recruitable mercenary
    ---unit (regiment of renown, Waaagh mobs, Grudge settlers, ...).
    inRecruitmentMercenaryUnitCard = "^temp_merc_",

    ---Pattern for identifying a UI component corresponding to the unit card of recruitable standard
    ---unit in the selected army recruitment queue.
    inRecruitmentStandardUnitCard = "^QueuedLandUnit",

    ---Pattern for identifying a UI component corresponding to the unit card of a mercenary
    ---unit (regiment of renown, Waaagh mobs, Grudge settlers, ...) in the selected army recruitment
    ---queue.
    recruitableMercenaryUnitCard = "^wh%d*_.*_mercenary$",

    ---Pattern for identifying a UI component corresponding to the unit card of an hero during unit exchange.
    unitExchangeHeroCard = "^HeroCard",

    ---Pattern for identifying a UI component corresponding to a unit card during unit exchange.
    unitExchangeUnitCard = "^UnitCard"
}
