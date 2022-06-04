return {
    Execute = function()

        function GetBoundsForPixels(pixels)
            if pixels and #pixels == 0 then return end

            local minX = pixels[1].x
            local maxX = pixels[1].x
            local minY = pixels[1].y
            local maxY = pixels[1].y

            for _, pixel in ipairs(pixels) do
                minX = math.min(minX, pixel.x)
                maxX = math.max(maxX, pixel.x)

                minY = math.min(minY, pixel.y)
                maxY = math.max(maxY, pixel.y)
            end

            local width = maxX - minX + 1
            local height = maxY - minY + 1

            return Rectangle(minX, minY, width, height)
        end

        function WasValueBlended(old, value, new)
            return (old < value and new > old) or (old >= value and new <= old)
        end

        function WasColorBlended(old, color, new)
            return WasValueBlended(old.red, color.red, new.red) and
                       WasValueBlended(old.green, color.green, new.green) and
                       WasValueBlended(old.blue, color.blue, new.blue)
        end

        function GetButtonsPressed(pixels, previous, next, isSpecialCursorMode)
            if #pixels == 0 then return end

            local leftPressed = false
            local rightPressed = false
            local pixelInImage = nil

            for _, pixel in ipairs(pixels) do
                if pixel.x >= previous.position.x and pixel.x <=
                    previous.position.x + previous.bounds.width - 1 and pixel.y >=
                    previous.position.y and pixel.y <= previous.position.y +
                    previous.bounds.height - 1 and pixel.x >= next.position.x and
                    pixel.x <= next.position.x + next.bounds.width - 1 and
                    pixel.y >= next.position.y and pixel.y <= next.position.y +
                    next.bounds.height - 1 then
                    pixelInImage = pixel
                    break
                end
            end

            if pixelInImage == nil then
                return leftPressed, rightPressed
            end

            local old = Color(previous.image:getPixel(pixelInImage.x -
                                                          previous.position.x,
                                                      pixelInImage.y -
                                                          previous.position.y))
            local new = Color(next.image:getPixel(pixelInImage.x -
                                                      next.position.x,
                                                  pixelInImage.y -
                                                      next.position.y))

            if isSpecialCursorMode then
                if new.red >= old.red and new.green <= old.green and new.blue >=
                    new.blue then
                    leftPressed = true
                elseif new.red <= old.red and
                    ((old.green <= 128 and new.green >= old.green) or
                        (old.green >= 128 and new.green <= old.green)) and
                    ((old.blue <= 128 and new.blue >= old.blue) or
                        (old.blue >= 128 and new.blue <= old.blue)) then
                    rightPressed = true
                end
            else
                if app.fgColor.alpha == 255 and new.rgbaPixel ==
                    app.fgColor.rgbaPixel then
                    leftPressed = true
                elseif app.bgColor.alpha == 255 and new.rgbaPixel ==
                    app.bgColor.rgbaPixel then
                    rightPressed = true
                elseif WasColorBlended(old, app.fgColor, new) then
                    leftPressed = true
                elseif WasColorBlended(old, app.bgColor, new) then
                    rightPressed = true
                end
            end

            return leftPressed, rightPressed
        end

        function Outline(selection, image, x, y)
            local outlinePixels = {}
            local visitedPixels = {}

            RecursiveOutline(selection, image, x, y, outlinePixels,
                             visitedPixels)

            return outlinePixels
        end

        function RecursiveOutline(selection, image, x, y, outlinePixels,
                                  visitedPixels)
            -- Out of selection
            if selection then
                if x < selection.x or x > selection.x + selection.width - 1 or --
                y < selection.y or y > selection.y + selection.height - 1 then
                    return
                end
            end

            -- Out of bounds
            if x < 0 or x > image.width - 1 or y < 0 or y > image.height - 1 then
                table.insert(outlinePixels, {x = x, y = y})
                return
            end

            local pixelCoordinate = tostring(x) .. ":" .. tostring(y)

            -- Already visited
            if visitedPixels[pixelCoordinate] then return end

            -- Mark a pixel as visited
            visitedPixels[pixelCoordinate] = true

            if Color(image:getPixel(x, y)).alpha == 0 then
                table.insert(outlinePixels, {x = x, y = y})
                return
            end

            RecursiveOutline(selection, image, x - 1, y, outlinePixels,
                             visitedPixels)
            RecursiveOutline(selection, image, x + 1, y, outlinePixels,
                             visitedPixels)
            RecursiveOutline(selection, image, x, y - 1, outlinePixels,
                             visitedPixels)
            RecursiveOutline(selection, image, x, y + 1, outlinePixels,
                             visitedPixels)
        end

        function CalculateChange(previous, next, isSpecialCursorMode, canExtend)
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
                local shiftedX = nil
                local shiftedY = nil

                local nextPixelValue = nil

                for x = 0, next.image.width - 1 do
                    for y = 0, next.image.height - 1 do
                        -- Save X and Y as canvas global

                        shiftedX = x + shift.x
                        shiftedY = y + shift.y

                        prevPixelValue =
                            previous.image:getPixel(shiftedX, shiftedY)
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

            local start = nil
            local finish = nil
            local center = nil
            if bounds ~= nil then
                start = Point(bounds.x, bounds.y)
                finish = Point(bounds.x + bounds.width - 1,
                               bounds.y + bounds.height - 1)
                center = Point(bounds.x + math.floor(bounds.width / 2),
                               bounds.y + math.floor(bounds.height / 2))
            end

            -- Detect what button was pressed
            local leftPressed, rightPressed =
                GetButtonsPressed(pixels, previous, next, isSpecialCursorMode)

            return {
                start = start,
                finish = finish,
                center = center,

                bounds = bounds,
                pixels = pixels,

                leftPressed = leftPressed,
                rightPressed = rightPressed
            }
        end

        if not app.isUIAvailable or not app.activeSprite then return end

        local Transparent<const> = Color {gray = 0, alpha = 0}
        local MagicPink<const> = Color {
            red = 255,
            green = 0,
            blue = 255,
            alpha = 128
        }
        local MagicTeal<const> = Color {
            red = 0,
            green = 128,
            blue = 128,
            alpha = 128
        }

        -- This value is changed from the dialog
        local shiftPercentage = 5

        local Modes = {
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

        local lastFgColor = Color(app.fgColor.rgbaPixel)
        local lastBgColor = Color(app.bgColor.rgbaPixel)
        local selectedMode = Modes.Regular

        local SpecialCursorModes<const> = {
            Modes.Cut, Modes.Mix, Modes.MixProportional, Modes.Desaturate,
            Modes.ShiftHsvHue, Modes.ShiftHsvSaturation, Modes.ShiftHsvValue,
            Modes.ShiftHslHue, Modes.ShiftHslSaturation, Modes.ShiftHslLightness
        }
        local IsSpecialCursorMode = function()
            for _, mode in ipairs(SpecialCursorModes) do
                if selectedMode == mode then return true end
            end
        end

        local CanExtendModes<const> = {Modes.Mix, Modes.MixProportional}
        local CanExtendMode = function()
            for _, mode in ipairs(CanExtendModes) do
                if selectedMode == mode then return true end
            end
        end

        local sprite = app.activeSprite

        local lastKnownNumberOfCels = #sprite.cels
        local lastActiveCel = app.activeCel
        local lastActiveLayer = app.activeLayer
        local lastActiveFrameNumber = app.activeFrame.frameNumber

        local lastCelImage = lastActiveCel.image:clone()
        local lastCelPosition = lastActiveCel.position
        local lastCelBounds = lastActiveCel.bounds

        -- Declare dialog to refrence it in the listener
        local dialog = nil

        local updateLast = function(sameSprite)
            if sprite ~= nil then
                lastKnownNumberOfCels = #sprite.cels
            end

            -- If from site change, same sprite, same layer, same frame but cel changed
            if sameSprite and lastActiveCel == nil and app.activeCel ~= nil and
                lastActiveLayer == app.activeLayer and lastActiveFrameNumber ==
                app.activeFrame.frameNumber and lastActiveCel ~= app.activeCel then
                -- print("Daba di daba da!")
                return
            end

            lastActiveCel = app.activeCel

            lastCelImage = nil
            lastCelPosition = nil
            lastCelBounds = nil

            -- When creating a new layer or cel this can be triggered
            if lastActiveCel ~= nil then
                lastCelImage = lastActiveCel.image:clone()
                lastCelPosition = lastActiveCel.position
                lastCelBounds = lastActiveCel.bounds
            end

            lastActiveLayer = app.activeLayer
            lastActiveFrameNumber = app.activeFrame and
                                        app.activeFrame.frameNumber
        end

        local onSpriteChange = function()
            -- If there is no active cel, do nothing
            if app.activeCel == nil then return end

            -- If a cel was created where previously was none or cel was copied
            if lastActiveCel == nil then
                -- sprite:deleteCel(app.activeCel)

                updateLast()
                return
            end

            if app.activeTool.id ~= "pencil" or -- If it's the wrong tool then ignore
            selectedMode == Modes.Regular or -- If it's the wrong mode then ignore
            lastKnownNumberOfCels ~= #sprite.cels or -- If last layer/frame/cel was removed then ignore
            app.activeCel ~= lastActiveCel -- If it's just a layer/frame/cel change then ignore
            then
                updateLast()
                return
            end

            local change = CalculateChange({
                image = lastCelImage,
                position = lastCelPosition,
                bounds = lastCelBounds
            }, app.activeCel, IsSpecialCursorMode(), CanExtendMode())

            -- If no pixel was changed then revert to original
            if #change.pixels == 0 then
                -- If instead I just replace image and positon in the active cel, Aseprite will crash if I undo when hovering mouse over dialog
                sprite:newCel(app.activeLayer, app.activeFrame.frameNumber,
                              lastCelImage, lastCelPosition)
            elseif not change.leftPressed and not change.rightPressed then
                -- Not a user change - most probably an undo action, do nothing
            elseif selectedMode == Modes.Outline then
                -- Calculate outline pixels from the center of the change bound

                local selection = nil

                if not sprite.selection.isEmpty then
                    local b = sprite.selection.bounds
                    selection = Rectangle(b.x - lastCelBounds.x,
                                          b.y - lastCelBounds.y, b.width,
                                          b.height)
                end

                local outlinePixels = Outline(selection, lastCelImage,
                                              change.center.x - lastCelBounds.x,
                                              change.center.y - lastCelBounds.y)

                local bounds = GetBoundsForPixels(outlinePixels)
                local boundsGlobal = Rectangle(bounds.x + lastCelBounds.x,
                                               bounds.y + lastCelBounds.y,
                                               bounds.width, bounds.height)
                local newImageBounds = lastCelBounds:union(boundsGlobal)

                local shift = Point(lastCelBounds.x - newImageBounds.x,
                                    lastCelBounds.y - newImageBounds.y)

                local newImage = Image(newImageBounds.width,
                                       newImageBounds.height)
                newImage:drawImage(lastCelImage, shift.x, shift.y)

                local outlineColor = change.leftPressed and app.fgColor or
                                         app.bgColor

                for _, pixel in ipairs(outlinePixels) do
                    newImage:drawPixel(pixel.x + shift.x, pixel.y + shift.y,
                                       outlineColor)
                end

                sprite:newCel(app.activeLayer, app.activeFrame.frameNumber,
                              newImage,
                              Point(newImageBounds.x, newImageBounds.y))
            elseif selectedMode == Modes.Cut then
                local intersection = Rectangle(lastCelBounds):intersect(
                                         change.bounds)
                local image = Image(intersection.width, intersection.height)

                for _, pixel in ipairs(change.pixels) do
                    if pixel.x >= intersection.x and pixel.x <= intersection.x +
                        intersection.width - 1 and pixel.y >= intersection.y and
                        pixel.y <= intersection.y + intersection.height - 1 then
                        local color = lastCelImage:getPixel(pixel.x -
                                                                lastCelPosition.x,
                                                            pixel.y -
                                                                lastCelPosition.y)
                        lastCelImage:drawPixel(pixel.x - lastCelPosition.x,
                                               pixel.y - lastCelPosition.y,
                                               Transparent)

                        image:drawPixel(pixel.x - intersection.x,
                                        pixel.y - intersection.y, color)
                    end
                end

                sprite:newCel(app.activeLayer, app.activeFrame.frameNumber,
                              lastCelImage, lastCelPosition)

                local newLayer = sprite:newLayer()
                newLayer.name = "Lifted Content"

                sprite:newCel(newLayer, app.activeFrame.frameNumber, image,
                              Point(intersection.x, intersection.y))
            elseif selectedMode == Modes.Yeet then
                local currentFrameNumber = app.activeFrame.frameNumber

                sprite:newCel(app.activeLayer, app.activeFrame.frameNumber,
                              lastCelImage, lastCelPosition)

                local x = lastCelPosition.x
                local y = lastCelPosition.y

                local xSpeed = math.floor(change.bounds.width / 2)
                local ySpeed = -math.floor(change.bounds.height / 2)

                local image = lastCelImage:clone()

                for i = 1, 50 do
                    if x < 0 or x > sprite.width or y > sprite.height then
                        break
                    end

                    x = x + xSpeed
                    y = y + ySpeed

                    xSpeed = xSpeed
                    ySpeed = ySpeed + 2

                    if currentFrameNumber + i > #sprite.frames then
                        sprite:newEmptyFrame()
                    end
                    sprite:newCel(app.activeLayer, currentFrameNumber + i,
                                  image, Point(x, y))
                end
            elseif selectedMode == Modes.Mix then
                local uniqueColors = {}

                for _, pixel in ipairs(change.pixels) do
                    if pixel.color ~= nil then
                        if pixel.color.alpha == 255 then
                            uniqueColors[tostring(pixel.color.rgbaPixel)] = true
                        end
                    end
                end

                local c = nil

                if change.leftPressed then
                    local r = 0
                    local g = 0
                    local b = 0
                    local a = 0
                    local count = 0

                    for pixelId, _ in pairs(uniqueColors) do
                        local uniqueColor = Color(tonumber(pixelId))

                        r = r + uniqueColor.red
                        g = g + uniqueColor.green
                        b = b + uniqueColor.blue
                        a = a + uniqueColor.alpha

                        count = count + 1
                    end

                    r = math.floor(r / count)
                    g = math.floor(g / count)
                    b = math.floor(b / count)
                    a = math.floor(a / count)

                    c = Color {red = r, green = g, blue = b, alpha = a}
                else
                    local h1 = 0
                    local h2 = 0
                    local s = 0
                    local v = 0
                    local a = 0
                    local count = 0

                    for pixelId, _ in pairs(uniqueColors) do
                        local uniqueColor = Color(tonumber(pixelId))

                        h1 = h1 + math.cos(math.rad(uniqueColor.hsvHue))
                        h2 = h2 + math.sin(math.rad(uniqueColor.hsvHue))
                        s = s + uniqueColor.hsvSaturation
                        v = v + uniqueColor.hsvValue
                        a = a + uniqueColor.alpha

                        count = count + 1
                    end

                    local h = math.deg(math.atan(h2, h1))
                    s = s / count
                    v = v / count
                    a = math.floor(a / count)

                    c = Color {
                        hue = math.abs(h),
                        saturation = s,
                        value = v,
                        alpha = a
                    }
                end

                local newBounds = app.activeCel.bounds
                local shift = Point(lastCelBounds.x - newBounds.x,
                                    lastCelBounds.y - newBounds.y)

                local newImage = Image(app.activeCel.image.width,
                                       app.activeCel.image.height)
                newImage:drawImage(lastCelImage, shift.x, shift.y)

                for _, pixel in ipairs(change.pixels) do
                    newImage:drawPixel(pixel.x - newBounds.x,
                                       pixel.y - newBounds.y, c)
                end

                sprite:newCel(app.activeLayer, app.activeFrame.frameNumber,
                              newImage, Point(newBounds.x, newBounds.y))
            elseif selectedMode == Modes.MixProportional then
                local c = nil

                if change.leftPressed then
                    local r = 0
                    local g = 0
                    local b = 0
                    local a = 0

                    local count = 0

                    for _, pixel in ipairs(change.pixels) do
                        if pixel.color ~= nil then
                            if pixel.color.alpha == 255 then
                                r = r + pixel.color.red
                                g = g + pixel.color.green
                                b = b + pixel.color.blue
                                a = a + pixel.color.alpha
                                count = count + 1
                            end
                        end
                    end

                    r = math.floor(r / count)
                    g = math.floor(g / count)
                    b = math.floor(b / count)
                    a = math.floor(a / count)

                    c = Color {red = r, green = g, blue = b, alpha = a}
                else
                    local h1 = 0
                    local h2 = 0
                    local s = 0
                    local v = 0
                    local a = 0
                    local count = 0

                    for _, pixel in ipairs(change.pixels) do
                        if pixel.color ~= nil then
                            if pixel.color.alpha == 255 then
                                h1 = h1 + math.cos(math.rad(pixel.color.hsvHue))
                                h2 = h2 + math.sin(math.rad(pixel.color.hsvHue))
                                s = s + pixel.color.hsvSaturation
                                v = v + pixel.color.hsvValue
                                a = a + pixel.color.alpha

                                count = count + 1
                            end
                        end
                    end

                    local h = math.deg(math.atan(h2, h1))
                    s = s / count
                    v = v / count
                    a = math.floor(a / count)

                    c = Color {
                        hue = math.abs(h),
                        saturation = s,
                        value = v,
                        alpha = a
                    }
                end

                local newBounds = app.activeCel.bounds
                local shift = Point(lastCelBounds.x - newBounds.x,
                                    lastCelBounds.y - newBounds.y)

                local newImage = Image(app.activeCel.image.width,
                                       app.activeCel.image.height)
                newImage:drawImage(lastCelImage, shift.x, shift.y)

                for _, pixel in ipairs(change.pixels) do
                    newImage:drawPixel(pixel.x - newBounds.x,
                                       pixel.y - newBounds.y, c)
                end

                sprite:newCel(app.activeLayer, app.activeFrame.frameNumber,
                              newImage, Point(newBounds.x, newBounds.y))
            elseif selectedMode == Modes.Colorize then
                local hue = nil

                if change.leftPressed then
                    hue = app.fgColor.hsvHue
                else
                    hue = app.bgColor.hsvHue
                end

                for _, pixel in ipairs(change.pixels) do
                    local c = Color(lastCelImage:getPixel(pixel.x -
                                                              lastCelPosition.x,
                                                          pixel.y -
                                                              lastCelPosition.y))
                    c.hsvHue = hue

                    lastCelImage:drawPixel(pixel.x - lastCelPosition.x,
                                           pixel.y - lastCelPosition.y, c)
                end

                sprite:newCel(app.activeLayer, app.activeFrame.frameNumber,
                              lastCelImage, lastCelPosition)
            elseif selectedMode == Modes.Desaturate then
                for _, pixel in ipairs(change.pixels) do
                    local c = Color(lastCelImage:getPixel(pixel.x -
                                                              lastCelPosition.x,
                                                          pixel.y -
                                                              lastCelPosition.y))

                    lastCelImage:drawPixel(pixel.x - lastCelPosition.x,
                                           pixel.y - lastCelPosition.y, Color {
                        gray = 0.299 * c.red + 0.114 * c.blue + 0.587 * c.green,
                        alpha = c.alpha
                    })
                end

                sprite:newCel(app.activeLayer, app.activeFrame.frameNumber,
                              lastCelImage, lastCelPosition)
            elseif selectedMode == Modes.ShiftHsvHue then
                local shift = (shiftPercentage / 100) * 360

                for _, pixel in ipairs(change.pixels) do
                    local c = Color(lastCelImage:getPixel(pixel.x -
                                                              lastCelPosition.x,
                                                          pixel.y -
                                                              lastCelPosition.y))

                    local newHue = c.hsvHue

                    if change.leftPressed then
                        newHue = newHue + shift
                        if newHue > 360 then
                            newHue = newHue - 360
                        end
                    else
                        newHue = newHue - shift
                        if newHue < 0 then
                            newHue = 360 + newHue
                        end
                    end

                    c.hsvHue = newHue

                    lastCelImage:drawPixel(pixel.x - lastCelPosition.x,
                                           pixel.y - lastCelPosition.y, c)
                end

                sprite:newCel(app.activeLayer, app.activeFrame.frameNumber,
                              lastCelImage, lastCelPosition)
            elseif selectedMode == Modes.ShiftHsvSaturation then
                local shift = shiftPercentage / 100

                for _, pixel in ipairs(change.pixels) do
                    local c = Color(lastCelImage:getPixel(pixel.x -
                                                              lastCelPosition.x,
                                                          pixel.y -
                                                              lastCelPosition.y))

                    local newSaturation = c.hsvSaturation

                    if change.leftPressed then
                        newSaturation = newSaturation + shift
                    else
                        newSaturation = newSaturation - shift
                    end

                    c.hsvSaturation = newSaturation

                    lastCelImage:drawPixel(pixel.x - lastCelPosition.x,
                                           pixel.y - lastCelPosition.y, c)
                end

                sprite:newCel(app.activeLayer, app.activeFrame.frameNumber,
                              lastCelImage, lastCelPosition)
            elseif selectedMode == Modes.ShiftHsvValue then
                local shift = shiftPercentage / 100

                for _, pixel in ipairs(change.pixels) do
                    local c = Color(lastCelImage:getPixel(pixel.x -
                                                              lastCelPosition.x,
                                                          pixel.y -
                                                              lastCelPosition.y))

                    local newValue = c.hsvValue

                    if change.leftPressed then
                        newValue = newValue + shift
                    else
                        newValue = newValue - shift
                    end

                    c.hsvValue = newValue

                    lastCelImage:drawPixel(pixel.x - lastCelPosition.x,
                                           pixel.y - lastCelPosition.y, c)
                end

                sprite:newCel(app.activeLayer, app.activeFrame.frameNumber,
                              lastCelImage, lastCelPosition)
            elseif selectedMode == Modes.ShiftHslHue then
                local shift = (shiftPercentage / 100) * 360

                for _, pixel in ipairs(change.pixels) do
                    local c = Color(lastCelImage:getPixel(pixel.x -
                                                              lastCelPosition.x,
                                                          pixel.y -
                                                              lastCelPosition.y))

                    local newHue = c.hslHue

                    if change.leftPressed then
                        newHue = newHue + shift
                        if newHue > 360 then
                            newHue = newHue - 360
                        end
                    else
                        newHue = newHue - shift
                        if newHue < 0 then
                            newHue = 360 + newHue
                        end
                    end

                    c.hslHue = newHue

                    lastCelImage:drawPixel(pixel.x - lastCelPosition.x,
                                           pixel.y - lastCelPosition.y, c)
                end

                sprite:newCel(app.activeLayer, app.activeFrame.frameNumber,
                              lastCelImage, lastCelPosition)
            elseif selectedMode == Modes.ShiftHslSaturation then
                local shift = shiftPercentage / 100

                for _, pixel in ipairs(change.pixels) do
                    local c = Color(lastCelImage:getPixel(pixel.x -
                                                              lastCelPosition.x,
                                                          pixel.y -
                                                              lastCelPosition.y))

                    local newSaturation = c.hslSaturation

                    if change.leftPressed then
                        newSaturation = newSaturation + shift
                    else
                        newSaturation = newSaturation - shift
                    end

                    c.hslSaturation = newSaturation

                    lastCelImage:drawPixel(pixel.x - lastCelPosition.x,
                                           pixel.y - lastCelPosition.y, c)
                end

                sprite:newCel(app.activeLayer, app.activeFrame.frameNumber,
                              lastCelImage, lastCelPosition)
            elseif selectedMode == Modes.ShiftHslLightness then
                local shift = shiftPercentage / 100

                for _, pixel in ipairs(change.pixels) do
                    local c = Color(lastCelImage:getPixel(pixel.x -
                                                              lastCelPosition.x,
                                                          pixel.y -
                                                              lastCelPosition.y))

                    local newLightness = c.hslLightness

                    if change.leftPressed then
                        newLightness = newLightness + shift
                    else
                        newLightness = newLightness - shift
                    end

                    c.hslLightness = newLightness

                    lastCelImage:drawPixel(pixel.x - lastCelPosition.x,
                                           pixel.y - lastCelPosition.y, c)
                end

                sprite:newCel(app.activeLayer, app.activeFrame.frameNumber,
                              lastCelImage, lastCelPosition)
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
                updateLast(true)
                return
            end

            -- Unsubscribe from changes on the previous sprite
            if sprite ~= nil then
                sprite.events:off(onChangeListener)
                sprite = nil
            end

            -- Subscribe to change on the new sprite
            if app.activeSprite ~= nil then
                sprite = app.activeSprite
                onChangeListener = sprite.events:on('change', onSpriteChange)

                updateLast()
            end

            -- Update dialog based on new sprite's color mode
            local enabled = false
            if sprite ~= nil then
                enabled = sprite.colorMode == ColorMode.RGB
            end

            dialog:modify{id = Modes.Regular, enabled = enabled} --
            :modify{id = Modes.Outline, enabled = enabled} --
            :modify{id = Modes.Cut, enabled = enabled} --
            -- :modify{id = Modes.Yeet, enabled = enabled} --
            :modify{id = Modes.Mix, enabled = enabled} --
            :modify{id = Modes.MixProportional, enabled = enabled} --
            :modify{id = Modes.Colorize, enabled = enabled} --
            :modify{id = Modes.Desaturate, enabled = enabled} --
            :modify{id = Modes.ShiftHsvHue, enabled = enabled} --
            :modify{id = Modes.ShiftHslHue, enabled = enabled} --
            :modify{id = Modes.ShiftHsvSaturation, enabled = enabled} --
            :modify{id = Modes.ShiftHslSaturation, enabled = enabled} --
            :modify{id = Modes.ShiftHsvValue, enabled = enabled} --
            :modify{id = Modes.ShiftHslLightness, enabled = enabled} --
        end)

        local updateColors = function()
            if not IsSpecialCursorMode() then
                app.fgColor = lastFgColor
                app.bgColor = lastBgColor
            else
                if app.fgColor.rgbaPixel ~= MagicPink.rgbaPixel then
                    lastFgColor = Color(app.fgColor.rgbaPixel)
                    app.fgColor = MagicPink
                end

                if app.bgColor.rgbaPixel ~= MagicTeal.rgbaPixel then
                    lastBgColor = Color(app.bgColor.rgbaPixel)
                    app.bgColor = MagicTeal
                end
            end
        end

        local onFgColorListener = app.events:on('fgcolorchange', function()
            if IsSpecialCursorMode() then
                if app.fgColor.rgbaPixel ~= MagicPink.rgbaPixel then
                    lastFgColor = Color(app.fgColor.rgbaPixel)
                    app.fgColor = MagicPink
                end
            else
                lastFgColor = Color(app.fgColor.rgbaPixel)
            end
        end)

        local onBgColorListener = app.events:on('bgcolorchange', function()
            if IsSpecialCursorMode() then
                if app.bgColor.rgbaPixel ~= MagicTeal.rgbaPixel then
                    lastBgColor = Color(app.bgColor.rgbaPixel)
                    app.bgColor = MagicTeal
                end
            else
                lastBgColor = Color(app.bgColor.rgbaPixel)
            end
        end)

        local ColorModels<const> = {HSV = "HSV", HSL = "HSL"}
        local colorModel = ColorModels.HSV

        dialog = Dialog {
            title = "Magic Pencil",
            onclose = function()
                if sprite ~= nil then
                    sprite.events:off(onChangeListener)
                    sprite = nil
                end

                app.events:off(onSiteChange)
                app.events:off(onFgColorListener)
                app.events:off(onBgColorListener)

                app.fgColor = lastFgColor
                app.bgColor = lastBgColor
            end
        }
        dialog --
        :radio{
            id = Modes.Regular,
            text = "Regular",
            selected = true,
            enabled = sprite.colorMode == ColorMode.RGB,
            onclick = function()
                selectedMode = Modes.Regular
                updateColors()
            end
        } --
        :separator{text = "Transform"} --
        :radio{
            id = Modes.Outline,
            text = "Outline",
            enabled = sprite.colorMode == ColorMode.RGB,
            onclick = function()
                selectedMode = Modes.Outline
                updateColors()
            end
        }:newrow() --
        :radio{
            id = Modes.Cut,
            text = "Lift",
            enabled = sprite.colorMode == ColorMode.RGB,
            onclick = function()
                selectedMode = Modes.Cut
                updateColors()
            end
        }:newrow() --
        -- :radio{
        --     id = Modes.Yeet,
        --     text = "Yeet",
        --     enabled = sprite.colorMode == ColorMode.RGB,
        --     onclick = function()
        --         selectedMode = Modes.Yeet
        --         updateColors()
        --     end
        -- }:newrow() --
        :separator{text = "Mix"}:radio{
            id = Modes.Mix,
            text = "Unique",
            enabled = sprite.colorMode == ColorMode.RGB,
            onclick = function()
                selectedMode = Modes.Mix
                updateColors()
            end
        }:newrow() --
        :radio{
            id = Modes.MixProportional,
            text = "Proportional",
            enabled = sprite.colorMode == ColorMode.RGB,
            onclick = function()
                selectedMode = Modes.MixProportional
                updateColors()
            end
        } --
        :separator{text = "Change"} --
        :radio{
            id = Modes.Colorize,
            text = "Colorize",
            enabled = sprite.colorMode == ColorMode.RGB,
            onclick = function()
                selectedMode = Modes.Colorize
                updateColors()
            end
        }:newrow() --
        :radio{
            id = Modes.Desaturate,
            text = "Desaturate",
            enabled = sprite.colorMode == ColorMode.RGB,
            onclick = function()
                selectedMode = Modes.Desaturate
                updateColors()
            end
        }:newrow() --
        :separator{text = "Shift"} --
        :combobox{
            id = "colorModel",
            options = ColorModels,
            option = colorModel,
            onchange = function()
                colorModel = dialog.data.colorModel

                if colorModel == ColorModels.HSV then
                    if selectedMode == Modes.ShiftHslHue then
                        selectedMode = Modes.ShiftHsvHue
                    elseif selectedMode == Modes.ShiftHslSaturation then
                        selectedMode = Modes.ShiftHsvSaturation
                    elseif selectedMode == Modes.ShiftHslLightness then
                        selectedMode = Modes.ShiftHsvValue
                    end

                    dialog --
                    :modify{
                        id = Modes.ShiftHslHue,
                        visible = false,
                        selected = false
                    } --
                    :modify{
                        id = Modes.ShiftHslSaturation,
                        visible = false,
                        selected = false
                    } --
                    :modify{
                        id = Modes.ShiftHslLightness,
                        visible = false,
                        selected = false
                    } --
                    :modify{
                        id = Modes.ShiftHsvHue,
                        visible = true,
                        selected = selectedMode == Modes.ShiftHsvHue
                    } --
                    :modify{
                        id = Modes.ShiftHsvSaturation,
                        visible = true,
                        selected = selectedMode == Modes.ShiftHsvSaturation
                    } --
                    :modify{
                        id = Modes.ShiftHsvValue,
                        visible = true,
                        selected = selectedMode == Modes.ShiftHsvValue
                    } --
                elseif colorModel == ColorModels.HSL then
                    if selectedMode == Modes.ShiftHsvHue then
                        selectedMode = Modes.ShiftHslHue
                    elseif selectedMode == Modes.ShiftHsvSaturation then
                        selectedMode = Modes.ShiftHslSaturation
                    elseif selectedMode == Modes.ShiftHsvValue then
                        selectedMode = Modes.ShiftHslLightness
                    end

                    dialog --
                    :modify{
                        id = Modes.ShiftHslHue,
                        visible = true,
                        selected = selectedMode == Modes.ShiftHslHue
                    } --
                    :modify{
                        id = Modes.ShiftHslSaturation,
                        visible = true,
                        selected = selectedMode == Modes.ShiftHslSaturation
                    } --
                    :modify{
                        id = Modes.ShiftHslLightness,
                        visible = true,
                        selected = selectedMode == Modes.ShiftHslLightness
                    } --
                    :modify{
                        id = Modes.ShiftHsvHue,
                        visible = false,
                        selected = false
                    } --
                    :modify{
                        id = Modes.ShiftHsvSaturation,
                        visible = false,
                        selected = false
                    } --
                    :modify{
                        id = Modes.ShiftHsvValue,
                        visible = false,
                        selected = false
                    } --
                end
            end
        } --
        :radio{
            id = Modes.ShiftHsvHue,
            text = "Hue",
            enabled = sprite.colorMode == ColorMode.RGB,
            visible = colorModel == ColorModels.HSV,
            onclick = function()
                selectedMode = Modes.ShiftHsvHue
                updateColors()
            end
        } --
        :radio{
            id = Modes.ShiftHslHue,
            text = "Hue",
            enabled = sprite.colorMode == ColorMode.RGB,
            visible = colorModel == ColorModels.HSL,
            onclick = function()
                selectedMode = Modes.ShiftHslHue
                updateColors()
            end
        } --
        :newrow() --
        :radio{
            id = Modes.ShiftHsvSaturation,
            text = "Saturation",
            enabled = sprite.colorMode == ColorMode.RGB,
            visible = colorModel == ColorModels.HSV,
            onclick = function()
                selectedMode = Modes.ShiftHsvSaturation
                updateColors()
            end
        } --
        :radio{
            id = Modes.ShiftHslSaturation,
            text = "Saturation",
            enabled = sprite.colorMode == ColorMode.RGB,
            visible = colorModel == ColorModels.HSL,
            onclick = function()
                selectedMode = Modes.ShiftHslSaturation
                updateColors()
            end
        } --
        :newrow() --
        :radio{
            id = Modes.ShiftHsvValue,
            text = "Value",
            enabled = sprite.colorMode == ColorMode.RGB,
            visible = colorModel == ColorModels.HSV,
            onclick = function()
                selectedMode = Modes.ShiftHsvValue
                updateColors()
            end
        } --
        :radio{
            id = Modes.ShiftHslLightness,
            text = "Lightness",
            enabled = sprite.colorMode == ColorMode.RGB,
            visible = colorModel == ColorModels.Hsl,
            onclick = function()
                selectedMode = Modes.ShiftHslLightness
                updateColors()
            end
        } --
        :newrow() --
        :slider{
            id = "shift",
            min = 1,
            max = 100,
            value = shiftPercentage,
            onrelease = function()
                shiftPercentage = dialog.data.shift
            end
        } --
        dialog:show{wait = false}
    end
}
