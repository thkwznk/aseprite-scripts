local ModeProcessorProvider = dofile("./ModeProcessorProvider.lua")
local GetBoundsForPixels = dofile("./GetBoundsForPixels.lua")
local Mode = dofile("./Mode.lua")
local Tool = dofile("./Tool.lua")
local ColorContext = dofile("./ColorContext.lua")

-- Colors
local MagicPink = Color {red = 255, green = 0, blue = 255, alpha = 128}
local MagicTeal = Color {red = 0, green = 128, blue = 128, alpha = 128}

local ColorModels = {HSV = "HSV", HSL = "HSL", RGB = "RGB"}

local function RectangleContains(rect, x, y)
    return x >= rect.x and x <= rect.x + rect.width - 1 and --
    y >= rect.y and y <= rect.y + rect.height - 1
end

local function GetButtonsPressedFromEmpty(pixels)
    if #pixels == 0 then return end

    local pixel = pixels[1]

    if ColorContext:Compare(app.fgColor, pixel.newColor) then
        return true, false
    elseif ColorContext:Compare(app.bgColor, pixel.newColor) then
        return false, true
    end

    return false, false
end

local function GetButtonsPressed(pixels)
    if #pixels == 0 then return false, false end

    local leftPressed, rightPressed = false, false
    local pixel = pixels[1]

    if ColorContext:IsTransparent(app.fgColor) and
        not ColorContext:IsTransparent(pixel.newColor) then
        return false, true
    elseif ColorContext:IsTransparent(app.bgColor) and
        not ColorContext:IsTransparent(pixel.newColor) then
        return true, false
    end

    local fgColorDistance = ColorContext:Distance(pixel.newColor, app.fgColor) -
                                ColorContext:Distance(pixel.color, app.fgColor)
    local bgColorDistance = ColorContext:Distance(pixel.newColor, app.bgColor) -
                                ColorContext:Distance(pixel.color, app.bgColor)

    if fgColorDistance < bgColorDistance then
        leftPressed = true
    else
        rightPressed = true
    end

    return leftPressed, rightPressed
end

local function CalculateChangeFromEmpty(cel)
    local pixels = {}
    local pixelValue

    local getPixel = cel.image.getPixel

    for x = 0, cel.image.width - 1 do
        for y = 0, cel.image.height - 1 do
            pixelValue = getPixel(cel.image, x, y)

            if pixelValue > 0 then
                table.insert(pixels, {
                    x = x + cel.position.x,
                    y = y + cel.position.y,
                    color = ColorContext:Create(0),
                    newColor = ColorContext:Create(pixelValue)
                })
            end
        end
    end

    local leftPressed, rightPressed = GetButtonsPressedFromEmpty(pixels)

    return {
        pixels = pixels,
        bounds = cel.bounds,
        leftPressed = leftPressed,
        rightPressed = rightPressed,
        sizeChanged = false
    }
end

local function CalculateChange(previous, next, canExtend)
    -- If size changed then it's a clear indicator of a change
    -- Pencil can only add which means the new image can only be bigger (not true, you COULD paint with color 0...)

    local pixels = {}
    local prevPixelValue = nil

    local getPixel = previous.image.getPixel

    local previousArea = previous.bounds.width * previous.bounds.height
    local nextArea = next.bounds.width * next.bounds.height

    -- if nextArea < previousArea then
    --     CalculateChangeWhenNextSmaller(previous, next, canExtend)
    -- end

    -- It's faster without registering any local variables inside the loops
    if nextArea > previousArea and canExtend then -- Can extend, iterate over the new image
        local shift = {
            x = next.position.x - previous.position.x,
            y = next.position.y - previous.position.y
        }
        local shiftedX, shiftedY, nextPixelValue

        for x = 0, next.image.width - 1 do
            for y = 0, next.image.height - 1 do
                -- Save X and Y as canvas global
                shiftedX = x + shift.x
                shiftedY = y + shift.y

                prevPixelValue = getPixel(previous.image, shiftedX, shiftedY)
                nextPixelValue = getPixel(next.image, x, y)

                -- Out of bounds of the previous image or transparent
                if (shiftedX < 0 or shiftedX > previous.image.width - 1 or
                    shiftedY < 0 or shiftedY > previous.image.height - 1) then
                    if not ColorContext:IsTransparentValue(nextPixelValue) then
                        table.insert(pixels, {
                            x = x + next.position.x,
                            y = y + next.position.y,
                            color = ColorContext:Create(0),
                            newColor = ColorContext:Create(nextPixelValue)
                        })
                    end
                elseif prevPixelValue ~= nextPixelValue then
                    table.insert(pixels, {
                        x = x + next.position.x,
                        y = y + next.position.y,
                        color = ColorContext:Create(prevPixelValue),
                        newColor = ColorContext:Create(nextPixelValue)
                    })
                end
            end
        end
    else -- Cannot extend, iterate over the previous image
        local shift = {
            x = previous.position.x - next.position.x,
            y = previous.position.y - next.position.y
        }

        for x = 0, previous.image.width - 1 do
            for y = 0, previous.image.height - 1 do
                prevPixelValue = getPixel(previous.image, x, y)

                -- Next image in some rare cases can be smaller
                if RectangleContains(next.bounds, x + previous.position.x,
                                     y + previous.position.y) then
                    -- Saving the new pixel's colors would be necessary for working with brushes, I think
                    local nextPixelValue =
                        getPixel(next.image, x + shift.x, y + shift.y)

                    if prevPixelValue ~= nextPixelValue then
                        -- Save X and Y as canvas global
                        table.insert(pixels, {
                            x = x + previous.position.x,
                            y = y + previous.position.y,
                            color = ColorContext:Create(prevPixelValue),
                            newColor = ColorContext:Create(nextPixelValue)
                        })
                    end
                elseif not ColorContext:IsTransparentValue(prevPixelValue) then
                    table.insert(pixels, {
                        x = x + previous.position.x,
                        y = y + previous.position.y,
                        color = ColorContext:Create(prevPixelValue),
                        newColor = ColorContext:Create(0)
                    })
                end
            end
        end
    end

    local bounds = GetBoundsForPixels(pixels)
    local leftPressed, rightPressed = GetButtonsPressed(pixels)

    return {
        pixels = pixels,
        bounds = bounds,
        leftPressed = leftPressed,
        rightPressed = rightPressed,
        sizeChanged = previous.bounds.width ~= next.bounds.width or
            previous.bounds.height ~= next.bounds.height
    }
end

local function MagicPencilDialog(options)
    local dialog
    local isRefresh = false
    local colorModel = ColorModels.HSV
    local selectedMode = Mode.Regular
    local sprite = app.activeSprite
    local lastCel
    local lastFgColor = ColorContext:Copy(app.fgColor)
    local lastBgColor = ColorContext:Copy(app.bgColor)
    local isMinimized = options.isminimized

    local function RefreshDialog()
        -- Update dialog based only sprite's color mode
        local isRGB = sprite and sprite.colorMode == ColorMode.RGB
        local isIndexed = sprite and sprite.colorMode == ColorMode.INDEXED

        local isChange = selectedMode == Mode.Colorize or selectedMode ==
                             Mode.Desaturate or selectedMode == Mode.Shift

        dialog --
        :modify{id = "selectedMode", visible = isMinimized} --
        :modify{id = Mode.Regular, visible = not isMinimized} --
        :modify{id = "effectSeparator", visible = not isMinimized} --
        :modify{id = Mode.Graffiti, visible = not isMinimized} --
        :modify{id = Mode.OutlineLive, visible = not isMinimized} --
        :modify{id = "transformSeparator", visible = isRGB and not isMinimized} --
        :modify{id = Mode.Cut, visible = isRGB and not isMinimized} --
        :modify{id = Mode.Merge, visible = isRGB and not isMinimized} --
        :modify{id = Mode.Selection, visible = isRGB and not isMinimized} --
        :modify{id = "mixSeparator", visible = isRGB and not isMinimized} --
        :modify{id = Mode.Desaturate, visible = isRGB and not isMinimized} --
        :modify{id = Mode.Mix, visible = isRGB and not isMinimized} --
        :modify{id = Mode.MixProportional, visible = isRGB and not isMinimized} --
        :modify{
            id = "changeSeparator",
            visible = (isRGB or isIndexed) and not isMinimized
        } --
        :modify{id = Mode.Outline, visible = isRGB and not isMinimized} --
        :modify{id = Mode.Shift, visible = isRGB and not isMinimized} --
        :modify{
            id = Mode.Colorize,
            visible = (isRGB or isIndexed) and not isMinimized
        } --
        :modify{id = "indexedModeSeparator", visible = isRGB and isChange} --
        :modify{
            id = "indexedMode",
            visible = isRGB and isChange,
            enabled = isRGB
        }

        isRefresh = true
        dialog:show{wait = false}
        dialog:close()
        local newBounds = Rectangle(dialog.bounds)
        newBounds.width = (isMinimized and 125 or 88) *
                              app.preferences.general["ui_scale"]

        dialog:show{wait = false, bounds = newBounds}
    end

    local function UpdateLast()
        if app.activeCel then
            lastCel = {
                image = app.activeCel.image:clone(),
                position = app.activeCel.position,
                bounds = app.activeCel.bounds,
                sprite = sprite
            }
        else
            lastCel = {
                image = Image(0, 0),
                position = Point(0, 0),
                bounds = Rectangle(0, 0, 0, 0),
                sprite = sprite,
                empty = true
            }
        end
    end

    UpdateLast()

    local skip = false

    local onBeforeCommand = function(ev) skip = true end

    local onAfterCommand = function(ev)
        skip = false
        UpdateLast()

        if ev.name == "ChangePixelFormat" then RefreshDialog() end
    end

    local onSpriteChange = function(ev)
        if skip or -- Skip change, usually when a command is being run
        app.activeCel == nil -- If there is no active cel, do nothing
        then
            UpdateLast()
            return
        end

        local modeProcessor = ModeProcessorProvider:Get(selectedMode)

        if not Tool:IsSupported(app.tool.id, modeProcessor) or -- Only react to supported tools
        selectedMode == Mode.Regular or -- If it's the regular mode then ignore
        sprite.colorMode == ColorMode.TILEMAP or -- Tilemap Mode is not supported
        app.activeLayer.isTilemap or -- If a layer is a tilemap
        (app.apiVersion >= 21 and ev.fromUndo) -- From API v21, ignore all changes from undo/redo
        then
            UpdateLast()
            return
        end

        local change =
            lastCel.empty and CalculateChangeFromEmpty(app.activeCel) or
                CalculateChange(lastCel, app.activeCel, modeProcessor.canExtend)

        -- Mode Processor can change the active cel, save it here for deletion just in case  
        local celToDelete = app.activeCel

        -- If no pixel was changed, but the size changed then revert to original
        if #change.pixels == 0 or lastCel.empty and modeProcessor.ignoreEmptyCel then
            -- Ignore, do nothing
        elseif change.leftPressed or change.rightPressed then
            -- Only respond if it's known which button the user pressed
            modeProcessor:Process(change, sprite, lastCel, dialog.data)
        end

        if lastCel.empty and modeProcessor.deleteOnEmptyCel then
            app.activeSprite:deleteCel(celToDelete)
        end

        app.refresh()
        UpdateLast()

        -- v This just crashes Aseprite
        -- app.undo()
    end

    local onBeforeCommandListener = app.events:on('beforecommand',
                                                  onBeforeCommand)
    local onAfterCommandListener = app.events:on('aftercommand', onAfterCommand)
    local onChangeListener = sprite.events:on('change', onSpriteChange)
    local onSiteChange = app.events:on('sitechange', function()
        -- If sprite stayed the same then do nothing
        if app.activeSprite == sprite then
            UpdateLast()
            return
        end

        -- Unsubscribe from changes on the previous sprite
        if sprite then
            sprite.events:off(onChangeListener)
            sprite = nil
        end

        -- Subscribe to change on the new sprite
        if app.activeSprite then
            sprite = app.activeSprite
            onChangeListener = sprite.events:on('change', onSpriteChange)

            UpdateLast()
        end

        -- Update dialog based on new sprite's color mode
        RefreshDialog()
    end)

    local function ToggleMinimize()
        isMinimized = not isMinimized

        RefreshDialog()
    end

    local function SelectMode(mode, skipColor)
        selectedMode = mode

        dialog --
        :modify{id = "selectedMode", option = selectedMode} --
        :modify{id = selectedMode, selected = true}

        local useMaskColor =
            ModeProcessorProvider:Get(selectedMode).useMaskColor

        if not skipColor then
            if useMaskColor then
                app.fgColor = MagicPink
                app.bgColor = MagicTeal
            else
                app.fgColor = lastFgColor
                app.bgColor = lastBgColor
            end
        end

        local isChange = selectedMode == Mode.Colorize or selectedMode ==
                             Mode.Desaturate or selectedMode == Mode.Shift

        dialog --
        :modify{id = "outlineColor", visible = selectedMode == Mode.OutlineLive} --
        :modify{id = "outlineSize", visible = selectedMode == Mode.OutlineLive} -- 
        :modify{
            id = "outlineOtherColors",
            visible = selectedMode == Mode.OutlineLive
        } --
        :modify{
            id = "outlineErasingEnable",
            visible = selectedMode == Mode.OutlineLive
        } --
        :modify{id = "graffitiPower", visible = selectedMode == Mode.Graffiti} --
        :modify{
            id = "graffitiSpeckEnabled",
            visible = selectedMode == Mode.Graffiti
        } --
        :modify{
            id = "graffitiSpeckPower",
            visible = selectedMode == Mode.Graffiti and
                dialog.data.graffitiSpeckEnabled
        } --
        :modify{id = "colorModel", visible = selectedMode == Mode.Shift} --
        :modify{id = "shiftFirstOption", visible = selectedMode == Mode.Shift} --
        :modify{
            id = "shiftFirstPercentage",
            visible = selectedMode == Mode.Shift and
                dialog.data.shiftFirstOption
        } --
        :modify{id = "shiftSecondOption", visible = selectedMode == Mode.Shift} --
        :modify{
            id = "shiftSecondPercentage",
            visible = selectedMode == Mode.Shift and
                dialog.data.shiftSecondOption
        } --
        :modify{id = "shiftThirdOption", visible = selectedMode == Mode.Shift} --
        :modify{
            id = "shiftThirdPercentage",
            visible = selectedMode == Mode.Shift and
                dialog.data.shiftThirdOption
        } --
        :modify{id = "indexedModeSeparator", visible = isChange} --
        :modify{id = "indexedMode", visible = isChange} --
    end

    local resetColors = false
    local resetColorsTimer = Timer {
        interval = 1 / 6, -- fps
        ontick = function()
            -- This is the only reliable way
            -- There's no option to change colors within a color change event without causing issue 
            if resetColors then
                app.fgColor = lastFgColor
                app.bgColor = lastBgColor
                resetColors = false
            end
        end
    }

    local onFgColorChange = function()
        local modeProcessor = ModeProcessorProvider:Get(selectedMode)
        local isMagicColor = app.fgColor.rgbaPixel == MagicPink.rgbaPixel

        if not isMagicColor then
            if modeProcessor.useMaskColor then
                -- Skip setting colors here to avoid issue with changing colors from within an event
                SelectMode(Mode.Regular, true)

                resetColors = true
            end

            lastFgColor = ColorContext:Copy(app.fgColor)
        end
    end

    local onBgColorChange = function()
        local modeProcessor = ModeProcessorProvider:Get(selectedMode)
        local isMagicColor = app.bgColor.rgbaPixel == MagicTeal.rgbaPixel

        if not isMagicColor then
            if modeProcessor.useMaskColor then
                -- Skip setting colors here to avoid issue with changing colors from within an event
                SelectMode(Mode.Regular, true)

                resetColors = true
            end

            lastBgColor = ColorContext:Copy(app.bgColor)
        end
    end

    local onFgColorListener = app.events:on('fgcolorchange', onFgColorChange)
    local onBgColorListener = app.events:on('bgcolorchange', onBgColorChange)

    dialog = Dialog {
        title = "Magic Pencil",
        onclose = function()
            if isRefresh then
                isRefresh = false
                return
            end

            if sprite then sprite.events:off(onChangeListener) end

            app.events:off(onSiteChange)
            app.events:off(onFgColorListener)
            app.events:off(onBgColorListener)

            app.fgColor = lastFgColor
            app.bgColor = lastBgColor

            app.events:off(onBeforeCommandListener)
            app.events:off(onAfterCommandListener)

            resetColorsTimer:stop()

            options.onclose(isMinimized)
        end
    }

    local function AddMode(mode, text, selected)
        dialog --
        :radio{
            id = mode,
            text = text,
            selected = selected,
            visible = not isMinimized,
            onclick = function() SelectMode(mode) end
        }:newrow()
    end

    dialog:combobox{
        id = "selectedMode",
        option = Mode.Regular,
        options = {
            Mode.Regular, Mode.Graffiti, Mode.OutlineLive, Mode.Cut, Mode.Merge,
            Mode.Selection, Mode.Mix, Mode.MixProportional, Mode.Outline,
            Mode.Colorize, Mode.Desaturate, Mode.Shift
        },
        visible = isMinimized,
        onchange = function() SelectMode(dialog.data.selectedMode) end
    }

    AddMode(Mode.Regular, "Disable", true)

    dialog:separator{
        id = "effectSeparator",
        text = "Effect",
        visible = not isMinimized
    }

    AddMode(Mode.Graffiti, "Graffiti")
    dialog --
    :slider{
        id = "graffitiPower",
        visible = false,
        min = 0,
        max = 100,
        value = 50
    } --
    :check{
        id = "graffitiSpeckEnabled",
        visible = false,
        selected = true,
        text = "Speck",
        onclick = function()
            dialog:modify{
                id = "graffitiSpeckPower",
                visible = dialog.data.graffitiSpeckEnabled
            }
        end
    } --
    :slider{
        id = "graffitiSpeckPower",
        visible = false,
        min = 0,
        max = 100,
        value = 20
    }
    AddMode(Mode.OutlineLive, "Outline")
    dialog --
    :color{
        id = "outlineColor",
        visible = false,
        color = Color {gray = 0, alpha = 255}
    } --
    :number{id = "outlineSize", visible = false, text = "1", decimals = 0} --
    :check{
        id = "outlineOtherColors",
        text = "Over color",
        visible = false,
        selected = false
    } --
    :newrow() --
    :check{
        id = "outlineErasingEnable",
        text = "Erasing",
        visible = false,
        selected = true
    } --

    dialog:separator{
        id = "transformSeparator",
        text = "Transform",
        visible = not isMinimized
    }
    AddMode(Mode.Cut, "Lift")
    AddMode(Mode.Merge, "Merge")
    AddMode(Mode.Selection, "Selection")

    dialog:separator{
        id = "mixSeparator",
        text = "Mix",
        visible = not isMinimized
    }
    AddMode(Mode.Mix, "Unique")
    AddMode(Mode.MixProportional, "Proportional")

    dialog:separator{
        id = "changeSeparator",
        text = "Change",
        visible = not isMinimized
    }
    AddMode(Mode.Outline, "Outline")
    AddMode(Mode.Colorize, "Colorize")
    AddMode(Mode.Desaturate, "Desaturate")
    AddMode(Mode.Shift, "Shift")

    local onShiftOptionClick = function()
        dialog --
        :modify{
            id = "shiftFirstPercentage",
            visible = selectedMode == Mode.Shift and
                dialog.data.shiftFirstOption
        } --
        :modify{
            id = "shiftSecondPercentage",
            visible = selectedMode == Mode.Shift and
                dialog.data.shiftSecondOption
        } --
        :modify{
            id = "shiftThirdPercentage",
            visible = selectedMode == Mode.Shift and
                dialog.data.shiftThirdOption
        } --
    end

    dialog --
    :combobox{
        id = "colorModel",
        options = ColorModels,
        option = colorModel,
        visible = false,
        onchange = function()
            colorModel = dialog.data.colorModel

            local firstOption = "Red"
            local secondOption = "Green"
            local thirdOption = "Blue"

            if colorModel == ColorModels.HSV then
                firstOption = "Hue"
                secondOption = "Saturation"
                thirdOption = "Value"
            elseif colorModel == ColorModels.HSL then
                firstOption = "Hue"
                secondOption = "Saturation"
                thirdOption = "Lightness"
            end

            dialog --
            :modify{id = "shiftFirstOption", text = firstOption} --
            :modify{id = "shiftSecondOption", text = secondOption} --
            :modify{id = "shiftThirdOption", text = thirdOption}
        end
    } --
    :check{
        id = "shiftFirstOption",
        text = "Hue",
        selected = true,
        visible = false,
        onclick = onShiftOptionClick
    } --
    :slider{
        id = "shiftFirstPercentage",
        min = 1,
        max = 100,
        value = 5,
        visible = false
    } --
    :check{
        id = "shiftSecondOption",
        text = "Saturation",
        selected = false,
        visible = false,
        onclick = onShiftOptionClick
    } --
    :slider{
        id = "shiftSecondPercentage",
        min = 1,
        max = 100,
        value = 5,
        visible = false
    } --
    :check{
        id = "shiftThirdOption",
        text = "Value",
        selected = false,
        visible = false,
        onclick = onShiftOptionClick
    } --
    :slider{
        id = "shiftThirdPercentage",
        min = 1,
        max = 100,
        value = 5,
        visible = false
    } --
    :separator{id = "indexedModeSeparator"} --
    :check{id = "indexedMode", text = "Indexed Mode"} --
    :separator() --
    :check{
        id = "minimize-check",
        text = "Minimize",
        selected = isMinimized,
        onclick = ToggleMinimize
    }

    RefreshDialog()

    resetColorsTimer:start()

    return dialog
end

return MagicPencilDialog

-- TODO: Last cel data might include a cache of pixels to speed up processing
