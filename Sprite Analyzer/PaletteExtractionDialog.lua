local PageSize<const> = 8

local PaletteExtractionDialog = {
    paletteExtractor = nil,
    dialogBounds = nil,
    dialog = nil,
    cache = {}
}

function PaletteExtractionDialog:New(options)
    options = options or {}
    setmetatable(options, self)
    self.__index = self
    return options
end

function PaletteExtractionDialog:Create()
    self.dialog = Dialog {
        title = "Palette Extraction",
        onclose = function()
            if not self.isRefreshing then
                self.onclose(self.dialogBounds)
            end

            self.isRefreshing = false
        end
    }

    local outlineColors = self.paletteExtractor:GetOutlineColors()
    if outlineColors ~= nil and #outlineColors > 0 then
        self.dialog --
        :separator{text = "Outline"} --
        :shades{colors = outlineColors} --
    end

    self.tolerance = self.tolerance or 50
    self.countTolerance = self.countTolerance or 50

    if self.flatColors == nil or self.refreshColors then
        self.flatColors = self.paletteExtractor:CreateColorRamps(self.tolerance,
                                                                 self.countTolerance)
        self.refreshColors = false
    end

    self.dialog --
    :separator{text = "Palettes"} --
    :slider{
        id = "tolerance",
        label = "Tolerance",
        min = 1,
        max = 100,
        value = self.tolerance,
        onrelease = function()
            self.tolerance = self.dialog.data["tolerance"]
            self:Refresh()
        end
    } --
    :slider{
        id = "count-tolerance",
        label = "Ignorance",
        min = 1,
        max = 100,
        value = self.countTolerance,
        onrelease = function()
            self.countTolerance = self.dialog.data["count-tolerance"]
            self:Refresh()
        end
    }

    local numberOfPages = math.max(math.ceil(#self.flatColors / PageSize), 1)
    self.currentPage = math.min(self.currentPage or 1, numberOfPages)

    if numberOfPages > 1 then
        self.dialog --
        :button{
            text = "<",
            enabled = numberOfPages > 1 and self.currentPage > 1,
            onclick = function()
                self.currentPage = self.currentPage - 1
                self:Refresh{refreshColors = false}
            end
        } --
        :button{
            text = ">",
            enabled = numberOfPages > 1 and self.currentPage < numberOfPages,
            onclick = function()
                self.currentPage = self.currentPage + 1
                self:Refresh{refreshColors = false}
            end
        }
    end

    local skip = (self.currentPage - 1) * PageSize
    local colorsOnPage = math.min(PageSize, #self.flatColors - skip)

    for i = skip + 1, skip + colorsOnPage do
        local colorRamp = self.flatColors[i]
        local id = "colorRamp-" .. tostring(i)

        self.dialog --
        :shades{
            id = id,
            colors = colorRamp,
            mode = "sort",
            onclick = function(ev)
                if ev.button == MouseButton.LEFT then
                    local newColorRamp = self.dialog.data[id]
                    local colorsMoved = false

                    for j = 1, #newColorRamp do
                        if colorRamp[j] ~= newColorRamp[j] then
                            colorsMoved = true
                            break
                        end
                    end

                    if colorsMoved or ev.color == nil then
                        -- If a color was removed
                        if #colorRamp > #newColorRamp then
                            local removedColor = nil

                            for j = 1, #colorRamp do
                                if colorRamp[j] ~= newColorRamp[j] then
                                    removedColor = colorRamp[j]
                                    break
                                end
                            end

                            local colorFound = false

                            -- If no other ramp contains the color then add it separately
                            for j, otherColorRamp in ipairs(self.flatColors) do
                                if j ~= i then
                                    for k = 1, #otherColorRamp do
                                        if removedColor == otherColorRamp[k] then
                                            colorFound = true
                                            break
                                        end
                                    end
                                end

                                if colorFound then
                                    break
                                end
                            end

                            if not colorFound then
                                table.insert(self.flatColors, i + 1,
                                             {removedColor})
                            end
                        end

                        self.flatColors[i] = newColorRamp
                    else
                        -- We can't merge the first color ramp because there's nothing to merge with
                        if i > 1 then
                            for _, v in ipairs(self.flatColors[i]) do
                                table.insert(self.flatColors[i - 1], v)
                            end

                            self.flatColors[i] = {}
                        end
                    end
                else
                    local colorOrderIndex = 1

                    for j = 1, #colorRamp do
                        if colorRamp[j] == ev.color then
                            colorOrderIndex = j
                            break
                        end
                    end

                    if colorOrderIndex > 1 then
                        local left = {}
                        local right = {}

                        for j = 1, #colorRamp do
                            if j < colorOrderIndex then
                                table.insert(left, colorRamp[j])
                            else
                                table.insert(right, colorRamp[j])
                            end
                        end

                        self.flatColors[i] = left
                        table.insert(self.flatColors, i + 1, right)
                    end
                end

                if self.flatColors[i] == nil or #self.flatColors[i] == 0 then
                    table.remove(self.flatColors, i)
                end

                self:Refresh{refreshColors = false}
            end
        } --
        :newrow()
    end

    self.dialog --
    :separator() --
    :button{text = "Confirm"}

    -- Restore bounds
    if self.dialogBounds ~= nil then
        local newBounds = self.dialog.bounds
        newBounds.x = self.dialogBounds.x
        newBounds.y = self.dialogBounds.y
        self.dialog.bounds = newBounds
    end

    self.onchange(outlineColors, self.flatColors)
end

function PaletteExtractionDialog:Show() self.dialog:show{wait = false} end

function PaletteExtractionDialog:Refresh(options)
    self.isRefreshing = true
    self.dialogBounds = self.dialog.bounds
    self.dialog:close()

    -- Always refresh colors by default
    self.refreshColors = true

    if options and options.refreshColors ~= nil then
        self.refreshColors = options.refreshColors
    end

    self:Create()
    self:Show()
end

return PaletteExtractionDialog
