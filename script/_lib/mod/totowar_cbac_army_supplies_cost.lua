---@class TotoWarCbacArmySuppliesCost
TotoWarCbacArmySuppliesCost = {
    ---Total army supplies cost detailed by unit type.
    ---@type TotoWarCbacUnitArmySuppliesCost[]
    details = nil,

    ---Total army supplies cost
    ---@type number
    totalCost = 0,
}
TotoWarCbacArmySuppliesCost.__index = TotoWarCbacArmySuppliesCost

---Initializes a new instance.
---@param army MILITARY_FORCE_SCRIPT_INTERFACE
---@return TotoWarCbacArmySuppliesCost
function TotoWarCbacArmySuppliesCost.new(army)
    TotoWar().genericLogger:logDebug("TotoWarCbacArmySuppliesCost.new(%s): STARTED", army:command_queue_index())

    local instance = setmetatable({}, TotoWarCbacArmySuppliesCost)

    local units = army:unit_list()
    local details = {}

    for i = 0, units:num_items() - 1, 1 do
        local unit = units:item_at(i)
        local unitCost = unit:get_unit_custom_battle_cost()

        ---@type TotoWarCbacUnitArmySuppliesCost
        local unitArmySuppliesCost = nil

        for j, detail in ipairs(details) do
            if detail.unitKey == unit:unit_key() then
                unitArmySuppliesCost = detail
                break
            end
        end

        if not unitArmySuppliesCost then
            unitArmySuppliesCost = TotoWarCbacUnitArmySuppliesCost.new(unit:unit_key(), unitCost)
            table.insert(details, unitArmySuppliesCost)
        else
            unitArmySuppliesCost:addUnit()
        end

        instance.totalCost = instance.totalCost + unitCost
    end

    instance.details = details

    TotoWar().genericLogger:logDebug("TotoWarCbacArmySuppliesCost.new(%s): COMPLETED", army:command_queue_index())

    return instance
end

---Gets the list of unit army supplies costs as a tooltip string.
---@param armySupplies number Army supplies.
---@return string
function TotoWarCbacArmySuppliesCost:toTooltipText(armySupplies)
    TotoWar().genericLogger:logDebug("TotoWarCbacArmySuppliesCost:toTooltipText(%s): STARTED", armySupplies)

    local unitsArmySuppliesCostTooltipText = ""

    for i, unitArmySuppliesCost in ipairs(self.details) do
        if i > 0 then
            unitsArmySuppliesCostTooltipText = unitsArmySuppliesCostTooltipText .. "\n"
        end

        unitsArmySuppliesCostTooltipText = unitsArmySuppliesCostTooltipText .. unitArmySuppliesCost:toTooltipText()
    end

    local availableArmySupplies = armySupplies - self.totalCost
    local availableArmySuppliesString = tostring(availableArmySupplies)
    local depletedArmySuppliesWarning = ""

    if availableArmySupplies < 0 then
        availableArmySuppliesString = string.format(
            "[[col:%s]]%s[[/col]]",
            TotoWar().utils.enums.color.red,
            availableArmySupplies)
        depletedArmySuppliesWarning = string.format(
            "\n\n[[col:%s]]%s[[/col]]",
            TotoWar().utils.enums.color.red,
            common.get_localised_string("totowar_cbac_unit_army_supply_cost_tooltip_depleted"))
    end

    local tooltipText = string.format(
        common.get_localised_string("totowar_cbac_army_supply_cost_tooltip"),
        armySupplies,
        self.totalCost,
        availableArmySuppliesString,
        depletedArmySuppliesWarning,
        unitsArmySuppliesCostTooltipText)

    TotoWar().genericLogger:logDebug("TotoWarCbacArmySuppliesCost:toTooltipText(%s): COMPLETED", armySupplies)

    return tooltipText
end
