require("script._lib.mod.totowar__mod_options")

---@diagnostic disable-next-line: undefined-global
local mct = get_mct()

if mct then
    local totoWarMod = mct:register_mod(TotoWar_ModName)
    totoWarMod:set_author("Kefff")
    totoWarMod:set_description("totowar_mct_description")
    totoWarMod:set_title("TotoWar mods")

    -- local defaultSettingsPage = totoWarMod:get_default_settings_page()
    -- totoWarMod:remove_settings_page(defaultSettingsPage)

    local totoWarModPage = totoWarMod:create_settings_page("TotoWar global options", 1) -- For some reason the key used to identify the page is displayed to the user, but using a localised text does not work

    local globalSection = totoWarMod:add_new_section("totowar_section", "totowar_mct_section_title")
    totoWarModPage:assign_section_to_page(globalSection)

    local debugEnabledOption = totoWarMod:add_new_option(TotoWar_OptionName_DebugEnabled, "checkbox")
    debugEnabledOption:set_default_value(TotoWar_OptionDefaultValue_DebugEnabled)
    debugEnabledOption:set_text("totowar_mct_option_text_debug_enabled")
    debugEnabledOption:set_tooltip_text("totowar_mct_option_tooltip_debug_enabled")
    debugEnabledOption:set_is_global(true)
    globalSection:assign_option(debugEnabledOption)
end
