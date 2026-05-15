---Represents an utility class for managing strings.
---@class TotoWarString
TotoWarString = {}
TotoWarString.__index = TotoWarString

---Adds padding to the left of a text to reach a certain length.
---@param text string Text.
---@param length integer Target length.
---@param paddingCharacter string | nil Padding character. Space by default.
---@return string
function TotoWarString:padLeft(text, length, paddingCharacter)
    paddingCharacter = paddingCharacter or ' '
    text = string.rep(paddingCharacter, length - #text) .. text

    return text
end

---Adds padding to the right of a text to reach a certain length.
---@param text string Text.
---@param length integer Target length.
---@param paddingCharacter string | nil Padding character. Space by default.
---@return string
function TotoWarString:padRight(text, length, paddingCharacter)
    paddingCharacter = paddingCharacter or ' '
    text = text .. string.rep(paddingCharacter, length - #text)

    return text
end
