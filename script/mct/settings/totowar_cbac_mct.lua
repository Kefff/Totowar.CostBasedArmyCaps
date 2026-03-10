require("script._lib.mod.totowar__mod_options")
require("script._lib.mod.totowar_cbac_mod_options")

---@diagnostic disable-next-line: undefined-global
local mct = get_mct()

if mct then
    local totoWarMod = mct:get_mod_by_key(TotoWar_ModName)

    local totoWarCbacModPage = totoWarMod:create_settings_page("TotoWar Cost-Based Army Caps options", 1) -- For some reason the key used to identify the page is displayed to the user, but using a localised text does not work

    local cbacSection = totoWarMod:add_new_section("totowar_cbac_section", "totowar_cbac_mct_section_title")
    totoWarCbacModPage:assign_section_to_page(cbacSection)

    local playerArmySuppliesEnabledOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_PlayerArmySuppliesEnabled,
        "checkbox")
    playerArmySuppliesEnabledOption:set_default_value(TotoWar_Cbac_OptionDefaultValue_PlayerArmySuppliesEnabled)
    playerArmySuppliesEnabledOption:set_text("totowar_cbac_mct_option_text_player_army_supplies_enabled")
    playerArmySuppliesEnabledOption:set_tooltip_text("totowar_cbac_mct_option_tooltip_player_army_supplies_enabled")
    playerArmySuppliesEnabledOption:add_option_set_callback(
        function(context)
            ---@type boolean
            local isEnabled = context:setting()
            local mod = context:option():get_mod()

            local paso = mod:get_option_by_key(TotoWar_Cbac_OptionName_PlayerArmySuppliesAmount)
            paso:set_uic_visibility(isEnabled)
        end,
        true)
    cbacSection:assign_option(playerArmySuppliesEnabledOption)

    local playerArmySuppliesOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_PlayerArmySuppliesAmount,
        "slider")
    playerArmySuppliesOption:slider_set_min_max(100, 100000)
    playerArmySuppliesOption:slider_set_step_size(100)
    playerArmySuppliesOption:set_default_value(TotoWar_Cbac_OptionDefaultValue_PlayerArmySuppliesAmount)
    playerArmySuppliesOption:set_text("totowar_cbac_mct_option_text_player_army_supplies")
    playerArmySuppliesOption:set_tooltip_text("totowar_cbac_mct_option_tooltip_player_army_supplies")
    cbacSection:assign_option(playerArmySuppliesOption)

    local aiArmySuppliesEnabledOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_AiArmySuppliesEnabled,
        "checkbox")
    aiArmySuppliesEnabledOption:set_default_value(TotoWar_Cbac_OptionDefaultValue_AiArmySuppliesEnabled)
    aiArmySuppliesEnabledOption:set_text("totowar_cbac_mct_option_text_ai_army_supplies_enabled")
    aiArmySuppliesEnabledOption:set_tooltip_text("totowar_cbac_mct_option_tooltip_ai_army_supplies_enabled")
    aiArmySuppliesEnabledOption:add_option_set_callback(
        function(context)
            ---@type boolean
            local isEnabled = context:setting()
            local mod = context:option():get_mod()

            local aiasao = mod:get_option_by_key(TotoWar_Cbac_OptionName_AiArmySuppliesAmount)
            aiasao:set_uic_visibility(isEnabled)

            local aidumao = mod:get_option_by_key(TotoWar_Cbac_OptionName_AiDisposableUnitsMaximumAmount)
            aidumao:set_uic_visibility(isEnabled)
        end,
        true)
    cbacSection:assign_option(aiArmySuppliesEnabledOption)

    local aiArmySuppliesAmountOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_AiArmySuppliesAmount,
        "slider")
    aiArmySuppliesAmountOption:slider_set_min_max(100, 100000)
    aiArmySuppliesAmountOption:slider_set_step_size(100)
    aiArmySuppliesAmountOption:set_default_value(TotoWar_Cbac_OptionDefaultValue_AiArmySuppliesAmount)
    aiArmySuppliesAmountOption:set_text("totowar_cbac_mct_option_text_ai_army_supplies")
    aiArmySuppliesAmountOption:set_tooltip_text("totowar_cbac_mct_option_tooltip_ai_army_supplies")
    cbacSection:assign_option(aiArmySuppliesAmountOption)

    local aiDisposableUnitsMaximumAmountOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_AiDisposableUnitsMaximumAmount,
        "slider")
    aiDisposableUnitsMaximumAmountOption:slider_set_min_max(0, 20)
    aiDisposableUnitsMaximumAmountOption:slider_set_step_size(1)
    aiDisposableUnitsMaximumAmountOption:set_default_value(
        TotoWar_Cbac_OptionDefaultValue_AiDisposableUnitsMaximumAmount)
    aiDisposableUnitsMaximumAmountOption:set_text(
        "totowar_cbac_mct_option_text_ai_disposable_units_maximum_amount_option")
    aiDisposableUnitsMaximumAmountOption:set_tooltip_text(
        "totowar_cbac_mct_option_tooltip_ai_disposable_units_maximum_amount_option")
    cbacSection:assign_option(aiDisposableUnitsMaximumAmountOption)
end
