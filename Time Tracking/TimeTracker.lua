local Hash = dofile("./Hash.lua")
local PreferencesConverter = dofile("./PreferencesConverter.lua")
local Tracking = dofile("./Tracking.lua")
local Time = dofile("./Time.lua")

local TimeTracker = {dataStorage = {}}

function TimeTracker:Init(dataStorage)
    self.dataStorage = PreferencesConverter:Convert(dataStorage)
end

function TimeTracker:OnSiteEnter(sprite)
    local now = Time.Now()
    local filename = sprite.filename
    local id = Hash(filename)

    if self.dataStorage[id] == nil then
        self.dataStorage[id] = {filename = filename, details = {}}
    end

    local data = self.dataStorage[id]
    data.startTime = now
    data.lastUpdateTime = nil
    data.currentSession = data.currentSession or Tracking.Session()
end

function TimeTracker:OnSiteLeave(sprite, forceClose)
    local now = Time.Now()
    local id = Hash(sprite.filename)
    local data = self.dataStorage[id]
    if data == nil then return end

    local isTrueClose = forceClose or not self:_IsSpriteOpen(data.filename)

    -- Data for temporary files isn't saved
    if isTrueClose and self:_IsTemporaryFile(data.filename) then
        self.dataStorage[id] = nil
        return
    end

    local currentSession = data.currentSession
    if currentSession then
        currentSession.totalTime = currentSession.totalTime +
                                       self:_GetUnsavedTime(data, now)

        if isTrueClose then
            local todayData = self:_GetDetailsForDate(data.details, Time.Date())
            table.insert(todayData, currentSession)

            data.currentSession = nil
        end
    end

    data.startTime = nil
    data.lastUpdateTime = nil
end

function TimeTracker:OnChange(sprite)
    local id = Hash(sprite.filename)
    local now = Time.Now()

    local data = self.dataStorage[id]
    local sessionData = data.currentSession
    local timeDiff = now - data.startTime

    if data.lastUpdateTime then
        timeDiff = now - data.lastUpdateTime

        sessionData.changeTime = sessionData.changeTime + timeDiff
    end

    sessionData.totalTime = sessionData.totalTime + timeDiff
    sessionData.changes = sessionData.changes + 1

    data.lastUpdateTime = now
end

function TimeTracker:OnFilenameChange(sprite, previousFilename)
    local id = Hash(sprite.filename)
    local previousId = Hash(previousFilename)
    local lastData = self.dataStorage[previousId]

    local lastSpriteSessionData = lastData.currentSession
    lastSpriteSessionData.saves = (lastSpriteSessionData.saves or 0) + 1

    -- If the current and last IDs are the same it's a regular file save
    if id == previousId then return end

    local detailsCopy = self:_Deepcopy(lastData.details)

    self.dataStorage[id] = {
        filename = sprite.filename,
        startTime = lastData.startTime,
        lastUpdateTime = lastData.lastUpdateTime,
        details = detailsCopy,
        currentSession = lastSpriteSessionData
    }
end

function TimeTracker:_IsTemporaryFile(filename)
    return not app.fs.isFile(filename)
end

function TimeTracker:_Deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[self:_Deepcopy(orig_key)] = self:_Deepcopy(orig_value)
        end
        setmetatable(copy, self:_Deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function TimeTracker:_GetDetailsForDate(details, date)
    local y, m, d = "_" .. tostring(date.year), "_" .. tostring(date.month),
                    "_" .. tostring(date.day)

    if not details[y] then details[y] = {} end
    if not details[y][m] then details[y][m] = {} end
    if not details[y][m][d] then details[y][m][d] = {} end

    return details[y][m][d]
end

function TimeTracker:_IsSpriteOpen(filename)
    for _, sprite in ipairs(app.sprites) do
        if sprite.filename == filename then return true end
    end

    return false
end

function TimeTracker:_GetUnsavedTime(spriteData, time)
    -- If there's is no start time - sprite is closed
    if not spriteData.startTime then return 0 end

    -- If there's the last update time - count from then
    if spriteData.lastUpdateTime then return time - spriteData.lastUpdateTime end

    return time - spriteData.startTime
end

return TimeTracker
