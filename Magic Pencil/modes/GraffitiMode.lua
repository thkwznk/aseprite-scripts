local GetBoundsForPixels = dofile("../GetBoundsForPixels.lua")

local ceil, random, sqrt, max = math.ceil, math.random, math.sqrt, math.max
local insert = table.insert

local GraffitiMode = {canExtend = true}

function GraffitiMode:Process(change, sprite, cel, parameters)
    -- Use the current image instead of the previous one
    local activeCel = app.activeCel
    local drawPixel = activeCel.image.drawPixel

    local brushSize = app.preferences.tool(app.tool.id).brush.size

    -- Paint Bucket has a hardcoded brush size of 64 so it needs to be overwritten for better results
    if app.tool.id == "paint_bucket" then brushSize = 8 end

    local sizeFactor = brushSize * 4 -- The second value is a magic number
    local power = parameters.graffitiPower / 100
    local speckPower = (parameters.graffitiSpeckEnabled and
                           parameters.graffitiSpeckPower or 0) / 100

    local dripChance = power / sizeFactor
    local speckChance = speckPower / sizeFactor

    local maxDripLength = ceil(brushSize * 8)
    local maxDripSize = ceil(brushSize * power)

    local maxSpeckDist = max((brushSize * 2), 3)
    local maxSpeckSize = ceil(brushSize * speckPower)

    if brushSize > 1 then maxSpeckSize = max(maxSpeckSize, 2) end

    local paintPixels = {}

    for _, pixel in ipairs(change.pixels) do
        local shouldDrip = random() <= dripChance
        local shouldSpeck = random() <= speckChance

        if shouldDrip then
            local proportions = random(10) / 10
            local length = ceil(random(maxDripLength) * proportions)
            local size = ceil(random(maxDripSize) * (1 - proportions))

            self:_DrawDrip(pixel.x, pixel.y, length, size, pixel.newColor,
                           paintPixels)
        end

        if shouldSpeck then
            local distX = ceil((random() - 0.5) * maxSpeckDist)
            local distY = ceil((random() - 0.5) * maxSpeckDist)
            local size = ceil(random() * maxSpeckSize)

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

    local xx = x - (size / 2)

    for i = 1, length do
        for j = 1, size do
            insert(pixels, {x = xx + j, y = y + i, color = color})
        end
    end

    local yy = y + length + 2

    for j = 1, size do insert(pixels, {x = xx + j, y = yy, color = color}) end
end

function GraffitiMode:_DrawSpeck(x, y, size, color, pixels)
    if size < 1 then return end

    for ex = x - size, x + size do
        for ey = y - size, y + size do
            if sqrt(((ex - x) ^ 2) + ((ey - y) ^ 2)) <= size then
                insert(pixels, {x = ex, y = ey, color = color})
            end
        end
    end
end

return GraffitiMode

-- TODO: Correctly blend color with alpha
