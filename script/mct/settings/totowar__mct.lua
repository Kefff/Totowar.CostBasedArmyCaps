require("script._lib.mod.totowar__mod_options")

---@diagnostic disable-next-line: undefined-global
local mct = get_mct()

if mct then
    local TotoWar__Mod = mct:register_mod(TotoWar__ModName)
    TotoWar__Mod:set_author("Kefff")
    TotoWar__Mod:set_description("totowar_mct_description")
    TotoWar__Mod:set_title("TotoWar mods")

    -- Replacing the default page that lists all the options of all the mods.
    -- A default page needs to exist because by default, the first page always displays all the options of all the pages.
    -- We replace the default page to be able to customize the text of its menu entry and the page layout (1 column instead of 2).
    local defaultSettingsPage = TotoWar__Mod:get_default_settings_page()
    TotoWar__Mod:remove_settings_page(defaultSettingsPage)
    TotoWar__Mod:create_settings_page("TotoWar - All options", 1)                           -- For some reason the key used to identify the page is displayed to the user, but using a localised text does not work

    local totoWarModPage = TotoWar__Mod:create_settings_page("TotoWar - Global options", 1) -- For some reason the key used to identify the page is displayed to the user, but using a localised text does not work

    -- Debug section
    local debugAndLogsSection = TotoWar__Mod:add_new_section(
        "totowar_section_debug",
        "totowar_mct_section_title_debug")
    totoWarModPage:assign_section_to_page(debugAndLogsSection)

    local debugEnabledOption = TotoWar__Mod:add_new_option(
        TotoWar__OptionName_DebugEnabled,
        "checkbox")
    debugEnabledOption:set_default_value(TotoWar__OptionDefaultValue_DebugEnabled)
    debugEnabledOption:set_text("totowar_mct_option_caption_debugEnabled")
    debugEnabledOption:set_tooltip_text("totowar_mct_option_tooltip_debugEnabled")
    debugAndLogsSection:assign_option(debugEnabledOption)
end
