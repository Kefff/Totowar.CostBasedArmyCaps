---Information about a UI panel.
---@class TotoWarUIPanelInfo
TotoWarUIPanelInfo = {
    ---Categories indicating the purpose of the panel.
    ---@type string[]
    categories = nil,

    ---Name of the panel.
    ---@type string
    name = nil,

    ---Queries for searching for the UI components of the panel.
    ---@type string[][]
    uiComponentQueries = nil
}
TotoWarUIPanelInfo.__index = TotoWarUIPanelInfo

---Initializes a new instance.
---@param name string Name of the panel.
---@param categories string[] Categories indicating the purpose of the panel.
---@param uiComponentQueries string[][] Queries for searching for the UI components of the panel.
---@return TotoWarUIPanelInfo
function TotoWarUIPanelInfo.new(name, categories, uiComponentQueries)
    local self = setmetatable({}, TotoWarUIPanelInfo)

    self.categories = categories
    self.name = name
    self.uiComponentQueries = uiComponentQueries

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
