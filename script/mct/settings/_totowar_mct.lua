require("script._lib.mod.totowar_core_options")

---@diagnostic disable-next-line: undefined-global
local mct = get_mct()

if mct then
    local totoWarMod = mct:register_mod(TotoWarModName)
    totoWarMod:set_author("Kefff")
    totoWarMod:set_description("Global options for the TotoWar mods")
    totoWarMod:set_title("TotoWar mods")

    local defaultSettingsPage = totoWarMod:get_default_settings_page()
    totoWarMod:remove_settings_page(defaultSettingsPage)

    local totoWarModPage = totoWarMod:create_settings_page("TotoWar global options", 1)

    local globalSection = totoWarMod:add_new_section("totowar_global_section", "TotoWar global options")
    globalSection:set_description("Global options for all TotoWar mods")
    totoWarModPage:assign_section_to_page(globalSection)

    local debugModeOption = totoWarMod:add_new_option(TotoWarDebugOptionName, "checkbox")
    debugModeOption:set_default_value(false)
    debugModeOption:set_text("Debug mode")
    debugModeOption:set_tooltip_text(
        "Activates the debug mode for TotoWar mods.\n\n[[col:red]]WARNING : THIS HEAVILY REDUCES THE GAME PERFORMANCES ! ONLY ACTIVATE THIS OPTION WHEN NEEDED.[[/col]]\n\nCreates a [[col:alliance_ally]]totowar_logs.txt[[/col]] file in your game folder in which advanced debug information are stored.\nOnly useful when you need to report a bug in order to be able to figure out what is happening.\n\n[[col:alliance_ally]]Unchecked[[/col]] by default.")
    debugModeOption:set_is_global(true)
    globalSection:assign_option(debugModeOption)
end
