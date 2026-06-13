cm:add_first_tick_callback(
    function()
        ---Registering the mod
        TotoWar.modsManager:registerMod(
            TotoWar_Cbac_Constant.modName,
            ---@param modsManager TotoWar__ModsManager
            ---@return TotoWar_Cbac_Mod
            function(modsManager)
                return TotoWar_Cbac_Mod.new()
            end)
    end)
