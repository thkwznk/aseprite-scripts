local GraffitiMode = {}

function GraffitiMode:Process(change, sprite, cel, parameters)
    local drawPixel = cel.image.drawPixel

    local brushSize = app.preferences.tool("pencil").brush.size
    local power = parameters.graffitiPower / 100

    local safeValue = function(x) return math.max(math.floor(x), 1) end

    local chanceToDrip = (2 + 3 * power) / 100
    local maxDripLength = safeValue(brushSize * 8 * power)
    local maxDripSize = safeValue(brushSize * 0.2 * power)

    local chanceToSpeck = (1 + 1 * power) / 100
    local maxSpeckDist = safeValue(brushSize * 3 * power)
    local maxSpeckSize = safeValue(brushSize * 0.2 * power)

    local paintPixels = {}

    for _, pixel in ipairs(change.pixels) do
        local shouldDrip = math.random() <= chanceToDrip
        local shouldSpeck = math.random() <= chanceToSpeck

        if shouldDrip then
            local proportions = math.random(10) / 10
            local length = math.ceil(math.random(maxDripLength) * proportions)
            local size = math.ceil(math.random(maxDripSize) * (1 - proportions))

            self:_DrawDrip(pixel.x, pixel.y, length, size, pixel.newColor,
                           paintPixels)
        end

        if shouldSpeck then
            local distX = math.floor((math.random() - 0.5) * maxSpeckDist)
            local distY = math.floor((math.random() - 0.5) * maxSpeckDist)
            local size = math.floor(math.random() * maxSpeckSize)

            local speckX = pixel.x + distX
            local speckY = pixel.y + distY

            self:_DrawSpeck(speckX, speckY, size, pixel.newColor, paintPixels)
        end
    end

    local paintBounds = GetBoundsForPixels(paintPixels)
    local newImageBounds = cel.bounds:union(paintBounds)
    local shift = Point(cel.bounds.x - newImageBounds.x,
                        cel.bounds.y - newImageBounds.y)

    local newImage = Image(newImageBounds.width, newImageBounds.height)
    newImage:drawImage(cel.image, shift.x, shift.y)

    for _, pixel in ipairs(paintPixels) do
        drawPixel(newImage, pixel.x - newImageBounds.x,
                  pixel.y - newImageBounds.y, pixel.color)
    end

    sprite:newCel(app.activeLayer, app.activeFrame, newImage,
                  Point(newImageBounds.x, newImageBounds.y))
end

function GraffitiMode:_DrawDrip(x, y, length, size, color, pixels)
    for i = 1, length do
        for j = 1, size do
            table.insert(pixels,
                         {x = x - (size / 2) + j, y = y + i, color = color})
        end
    end
end

function GraffitiMode:_DrawSpeck(x, y, size, color, pixels)
    for ex = x - size, x + size do
        for ey = y - size, y + size do
            if math.sqrt(((ex - x) ^ 2) + ((ey - y) ^ 2)) <= size then
                table.insert(pixels, {x = ex, y = ey, color = color})
            end
        end
    end
end

return GraffitiMode
