---State class used to store unit removal counts for constrained categories when adjusting the units of an AI army.
---@class TotoWarCbacAiManagerAdjustmentSelection
---@field categories string[]
---@field minReq table<string, integer>
---@field counts integer[]
TotoWarCbacAiManagerAdjustmentSelection = {}
TotoWarCbacAiManagerAdjustmentSelection.__index = TotoWarCbacAiManagerAdjustmentSelection

---Initializes a new instance.
---@param categories string[]
---@param minReq table<string, integer>
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
---@param minReq table<string, integer>
---@return TotoWarCbacAiManagerAdjustmentSelection
function TotoWarCbacAiManagerAdjustmentSelection.newFromKey(key, categories, minReq)
    local st = TotoWarCbacAiManagerAdjustmentSelection.new(categories, minReq)
    local idx = 1
    for num in string.gmatch(key, "([^,]+)") do
        st.counts[idx] = tonumber(num) or 0
        idx = idx + 1
    end
    return st
end

---Increments the count for the given category, if it exists in the categories list.
---@param category string
function TotoWarCbacAiManagerAdjustmentSelection:add(category)
    for i, cat in ipairs(self.categories) do
        if cat == category then
            self.counts[i] = self.counts[i] + 1

            -- Clamp to requirement (beyond requirement doesn't matter)
            local req = self.minReq[cat]

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
---@param minReq table<string, integer>
---@return string
function TotoWarCbacAiManagerAdjustmentSelection.getFinalKey(categories, minReq)
    local counts = {}
    for i, cat in ipairs(categories) do
        counts[i] = minReq[cat]
    end
    return table.concat(counts, ",")
end

---Gets a unique key representing the current counts for all categories.
---@return string
function TotoWarCbacAiManagerAdjustmentSelection:getKey()
    return table.concat(self.counts, ",")
end
