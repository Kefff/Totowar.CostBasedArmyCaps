cm:add_first_tick_callback(
    function()
        ---Registering the mod
        TotoWar__ModsManager:registerMod(
            TotoWar_Cbac_Constant.modName,
            TotoWar_Cbac_Constant.modCaption,
            function() TotoWar_Cbac_Mod:initialize() end)
    end)
