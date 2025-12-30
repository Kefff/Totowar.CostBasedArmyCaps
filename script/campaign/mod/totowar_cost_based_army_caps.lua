local modName = "totowar_cost_based_army_caps"

cm:add_first_tick_callback(
    function()
        local totowarCbacManager = core:get_static_object(modName)
        totowarCbacManager.isDebug = true -- TEST
        totowarCbacManager:initialize()
    end)
