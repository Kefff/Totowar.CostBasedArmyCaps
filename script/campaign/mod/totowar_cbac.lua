cm:add_first_tick_callback(
    function()
        -- TEST
        TotoWarUtils.isDebug = true
        TotoWarUtils.logger.isEnabled = false
        -- /TEST

        local totoWarCbacManager = core:get_static_object(totowarCbacModName)
        totoWarCbacManager:initialize()
    end)
