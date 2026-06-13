require("script._lib.mod.totowar__constant")

---@diagnostic disable-next-line: undefined-global
local mct = get_mct()

if mct then
    local mctMod = mct:register_mod(TotoWar__Constant.modName)
    mctMod:set_author("Kefff")
    mctMod:set_description("totowar_mct_description")
    mctMod:set_title("TotoWar mods")

    -- Replacing the default page that lists all the options of all the mods.
    -- A default page needs to exist because by default, the first page always displays all the options of all the pages.
    -- We replace the default page to be able to customize the text of its menu entry and the page layout (1 column instead of 2).
    local defaultSettingsPage = mctMod:get_default_settings_page()
    mctMod:remove_settings_page(defaultSettingsPage)
    mctMod:create_settings_page("TotoWar - All options", 1)                           -- For some reason the key used to identify the page is displayed to the user, but using a localised text does not work

    local totoWarModPage = mctMod:create_settings_page("TotoWar - Global options", 1) -- For some reason the key used to identify the page is displayed to the user, but using a localised text does not work

    -- Debug section
    local debugAndLogsSection = mctMod:add_new_section(
        "totowar_section_debug",
        "totowar_mct_section_title_debug")
    totoWarModPage:assign_section_to_page(debugAndLogsSection)

    local debugEnabledOption = mctMod:add_new_option(
        TotoWar__Constant.optionName_debugEnabled,
        "checkbox")
    debugEnabledOption:set_default_value(TotoWar__Constant.optionDefaultValue_debugEnabled)
    debugEnabledOption:set_text("totowar_mct_option_caption_debugEnabled")
    debugEnabledOption:set_tooltip_text("totowar_mct_option_tooltip_debugEnabled")
    debugAndLogsSection:assign_option(debugEnabledOption)
end
