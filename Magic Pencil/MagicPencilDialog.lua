local ModeFactory = dofile("./ModeFactory.lua")
local GetBoundsForPixels = dofile("./GetBoundsForPixels.lua")
local Mode = dofile("./Mode.lua")

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
local ShiftHsvModes = {
    Mode.ShiftHsvHue, Mode.ShiftHsvSaturation, Mode.ShiftHsvValue
}
local ShiftHslModes = {
    Mode.ShiftHslHue, Mode.ShiftHslSaturation, Mode.ShiftHslLightness
}
local ShiftRgbModes = {Mode.ShiftRgbRed, Mode.ShiftRgbGreen, Mode.ShiftRgbBlue}

local ColorModels = {HSV = "HSV", HSL = "HSL", RGB = "RGB"}

local function WasColorBlended(old, color, new)
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

local function RectangleContains(rect, x, y)
    return x >= rect.x and x <= rect.x + rect.width - 1 and --
    y >= rect.y and y <= rect.y + rect.height - 1
end

local function RectangleCenter(rect)
    if not rect then return nil end

    return Point(rect.x + math.floor(rect.width / 2),
                 rect.y + math.floor(rect.height / 2))
end

local function GetButtonsPressed(pixels, previous, next)
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

local function CalculateChange(previous, next, canExtend)
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

local function MagicPencilDialog(options)
    local dialog
    local colorModel = ColorModels.HSV
    local selectedMode = Mode.Regular
    local sprite = app.activeSprite

    local lastKnownNumberOfCels, lastActiveCel, lastActiveLayer,
          lastActiveFrame, newCelFromEmpty, lastCelData

    local updateLast = function()
        if sprite then lastKnownNumberOfCels = #sprite.cels end

        newCelFromEmpty = (lastActiveCel == nil) and
                              (lastActiveLayer == app.activeLayer) and
                              (lastActiveFrame == app.activeFrame)

        lastActiveLayer = app.activeLayer
        lastActiveFrame = app.activeFrame
        lastActiveCel = app.activeCel
        lastCelData = nil

        -- When creating a new layer or cel this can be triggered
        if lastActiveCel then
            lastCelData = {
                image = lastActiveCel.image:clone(),
                position = lastActiveCel.position,
                bounds = lastActiveCel.bounds
            }
        end
    end

    updateLast()

    local onSpriteChange = function(ev)
        -- If there is no active cel, do nothing
        if app.activeCel == nil then return end

        -- TODO: In order to make all tools work I need to readjust the detection of Magic Colors - spray will overlay them and break it right now

        if app.activeTool.id ~= "pencil" or -- If it's the wrong tool then ignore
        selectedMode == Mode.Regular or -- If it's the regular mode then ignore
        lastKnownNumberOfCels ~= #sprite.cels or -- If last layer/frame/cel was removed then ignore
        lastActiveCel ~= app.activeCel or -- If it's just a layer/frame/cel change then ignore
        lastActiveCel == nil or -- If a cel was created where previously was none or cel was copied
        (app.apiVersion >= 21 and ev.fromUndo) -- From API v21, ignore all changes from undo/redo
        then
            updateLast()
            return
        end

        local modeProcessor = ModeFactory:Create(selectedMode)
        local celData = newCelFromEmpty and
                            {
                image = Image(0, 0),
                position = Point(0, 0),
                bounds = Rectangle(0, 0, 0, 0)
            } or lastCelData

        local change = CalculateChange(celData, app.activeCel,
                                       modeProcessor.canExtend)

        -- Mode Processor can cause the data about the last cel update, we calcualate it here to mitigate issues  
        local deleteCel = newCelFromEmpty and modeProcessor.deleteOnEmptyCel

        -- If no pixel was changed, but the size changed then revert to original
        if #change.pixels == 0 then
            if change.sizeChanged and modeProcessor.canExtend and lastCelData then
                -- If instead I just replace image and positon in the active cel, Aseprite will crash if I undo when hovering mouse over dialog
                -- sprite:newCel(app.activeLayer, app.activeFrame.frameNumber,
                --               lastCel.image, lastCel.position)
                app.activeCel.image = lastCelData.image
                app.activeCel.position = lastCelData.position
            end
            -- Otherwise, do nothing
        elseif not change.leftPressed and not change.rightPressed then
            -- TODO: This can be checked with the new API since 1.3-rc1
            -- Not a user change - most probably an undo action, do nothing
        else
            modeProcessor:Process(change, sprite, celData, dialog.data)
        end

        if deleteCel then app.activeSprite:deleteCel(app.activeCel) end

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

        for _, mode in pairs(Mode) do
            dialog:modify{id = mode, enabled = enabled} --
        end
    end)

    local lastFgColor = Color(app.fgColor.rgbaPixel)
    local lastBgColor = Color(app.bgColor.rgbaPixel)
    local lastInk = app.preferences.tool("pencil").ink

    function OnFgColorChange()
        local modeProcessor = ModeFactory:Create(selectedMode)

        if modeProcessor.useMaskColor then
            if app.fgColor.rgbaPixel ~= MagicPink.rgbaPixel then
                lastFgColor = Color(app.fgColor.rgbaPixel)
                app.fgColor = MagicPink
            end
        else
            lastFgColor = Color(app.fgColor.rgbaPixel)
        end
    end

    function OnBgColorChange()
        local modeProcessor = ModeFactory:Create(selectedMode)

        if modeProcessor.useMaskColor then
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

    dialog = Dialog {
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

    local AddMode = function(mode, text, visible, selected)
        dialog:radio{
            id = mode,
            text = text,
            selected = selected,
            enabled = sprite.colorMode == ColorMode.RGB,
            visible = visible,
            onclick = function()
                selectedMode = mode

                local useMaskColor =
                    ModeFactory:Create(selectedMode).useMaskColor
                local pencilPreferences = app.preferences.tool("pencil")

                if useMaskColor then
                    app.fgColor = MagicPink
                    app.bgColor = MagicTeal
                    pencilPreferences.ink = "simple"
                else
                    app.fgColor = lastFgColor
                    app.bgColor = lastBgColor
                    pencilPreferences.ink = lastInk
                end

                dialog --
                :modify{
                    id = "outlineColor",
                    visible = selectedMode == Mode.OutlineLive
                } --
                :modify{
                    id = "graffitiPower",
                    visible = selectedMode == Mode.Graffiti
                } --
            end
        }:newrow() --
    end

    AddMode(Mode.Regular, "Regular", true, true)

    AddMode(Mode.Graffiti, "Graffiti", true)
    dialog:slider{
        id = "graffitiPower",
        visible = false,
        min = 1,
        max = 100,
        value = 50
    }

    dialog:separator{text = "Outline"} --
    AddMode(Mode.Outline, "Tool")
    AddMode(Mode.OutlineLive, "Brush")
    dialog:color{
        id = "outlineColor",
        visible = false,
        color = Color {gray = 0, alpha = 255}
    }

    dialog:separator{text = "Transform"} --
    AddMode(Mode.Cut, "Lift")
    AddMode(Mode.Selection, "Selection")

    -- self.dialog:separator{text = "Forbidden"} --
    AddMode(Mode.Yeet, "Yeet", false)

    dialog:separator{text = "Mix"}
    AddMode(Mode.Mix, "Unique")
    AddMode(Mode.MixProportional, "Proportional")

    dialog:separator{text = "Change"} --
    AddMode(Mode.Colorize, "Colorize")
    AddMode(Mode.Desaturate, "Desaturate")

    dialog:separator{text = "Shift"} --
    :combobox{
        id = "colorModel",
        options = ColorModels,
        option = colorModel,
        onchange = function()
            colorModel = dialog.data.colorModel

            if colorModel == ColorModels.HSV then
                selectedMode = Mode.ToHsvMap[selectedMode]
            elseif colorModel == ColorModels.HSL then
                selectedMode = Mode.ToHslMap[selectedMode]
            elseif colorModel == ColorModels.RGB then
                selectedMode = Mode.ToRgbMap[selectedMode]
            end

            for _, hsvMode in ipairs(ShiftHsvModes) do
                dialog:modify{
                    id = hsvMode,
                    visible = colorModel == ColorModels.HSV,
                    selected = selectedMode == hsvMode
                }
            end

            for _, hslMode in ipairs(ShiftHslModes) do
                dialog:modify{
                    id = hslMode,
                    visible = colorModel == ColorModels.HSL,
                    selected = selectedMode == hslMode
                }
            end

            for _, rgbMode in ipairs(ShiftRgbModes) do
                dialog:modify{
                    id = rgbMode,
                    visible = colorModel == ColorModels.RGB,
                    selected = selectedMode == rgbMode
                }
            end
        end
    } --

    local isHsv = colorModel == ColorModels.HSV
    AddMode(Mode.ShiftHsvHue, "Hue", isHsv)
    AddMode(Mode.ShiftHsvSaturation, "Saturation", isHsv)
    AddMode(Mode.ShiftHsvValue, "Value", isHsv)

    local isHsl = colorModel == ColorModels.HSL
    AddMode(Mode.ShiftHslHue, "Hue", isHsl)
    AddMode(Mode.ShiftHslSaturation, "Saturation", isHsl)
    AddMode(Mode.ShiftHslLightness, "Lightness", isHsl)

    local isRgb = colorModel == ColorModels.RGB
    AddMode(Mode.ShiftRgbRed, "Red", isRgb)
    AddMode(Mode.ShiftRgbGreen, "Green", isRgb)
    AddMode(Mode.ShiftRgbBlue, "Blue", isRgb)

    dialog --
    :slider{id = "shiftPercentage", min = 1, max = 100, value = 5} --

    dialog --
    :separator() --
    :check{id = "indexedMode", text = "Indexed Mode"}

    return dialog
end

return MagicPencilDialog

-- TODO: Integrate the new `App.events`: `beforecommand` and `aftercommand`, to avoid responding to commands when a pencil tool is selected
