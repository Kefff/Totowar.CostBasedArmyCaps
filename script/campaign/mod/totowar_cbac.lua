cm:add_first_tick_callback(
    function()
        -- TEST
        TotoWarUtils.isDebug = true
        TotoWarUtils.logger.isEnabled = false
        -- /TEST

        local totowarCbacManager = core:get_static_object(totowarCbacModName)
        totowarCbacManager:initialize()
    end)
