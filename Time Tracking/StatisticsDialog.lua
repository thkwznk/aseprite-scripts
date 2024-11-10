local Statistics = dofile("./Statistics.lua")

local function ParseTime(time)
    local seconds = time % 60
    local hours = math.floor(time / 3600)
    local minutes = math.floor((time - (hours * 3600)) / 60)

    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

return function(options)
    local filename = options.sprite.filename
    Statistics:Init(options.preferences)

    local dialog = Dialog {title = "Sprite Statistics"}

    local totalData = Statistics:GetTotalData(filename)
    local todayData = Statistics:GetTodayData(filename)

    dialog --
    :separator{text = "File:"} --
    :label{label = "Name:", text = app.fs.fileName(filename)} --
    :label{label = "Directory:", text = app.fs.filePath(filename)} --
    :separator{text = "Total:"} --
    :label{
        id = "total-time",
        label = "Time:",
        text = ParseTime(totalData.totalTime)
    } --
    :label{
        id = "total-change-time",
        label = "Change Time:",
        text = ParseTime(totalData.changeTime)
    } --
    :label{
        id = "total-changes",
        label = "Changes:",
        text = tostring(totalData.changes)
    } --
    :label{
        id = "total-saves",
        label = "Saves:",
        text = tostring(totalData.saves)
    } --
    :label{
        id = "total-sessions",
        label = "Sessions:",
        text = tostring(totalData.sessions)
    } --
    :separator{text = "Today:"} --
    :label{
        id = "today-time",
        label = "Time:",
        text = ParseTime(todayData.totalTime)
    } --
    :label{
        id = "today-change-time",
        label = "Change Time:",
        text = ParseTime(todayData.changeTime)
    } --
    :label{
        id = "today-changes",
        label = "Changes:",
        text = tostring(todayData.changes)
    } --
    :label{
        id = "today-saves",
        label = "Saves:",
        text = tostring(todayData.saves)
    } --
    :label{
        id = "today-sessions",
        label = "Sessions:",
        text = tostring(todayData.sessions)
    } --
    :separator() --
    :button{text = "Close", focus = true}

    return dialog
end
