require("script._lib.mod.totowar__mod_options")

---@diagnostic disable-next-line: undefined-global
local mct = get_mct()

if mct then
    local totoWarMod = mct:register_mod(TotoWar_ModName)
    totoWarMod:set_author("Kefff")
    totoWarMod:set_description("Global options for the TotoWar mods")
    totoWarMod:set_title("TotoWar mods")

    local defaultSettingsPage = totoWarMod:get_default_settings_page()
    totoWarMod:remove_settings_page(defaultSettingsPage)

    local totoWarModPage = totoWarMod:create_settings_page("TotoWar global options", 1)

    local globalSection = totoWarMod:add_new_section("totowar_global_section", "TotoWar global options")
    globalSection:set_description("Global options for all TotoWar mods")
    totoWarModPage:assign_section_to_page(globalSection)

    local debugEnabledOption = totoWarMod:add_new_option(TotoWar_OptionName_DebugEnabled, "checkbox")
    debugEnabledOption:set_default_value(TotoWar_OptionDefaultValue_DebugEnabled)
    debugEnabledOption:set_text("Debug mode [[img:totowar_alert]][[/img]][[col:red]]HEAVY PERFORMANCE IMPACT[[/col]]")
    debugEnabledOption:set_tooltip_text(
        "Enables the debug mode for TotoWar mods.\n\n[[img:totowar_alert]][[/img]][[col:red]]THIS HEAVILY REDUCES THE GAME PERFORMANCES ! ONLY ACTIVATE THIS OPTION WHEN NEEDED.[[/col]]\n\nDebug mode creates a [[col:alliance_ally]]totowar_logs.txt[[/col]] file in your game folder in which advanced debug logs are stored.\nOnly useful when you need to report a bug in order to be able to figure out what is happening.\n\n[[col:alliance_ally]]Unchecked[[/col]] by default.")
    debugEnabledOption:set_is_global(true)
    globalSection:assign_option(debugEnabledOption)
end
