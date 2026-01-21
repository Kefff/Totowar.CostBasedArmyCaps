cm:add_first_tick_callback(
    function()
        ---Registering the mod
        -- core:get_static_object(TotoWarCoreModName).modsManager:registerMod(
        TotoWar().modsManager:registerMod(
            TotoWarCbacModName,
            ---@param modsManager TotoWarModsManager
            ---@return TotoWarCbac
            function(modsManager)
                return TotoWarCbac:new()
            end)
    end)
