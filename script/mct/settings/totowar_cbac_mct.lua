require("script._lib.mod.totowar__mod_options")
require("script._lib.mod.totowar_cbac_mod_options")

---@diagnostic disable-next-line: undefined-global
local mct = get_mct()

if mct then
    local totoWarMod = mct:get_mod_by_key(TotoWar_ModName)

    local totoWarCbacModPage = totoWarMod:create_settings_page("TotoWar Cost-Based Army Caps - Options", 1) -- For some reason the key used to identify the page is displayed to the user, but using a localised text does not work

    -- Player section
    local cbacPlayerSection = totoWarMod:add_new_section(
        "totowar_cbac_section_player",
        "totowar_cbac_mct_section_title_player")
    totoWarCbacModPage:assign_section_to_page(cbacPlayerSection)

    local playerArmySuppliesEnabledOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_PlayerArmySuppliesEnabled,
        "checkbox")
    playerArmySuppliesEnabledOption:set_default_value(TotoWar_Cbac_OptionDefaultValue_PlayerArmySuppliesEnabled)
    playerArmySuppliesEnabledOption:set_text("totowar_cbac_mct_option_caption_playerArmySuppliesEnabled")
    playerArmySuppliesEnabledOption:set_tooltip_text("totowar_cbac_mct_option_tooltip_playerArmySuppliesEnabled")
    playerArmySuppliesEnabledOption:add_option_set_callback(
        function(context)
            ---@type boolean
            local isEnabled = context:setting()
            local mod = context:option():get_mod()

            local paso = mod:get_option_by_key(TotoWar_Cbac_OptionName_PlayerArmySuppliesAmount)
            paso:set_uic_visibility(isEnabled)
        end,
        true)
    cbacPlayerSection:assign_option(playerArmySuppliesEnabledOption)

    local playerArmySuppliesOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_PlayerArmySuppliesAmount,
        "slider")
    playerArmySuppliesOption:slider_set_min_max(100, 100000)
    playerArmySuppliesOption:slider_set_step_size(100)
    playerArmySuppliesOption:set_default_value(TotoWar_Cbac_OptionDefaultValue_PlayerArmySuppliesAmount)
    playerArmySuppliesOption:set_text("totowar_cbac_mct_option_caption_playerArmySupplies")
    playerArmySuppliesOption:set_tooltip_text("totowar_cbac_mct_option_tooltip_playerArmySupplies")
    cbacPlayerSection:assign_option(playerArmySuppliesOption)

    -- AI section
    local cbacAiSection = totoWarMod:add_new_section(
        "totowar_cbac_section_ai",
        "totowar_cbac_mct_section_title_ai")
    totoWarCbacModPage:assign_section_to_page(cbacAiSection)

    local aiArmySuppliesEnabledOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_AiArmySuppliesEnabled,
        "checkbox")
    aiArmySuppliesEnabledOption:set_default_value(TotoWar_Cbac_OptionDefaultValue_AiArmySuppliesEnabled)
    aiArmySuppliesEnabledOption:set_text("totowar_cbac_mct_option_caption_aiArmySuppliesEnabled")
    aiArmySuppliesEnabledOption:set_tooltip_text("totowar_cbac_mct_option_tooltip_aiArmySuppliesEnabled")
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
    cbacAiSection:assign_option(aiArmySuppliesEnabledOption)

    local aiArmySuppliesAmountOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_AiArmySuppliesAmount,
        "slider")
    aiArmySuppliesAmountOption:slider_set_min_max(100, 100000)
    aiArmySuppliesAmountOption:slider_set_step_size(100)
    aiArmySuppliesAmountOption:set_default_value(TotoWar_Cbac_OptionDefaultValue_AiArmySuppliesAmount)
    aiArmySuppliesAmountOption:set_text("totowar_cbac_mct_option_caption_aiArmySupplies")
    aiArmySuppliesAmountOption:set_tooltip_text("totowar_cbac_mct_option_tooltip_aiArmySupplies")
    cbacAiSection:assign_option(aiArmySuppliesAmountOption)

    local aiArmyAgentMaximumAmountOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_AiArmyAgentMaximumAmount,
        "slider")
    aiArmyAgentMaximumAmountOption:slider_set_min_max(0, 20)
    aiArmyAgentMaximumAmountOption:slider_set_step_size(1)
    aiArmyAgentMaximumAmountOption:set_default_value(
        TotoWar_Cbac_OptionDefaultValue_AiArmyAgentMaximumAmount)
    aiArmyAgentMaximumAmountOption:set_text(
        "totowar_cbac_mct_option_caption_aiArmyAgentMaximumAmount")
    aiArmyAgentMaximumAmountOption:set_tooltip_text(
        "totowar_cbac_mct_option_tooltip_aiArmyAgentMaximumAmount")
    cbacAiSection:assign_option(aiArmyAgentMaximumAmountOption)

    local aiArmyMeleeInfantryMaximumPercentageOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_AiArmyMeleeInfantryMaximumPercentage,
        "slider")
    aiArmyMeleeInfantryMaximumPercentageOption:slider_set_min_max(0, 100)
    aiArmyMeleeInfantryMaximumPercentageOption:slider_set_step_size(1)
    aiArmyMeleeInfantryMaximumPercentageOption:set_default_value(
        TotoWar_Cbac_OptionDefaultValue_AiArmyMeleeInfantryMaximumPercentage)
    aiArmyMeleeInfantryMaximumPercentageOption:set_text(
        "totowar_cbac_mct_option_caption_aiArmyMeleeInfantryMaximumPercentage")
    aiArmyMeleeInfantryMaximumPercentageOption:set_tooltip_text(
        "totowar_cbac_mct_option_tooltip_aiArmyMeleeInfantryMaximumPercentage")
    cbacAiSection:assign_option(aiArmyMeleeInfantryMaximumPercentageOption)

    local aiArmyRangedInfantryMaximumPercentageOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_AiArmyRangedInfantryMaximumPercentage,
        "slider")
    aiArmyRangedInfantryMaximumPercentageOption:slider_set_min_max(0, 100)
    aiArmyRangedInfantryMaximumPercentageOption:slider_set_step_size(1)
    aiArmyRangedInfantryMaximumPercentageOption:set_default_value(
        TotoWar_Cbac_OptionDefaultValue_AiArmyRangedInfantryMaximumPercentage)
    aiArmyRangedInfantryMaximumPercentageOption:set_text(
        "totowar_cbac_mct_option_caption_aiArmyRangedInfantryMaximumPercentage")
    aiArmyRangedInfantryMaximumPercentageOption:set_tooltip_text(
        "totowar_cbac_mct_option_tooltip_aiArmyRangedInfantryMaximumPercentage")
    cbacAiSection:assign_option(aiArmyRangedInfantryMaximumPercentageOption)

    local aiArmyCavalryAndMonstersMaximumPercentageOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_AiArmyCavalryAndMonstersMaximumPercentage,
        "slider")
    aiArmyCavalryAndMonstersMaximumPercentageOption:slider_set_min_max(0, 100)
    aiArmyCavalryAndMonstersMaximumPercentageOption:slider_set_step_size(1)
    aiArmyCavalryAndMonstersMaximumPercentageOption:set_default_value(
        TotoWar_Cbac_OptionDefaultValue_AiArmyCavalryAndMonstersMaximumPercentage)
    aiArmyCavalryAndMonstersMaximumPercentageOption:set_text(
        "totowar_cbac_mct_option_caption_aiArmyCavalryAndMonstersMaximumPercentage")
    aiArmyCavalryAndMonstersMaximumPercentageOption:set_tooltip_text(
        "totowar_cbac_mct_option_tooltip_aiArmyCavalryAndMonstersMaximumPercentage")
    cbacAiSection:assign_option(aiArmyCavalryAndMonstersMaximumPercentageOption)

    local aiArmyArtilleryMaximumPercentageOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_AiArmyArtilleryMaximumPercentage,
        "slider")
    aiArmyArtilleryMaximumPercentageOption:slider_set_min_max(0, 100)
    aiArmyArtilleryMaximumPercentageOption:slider_set_step_size(1)
    aiArmyArtilleryMaximumPercentageOption:set_default_value(
        TotoWar_Cbac_OptionDefaultValue_AiArmyArtilleryMaximumPercentage)
    aiArmyArtilleryMaximumPercentageOption:set_text(
        "totowar_cbac_mct_option_caption_aiArmyArtilleryMaximumPercentage")
    aiArmyArtilleryMaximumPercentageOption:set_tooltip_text(
        "totowar_cbac_mct_option_tooltip_aiArmyArtilleryMaximumPercentage")
    cbacAiSection:assign_option(aiArmyArtilleryMaximumPercentageOption)

    local aiDisposableUnitsMaximumAmountOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_AiDisposableUnitsMaximumAmount,
        "slider")
    aiDisposableUnitsMaximumAmountOption:slider_set_min_max(0, 20)
    aiDisposableUnitsMaximumAmountOption:slider_set_step_size(1)
    aiDisposableUnitsMaximumAmountOption:set_default_value(
        TotoWar_Cbac_OptionDefaultValue_AiArmyDisposableUnitsMaximumAmount)
    aiDisposableUnitsMaximumAmountOption:set_text(
        "totowar_cbac_mct_option_caption_aiDisposableUnitsMaximumAmountOption")
    aiDisposableUnitsMaximumAmountOption:set_tooltip_text(
        "totowar_cbac_mct_option_tooltip_aiDisposableUnitsMaximumAmountOption")
    cbacAiSection:assign_option(aiDisposableUnitsMaximumAmountOption)

    -- Logs section
    local cbacLogsSection = totoWarMod:add_new_section(
        "totowar_cbac_section_logs",
        "totowar_cbac_mct_section_title_logs")
    totoWarCbacModPage:assign_section_to_page(cbacLogsSection)

    local aiManagerLoggerEnabledOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_AiManagerLoggerEnabled,
        "checkbox")
    aiManagerLoggerEnabledOption:set_default_value(TotoWar_Cbac_OptionDefaultValue_AiManagerLoggerEnabled)
    aiManagerLoggerEnabledOption:set_text("totowar_cbac_mct_option_caption_aiManagerLoggerEnabled")
    aiManagerLoggerEnabledOption:set_tooltip_text("totowar_cbac_mct_option_tooltip_aiManagerLoggerEnabled")
    cbacLogsSection:assign_option(aiManagerLoggerEnabledOption)

    local playerManagerLoggerEnabledOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_PlayerManagerLoggerEnabled,
        "checkbox")
    playerManagerLoggerEnabledOption:set_default_value(TotoWar_Cbac_OptionDefaultValue_PlayerManagerLoggerEnabled)
    playerManagerLoggerEnabledOption:set_text("totowar_cbac_mct_option_caption_playerManagerLoggerEnabled")
    playerManagerLoggerEnabledOption:set_tooltip_text("totowar_cbac_mct_option_tooltip_playerManagerLoggerEnabled")
    cbacLogsSection:assign_option(playerManagerLoggerEnabledOption)

    local uiManagerLoggerEnabledOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_UiManagerLoggerEnabled,
        "checkbox")
    uiManagerLoggerEnabledOption:set_default_value(TotoWar_Cbac_OptionDefaultValue_UiManagerLoggerEnabled)
    uiManagerLoggerEnabledOption:set_text("totowar_cbac_mct_option_caption_uiManagerLoggerEnabled")
    uiManagerLoggerEnabledOption:set_tooltip_text("totowar_cbac_mct_option_tooltip_uiManagerLoggerEnabled")
    cbacLogsSection:assign_option(uiManagerLoggerEnabledOption)
end
