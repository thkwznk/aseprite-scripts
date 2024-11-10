local ChangeTracker = {
    currentSprite = nil,
    previousFilename = nil,
    --
    onSiteEnter = function(sprite) end,
    onSiteLeave = function(sprite) end,
    onChange = function(sprite) end,
    onFilenameChange = function(sprite, previousFilename) end,
    -- Event Callbacks
    siteChangeListener = nil,
    changeListener = nil,
    filenameChangeListener = nil
}

function ChangeTracker:Start(options)
    self.onSiteEnter = options.onsiteenter
    self.onSiteLeave = options.onsiteleave
    self.onChange = options.onchange
    self.onFilenameChange = options.onfilenamechange

    self.siteChangeListener = app.events:on("sitechange",
                                            function() self:OnSiteChange() end)
end

function ChangeTracker:Stop() app.events:off(self.siteChangeListener) end

function ChangeTracker:OnSiteChange()
    local sprite = app.activeSprite

    -- If sprite didn't change, do nothing
    if sprite == self.currentSprite then return end

    -- Save the total time and close the current sprite
    if self.currentSprite ~= nil then self:CloseCurrentSprite() end

    -- Update the current sprite
    self.currentSprite = sprite

    -- Open a new sprite
    if self.currentSprite ~= nil then
        self.previousFilename = self.currentSprite.filename
        self.onSiteEnter(self.currentSprite)

        self.changeListener = self.currentSprite.events:on("change", function()
            self.onChange(self.currentSprite)
        end)

        self.filenameChangeCallback = self.currentSprite.events:on(
                                          "filenamechange", function()
                self.onFilenameChange(self.currentSprite, self.previousFilename)
                self.previousFilename = self.currentSprite.filename
            end)
    end
end

function ChangeTracker:CloseCurrentSprite()
    if self.currentSprite == nil then return end

    self.onSiteLeave(self.currentSprite)
    self.currentSprite.events:off(self.changeListener)

    self.currentSprite = nil
end

return ChangeTracker

-- Using sprite properties for saving time data has it's downsides, one of them is that if a file is not saved at the end of a session all of the data is lost
