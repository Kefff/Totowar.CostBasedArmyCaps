---Information about a UI panel.
---@class TotoWarUIPanelInfo
TotoWarUIPanelInfo = {
    ---Categories indicating the purpose of the panel.
    ---@type string[]
    categories = nil,

    ---Name of the panel.
    ---@type string
    name = nil
}
TotoWarUIPanelInfo.__index = TotoWarUIPanelInfo

---Initializes a new instance.
---@param name string Name of the panel.
---@param categories string[] Categories indicating the purpose of the panel.
---@return TotoWarUIPanelInfo
function TotoWarUIPanelInfo.new(name, categories)
    local self = setmetatable({}, TotoWarUIPanelInfo)

    self.categories = categories
    self.name = name

    return self
end

---Indicates whether the panel has a category.
---@param category string Category.
---@return boolean
function TotoWarUIPanelInfo:hasCategory(category)
    local hasCategory = false

    for i, c in ipairs(self.categories) do
        if c == category then
            hasCategory = true

            break
        end
    end

    return hasCategory
end
