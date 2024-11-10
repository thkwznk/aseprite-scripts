local Statistics = dofile("./Statistics.lua")
local View = dofile("./View.lua")

local ParseTime = function(time)
    local seconds = time % 60
    local hours = math.floor(time / 3600)
    local minutes = math.floor((time - (hours * 3600)) / 60)

    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

return function(options)
    local sprite = app.activeSprite
    local currentFilename = sprite and sprite.filename or ""

    Statistics:Init(options.preferences)
    local filenames = Statistics:GetFilenames()

    local dialog = Dialog {
        title = "Sprite Statistics",
        onclose = options.onclose
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
        :modify{id = "refreshButton", enabled = filename and #filename > 0} --

        updateSection("total", Statistics:GetTotalData(filename))
        updateSection("today", Statistics:GetTodayData(filename))
        updateSection("session", Statistics:GetSessionData(filename), "(", ")")
    end

    local updateView = function(view)
        options.preferences.view = view

        dialog --
        :modify{id = "total-saves", visible = view == View.Detailed} --
        :modify{id = "total-sessions", visible = view == View.Detailed} --
        :modify{id = "today-saves", visible = view == View.Detailed} --
        :modify{id = "today-sessions", visible = view == View.Detailed} --
        :modify{id = "session-saves", visible = view == View.Detailed} --
        :modify{id = "session-sessions", visible = view == View.Detailed} --
    end

    dialog --
    :combobox{
        id = "selectedFilename",
        options = filenames,
        option = currentFilename,
        onchange = function() updateDialog(dialog.data.selectedFilename) end,
        visible = options.isDebug
    } --
    :radio{
        id = "basic-view",
        label = "View:",
        text = "Basic",
        selected = options.preferences.view == View.Basic,
        onclick = function() updateView(View.Basic) end
    } --
    :radio{
        id = "basic-view",
        text = "Detailed",
        selected = options.preferences.view == View.Detailed,
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
        visible = options.isDebug
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
        visible = options.isDebug
    } --
    :label{
        id = "session-change-time",
        enabled = false,
        visible = options.isDebug
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
        visible = options.isDebug,
        onclick = function() updateDialog(dialog.data.selectedFilename) end
    } --
    :button{text = "Close", focus = true}

    -- Initialize dialog for the current sprite
    updateDialog(currentFilename)
    updateView(options.preferences.view)

    return dialog
end
