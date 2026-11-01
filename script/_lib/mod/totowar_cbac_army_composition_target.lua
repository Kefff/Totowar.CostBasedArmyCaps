require("script._lib.mod.totowar_cbac_constant")
require("script._lib.mod.totowar_cbac_enum")

---@type TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategories, integer>
local beastmen = TotoWar__Dictionary.new()
beastmen:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.warMachines, 10)

---@type TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategories, integer>
local chaos = TotoWar__Dictionary.new()
chaos:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.rangedInfantry, 10) -- Extended roster

---@type TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategories, integer>
local default = TotoWar__Dictionary.new()
default:set(
    TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.cavalryAndMonsters,
    TotoWar_Cbac_Constant.optionDefaultValue_aiArmyCavalryAndMonstersMaximumPercentage)
default:set(
    TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.hero,
    TotoWar_Cbac_Constant.optionDefaultValue_aiArmyHeroMaximumPercentage)
default:set(
    TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.meleeInfantry,
    TotoWar_Cbac_Constant.optionDefaultValue_aiArmyMeleeInfantryMaximumPercentage)
default:set(
    TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.rangedInfantry,
    TotoWar_Cbac_Constant.optionDefaultValue_aiArmyRangedInfantryMaximumPercentage)
default:set(
    TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.warMachines,
    TotoWar_Cbac_Constant.optionDefaultValue_aiArmyWarMachinesMaximumPercentage)

---@type TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategories, integer>
local dwarfs = TotoWar__Dictionary.new()
dwarfs:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.cavalryAndMonsters, 10) -- Extended roster

---@type TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategories, integer>
local khorne = TotoWar__Dictionary.new()
khorne:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.rangedInfantry, 10)

---@type TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategories, integer>
local lizardmen = TotoWar__Dictionary.new()
lizardmen:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.warMachines, 10)

---@type TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategories, integer>
local norsca = TotoWar__Dictionary.new()
norsca:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.warMachines, 10) -- Extended roster

---@type TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategories, integer>
local nurgle = TotoWar__Dictionary.new()
nurgle:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.rangedInfantry, 10) -- Extended roster
nurgle:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.warMachines, 10)    -- Extended roster

---@type TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategories, integer>
local slaanesh = TotoWar__Dictionary.new()
slaanesh:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.warMachines, 10)

---@type TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategories, integer>
local tzeench = TotoWar__Dictionary.new()
tzeench:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.warMachines, 10)

---@type TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategories, integer>
local vampireCounts = TotoWar__Dictionary.new()
vampireCounts:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.rangedInfantry, 10) -- Extended roster

---@type TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategories, integer>
local woodElves = TotoWar__Dictionary.new()
woodElves:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategories.warMachines, 10)

---Army compositions to target based on the culture of the faction.
---
---Those are the maximum percentage of each unit category an AI army can contain.
---
---The "default" entry applies to every culture. Its percentages are replaced by the MCT options when MCT is installed.
---
---Culture entries are caps for unit categories in which the culture has few or no units of its own.
---Such units can still come from allied recruitment, mercenaries, confederations, etc., so a cap keeps a small share of
---them instead of disbanding them all.
---- The percentage used is the lowest between the default percentage and the cap: a cap never raises the MCT value.
---- The percentage removed by caps is shared between the other categories, excluding lords, heroes and capped categories.
---@type TotoWar__Dictionary<TotoWar__Enum_Cultures, TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategories, integer>>
TotoWar_Cbac_ArmyCompositionTarget = TotoWar__Dictionary.new()
TotoWar_Cbac_ArmyCompositionTarget:set(TotoWar__Enum_Cultures.beastmen, beastmen)
TotoWar_Cbac_ArmyCompositionTarget:set(TotoWar__Enum_Cultures.chaos, chaos)
---@diagnostic disable-next-line: param-type-mismatch
TotoWar_Cbac_ArmyCompositionTarget:set("default", default)
TotoWar_Cbac_ArmyCompositionTarget:set(TotoWar__Enum_Cultures.dwarfs, dwarfs)
TotoWar_Cbac_ArmyCompositionTarget:set(TotoWar__Enum_Cultures.khorne, khorne)
TotoWar_Cbac_ArmyCompositionTarget:set(TotoWar__Enum_Cultures.lizardmen, lizardmen)
TotoWar_Cbac_ArmyCompositionTarget:set(TotoWar__Enum_Cultures.norsca, norsca)
TotoWar_Cbac_ArmyCompositionTarget:set(TotoWar__Enum_Cultures.nurgle, nurgle)
TotoWar_Cbac_ArmyCompositionTarget:set(TotoWar__Enum_Cultures.slaanesh, slaanesh)
TotoWar_Cbac_ArmyCompositionTarget:set(TotoWar__Enum_Cultures.tzeench, tzeench)
TotoWar_Cbac_ArmyCompositionTarget:set(TotoWar__Enum_Cultures.vampireCounts, vampireCounts)
TotoWar_Cbac_ArmyCompositionTarget:set(TotoWar__Enum_Cultures.woodElves, woodElves)
