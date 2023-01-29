local sha1 = dofile("./sha1.lua")

-- TODO: Integrate hashing into the new SHA1 class/method

local hash, cached, hashCache = nil, nil, {}

local GetHash = function(text)
    cached = hashCache[text]
    if cached then return cached end

    -- Add a "_" as the first character to always make it a valid table key
    hash = "_" .. sha1.hex(text)
    hashCache[text] = hash

    return hash
end

local DefaultData = function()
    return {totalTime = 0, changeTime = 0, changes = 0}
end

local TimeTracker = {
    GetClock = os.clock,
    GetTime = os.time,
    dataStorage = {},
    currentSprite = nil,
    lastSpriteId = nil
}

function TimeTracker:GetDate()
    local time = self.GetTime()
    return os.date("*t", time)
end

function TimeTracker:IsTemporaryFile(filename)
    return string.sub(filename, 0, 6) == "Sprite"
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

function TimeTracker:GetDetailsForDate(details, date)
    local y, m, d = "_" .. tostring(date.year), "_" .. tostring(date.month),
                    "_" .. tostring(date.day)

    if not details[y] then details[y] = {} end
    if not details[y][m] then details[y][m] = {} end
    if not details[y][m][d] then details[y][m][d] = DefaultData() end

    return details[y][m][d]
end

function TimeTracker:UpdateData(data, time)
    local today = self:GetDate()
    local todayData = self:GetDetailsForDate(data.details, today)

    if data.lastUpdateTime then
        local timeDiff = time - data.lastUpdateTime

        data.totalTime = data.totalTime + timeDiff
        todayData.totalTime = todayData.totalTime + timeDiff

        data.changeTime = data.changeTime + timeDiff
        todayData.changeTime = todayData.changeTime + timeDiff
    else
        local timeDiff = time - data.startTime

        data.totalTime = data.totalTime + timeDiff
        todayData.totalTime = todayData.totalTime + timeDiff
    end

    data.lastUpdateTime = time

    data.changes = data.changes + 1
    todayData.changes = todayData.changes + 1
end

function TimeTracker:CloseData(data, time)
    local today = self:GetDate()
    local todayData = self:GetDetailsForDate(data.details, today)

    if data.lastUpdateTime then
        local timeDiff = time - data.lastUpdateTime

        data.totalTime = data.totalTime + timeDiff
        todayData.totalTime = todayData.totalTime + timeDiff
    else
        local timeDiff = (time - data.startTime)

        data.totalTime = data.totalTime + timeDiff
        todayData.totalTime = todayData.totalTime + timeDiff
    end

    data.startTime = nil
    data.lastUpdateTime = nil
end

function TimeTracker:OnSpriteChange()
    local id = GetHash(self.currentSprite.filename)
    local now = self.GetClock()
    local data = self.dataStorage[id]

    self:UpdateData(data, now)
end

function TimeTracker:OnSpriteFilenameChange()
    local id = GetHash(self.currentSprite.filename)
    local now = self.GetClock()

    local lastData = self.dataStorage[self.lastSpriteId]

    -- TODO: What if data for this ID already exists? It shouldn't... but what if?
    self.dataStorage[id] = {
        filename = self.currentSprite.filename,
        totalTime = lastData.totalTime,
        changeTime = lastData.changeTime,
        changes = lastData.changes,
        startTime = lastData.startTime,
        lastUpdateTime = lastData.lastUpdateTime,
        details = self:_Deepcopy(lastData.details)
    }

    if self:IsTemporaryFile(lastData.filename) then
        self.dataStorage[self.lastSpriteId] = nil
    else
        self:CloseData(lastData, now)
    end

    self.lastSpriteId = id
    self.currentSprite = app.activeSprite
end

function TimeTracker:OnSiteChange()
    local sprite = app.activeSprite

    -- If sprite didn't change, do nothing
    if sprite == self.currentSprite then return end

    local now = self.GetClock()

    -- Save the total time and deregister event listener
    if self.currentSprite ~= nil and self.currentSprite.filename then
        local id = GetHash(self.currentSprite.filename)
        local data = self.dataStorage[id]

        if self:IsTemporaryFile(self.currentSprite.filename) then
            self.dataStorage[id] = nil
        else
            self:CloseData(data, now)
        end

        self.currentSprite.events:off(self.OnSpriteChange)
        self.currentSprite.events:off(self.OnSpriteFilenameChange)
    end

    -- Update the current sprite
    self.currentSprite = sprite
    self.lastSpriteId = nil

    if self.currentSprite ~= nil then
        local id = GetHash(self.currentSprite.filename)
        self.lastSpriteId = id

        -- Create a new entry if there is none OR if the sprite is only a temporary file (e.g. Sprite-001, Sprite-002...)
        if self.dataStorage[id] == nil or
            self:IsTemporaryFile(self.currentSprite.filename) then
            self.dataStorage[id] = {
                filename = self.currentSprite.filename,
                totalTime = 0,
                changeTime = 0,
                changes = 0,
                details = {}
            }
        end

        local data = self.dataStorage[id]
        data.startTime = now
        data.lastUpdateTime = nil

        self.currentSprite.events:on("change",
                                     function() self:OnSpriteChange() end)
        self.currentSprite.events:on("filenamechange", function()
            self:OnSpriteFilenameChange()
        end)
    end
end

function TimeTracker:Start(dataStorage)
    self.dataStorage = dataStorage
    self.currentSprite = app.activeSprite

    -- Start responding to the site change
    app.events:on("sitechange", function() self:OnSiteChange() end)
end

function TimeTracker:Stop()
    -- Stop responding to the site change
    app.events:off(self.OnSiteChange)
end

function TimeTracker:GetDataForSprite(filename, date)
    local spriteId = GetHash(filename)

    local completeData = self.dataStorage[spriteId]

    if not completeData then
        return {totalTime = 0, changeTime = 0, changes = 0}
    end

    local unsavedTime = completeData and
                            (completeData.startTime and
                                (self.GetClock() - completeData.startTime)) or 0

    if not date then
        return {
            totalTime = completeData.totalTime + unsavedTime,
            changeTime = completeData.changeTime,
            changes = completeData.changes
        }
    end

    local specificData = self:GetDetailsForDate(completeData.details, date)

    return {
        totalTime = specificData.totalTime + unsavedTime,
        changeTime = specificData.changeTime,
        changes = specificData.changes
    }
end

function TimeTracker:GetFilenames()
    local filenames = {""}

    for _, dataEntry in pairs(self.dataStorage) do
        table.insert(filenames, dataEntry.filename)
    end

    table.sort(filenames)

    return filenames
end

return TimeTracker
