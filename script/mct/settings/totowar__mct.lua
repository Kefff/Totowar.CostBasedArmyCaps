require("script._lib.mod.totowar__mod_options")

---@diagnostic disable-next-line: undefined-global
local mct = get_mct()

if mct then
    local totoWarMod = mct:register_mod(TotoWar_ModName)
    totoWarMod:set_author("Kefff")
    totoWarMod:set_description("totowar_mct_description")
    totoWarMod:set_title("TotoWar mods")

    -- Replacing the default page that lists all the options of all the mods.
    -- A default page needs to exist because by default, the first page always displays all the options of all the pages.
    -- We replace the default page to be able to customize the text of its menu entry and the page layout (1 column instead of 2).
    local defaultSettingsPage = totoWarMod:get_default_settings_page()
    totoWarMod:remove_settings_page(defaultSettingsPage)
    totoWarMod:create_settings_page("TotoWar - All options", 1)                           -- For some reason the key used to identify the page is displayed to the user, but using a localised text does not work

    local totoWarModPage = totoWarMod:create_settings_page("TotoWar - Global options", 1) -- For some reason the key used to identify the page is displayed to the user, but using a localised text does not work

    -- Debug section
    local debugAndLogsSection = totoWarMod:add_new_section(
        "totowar_section_debug",
        "totowar_mct_section_title_debug")
    totoWarModPage:assign_section_to_page(debugAndLogsSection)

    local debugEnabledOption = totoWarMod:add_new_option(
        TotoWar_OptionName_DebugEnabled,
        "checkbox")
    debugEnabledOption:set_default_value(TotoWar_OptionDefaultValue_DebugEnabled)
    debugEnabledOption:set_text("totowar_mct_option_caption_debugEnabled")
    debugEnabledOption:set_tooltip_text("totowar_mct_option_tooltip_debugEnabled")
    debugAndLogsSection:assign_option(debugEnabledOption)

    -- Logs section
    local logsSection = totoWarMod:add_new_section(
        "totowar_section_logs",
        "totowar_mct_section_title_logs")
    totoWarModPage:assign_section_to_page(logsSection)

    local genericLoggerEnabledOption = totoWarMod:add_new_option(
        TotoWar_OptionName_GenericLoggerEnabled,
        "checkbox")
    genericLoggerEnabledOption:set_default_value(TotoWar_OptionDefaultValue_GenericLoggerEnabled)
    genericLoggerEnabledOption:set_text("totowar_mct_option_caption_genericLoggerEnabled")
    genericLoggerEnabledOption:set_tooltip_text("totowar_mct_option_tooltip_genericLoggerEnabled")
    logsSection:assign_option(genericLoggerEnabledOption)

    local uiUtilsLoggerEnabledOption = totoWarMod:add_new_option(
        TotoWar_OptionName_UiUtilsLoggerEnabled,
        "checkbox")
    uiUtilsLoggerEnabledOption:set_default_value(TotoWar_OptionDefaultValue_UiUtilsLoggerEnabled)
    uiUtilsLoggerEnabledOption:set_text("totowar_mct_option_caption_uiUtilsLoggerEnabled")
    uiUtilsLoggerEnabledOption:set_tooltip_text("totowar_mct_option_tooltip_ui_utilsLoggerEnabled")
    logsSection:assign_option(uiUtilsLoggerEnabledOption)

    local utilsLoggerEnabledOption = totoWarMod:add_new_option(
        TotoWar_OptionName_UtilsLoggerEnabled,
        "checkbox")
    utilsLoggerEnabledOption:set_default_value(TotoWar_OptionDefaultValue_UtilsLoggerEnabled)
    utilsLoggerEnabledOption:set_text("totowar_mct_option_caption_utilsLoggerEnabled")
    utilsLoggerEnabledOption:set_tooltip_text("totowar_mct_option_tooltip_utilsLoggerEnabled")
    logsSection:assign_option(utilsLoggerEnabledOption)
end
