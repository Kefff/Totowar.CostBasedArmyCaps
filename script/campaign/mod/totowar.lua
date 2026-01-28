cm:add_pre_first_tick_callback(
    function()
        ---Creating the TotoWar core instance before the first tick where TotoWar mods will be registered
        local totoWar = TotoWarCore.new()

        -- TEST
        totoWar.isDebug = true
        totoWar.genericLogger.isEnabled = true
        -- /TEST
    end)

cm:add_post_first_tick_callback(
    function()
        ---Initializing TotoWar mods after the first tick where they have been registered
        TotoWar().modsManager:initializeMods()
    end)
