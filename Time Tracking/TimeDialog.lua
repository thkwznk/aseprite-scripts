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
    local isMinimized = true
    local timer, lastFilename, totalData, todayData, lastMilestone
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

    local function UpdateLastMilestone(filename)
        if filename == nil then
            dialog:modify{id = "last-milestone", visible = false}
            return
        end

        local id = Hash(filename)
        local milestones = options.preferences.milestones[id]
        lastMilestone = milestones and milestones[#milestones]

        dialog:modify{id = "last-milestone", visible = lastMilestone ~= nil}

        if lastMilestone then
            local time = lastMilestone.totalTime

            if dialog.data.tab == "session-tab" then
                time = time - totalData.totalTime
            elseif dialog.data.tab == "today-tab" then
                time = time - totalData.totalTime + todayData.totalTime
            end

            dialog:modify{
                id = "last-milestone",
                text = lastMilestone.title .. ": " .. ParseTime(time),
                visible = time > 0
            }
        end
    end

    local function UpdateDialog(sprite)
        if sprite == nil then
            lastFilename = nil
            local data = Tracking.Data()
            UpdateSection("total", data)
            UpdateSection("today", data)
            UpdateSection("session", data)
            UpdateLastMilestone()
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
        UpdateLastMilestone(filename)

        lastFilename = filename
    end

    dialog --
    :tab{id = "session-tab", text = "Session", onclick = function() end} --
    :label{id = "session-time", label = "Time:"} --
    :label{
        id = "session-change-time",
        label = "Change Time:",
        visible = not isMinimized
    } --
    :label{
        id = "session-changes",
        label = "Changes:",
        visible = not isMinimized
    } --
    :label{id = "session-saves", label = "Saves:", visible = not isMinimized} --
    :label{
        id = "session-sessions",
        label = "Sessions:",
        visible = not isMinimized
    } --
    --
    :tab{id = "today-tab", text = "Today", onclick = function() end} --
    :label{id = "today-time", label = "Time:"} --
    :label{
        id = "today-change-time",
        label = "Change Time:",
        visible = not isMinimized
    } --
    :label{id = "today-changes", label = "Changes:", visible = not isMinimized} --
    :label{id = "today-saves", label = "Saves:", visible = not isMinimized} --
    :label{
        id = "today-sessions",
        label = "Sessions:",
        visible = not isMinimized
    } --
    --
    :tab{id = "total-tab", text = "Total", onclick = function() end} --
    :label{id = "total-time", label = "Time:"} --
    :label{
        id = "total-change-time",
        label = "Change Time:",
        visible = not isMinimized
    } --
    :label{id = "total-changes", label = "Changes:", visible = not isMinimized} --
    :label{id = "total-saves", label = "Saves:", visible = not isMinimized} --
    :label{
        id = "total-sessions",
        label = "Sessions:",
        visible = not isMinimized
    } --
    --
    :endtabs{
        id = "tab",
        selected = options.preferences.view .. "-tab",
        onchange = function() options.preferences.view = dialog.data.tab end
    } --
    :label{id = "last-milestone", text = "", enabled = false} --
    :button{
        id = "minimize",
        text = isMinimized and "v" or "^",
        visible = false,
        onclick = function()
            isMinimized = not isMinimized

            dialog --
            :modify{id = "minimize", text = isMinimized and "v" or "^"}

            for _, prefix in ipairs({"session", "today", "total"}) do
                for _, suffix in ipairs({
                    "change-time", "changes", "saves", "sessions"
                }) do
                    dialog:modify{
                        id = prefix .. "-" .. suffix,
                        visible = not isMinimized
                    }
                end
            end

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
