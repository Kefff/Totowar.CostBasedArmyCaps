require("script._lib.mod.totowar__mod_options")
require("script._lib.mod.totowar_cbac_mod_options")

---@diagnostic disable-next-line: undefined-global
local mct = get_mct()

if mct then
    local totoWarMod = mct:get_mod_by_key(TotoWar_ModName)

    local totoWarCbacModPage = totoWarMod:create_settings_page("TotoWar Cost-Based Army Caps", 1)

    local cbacSection = totoWarMod:add_new_section("totowar_cbac_section", "TotoWar Cost-Based Army Caps")
    cbacSection:set_description("Options for the TotoWar Cost-Based Army Caps")
    totoWarCbacModPage:assign_section_to_page(cbacSection)

    local playerArmySuppliesEnabledOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_PlayerArmySuppliesEnabled,
        "checkbox")
    playerArmySuppliesEnabledOption:set_default_value(TotoWar_Cbac_OptionDefaultValue_PlayerArmySuppliesEnabled)
    playerArmySuppliesEnabledOption:set_text("Army supplies restrictions for player armies")
    playerArmySuppliesEnabledOption:set_tooltip_text(
        "Enables army supplies restrictions for player armies.\n\nIf the combined army supplies cost of an army’s units exceeds the limit, the army becomes immobilized until units are either disbanded or transferred to another army.\n\n[[col:alliance_ally]]Checked[[/col]] by default.")
    cbacSection:assign_option(playerArmySuppliesEnabledOption)

    local playerArmySuppliesOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_PlayerArmySuppliesAmount,
        "slider")
    playerArmySuppliesOption:slider_set_min_max(100, 100000)
    playerArmySuppliesOption:slider_set_step_size(100)
    playerArmySuppliesOption:set_default_value(TotoWar_Cbac_OptionDefaultValue_PlayerArmySuppliesAmount)
    playerArmySuppliesOption:set_text("Army supplies for player armies")
    playerArmySuppliesOption:set_tooltip_text(
        "Amount of [[img:icon_merc]][[/img]]Army supplies available for recruiting units in a player's armies.\n\nA unit's army supplies cost is identical to its cost in a skirmish battle.\n\n[[col:alliance_ally]]12400[[/col]] by default.")
    cbacSection:assign_option(playerArmySuppliesOption)

    local aiArmySuppliesEnabledOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_AiArmySuppliesEnabled,
        "checkbox")
    aiArmySuppliesEnabledOption:set_default_value(TotoWar_Cbac_OptionDefaultValue_AiArmySuppliesEnabled)
    aiArmySuppliesEnabledOption:set_text("Army supplies restrictions for AI armies")
    aiArmySuppliesEnabledOption:set_tooltip_text(
        "Enables army supplies restrictions for AI armies.\n\nWhen an AI faction recruits a new unit, if the combined supply cost of the army’s units exceeds the limit, the AI automatically disbands some of its cheapest units to stay within the cap.\nThe AI faction is then reimbursed for the cost of the disbanded units.\n\n[[col:alliance_ally]]Checked[[/col]] by default.")
    cbacSection:assign_option(aiArmySuppliesEnabledOption)

    local aiArmySuppliesAmountOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_AiArmySuppliesAmount,
        "slider")
    aiArmySuppliesAmountOption:slider_set_min_max(100, 100000)
    aiArmySuppliesAmountOption:slider_set_step_size(100)
    aiArmySuppliesAmountOption:set_default_value(TotoWar_Cbac_OptionDefaultValue_AiArmySuppliesAmount)
    aiArmySuppliesAmountOption:set_text("Army supplies for AI armies")
    aiArmySuppliesAmountOption:set_tooltip_text(
        "Amount of [[img:icon_merc]][[/img]]Army supplies available for recruiting units in AI faction armies.\n\nA unit’s army supplies cost is the same as its cost in a skirmish battle.\n\n[[col:alliance_ally]]12400[[/col]] by default.")
    cbacSection:assign_option(aiArmySuppliesAmountOption)

    local aiDisposableUnitsMaximumAmountOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_AiDisposableUnitsMaximumAmount,
        "slider")
    aiDisposableUnitsMaximumAmountOption:slider_set_min_max(0, 20)
    aiDisposableUnitsMaximumAmountOption:slider_set_step_size(1)
    aiDisposableUnitsMaximumAmountOption:set_default_value(
        TotoWar_Cbac_OptionDefaultValue_AiDisposableUnitsMaximumAmount)
    aiDisposableUnitsMaximumAmountOption:set_text("Number of units the AI can disband")
    aiDisposableUnitsMaximumAmountOption:set_tooltip_text(
        "Determines how many units an AI faction can disband when an army’s total [[img:icon_merc]][[/img]]Army supplies cost exceeds the allowed limit.\n\n[[col:alliance_ally]]3[[/col]] by default.")
    cbacSection:assign_option(aiDisposableUnitsMaximumAmountOption)
end
