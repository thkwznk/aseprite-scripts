PreviewDirection = dofile("./PreviewDirection.lua")
PaletteExtractionDialog = dofile("./PaletteExtractionDialog.lua")
PaletteExtractor = dofile("./PaletteExtractor.lua")

local PageSize<const> = 8

function GetTransparentColor() return Color {gray = 0, alpha = 0} end
function GetEmptyShades() return {GetTransparentColor()} end

local SpriteAnalyzerDialog = {
    dialog = nil,
    isRefreshing = false,

    modified = false,

    -- Sprite Analyzer Configuration
    name = nil,
    outlineColors = nil,
    flatColors = nil,
    preview = nil
}

function SpriteAnalyzerDialog:New(options)
    options = options or {}
    setmetatable(options, self)
    self.__index = self
    return options
end

function SpriteAnalyzerDialog:HandleShadesClick(ev, originalColors, newColors)
    local colorsMoved = false

    for i = 1, #newColors do
        if originalColors[i] ~= newColors[i] then
            colorsMoved = true
            break
        end
    end

    if ev.button == MouseButton.LEFT then
        -- Dragging a color out of the picker removes it but sets no color on the event
        if colorsMoved or ev.color == nil then
            originalColors = newColors
        else
            -- If the shades only have the placeholder transparent color then remove it before adding the new one
            if #originalColors == 1 and originalColors[1].alpha == 0 then
                table.remove(originalColors, 1)
            end

            local colorOrderIndex = 1

            for i = 1, #originalColors do
                if originalColors[i] == ev.color then
                    colorOrderIndex = i
                    break
                end
            end

            local colorsToAdd = self:GetColorsToAdd()

            if colorOrderIndex > #originalColors / 2 and #originalColors > 1 then
                colorOrderIndex = colorOrderIndex + 1
            end

            for i, color in ipairs(colorsToAdd) do
                table.insert(originalColors, colorOrderIndex + i - 1, color)
            end

            -- Go through all of the colors once again, avoid the part where we added new colors and  remove duplicates?

            for _, addedColor in ipairs(colorsToAdd) do
                for i = 1, #originalColors do
                    if i < colorOrderIndex or i >= colorOrderIndex +
                        #colorsToAdd then
                        if originalColors[i].rgbaPixel == addedColor.rgbaPixel then
                            table.remove(originalColors, i)
                            break
                        end
                    end
                end
            end
        end
    end

    if ev.button == MouseButton.RIGHT then
        for i = 1, #originalColors do
            if originalColors[i] == ev.color then
                table.remove(originalColors, i)
                break
            end
        end
    end

    if #originalColors == 0 then
        -- Don't allow for an empty range of shades, otherwise it's impossible to add colors
        table.insert(originalColors, GetTransparentColor())
    end

    return originalColors
end

function SpriteAnalyzerDialog:GetColorsToAdd()
    local palette = app.activeSprite.palettes[1]
    local colorsToAdd = {}

    if #app.range.colors > 0 then
        for i, colorIndex in ipairs(app.range.colors) do
            table.insert(colorsToAdd, i, palette:getColor(colorIndex))
        end
    else
        table.insert(colorsToAdd, app.fgColor)
    end

    return colorsToAdd
end

function SpriteAnalyzerDialog:Create(options)
    self.title = options and options.title or self.title
    self.spriteBounds = options and options.spriteBounds or self.spriteBounds
    self.onclose = options and options.onclose or self.onclose
    self.onchange = options and options.onchange or self.onchange
    self.presetProvider = options and options.presetProvider or
                              self.presetProvider
    self.imageProvider = options and options.imageProvider or self.imageProvider
    self.dialogBounds = options and options.dialogBounds or self.dialogBounds

    local maxPadding = math.min(self.spriteBounds.width,
                                self.spriteBounds.height) / 2

    -- Initialize Configuration
    self.outlineColors = self.outlineColors or GetEmptyShades()
    self.flatColors = self.flatColors or {}
    self.preview = self.preview or {
        padding = maxPadding / 2,
        direction = PreviewDirection.Horizontal,
        singleLine = true
    }

    self.dialog = Dialog {
        title = self.title,
        onclose = function()
            if not self.isRefreshing then
                self.onclose(self.dialogBounds)
            end

            self.isRefreshing = false
        end
    }

    self.dialog --
    :separator{text = "Presets"} --
    :button{
        text = "New Empty",
        onclick = function() self:LoadConfiguration({}) end
    } --
    :button{
        text = "New Auto",
        onclick = function()
            self:LoadConfiguration({}, function()
                -- Close the dialog for the time
                self.isRefreshing = true
                self:Close()

                local paletteExtractor =
                    PaletteExtractor:New{imageProvider = self.imageProvider}

                local function ShowPaletteExtractionDialog()
                    local paletteExtractionDialog =
                        PaletteExtractionDialog --
                        :New{
                            paletteExtractor = paletteExtractor,
                            onchange = function(outlineColors, flatColors)
                                if outlineColors and #outlineColors > 0 then
                                    self.outlineColors = outlineColors
                                else
                                    self.outlineColors = GetEmptyShades()
                                end

                                if flatColors and #flatColors > 0 then
                                    self.flatColors = flatColors
                                else
                                    self.flatColors = {GetEmptyShades()}
                                end

                                self:OnChange()
                            end,
                            onclose = function()
                                -- Reopen the SpriteAnalyzerDialog after done with palette extraction
                                self:Create()
                                self:Show()
                            end
                        } --
                    paletteExtractionDialog:Create() --
                    paletteExtractionDialog:Show()
                end

                local function ShowOutlineExtractionDialog()
                    local outlineColors = paletteExtractor:GetOutlineColors()

                    local outlineExtractionDialog = Dialog("Outline Colors")
                    outlineExtractionDialog --
                    :label{text = "Are these the correct outline colors?"} --
                    :shades{
                        id = "outline-colors",
                        mode = "sort",
                        colors = outlineColors,
                        onclick = function(ev)
                            local newColors =
                                self:HandleShadesClick(ev, outlineColors,
                                                       outlineExtractionDialog.data["outline-colors"])
                            outlineExtractionDialog:modify{
                                id = "outline-colors",
                                colors = newColors
                            }
                            outlineColors = newColors

                            self:OnChange()
                        end
                    } --
                    :button{
                        text = "Confirm",
                        onclick = function()
                            paletteExtractor:SetOutlineColors(
                                outlineExtractionDialog.data["outline-colors"])
                            ShowPaletteExtractionDialog()
                            outlineExtractionDialog:close()
                        end
                    } --
                    :button{
                        text = "Cancel",
                        onclick = function()
                            paletteExtractor:SetOutlineColors({})
                            ShowPaletteExtractionDialog()
                            outlineExtractionDialog:close()
                        end
                    } --
                    :show{wait = false}
                end

                local outlineConfirmationDialog = Dialog("Outline?") --
                outlineConfirmationDialog:label{
                    text = "Does your sprite have an outline?"
                } --
                :button{
                    text = "Yes",
                    onclick = function()
                        outlineConfirmationDialog:close()
                        ShowOutlineExtractionDialog()
                    end
                } --
                :button{
                    text = "No",
                    onclick = function()
                        -- Handle close the same way
                        paletteExtractor:SetOutlineColors({})
                        outlineConfirmationDialog:close()
                        ShowPaletteExtractionDialog()
                    end
                } --
                :show()
            end)
        end
    } --
    :newrow() --
    :button{
        text = "Save",
        onclick = function()
            local savePresetDialog = Dialog("Save Preset")
            savePresetDialog --
            :entry{
                id = "preset-name",
                text = self.name,
                onchange = function()
                    savePresetDialog:modify{
                        id = "save-preset-button",
                        enabled = #savePresetDialog.data["preset-name"] > 0
                    }
                end
            } --
            :button{
                id = "save-preset-button",
                text = "Save",
                enabled = self.name and #self.name > 0 or false,
                onclick = function()
                    self.name = savePresetDialog.data["preset-name"]
                    self.presetProvider:SavePreset(self:GetConfiguration())
                    self.modified = false

                    savePresetDialog:close()
                end
            } --
            :button{text = "Cancel"}

            savePresetDialog:show{wait = true}
        end
    } --
    :button{
        text = "Load",
        onclick = function()
            local presetNames = self.presetProvider:GetPresetNames()

            local loadPresetDialog = Dialog("Load Preset")
            loadPresetDialog --
            :combobox{id = "preset", label = "Presets:", options = presetNames} --
            :button{
                id = "load-button",
                text = "Load",
                enabled = #presetNames > 0,
                onclick = function()
                    local name = loadPresetDialog.data["preset"]
                    local presetConfiguration =
                        self.presetProvider:GetPresetByName(name)

                    if presetConfiguration ~= nil then
                        self:LoadConfiguration(presetConfiguration)
                        loadPresetDialog:close()
                    end
                end
            } --
            :button{
                id = "delete-button",
                text = "Delete",
                enabled = #presetNames > 0,
                onclick = function()
                    local name = loadPresetDialog.data["preset"]
                    self.presetProvider:DeleteProvider(name)

                    presetNames = self.presetProvider:GetPresetNames()

                    loadPresetDialog --
                    :modify{id = "preset", options = presetNames} --
                    :modify{id = "load-button", enabled = #presetNames > 0} --
                    :modify{id = "delete-button", enabled = #presetNames > 0} --
                end
            } --
            :button{text = "Cancel"}

            loadPresetDialog:show{wait = true}
        end
    }

    self.dialog --
    :separator{text = "Outline Colors"} --
    :shades{
        id = "outline",
        mode = "sort",
        colors = self.outlineColors,
        onclick = function(ev)
            local newColors = self:HandleShadesClick(ev, self.outlineColors,
                                                     self.dialog.data["outline"])
            self.dialog:modify{id = "outline", colors = newColors}
            self.outlineColors = newColors

            self:OnChange()
        end
    } --
    :separator{text = "Flatten Colors"} --

    -- Add one for an empty entry
    local numberOfColors = #self.flatColors + 1
    local numberOfPages = math.max(math.ceil(numberOfColors / PageSize), 1)
    self.currentPage = math.min(self.currentPage or 1, numberOfPages)

    if numberOfPages > 1 then
        self.dialog --
        :button{
            text = "<",
            enabled = numberOfPages > 1 and self.currentPage > 1,
            onclick = function()
                self.currentPage = self.currentPage - 1
                self:Refresh()
            end
        } --
        :button{
            text = ">",
            enabled = numberOfPages > 1 and self.currentPage < numberOfPages,
            onclick = function()
                self.currentPage = self.currentPage + 1
                self:Refresh()
            end
        }
    end

    local skip = (self.currentPage - 1) * PageSize
    local colorsOnPage = math.min(PageSize, numberOfColors - skip)

    for index = skip + 1, skip + colorsOnPage do
        local flatColorEntry = self.flatColors[index] or GetEmptyShades()
        local id = "flatColors-" .. index

        self.dialog:shades{
            id = id,
            mode = "sort",
            colors = flatColorEntry,
            onclick = function(ev)
                local newColors = self:HandleShadesClick(ev, flatColorEntry,
                                                         self.dialog.data[id])

                -- If after update there are no colors left than delete this group
                if #newColors == 1 and newColors[1].alpha == 0 then
                    table.remove(self.flatColors, index)
                else
                    self.dialog:modify{id = id, colors = newColors}
                    self.flatColors[index] = newColors

                    -- Add one for an empty entry
                    local newNumberOfColors = #self.flatColors + 1
                    local newNumberOfPages = math.max(math.ceil(
                                                          newNumberOfColors /
                                                              PageSize), 1)

                    if newNumberOfPages > numberOfPages then
                        self.currentPage = self.currentPage + 1
                    end
                end

                self:OnChange()
                self:Refresh()
            end
        } --
        :newrow()
    end

    self.dialog --
    :separator() --
    :button{
        text = "Preview Options",
        onclick = function()
            local previewOptionsDialog = Dialog("Preview Options")
            previewOptionsDialog --
            :slider{
                id = "preview-padding",
                label = "Padding",
                min = 0,
                max = maxPadding,
                value = self.preview.padding,
                onrelease = function()
                    self.preview.padding =
                        previewOptionsDialog.data["preview-padding"]
                    self:OnChange()
                end
            } --
            :combobox{
                id = "preview-direction",
                label = "Direction",
                options = PreviewDirection,
                option = self.preview.direction,
                onchange = function()
                    self.preview.direction =
                        previewOptionsDialog.data["preview-direction"]
                    self:OnChange()

                    previewOptionsDialog:close()
                    previewOptionsDialog:show{wait = false}
                end
            } --
            :check{
                id = "preview-single-line",
                label = "Single Line",
                selected = self.preview.singleLine,
                onclick = function()
                    self.preview.singleLine =
                        previewOptionsDialog.data["preview-single-line"]
                    self:OnChange()
                end
            } --
            :separator() --
            :button{text = "Close"} --
            :show{wait = false}
        end
    } --
    :separator() --
    :button{text = "Cancel"}

    -- Restore bounds
    if self.dialogBounds ~= nil then
        local newBounds = self.dialog.bounds
        newBounds.x = self.dialogBounds.x
        newBounds.y = self.dialogBounds.y
        self.dialog.bounds = newBounds
    end
end

function SpriteAnalyzerDialog:Show() self.dialog:show{wait = false} end

function SpriteAnalyzerDialog:Close()
    self.dialogBounds = self.dialog and self.dialog.bounds or self.dialogBounds
    self.dialog:close()
end

function SpriteAnalyzerDialog:Refresh()
    self.isRefreshing = true
    self:Close()
    self:Create()
    self:Show()
end

function SpriteAnalyzerDialog:OnChange(modified)
    -- Save dialog bounds
    self.dialogBounds = self.dialog and self.dialog.bounds or self.dialogBounds

    if modified ~= nil then
        self.modified = modified
    else
        self.modified = true
    end

    -- Trigger change event
    self.onchange()
end

function SpriteAnalyzerDialog:GetConfiguration()
    return {
        name = self.name,
        outlineColors = self.outlineColors,
        flatColors = self.flatColors,
        preview = self.preview
    }
end

function SpriteAnalyzerDialog:LoadConfiguration(configuration, onload)
    if self.modified then
        local confirmationDialog = Dialog("Unsaved Changes")

        confirmationDialog --
        :label{text = "Unsaved changes will be lost, do you want to continue?"} --
        :button{
            text = "Yes",
            onclick = function()
                -- Reset the state to not modified
                self.modified = false

                confirmationDialog:close()
                self:LoadConfiguration(configuration, onload)
            end
        } --
        :button{text = "No"} --
        :show{wait = true}
    else
        self.name = configuration.name
        self.outlineColors = configuration.outlineColors
        self.flatColors = configuration.flatColors
        self.preview = configuration.preview

        self:OnChange(false)
        self:Refresh()

        if onload then onload() end
    end
end

return SpriteAnalyzerDialog
