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
            TimeTracker:Pause()

            local sprite = app.activeSprite

            local currentFilename = sprite and sprite.filename or ""
            local filenames = TimeTracker:GetFilenames()

            local dialog = Dialog {
                title = "Sprite Statistics",
                onclose = function() TimeTracker:Unpause() end
            }

            local updateDialog = function(filename)
                local spriteData = TimeTracker:GetDataForSprite(filename)
                local spriteTodayData = TimeTracker:GetDataForSprite(filename,
                                                                     TimeTracker:GetDate())

                dialog --
                :modify{id = "name", text = app.fs.fileName(filename)} --
                :modify{id = "directory", text = app.fs.filePath(filename)} --
                :modify{id = "time", text = ParseTime(spriteData.totalTime)} --
                :modify{
                    id = "changeTime",
                    text = ParseTime(spriteData.changeTime)
                } --
                :modify{id = "changes", text = tostring(spriteData.changes)} --
                :modify{id = "saves", text = tostring(spriteData.saves)} --
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
            :separator{text = "Total:"} --
            :label{id = "time", label = "Time:"} --
            :label{id = "changeTime", label = "Change Time:", visible = isDebug} --
            :label{id = "changes", label = "Changes:"} --
            :label{id = "saves", label = "Saves:"} --
            :separator{text = "Today:"} --
            :label{id = "todayTime", label = "Time:"} --
            :label{
                id = "todayChangeTime",
                label = "Change Time:",
                visible = isDebug
            } --
            :label{id = "todayChanges", label = "Changes:"} --
            :label{id = "todaySaves", label = "Saves:"} --
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
