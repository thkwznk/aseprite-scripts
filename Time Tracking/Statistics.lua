local Hash = dofile("./Hash.lua")
local DefaultData = dofile("./DefaultData.lua")
local Time = dofile("./Time.lua")

local Statistics = {dataStorage = nil}

function Statistics:Init(pluginPreferences) self.dataStorage = pluginPreferences end

function Statistics:GetTotalData(filename)
    if not filename then return DefaultData() end

    local spriteId = Hash(filename)
    local data = self.dataStorage[spriteId]

    if not data then return DefaultData() end

    local totalTime, changeTime, changes, saves, sessions = 0, 0, 0, 0, 0

    for _, yearData in pairs(data.details) do
        for _, monthData in pairs(yearData) do
            for _, dayData in pairs(monthData) do
                for _, sessionData in ipairs(dayData) do
                    totalTime = totalTime + sessionData.totalTime
                    changeTime = changeTime + sessionData.changeTime
                    changes = changes + sessionData.changes
                    saves = saves + sessionData.saves
                end

                sessions = sessions + #dayData
            end
        end
    end

    local now = Time.Now()

    return {
        totalTime = totalTime + self:_GetUnsavedTime(data, now),
        changeTime = changeTime,
        changes = changes,
        saves = saves,
        sessions = sessions
    }
end

function Statistics:GetTodayData(filename)
    if not filename then return DefaultData() end

    local date = Time.Date()
    local spriteId = Hash(filename)
    local data = self.dataStorage[spriteId]

    if not data then return DefaultData() end

    local dayData = self:GetDetailsForDate(data.details, date)
    local totalTime, changeTime, changes, saves = 0, 0, 0, 0
    local sessions = #dayData

    for _, sessionData in ipairs(dayData) do
        totalTime = totalTime + sessionData.totalTime
        changeTime = changeTime + sessionData.changeTime
        changes = changes + sessionData.changes
        saves = saves + sessionData.saves
    end

    local now = Time.Now()

    return {
        totalTime = totalTime + self:_GetUnsavedTime(data, now),
        changeTime = changeTime,
        changes = changes,
        saves = saves,
        sessions = sessions
    }
end

function Statistics:GetSessionData(filename)
    if not filename then return DefaultData() end

    local spriteId = Hash(filename)
    local data = self.dataStorage[spriteId]

    if not data or not data.currentSession then return DefaultData() end

    local now = Time.Now()

    return {
        totalTime = data.currentSession.totalTime +
            self:_GetUnsavedTime(data, now),
        changeTime = data.currentSession.changeTime,
        changes = data.currentSession.changes,
        saves = data.currentSession.saves
    }
end

function Statistics:_GetUnsavedTime(spriteData, time)
    -- If there's is no start time - sprite is closed
    if not spriteData.startTime then return 0 end

    -- If there's the last update time - count from then
    if spriteData.lastUpdateTime then return time - spriteData.lastUpdateTime end

    return time - spriteData.startTime
end

function Statistics:GetDetailsForDate(details, date)
    local y, m, d = "_" .. tostring(date.year), "_" .. tostring(date.month),
                    "_" .. tostring(date.day)

    if not details[y] then details[y] = {} end
    if not details[y][m] then details[y][m] = {} end
    if not details[y][m][d] then details[y][m][d] = {} end

    return details[y][m][d]
end

return Statistics
