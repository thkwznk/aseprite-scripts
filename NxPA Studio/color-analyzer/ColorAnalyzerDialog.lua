Transaction = dofile("../shared/Transaction.lua")
ColorList = dofile("./ColorList.lua")
SortOptions = dofile("./SortOptions.lua")

local MinDialogWidth<const> = 250

local ColorAnalyzerDialog = {
    title = nil,
    dialog = nil,
    sortBy = SortOptions.UsageDesc,
    page = 1,
    pageSize = 16
}

function ColorAnalyzerDialog:Create(title)
    self.title = title or self.title

    local sprite = app.activeSprite

    local function onChange()
        -- Reset page number
        self.page = 1
        self:Refresh()
    end
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

    local palette = app.activeSprite.palettes[1]
    local isIndexedPalette = app.activeImage.spec.colorMode == ColorMode.INDEXED

    -- Colors
    self.dialog:combobox{
        id = "sortBy",
        label = "Sort By",
        option = self.sortBy,
        options = SortOptions,
        onchange = function()
            self.sortBy = self.dialog.data["sortBy"]
            self:Refresh()
        end
    }

    self.dialog:separator{text = "Colors"}

    ColorList:Clear()
    ColorList:GetColorsFromFrame(sprite, app.activeFrame)
    ColorList:Sort(self.sortBy)

    local pageSkip = (self.page - 1) * (self.pageSize)
    local numberOfColorsOnPage = math.min(self.pageSize, #ColorList - pageSkip)
    local numberOfPages = math.ceil(#ColorList / self.pageSize)

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

    for i = 1, numberOfColorsOnPage do
        local color = ColorList[pageSkip + i]
        local colorId = tostring(i)
        local resetButtonId = "reset" .. colorId
        local colorValue = Color(color.value)
        local colorUsagePercent =
            (color.count / (sprite.width * sprite.height)) * 100

        self.dialog --
        :color{
            id = colorId,
            label = string.format("%.2f %%", colorUsagePercent),
            color = colorValue,
            onchange = function()
                local newColorValue = self.dialog.data[colorId]

                palette:setColor(color.paletteIndex, newColorValue)

                if not isIndexedPalette then
                    app.command.ReplaceColor {
                        ui = false,
                        from = colorValue,
                        to = newColorValue,
                        tolerance = 0
                    }
                    colorValue = Color(newColorValue)
                end

                self.dialog:modify{id = resetButtonId, visible = true}
            end
        } --
        :button{
            id = resetButtonId,
            text = "Reset",
            onclick = function()
                palette:setColor(color.paletteIndex, Color {
                    red = color.red,
                    green = color.green,
                    blue = color.blue,
                    alpha = color.alpha
                })

                if not isIndexedPalette then
                    app.command.ReplaceColor {
                        ui = false,
                        from = colorValue,
                        to = color.value,
                        tolerance = 0
                    }
                    colorValue = Color(color.value)
                end

                self.dialog:modify{id = colorId, color = color.value} -- Reset color on widget
                self.dialog:modify{id = resetButtonId, visible = false} -- Hide reset button
            end,
            visible = false
        }
    end

    -- Palette
    self.dialog --
    :separator{text = "Palette"} --
    :button{
        text = "Sort",
        onclick = Transaction(function()
            if isIndexedPalette then
                ColorList:CopyToIndexedPalette(palette)
            else
                ColorList:CopyToPalette(palette)
            end

            self.dialog:close()
        end)
    } --
    :button{text = "Close"}
end

function ColorAnalyzerDialog:Refresh()
    local bounds = self.dialog.bounds

    self:Close()
    self:Create()
    self:Show(false)

    local newBounds = self.dialog.bounds
    newBounds.x = bounds.x
    newBounds.y = bounds.y
    newBounds.width = math.max(bounds.width, MinDialogWidth)
    self.dialog.bounds = newBounds
end

function ColorAnalyzerDialog:Show(wait)
    self.dialog:show{wait = wait}

    -- Don't display the dialog in the center of the screen, It covers the image
    local bounds = self.dialog.bounds
    bounds.x = bounds.x / 2
    bounds.width = MinDialogWidth
    self.dialog.bounds = bounds
end

function ColorAnalyzerDialog:Close()
    if self.dialog ~= nil then self.dialog:close() end
end

return ColorAnalyzerDialog
