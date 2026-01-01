cm:add_first_tick_callback(
    function()
        TotoWarUtils.isDebug = true -- TEST

        local totowarCbacManager = core:get_static_object(totowarCbacModName)
        totowarCbacManager:initialize()
    end)
