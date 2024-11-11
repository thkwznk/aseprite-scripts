local View = dofile("./View.lua")
local TimeTracker = dofile("./TimeTracker.lua")
local ChangeTracker = dofile("./ChangeTracker.lua")
local StatisticsDialog = dofile("./StatisticsDialog.lua")
local TimeDialog = dofile("./TimeDialog.lua")

function init(plugin)
    -- Reset view if it has a deprecated value
    if plugin.preferences.view == View.Basic or plugin.preferences.view ==
        View.Advanced then plugin.preferences.view = nil end

    -- Initialize the view
    plugin.preferences.view = plugin.preferences.view or View.Session

    -- Initialize the tracker
    TimeTracker:Init(plugin.preferences)
    ChangeTracker:Start{
        onsiteenter = function(sprite) TimeTracker:OnSiteEnter(sprite) end,
        onsiteleave = function(sprite) TimeTracker:OnSiteLeave(sprite) end,
        onchange = function(sprite) TimeTracker:OnChange(sprite) end,
        onfilenamechange = function(sprite, previousFilename)
            TimeTracker:OnFilenameChange(sprite, previousFilename)
        end
    }

    -- Register commands
    plugin:newCommand{
        id = "SpriteStatistics",
        title = "Statistics...",
        group = "sprite_color",
        onenable = function() return app.activeSprite ~= nil end,
        onclick = function()
            local dialog = StatisticsDialog {
                sprite = app.activeSprite,
                preferences = plugin.preferences
            }
            dialog:show{wait = false}
        end
    }

    plugin:newCommand{
        id = "SpriteWorkTime",
        title = "Sprite Work Time",
        group = "view_controls",
        onclick = function()
            local dialog = TimeDialog {
                preferences = plugin.preferences,
                onpause = function() ChangeTracker:Stop() end,
                onresume = function() ChangeTracker:Resume() end
            }
            dialog:show{wait = false}
        end
    }
end

function exit(plugin) ChangeTracker:Stop() end
