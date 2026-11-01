---Internal DP State used for the knapsack algorithm.
---
---Stores how many units were removed per category (in a fixed order).
---@class TotoWar_Cbac_AiManagerAdjustmentState
---@field categories string[]
---@field maxPerCategory table<string, integer>
---@field counts table<string, integer>
TotoWar_Cbac_AiManagerAdjustmentState = {}
TotoWar_Cbac_AiManagerAdjustmentState.__index = TotoWar_Cbac_AiManagerAdjustmentState

---@param categories string[]
---@param maxPerCategory table<string, integer>
---@return TotoWar_Cbac_AiManagerAdjustmentState
function TotoWar_Cbac_AiManagerAdjustmentState.new(categories, maxPerCategory)
    ---@type TotoWar_Cbac_AiManagerAdjustmentState
    local self = setmetatable({}, TotoWar_Cbac_AiManagerAdjustmentState)

    self.categories = categories
    self.maxPerCategory = maxPerCategory
    self.counts = {}

    for _, cat in ipairs(categories) do
        self.counts[cat] = 0
    end

    return self
end

---@param key string
---@param categories string[]
---@param maxPerCategory table<string, integer>
---@return TotoWar_Cbac_AiManagerAdjustmentState
function TotoWar_Cbac_AiManagerAdjustmentState.newFromKey(key, categories, maxPerCategory)
    local state = TotoWar_Cbac_AiManagerAdjustmentState.new(categories, maxPerCategory)

    if key == "" then
        return state
    end

    local i = 1
    for num in string.gmatch(key, "([^,]+)") do
        local cat = categories[i]
        if cat then
            state.counts[cat] = tonumber(num) or 0
        end
        i = i + 1
    end

    return state
end

---@return TotoWar_Cbac_AiManagerAdjustmentState
function TotoWar_Cbac_AiManagerAdjustmentState:clone()
    local copy = TotoWar_Cbac_AiManagerAdjustmentState.new(self.categories, self.maxPerCategory)

    for _, cat in ipairs(self.categories) do
        copy.counts[cat] = self.counts[cat]
    end

    return copy
end

---@param category string
---@return boolean
function TotoWar_Cbac_AiManagerAdjustmentState:canAdd(category)
    local maxAllowed = self.maxPerCategory[category]
    if maxAllowed == nil then
        return false
    end

    local current = self.counts[category] or 0
    return (current + 1) <= maxAllowed
end

---@param category string
function TotoWar_Cbac_AiManagerAdjustmentState:add(category)
    self.counts[category] = (self.counts[category] or 0) + 1
end

---@return string
function TotoWar_Cbac_AiManagerAdjustmentState:getKey()
    if #self.categories == 0 then
        return ""
    end

    local parts = {}
    for _, cat in ipairs(self.categories) do
        table.insert(parts, tostring(self.counts[cat] or 0))
    end

    return table.concat(parts, ",")
end

---@return integer
function TotoWar_Cbac_AiManagerAdjustmentState:getSatisfiedScore()
    local score = 0
    for _, cat in ipairs(self.categories) do
        score = score + (self.counts[cat] or 0)
    end
    return score
end
