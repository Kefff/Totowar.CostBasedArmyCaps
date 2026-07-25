---Represents an utility class for managing strings.
---@class TotoWar__String
TotoWar__String = {}
TotoWar__String.__index = TotoWar__String

---Indicates whether a text contains another text.
---@param text string Text.
---@param searchedText integer Searched text.
---@return boolean
function TotoWar__String:contains(text, searchedText)
    local contains = text:find(searchedText, 1, true) ~= nil

    return contains
end

---Indicates whether a text ends with another text.
---@param text string Text.
---@param searchedText integer Searched text.
---@return boolean
function TotoWar__String:endsWith(text, searchedText)
    local start = #text - #searchedText + 1
    local endsWith = start > 0 and text:find(searchedText, start, true) == start

    return endsWith
end

---Adds padding to the left of a text to reach a certain length.
---@param text string Text.
---@param length integer Target length.
---@param paddingCharacter string | nil Padding character. Space by default.
---@return string
function TotoWar__String:padLeft(text, length, paddingCharacter)
    paddingCharacter = paddingCharacter or ' '
    text = string.rep(paddingCharacter, length - #text) .. text

    return text
end

---Adds padding to the right of a text to reach a certain length.
---@param text string Text.
---@param length integer Target length.
---@param paddingCharacter string | nil Padding character. Space by default.
---@return string
function TotoWar__String:padRight(text, length, paddingCharacter)
    paddingCharacter = paddingCharacter or ' '
    text = text .. string.rep(paddingCharacter, length - #text)

    return text
end

---Indicates whether a text starts with another text.
---@param text string Text.
---@param searchedText integer Searched text.
---@return boolean
function TotoWar__String:startsWith(text, searchedText)
    text = text:sub(1, #searchedText)
    local startsWith = text == searchedText

    return startsWith
end
