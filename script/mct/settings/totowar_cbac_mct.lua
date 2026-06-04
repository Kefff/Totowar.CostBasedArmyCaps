require("script._lib.mod.totowar__constant")
require("script._lib.mod.totowar_cbac_constant")

---@diagnostic disable-next-line: undefined-global
local mct = get_mct()

if mct then
    local mctMod = mct:get_mod_by_key(TotoWar__Constant.modName)

    local totoWarCbacModPage = mctMod:create_settings_page("TotoWar Cost-Based Army Caps - Options", 1) -- For some reason the key used to identify the page is displayed to the user, but using a localised text does not work

    -- Player section
    local cbacPlayerSection = mctMod:add_new_section(
        "totowar_cbac_section_player",
        "totowar_cbac_mct_section_title_player")
    totoWarCbacModPage:assign_section_to_page(cbacPlayerSection)

    local playerArmySuppliesEnabledOption = mctMod:add_new_option(
        TotoWar_Cbac_Constant.optionName_playerArmySuppliesEnabled,
        "checkbox")
    playerArmySuppliesEnabledOption:set_default_value(TotoWar_Cbac_Constant.optionDefaultValue_playerArmySuppliesEnabled)
    playerArmySuppliesEnabledOption:set_text("totowar_cbac_mct_option_caption_playerArmySuppliesEnabled")
    playerArmySuppliesEnabledOption:set_tooltip_text("totowar_cbac_mct_option_tooltip_playerArmySuppliesEnabled")
    cbacPlayerSection:assign_option(playerArmySuppliesEnabledOption)

    local playerArmySuppliesOption = mctMod:add_new_option(
        TotoWar_Cbac_Constant.optionName_playerArmySuppliesAmount,
        "slider")
    playerArmySuppliesOption:slider_set_min_max(100, 50000)
    playerArmySuppliesOption:slider_set_step_size(100)
    playerArmySuppliesOption:set_default_value(TotoWar_Cbac_Constant.optionDefaultValue_playerArmySuppliesAmount)
    playerArmySuppliesOption:set_text("totowar_cbac_mct_option_caption_playerArmySupplies")
    playerArmySuppliesOption:set_tooltip_text("totowar_cbac_mct_option_tooltip_playerArmySupplies")
    cbacPlayerSection:assign_option(playerArmySuppliesOption)

    local playerArmySuppliesBonusAmountPerLevelOption = mctMod:add_new_option(
        TotoWar_Cbac_Constant.optionName_playerArmySuppliesBonusAmountPerLevel,
        "slider")
    playerArmySuppliesBonusAmountPerLevelOption:slider_set_min_max(10, 500)
    playerArmySuppliesBonusAmountPerLevelOption:slider_set_step_size(100)
    playerArmySuppliesBonusAmountPerLevelOption:set_default_value(
        TotoWar_Cbac_Constant.optionDefaultValue_playerArmySuppliesBonusAmountPerLevel)
    playerArmySuppliesBonusAmountPerLevelOption:set_text(
        "totowar_cbac_mct_option_caption_playerArmySuppliesBonusAmountPerLevel")
    playerArmySuppliesBonusAmountPerLevelOption:set_tooltip_text(
        "totowar_cbac_mct_option_tooltip_playerArmySuppliesBonusAmountPerLevel")
    cbacPlayerSection:assign_option(playerArmySuppliesBonusAmountPerLevelOption)

    -- AI section
    local cbacAiSection = mctMod:add_new_section(
        "totowar_cbac_section_ai",
        "totowar_cbac_mct_section_title_ai")
    totoWarCbacModPage:assign_section_to_page(cbacAiSection)

    local aiArmySuppliesEnabledOption = mctMod:add_new_option(
        TotoWar_Cbac_Constant.optionName_aiArmySuppliesEnabled,
        "checkbox")
    aiArmySuppliesEnabledOption:set_default_value(TotoWar_Cbac_Constant.optionDefaultValue_aiArmySuppliesEnabled)
    aiArmySuppliesEnabledOption:set_text("totowar_cbac_mct_option_caption_aiArmySuppliesEnabled")
    aiArmySuppliesEnabledOption:set_tooltip_text("totowar_cbac_mct_option_tooltip_aiArmySuppliesEnabled")
    cbacAiSection:assign_option(aiArmySuppliesEnabledOption)

    local aiArmySuppliesAmountOption = mctMod:add_new_option(
        TotoWar_Cbac_Constant.optionName_aiArmySuppliesAmount,
        "slider")
    aiArmySuppliesAmountOption:slider_set_min_max(100, 50000)
    aiArmySuppliesAmountOption:slider_set_step_size(100)
    aiArmySuppliesAmountOption:set_default_value(TotoWar_Cbac_Constant.optionDefaultValue_aiArmySuppliesAmount)
    aiArmySuppliesAmountOption:set_text("totowar_cbac_mct_option_caption_aiArmySupplies")
    aiArmySuppliesAmountOption:set_tooltip_text("totowar_cbac_mct_option_tooltip_aiArmySupplies")
    cbacAiSection:assign_option(aiArmySuppliesAmountOption)

    local aiArmySuppliesBonusAmountPerLevelOption = mctMod:add_new_option(
        TotoWar_Cbac_Constant.optionName_aiArmySuppliesBonusAmountPerLevel,
        "slider")
    aiArmySuppliesBonusAmountPerLevelOption:slider_set_min_max(10, 500)
    aiArmySuppliesBonusAmountPerLevelOption:slider_set_step_size(100)
    aiArmySuppliesBonusAmountPerLevelOption:set_default_value(
        TotoWar_Cbac_Constant.optionDefaultValue_aiArmySuppliesBonusAmountPerLevel)
    aiArmySuppliesBonusAmountPerLevelOption:set_text("totowar_cbac_mct_option_caption_aiArmySuppliesBonusAmountPerLevel")
    aiArmySuppliesBonusAmountPerLevelOption:set_tooltip_text(
        "totowar_cbac_mct_option_tooltip_aiArmySuppliesBonusAmountPerLevel")
    cbacAiSection:assign_option(aiArmySuppliesBonusAmountPerLevelOption)

    local aiArmyMeleeInfantryMinimumPercentageOption = mctMod:add_new_option(
        TotoWar_Cbac_Constant.optionName_aiArmyMeleeInfantryMinimumPercentage,
        "slider")
    aiArmyMeleeInfantryMinimumPercentageOption:slider_set_min_max(0, 100)
    aiArmyMeleeInfantryMinimumPercentageOption:slider_set_step_size(5)
    aiArmyMeleeInfantryMinimumPercentageOption:set_default_value(
        TotoWar_Cbac_Constant.optionDefaultValue_aiArmyMeleeInfantryMinimumPercentage)
    aiArmyMeleeInfantryMinimumPercentageOption:set_text(
        "totowar_cbac_mct_option_caption_aiArmyMeleeInfantryMinimumPercentage")
    aiArmyMeleeInfantryMinimumPercentageOption:set_tooltip_text(
        "totowar_cbac_mct_option_tooltip_aiArmyMeleeInfantryMinimumPercentage")
    cbacAiSection:assign_option(aiArmyMeleeInfantryMinimumPercentageOption)

    local aiArmyHeroMaximumPercentageOption = mctMod:add_new_option(
        TotoWar_Cbac_Constant.optionName_aiArmyHeroMaximumPercentage,
        "slider")
    aiArmyHeroMaximumPercentageOption:slider_set_min_max(0, 100)
    aiArmyHeroMaximumPercentageOption:slider_set_step_size(5)
    aiArmyHeroMaximumPercentageOption:set_default_value(
        TotoWar_Cbac_Constant.optionDefaultValue_aiArmyHeroMaximumPercentage)
    aiArmyHeroMaximumPercentageOption:set_text(
        "totowar_cbac_mct_option_caption_aiArmyHeroMaximumPercentage")
    aiArmyHeroMaximumPercentageOption:set_tooltip_text(
        "totowar_cbac_mct_option_tooltip_aiArmyHeroMaximumPercentage")
    cbacAiSection:assign_option(aiArmyHeroMaximumPercentageOption)

    local aiArmyRangedInfantryMaximumPercentageOption = mctMod:add_new_option(
        TotoWar_Cbac_Constant.optionName_aiArmyRangedInfantryMaximumPercentage,
        "slider")
    aiArmyRangedInfantryMaximumPercentageOption:slider_set_min_max(0, 100)
    aiArmyRangedInfantryMaximumPercentageOption:slider_set_step_size(5)
    aiArmyRangedInfantryMaximumPercentageOption:set_default_value(
        TotoWar_Cbac_Constant.optionDefaultValue_aiArmyRangedInfantryMaximumPercentage)
    aiArmyRangedInfantryMaximumPercentageOption:set_text(
        "totowar_cbac_mct_option_caption_aiArmyRangedInfantryMaximumPercentage")
    aiArmyRangedInfantryMaximumPercentageOption:set_tooltip_text(
        "totowar_cbac_mct_option_tooltip_aiArmyRangedInfantryMaximumPercentage")
    cbacAiSection:assign_option(aiArmyRangedInfantryMaximumPercentageOption)

    local aiArmyCavalryAndMonstersMaximumPercentageOption = mctMod:add_new_option(
        TotoWar_Cbac_Constant.optionName_aiArmyCavalryAndMonstersMaximumPercentage,
        "slider")
    aiArmyCavalryAndMonstersMaximumPercentageOption:slider_set_min_max(0, 100)
    aiArmyCavalryAndMonstersMaximumPercentageOption:slider_set_step_size(5)
    aiArmyCavalryAndMonstersMaximumPercentageOption:set_default_value(
        TotoWar_Cbac_Constant.optionDefaultValue_aiArmyCavalryAndMonstersMaximumPercentage)
    aiArmyCavalryAndMonstersMaximumPercentageOption:set_text(
        "totowar_cbac_mct_option_caption_aiArmyCavalryAndMonstersMaximumPercentage")
    aiArmyCavalryAndMonstersMaximumPercentageOption:set_tooltip_text(
        "totowar_cbac_mct_option_tooltip_aiArmyCavalryAndMonstersMaximumPercentage")
    cbacAiSection:assign_option(aiArmyCavalryAndMonstersMaximumPercentageOption)

    local aiArmyWarMachinesMaximumPercentageOption = mctMod:add_new_option(
        TotoWar_Cbac_Constant.optionName_aiArmyWarMachinesMaximumPercentage,
        "slider")
    aiArmyWarMachinesMaximumPercentageOption:slider_set_min_max(0, 100)
    aiArmyWarMachinesMaximumPercentageOption:slider_set_step_size(5)
    aiArmyWarMachinesMaximumPercentageOption:set_default_value(
        TotoWar_Cbac_Constant.optionDefaultValue_aiArmyWarMachinesMaximumPercentage)
    aiArmyWarMachinesMaximumPercentageOption:set_text(
        "totowar_cbac_mct_option_caption_aiArmyWarMachinesMaximumPercentage")
    aiArmyWarMachinesMaximumPercentageOption:set_tooltip_text(
        "totowar_cbac_mct_option_tooltip_aiArmyWarMachinesMaximumPercentage")
    cbacAiSection:assign_option(aiArmyWarMachinesMaximumPercentageOption)
end
