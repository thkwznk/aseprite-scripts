local TimeTracker = dofile("./TimeTracker.lua")

local View = {Basic = "basic", Detailed = "detailed"}

local ParseTime = function(time)
    local seconds = time % 60
    local hours = math.floor(time / 3600)
    local minutes = math.floor((time - (hours * 3600)) / 60)

    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

function init(plugin)
    TimeTracker:Start(plugin.preferences)

    local isDebug = false

    -- Initialize the view
    plugin.preferences.view = plugin.preferences.view or View.Basic

    plugin:newCommand{
        id = "SpriteStatistics",
        title = "Statistics...",
        group = "sprite_color",
        onenabled = function() return app.activeSprite or isDebug end,
        onclick = function()
            if not isDebug then TimeTracker:Pause() end

            local sprite = app.activeSprite

            local currentFilename = sprite and sprite.filename or ""
            local filenames = TimeTracker:GetFilenames()

            local dialog = Dialog {
                title = "Sprite Statistics",
                onclose = function()
                    if not isDebug then TimeTracker:Unpause() end
                end
            }

            local updateSection = function(id, data, prefix, suffix)
                prefix = prefix or ""
                suffix = suffix or ""

                dialog --
                :modify{
                    id = id .. "-time",
                    text = prefix .. ParseTime(data.totalTime) .. suffix
                } --
                :modify{
                    id = id .. "-change-time",
                    text = prefix .. ParseTime(data.changeTime) .. suffix
                } --
                :modify{
                    id = id .. "-changes",
                    text = prefix .. tostring(data.changes) .. suffix
                } --
                :modify{
                    id = id .. "-saves",
                    text = prefix .. tostring(data.saves) .. suffix
                } --
                :modify{
                    id = id .. "-sessions",
                    text = data.sessions and
                        (prefix .. tostring(data.sessions) .. suffix) or "-"
                } --
            end

            local updateDialog = function(filename)
                dialog --
                :modify{id = "name", text = app.fs.fileName(filename)} --
                :modify{id = "directory", text = app.fs.filePath(filename)} --
                :modify{
                    id = "refreshButton",
                    enabled = filename and #filename > 0
                } --

                updateSection("total", TimeTracker:GetTotalData(filename))
                updateSection("today", TimeTracker:GetTodayData(filename))
                updateSection("session", TimeTracker:GetSessionData(filename),
                              "(", ")")
            end

            local updateView = function(view)
                plugin.preferences.view = view

                dialog --
                :modify{id = "total-saves", visible = view == View.Detailed} --
                :modify{id = "total-sessions", visible = view == View.Detailed} --
                :modify{id = "today-saves", visible = view == View.Detailed} --
                :modify{id = "today-sessions", visible = view == View.Detailed} --
                :modify{id = "session-saves", visible = view == View.Detailed} --
                :modify{
                    id = "session-sessions",
                    visible = view == View.Detailed
                } --
            end

            dialog --
            :combobox{
                id = "selectedFilename",
                options = filenames,
                option = currentFilename,
                onchange = function()
                    updateDialog(dialog.data.selectedFilename)
                end,
                visible = isDebug
            } --
            :radio{
                id = "basic-view",
                label = "View:",
                text = "Basic",
                selected = plugin.preferences.view == View.Basic,
                onclick = function() updateView(View.Basic) end
            } --
            :radio{
                id = "basic-view",
                text = "Detailed",
                selected = plugin.preferences.view == View.Detailed,
                onclick = function() updateView(View.Detailed) end
            } --
            :separator{text = "File:"} --
            :label{id = "name", label = "Name:"} --
            :label{id = "directory", label = "Directory:"} --
            :separator{text = "Total:"} --
            :label{id = "total-time", label = "Time:"} --
            :label{
                id = "total-change-time",
                label = "Change Time:",
                visible = isDebug
            } --
            :label{id = "total-changes", label = "Changes:"} --
            :label{id = "total-saves", label = "Saves:"} --
            :label{id = "total-sessions", label = "Sessions:"} --
            :separator{text = "Today (Current Session):"} --
            :label{id = "today-time", label = "Time:"} --
            :label{id = "session-time", enabled = false} --
            :label{
                id = "today-change-time",
                label = "Change Time:",
                visible = isDebug
            } --
            :label{
                id = "session-change-time",
                enabled = false,
                visible = isDebug
            } --
            :label{id = "today-changes", label = "Changes:"} --
            :label{id = "session-changes", enabled = false} --
            :label{id = "today-saves", label = "Saves:"} --
            :label{id = "session-saves", enabled = false} --
            :label{id = "today-sessions", label = "Sessions:"} --
            :label{id = "session-sessions", enabled = false} --
            :separator() --
            :button{
                id = "refreshButton",
                text = "Refresh",
                enabled = false,
                visible = isDebug,
                onclick = function()
                    updateDialog(dialog.data.selectedFilename)
                end
            } --
            :button{text = "Close", focus = true}

            -- Initialize dialog for the current sprite
            updateDialog(currentFilename)
            updateView(plugin.preferences.view)

            dialog:show{wait = not isDebug}
        end
    }
end

function exit(plugin) TimeTracker:Stop() end
