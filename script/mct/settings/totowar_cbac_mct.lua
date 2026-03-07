require("script._lib.mod.totowar_core_options")
require("script._lib.mod.totowar_cbac_options")

---@diagnostic disable-next-line: undefined-global
local mct = get_mct()

if mct then
    local totoWarMod = mct:get_mod_by_key(TotoWarModName)

    local totoWarCbacModPage = totoWarMod:create_settings_page("TotoWar Cost-Based Army Caps", 1)

    local cbacSection = totoWarMod:add_new_section("totowar_cbac_section", "TotoWar Cost-Based Army Caps")
    cbacSection:set_description("Options for the TotoWar Cost-Based Army Caps")
    totoWarCbacModPage:assign_section_to_page(cbacSection)

    local playerArmySuppliesOption = totoWarMod:add_new_option(
        TotoWarCbacPlayerArmySuppliesOptionName,
        "slider")
    playerArmySuppliesOption:slider_set_min_max(0, 100000)
    playerArmySuppliesOption:slider_set_step_size(100)
    playerArmySuppliesOption:set_default_value(TotoWarCbacDefaultPlayerArmySupplies)
    playerArmySuppliesOption:set_text("Army supplies for player armies")
    playerArmySuppliesOption:set_tooltip_text(
        "Amount of [[img:icon_merc]][[/img]]Army supplies available for recruiting units in a player's armies.\n\nIf the combined army supplies cost of an army’s units exceeds this limit, the army becomes immobilized until units are either disbanded or transferred to another army.\n\nA unit's army supplies cost is identical to its cost in a skirmish battle.\n\n[[col:alliance_ally]]0[[/col]] disables army supplies restrictions for the player.\n[[col:alliance_ally]]12400[[/col]] by default.")

    local aiArmySuppliesOption = totoWarMod:add_new_option(
        TotoWarCbacAiArmySuppliesOptionName,
        "slider")
    aiArmySuppliesOption:slider_set_min_max(0, 100000)
    aiArmySuppliesOption:slider_set_step_size(100)
    aiArmySuppliesOption:set_default_value(TotoWarCbacDefaultAiArmySupplies)
    aiArmySuppliesOption:set_text("Army supplies for AI armies")
    aiArmySuppliesOption:set_tooltip_text(
        "Amount of [[img:icon_merc]][[/img]]Army supplies available for recruiting units in AI faction armies.\n\nWhen an AI faction recruits a new unit, if the combined supply cost of the army’s units exceeds this limit, the AI automatically disbands some of its cheapest units to stay within the cap.\nThe AI faction is then reimbursed for the cost of the disbanded units.\n\nA unit’s army supplies cost is the same as its cost in a skirmish battle.\n\n[[col:alliance_ally]]0[[/col]] disables army supplies restrictions for AI factions.\n[[col:alliance_ally]]12400[[/col]] by default.")

    local aiUnitsToDiscardMaximumNumberOption = totoWarMod:add_new_option(
        TotoWarCbacAiUnitsToDiscardMaximumNumberOptionName,
        "slider")
    aiUnitsToDiscardMaximumNumberOption:slider_set_min_max(0, 20)
    aiUnitsToDiscardMaximumNumberOption:slider_set_step_size(1)
    aiUnitsToDiscardMaximumNumberOption:set_default_value(TotoWarCbacDefaultAiUnitsToDiscardMaximumNumber)
    aiUnitsToDiscardMaximumNumberOption:set_text("Number of units the AI can disband")
    aiUnitsToDiscardMaximumNumberOption:set_tooltip_text(
        "Determines how many units an AI faction can disband when an army’s total [[img:icon_merc]][[/img]]Army supplies cost exceeds the allowed limit.\n\n[[col:alliance_ally]]3[[/col]] by default.")
end
