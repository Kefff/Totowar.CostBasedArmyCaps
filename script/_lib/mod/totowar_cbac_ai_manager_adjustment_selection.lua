---State class used to store unit removal counts for constrained categories when adjusting the units of an AI army.
---@class TotoWarCbacAiManagerAdjustmentSelection
---@field categories string[]
---@field minReq TotoWarDictionary<string, integer>
---@field counts integer[]
TotoWarCbacAiManagerAdjustmentSelection = {}
TotoWarCbacAiManagerAdjustmentSelection.__index = TotoWarCbacAiManagerAdjustmentSelection

---Initializes a new instance.
---@param categories string[]
---@param minReq TotoWarDictionary<string, integer>
---@return TotoWarCbacAiManagerAdjustmentSelection
function TotoWarCbacAiManagerAdjustmentSelection.new(categories, minReq)
    ---@type TotoWarCbacAiManagerAdjustmentSelection
    local self = setmetatable({}, TotoWarCbacAiManagerAdjustmentSelection)
    self.categories = categories
    self.minReq = minReq
    self.counts = {}

    for i = 1, #categories do
        self.counts[i] = 0
    end

    return self
end

---Initializes a new instance from a key string, categories and requirements.
---@param key string
---@param categories string[]
---@param minReq TotoWarDictionary<string, integer>
---@return TotoWarCbacAiManagerAdjustmentSelection
function TotoWarCbacAiManagerAdjustmentSelection.newFromKey(key, categories, minReq)
    local instance = TotoWarCbacAiManagerAdjustmentSelection.new(categories, minReq)
    local index = 1

    for num in string.gmatch(key, "([^,]+)") do
        instance.counts[index] = tonumber(num) or 0
        index = index + 1
    end

    return instance
end

---Increments the count for the given category, if it exists in the categories list.
---@param category string
function TotoWarCbacAiManagerAdjustmentSelection:add(category)
    for i, cat in ipairs(self.categories) do
        if cat == category then
            self.counts[i] = self.counts[i] + 1

            -- Clamp to requirement (beyond requirement doesn't matter)
            local req = self.minReq:get(cat)

            if self.counts[i] > req then
                self.counts[i] = req
            end

            return
        end
    end
end

---Creates a copy of the instance.
---@return TotoWarCbacAiManagerAdjustmentSelection
function TotoWarCbacAiManagerAdjustmentSelection:clone()
    ---@type TotoWarCbacAiManagerAdjustmentSelection
    local copy = setmetatable({}, TotoWarCbacAiManagerAdjustmentSelection)
    copy.categories = self.categories
    copy.minReq = self.minReq
    copy.counts = { unpack(self.counts) }

    return copy
end

---Gets a unique key representing the counts for the given categories and requirements.
---@param categories string[]
---@param minReq TotoWarDictionary<string, integer>
---@return string
function TotoWarCbacAiManagerAdjustmentSelection.getFinalKey(categories, minReq)
    local counts = {}
    for i, cat in ipairs(categories) do
        counts[i] = minReq:get(cat)
    end
    return table.concat(counts, ",")
end

---Gets a unique key representing the current counts for all categories.
---@return string
function TotoWarCbacAiManagerAdjustmentSelection:getKey()
    return table.concat(self.counts, ",")
end
