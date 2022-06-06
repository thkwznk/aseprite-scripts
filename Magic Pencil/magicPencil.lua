-- Colors
local Transparent<const> = Color {gray = 0, alpha = 0}
local MagicPink<const> = Color {red = 255, green = 0, blue = 255, alpha = 128}
local MagicTeal<const> = Color {red = 0, green = 128, blue = 128, alpha = 128}

-- Modes
local Modes<const> = {
    Regular = "regular",
    Outline = "outline",
    Cut = "cut",
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
    ShiftHslLightness = "shift-hsl-lightness"
}

local SpecialCursorModes<const> = {
    Modes.Cut, Modes.Mix, Modes.MixProportional, Modes.Desaturate,
    Modes.ShiftHsvHue, Modes.ShiftHsvSaturation, Modes.ShiftHsvValue,
    Modes.ShiftHslHue, Modes.ShiftHslSaturation, Modes.ShiftHslLightness
}

local CanExtendModes<const> = {Modes.Mix, Modes.MixProportional}

local ShiftHsvModes<const> = {
    Modes.ShiftHsvHue, Modes.ShiftHsvSaturation, Modes.ShiftHsvValue
}

local ShiftHslModes<const> = {
    Modes.ShiftHslHue, Modes.ShiftHslSaturation, Modes.ShiftHslLightness
}

local ColorModels<const> = {HSV = "HSV", HSL = "HSL"}

local ToHsvMap<const> = {
    [Modes.ShiftHslHue] = Modes.ShiftHsvHue,
    [Modes.ShiftHslSaturation] = Modes.ShiftHsvSaturation,
    [Modes.ShiftHslLightness] = Modes.ShiftHsvValue
}

local ToHslMap<const> = {
    [Modes.ShiftHsvHue] = Modes.ShiftHslHue,
    [Modes.ShiftHsvSaturation] = Modes.ShiftHslSaturation,
    [Modes.ShiftHsvValue] = Modes.ShiftHslLightness
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

    for _, pixel in ipairs(pixels) do
        if RectangleContains(previous.bounds, pixel) and
            RectangleContains(next.bounds, pixel) then
            old = Color(previous.image:getPixel(pixel.x - previous.position.x,
                                                pixel.y - previous.position.y))
            new = Color(next.image:getPixel(pixel.x - next.position.x,
                                            pixel.y - next.position.y))
            break
        end
    end

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

    local bounds = GetBoundsForPixels(pixels)
    local leftPressed, rightPressed = GetButtonsPressed(pixels, previous, next)

    return {
        pixels = pixels,
        bounds = bounds,
        center = RectangleCenter(bounds),
        leftPressed = leftPressed,
        rightPressed = rightPressed
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

        local change = CalculateChange(lastCel, app.activeCel,
                                       Contains(CanExtendModes, selectedMode))

        -- If no pixel was changed then revert to original
        if #change.pixels == 0 then
            -- If instead I just replace image and positon in the active cel, Aseprite will crash if I undo when hovering mouse over dialog
            sprite:newCel(app.activeLayer, app.activeFrame.frameNumber,
                          lastCel.image, lastCel.position)
        elseif not change.leftPressed and not change.rightPressed then
            -- Not a user change - most probably an undo action, do nothing
        else
            self:ProcessMode(selectedMode, change, sprite, lastCel, {
                shiftPercentage = self.dialog.data.shiftPercentage
            })
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
            end
        }:newrow() --
    end

    Mode(Modes.Regular, "Regular", true, true)

    self.dialog:separator{text = "Transform"} --
    Mode(Modes.Outline, "Outline")
    Mode(Modes.Cut, "Lift")
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

    self.dialog --
    :slider{id = "shiftPercentage", min = 1, max = 100, value = 5} --
    :show{wait = false}
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

            sprite:newCel(app.activeLayer, app.activeFrame.frameNumber,
                          newImage, Point(newImageBounds.x, newImageBounds.y))
        else
            sprite:newCel(app.activeLayer, app.activeFrame.frameNumber,
                          cel.image, cel.position)
        end
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

        sprite:newCel(app.activeLayer, app.activeFrame.frameNumber, cel.image,
                      cel.position)

        local newLayer = sprite:newLayer()
        newLayer.name = "Lifted Content"

        sprite:newCel(newLayer, app.activeFrame.frameNumber, image,
                      Point(intersection.x, intersection.y))
    elseif mode == Modes.Yeet then
        local startFrame = app.activeFrame.frameNumber

        local x, y = cel.position.x, cel.position.y
        local xSpeed = math.floor(change.bounds.width / 2)
        local ySpeed = -math.floor(change.bounds.height / 2)

        sprite:newCel(app.activeLayer, startFrame, cel.image, cel.position)

        local MaxFrames<const> = 50

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

        sprite:newCel(app.activeLayer, app.activeFrame.frameNumber, newImage,
                      Point(newBounds.x, newBounds.y))
    elseif mode == Modes.Colorize then
        local x, y, c
        local hue = If(change.leftPressed, app.fgColor.hsvHue,
                       app.bgColor.hsvHue)

        for _, pixel in ipairs(change.pixels) do
            x = pixel.x - cel.position.x
            y = pixel.y - cel.position.y
            c = Color(cel.image:getPixel(x, y))
            c.hsvHue = hue

            cel.image:drawPixel(x, y, c)
        end

        sprite:newCel(app.activeLayer, app.activeFrame.frameNumber, cel.image,
                      cel.position)
    elseif mode == Modes.Desaturate then
        local x, y, c

        for _, pixel in ipairs(change.pixels) do
            x = pixel.x - cel.position.x
            y = pixel.y - cel.position.y
            c = Color(cel.image:getPixel(x, y))

            cel.image:drawPixel(x, y, Color {
                gray = 0.299 * c.red + 0.114 * c.blue + 0.587 * c.green,
                alpha = c.alpha
            })
        end

        sprite:newCel(app.activeLayer, app.activeFrame.frameNumber, cel.image,
                      cel.position)
    elseif Contains(ShiftHsvModes, mode) or Contains(ShiftHslModes, mode) then
        local shift = parameters.shiftPercentage / 100 *
                          If(change.leftPressed, 1, -1)
        local x, y, c

        for _, pixel in ipairs(change.pixels) do
            x = pixel.x - cel.position.x
            y = pixel.y - cel.position.y
            c = Color(cel.image:getPixel(x, y))

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
            end

            cel.image:drawPixel(x, y, c)
        end

        sprite:newCel(app.activeLayer, app.activeFrame.frameNumber, cel.image,
                      cel.position)
    end
end

return MagicPencil
