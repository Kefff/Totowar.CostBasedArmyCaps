---Indicates whether a list contains an element that matches a predicate.
---@generic T
---@param list T[] List.
---@param predicate fun(item: T): boolean Predicate.
---@return boolean
function totoWar_linqAny(list, predicate)
    local exists = totoWar_linqFirstOrDefault(list, predicate) ~= nil

    return exists
end

---Gets the first element of a list that matches a predicate, or nil if there are none.
---@generic T
---@param list T[] List.
---@param predicate fun(item: T): boolean Predicate.
---@return T | nil
function totoWar_linqFirstOrDefault(list, predicate)
    for index, item in ipairs(list) do
        local predicateResult = predicate(item)

        if predicateResult then
            return item
        end
    end

    return nil
end

---Groups elements of a list based on a predicate used as a group key.
---@generic T
---@param list T[] List.
---@param predicate fun(item: T): string Predicate.
---@return { [string]: T[] }
function totoWar_linqGroupBy(list, predicate)
    ---@type { [string]: `T`[] }
    local groups = {}

    for index, item in ipairs(list) do
        local key = predicate(item)

        if groups[key] == nil then
            groups[key] = { item }
        else
            table.insert(groups[key], item)
        end
    end

    return groups
end

---Gets the last element of a list that matches a predicate, or nil if there are none.
---@generic T
---@param list T[] List.
---@param predicate fun(item: T): boolean Predicate.
---@return T
function totoWar_linqLastOrDefault(list, predicate)
    for i = #list, 1, -1 do
        local item = list[i]
        local predicateResult = predicate(item)

        if predicateResult then
            return item
        end
    end

    return nil
end

---Selects the result of a predicate for each element of a list.
---@generic T, Y
---@param list T[] List.
---@param predicate fun(item: T): Y Predicate.
---@return Y[]
function totoWar_linqSelect(list, predicate)
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
function totoWar_linqSum(list, predicate)
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
function totoWar_linqWhere(list, predicate)
    local filteredTable = {}

    for index, item in ipairs(list) do
        local predicateResult = predicate(item)

        if predicateResult then
            table.insert(filteredTable, item)
        end
    end

    return filteredTable
end
