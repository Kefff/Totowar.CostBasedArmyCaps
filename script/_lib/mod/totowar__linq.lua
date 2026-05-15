---Represents an utility class for managing enumerations.
---@class TotoWarLinq
TotoWarLinq = {}
TotoWarLinq.__index = TotoWarLinq

---Indicates whether all elements of a list match a predicate.
---@generic T
---@param list T[] List.
---@param predicate fun(item: T): boolean Predicate.
---@return boolean
function TotoWarLinq:all(list, predicate)
    local nonMatchingElement = TotoWarLinq:firstOrDefault(list, function(e) return not predicate(e) end)
    local allMatch = nonMatchingElement == nil

    return allMatch
end

---Indicates whether a list contains an element that matches a predicate.
---@generic T
---@param list T[] List.
---@param predicate fun(item: T): boolean Predicate.
---@return boolean
function TotoWarLinq:any(list, predicate)
    local exists = TotoWarLinq:firstOrDefault(list, predicate) ~= nil

    return exists
end

---Finds the index of the first element in a list that matches a predicate, or -1 if there are none.
---@generic T
---@param list T[] List.
---@param predicate fun(item: T): boolean Predicate.
---@return number
function TotoWarLinq:findIndex(list, predicate)
    for index, item in ipairs(list) do
        local predicateResult = predicate(item)

        if predicateResult then
            return index
        end
    end

    return -1
end

---Gets the first element of a list that matches a predicate, or nil if there are none.
---@generic T
---@param list T[] List.
---@param predicate fun(item: T): boolean Predicate.
---@return T | nil
function TotoWarLinq:firstOrDefault(list, predicate)
    for index, item in ipairs(list) do
        local predicateResult = predicate(item)

        if predicateResult then
            return item
        end
    end

    return nil
end

---Groups elements of a list based on a predicate used as a group key.
---@generic T, Y
---@param list T[] List.
---@param predicate fun(item: T): Y Predicate.
---@return TotoWarDictionary<Y, T[]>
function TotoWarLinq:groupBy(list, predicate)
    local groups = TotoWarDictionary.new()

    for index, item in ipairs(list) do
        local key = predicate(item)
        local group = groups:get(key)

        if group == nil then
            group = { item }
            groups:set(key, group)
        else
            table.insert(group, item)
        end
    end

    return groups
end

---Gets the last element of a list that matches a predicate, or nil if there are none.
---@generic T
---@param list T[] List.
---@param predicate fun(item: T): boolean Predicate.
---@return T
function TotoWarLinq:lastOrDefault(list, predicate)
    for i = #list, 1, -1 do
        local item = list[i]
        local predicateResult = predicate(item)

        if predicateResult then
            return item
        end
    end

    return nil
end

---Removes the elements corresponding to a predicate.
---@generic T
---@param list T[] List.
---@param predicate fun(item: T): boolean Predicate.
function TotoWarLinq:remove(list, predicate)
    while true do
        local index = TotoWarLinq:findIndex(list, predicate)

        if index == -1 then
            return
        else
            table.remove(list, index)
        end
    end
end

---Selects the result of a predicate for each element of a list.
---@generic T, Y
---@param list T[] List.
---@param predicate fun(item: T): Y Predicate.
---@return Y[]
function TotoWarLinq:select(list, predicate)
    ---@diagnostic disable-next-line: undefined-doc-name
    ---@type Y[]
    local result = {}

    for index, item in ipairs(list) do
        table.insert(result, predicate(item))
    end

    return result
end

---Sums for each element of a list the value corresponding a predicate.
---@generic T
---@param list T[] List.
---@param predicate fun(item: T): number Predicate.
---@return number
function TotoWarLinq:sum(list, predicate)
    ---@type number
    local result = 0

    for index, item in ipairs(list) do
        result = result + predicate(item)
    end

    return result
end

---Filters a list based on a predicate.
---@generic T
---@param list T[] List.
---@param predicate fun(item: T): boolean Predicate.
---@return T[]
function TotoWarLinq:where(list, predicate)
    local filteredTable = {}

    for index, item in ipairs(list) do
        local predicateResult = predicate(item)

        if predicateResult then
            table.insert(filteredTable, item)
        end
    end

    return filteredTable
end
