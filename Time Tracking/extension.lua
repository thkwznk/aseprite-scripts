local TimeTracker = dofile("./TimeTracker.lua")

local ParseTime = function(time)
    local seconds = time % 60
    local hours = math.floor(time / 3600)
    local minutes = math.floor((time - (hours * 3600)) / 60)

    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

function init(plugin)
    TimeTracker:Start(plugin.preferences)

    local isDebug = false

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

            local updateDialog = function(filename)
                local spriteData = TimeTracker:GetDataForSprite(filename)
                local spriteTodayData = TimeTracker:GetTodayDataForSprite(
                                            filename, TimeTracker:GetDate())
                local sessionData = TimeTracker:GetCurrentSessionDataForSprite(
                                        filename)

                dialog --
                :modify{
                    id = "name",
                    text = app.fs.fileName(filename),
                    enabled = false
                } --
                :modify{
                    id = "directory",
                    text = app.fs.filePath(filename),
                    enabled = false
                } --
                :modify{id = "time", text = ParseTime(spriteData.totalTime)} --
                :modify{
                    id = "changeTime",
                    text = ParseTime(spriteData.changeTime)
                } --
                :modify{id = "changes", text = tostring(spriteData.changes)} --
                :modify{id = "saves", text = tostring(spriteData.saves)} --
                :modify{id = "sessions", text = tostring(spriteData.sessions)} --
                :modify{
                    id = "todayTime",
                    text = ParseTime(spriteTodayData.totalTime)
                } --
                :modify{
                    id = "todayChangeTime",
                    text = ParseTime(spriteTodayData.changeTime)
                } --
                :modify{
                    id = "todayChanges",
                    text = tostring(spriteTodayData.changes)
                } --
                :modify{
                    id = "todaySaves",
                    text = tostring(spriteTodayData.saves)
                } --
                :modify{
                    id = "todaySessions",
                    text = tostring(spriteTodayData.sessions)
                } --
                :modify{
                    id = "sessionTime",
                    text = ParseTime(sessionData.totalTime)
                } --
                :modify{
                    id = "sessionChangeTime",
                    text = ParseTime(sessionData.changeTime)
                } --
                :modify{
                    id = "sessionChanges",
                    text = tostring(sessionData.changes)
                } --
                :modify{id = "sessionSaves", text = tostring(sessionData.saves)} --
                :modify{
                    id = "refreshButton",
                    enabled = filename and #filename > 0
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
            :separator{text = "File:"} --
            :label{id = "name", label = "Name:"} --
            :label{id = "directory", label = "Directory:"} --
            :separator{text = "Statistics:"} --
            :label{text = "Total", enabled = false} --
            :label{text = "Today", enabled = false} --
            :label{text = "Session", enabled = false} --
            :label{id = "time", label = "Time:"} --
            :label{id = "todayTime"} --
            :label{id = "sessionTime"} --
            :label{id = "changeTime", label = "Change Time:", visible = isDebug} --
            :label{id = "todayChangeTime", visible = isDebug} --
            :label{id = "sessionChangeTime", visible = isDebug} --
            :label{id = "changes", label = "Changes:"} --
            :label{id = "todayChanges"} --
            :label{id = "sessionChanges"} --
            :label{id = "saves", label = "Saves:"} --
            :label{id = "todaySaves"} --
            :label{id = "sessionSaves"} --
            :label{id = "sessions", label = "Sessions:"} --
            :label{id = "todaySessions"} --
            :label{id = "sessionSessions", text = "-"} --
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
            :button{text = "Close"}

            -- Initialize dialog for the current sprite
            updateDialog(currentFilename)

            dialog:show{wait = not isDebug}
        end
    }
end

function exit(plugin) TimeTracker:Stop() end
