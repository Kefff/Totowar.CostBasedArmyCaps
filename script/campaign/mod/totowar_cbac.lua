cm:add_first_tick_callback(
    function()
        ---Registering the mod
        TotoWar.modsManager:registerMod(
            TotoWarCbacModName,
            ---@param modsManager TotoWarModsManager
            ---@return TotoWarCbacMod
            function(modsManager)
                return TotoWarCbacMod:new()
            end)
    end)
