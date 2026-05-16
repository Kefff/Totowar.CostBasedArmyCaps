---Internal DP State used for the knapsack algorithm.
---
---Stores how many units were removed per category (in a fixed order).
---@class TotoWarCbacAiManagerAdjustmentState
---@field categories string[]
---@field categoryIndex table<string, integer>
---@field maxPerCategory integer[]
---@field counts integer[]
TotoWarCbacAiManagerAdjustmentState = {}
TotoWarCbacAiManagerAdjustmentState.__index = TotoWarCbacAiManagerAdjustmentState

---@param categories string[]
---@param maxPerCategory table<string, integer>
---@return TotoWarCbacAiManagerAdjustmentState
function TotoWarCbacAiManagerAdjustmentState.new(categories, maxPerCategory)
    ---@type table<string, integer>
    local index = {}

    ---@type integer[]
    local maxArr = {}

    ---@type integer[]
    local counts = {}

    for i, cat in ipairs(categories) do
        index[cat] = i
        maxArr[i] = maxPerCategory[cat] or 0
        counts[i] = 0
    end

    ---@type TotoWarCbacAiManagerAdjustmentState
    local o = {
        categories = categories,
        categoryIndex = index,
        maxPerCategory = maxArr,
        counts = counts
    }

    return setmetatable(o, TotoWarCbacAiManagerAdjustmentState)
end

---@return TotoWarCbacAiManagerAdjustmentState
function TotoWarCbacAiManagerAdjustmentState:clone()
    ---@type integer[]
    local newCounts = {}

    for i = 1, #self.counts do
        newCounts[i] = self.counts[i]
    end

    ---@type TotoWarCbacAiManagerAdjustmentState
    local o = {
        categories = self.categories,
        categoryIndex = self.categoryIndex,
        maxPerCategory = self.maxPerCategory,
        counts = newCounts
    }

    return setmetatable(o, TotoWarCbacAiManagerAdjustmentState)
end

---@param category string
---@return boolean
function TotoWarCbacAiManagerAdjustmentState:canAdd(category)
    local idx = self.categoryIndex[category]
    if not idx then
        return false
    end

    return (self.counts[idx] + 1) <= self.maxPerCategory[idx]
end

---@param category string
function TotoWarCbacAiManagerAdjustmentState:add(category)
    local idx = self.categoryIndex[category]
    if idx then
        self.counts[idx] = self.counts[idx] + 1
    end
end

---@param category string
---@return integer
function TotoWarCbacAiManagerAdjustmentState:get(category)
    local idx = self.categoryIndex[category]
    if not idx then
        return 0
    end

    return self.counts[idx]
end

---@return integer
function TotoWarCbacAiManagerAdjustmentState:getSatisfiedScore()
    local score = 0
    for i = 1, #self.counts do
        score = score + self.counts[i]
    end
    return score
end

---@return string
function TotoWarCbacAiManagerAdjustmentState:getKey()
    if #self.counts == 0 then
        return ""
    end

    -- Key is a compact CSV of counts in the fixed category order.
    -- Ex: "1,0,3"
    return table.concat(self.counts, ",")
end

---@param key string
---@param categories string[]
---@param maxPerCategory table<string, integer>
---@return TotoWarCbacAiManagerAdjustmentState
function TotoWarCbacAiManagerAdjustmentState.newFromKey(key, categories, maxPerCategory)
    local st = TotoWarCbacAiManagerAdjustmentState.new(categories, maxPerCategory)

    if key == "" then
        return st
    end

    local i = 1
    for num in string.gmatch(key, "([^,]+)") do
        st.counts[i] = tonumber(num) or 0
        i = i + 1
    end

    return st
end
