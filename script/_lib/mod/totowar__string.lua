---Represents an utility class for managing strings.
---@class TotoWar__String
TotoWar__String = {}
TotoWar__String.__index = TotoWar__String

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
