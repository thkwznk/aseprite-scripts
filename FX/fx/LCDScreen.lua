local LCDScreen = {}

function LCDScreen:_CountDepth(layers, layer, counter)
    counter = counter or {found = false, count = 0}

    for _, currentLayer in ipairs(layers) do
        if currentLayer.isGroup then
            self:_CountDepth(currentLayer.layers, layer, counter)
        else
            counter.count = counter.count + 1
        end

        if currentLayer == layer then
            counter.found = true
            break
        end
    end

    return counter
end

function LCDScreen:_MergeImages(imageA, positionA, imageB, positionB)
    local minX = math.min(positionA.x, positionB.x)
    local minY = math.min(positionA.y, positionB.y)

    local maxX =
        math.max(positionA.x + imageA.width, positionB.x + imageB.width)
    local maxY = math.max(positionA.y + imageA.height,
                          positionB.y + imageB.height)

    local newImage = Image(maxX - minX, maxY - minY)
    local newPosition = Point(minX, minY)

    newImage:drawImage(imageA, Point(positionA.x - minX, positionA.y - minY))
    self:_DrawImageOver(newImage, imageB,
                        Point(positionB.x - minX, positionB.y - minY))

    return newImage, newPosition
end

function LCDScreen:_DrawImageOver(backgroundImage, image, position)
    -- TODO: Could be calculated only for the common part
    for pixel in image:pixels() do
        local pixelValue = pixel()
        local pixelColor = Color(pixelValue)

        local x = position.x + pixel.x
        local y = position.y + pixel.y

        local backgroundPixelValue = backgroundImage:getPixel(x, y)
        local backgroundColor = Color(backgroundPixelValue)

        if backgroundColor.alpha == 0 then
            backgroundImage:drawPixel(x, y, pixelValue)
        else
            local backgroundAlpha = (backgroundColor.alpha / 255)
            local pixelAlpha = (pixelColor.alpha / 255)

            local finalAlpha = backgroundColor.alpha + pixelColor.alpha -
                                   (backgroundAlpha * pixelAlpha * 255)

            local backgroundRed = backgroundColor.red * backgroundAlpha
            local backgroundGreen = backgroundColor.green * backgroundAlpha
            local backgroundBlue = backgroundColor.blue * backgroundAlpha

            local pixelRed = pixelColor.red * pixelAlpha
            local pixelGreen = pixelColor.green * pixelAlpha
            local pixelBlue = pixelColor.blue * pixelAlpha

            local pixelOpaqueness = ((255 - pixelColor.alpha) / 255)

            local finalRed = pixelRed + backgroundRed * pixelOpaqueness
            local finalGreen = pixelGreen + backgroundGreen * pixelOpaqueness
            local finalBlue = pixelBlue + backgroundBlue * pixelOpaqueness

            backgroundImage:drawPixel(x, y, Color {
                r = finalRed / (finalAlpha / 255),
                g = finalGreen / (finalAlpha / 255),
                b = finalBlue / (finalAlpha / 255),
                a = finalAlpha
            })
        end
    end
end

function LCDScreen:_GetProcessingUnits(cels)
    local units = {}

    for _, cel in ipairs(cels) do
        local unit = nil

        for _, existingUnit in ipairs(units) do
            if cel.frameNumber == existingUnit.frameNumber then
                unit = existingUnit
                break
            end
        end

        if unit == nil then
            unit = {frameNumber = cel.frameNumber, cels = {cel}}
            table.insert(units, unit)
        end

        table.insert(unit.cels, cel)
    end

    return units
end

function LCDScreen:Generate(sprite, cels, pixelWidth, pixelHeight)
    -- If there's no cels to modify
    if #cels == 0 then return end

    -- Split all selected cels by layer - into units, one per frame
    local units = self:_GetProcessingUnits(cels)

    local colorShift = {
        x = math.floor(pixelWidth / 2),
        y = math.floor(pixelHeight / 4)
    }

    local groupLayer = sprite:newGroup()
    groupLayer.name = "LCD Screen"

    local redLayer = sprite:newLayer()
    redLayer.name = "Red"
    redLayer.parent = groupLayer
    redLayer.color = Color {red = 255, green = 0, blue = 0, alpha = 32}
    redLayer.blendMode = BlendMode.SCREEN

    local greenLayer = sprite:newLayer()
    greenLayer.name = "Green"
    greenLayer.parent = groupLayer
    greenLayer.color = Color {red = 0, green = 255, blue = 0, alpha = 32}
    greenLayer.blendMode = BlendMode.SCREEN

    local blueLayer = sprite:newLayer()
    blueLayer.name = "Blue"
    blueLayer.parent = groupLayer
    blueLayer.color = Color {red = 0, green = 0, blue = 255, alpha = 32}
    blueLayer.blendMode = BlendMode.SCREEN

    local scanlinesLayer = sprite:newLayer()
    scanlinesLayer.name = "Scanlines"
    scanlinesLayer.parent = groupLayer
    scanlinesLayer.color = Color {red = 0, green = 0, blue = 0, alpha = 32}
    scanlinesLayer.blendMode = BlendMode.SOFT_LIGHT
    scanlinesLayer.opacity = 128

    for _, unit in ipairs(units) do
        local frameNumber = unit.frameNumber

        -- TODO: Even if this works, could be more efficient
        table.sort(unit.cels, function(a, b)
            return self:_CountDepth(sprite.layers, a.layer).count <
                       self:_CountDepth(sprite.layers, b.layer).count
        end)

        local image = unit.cels[1].image
        local position = unit.cels[1].position

        for i = 2, #unit.cels do
            image, position = self:_MergeImages(image, position,
                                                unit.cels[i].image,
                                                unit.cels[i].position)
        end

        local bounds = Rectangle(position.x, position.y, image.width,
                                 image.height)

        local redCel, greenCel, blueCel = {}, {}, {}

        if sprite.selection.isEmpty then
            redCel.image = Image(image.width, image.height)
            greenCel.image = Image(image.width, image.height)
            blueCel.image = Image(image.width, image.height)

            -- Offset red to the left
            redCel.position = Point(position.x - colorShift.x, position.y)
            -- Don't offset green
            greenCel.position = Point(position.x, position.y)
            -- Offset blue to the right
            blueCel.position = Point(position.x + colorShift.x, position.y)

            for pixel in image:pixels() do
                local redColor = Color(pixel())
                redColor.green = 0
                redColor.blue = 0

                redCel.image:drawPixel(pixel.x, pixel.y, redColor)

                local greenColor = Color(pixel())
                greenColor.red = 0
                greenColor.blue = 0

                greenCel.image:drawPixel(pixel.x, pixel.y, greenColor)

                local blueColor = Color(pixel())
                blueColor.red = 0
                blueColor.green = 0

                blueCel.image:drawPixel(pixel.x, pixel.y, blueColor)
            end
        elseif bounds:intersects(sprite.selection.bounds) then
            local imagePartBounds = bounds:intersect(sprite.selection.bounds)

            redCel.image = Image(imagePartBounds.width, imagePartBounds.height)
            greenCel.image =
                Image(imagePartBounds.width, imagePartBounds.height)
            blueCel.image = Image(imagePartBounds.width, imagePartBounds.height)

            local shiftX = imagePartBounds.x - position.x
            local shiftY = imagePartBounds.y - position.y

            -- Offset red to the left + include selection shift
            redCel.position = Point(position.x - colorShift.x + shiftX,
                                    position.y + shiftY)
            -- Don't offset green BUT include selection shift
            greenCel.position = Point(position.x + shiftX, position.y + shiftY)
            -- Offset blue to the right + include selection shift
            blueCel.position = Point(position.x + colorShift.x + shiftX,
                                     position.y + shiftY)

            for pixel in image:pixels(Rectangle(shiftX, shiftY,
                                                imagePartBounds.width,
                                                imagePartBounds.height)) do
                local redColor = Color(pixel())
                redColor.green = 0
                redColor.blue = 0

                redCel.image:drawPixel(pixel.x - shiftX, pixel.y - shiftY,
                                       redColor)

                local greenColor = Color(pixel())
                greenColor.red = 0
                greenColor.blue = 0

                greenCel.image:drawPixel(pixel.x - shiftX, pixel.y - shiftY,
                                         greenColor)

                local blueColor = Color(pixel())
                blueColor.red = 0
                blueColor.green = 0

                blueCel.image:drawPixel(pixel.x - shiftX, pixel.y - shiftY,
                                        blueColor)
            end
        end

        sprite:newCel(redLayer, frameNumber, redCel.image, redCel.position)
        sprite:newCel(greenLayer, frameNumber, greenCel.image, greenCel.position)
        sprite:newCel(blueLayer, frameNumber, blueCel.image, blueCel.position)
    end

    self:_CreateScanlinesLayer(sprite, scanlinesLayer, cels, pixelWidth,
                               pixelHeight)
end

function LCDScreen:_CreateScanlinesLayer(sprite, layer, cels, pixelWidth,
                                         pixelHeight)
    local width = sprite.selection.isEmpty and sprite.width or
                      sprite.selection.bounds.width
    local height = sprite.selection.isEmpty and sprite.height or
                       sprite.selection.bounds.height
    local position = sprite.selection.isEmpty and Point(0, 0) or
                         sprite.selection.origin

    local scanlinesImage = Image(width, height)

    for y = 0, scanlinesImage.height - 1 do
        for x = 0, scanlinesImage.width - 1 do
            if y % pixelHeight == 0 then
                scanlinesImage:drawPixel(x, y, Color {gray = 0, alpha = 64})
            end

            if x % pixelWidth == 0 then
                scanlinesImage:drawPixel(x, y, Color {gray = 0, alpha = 255})
            end
        end
    end

    local frames = {}
    for _, cel in ipairs(cels) do table.insert(frames, cel.frameNumber) end
    table.sort(frames)

    sprite:newCel(layer, frames[1], scanlinesImage, position)

    app.range:clear()
    app.range.frames = frames
    app.range.layers = {layer}
    app.command:LinkCels()
end

return LCDScreen

-- TODO: Skip cels that are empty
