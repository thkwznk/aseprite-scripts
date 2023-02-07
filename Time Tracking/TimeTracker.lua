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
    lastSpriteId = nil,
    -- Event Callbacks
    siteChangeCallback = nil,
    spriteChangeCallback = nil,
    filenameChangeCallback = nil
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

function TimeTracker:UpdateSpriteData(id, time)
    local data = self.dataStorage[id]
    local today = self:GetDate()
    local todayData = self:GetDetailsForDate(data.details, today)

    local timeDiff = time - data.startTime

    if data.lastUpdateTime then
        timeDiff = time - data.lastUpdateTime

        todayData.changeTime = todayData.changeTime + timeDiff
    end

    todayData.totalTime = todayData.totalTime + timeDiff
    todayData.changes = todayData.changes + 1

    data.lastUpdateTime = time
end

function TimeTracker:CloseSpriteData(id, time)
    local data = self.dataStorage[id]

    -- Data for temporary files isn't saved
    if self:IsTemporaryFile(data.filename) and
        not self:IsSpriteOpen(data.filename) then
        self.dataStorage[id] = nil
        return
    end

    local today = self:GetDate()
    local todayData = self:GetDetailsForDate(data.details, today)

    local timeDiff = time - data.startTime

    if data.lastUpdateTime then timeDiff = time - data.lastUpdateTime end

    todayData.totalTime = todayData.totalTime + timeDiff

    data.startTime = nil
    data.lastUpdateTime = nil
end

function TimeTracker:IsSpriteOpen(filename)
    for _, sprite in ipairs(app.sprites) do
        if sprite.filename == filename then return true end
    end

    return false
end

function TimeTracker:OnSpriteChange()
    local id = GetHash(self.currentSprite.filename)
    local now = self.GetClock()

    self:UpdateSpriteData(id, now)
end

function TimeTracker:OnSpriteFilenameChange()
    local id = GetHash(self.currentSprite.filename)
    local data = self.dataStorage[id]
    local today = self:GetDate()
    local todayData = self:GetDetailsForDate(data.details, today)

    todayData.saves = (todayData.saves or 0) + 1

    -- If the current and last IDs are the same it's a regular file save
    if id == self.lastSpriteId then return end

    local now = self.GetClock()

    local lastData = self.dataStorage[self.lastSpriteId]

    -- TODO: What if data for this ID already exists? It shouldn't... but what if?
    self.dataStorage[id] = {
        filename = self.currentSprite.filename,
        startTime = lastData.startTime,
        lastUpdateTime = lastData.lastUpdateTime,
        details = self:_Deepcopy(lastData.details)
    }

    -- Close sprite data after copying
    self:CloseSpriteData(self.lastSpriteId, now)

    self.lastSpriteId = id
    self.currentSprite = app.activeSprite
end

function TimeTracker:CloseCurrentSprite(time)
    if self.currentSprite == nil then return end

    local id = GetHash(self.currentSprite.filename)

    self:CloseSpriteData(id, time)

    self.currentSprite.events:off(self.spriteChangeCallback)
    self.currentSprite.events:off(self.filenameChangeCallback)

    self.currentSprite = nil
end

function TimeTracker:OnSiteChange()
    local sprite = app.activeSprite

    -- If sprite didn't change, do nothing
    if sprite == self.currentSprite then return end

    local now = self.GetClock()

    -- Save the total time and close the current sprite
    if self.currentSprite ~= nil then self:CloseCurrentSprite(now) end

    -- Update the current sprite
    self.currentSprite = sprite
    self.lastSpriteId = nil

    if self.currentSprite ~= nil then
        local id = GetHash(self.currentSprite.filename)
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
    local now = self.GetClock()

    self:CloseCurrentSprite(now)
end

function TimeTracker:Unpause()
    -- Simulate a site change
    self:OnSiteChange()
end

function TimeTracker:Start(dataStorage)
    self.dataStorage = dataStorage
    self.currentSprite = app.activeSprite

    -- Start responding to the site change
    self.siteChangeCallback = app.events:on("sitechange",
                                            function() self:OnSiteChange() end)
end

function TimeTracker:Stop()
    -- Stop responding to the site change
    app.events:off(self.siteChangeCallback)
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
        local totalTime, changeTime, changes, saves = 0, 0, 0, 0

        for _, yearData in pairs(completeData.details) do
            for _, monthData in pairs(yearData) do
                for _, dayData in pairs(monthData) do
                    totalTime = totalTime + dayData.totalTime
                    changeTime = changeTime + dayData.changeTime
                    changes = changes + dayData.changes
                    saves = saves + (dayData.saves or 0) -- Added in version 1.0.2, can be `nil` for entries from older versions
                end
            end
        end

        return {
            totalTime = totalTime + unsavedTime,
            changeTime = changeTime,
            changes = changes,
            saves = saves
        }
    end

    local specificData = self:GetDetailsForDate(completeData.details, date)

    return {
        totalTime = specificData.totalTime + unsavedTime,
        changeTime = specificData.changeTime,
        changes = specificData.changes,
        saves = specificData.saves or 0 -- Added in version 1.0.2, can be `nil` for entries from older versions
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
