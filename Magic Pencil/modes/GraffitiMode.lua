local GraffitiMode = {}

function GraffitiMode:Process(change, sprite, cel, parameters)
    local brushSize = app.preferences.tool("pencil").brush.size
    local power = parameters.graffitiPower / 100

    local safeValue = function(x) return math.max(math.floor(x), 1) end

    local chanceToDrip = (2 + 3 * power) / 100
    local maxDripLength = safeValue(brushSize * 8 * power)
    local maxDripSize = safeValue(brushSize * 0.2 * power)

    local chanceToSpeck = (1 + 1 * power) / 100
    local maxSpeckDist = safeValue(brushSize * 3 * power)
    local maxSpeckSize = safeValue(brushSize * 0.2 * power)

    -- TODO: Make the mode correctly expand the image

    for _, pixel in ipairs(change.pixels) do
        local x = pixel.x - cel.position.x
        local y = pixel.y - cel.position.y

        cel.image:drawPixel(x, y, pixel.newColor)

        local shouldDrip = math.random() <= chanceToDrip
        local shouldSpeck = math.random() <= chanceToSpeck

        if shouldDrip then
            local proportions = math.random(10) / 10
            local dripLength = math.ceil(
                                   math.random(maxDripLength) * proportions)
            local dripSize = math.ceil(math.random(maxDripSize) *
                                           (1 - proportions))

            for i = 1, dripLength do
                for j = 1, dripSize do
                    cel.image:drawPixel(x - (dripSize / 2) + j, y + i,
                                        pixel.newColor)
                end
            end
        end

        if shouldSpeck then
            local speckDistX = math.floor((math.random() - 0.5) * maxSpeckDist)
            local speckDistY = math.floor((math.random() - 0.5) * maxSpeckDist)
            local speckSize = math.floor(math.random() * maxSpeckSize)

            local speckX = x + speckDistX
            local speckY = y + speckDistY

            for ex = speckX - speckSize, speckX + speckSize do
                for ey = speckY - speckSize, speckY + speckSize do

                    if math.sqrt(((ex - speckX) ^ 2) + ((ey - speckY) ^ 2)) <=
                        speckSize then
                        cel.image:drawPixel(ex, ey, pixel.newColor)
                    end
                end
            end
        end
    end

    sprite:newCel(app.activeLayer, app.activeFrame, cel.image, cel.position)
end

return GraffitiMode
