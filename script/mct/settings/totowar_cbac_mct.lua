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
    cbacPlayerSection:assign_option(playerArmySuppliesEnabledOption)

    local playerArmySuppliesOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_PlayerArmySuppliesAmount,
        "slider")
    playerArmySuppliesOption:slider_set_min_max(100, 50000)
    playerArmySuppliesOption:slider_set_step_size(100)
    playerArmySuppliesOption:set_default_value(TotoWar_Cbac_OptionDefaultValue_PlayerArmySuppliesAmount)
    playerArmySuppliesOption:set_text("totowar_cbac_mct_option_caption_playerArmySupplies")
    playerArmySuppliesOption:set_tooltip_text("totowar_cbac_mct_option_tooltip_playerArmySupplies")
    cbacPlayerSection:assign_option(playerArmySuppliesOption)

    local playerArmySuppliesBonusAmountPerLevelOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_PlayerArmySuppliesBonusAmountPerLevel,
        "slider")
    playerArmySuppliesBonusAmountPerLevelOption:slider_set_min_max(10, 500)
    playerArmySuppliesBonusAmountPerLevelOption:slider_set_step_size(100)
    playerArmySuppliesBonusAmountPerLevelOption:set_default_value(
        TotoWar_Cbac_OptionDefaultValue_PlayerArmySuppliesBonusAmountPerLevel)
    playerArmySuppliesBonusAmountPerLevelOption:set_text(
        "totowar_cbac_mct_option_caption_playerArmySuppliesBonusAmountPerLevel")
    playerArmySuppliesBonusAmountPerLevelOption:set_tooltip_text(
        "totowar_cbac_mct_option_tooltip_playerArmySuppliesBonusAmountPerLevel")
    cbacPlayerSection:assign_option(playerArmySuppliesBonusAmountPerLevelOption)

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
    cbacAiSection:assign_option(aiArmySuppliesEnabledOption)

    local aiArmySuppliesAmountOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_AiArmySuppliesAmount,
        "slider")
    aiArmySuppliesAmountOption:slider_set_min_max(100, 50000)
    aiArmySuppliesAmountOption:slider_set_step_size(100)
    aiArmySuppliesAmountOption:set_default_value(TotoWar_Cbac_OptionDefaultValue_AiArmySuppliesAmount)
    aiArmySuppliesAmountOption:set_text("totowar_cbac_mct_option_caption_aiArmySupplies")
    aiArmySuppliesAmountOption:set_tooltip_text("totowar_cbac_mct_option_tooltip_aiArmySupplies")
    cbacAiSection:assign_option(aiArmySuppliesAmountOption)

    local aiArmySuppliesBonusAmountPerLevelOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_AiArmySuppliesBonusAmountPerLevel,
        "slider")
    aiArmySuppliesBonusAmountPerLevelOption:slider_set_min_max(10, 500)
    aiArmySuppliesBonusAmountPerLevelOption:slider_set_step_size(100)
    aiArmySuppliesBonusAmountPerLevelOption:set_default_value(
        TotoWar_Cbac_OptionDefaultValue_AiArmySuppliesBonusAmountPerLevel)
    aiArmySuppliesBonusAmountPerLevelOption:set_text("totowar_cbac_mct_option_caption_aiArmySuppliesBonusAmountPerLevel")
    aiArmySuppliesBonusAmountPerLevelOption:set_tooltip_text(
        "totowar_cbac_mct_option_tooltip_aiArmySuppliesBonusAmountPerLevel")
    cbacAiSection:assign_option(aiArmySuppliesBonusAmountPerLevelOption)

    local aiArmyMeleeInfantryMinimumPercentageOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_AiArmyMeleeInfantryMinimumPercentage,
        "slider")
    aiArmyMeleeInfantryMinimumPercentageOption:slider_set_min_max(0, 100)
    aiArmyMeleeInfantryMinimumPercentageOption:slider_set_step_size(5)
    aiArmyMeleeInfantryMinimumPercentageOption:set_default_value(
        TotoWar_Cbac_OptionDefaultValue_AiArmyMeleeInfantryMinimumPercentage)
    aiArmyMeleeInfantryMinimumPercentageOption:set_text(
        "totowar_cbac_mct_option_caption_aiArmyMeleeInfantryMinimumPercentage")
    aiArmyMeleeInfantryMinimumPercentageOption:set_tooltip_text(
        "totowar_cbac_mct_option_tooltip_aiArmyMeleeInfantryMinimumPercentage")
    cbacAiSection:assign_option(aiArmyMeleeInfantryMinimumPercentageOption)

    local aiArmyHeroMaximumPercentageOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_AiArmyHeroMaximumPercentage,
        "slider")
    aiArmyHeroMaximumPercentageOption:slider_set_min_max(0, 100)
    aiArmyHeroMaximumPercentageOption:slider_set_step_size(5)
    aiArmyHeroMaximumPercentageOption:set_default_value(
        TotoWar_Cbac_OptionDefaultValue_AiArmyHeroMaximumPercentage)
    aiArmyHeroMaximumPercentageOption:set_text(
        "totowar_cbac_mct_option_caption_aiArmyHeroMaximumPercentage")
    aiArmyHeroMaximumPercentageOption:set_tooltip_text(
        "totowar_cbac_mct_option_tooltip_aiArmyHeroMaximumPercentage")
    cbacAiSection:assign_option(aiArmyHeroMaximumPercentageOption)

    local aiArmyRangedInfantryMaximumPercentageOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_AiArmyRangedInfantryMaximumPercentage,
        "slider")
    aiArmyRangedInfantryMaximumPercentageOption:slider_set_min_max(0, 100)
    aiArmyRangedInfantryMaximumPercentageOption:slider_set_step_size(5)
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
    aiArmyCavalryAndMonstersMaximumPercentageOption:slider_set_step_size(5)
    aiArmyCavalryAndMonstersMaximumPercentageOption:set_default_value(
        TotoWar_Cbac_OptionDefaultValue_AiArmyCavalryAndMonstersMaximumPercentage)
    aiArmyCavalryAndMonstersMaximumPercentageOption:set_text(
        "totowar_cbac_mct_option_caption_aiArmyCavalryAndMonstersMaximumPercentage")
    aiArmyCavalryAndMonstersMaximumPercentageOption:set_tooltip_text(
        "totowar_cbac_mct_option_tooltip_aiArmyCavalryAndMonstersMaximumPercentage")
    cbacAiSection:assign_option(aiArmyCavalryAndMonstersMaximumPercentageOption)

    local aiArmyWarMachinesMaximumPercentageOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_AiArmyWarMachinesMaximumPercentage,
        "slider")
    aiArmyWarMachinesMaximumPercentageOption:slider_set_min_max(0, 100)
    aiArmyWarMachinesMaximumPercentageOption:slider_set_step_size(5)
    aiArmyWarMachinesMaximumPercentageOption:set_default_value(
        TotoWar_Cbac_OptionDefaultValue_AiArmyWarMachinesMaximumPercentage)
    aiArmyWarMachinesMaximumPercentageOption:set_text(
        "totowar_cbac_mct_option_caption_aiArmyWarMachinesMaximumPercentage")
    aiArmyWarMachinesMaximumPercentageOption:set_tooltip_text(
        "totowar_cbac_mct_option_tooltip_aiArmyWarMachinesMaximumPercentage")
    cbacAiSection:assign_option(aiArmyWarMachinesMaximumPercentageOption)
end
