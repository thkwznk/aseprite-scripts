local Hash = dofile("./Hash.lua")
local PreferencesConverter = dofile("./PreferencesConverter.lua")

local DefaultData = function()
    return {totalTime = 0, changeTime = 0, changes = 0, saves = 0}
end

local TimeTracker = {
    dataStorage = {},
    currentSprite = nil,
    lastSpriteId = nil,

    -- Event Callbacks
    siteChangeCallback = nil,
    spriteChangeCallback = nil,
    filenameChangeCallback = nil
}

function TimeTracker:Now() return os.clock() end

function TimeTracker:Date()
    local time = os.time()
    return os.date("*t", time)
end

function TimeTracker:IsTemporaryFile(filename) return
    not app.fs.isFile(filename) end

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

function TimeTracker:GetDetailsForDate(details, date)
    local y, m, d = "_" .. tostring(date.year), "_" .. tostring(date.month),
                    "_" .. tostring(date.day)

    if not details[y] then details[y] = {} end
    if not details[y][m] then details[y][m] = {} end
    if not details[y][m][d] then details[y][m][d] = {} end

    return details[y][m][d]
end

function TimeTracker:UpdateSpriteData(id, time)
    local data = self.dataStorage[id]
    local sessionData = data.currentSession
    local timeDiff = time - data.startTime

    if data.lastUpdateTime then
        timeDiff = time - data.lastUpdateTime

        sessionData.changeTime = sessionData.changeTime + timeDiff
    end

    sessionData.totalTime = sessionData.totalTime + timeDiff
    sessionData.changes = sessionData.changes + 1

    data.lastUpdateTime = time
end

function TimeTracker:CloseSpriteData(id, time)
    local data = self.dataStorage[id]
    local isTrueClose = not self:IsSpriteOpen(data.filename)

    -- Data for temporary files isn't saved
    if self:IsTemporaryFile(data.filename) and isTrueClose then
        self.dataStorage[id] = nil
        return
    end

    local sessionData = data.currentSession
    sessionData.totalTime = sessionData.totalTime +
                                self:_GetUnsavedTime(data, time)

    data.startTime = nil
    data.lastUpdateTime = nil

    if isTrueClose then data.currentSession = nil end
end

function TimeTracker:IsSpriteOpen(filename)
    for _, sprite in ipairs(app.sprites) do
        if sprite.filename == filename then return true end
    end

    return false
end

function TimeTracker:OnSpriteChange()
    local id = Hash(self.currentSprite.filename)
    local now = self:Now()

    self:UpdateSpriteData(id, now)
end

function TimeTracker:OnSpriteFilenameChange()
    local id = Hash(self.currentSprite.filename)
    local lastData = self.dataStorage[self.lastSpriteId]

    local lastSpriteSessionData = lastData.currentSession
    lastSpriteSessionData.saves = (lastSpriteSessionData.saves or 0) + 1

    -- If the current and last IDs are the same it's a regular file save
    if id == self.lastSpriteId then return end

    local now = self:Now()
    local today = self:Date()

    local detailsCopy = self:_Deepcopy(lastData.details)
    local todayCopy = self:GetDetailsForDate(detailsCopy, today)

    -- TODO: What if data for this ID already exists? It shouldn't... but what if?
    self.dataStorage[id] = {
        filename = self.currentSprite.filename,
        startTime = lastData.startTime,
        lastUpdateTime = lastData.lastUpdateTime,
        details = detailsCopy,
        -- Overwrite the current session to not leave a reference to the old sprite's session
        currentSession = todayCopy[#todayCopy]
    }

    -- Close sprite data after copying
    self:CloseSpriteData(self.lastSpriteId, now)

    self.lastSpriteId = id
    self.currentSprite = app.activeSprite
end

function TimeTracker:CloseCurrentSprite(time)
    if self.currentSprite == nil then return end

    local id = Hash(self.currentSprite.filename)

    self:CloseSpriteData(id, time)

    if self.spriteChangeCallback then
        self.currentSprite.events:off(self.spriteChangeCallback)
    end

    if self.filenameChangeCallback then
        self.currentSprite.events:off(self.filenameChangeCallback)
    end

    self.currentSprite = nil
end

function TimeTracker:OnSiteChange()
    local sprite = app.activeSprite

    -- If sprite didn't change, do nothing
    if sprite == self.currentSprite then return end

    local now = self:Now()

    -- Save the total time and close the current sprite
    if self.currentSprite ~= nil then self:CloseCurrentSprite(now) end

    -- Update the current sprite
    self.currentSprite = sprite
    self.lastSpriteId = nil

    -- Open a new sprite
    if self.currentSprite ~= nil then
        local id = Hash(self.currentSprite.filename)
        self.lastSpriteId = id

        -- Create a new entry if there is none OR if the sprite is only a temporary file that is not already open (e.g. Sprite-001, Sprite-002...)
        if self.dataStorage[id] == nil or
            (self:IsTemporaryFile(self.currentSprite.filename) and
                not self:IsSpriteOpen(self.currentSprite.filename)) then
            self.dataStorage[id] = {
                filename = self.currentSprite.filename,
                details = {}
            }
        end

        local data = self.dataStorage[id]
        data.startTime = now
        data.lastUpdateTime = nil

        if not data.currentSession then
            local today = self:Date()
            local todayData = self:GetDetailsForDate(data.details, today)

            local newSession = DefaultData()
            data.currentSession = newSession

            table.insert(todayData, data.currentSession)
        end

        self.spriteChangeCallback = self.currentSprite.events:on("change",
                                                                 function()
            self:OnSpriteChange()
        end)

        self.filenameChangeCallback = self.currentSprite.events:on(
                                          "filenamechange", function()
                self:OnSpriteFilenameChange()
            end)
    end
end

function TimeTracker:Pause()
    local now = self:Now()

    self:CloseCurrentSprite(now)
end

function TimeTracker:Unpause()
    -- Simulate a site change
    self:OnSiteChange()
end

function TimeTracker:Start(dataStorage)
    self.dataStorage = PreferencesConverter:Convert(dataStorage)
    self.currentSprite = app.activeSprite

    -- Start responding to the site change
    self.siteChangeCallback = app.events:on("sitechange",
                                            function() self:OnSiteChange() end)
end

function TimeTracker:Stop()
    -- Stop responding to the site change
    app.events:off(self.siteChangeCallback)
end

function TimeTracker:_GetUnsavedTime(spriteData, time)
    -- If there's is no start time - sprite is closed
    if not spriteData.startTime then return 0 end

    -- If there's the last update time - count from then
    if spriteData.lastUpdateTime then return time - spriteData.lastUpdateTime end

    return time - spriteData.startTime
end

function TimeTracker:GetTotalData(filename)
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

    local now = self:Now()

    return {
        totalTime = totalTime + self:_GetUnsavedTime(data, now),
        changeTime = changeTime,
        changes = changes,
        saves = saves,
        sessions = sessions
    }
end

function TimeTracker:GetTodayData(filename)
    if not filename then return DefaultData() end

    local date = self:Date()
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

    local now = self:Now()

    return {
        totalTime = totalTime + self:_GetUnsavedTime(data, now),
        changeTime = changeTime,
        changes = changes,
        saves = saves,
        sessions = sessions
    }
end

function TimeTracker:GetSessionData(filename)
    if not filename then return DefaultData() end

    local spriteId = Hash(filename)
    local data = self.dataStorage[spriteId]

    if not data or not data.currentSession then return DefaultData() end

    local now = self:Now()

    return {
        totalTime = data.currentSession.totalTime +
            self:_GetUnsavedTime(data, now),
        changeTime = data.currentSession.changeTime,
        changes = data.currentSession.changes,
        saves = data.currentSession.saves
    }
end

function TimeTracker:GetFilenames()
    local filenames = {""}

    for _, dataEntry in pairs(self.dataStorage) do
        if type(dataEntry) == "table" then
            table.insert(filenames, dataEntry.filename)
        end
    end

    table.sort(filenames)

    return filenames
end

return TimeTracker
