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
---@param paddingCharacter string? Padding character. Space by default.
---@return string
function TotoWar__String:padLeft(text, length, paddingCharacter)
    paddingCharacter = paddingCharacter or ' '
    text = string.rep(paddingCharacter, length - #text) .. text

    return text
end

---Adds padding to the right of a text to reach a certain length.
---@param text string Text.
---@param length integer Target length.
---@param paddingCharacter string? Padding character. Space by default.
---@return string
function TotoWar__String:padRight(text, length, paddingCharacter)
    paddingCharacter = paddingCharacter or ' '
    text = text .. string.rep(paddingCharacter, length - #text)

    return text
end

---Splits a text on a separator character.
---@param text string Text.
---@param separator string Separator, a single character.
---@return string[] # Parts of the text, empty parts excluded.
function TotoWar__String:split(text, separator)
    -- The game replaces string.find and string.sub with its own implementations, which support UTF-8 strings
    -- but not all the parameters of the Lua implementations (see lib_lua_extensions.lua). For example,
    -- string.find does not support the "plain" parameter. string.gmatch is not replaced, so it is used here.
    local parts = {}
    local escapedSeparator = string.gsub(separator, "%p", "%%%0")

    for part in string.gmatch(text, "[^" .. escapedSeparator .. "]+") do
        table.insert(parts, part)
    end

    return parts
end

---Indicates whether a text starts with another text.
---@param text string Text.
---@param searchedText string Searched text.
---@return boolean
function TotoWar__String:startsWith(text, searchedText)
    text = text:sub(1, #searchedText)
    local startsWith = text == searchedText

    return startsWith
end
