local ModeFactory = dofile("./ModeFactory.lua")

-- Automatically load all modes
local extensionsDirectory = app.fs.joinPath(app.fs.userConfigPath, "extensions")
local magicPencilDirectory = app.fs
                                 .joinPath(extensionsDirectory, "magic-pencil")
local modesDirectory = app.fs.joinPath(magicPencilDirectory, "modes")

ModeFactory:Init(modesDirectory)

-- Colors
local MagicPink = Color {red = 255, green = 0, blue = 255, alpha = 128}
local MagicTeal = Color {red = 0, green = 128, blue = 128, alpha = 128}

-- Modes
local Modes = {
    Regular = "RegularMode",
    Graffiti = "GraffitiMode",
    Outline = "OutlineMode",
    OutlineLive = "OutlineLiveMode",
    Cut = "CutMode",
    Selection = "SelectionMode",
    Yeet = "YeetMode",
    Mix = "MixMode",
    MixProportional = "MixProportionalMode",
    Colorize = "ColorizeMode",
    Desaturate = "DesaturateMode",
    ShiftHsvHue = "ShiftHsvHueMode",
    ShiftHsvSaturation = "ShiftHsvSaturationMode",
    ShiftHsvValue = "ShiftHsvValueMode",
    ShiftHslHue = "ShiftHslHueMode",
    ShiftHslSaturation = "ShiftHslSaturationMode",
    ShiftHslLightness = "ShiftHslLightnessMode",
    ShiftRgbRed = "ShiftRgbRedMode",
    ShiftRgbGreen = "ShiftRgbGreenMode",
    ShiftRgbBlue = "ShiftRgbBlueMode"
}

local SpecialCursorModes = {
    Modes.Cut, Modes.Selection, Modes.Mix, Modes.MixProportional,
    Modes.Desaturate, Modes.ShiftHsvHue, Modes.ShiftHsvSaturation,
    Modes.ShiftHsvValue, Modes.ShiftHslHue, Modes.ShiftHslSaturation,
    Modes.ShiftHslLightness, Modes.ShiftRgbRed, Modes.ShiftRgbGreen,
    Modes.ShiftRgbBlue
}

local MixModes = {Modes.Mix, Modes.MixProportional}

local ShiftHsvModes = {
    Modes.ShiftHsvHue, Modes.ShiftHsvSaturation, Modes.ShiftHsvValue
}

local ShiftHslModes = {
    Modes.ShiftHslHue, Modes.ShiftHslSaturation, Modes.ShiftHslLightness
}

local ShiftRgbModes = {
    Modes.ShiftRgbRed, Modes.ShiftRgbGreen, Modes.ShiftRgbBlue
}

local ColorModels = {HSV = "HSV", HSL = "HSL", RGB = "RGB"}

local ToHsvMap = {
    [Modes.ShiftHslHue] = Modes.ShiftHsvHue,
    [Modes.ShiftHslSaturation] = Modes.ShiftHsvSaturation,
    [Modes.ShiftHslLightness] = Modes.ShiftHsvValue,

    [Modes.ShiftRgbRed] = Modes.ShiftHsvHue,
    [Modes.ShiftRgbGreen] = Modes.ShiftHsvSaturation,
    [Modes.ShiftRgbBlue] = Modes.ShiftHsvValue
}

local ToHslMap = {
    [Modes.ShiftHsvHue] = Modes.ShiftHslHue,
    [Modes.ShiftHsvSaturation] = Modes.ShiftHslSaturation,
    [Modes.ShiftHsvValue] = Modes.ShiftHslLightness,

    [Modes.ShiftRgbRed] = Modes.ShiftHslHue,
    [Modes.ShiftRgbGreen] = Modes.ShiftHslSaturation,
    [Modes.ShiftRgbBlue] = Modes.ShiftHslLightness
}

local ToRgbMap = {
    [Modes.ShiftHsvHue] = Modes.ShiftRgbRed,
    [Modes.ShiftHsvSaturation] = Modes.ShiftRgbGreen,
    [Modes.ShiftHsvValue] = Modes.ShiftRgbBlue,

    [Modes.ShiftHslHue] = Modes.ShiftRgbRed,
    [Modes.ShiftHslSaturation] = Modes.ShiftRgbGreen,
    [Modes.ShiftHslLightness] = Modes.ShiftRgbBlue
}

function If(condition, trueValue, falseValue)
    if condition then
        return trueValue
    else
        return falseValue
    end
end

function Contains(collection, expectedValue)
    for _, value in ipairs(collection) do
        if value == expectedValue then return true end
    end
end

function GetBoundsForPixels(pixels)
    if pixels and #pixels == 0 then return end

    local minX, maxX = pixels[1].x, pixels[1].x
    local minY, maxY = pixels[1].y, pixels[1].y

    for _, pixel in ipairs(pixels) do
        minX = math.min(minX, pixel.x)
        maxX = math.max(maxX, pixel.x)

        minY = math.min(minY, pixel.y)
        maxY = math.max(maxY, pixel.y)
    end

    return Rectangle(minX, minY, maxX - minX + 1, maxY - minY + 1)
end

function WasColorBlended(old, color, new)
    local oldAlpha = old.alpha / 255
    local pixelAlpha = color.alpha / 255

    local finalAlpha = old.alpha + color.alpha - (oldAlpha * pixelAlpha * 255)

    local oldRed = old.red * oldAlpha
    local oldGreen = old.green * oldAlpha
    local oldBlue = old.blue * oldAlpha

    local pixelRed = color.red * pixelAlpha
    local pixelGreen = color.green * pixelAlpha
    local pixelBlue = color.blue * pixelAlpha

    local pixelOpaqueness = ((255 - color.alpha) / 255)

    local finalRed = pixelRed + oldRed * pixelOpaqueness
    local finalGreen = pixelGreen + oldGreen * pixelOpaqueness
    local finalBlue = pixelBlue + oldBlue * pixelOpaqueness

    return math.abs(finalRed / (finalAlpha / 255) - new.red) < 1 and
               math.abs(finalGreen / (finalAlpha / 255) - new.green) < 1 and
               math.abs(finalBlue / (finalAlpha / 255) - new.blue) < 1 and
               math.abs(finalAlpha - new.alpha) < 1
end

function RectangleContains(rect, x, y)
    return x >= rect.x and x <= rect.x + rect.width - 1 and --
    y >= rect.y and y <= rect.y + rect.height - 1
end

function RectangleCenter(rect)
    if not rect then return nil end

    return Point(rect.x + math.floor(rect.width / 2),
                 rect.y + math.floor(rect.height / 2))
end

function GetButtonsPressed(pixels, previous, next)
    if #pixels == 0 then return end

    local leftPressed, rightPressed = false, false
    local old, new = nil, nil
    local pixel = pixels[1]

    local getPixel = next.image.getPixel

    if not RectangleContains(previous.bounds, pixel.x, pixel.y) then
        local newPixelValue = getPixel(next.image, pixel.x - next.position.x,
                                       pixel.y - next.position.y)

        if app.fgColor.rgbaPixel == newPixelValue then
            leftPressed = true
        elseif app.bgColor.rgbaPixel == newPixelValue then
            rightPressed = true
        end

        return leftPressed, rightPressed
    end

    old = Color(getPixel(previous.image, pixel.x - previous.position.x,
                         pixel.y - previous.position.y))
    new = Color(getPixel(next.image, pixel.x - next.position.x,
                         pixel.y - next.position.y))

    if old == nil or new == nil then return leftPressed, rightPressed end

    if WasColorBlended(old, app.fgColor, new) then
        leftPressed = true
    elseif WasColorBlended(old, app.bgColor, new) then
        rightPressed = true
    end

    return leftPressed, rightPressed
end

function CalculateChange(previous, next, canExtend)
    -- If size changed then it's a clear indicator of a change
    -- Pencil can only add which means the new image can only be bigger (not true, you COULD paint with color 0...)

    local pixels = {}
    local prevPixelValue = nil

    local getPixel = previous.image.getPixel

    -- It's faster without registering any local variables inside the loops
    if canExtend then -- Can extend, iterate over the new image
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
                    if Color(nextPixelValue).alpha > 0 then
                        table.insert(pixels, {
                            x = x + next.position.x,
                            y = y + next.position.y,
                            color = nil,
                            newColor = Color(nextPixelValue)
                        })
                    end
                elseif prevPixelValue ~= nextPixelValue then
                    table.insert(pixels, {
                        x = x + next.position.x,
                        y = y + next.position.y,
                        color = Color(prevPixelValue),
                        newColor = Color(nextPixelValue)
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
                            color = Color(prevPixelValue),
                            newColor = Color(nextPixelValue)
                        })
                    end
                end
            end
        end
    end

    local bounds = GetBoundsForPixels(pixels)
    local leftPressed, rightPressed = GetButtonsPressed(pixels, previous, next)

    return {
        pixels = pixels,
        bounds = bounds,
        center = RectangleCenter(bounds),
        leftPressed = leftPressed,
        rightPressed = rightPressed,
        sizeChanged = previous.bounds.width ~= next.bounds.width or
            previous.bounds.height ~= next.bounds.height
    }
end

local MagicPencil = {dialog = nil, colorModel = ColorModels.HSV}

function MagicPencil:Execute(options)
    local selectedMode = Modes.Regular
    local sprite = app.activeSprite

    local lastKnownNumberOfCels, lastActiveCel, lastCel

    local updateLast = function()
        if sprite then lastKnownNumberOfCels = #sprite.cels end

        lastActiveCel = app.activeCel
        lastCel = nil

        -- When creating a new layer or cel this can be triggered
        if lastActiveCel then
            lastCel = {
                image = lastActiveCel.image:clone(),
                position = lastActiveCel.position,
                bounds = lastActiveCel.bounds
            }
        end
    end

    updateLast()

    local onSpriteChange = function()
        -- If there is no active cel, do nothing
        if app.activeCel == nil then return end

        if app.activeTool.id ~= "pencil" or -- If it's the wrong tool then ignore
        selectedMode == Modes.Regular or -- If it's the regular mode then ignore
        lastKnownNumberOfCels ~= #sprite.cels or -- If last layer/frame/cel was removed then ignore
        lastActiveCel ~= app.activeCel or -- If it's just a layer/frame/cel change then ignore
        lastActiveCel == nil -- If a cel was created where previously was none or cel was copied
        then
            updateLast()
            return
        end

        local modeProcessor = self:GetModeProcessor(selectedMode)
        local change = CalculateChange(lastCel, app.activeCel,
                                       modeProcessor.canExtend)

        -- If no pixel was changed, but the size changed then revert to original
        if #change.pixels == 0 then
            if change.sizeChanged and modeProcessor.canExtend and lastCel then
                -- If instead I just replace image and positon in the active cel, Aseprite will crash if I undo when hovering mouse over dialog
                -- sprite:newCel(app.activeLayer, app.activeFrame.frameNumber,
                --               lastCel.image, lastCel.position)
                app.activeCel.image = lastCel.image
                app.activeCel.position = lastCel.position
            end
            -- Otherwise, do nothing
        elseif not change.leftPressed and not change.rightPressed then
            -- TODO: This can be checked with the new API since 1.3-rc1
            -- Not a user change - most probably an undo action, do nothing
        else
            modeProcessor:Process(selectedMode, change, sprite, lastCel,
                                  self.dialog.data)
        end

        app.refresh()
        updateLast()

        -- v This just crashes Aseprite
        -- app.undo()
    end

    local onChangeListener = sprite.events:on('change', onSpriteChange)

    local onSiteChange = app.events:on('sitechange', function()
        -- If sprite stayed the same then do nothing
        if app.activeSprite == sprite then
            updateLast()
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

            updateLast()
        end

        -- Update dialog based on new sprite's color mode
        local enabled = false
        if sprite then enabled = sprite.colorMode == ColorMode.RGB end

        for _, mode in pairs(Modes) do
            self.dialog:modify{id = mode, enabled = enabled} --
        end
    end)

    local lastFgColor = Color(app.fgColor.rgbaPixel)
    local lastBgColor = Color(app.bgColor.rgbaPixel)
    local lastInk = app.preferences.tool("pencil").ink

    function OnFgColorChange()
        if Contains(SpecialCursorModes, selectedMode) then
            if app.fgColor.rgbaPixel ~= MagicPink.rgbaPixel then
                lastFgColor = Color(app.fgColor.rgbaPixel)
                app.fgColor = MagicPink
            end
        else
            lastFgColor = Color(app.fgColor.rgbaPixel)
        end
    end

    function OnBgColorChange()
        if Contains(SpecialCursorModes, selectedMode) then
            if app.bgColor.rgbaPixel ~= MagicTeal.rgbaPixel then
                lastBgColor = Color(app.bgColor.rgbaPixel)
                app.bgColor = MagicTeal
            end
        else
            lastBgColor = Color(app.bgColor.rgbaPixel)
        end
    end

    local onFgColorListener = app.events:on('fgcolorchange', OnFgColorChange)
    local onBgColorListener = app.events:on('bgcolorchange', OnBgColorChange)

    self.dialog = Dialog {
        title = "Magic Pencil",
        onclose = function()
            if sprite then sprite.events:off(onChangeListener) end

            app.events:off(onSiteChange)
            app.events:off(onFgColorListener)
            app.events:off(onBgColorListener)

            app.fgColor = lastFgColor
            app.bgColor = lastBgColor

            local pencilPreferences = app.preferences.tool("pencil")
            pencilPreferences.ink = lastInk

            options.onclose()
        end
    }

    local Mode = function(mode, text, visible, selected)
        self.dialog:radio{
            id = mode,
            text = text,
            selected = selected,
            enabled = sprite.colorMode == ColorMode.RGB,
            visible = visible,
            onclick = function()
                selectedMode = mode

                local isSpecial = Contains(SpecialCursorModes, selectedMode)
                app.fgColor = If(isSpecial, MagicPink, lastFgColor)
                app.bgColor = If(isSpecial, MagicTeal, lastBgColor)

                local pencilPreferences = app.preferences.tool("pencil")
                pencilPreferences.ink = If(isSpecial, "simple", lastInk)

                self.dialog --
                :modify{
                    id = "outlineColor",
                    visible = selectedMode == Modes.OutlineLive
                } --
                :modify{
                    id = "graffitiPower",
                    visible = selectedMode == Modes.Graffiti
                } --
            end
        }:newrow() --
    end

    Mode(Modes.Regular, "Regular", true, true)

    Mode(Modes.Graffiti, "Graffiti", true)
    self.dialog:slider{
        id = "graffitiPower",
        visible = false,
        min = 1,
        max = 100,
        value = 50
    }

    self.dialog:separator{text = "Outline"} --
    Mode(Modes.Outline, "Tool")
    Mode(Modes.OutlineLive, "Brush")
    self.dialog:color{
        id = "outlineColor",
        visible = false,
        color = Color {gray = 0, alpha = 255}
    }

    self.dialog:separator{text = "Transform"} --
    Mode(Modes.Cut, "Lift")
    Mode(Modes.Selection, "Selection")

    -- self.dialog:separator{text = "Forbidden"} --
    Mode(Modes.Yeet, "Yeet", false)

    self.dialog:separator{text = "Mix"}
    Mode(Modes.Mix, "Unique")
    Mode(Modes.MixProportional, "Proportional")

    self.dialog:separator{text = "Change"} --
    Mode(Modes.Colorize, "Colorize")
    Mode(Modes.Desaturate, "Desaturate")

    self.dialog:separator{text = "Shift"} --
    :combobox{
        id = "colorModel",
        options = ColorModels,
        option = self.colorModel,
        onchange = function()
            self.colorModel = self.dialog.data.colorModel

            if self.colorModel == ColorModels.HSV then
                selectedMode = ToHsvMap[selectedMode]
            elseif self.colorModel == ColorModels.HSL then
                selectedMode = ToHslMap[selectedMode]
            elseif self.colorModel == ColorModels.RGB then
                selectedMode = ToRgbMap[selectedMode]
            end

            for _, hsvMode in ipairs(ShiftHsvModes) do
                self.dialog:modify{
                    id = hsvMode,
                    visible = self.colorModel == ColorModels.HSV,
                    selected = selectedMode == hsvMode
                }
            end

            for _, hslMode in ipairs(ShiftHslModes) do
                self.dialog:modify{
                    id = hslMode,
                    visible = self.colorModel == ColorModels.HSL,
                    selected = selectedMode == hslMode
                }
            end

            for _, rgbMode in ipairs(ShiftRgbModes) do
                self.dialog:modify{
                    id = rgbMode,
                    visible = self.colorModel == ColorModels.RGB,
                    selected = selectedMode == rgbMode
                }
            end
        end
    } --

    local isHsv = self.colorModel == ColorModels.HSV
    Mode(Modes.ShiftHsvHue, "Hue", isHsv)
    Mode(Modes.ShiftHsvSaturation, "Saturation", isHsv)
    Mode(Modes.ShiftHsvValue, "Value", isHsv)

    local isHsl = self.colorModel == ColorModels.HSL
    Mode(Modes.ShiftHslHue, "Hue", isHsl)
    Mode(Modes.ShiftHslSaturation, "Saturation", isHsl)
    Mode(Modes.ShiftHslLightness, "Lightness", isHsl)

    local isRgb = self.colorModel == ColorModels.RGB
    Mode(Modes.ShiftRgbRed, "Red", isRgb)
    Mode(Modes.ShiftRgbGreen, "Green", isRgb)
    Mode(Modes.ShiftRgbBlue, "Blue", isRgb)

    self.dialog --
    :slider{id = "shiftPercentage", min = 1, max = 100, value = 5} --

    self.dialog --
    :separator() --
    :check{id = "indexedMode", text = "Indexed Mode"}

    self.dialog:show{wait = false}
end

function MagicPencil:GetModeProcessor(mode)
    if Contains(ShiftHsvModes, mode) or Contains(ShiftHslModes, mode) or
        Contains(ShiftRgbModes, mode) then
        return ModeFactory:Create("ShiftMode")
    elseif Contains(MixModes, mode) then
        return ModeFactory:Create("MixMode")
    else
        return ModeFactory:Create(mode)
    end
end

return MagicPencil
