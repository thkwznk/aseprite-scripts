local View = dofile("./View.lua")
local TimeTracker = dofile("./TimeTracker.lua")
local ChangeTracker = dofile("./ChangeTracker.lua")
local StatisticsDialog = dofile("./Dialogs/StatisticsDialog.lua")
local TimeDialog = dofile("./Dialogs/TimeDialog.lua")
local MilestonesDialog = dofile("./Dialogs/MilestonesDialog.lua")

function init(plugin)
    -- Initialize the view
    plugin.preferences.view = plugin.preferences.view or View.Basic

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

    -- Register commands
    plugin:newCommand{
        id = "SpriteStatistics",
        title = "Statistics...",
        group = "sprite_color",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            local dialog = StatisticsDialog {
                sprite = app.activeSprite,
                preferences = plugin.preferences
            }
            dialog:show()
        end
    }

    plugin:newCommand{
        id = "SpriteMilestones",
        title = "Milestones",
        group = "sprite_color",
        onenabled = function() return app.activeSprite ~= nil end,
        onclick = function()
            local dialog = MilestonesDialog {
                sprite = app.activeSprite,
                preferences = plugin.preferences
            }
            dialog:show()
        end
    }

    local isSessionTimeOpen = false

    plugin:newCommand{
        id = "SessionTime",
        title = "Session Time",
        group = "view_controls",
        onenabled = function() return not isSessionTimeOpen end,
        onclick = function()
            isSessionTimeOpen = true

            local dialog = TimeDialog {
                notitlebar = true,
                preferences = plugin.preferences,
                onpause = function() ChangeTracker:Stop() end,
                onresume = function() ChangeTracker:Resume() end,
                onclose = function() isSessionTimeOpen = false end
            }
            dialog:show{wait = false}
            local newBounds = Rectangle(dialog.bounds)
            newBounds.x = app.window.width - newBounds.width - 26
            newBounds.y = 48
            dialog.bounds = newBounds
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
