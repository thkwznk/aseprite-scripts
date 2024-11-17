local Statistics = dofile("../Statistics.lua")
local Time = dofile("../Time.lua")

return function(options)
    local timer
    local filename = options.sprite.filename
    Statistics:Init(options.preferences)

    local dialog = Dialog {title = "Sprite Statistics"}

    local totalData = Statistics:GetTotalData(filename, true)
    local todayData = Statistics:GetTodayData(filename, true)
    local time = 0

    local function AddSection(prefix, title, data)
        dialog --
        :separator{text = title .. ":"} --
        :label{
            id = prefix .. "-time",
            label = "Open Time:",
            text = Time.Parse(data.totalTime)
        } --
        :label{
            id = prefix .. "-change-time",
            label = "Active Time:",
            text = Time.Parse(data.changeTime)
        } --
        :label{
            id = prefix .. "-sessions",
            label = "Sessions:",
            text = tostring(data.sessions)
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
    end

    dialog --
    :separator{text = "File:"} --
    :label{label = "Name:", text = app.fs.fileName(filename)} --
    :label{label = "Directory:", text = app.fs.filePath(filename)} --

    AddSection("total", "Total", totalData)
    AddSection("today", "Today", totalData)

    dialog --
    :separator() --
    :button{text = "Close", focus = true}

    timer = Timer {
        interval = 1.0,
        ontick = function()
            time = time + 1
            -- Update only total time - nothing else can change when this dialog is open
            dialog --
            :modify{
                id = "total-time",
                text = Time.Parse(totalData.totalTime + time)
            } --
            :modify{
                id = "today-time",
                text = Time.Parse(todayData.totalTime + time)
            } --
        end
    }
    timer:start()

    return dialog
end
