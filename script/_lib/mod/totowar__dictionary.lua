---Represents a key / value couple in a dictionary.
---@class TotoWar__KeyValue<T, Y>
---@field key T
---@field value Y
TotoWar__KeyValue = {}
TotoWar__KeyValue.__index = TotoWar__KeyValue

---Initializes a new instance.
---@param key T Key.
---@param value Y Value.
---@return TotoWar__KeyValue<T, Y>
function TotoWar__KeyValue.new(key, value)
    local instance = setmetatable({}, TotoWar__KeyValue)

    instance.key = key
    instance.value = value

    return instance
end

---Represents a dictionary that can be sorted.
---@class TotoWar__Dictionary<T, Y>
---@field entries TotoWar__KeyValue<T, Y>[]
TotoWar__Dictionary = {
    entries = {}
}
TotoWar__Dictionary.__index = TotoWar__Dictionary

---Initializes a new instance.
---@return TotoWar__Dictionary<T, Y>
function TotoWar__Dictionary.new()
    local instance = setmetatable({}, TotoWar__Dictionary)

    instance.entries = {}

    return instance
end

---Indicates whether a key exists.
---@param key T Key.
---@return boolean
function TotoWar__Dictionary:exists(key)
    local exists = TotoWar__Linq:any(self.entries, function(e) return e.key == key end)

    return exists
end

---Gets the value corresponding to a key if it exists.
---@param key T Key
---@return Y
function TotoWar__Dictionary:get(key)
    local entry = TotoWar__Linq:firstOrDefault(self.entries, function(e) return e.key == key end)

    if entry == nil then
        TotoWar.loggers.generic:logError("Dictionary key \"%s\" not found", tostring(key))

        ---@diagnostic disable-next-line: return-type-mismatch
        return nil
    end

    return entry.value
end

---Gets the existing keys.
---@return T[]
function TotoWar__Dictionary:getKeys()
    local keys = TotoWar__Linq:select(self.entries, function(e) return e.key end)

    return keys
end

---Gets the existing values.
---@return Y[]
function TotoWar__Dictionary:getValues()
    local values = TotoWar__Linq:select(self.entries, function(e) return e.value end)

    return values
end

---Deletes the entry corresponding to a key if it exists.
---@param key T Key.
function TotoWar__Dictionary:remove(key)
    local entryIndex = TotoWar__Linq:findIndex(self.entries, function(e) return e.key == key end)

    if entryIndex >= 1 then
        table.remove(self.entries, entryIndex)
    end
end

---Sets the value corresponding to a key. Replaces the previous value when the key already exists.
---@param key T Key
function TotoWar__Dictionary:set(key, value)
    local entry = TotoWar__Linq:firstOrDefault(self.entries, function(e) return e.key == key end)

    if entry == nil then
        entry = TotoWar__KeyValue.new(key, value)
        table.insert(self.entries, entry)
    else
        entry.value = value
    end
end
