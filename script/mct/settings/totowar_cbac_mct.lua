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

    local aiArmyHeroMaximumAmountOption = totoWarMod:add_new_option(
        TotoWar_Cbac_OptionName_AiArmyHeroMaximumAmount,
        "slider")
    aiArmyHeroMaximumAmountOption:slider_set_min_max(0, 20)
    aiArmyHeroMaximumAmountOption:slider_set_step_size(1)
    aiArmyHeroMaximumAmountOption:set_default_value(
        TotoWar_Cbac_OptionDefaultValue_AiArmyHeroMaximumAmount)
    aiArmyHeroMaximumAmountOption:set_text(
        "totowar_cbac_mct_option_caption_aiArmyHeroMaximumAmount")
    aiArmyHeroMaximumAmountOption:set_tooltip_text(
        "totowar_cbac_mct_option_tooltip_aiArmyHeroMaximumAmount")
    cbacAiSection:assign_option(aiArmyHeroMaximumAmountOption)

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
end
