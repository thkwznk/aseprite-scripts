local View = dofile("./View.lua")
local TimeTracker = dofile("./TimeTracker.lua")
local ChangeTracker = dofile("./ChangeTracker.lua")
local StatisticsDialog = dofile("./StatisticsDialog.lua")
local TimeDialog = dofile("./TimeDialog.lua")
local Hash = dofile("./Hash.lua")

-- TODO: Organize these Lua files into folders

local function ParseTime(time) -- TODO: Extract to it's own file
    local seconds = time % 60
    local hours = math.floor(time / 3600)
    local minutes = math.floor((time - (hours * 3600)) / 60)

    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

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
            local sprite = app.activeSprite
            local id = Hash(sprite.filename)

            -- TODO: Move this dialog to a separate file
            local dialog = Dialog {title = "Milestones"}

            local milestones = plugin.preferences.milestones[id]

            -- TODO: Reverse order - newest on top
            for i, milestone in ipairs(milestones) do
                local milestoneId = "milestone-" .. tostring(i)
                dialog:button{
                    id = milestoneId,
                    label = ParseTime(milestone.totalTime) .. " - " ..
                        milestone.title,
                    text = "Edit",
                    onclick = function()
                        local editMilestoneDialog
                        editMilestoneDialog = Dialog {
                            title = "Edit Milestone: " .. milestone.title
                        }

                        editMilestoneDialog:entry{
                            id = "title",
                            label = "Title:",
                            text = milestone.title
                        }:entry{
                            id = "totalTime",
                            label = "Time:",
                            text = ParseTime(milestone.totalTime)
                        }:button{
                            text = "&OK",
                            onclick = function()
                                milestone.title = editMilestoneDialog.data.title
                                -- TODO: time
                                dialog:modify{
                                    id = milestoneId,
                                    label = ParseTime(milestone.totalTime) ..
                                        " - " .. milestone.title
                                }
                                editMilestoneDialog:close()

                                -- TODO: Make the entire milestones dialog scrollable, with default width and height and refresh when editings milestones
                            end
                        }:button{text = "&Cancel"}

                        editMilestoneDialog:show()
                    end
                }
            end

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
