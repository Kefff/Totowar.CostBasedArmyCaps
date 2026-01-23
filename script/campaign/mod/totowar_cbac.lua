cm:add_first_tick_callback(
    function()
        ---Registering the mod
        TotoWar().modsManager:registerMod(
            TotoWarCbacModName,
            ---@param modsManager TotoWarModsManager
            ---@return TotoWarCbac
            function(modsManager)
                return TotoWarCbac:new()
            end)
    end)
