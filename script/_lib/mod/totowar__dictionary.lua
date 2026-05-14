---Represents a key / value couple in a dictionary.
---@class TotoWarKeyValue<T, Y>
---@field key T
---@field value Y
TotoWarKeyValue = {}
TotoWarKeyValue.__index = TotoWarKeyValue

---Initializes a new instance.
---@param key T Key.
---@param value Y Value.
---@return TotoWarKeyValue<T, Y>
function TotoWarKeyValue.new(key, value)
    local instance = setmetatable({}, TotoWarKeyValue)

    instance.key = key
    instance.value = value

    return instance
end

---Represents a dictionary that can be sorted.
---@class TotoWarDictionary<T, Y>
---@field entries TotoWarKeyValue<T, Y>[]
TotoWarDictionary = {
    entries = {}
}
TotoWarDictionary.__index = TotoWarDictionary

---Initializes a new instance.
---@return TotoWarDictionary<T, Y>
function TotoWarDictionary.new()
    local instance = setmetatable({}, TotoWarDictionary)

    instance.entries = {}

    return instance
end

---Indicates whether a key exists.
---@param key T Key.
---@return boolean
function TotoWarDictionary:exists(key)
    local exists = TotoWarLinq:any(self.entries, function(e) return e.key == key end)

    return exists
end

---Gets the value corresponding to a key if it exists.
---@param key T Key
---@return Y | nil
function TotoWarDictionary:get(key)
    local entry = TotoWarLinq:firstOrDefault(self.entries, function(e) return e.key == key end)

    if entry == nil then
        return nil
    end

    return entry.value
end

---Gets the existing keys.
---@return T[]
function TotoWarDictionary:getKeys()
    local keys = TotoWarLinq:select(self.entries, function(e) return e.key end)

    return keys
end

---Gets the existing values.
---@return Y[]
function TotoWarDictionary:getValues()
    local values = TotoWarLinq:select(self.entries, function(e) return e.value end)

    return values
end

---Deletes the entry corresponding to a key if it exists.
---@param key T Key.
function TotoWarDictionary:remove(key)
    local entryIndex = TotoWarLinq:findIndex(self.entries, function(e) return e.key == key end)

    if entryIndex < 0 then
        return
    end

    table.remove(self.entries, entryIndex)
end

---Sets the value corresponding to a key. Replaces the previous value when the key already exists.
---@param key T Key
---@return Y | nil
function TotoWarDictionary:set(key, value)
    local entry = TotoWarLinq:firstOrDefault(self.entries, function(e) return e.key == key end)

    if entry == nil then
        entry = TotoWarKeyValue.new(key, value)
        table.insert(self.entries, entry)
    end

    entry.value = value
end
