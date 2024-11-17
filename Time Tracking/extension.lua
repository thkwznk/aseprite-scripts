local View = dofile("./View.lua")
local TimeTracker = dofile("./TimeTracker.lua")
local ChangeTracker = dofile("./ChangeTracker.lua")
local StatisticsDialog = dofile("./Dialogs/StatisticsDialog.lua")
local TimeDialog = dofile("./Dialogs/TimeDialog.lua")
local MilestonesDialog = dofile("./Dialogs/MilestonesDialog.lua")

function init(plugin)
    -- Reset view if it has a deprecated value
    if plugin.preferences.view == View.Basic or plugin.preferences.view ==
        View.Advanced then plugin.preferences.view = nil end

    -- Initialize the view
    plugin.preferences.view = plugin.preferences.view or View.Session

    -- Initialize the milestones
    plugin.preferences.milestones = plugin.preferences.milestones or {}

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

    -- If on init there's already an active sprite, simulate switching site to it
    -- This fixes time tracking being stopped after updating the extension
    if app.activeSprite then TimeTracker:OnSiteEnter(app.activeSprite) end

    -- TODO: Live update Sprite Statistics

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
        id = "SpriteMilestones",
        title = "Milestones",
        group = "sprite_color",
        onenable = function() return app.activeSprite ~= nil end,
        onclick = function()
            local dialog = MilestonesDialog {
                sprite = app.activeSprite,
                preferences = plugin.preferences
            }
            dialog:show()
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

function exit(plugin)
    for _, sprite in ipairs(app.sprites) do
        -- Simulate a true close of the file
        TimeTracker:OnSiteLeave(sprite, true)
    end

    ChangeTracker:Stop()
end
