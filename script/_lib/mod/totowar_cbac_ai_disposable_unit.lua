---@class TotoWarCbacAiDisposableUnit
TotoWarCbacAiDisposableUnit = {
    ---Army supplies cost of the unit.
    armySuppliesCost = 0,

    ---Unit key.
    ---@type string
    key = nil,

    ---Real cost for recruiting the unit.
    ---Used to reimburse the AI when removing a recruited unit that exceeds the army supplies cost available.
    realCost = 0
}
TotoWarCbacAiDisposableUnit.__index = TotoWarCbacAiDisposableUnit

---Initializes a new instance.
---@param unit UNIT_SCRIPT_INTERFACE Unit.
---@param armySuppliesCost number Army supplies cost of the unit.
---@return TotoWarCbacAiDisposableUnit
function TotoWarCbacAiDisposableUnit.new(unit, armySuppliesCost)
    local instance = setmetatable({}, TotoWarCbacAiDisposableUnit)

    instance.armySuppliesCost = armySuppliesCost
    instance.key = unit:unit_key()
    instance.realCost = cco("CcoCampaignUnit", unit:command_queue_index()):Call("Cost")

    return instance
end
