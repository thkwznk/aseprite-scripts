ColorList = dofile("./ColorList.lua")
SortOptions = dofile("./SortOptions.lua")

local PageSize = 16
local MinDialogWidth = 250

local ColorAnalyzerDialog = {}

function ColorAnalyzerDialog:Create(title)
    self.title = title or self.title
    self.sortBy = self.sortBy or SortOptions.UsageDesc
    self.page = self.page or 1

    local function onChange()
        self.page = 1
        self:Refresh()
    end

    -- Saving the active sprite to a variable to reference it in the dialog's "onclose" function
    local sprite = app.activeSprite
    local onSiteChange = app.events:on('sitechange', onChange)
    local onSpriteChange = sprite and sprite.events:on('change', onChange)

    self.dialog = Dialog {
        title = self.title,
        onclose = function()
            if onSiteChange ~= nil then app.events:off(onSiteChange) end
            if onSpriteChange ~= nil then
                sprite.events:off(onSpriteChange)
            end
        end
    }

    if app.activeSprite == nil or app.activeCel == nil then
        -- Display an empty dialog when there's no active sprite
        self.dialog --
        :separator{text = "No image"} --
        :button{text = "Close"}
        return
    end

    -- Colors
    self.dialog --
    :combobox{
        id = "sortBy",
        label = "Sort By",
        option = self.sortBy,
        options = SortOptions,
        onchange = function()
            self.sortBy = self.dialog.data["sortBy"]
            self:Refresh()
        end
    } --
    :separator{text = "Colors"}

    local image = app.activeCel.image
    local colorEntries = ColorList --
    :Clear() --
    :LoadColorsFromImage(image) --
    :GetColors(self.sortBy)
    local numberOfPages = math.ceil(#colorEntries / PageSize)

    -- Page Buttons
    local hasPreviousPage = self.page > 1
    local hasNextPage = self.page < numberOfPages

    self.dialog --
    :button{
        text = hasPreviousPage and "Prev",
        visible = numberOfPages > 1,
        onclick = function()
            if not hasPreviousPage then return end
            self.page = self.page - 1
            self:Refresh()
        end
    } --
    :button{
        text = hasNextPage and "Next",
        visible = numberOfPages > 1,
        onclick = function()
            if not hasNextPage then return end
            self.page = self.page + 1
            self:Refresh()
        end
    }

    -- Color List
    local pageSkip = (self.page - 1) * (PageSize)
    local numberOfColorsOnPage = math.min(PageSize, #colorEntries - pageSkip)

    local maxColorCount = 0
    for _, colorEntry in ipairs(colorEntries) do
        maxColorCount = maxColorCount + colorEntry.count
    end

    for i = 1, numberOfColorsOnPage do
        local colorEntry = colorEntries[pageSkip + i]
        local colorUsagePercent = (colorEntry.count / maxColorCount) * 100

        self.dialog --
        :color{
            label = string.format("%.2f %%", colorUsagePercent),
            color = colorEntry.color,
            enabled = false
        }
    end

    -- Palette
    self.dialog --
    :separator{text = "Palette"} --
    :button{
        text = "Sort",
        onclick = function()
            app.transaction(function()
                ColorList:SortPalette(colorEntries)
            end)

            self.dialog:close()
        end
    } --
    :button{text = "Close"}
end

function ColorAnalyzerDialog:Refresh()
    if self.dialog == nil then return end

    local savedBounds = self.dialog.bounds

    self:Close()
    self:Create()
    self:Show()

    savedBounds.height = self.dialog.bounds.height
    self.dialog.bounds = savedBounds
end

function ColorAnalyzerDialog:Show()
    if self.dialog == nil then return end

    self.dialog:show{wait = false}

    -- Don't display the dialog in the center of the screen, It covers the image
    -- Also, it's a coincidence this works - it's set for every show, refresh copies old value, that's the only reson why this doesn't reset on every refresh
    local bounds = self.dialog.bounds
    bounds.x = bounds.x / 2
    bounds.width = MinDialogWidth
    self.dialog.bounds = bounds
end

function ColorAnalyzerDialog:Close()
    if self.dialog == nil then return end

    self.dialog:close()
end

return ColorAnalyzerDialog
