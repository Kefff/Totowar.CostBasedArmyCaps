---Component context object type IDs.
---@class TotoWar__Enum_CcoContextTypeIds
TotoWar__Enum_CcoContextTypeIds = {
    ---Character. ID: character CQI.
    campaignCharacter = "CcoCampaignCharacter",

    ---Unit. ID: unit CQI.
    campaignUnit = "CcoCampaignUnit",

    -- Faction. ID: faction CQI.
    factionRecord = "CcoFactionRecord",

    ---Main unit record. ID: unit key.
    mainUnitRecord = "CcoMainUnitRecord"
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

---Factions.
---@class TotoWar__Enum_Factions
TotoWar__Enum_Factions = {
    beastmen = "wh_dlc03_bst_beastmen",
    bretonnia = "wh_main_brt_bretonnia",
    cathay = "wh3_main_cth_cathay",
    chaos = "wh_main_chs_chaos",
    chaosDwarfs = "wh3_dlc23_chd_chaos_dwarfs",
    daemons = "wh3_main_dae_daemons",
    darkElves = "wh2_main_def_dark_elves",
    dwarfs = "wh_main_dwf_dwarfs",
    empire = "wh_main_emp_empire",
    greenskins = "wh_main_grn_greenskins",
    highElves = "wh2_main_hef_high_elves",
    khorne = "wh3_main_kho_khorne",
    kislev = "wh3_main_ksl_kislev",
    kislevPrologue = "wh3_main_pro_ksl_kislev",
    lizardmen = "wh2_main_lzd_lizardmen",
    norsca = "wh_dlc08_nor_norsca",
    nurgle = "wh3_main_nur_nurgle",
    ogreKingdoms = "wh3_main_ogr_ogre_kingdoms",
    rogue = "wh2_main_rogue",
    skaven = "wh2_main_skv_skaven",
    slaanesh = "wh3_main_sla_slaanesh",
    tombKings = "wh2_dlc09_tmb_tomb_kings",
    tzeench = "wh3_main_tze_tzeentch",
    vampireCoast = "wh2_dlc11_cst_vampire_coast",
    vampireCounts = "wh_main_vmp_vampire_counts",
    woodElves = "wh_dlc05_wef_wood_elves"
}

---Events triggered by the game.
---@class TotoWar__Enum_GameEvents
TotoWar__Enum_GameEvents = {
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

    --Event triggered by one player's game to activate a change across all players' games.
    --It is primarily used to synchronize the game state among all connected players.
    multiplayerEventTriggered = "UITrigger",

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
---@class TotoWar__Enum_LogSeverities
TotoWar__Enum_LogSeverities = {
    debug = "DEBUG",
    info = "INFO",
    warning = "WARN",
    error = "ERROR"
}

---Events triggered by the mod.
---@class TotoWar__Enum_ModEvents
TotoWar__Enum_ModEvents = {
    ---Event triggered when the events manager has been initialized to indicate to loggers,
    ---which are instaciated before, that they can now subscribe to events.
    eventsManagerInitialized = "TotoWar__EventsManagerInitialized",

    ---Event triggered when options are updated in the Mod Configuration Tool if it is installed.
    mctOptionsUpdated = "MctFinalized",

    ---Event triggered when options are updated.
    ---This differs from `mctOptionsUpdated` as it is used to signal that TotoWar option values
    ---have been updated by reading values from the Mod Configuration Tool.
    optionsUpdated = "TotoWar__OptionsUpdated"
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

    ---Pattern for identifying a UI component corresponding to the unit card of a unit in the selected army.
    standardUnitCard = "^LandUnit",

    ---Pattern for identifying a UI component corresponding to the unit card of an hero during unit exchange.
    unitExchangeHeroCard = "^HeroCard",

    ---Pattern for identifying a UI component corresponding to a unit card during unit exchange.
    unitExchangeUnitCard = "^UnitCard"
}

---UI component states.
---@class TotoWar__Enum_UIComponentStates
TotoWar__Enum_UIComponentStates = {
    ---Active.
    active = "active",

    ---Inactive.
    inactive = "inactive",

    ---Selected.
    selected = "selected",

    ---Selected and hovered.
    selectedHover = "selected_hover"
}
