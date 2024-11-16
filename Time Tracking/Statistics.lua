local Hash = dofile("./Hash.lua")
local Tracking = dofile("./Tracking.lua")
local Time = dofile("./Time.lua")

local Statistics = {dataStorage = nil}

function Statistics:Init(pluginPreferences) self.dataStorage = pluginPreferences end

function Statistics:GetTotalData(filename, skipUnsavedTime)
    if not filename then return Tracking.Data() end

    local now = Time.Now()
    local spriteId = Hash(filename)
    local data = self.dataStorage[spriteId]

    if not data then return Tracking.Data() end

    local totalTime, changeTime, changes, saves, sessions = 0, 0, 0, 0, 0
    local totalDays = 0

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
                totalDays = totalDays + 1
            end
        end
    end

    local unsavedTime = 0
    if not skipUnsavedTime then
        local currentSession = data.currentSession
        if currentSession then
            totalTime = totalTime + currentSession.totalTime
            changeTime = changeTime + currentSession.changeTime
            changes = changes + currentSession.changes
            saves = saves + currentSession.saves
            sessions = sessions + 1

            -- TODO: What if it's the first session of the day an only one day before that this file was worked on? How to handle the totalDays in this case?
        end

        unsavedTime = self:_GetUnsavedTime(data, now)
    end

    return {
        totalTime = totalTime + unsavedTime,
        changeTime = changeTime,
        changes = changes,
        saves = saves,
        sessions = sessions,
        totalDays = totalDays
    }
end

function Statistics:GetTodayData(filename, skipUnsavedTime)
    if not filename then return Tracking.Data() end

    local now = Time.Now()
    local date = Time.Date()
    local spriteId = Hash(filename)
    local data = self.dataStorage[spriteId]

    if not data then return Tracking.Data() end

    local dayData = self:_GetDetailsForDate(data.details, date)
    local totalTime, changeTime, changes, saves = 0, 0, 0, 0
    local sessions = #dayData

    for _, sessionData in ipairs(dayData) do
        totalTime = totalTime + sessionData.totalTime
        changeTime = changeTime + sessionData.changeTime
        changes = changes + sessionData.changes
        saves = saves + sessionData.saves
    end

    local unsavedTime = 0
    if not skipUnsavedTime then
        local currentSession = data.currentSession
        if currentSession then
            totalTime = totalTime + currentSession.totalTime
            changeTime = changeTime + currentSession.changeTime
            changes = changes + currentSession.changes
            saves = saves + currentSession.saves
            sessions = sessions + 1

            -- TODO: What if it's the first session of the day an only one day before that this file was worked on? How to handle the totalDays in this case?
        end

        unsavedTime = self:_GetUnsavedTime(data, now)
    end

    return {
        totalTime = totalTime + unsavedTime,
        changeTime = changeTime,
        changes = changes,
        saves = saves,
        sessions = sessions
    }
end

function Statistics:GetSessionData(filename)
    if not filename then return Tracking.Data() end

    local spriteId = Hash(filename)
    local data = self.dataStorage[spriteId]

    if not data or not data.currentSession then return Tracking.Data() end

    local now = Time.Now()

    return {
        totalTime = data.currentSession.totalTime +
            self:_GetUnsavedTime(data, now),
        changeTime = data.currentSession.changeTime,
        changes = data.currentSession.changes,
        saves = data.currentSession.saves
    }
end

function Statistics:AddMilestone(filename, title)
    local id = Hash(filename)
    self.dataStorage.milestones[id] = self.dataStorage.milestones[id] or {}

    local totalData = self:GetTotalData(filename)
    local milestone = Tracking.Milestone(title, totalData)
    table.insert(self.dataStorage.milestones[id], milestone)
end

function Statistics:_GetUnsavedTime(spriteData, time)
    -- If there's is no start time - sprite is closed
    if not spriteData.startTime then return 0 end

    -- If there's the last update time - count from then
    if spriteData.lastUpdateTime then return time - spriteData.lastUpdateTime end

    return time - spriteData.startTime
end

function Statistics:_GetDetailsForDate(details, date)
    local y, m, d = "_" .. tostring(date.year), "_" .. tostring(date.month),
                    "_" .. tostring(date.day)

    if not details[y] then details[y] = {} end
    if not details[y][m] then details[y][m] = {} end
    if not details[y][m][d] then details[y][m][d] = {} end

    return details[y][m][d]
end

return Statistics
