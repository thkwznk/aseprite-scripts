local Statistics = dofile("../Statistics.lua")
local Time = dofile("../Time.lua")
local Tracking = dofile("../Tracking.lua")

return function(options)
    local dialog, timer

    local filename = options.sprite.filename
    Statistics:Init(options.preferences)

    dialog = Dialog {
        title = "Sprite Statistics",
        onclose = function()
            timer:stop()
            if options.onclose then options.onclose(dialog.data) end
        end
    }

    local sessionData = Statistics:GetSessionData(filename)

    local todayData = Statistics:GetTodayData(filename, true)
    todayData = Tracking.Sum(todayData, sessionData)

    local totalData = Statistics:GetTotalData(filename, true)
    totalData = Tracking.Sum(totalData, sessionData)

    local function AddSection(prefix, title, data)
        dialog --
        :tab{id = prefix .. "-tab", text = title} --
        :label{
            id = prefix .. "-time",
            label = "Time:",
            text = Time.Parse(data.totalTime)
        } --
        :label{
            id = prefix .. "-changes",
            label = "Changes:",
            text = tostring(data.changes)
        } --
        :label{
            id = prefix .. "-saves",
            label = "Saves:",
            text = tostring(data.saves)
        } --
        :label{
            id = prefix .. "-sessions",
            label = "Sessions:",
            text = tostring(data.sessions or "-")
        } --
    end

    dialog --
    :separator{text = "File:"} --
    :label{label = "Name:", text = app.fs.fileName(filename)} --
    :label{label = "Directory:", text = app.fs.filePath(filename)} --

    AddSection("current-session", "Current Session", sessionData)
    AddSection("today", "     Today     ", todayData)
    AddSection("total", "     Total     ", totalData)

    dialog --
    :endtabs{
        id = "statistics-tab",
        selected = options.selectedTab or "current-session-tab",
        align = Align.CENTER | Align.TOP
    } --
    :button{text = "Close", focus = true}

    local time = 0

    timer = Timer {
        interval = 1.0,
        ontick = function()
            time = time + 1
            -- Update only total time - nothing else can change when this dialog is open
            dialog --
            :modify{
                id = "current-session-time",
                text = Time.Parse(sessionData.totalTime + time)
            } --
            :modify{
                id = "today-time",
                text = Time.Parse(todayData.totalTime + time)
            } --
            :modify{
                id = "total-time",
                text = Time.Parse(totalData.totalTime + time)
            } --
        end
    }
    timer:start()

    return dialog
end
