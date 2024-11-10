local Statistics = dofile("./Statistics.lua")
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
        saves = a.saves + b.saves,
        sessions = (a.sessions or 0) + (b.sessions or 0)
    }
end

return function(options)
    local isRunning = true
    local timer, lastFilename, totalData, todayData
    Statistics:Init(options.preferences)

    local dialog = Dialog {
        title = "Sprite Work Time",
        onclose = function()
            if options.onclose then options.onclose() end
            timer:stop()
        end
    }

    local updateSection = function(id, data)
        dialog --
        :modify{id = id .. "-time", text = ParseTime(data.totalTime)} --
        :modify{id = id .. "-change-time", text = ParseTime(data.changeTime)} --
        :modify{id = id .. "-changes", text = tostring(data.changes)} --
        :modify{id = id .. "-saves", text = tostring(data.saves)} --
        :modify{
            id = id .. "-sessions",
            text = data.sessions or "-",
            enabled = id ~= "session"
        } --
    end

    local updateDialog = function(sprite)
        if sprite == nil then
            local data = DefaultData()
            updateSection("total", data)
            updateSection("today", data)
            updateSection("session", data)
            return
        end

        local filename = sprite.filename

        if filename ~= lastFilename then
            totalData = Statistics:GetTotalData(filename)
            todayData = Statistics:GetTodayData(filename)
        end

        local sessionData = Statistics:GetSessionData(filename)

        updateSection("total", SumData(totalData, sessionData))
        updateSection("today", SumData(todayData, sessionData))
        updateSection("session", sessionData)

        lastFilename = filename
    end

    dialog --
    :tab{id = "session-tab", text = "Session", onclick = function() end} --
    :label{id = "session-time", label = "Time:"} --
    :label{id = "session-change-time", label = "Change Time:"} --
    :label{id = "session-changes", label = "Changes:"} --
    :label{id = "session-saves", label = "Saves:"} --
    :label{id = "session-sessions", label = "Sessions:"} --
    --
    :tab{id = "today-tab", text = "Today", onclick = function() end} --
    :label{id = "today-time", label = "Time:"} --
    :label{id = "today-change-time", label = "Change Time:"} --
    :label{id = "today-changes", label = "Changes:"} --
    :label{id = "today-saves", label = "Saves:"} --
    :label{id = "today-sessions", label = "Sessions:"} --
    --
    :tab{id = "total-tab", text = "Total", onclick = function() end} --
    :label{id = "total-time", label = "Time:"} --
    :label{id = "total-change-time", label = "Change Time:"} --
    :label{id = "total-changes", label = "Changes:"} --
    :label{id = "total-saves", label = "Saves:"} --
    :label{id = "total-sessions", label = "Sessions:"} --
    --
    :endtabs{
        id = "tab",
        selected = options.preferences.view,
        onchange = function() options.preferences.view = dialog.data.tab end
    } --
    :button{
        id = "start-stop",
        text = "Stop",
        onclick = function()
            if isRunning then
                options.onpause()
            else
                options.onresume()
            end

            isRunning = not isRunning

            dialog:modify{
                id = "start-stop",
                text = isRunning and "Stop" or "Start"
            }
        end
    }

    timer = Timer {
        interval = 0.5,
        ontick = function() updateDialog(app.activeSprite) end
    }
    timer:start()

    return dialog
end

-- TODO: Add an option to minimize the dialog
-- TODO: Hide either "Today" or "Total" if there's no data from multiple days
