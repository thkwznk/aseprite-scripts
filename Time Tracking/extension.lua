local TimeTracker = dofile("./TimeTracker.lua")
local StatisticsDialog = dofile("./StatisticsDialog.lua")
local View = dofile("./View.lua")
local ChangeTracker = dofile("./ChangeTracker.lua")

function init(plugin)
    TimeTracker:Init(plugin.preferences)
    ChangeTracker:Start{
        onsiteenter = function(sprite) TimeTracker:OnSiteEnter(sprite) end,
        onsiteleave = function(sprite) TimeTracker:OnSiteLeave(sprite) end,
        onchange = function(sprite) TimeTracker:OnChange(sprite) end,
        onfilenamechange = function(sprite, previousFilename)
            TimeTracker:OnFilenameChange(sprite, previousFilename)
        end
    }

    -- Initialize the view
    plugin.preferences.view = plugin.preferences.view or View.Basic

    plugin:newCommand{
        id = "SpriteStatistics",
        title = "Statistics...",
        group = "sprite_color",
        onclick = function()
            local dialog = StatisticsDialog {preferences = plugin.preferences}
            dialog:show{wait = false}
        end
    }
end

function exit(plugin) ChangeTracker:Stop() end
