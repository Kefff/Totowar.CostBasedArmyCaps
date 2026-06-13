require("script._lib.mod.totowar__dictionary")
require("script._lib.mod.totowar_cbac_constant")
require("script._lib.mod.totowar_cbac_enum")

---@type TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategory, integer>
local default = TotoWar__Dictionary.new()
default:set(
    TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.cavalryAndMonsters,
    TotoWar_Cbac_Constant.optionDefaultValue_aiArmyCavalryAndMonstersMaximumPercentage)
default:set(
    TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.hero,
    TotoWar_Cbac_Constant.optionDefaultValue_aiArmyHeroMaximumPercentage)
default:set(
    TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.meleeInfantry,
    TotoWar_Cbac_Constant.optionDefaultValue_aiArmyMeleeInfantryMaximumPercentage)
default:set(
    TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.rangedInfantry,
    TotoWar_Cbac_Constant.optionDefaultValue_aiArmyRangedInfantryMaximumPercentage)
default:set(
    TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.warMachines,
    TotoWar_Cbac_Constant.optionDefaultValue_aiArmyWarMachinesMaximumPercentage)

---@type TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategory, integer>
local beastmen = TotoWar__Dictionary.new()
beastmen:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.warMachines, 0)

---@type TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategory, integer>
local chaos = TotoWar__Dictionary.new()
chaos:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.rangedInfantry, 0)

---@type TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategory, integer>
local dwarfs = TotoWar__Dictionary.new()
dwarfs:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.cavalryAndMonsters, 0)

---@type TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategory, integer>
local khorne = TotoWar__Dictionary.new()
khorne:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.rangedInfantry, 0)

---@type TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategory, integer>
local lizardmen = TotoWar__Dictionary.new()
lizardmen:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.warMachines, 0)

---@type TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategory, integer>
local norsca = TotoWar__Dictionary.new()
norsca:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.warMachines, 0)

---@type TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategory, integer>
local nurgle = TotoWar__Dictionary.new()
nurgle:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.rangedInfantry, 0)
nurgle:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.warMachines, 0)

---@type TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategory, integer>
local slaanesh = TotoWar__Dictionary.new()
slaanesh:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.warMachines, 0)

---@type TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategory, integer>
local tzeench = TotoWar__Dictionary.new()
tzeench:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.warMachines, 0)

---@type TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategory, integer>
local vampireCounts = TotoWar__Dictionary.new()
vampireCounts:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.rangedInfantry, 0)

---@type TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategory, integer>
local woodElves = TotoWar__Dictionary.new()
woodElves:set(TotoWar_Cbac_Enum_ArmyCompositionUnitCategory.warMachines, 0)

---Army compositions to target based on the faction.
---
---Those are the maximum percentage of each unit category an AI army can contain.
---Most faction use the default composition, but some cultures or factions can have a specific composition to target when they do not have access to some unit types.
---@type TotoWar__Dictionary<TotoWar__Enum_Faction, TotoWar__Dictionary<TotoWar_Cbac_Enum_ArmyCompositionUnitCategory, integer>>
TotoWar_Cbac_ArmyCompositionTarget = TotoWar__Dictionary.new()
TotoWar_Cbac_ArmyCompositionTarget:set("default", default)
TotoWar_Cbac_ArmyCompositionTarget:set(TotoWar__Enum_Culture.beastmen, beastmen)
TotoWar_Cbac_ArmyCompositionTarget:set(TotoWar__Enum_Culture.chaos, chaos)
TotoWar_Cbac_ArmyCompositionTarget:set(TotoWar__Enum_Culture.dwarfs, dwarfs)
TotoWar_Cbac_ArmyCompositionTarget:set(TotoWar__Enum_Culture.khorne, khorne)
TotoWar_Cbac_ArmyCompositionTarget:set(TotoWar__Enum_Culture.lizardmen, lizardmen)
TotoWar_Cbac_ArmyCompositionTarget:set(TotoWar__Enum_Culture.norsca, norsca)
TotoWar_Cbac_ArmyCompositionTarget:set(TotoWar__Enum_Culture.nurgle, nurgle)
TotoWar_Cbac_ArmyCompositionTarget:set(TotoWar__Enum_Culture.slaanesh, slaanesh)
TotoWar_Cbac_ArmyCompositionTarget:set(TotoWar__Enum_Culture.tzeench, tzeench)
TotoWar_Cbac_ArmyCompositionTarget:set(TotoWar__Enum_Culture.vampireCounts, vampireCounts)
TotoWar_Cbac_ArmyCompositionTarget:set(TotoWar__Enum_Culture.woodElves, woodElves)
