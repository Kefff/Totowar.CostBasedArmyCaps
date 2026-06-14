# TotoWar: Cost-Based Army Caps

`TotoWar: Cost-Based Army Caps` is a mod that caps player and AI campaign armies using a new resource called `Army Supplies`, similar to the budget in skirmish battles.
In addition to its normal price, each unit has an `Army Supplies` cost, which is deducted from the army's `Army Supplies`.
This prevents elite doomstacks and keeps low-tier units relevant during the late game.
The mod also affects AI army compositions to avoid elite or monster-only armies.

## Inspiration
This mod is heavily inspired by other great mods (and their derivatives) that add restrictions and lore-friendly caps to improve army compositions:
- Jadawin's [Cost-based Army Caps](https://steamcommunity.com/sharedfiles/filedetails/?id=1723390103)
- DrunkFlamingo's [Tabletop Caps](https://steamcommunity.com/sharedfiles/filedetails/?id=2789896406)

However, I did not find any mod that fully addressed my issues with the game, notably the bonkers AI army compositions and every army being a 20-unit stack.
I tried to address these problems in this mod.

## `Army Supplies` budget
Each unit has an `Army Supplies` cost, which is the same as in skirmish battles.
The `Army Supplies` cost of lords and heroes never changes. Mounts, abilities, and spells have no impact on it.

Like in skirmish battles, by default, player and AI armies have an initial budget of 12,400 `Army Supplies`.
By default, player and AI lords gain 50 `Army Supplies` each time they level up.
This roughly allows the recruitment of two more elite units at level 50 compared to a level 1 lord.

## Restrictions applied to player armies
Two restrictions are applied to player armies:
- If the `Army Supplies` cost of a unit exceeds the remaining `Army Supplies` of an army, it cannot be recruited.
- If the `Army Supplies` of an army are depleted, the army cannot move.
To be able to move again, you can remove heroes, disband units, or transfer them to another army.

## Restrictions applied to AI armies
By default, AI armies have the same `Army Supplies` budget as the player.
The mod has no impact on an AI army as long as its `Army Supplies` budget is not exceeded.
When it is exceeded, the following happens:

A target army size (between 13 and 20) and a maximum amount of each unit category are randomly generated for the army:
- Maximum amount of cavalry and monsters (up to 50% by default)
- Maximum amount of heroes (up to 15% by default)
- Maximum amount of melee infantry (up to 75% by default)
- Maximum amount of ranged infantry (up to 50% by default)
- Maximum amount of war machines (up to 20% by default)

If the faction does not have access to some unit categories, the maximum amount of other unit categories is increased, up to a maximum of 75%.
Each AI army has different randomly generated target values.

This determines how the mod chooses to remove units from the army to match the available `Army Supplies` budget, which makes AI army compositions more varied.
Armies with a lower target size will tend to use elite troops, while armies with a higher target size will tend to use more lower-tier units.

However, keep in mind that the mod does not influence which units the AI decides to recruit.
It only removes heroes and units in an attempt to match the `Army Supplies` budget, target army size, and to ensure units of different types stay under their maximum amount.

## Impact on quest battles
Since army compositions are weaker than usual due to the mod restrictions, quest battles are much more difficult.
If you struggle, you can work around the restrictions by recruiting or transferring additional or better units to your army (which will prevent it from moving).
Then, use the quest `Teleport` button to start the battle.
Afterward, you can disband or transfer units back to another army to be able to move again.

## Adding the mod to an ongoing campaign
While it is best to start a new campaign with the mod, you can still play an ongoing campaign with it.
Bear in mind that you will have to adjust the composition of all your armies to match the `Army Supplies` budget to be able to move them.
The composition of AI armies will be adjusted during following turn.

## Configuration
If you have installed Groove Wizard's [Mod Configuration Tool](https://steamcommunity.com/sharedfiles/filedetails/?id=2927955021), you can access options for customizing the mod's behavior in the game.
You can choose to disable restrictions for the player or the AI, change `Army Supplies` base budgets, change the amount of `Army Supplies` gained each level, and adjust AI army target composition maximum percentages.

## Multiplayer compatibility
**The mod is very likely not compatible with a multiplayer campaign**.
It has not been developed with multiplayer in mind, nor has been tested during a multiplayer campaign.

## Compatibility with other mods
The mod should be compatible with mods that add units, provided the added units have a skirmish battle price.

However, **the mod will conflict with mods that impose caps**, such as DrunkFlamingo's [Tabletop Caps](https://steamcommunity.com/sharedfiles/filedetails/?id=2789896406) or Wolfy's [Cost-based Army Caps](https://steamcommunity.com/sharedfiles/filedetails/?id=2843367951) (and their derivatives).
Overhaul mods like [Venris' SFO: Grimhammer](https://steamcommunity.com/sharedfiles/filedetails/?id=2792731173) or [Radious Total War Mod](https://steamcommunity.com/sharedfiles/filedetails/?id=2791750313) **are very likely incompatible**. I have not made any test with them.

## Use of generative AI
Every part of this mod is locally produced, organic code, except for two elements made using generative AI:
- The `Army Supplies` icon, because I'm a programmer with zero artistic ability.
- The algorithm for choosing which units should be disbanded when the `Army Supplies` of an AI army are depleted (lots of parameters to take into account to make the optimal choice), because I'm too dumb to code something this complex.

## Links
[Github repository](https://github.com/Kefff/Totowar.CostBasedArmyCaps)