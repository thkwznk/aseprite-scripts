-- Colors
local Transparent = Color {gray = 0, alpha = 0}
local MagicPink = Color {red = 255, green = 0, blue = 255, alpha = 128}
local MagicTeal = Color {red = 0, green = 128, blue = 128, alpha = 128}

-- Modes
local Modes = {
    Regular = "regular",
    Outline = "outline",
    OutlineLive = "outline-live",
    Cut = "cut",
    Selection = "selection",
    Yeet = "yeet",
    Mix = "mix",
    MixProportional = "mix-proportional",
    Colorize = "colorize",
    Desaturate = "desaturate",
    ShiftHsvHue = "shift-hsv-hue",
    ShiftHsvSaturation = "shift-hsv-saturation",
    ShiftHsvValue = "shift-hsv-value",
    ShiftHslHue = "shift-hsl-hue",
    ShiftHslSaturation = "shift-hsl-saturation",
    ShiftHslLightness = "shift-hsl-lightness",
    ShiftRgbRed = "shift-rgb-red",
    ShiftRgbGreen = "shift-rgb-green",
    ShiftRgbBlue = "shift-rgb-blue"
}

local SpecialCursorModes = {
    Modes.Cut, Modes.Selection, Modes.Mix, Modes.MixProportional,
    Modes.Desaturate, Modes.ShiftHsvHue, Modes.ShiftHsvSaturation,
    Modes.ShiftHsvValue, Modes.ShiftHslHue, Modes.ShiftHslSaturation,
    Modes.ShiftHslLightness, Modes.ShiftRgbRed, Modes.ShiftRgbGreen,
    Modes.ShiftRgbBlue
}

local CanExtendModes = {
    Modes.OutlineLive, Modes.Selection, Modes.Mix, Modes.MixProportional
}

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

function RectangleContains(rect, p)
    return p.x >= rect.x and p.x <= rect.x + rect.width - 1 and --
    p.y >= rect.y and p.y <= rect.y + rect.height - 1
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

    if not RectangleContains(previous.bounds, pixel) then
        local newPixelValue = next.image:getPixel(pixel.x - next.position.x,
                                                  pixel.y - next.position.y)

        if app.fgColor.rgbaPixel == newPixelValue then
            leftPressed = true
        elseif app.bgColor.rgbaPixel == newPixelValue then
            rightPressed = true
        end

        return leftPressed, rightPressed
    end

    old = Color(previous.image:getPixel(pixel.x - previous.position.x,
                                        pixel.y - previous.position.y))
    new = Color(next.image:getPixel(pixel.x - next.position.x,
                                    pixel.y - next.position.y))

    if old == nil or new == nil then return leftPressed, rightPressed end

    if WasColorBlended(old, app.fgColor, new) then
        leftPressed = true
    elseif WasColorBlended(old, app.bgColor, new) then
        rightPressed = true
    end

    return leftPressed, rightPressed
end

function Outline(selection, image, x, y)
    local outlinePixels = {}
    RecursiveOutline(selection, image, x, y, outlinePixels, {})
    return outlinePixels
end

function RecursiveOutline(selection, image, x, y, outlinePixels, visited)
    -- Out of selection
    if selection then
        if not RectangleContains(selection, Point(x, y)) then return end
    end

    -- Out of bounds
    if x < 0 or x > image.width - 1 or y < 0 or y > image.height - 1 then
        table.insert(outlinePixels, {x = x, y = y})
        return
    end

    local pixelCoordinate = tostring(x) .. ":" .. tostring(y)
    -- Already visited
    if visited[pixelCoordinate] then return end
    -- Mark a pixel as visited
    visited[pixelCoordinate] = true

    if Color(image:getPixel(x, y)).alpha == 0 then
        table.insert(outlinePixels, {x = x, y = y})
        return
    end

    RecursiveOutline(selection, image, x - 1, y, outlinePixels, visited)
    RecursiveOutline(selection, image, x + 1, y, outlinePixels, visited)
    RecursiveOutline(selection, image, x, y - 1, outlinePixels, visited)
    RecursiveOutline(selection, image, x, y + 1, outlinePixels, visited)
end

function CalculateChange(previous, next, canExtend)
    -- If size changed then it's a clear indicator of a change
    -- Pencil can only add which means the new image can only be bigger

    local pixels = {}
    local prevPixelValue = nil

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

                prevPixelValue = previous.image:getPixel(shiftedX, shiftedY)
                nextPixelValue = next.image:getPixel(x, y)

                -- Out of bounds of the previous image or transparent
                if (shiftedX < 0 or shiftedX > previous.image.width - 1 or
                    shiftedY < 0 or shiftedY > previous.image.height - 1) then
                    if Color(nextPixelValue).alpha > 0 then
                        table.insert(pixels, {
                            x = x + next.position.x,
                            y = y + next.position.y,
                            color = nil
                        })
                    end
                elseif prevPixelValue ~= nextPixelValue then
                    table.insert(pixels, {
                        x = x + next.position.x,
                        y = y + next.position.y,
                        color = Color(prevPixelValue)
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
                prevPixelValue = previous.image:getPixel(x, y)

                -- Next image in some rare cases can be smaller
                if RectangleContains(next.bounds, Point(x + previous.position.x,
                                                        y + previous.position.y)) then
                    if prevPixelValue ~=
                        next.image:getPixel(x + shift.x, y + shift.y) then
                        -- Save X and Y as canvas global
                        table.insert(pixels, {
                            x = x + previous.position.x,
                            y = y + previous.position.y,
                            color = Color(prevPixelValue)
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

function AverageColorRGB(colors)
    local r, g, b = 0, 0, 0

    for _, color in ipairs(colors) do
        r = r + color.red
        g = g + color.green
        b = b + color.blue
    end

    return Color {
        red = math.floor(r / #colors),
        green = math.floor(g / #colors),
        blue = math.floor(b / #colors),
        alpha = 255
    }
end

function AverageColorHSV(colors)
    local h1, h2, s, v = 0, 0, 0, 0

    for _, color in ipairs(colors) do
        h1 = h1 + math.cos(math.rad(color.hsvHue))
        h2 = h2 + math.sin(math.rad(color.hsvHue))
        s = s + color.hsvSaturation
        v = v + color.hsvValue
    end

    return Color {
        hue = math.deg(math.atan(h2, h1)) % 360,
        saturation = s / #colors,
        value = v / #colors,
        alpha = 255
    }
end

local MagicPencil = {dialog = nil, colorModel = ColorModels.HSV}

function MagicPencil:Execute()
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
        selectedMode == Modes.Regular or -- If it's the wrong mode then ignore
        lastKnownNumberOfCels ~= #sprite.cels or -- If last layer/frame/cel was removed then ignore
        lastActiveCel ~= app.activeCel or -- If it's just a layer/frame/cel change then ignore
        lastActiveCel == nil -- If a cel was created where previously was none or cel was copied
        then
            updateLast()
            return
        end

        local modeCanExtend = Contains(CanExtendModes, selectedMode)
        local change = CalculateChange(lastCel, app.activeCel, modeCanExtend)

        -- If no pixel was changed, but the size changed then revert to original
        if #change.pixels == 0 then
            if change.sizeChanged and modeCanExtend and lastCel then
                -- If instead I just replace image and positon in the active cel, Aseprite will crash if I undo when hovering mouse over dialog
                -- sprite:newCel(app.activeLayer, app.activeFrame.frameNumber,
                --               lastCel.image, lastCel.position)
                app.activeCel.image = lastCel.image
                app.activeCel.position = lastCel.position
            end
            -- Otherwise, do nothing
        elseif not change.leftPressed and not change.rightPressed then
            -- Not a user change - most probably an undo action, do nothing
        else
            self:ProcessMode(selectedMode, change, sprite, lastCel,
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

                self.dialog:modify{
                    id = "outlineColor",
                    visible = selectedMode == Modes.OutlineLive
                }
            end
        }:newrow() --
    end

    Mode(Modes.Regular, "Regular", true, true)

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

function MagicPencil:ProcessMode(mode, change, sprite, cel, parameters)
    if mode == Modes.Outline then
        -- Calculate outline pixels from the center of the change bound
        local selection = nil

        if not sprite.selection.isEmpty then
            local b = sprite.selection.bounds
            selection = Rectangle(b.x - cel.bounds.x, b.y - cel.bounds.y,
                                  b.width, b.height)
        end

        local outlinePixels = Outline(selection, cel.image,
                                      change.center.x - cel.bounds.x,
                                      change.center.y - cel.bounds.y)

        local bounds = GetBoundsForPixels(outlinePixels)

        if bounds then
            local boundsGlobal = Rectangle(bounds.x + cel.bounds.x,
                                           bounds.y + cel.bounds.y,
                                           bounds.width, bounds.height)
            local newImageBounds = cel.bounds:union(boundsGlobal)

            local shift = Point(cel.bounds.x - newImageBounds.x,
                                cel.bounds.y - newImageBounds.y)

            local newImage = Image(newImageBounds.width, newImageBounds.height)
            newImage:drawImage(cel.image, shift.x, shift.y)

            local outlineColor = change.leftPressed and app.fgColor or
                                     app.bgColor

            for _, pixel in ipairs(outlinePixels) do
                newImage:drawPixel(pixel.x + shift.x, pixel.y + shift.y,
                                   outlineColor)
            end

            app.activeCel.image = newImage
            app.activeCel.position = Point(newImageBounds.x, newImageBounds.y)
        else
            app.activeCel.image = cel.image
            app.activeCel.position = cel.position
        end
    elseif mode == Modes.OutlineLive then
        local color = parameters.outlineColor.rgbaPixel

        local selection = sprite.selection
        local extend = {}

        for _, pixel in ipairs(change.pixels) do
            local ix = pixel.x - app.activeCel.bounds.x
            local iy = pixel.y - app.activeCel.bounds.y

            if ix == 0 then extend.left = true end
            if ix == app.activeCel.image.width - 1 then
                extend.right = true
            end
            if iy == 0 then extend.up = true end
            if iy == app.activeCel.image.height - 1 then
                extend.down = true
            end
        end

        local width = app.activeCel.image.width
        local height = app.activeCel.image.height

        if extend.left then width = width + 1 end
        if extend.right then width = width + 1 end
        if extend.up then height = height + 1 end
        if extend.down then height = height + 1 end

        local newImage = Image(width, height)

        local dpx = If(extend.left, 1, 0)
        local dpy = If(extend.up, 1, 0)

        newImage:drawImage(app.activeCel.image, Point(dpx, dpy))

        local CanOutline = function(x, y)
            return selection.isEmpty or
                       (not selection.isEmpty and selection:contains(x, y))
        end

        for _, pixel in ipairs(change.pixels) do
            local ix = pixel.x - app.activeCel.bounds.x + dpx
            local iy = pixel.y - app.activeCel.bounds.y + dpy

            if CanOutline(pixel.x - 1, pixel.y) then
                if newImage:getPixel(ix - 1, iy) == 0 then
                    newImage:drawPixel(ix - 1, iy, color)
                end
            end

            if CanOutline(pixel.x + 1, pixel.y) then
                if newImage:getPixel(ix + 1, iy) == 0 then
                    newImage:drawPixel(ix + 1, iy, color)
                end
            end

            if CanOutline(pixel.x, pixel.y - 1) then
                if newImage:getPixel(ix, iy - 1) == 0 then
                    newImage:drawPixel(ix, iy - 1, color)
                end
            end

            if CanOutline(pixel.x, pixel.y + 1) then
                if newImage:getPixel(ix, iy + 1) == 0 then
                    newImage:drawPixel(ix, iy + 1, color)
                end
            end
        end

        app.activeCel.image = newImage
        app.activeCel.position = Point(app.activeCel.position.x - dpx,
                                       app.activeCel.position.y - dpy)
    elseif mode == Modes.Cut then
        local intersection = Rectangle(cel.bounds):intersect(change.bounds)
        local image = Image(intersection.width, intersection.height)
        local color = nil

        for _, pixel in ipairs(change.pixels) do
            if RectangleContains(intersection, pixel) then
                color = cel.image:getPixel(pixel.x - cel.position.x,
                                           pixel.y - cel.position.y)
                cel.image:drawPixel(pixel.x - cel.position.x,
                                    pixel.y - cel.position.y, Transparent)

                image:drawPixel(pixel.x - intersection.x,
                                pixel.y - intersection.y, color)
            end
        end

        app.activeCel.image = cel.image
        app.activeCel.position = cel.position

        local activeLayerIndex = app.activeLayer.stackIndex
        local activeLayerParent = app.activeLayer.parent

        local newLayer = sprite:newLayer()
        newLayer.parent = activeLayerParent
        if change.leftPressed then
            newLayer.stackIndex = activeLayerIndex + 1
        else
            newLayer.stackIndex = activeLayerIndex
        end

        newLayer.name = "Lifted Content"

        sprite:newCel(app.activeLayer, app.activeFrame.frameNumber, image,
                      Point(intersection.x, intersection.y))
    elseif mode == Modes.Selection then
        -- FIX: If the whole selection is out of the original cel's bounds it will not be processed

        local newSelection = Selection()

        for _, pixel in ipairs(change.pixels) do
            newSelection:add(Rectangle(pixel.x, pixel.y, 1, 1))
        end

        if change.leftPressed then
            if sprite.selection.isEmpty then
                sprite.selection:add(newSelection)
            else
                sprite.selection:intersect(newSelection)
            end
        else
            sprite.selection:subtract(newSelection)
        end

        app.activeCel.image = cel.image
        app.activeCel.position = cel.position
    elseif mode == Modes.Yeet then
        local startFrame = app.activeFrame.frameNumber

        local x, y = cel.position.x, cel.position.y
        local xSpeed = math.floor(change.bounds.width / 2)
        local ySpeed = -math.floor(change.bounds.height / 2)

        sprite:newCel(app.activeLayer, startFrame, cel.image, cel.position)

        local MaxFrames = 50

        for frame = startFrame + 1, startFrame + MaxFrames do
            if x < 0 or x > sprite.width or y > sprite.height then
                break
            end

            x, y = x + xSpeed, y + ySpeed
            xSpeed, ySpeed = xSpeed, ySpeed + 2

            if frame > #sprite.frames then sprite:newEmptyFrame() end
            sprite:newCel(app.activeLayer, frame, cel.image, Point(x, y))
        end
    elseif mode == Modes.Mix or mode == Modes.MixProportional then
        local colors = {}

        for _, pixel in ipairs(change.pixels) do
            if pixel.color and pixel.color.alpha == 255 then
                if mode == Modes.Mix then
                    if not Contains(colors, pixel.color) then
                        table.insert(colors, pixel.color)
                    end
                elseif mode == Modes.MixProportional then
                    table.insert(colors, pixel.color)
                end
            end
        end

        local averageColor = If(change.leftPressed, AverageColorRGB,
                                AverageColorHSV)(colors)

        if parameters.indexedMode then
            averageColor = sprite.palettes[1]:getColor(averageColor.index)
        end

        local newBounds = app.activeCel.bounds
        local shift = Point(cel.bounds.x - newBounds.x,
                            cel.bounds.y - newBounds.y)

        local newImage = Image(app.activeCel.image.width,
                               app.activeCel.image.height)
        newImage:drawImage(cel.image, shift.x, shift.y)

        for _, pixel in ipairs(change.pixels) do
            newImage:drawPixel(pixel.x - newBounds.x, pixel.y - newBounds.y,
                               averageColor)
        end

        app.activeCel.image = newImage
        app.activeCel.position = Point(newBounds.x, newBounds.y)
    elseif mode == Modes.Colorize then
        local x, y, c
        local hue = If(change.leftPressed, app.fgColor.hsvHue,
                       app.bgColor.hsvHue)

        for _, pixel in ipairs(change.pixels) do
            x = pixel.x - cel.position.x
            y = pixel.y - cel.position.y
            c = Color(cel.image:getPixel(x, y))

            if c.alpha > 0 then
                c.hsvHue = hue
                c.hsvSaturation =
                    (c.hsvSaturation + app.fgColor.hsvSaturation) / 2

                if parameters.indexedMode then
                    c = sprite.palettes[1]:getColor(c.index)
                end

                cel.image:drawPixel(x, y, c)
            end
        end

        app.activeCel.image = cel.image
        app.activeCel.position = cel.position
    elseif mode == Modes.Desaturate then
        local x, y, c

        for _, pixel in ipairs(change.pixels) do
            x = pixel.x - cel.position.x
            y = pixel.y - cel.position.y
            c = Color(cel.image:getPixel(x, y))

            if c.alpha > 0 then
                c = Color {
                    gray = 0.299 * c.red + 0.114 * c.blue + 0.587 * c.green,
                    alpha = c.alpha
                }

                if parameters.indexedMode then
                    c = sprite.palettes[1]:getColor(c.index)
                end

                cel.image:drawPixel(x, y, c)
            end
        end

        app.activeCel.image = cel.image
        app.activeCel.position = cel.position
    elseif Contains(ShiftHsvModes, mode) or Contains(ShiftHslModes, mode) or
        Contains(ShiftRgbModes, mode) then
        local shift = parameters.shiftPercentage / 100 *
                          If(change.leftPressed, 1, -1)
        local x, y, c

        for _, pixel in ipairs(change.pixels) do
            x = pixel.x - cel.position.x
            y = pixel.y - cel.position.y
            c = Color(cel.image:getPixel(x, y))

            if c.alpha > 0 then
                if mode == Modes.ShiftHsvHue then
                    c.hsvHue = (c.hsvHue + shift * 360) % 360
                elseif mode == Modes.ShiftHsvSaturation then
                    c.hsvSaturation = c.hsvSaturation + shift
                elseif mode == Modes.ShiftHsvValue then
                    c.hsvValue = c.hsvValue + shift
                elseif mode == Modes.ShiftHslHue then
                    c.hslHue = (c.hslHue + shift * 360) % 360
                elseif mode == Modes.ShiftHslSaturation then
                    c.hslSaturation = c.hslSaturation + shift
                elseif mode == Modes.ShiftHslLightness then
                    c.hslLightness = c.hslLightness + shift
                elseif mode == Modes.ShiftRgbRed then
                    c.red = math.min(math.max(c.red + shift * 255, 0), 255)
                elseif mode == Modes.ShiftRgbGreen then
                    c.green = math.min(math.max(c.green + shift * 255, 0), 255)
                elseif mode == Modes.ShiftRgbBlue then
                    c.blue = math.min(math.max(c.blue + shift * 255, 0), 255)
                end

                if parameters.indexedMode then
                    c = sprite.palettes[1]:getColor(c.index)
                end

                cel.image:drawPixel(x, y, c)
            end
        end

        app.activeCel.image = cel.image
        app.activeCel.position = cel.position
    end
end

return MagicPencil
