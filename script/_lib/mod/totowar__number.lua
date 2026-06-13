---Represents an utility class for managing number.
---@class TotoWar__Number
TotoWar__Number = {}
TotoWar__Number.__index = TotoWar__Number

---Rounds a number to the nearest integer.
---@param number_ number Number.
---@return integer
function TotoWar__Number:roundToNearestInteger(number_)
    local result = 0

    if number_ >= 0 then
        result = math.floor(number_ + 0.5)
    else
        result = math.ceil(number_ - 0.5)
    end

    return result
end
