local Statistics = dofile("./Statistics.lua")
local Tracking = dofile("./Tracking.lua")
local View = dofile("./View.lua")
local Hash = dofile("./Hash.lua")

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
        sessions = (a.sessions or 0) + (b.sessions or 0) + 1 -- Increment the number of sessions to account for the current one
    }
end

return function(options)
    local isRunning = true
    local isMinimized = options.preferences.isMinimized
    local timer, lastFilename, totalData, todayData
    Statistics:Init(options.preferences)

    local dialog = Dialog {
        title = "Sprite Work Time",
        onclose = function()
            if options.onclose then options.onclose() end
            timer:stop()

            -- Resume when the dialog is closed
            if not isRunning then options.onresume() end
        end
    }

    local function UpdateSection(id, data)
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

    local function UpdateDialog(sprite)
        if sprite == nil then
            lastFilename = nil
            local data = Tracking.Data()
            UpdateSection("total", data)
            UpdateSection("today", data)
            UpdateSection("session", data)
            return
        end

        local filename = sprite.filename

        if filename ~= lastFilename then
            totalData = Statistics:GetTotalData(filename, true)
            todayData = Statistics:GetTodayData(filename, true)

            if totalData.totalDays <= 1 then
                dialog:modify{id = "total-tab", enabled = false}

                if dialog.data.tab == View.Total then
                    dialog:modify{id = "tab", selected = View.Today}
                end
            end
        end

        local sessionData = Statistics:GetSessionData(filename)

        local totalDataUpdated = SumData(totalData, sessionData)
        local todayDataUpdated = SumData(todayData, sessionData)

        UpdateSection("total", totalDataUpdated)
        UpdateSection("today", todayDataUpdated)
        UpdateSection("session", sessionData)

        if dialog.data.tab == View.Session .. "-tab" then
            dialog:modify{
                id = "minimized-time",
                label = "Session:",
                text = ParseTime(sessionData.totalTime)
            }
        elseif dialog.data.tab == View.Today .. "-tab" then
            dialog:modify{
                id = "minimized-time",
                label = "Today:",
                text = ParseTime(todayDataUpdated.totalTime)
            }
        elseif dialog.data.tab == View.Total .. "-tab" then
            dialog:modify{
                id = "minimized-time",
                label = "Total:",
                text = ParseTime(totalDataUpdated.totalTime)
            }
        end

        lastFilename = filename
    end

    dialog --
    :label{
        id = "minimized-time",
        label = "Time:",
        text = "00:00:00",
        visible = isMinimized
    } --
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
        selected = options.preferences.view .. "-tab",
        onchange = function() options.preferences.view = dialog.data.tab end,
        visible = not isMinimized
    } --
    :button{
        id = "minimize",
        text = isMinimized and "v" or "^",
        onclick = function()
            isMinimized = not isMinimized

            dialog --
            :modify{id = "minimize", text = isMinimized and "v" or "^"} --
            :modify{id = "minimized-time", visible = isMinimized} --
            :modify{id = "tab", visible = not isMinimized} --

            -- Update plugin preferences
            options.preferences.isMinimized = isMinimized
        end
    } --
    :button{
        id = "start-stop",
        text = "||",
        onclick = function()
            if isRunning then
                options.onpause()
            else
                options.onresume()
            end

            isRunning = not isRunning

            dialog:modify{id = "start-stop", text = isRunning and "||" or "|>"}
        end
    } --
    :button{
        id = "add-milestone",
        text = "+",
        onclick = function()
            local addMilestoneDialog = Dialog {title = "Add Milestone"}

            addMilestoneDialog:entry{id = "title", label = "Title:"} --
            :separator() --
            :button{
                text = "&OK",
                onclick = function()
                    local preferences = options.preferences
                    local sprite = app.activeSprite
                    local filename = sprite.filename
                    local id = Hash(filename)

                    local sessionData = Statistics:GetSessionData(filename)
                    local milestone = SumData(totalData, sessionData)
                    milestone.title = addMilestoneDialog.data.title

                    preferences.milestones[id] =
                        preferences.milestones[id] or {}

                    table.insert(preferences.milestones[id], milestone)

                    for _, m in ipairs(preferences.milestones[id]) do
                        print(m.title, ParseTime(m.totalTime),
                              ParseTime(m.changeTime), m.changes, m.saves,
                              m.sessions)
                    end

                    addMilestoneDialog:close()
                end
            } --
            :button{text = "&Cancel"}

            addMilestoneDialog:show()
        end
    }

    timer = Timer {
        interval = 0.5,
        ontick = function() UpdateDialog(app.activeSprite) end
    }
    timer:start()

    return dialog
end

-- TODO: Use the canvas to render buttons with icons
