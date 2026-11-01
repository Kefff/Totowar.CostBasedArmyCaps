require("script._lib.mod.totowar__enum")

---Constants of the TotoWar mod.
---@class TotoWar__Constant
TotoWar__Constant = {
    ---Default log severity.
    defaultLogLevel = TotoWar__Enum_LogSeverities.info,

    ---Name of the TotoWar base mod.
    modName = "totowar",

    ---Default value for the option that enables debug logs.
    optionDefaultValue_debugEnabled = false,

    ---Default value for the option that removes the fog of war from the whole campaign map.
    optionDefaultValue_mapRevealed = false,

    ---Name of the option that enables debug logs.
    optionName_debugEnabled = "totowar_debugEnabled",

    ---Name of the option that removes the fog of war from the whole campaign map.
    optionName_mapRevealed = "totowar_mapRevealed"
}
