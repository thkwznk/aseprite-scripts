local GetBoundsForPixels = dofile("../GetBoundsForPixels.lua")

local GraffitiMode = {canExtend = true}

function GraffitiMode:Process(change, sprite, cel, parameters)
    -- Use the current image instead of the previous one
    local activeCel = app.activeCel
    local drawPixel = activeCel.image.drawPixel

    local brushSize = app.preferences.tool(app.tool.id).brush.size
    local sizeFactor = 100 * 2 * brushSize

    local dripChance = parameters.graffitiPower / sizeFactor
    local speckChance = (parameters.graffitiSpeckEnabled and
                            parameters.graffitiSpeckPower or 0) / sizeFactor

    local maxDripLength = math.ceil(brushSize * 8)
    local maxDripSize = math.ceil(brushSize * 0.8)

    local maxSpeckDist = math.max((brushSize * 2), 3)
    local maxSpeckSize = math.ceil(brushSize * 0.2)

    -- TODO: Test this further and adjust values

    if brushSize > 1 then maxSpeckSize = math.max(maxSpeckSize, 2) end

    local paintPixels = {}

    for _, pixel in ipairs(change.pixels) do
        local shouldDrip = math.random() <= dripChance
        local shouldSpeck = math.random() <= speckChance

        if shouldDrip then
            local proportions = math.random(10) / 10
            local length = math.ceil(math.random(maxDripLength) * proportions)
            local size = math.ceil(math.random(maxDripSize) * (1 - proportions))

            self:_DrawDrip(pixel.x, pixel.y, length, size, pixel.newColor,
                           paintPixels)
        end

        if shouldSpeck then
            local distX = math.ceil((math.random() - 0.5) * maxSpeckDist)
            local distY = math.ceil((math.random() - 0.5) * maxSpeckDist)
            local size = math.ceil(math.random() * maxSpeckSize)

            local speckX = pixel.x + distX
            local speckY = pixel.y + distY

            self:_DrawSpeck(speckX, speckY, size / 2, pixel.newColor,
                            paintPixels)
        end
    end

    local paintBounds = GetBoundsForPixels(paintPixels)

    if not paintBounds then return end

    local newImageBounds = activeCel.bounds:union(paintBounds):intersect(
                               sprite.bounds)
    local shift = Point(activeCel.bounds.x - newImageBounds.x,
                        activeCel.bounds.y - newImageBounds.y)

    local newImage = Image(newImageBounds.width, newImageBounds.height,
                           cel.sprite.colorMode)
    newImage:drawImage(activeCel.image, shift)

    for _, pixel in ipairs(paintPixels) do
        drawPixel(newImage, pixel.x - newImageBounds.x,
                  pixel.y - newImageBounds.y, pixel.color)
    end

    sprite:newCel(app.activeLayer, app.activeFrame, newImage,
                  Point(newImageBounds.x, newImageBounds.y))
end

function GraffitiMode:_DrawDrip(x, y, length, size, color, pixels)
    if length < 1 or size < 1 then return end

    for i = 1, length do
        for j = 1, size do
            table.insert(pixels,
                         {x = x - (size / 2) + j, y = y + i, color = color})
        end
    end

    for j = 1, size do
        table.insert(pixels, {
            x = x - (size / 2) + j,
            y = y + length + 2,
            color = color
        })
    end
end

function GraffitiMode:_DrawSpeck(x, y, size, color, pixels)
    if size < 1 then return end

    for ex = x - size, x + size do
        for ey = y - size, y + size do
            if math.sqrt(((ex - x) ^ 2) + ((ey - y) ^ 2)) <= size then
                table.insert(pixels, {x = ex, y = ey, color = color})
            end
        end
    end
end

return GraffitiMode
