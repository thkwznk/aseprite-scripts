local Statistics = dofile("./Statistics.lua")
local View = dofile("./View.lua")
local DefaultData = dofile("./DefaultData.lua")

local function ParseTime(time)
    local seconds = time % 60
    local hours = math.floor(time / 3600)
    local minutes = math.floor((time - (hours * 3600)) / 60)

    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

local function SumData(a, b)
    return {
        totalTime = a.totalTime + b.totalTime,
        changeTime = a.changeTime + b.changeTime,
        changes = a.changes + b.changes,
        saves = a.saves + b.saves
    }
end

return function(options)
    local timer, lastFilename, totalData, todayData
    Statistics:Init(options.preferences)

    local function GetDialogTitle(sprite)
        return "Sprite Statistics: " ..
                   (sprite and app.fs.fileName(sprite.filename) or "None")
    end

    local dialog = Dialog {
        title = GetDialogTitle(),
        onclose = function()
            if options.onclose then options.onclose() end
            timer:stop()
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

    local updateDialog = function(sprite)
        if sprite == nil then
            dialog:modify{title = GetDialogTitle(sprite)}

            local data = DefaultData()
            updateSection("total", data)
            updateSection("today", data)
            updateSection("session", data, "(", ")")
            return
        end

        local filename = sprite.filename

        if filename ~= lastFilename then
            dialog:modify{title = GetDialogTitle(sprite)}

            totalData = Statistics:GetTotalData(filename)
            todayData = Statistics:GetTodayData(filename)
        end

        local sessionData = Statistics:GetSessionData(filename)

        updateSection("total", SumData(totalData, sessionData))
        updateSection("today", SumData(todayData, sessionData))
        updateSection("session", sessionData, "(", ")")

        lastFilename = filename
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

    timer = Timer {
        interval = 0.5,
        ontick = function() updateDialog(app.activeSprite) end
    }

    dialog --
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
    :separator{text = "Total:"} --
    :label{id = "total-time", label = "Time:"} --
    :label{id = "total-change-time", label = "Change Time:"} --
    :label{id = "total-changes", label = "Changes:"} --
    :label{id = "total-saves", label = "Saves:"} --
    :label{id = "total-sessions", label = "Sessions:"} --
    :separator{text = "Today (Current Session):"} --
    :label{id = "today-time", label = "Time:"} --
    :label{id = "session-time", enabled = false} --
    :label{id = "today-change-time", label = "Change Time:"} --
    :label{id = "session-change-time", enabled = false} --
    :label{id = "today-changes", label = "Changes:"} --
    :label{id = "session-changes", enabled = false} --
    :label{id = "today-saves", label = "Saves:"} --
    :label{id = "session-saves", enabled = false} --
    :label{id = "today-sessions", label = "Sessions:"} --
    :label{id = "session-sessions", enabled = false} --
    :separator() --
    :button{text = "Close", focus = true}

    -- Initialize dialog for the current sprite
    updateDialog(app.activeSprite)
    updateView(options.preferences.view)

    timer:start()

    return dialog
end
